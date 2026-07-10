import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "config" as Config

Rectangle {
    id: root

    Config.Numbers { id: numbers }
    Config.Colors { id: colors }

    required property var popupParentWindow
    property color themePillColor: colors.pillColor
    property color themeActivePillColor: colors.activePillColor
    property color themePopupColor: colors.popupColor
    property color themePopupBorderColor: colors.popupBorderColor
    property color themeTextColor: colors.textColor
    property color themeAudioTextColor: colors.audioTextColor

    readonly property var player: activePlayer()
    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property real progress: mediaProgress()
    readonly property var lyricEntries: currentLyricEntries()
    readonly property int currentLyricIndex: currentLyricIndexFor(playbackPosition)
    readonly property string pillLyricText: {
        var entry = lyricEntries[currentLyricIndex];
        if (entry && entry.time >= 0 && entry.text) return entry.text;
        if (hasPlayer && player.trackTitle) return player.trackTitle;
        return hasPlayer ? player.identity : "Media";
    }
    property bool popupOpen: false
    property bool popupClosing: false
    property bool suppressed: false
    property real playbackPosition: 0
    property string localLyricsText: ""
    property string localLyricsTrackKey: ""
    property var allowedPlayerKeywords: [
        "yesplaymusic",
        "spotify"
    ]
    property var allowedBrowserMediaKeywords: [
        "music.youtube.com",
        "youtube music",
        "ytmusic",
        "open.spotify.com",
        "spotify.com"
    ]
    property var browserPlayerKeywords: [
        "chrome",
        "chromium",
        "firefox",
        "zen",
        "brave",
        "edge"
    ]

    Layout.preferredWidth: hasPlayer && !suppressed ? numbers.musicPillWidth : 0
    Layout.preferredHeight: numbers.pillHeight
    Layout.alignment: Qt.AlignVCenter
    Layout.maximumWidth: hasPlayer && !suppressed ? numbers.musicPillWidth : 0
    visible: hasPlayer && !suppressed
    radius: numbers.pillRadius
    color: themePillColor
    clip: true

    function activePlayer() {
        var players = Mpris.players.values;
        if (!players || players.length === 0) return null;

        for (var i = 0; i < players.length; i++) {
            if (players[i].isPlaying && playerAllowed(players[i])) return players[i];
        }

        for (var j = 0; j < players.length; j++) {
            if (playerAllowed(players[j])) return players[j];
        }

        return null;
    }

    function playerAllowed(candidate) {
        if (!candidate) return false;

        var appText = playerAppText(candidate);
        if (textContainsAny(appText, allowedPlayerKeywords)) return true;

        if (!textContainsAny(appText, browserPlayerKeywords)) return false;

        return textContainsAny(playerMetadataText(candidate), allowedBrowserMediaKeywords);
    }

    function playerAppText(candidate) {
        return [
            candidate.identity || "",
            candidate.desktopEntry || "",
            candidate.dbusName || ""
        ].join(" ").toLowerCase();
    }

    function playerMetadataText(candidate) {
        var metadata = candidate.metadata || ({});
        var parts = [
            candidate.trackTitle || "",
            candidate.trackArtist || "",
            candidate.trackAlbum || "",
            candidate.trackArtUrl || "",
            metadata["xesam:url"] || "",
            metadata["mpris:trackid"] || "",
            metadata["xesam:title"] || "",
            metadata["xesam:artist"] || "",
            metadata["xesam:album"] || "",
            metadata["url"] || ""
        ];

        return parts.join(" ").toLowerCase();
    }

    function textContainsAny(text, keywords) {
        if (!text || !keywords) return false;

        for (var i = 0; i < keywords.length; i++) {
            if (text.indexOf(keywords[i]) >= 0) return true;
        }

        return false;
    }

    function mediaProgress() {
        if (!hasPlayer || !player.lengthSupported || player.length <= 0) return 0;
        return Math.max(0, Math.min(1, playbackPosition / player.length));
    }

    function popupArtistText() {
        if (!hasPlayer) return "";
        if (player.trackArtist) return player.trackArtist;
        return player.identity || "";
    }

    function lyricSourceText() {
        if (!hasPlayer) return "";

        var metadata = player.metadata || ({});
        var text = lyricTextFromMetadata(metadata);
        if ((!text || String(text).length === 0) && localLyricsText.length > 0) text = localLyricsText;
        if (text && String(text).length > 0) return String(text);

        return "";
    }

    function currentLyricEntries() {
        var text = lyricSourceText();
        if (text.length === 0) return [{ "time": -1, "text": "No lyrics from player" }];

        var entries = parseLyricEntries(text);
        return entries.length > 0 ? entries : [{ "time": -1, "text": "No lyrics from player" }];
    }

    function lyricTextFromMetadata(metadata) {
        if (!metadata) return "";

        var keys = [
            "xesam:asText",
            "lyrics",
            "lyric",
            "lrc",
            "xesam:comment",
            "xesam:description"
        ];

        for (var i = 0; i < keys.length; i++) {
            var direct = lyricValueToText(metadata[keys[i]]);
            if (direct.length > 0) return direct;
        }

        var nestedKeys = [
            ["lyrics", "lrc", "lyric"],
            ["lyrics", "tlyric", "lyric"],
            ["lyrics", "romalrc", "lyric"],
            ["lrc", "lyric"],
            ["tlyric", "lyric"],
            ["romalrc", "lyric"]
        ];

        for (var j = 0; j < nestedKeys.length; j++) {
            var value = metadata;
            for (var k = 0; k < nestedKeys[j].length; k++) {
                if (!value) break;
                value = value[nestedKeys[j][k]];
            }

            var nested = lyricValueToText(value);
            if (nested.length > 0) return nested;
        }

        return "";
    }

    function lyricValueToText(value) {
        if (value === null || value === undefined) return "";
        if (typeof value === "string") return value;
        if (Array.isArray(value)) return value.join("\n");
        if (typeof value === "object") {
            if (value.lyric) return lyricValueToText(value.lyric);
            if (value.lrc) return lyricValueToText(value.lrc);
            if (value.text) return lyricValueToText(value.text);
            if (value.content) return lyricValueToText(value.content);
        }

        return "";
    }

    function parseTimestamp(tag) {
        var match = tag.match(/^(\d+):(\d+(?:\.\d+)?)$/);
        if (!match) return -1;

        return parseInt(match[1]) * 60 + parseFloat(match[2]);
    }

    function parseLyricEntries(text) {
        var entries = [];
        var lines = text.split(/\r?\n/);

        for (var i = 0; i < lines.length; i++) {
            var raw = lines[i];
            var tags = [];
            var tagMatch;
            var tagPattern = /\[([0-9]+:[0-9.]+)\]/g;

            while ((tagMatch = tagPattern.exec(raw)) !== null) {
                var time = parseTimestamp(tagMatch[1]);
                if (time >= 0) tags.push(time);
            }

            var clean = raw
                .replace(/\[[0-9:.]+\]/g, "")
                .replace(/\[[a-z]+:[^\]]*\]/ig, "")
                .trim();

            if (clean.length === 0) continue;

            if (tags.length === 0) {
                entries.push({ "time": -1, "text": clean });
                continue;
            }

            for (var j = 0; j < tags.length; j++) {
                entries.push({ "time": tags[j], "text": clean });
            }
        }

        entries.sort(function(a, b) {
            if (a.time < 0 && b.time < 0) return 0;
            if (a.time < 0) return 1;
            if (b.time < 0) return -1;
            return a.time - b.time;
        });

        return entries.slice(0, numbers.musicLyricMaxEntries);
    }

    function currentLyricIndexFor(position) {
        var entries = lyricEntries;
        if (!entries || entries.length === 0 || entries[0].time < 0) return 0;

        var current = 0;
        for (var i = 0; i < entries.length; i++) {
            if (entries[i].time < 0) continue;
            if (entries[i].time <= position + 0.15) current = i;
            else break;
        }

        return current;
    }

    function currentTrackKey() {
        if (!hasPlayer) return "";
        return (player.trackTitle || "") + "|" + (player.trackArtist || "") + "|" + (player.trackAlbum || "");
    }

    function songIdFromMetadata() {
        if (!hasPlayer) return "";

        var metadata = player.metadata || ({});
        var candidates = [
            metadata["mpris:trackid"],
            metadata["xesam:url"],
            metadata["url"],
            metadata["trackid"],
            metadata["songId"],
            metadata["id"]
        ];

        for (var i = 0; i < candidates.length; i++) {
            var value = candidates[i];
            if (value === null || value === undefined) continue;

            var match = String(value).match(/(?:song(?:\?id=|\/)|id=|track\/|\/)([0-9]{4,})/i);
            if (match) return match[1];

            var plain = String(value).match(/^[0-9]{4,}$/);
            if (plain) return plain[0];
        }

        return "";
    }

    function refreshLocalLyrics() {
        if (!hasPlayer) return;
        if (yesplayLyricsProc.running) return;

        var metadata = player.metadata || ({});
        if (lyricTextFromMetadata(metadata).length > 0) return;

        var trackKey = currentTrackKey();
        if (localLyricsTrackKey === trackKey && localLyricsText.length > 0) return;

        var songId = songIdFromMetadata();
        var searchText = ((player.trackTitle || "") + " " + (player.trackArtist || "")).trim();
        localLyricsText = "";
        if (songId.length === 0 && searchText.length === 0) return;

        localLyricsTrackKey = trackKey;
        yesplayLyricsProc.command = ["sh", "-c", yesplayLyricsCommand(songId, searchText)];
        yesplayLyricsProc.running = true;
    }

    function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    function yesplayLyricsCommand(songId, searchText) {
        var base = "http://127.0.0.1:27232";
        var command = "id=" + shellQuote(songId) + "; ";
        command += "base=" + shellQuote(base) + "; ";
        command += "if [ -z \"$id\" ]; then ";
        command += "search=$(curl -sG --max-time 3 --data-urlencode keywords=" + shellQuote(searchText) + " --data-urlencode limit=1 --data-urlencode type=1 \"$base/search\"); ";
        command += "id=$(printf '%s' \"$search\" | sed -n 's/.*\"id\":\\([0-9][0-9]*\\).*/\\1/p' | head -1); ";
        command += "fi; ";
        command += "if [ -n \"$id\" ]; then ";
        command += "out=$(curl -s --max-time 3 \"$base/api/lyric?id=$id\"); ";
        command += "[ -n \"$out\" ] || out=$(curl -s --max-time 3 \"$base/lyric?id=$id\"); ";
        command += "printf '%s' \"$out\"; ";
        command += "fi";
        return command;
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00";

        var rounded = Math.floor(seconds);
        var minutes = Math.floor(rounded / 60);
        var rest = rounded % 60;
        return minutes + ":" + (rest < 10 ? "0" : "") + rest;
    }

    function itemPositionInWindow(item) {
        var x = 0;
        var y = 0;
        var current = item;

        while (current) {
            x += current.x || 0;
            y += current.y || 0;
            current = current.parent;
        }

        return { "x": x, "y": y };
    }

    function popupX() {
        var point = itemPositionInWindow(root);
        var width = numbers.musicPopupWidth;
        var centered = point.x + root.width / 2 - width / 2;
        var maxX = popupParentWindow.width - width - numbers.barSideMargin;
        return Math.max(numbers.barSideMargin, Math.min(centered, maxX));
    }

    function seekToRatio(ratio) {
        if (!hasPlayer || !player.canSeek || !player.lengthSupported || player.length <= 0) return;
        playbackPosition = Math.max(0, Math.min(1, ratio)) * player.length;
        player.position = playbackPosition;
    }

    function openMusicPopup() {
        if (!hasPlayer) return;
        musicPopupCloseTimer.stop();
        popupClosing = false;
        popupOpen = true;
    }

    function closeMusicPopup() {
        if (!popupOpen) return;
        if (!hasPlayer) {
            popupOpen = false;
            popupClosing = false;
            return;
        }

        popupClosing = true;
        popupOpen = false;
        musicPopupCloseTimer.restart();
    }

    function toggleMusicPopup() {
        if (popupOpen) closeMusicPopup();
        else openMusicPopup();
    }

    Process {
        id: yesplayLyricsProc

        command: ["sh", "-c", "echo"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    var lrc = root.lyricValueToText(data.lrc || data.lyric || data.lyrics);
                    var translated = root.lyricValueToText(data.tlyric);
                    root.localLyricsText = lrc.length > 0 ? lrc : translated;
                } catch (error) {
                    root.localLyricsText = text.trim();
                }
            }
        }
    }

    Timer {
        interval: numbers.musicPositionRefreshInterval
        repeat: true
        running: root.hasPlayer
        triggeredOnStart: true
        onTriggered: root.playbackPosition = root.player.position
    }

    Timer {
        interval: numbers.musicLyricRefreshInterval
        repeat: true
        running: root.hasPlayer
        triggeredOnStart: true
        onTriggered: root.refreshLocalLyrics()
    }

    Timer {
        id: musicPopupCloseTimer

        interval: numbers.popupAnimationMs
        repeat: false
        onTriggered: root.popupClosing = false
    }

    onPopupOpenChanged: {
        if (popupOpen) {
            popupClosing = false;
            refreshLocalLyrics();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: themeActivePillColor
        opacity: hasPlayer && player.isPlaying ? numbers.musicActiveOverlayOpacity : 0

        Behavior on opacity {
            NumberAnimation { duration: numbers.popupAnimationMs }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: numbers.musicPillTextMargin
        anchors.rightMargin: numbers.musicPillTextMargin
        height: implicitHeight
        spacing: numbers.musicPillIconTitleSpacing

        Text {
            text: hasPlayer && player.isPlaying ? "" : ""
            color: themeAudioTextColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: numbers.musicPillIconFontSize
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            id: pillLyricViewport

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: pillLyricText.implicitHeight
            clip: true

            Text {
                id: pillLyricText

                anchors.verticalCenter: parent.verticalCenter
                text: root.pillLyricText
                color: themeTextColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: numbers.musicPillIconFontSize
                maximumLineCount: 1

                onTextChanged: {
                    x = 0;
                    pillLyricMarquee.restart();
                }
            }

            SequentialAnimation {
                id: pillLyricMarquee

                running: pillLyricText.implicitWidth > pillLyricViewport.width
                loops: Animation.Infinite

                PauseAnimation { duration: numbers.musicPillLyricScrollDelay }
                NumberAnimation {
                    target: pillLyricText
                    property: "x"
                    from: 0
                    to: Math.min(0, pillLyricViewport.width - pillLyricText.implicitWidth)
                    duration: Math.max(1, -to * numbers.musicPillLyricScrollMsPerPixel)
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: numbers.musicPillLyricScrollEndDelay }
                PropertyAction {
                    target: pillLyricText
                    property: "x"
                    value: 0
                }
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        propagateComposedEvents: true
        onClicked: function(mouse) {
            if (!hasPlayer) return;
            if (mouse.button === Qt.MiddleButton && player.canGoNext) {
                player.next();
                return;
            }
            toggleMusicPopup();
        }
        onWheel: function(wheel) {
            if (!hasPlayer) return;
            if (wheel.angleDelta.y > 0 && player.canGoNext) player.next();
            if (wheel.angleDelta.y < 0 && player.canGoPrevious) player.previous();
        }
    }

    PanelWindow {
        id: musicPopup

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        margins.top: root.popupParentWindow.implicitHeight
        visible: (root.popupOpen || root.popupClosing) && root.hasPlayer
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: root.closeMusicPopup()
        }

        Rectangle {
            width: numbers.musicPopupWidth
            height: numbers.musicPopupHeight
            x: root.popupX()
            y: root.popupOpen
                ? numbers.musicPopupOffsetY
                : numbers.musicPopupOffsetY - numbers.popupAnimationOffset
            opacity: root.popupOpen ? 1 : 0
            scale: root.popupOpen ? 1 : 0.96
            transformOrigin: Item.Top
            radius: numbers.popupRadius
            color: themePopupColor
            border.color: themePopupBorderColor
            border.width: 1
            clip: true

            Behavior on y { NumberAnimation { duration: numbers.popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: numbers.popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: numbers.popupAnimationMs; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            }

            Item {
                id: musicPopupContent

                readonly property real centeredContentY: (
                    height - (musicInfoColumn.height - numbers.musicLyricHeightReduction)
                ) / 2 - numbers.musicCoverY

                anchors.fill: parent
                anchors.margins: numbers.musicPopupMargin

                Item {
                    id: musicInfoColumn

                    y: musicPopupContent.centeredContentY
                    width: numbers.musicInfoColumnWidth
                    height: musicControlsRow.y + musicControlsRow.height

                    Rectangle {
                        id: musicCover

                        x: numbers.musicCoverX
                        y: numbers.musicCoverY
                        width: numbers.musicCoverSize
                        height: numbers.musicCoverSize
                        radius: numbers.musicCoverRadius
                        color: colors.musicCoverFallbackColor
                        clip: true

                        Image {
                            id: popupAlbumArt

                            width: numbers.musicCoverSize
                            height: numbers.musicCoverSize
                            anchors.centerIn: parent
                            source: root.hasPlayer ? root.player.trackArtUrl : ""
                            sourceSize.width: numbers.musicCoverSize
                            sourceSize.height: numbers.musicCoverSize
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: popupAlbumArt.width
                                    height: popupAlbumArt.height
                                    radius: numbers.musicCoverRadius
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: popupAlbumArt.status !== Image.Ready
                            text: root.hasPlayer && root.player.isPlaying ? "" : ""
                            color: themeTextColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: numbers.musicPopupFallbackIconFontSize
                        }
                    }

                    Text {
                        id: musicTitleText

                        x: 0
                        y: musicCover.y + musicCover.height + numbers.musicInfoSpacerHeight
                        width: parent.width
                        text: root.hasPlayer && root.player.trackTitle ? root.player.trackTitle : "Media"
                        color: themeTextColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: numbers.musicTitleFontSize
                        font.bold: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        id: musicArtistText

                        x: 0
                        y: musicTitleText.y + musicTitleText.implicitHeight + numbers.musicInfoSpacing
                        width: parent.width
                        text: root.popupArtistText()
                        color: themeTextColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: numbers.musicArtistFontSize
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    RowLayout {
                        id: musicProgressRow

                        x: 0
                        y: musicArtistText.y + musicArtistText.implicitHeight + numbers.musicInfoSpacing
                        width: parent.width
                        height: implicitHeight
                        spacing: numbers.musicPillTextSpacing

                        Text {
                            text: root.formatTime(root.playbackPosition)
                            color: themeTextColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: numbers.musicTimeFontSize
                            Layout.preferredWidth: numbers.musicTimeWidth
                        }

                        Canvas {
                            id: popupProgressCanvas

                            property real wavePhase: 0

                            Layout.fillWidth: true
                            Layout.preferredHeight: numbers.musicProgressHeight
                            Layout.alignment: Qt.AlignVCenter
                            antialiasing: true

                            onPaint: {
                                var ctx = getContext("2d");
                                var centerY = height / 2;
                                var knobRadius = numbers.musicProgressKnobRadius;
                                var progressX = Math.max(knobRadius, Math.min(width - knobRadius, width * root.progress));
                                var waveLength = numbers.musicProgressWaveLength;
                                var amplitude = numbers.musicProgressWaveAmplitude;

                                ctx.clearRect(0, 0, width, height);

                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.lineWidth = 2;

                                ctx.beginPath();
                                ctx.moveTo(0, centerY);
                                ctx.lineTo(width, centerY);
                                ctx.strokeStyle = colors.musicPopupProgressTrackColor;
                                ctx.stroke();

                                if (root.progress > 0) {
                                    ctx.beginPath();
                                    ctx.moveTo(0, centerY);
                                    for (var x = 0; x <= progressX; x += 2) {
                                        var y = centerY + Math.sin((x + wavePhase) / waveLength * Math.PI * 2) * amplitude;
                                        ctx.lineTo(x, y);
                                    }
                                    ctx.lineTo(progressX, centerY);
                                    ctx.strokeStyle = root.themeTextColor;
                                    ctx.stroke();
                                }

                                ctx.beginPath();
                                ctx.arc(progressX, centerY, knobRadius, 0, Math.PI * 2);
                                ctx.fillStyle = root.themeTextColor;
                                ctx.fill();
                            }

                            onWavePhaseChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()

                            Connections {
                                target: root
                                function onProgressChanged() { popupProgressCanvas.requestPaint(); }
                            }

                            NumberAnimation on wavePhase {
                                from: 0
                                to: numbers.musicProgressWaveLength
                                duration: 900
                                loops: Animation.Infinite
                                running: musicPopup.visible && root.hasPlayer && root.player.isPlaying
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: function(mouse) { root.seekToRatio(mouse.x / width); }
                                onPositionChanged: function(mouse) {
                                    if (pressed) root.seekToRatio(mouse.x / width);
                                }
                            }
                        }

                        Text {
                            text: root.formatTime(root.hasPlayer && root.player.lengthSupported ? root.player.length : 0)
                            color: themeTextColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: numbers.musicTimeFontSize
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: numbers.musicTimeWidth
                        }
                    }

                    RowLayout {
                        id: musicControlsRow

                        x: (parent.width - width) / 2
                        y: musicProgressRow.y + musicProgressRow.height + numbers.musicInfoSpacing
                        width: implicitWidth
                        height: implicitHeight
                        spacing: numbers.musicControlSpacing

                        Text {
                            text: "󰒮"
                            color: root.hasPlayer && root.player.canGoPrevious ? themeTextColor : colors.musicDisabledTextColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: numbers.musicControlFontSize
                            Layout.alignment: Qt.AlignVCenter

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.hasPlayer && root.player.canGoPrevious
                                onClicked: root.player.previous()
                            }
                        }

                        Text {
                            text: root.hasPlayer && root.player.isPlaying ? "" : ""
                            color: themeTextColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: numbers.musicPlayFontSize
                            Layout.alignment: Qt.AlignVCenter

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.hasPlayer && root.player.canTogglePlaying
                                onClicked: root.player.togglePlaying()
                            }
                        }

                        Text {
                            text: "󰒭"
                            color: root.hasPlayer && root.player.canGoNext ? themeTextColor : colors.musicDisabledTextColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: numbers.musicControlFontSize
                            Layout.alignment: Qt.AlignVCenter

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.hasPlayer && root.player.canGoNext
                                onClicked: root.player.next()
                            }
                        }
                    }
                }

                Item {
                    id: lyricPane

                    x: numbers.musicInfoColumnWidth + numbers.musicPopupSpacing
                    y: musicPopupContent.centeredContentY + numbers.musicCoverY
                    width: parent.width - x
                    height: musicInfoColumn.height - numbers.musicLyricHeightReduction
                    clip: true

                    ListView {
                        id: lyricList

                        anchors.fill: parent
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.lyricEntries
                        currentIndex: root.currentLyricIndex
                        highlightMoveDuration: 180
                        preferredHighlightBegin: height * numbers.musicLyricHighlightPosition
                        preferredHighlightEnd: height * numbers.musicLyricHighlightPosition
                        highlightRangeMode: ListView.StrictlyEnforceRange

                        delegate: Text {
                            required property int index
                            required property var modelData

                            width: lyricList.width
                            height: implicitHeight + numbers.musicLyricItemVPadding
                            text: modelData.text
                            color: index === root.currentLyricIndex ? root.themeTextColor : colors.musicLyricLowlightColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: index === root.currentLyricIndex ? numbers.musicLyricActiveFontSize : numbers.musicLyricInactiveFontSize
                            font.bold: index === root.currentLyricIndex
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            lineHeight: numbers.musicLyricLineHeight
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation { duration: numbers.musicLyricAnimationMs }
                            }

                            Behavior on font.pixelSize {
                                NumberAnimation { duration: numbers.musicLyricAnimationMs }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        visible: lyricList.count === 0
                        text: "No lyrics from player"
                        color: colors.musicLyricLowlightColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: numbers.musicLyricInactiveFontSize
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
