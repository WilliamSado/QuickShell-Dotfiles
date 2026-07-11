import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var bar

    readonly property var player: activePlayer()
    readonly property bool hasPlayer: player !== null && player !== undefined
    property real playbackPosition: 0

    function textContainsAny(text, keywords) {
        if (!text || !keywords) return false;
        for (var i = 0; i < keywords.length; i++) {
            if (text.indexOf(keywords[i]) >= 0) return true;
        }
        return false;
    }

    function playerAllowed(candidate) {
        if (!candidate) return false;
        var appText = [
            candidate.identity || "",
            candidate.desktopEntry || "",
            candidate.dbusName || ""
        ].join(" ").toLowerCase();

        if (textContainsAny(appText, ["yesplaymusic", "spotify"])) return true;
        if (!textContainsAny(appText, ["chrome", "chromium", "firefox", "zen", "brave", "edge"])) return false;

        var metadata = candidate.metadata || ({});
        var mediaText = [
            candidate.trackTitle || "",
            candidate.trackArtist || "",
            metadata["xesam:url"] || "",
            metadata["mpris:trackid"] || "",
            metadata["url"] || ""
        ].join(" ").toLowerCase();
        return textContainsAny(mediaText, ["music.youtube.com", "youtube music", "ytmusic", "open.spotify.com", "spotify.com"]);
    }

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

    function musicProgress() {
        if (!hasPlayer || !player.lengthSupported || player.length <= 0) return 0;
        return Math.max(0, Math.min(1, playbackPosition / player.length));
    }

    function todoActiveItems() {
        var source = bar.todoItems || [];
        var items = [];
        for (var i = 0; i < source.length; i++) {
            if (!source[i].done) items.push(source[i]);
            if (items.length >= 3) break;
        }
        return items;
    }

    function statusItems() {
        var items = [];
        if (bar.focusModeEnabled) items.push({ icon: "󰒲", label: bar.focusTimerRunning ? bar.focusTimerText() : "Focus" });
        if (bar.gameModeEnabled) items.push({ icon: "󰊴", label: "Game" });
        if (bar.notificationsDnd) items.push({ icon: "󰂛", label: "DND" });
        if (bar.wallpaperRotationEnabled) items.push({ icon: "󰸉", label: bar.wallpaperRotationRandom ? "Random" : "Rotate" });
        if (bar.unreadNotifications > 0) items.push({ icon: "", label: String(bar.unreadNotifications) });
        if (items.length === 0) items.push({ icon: "󰋽", label: bar.currentThemeName });
        return items.slice(0, 4);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.hasPlayer
        onTriggered: {
            if (root.hasPlayer && root.player.positionSupported) root.playbackPosition = root.player.position;
        }
    }

    PanelWindow {
        id: islandWindow

        anchors.top: true
        anchors.left: true
        anchors.right: true
        margins.top: root.bar.implicitHeight + 18
        implicitHeight: 58
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            id: island

            width: Math.min(430, Math.max(210, islandRow.implicitWidth + 30))
            height: 44
            x: (islandWindow.width - width) / 2
            y: 0
            radius: 22
            color: root.bar.popupColor
            border.color: root.bar.popupBorderColor
            border.width: 1

            Behavior on width { SpringAnimation { spring: 3.0; damping: 0.36; epsilon: 0.2 } }

            Row {
                id: islandRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: root.statusItems()

                    Rectangle {
                        width: statusText.implicitWidth + 28
                        height: 28
                        radius: 14
                        color: root.bar.pillColor

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: statusText
                                text: modelData.label
                                color: root.bar.textColor
                                font.family: root.bar.barFont
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.bar.openControlCenter("focus")
            }
        }
    }

    PanelWindow {
        id: musicWindow

        anchors.left: true
        anchors.bottom: true
        margins.left: 28
        margins.bottom: 34
        implicitWidth: 320
        implicitHeight: 110
        visible: root.hasPlayer && !(root.bar.focusModeEnabled && root.bar.mediaHiddenInFocus)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: root.bar.popupColor
            border.color: root.bar.popupBorderColor
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    radius: 18
                    color: root.bar.activePillColor
                    clip: true

                    Image {
                        id: coverImage
                        anchors.fill: parent
                        source: root.hasPlayer ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !coverImage.visible
                        text: ""
                        color: root.bar.audioTextColor
                        font.family: root.bar.iconFont
                        font.pixelSize: 24
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: root.hasPlayer && root.player.trackTitle ? root.player.trackTitle : "Media"
                        color: root.bar.textColor
                        font.family: root.bar.barFont
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hasPlayer && root.player.trackArtist ? root.player.trackArtist : root.hasPlayer ? root.player.identity : ""
                        color: root.bar.mutedTextColor
                        font.family: root.bar.barFont
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5
                        radius: 3
                        color: root.bar.pillColor

                        Rectangle {
                            width: parent.width * root.musicProgress()
                            height: parent.height
                            radius: parent.radius
                            color: root.bar.audioTextColor
                        }
                    }

                    Row {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { icon: "", enabled: root.hasPlayer && root.player.canGoPrevious, action: "prev" },
                                { icon: root.hasPlayer && root.player.isPlaying ? "" : "", enabled: root.hasPlayer && root.player.canTogglePlaying, action: "play" },
                                { icon: "", enabled: root.hasPlayer && root.player.canGoNext, action: "next" }
                            ]

                            Rectangle {
                                width: 30
                                height: 24
                                radius: 12
                                opacity: modelData.enabled ? 1 : 0.45
                                color: musicControlMouse.containsMouse && modelData.enabled ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: root.bar.textColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: musicControlMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (!modelData.enabled) return;
                                        if (modelData.action === "prev") root.player.previous();
                                        else if (modelData.action === "play") root.player.togglePlaying();
                                        else if (modelData.action === "next") root.player.next();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.bottomMargin: 34
                onClicked: {
                    if (root.hasPlayer && root.player.canTogglePlaying) root.player.togglePlaying();
                }
            }
        }
    }

    PanelWindow {
        id: todoWindow

        anchors.right: true
        anchors.bottom: true
        margins.right: 28
        margins.bottom: 34
        implicitWidth: 300
        implicitHeight: 132
        visible: root.todoActiveItems().length > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: root.bar.popupColor
            border.color: root.bar.popupBorderColor
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 9

                RowLayout {
                    width: parent.width
                    height: 24

                    Text {
                        text: "󰄱 Today"
                        color: root.bar.textColor
                        font.family: root.bar.barFont
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.todoActiveItems().length + " active"
                        color: root.bar.mutedTextColor
                        font.family: root.bar.barFont
                        font.pixelSize: 10
                    }
                }

                Repeater {
                    model: root.todoActiveItems()

                    RowLayout {
                        width: parent.width
                        height: 22
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: root.bar.networkTextColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.text
                            color: root.bar.textColor
                            font.family: root.bar.barFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.bar.openControlCenter("todo")
            }
        }
    }
}
