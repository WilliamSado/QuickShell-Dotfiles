import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var bar

    property var clipboardItems: []
    property string clipboardStatus: "Ready"
    property string captureStatus: "Ready"
    property bool recording: false
    property string recordingPath: ""
    property var captureTools: ({})
    property var windowItems: []
    property string windowStatus: "Ready"
    property var launcherApps: []
    property string launcherQuery: ""
    property string launcherStatus: "Ready"
    property int launcherSelectedIndex: 0
    readonly property var launcherBuiltins: [
        { type: "builtin", icon: "󰖟", name: "Web Search", sub: "Search current query", action: "web" },
        { type: "builtin", icon: "", name: "Files", sub: "Open home folder", action: "files" },
        { type: "builtin", icon: "", name: "Terminal", sub: "Open terminal", action: "terminal" },
        { type: "builtin", icon: "󰑓", name: "Reload QS", sub: "Restart Quickshell config", action: "reload" },
        { type: "builtin", icon: "", name: "Lock", sub: "hyprlock", action: "lock" },
        { type: "builtin", icon: "󰒓", name: "Settings", sub: "Hyprland settings", action: "settings" },
        { type: "builtin", icon: "", name: "Capture", sub: "Screenshot / recording", action: "capture" },
        { type: "builtin", icon: "", name: "Clipboard", sub: "Clipboard history", action: "clipboard" },
        { type: "builtin", icon: "󰖯", name: "Windows", sub: "Window manager", action: "windows" },
        { type: "builtin", icon: "󰒲", name: "Focus", sub: "Toggle focus mode", action: "focus" }
    ]

    readonly property int relativeX: popup.relativeX
    readonly property int relativeY: popup.relativeY
    implicitWidth: popup.implicitWidth
    implicitHeight: popup.implicitHeight

    readonly property var pages: [
        { key: "launcher", label: "Launcher", icon: "" },
        { key: "clipboard", label: "Clipboard", icon: "" },
        { key: "capture", label: "Capture", icon: "" },
        { key: "windows", label: "Windows", icon: "󰖯" },
        { key: "focus", label: "Focus", icon: "󰒲" }
    ]

    function pageTitle() {
        for (var i = 0; i < pages.length; i++) {
            if (pages[i].key === root.bar.controlCenterPage) return pages[i].label;
        }
        return "Control Center";
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function cleanDesktopExec(value) {
        return String(value || "")
            .replace(/%[A-Za-z]/g, "")
            .replace(/\s+/g, " ")
            .trim();
    }

    function pagePanelHeight() {
        if (root.bar.controlCenterPage === "launcher") return 350;
        if (root.bar.controlCenterPage === "clipboard") return 310;
        if (root.bar.controlCenterPage === "capture") return 292;
        if (root.bar.controlCenterPage === "windows") return 350;
        if (root.bar.controlCenterPage === "focus") return 210;
        return 170;
    }

    function refreshClipboard() {
        clipboardStatus = "Loading";
        clipboardListProc.running = true;
    }

    function clipboardPreview(line) {
        var text = String(line || "").replace(/^\s*\d+\s+/, "");
        text = text.replace(/\s+/g, " ").trim();
        return text.length > 0 ? text : "Clipboard item";
    }

    function copyClipboardItem(line) {
        if (!line) return;
        clipboardStatus = "Copied";
        clipboardCopyProc.command = ["sh", "-c", "printf '%s' " + shellQuote(line) + " | cliphist decode | wl-copy"];
        clipboardCopyProc.running = true;
    }

    function clearClipboard() {
        clipboardStatus = "Clearing";
        clipboardClearProc.running = true;
    }

    function capturePath(kind, extension) {
        var base = kind === "record" ? "/home/sado/Videos/Recordings" : "/home/sado/Pictures/Screenshots";
        var stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-hhmmss");
        return base + "/" + kind + "-" + stamp + "." + extension;
    }

    function refreshCaptureTools() {
        captureToolsProc.running = true;
    }

    function captureActionEnabled(action) {
        if (action === "fullscreen") return !!captureTools.grim && !!captureTools.wlcopy;
        if (action === "region") return !!captureTools.grim && !!captureTools.slurp && !!captureTools.wlcopy;
        if (action === "window") return !!captureTools.grim && !!captureTools.hyprctl && !!captureTools.jq && !!captureTools.wlcopy;
        if (action === "record") return recording || (!!captureTools.wfrecorder && !!captureTools.slurp);
        if (action === "color") return !!captureTools.hyprpicker;
        return true;
    }

    function runCapture(command, status, path) {
        captureStatus = status || "Running";
        if (path) root.bar.captureLastPath = path;
        root.bar.closeControlCenter();
        captureProc.command = ["sh", "-c", "sleep 0.15; " + command];
        captureProc.running = true;
    }

    function captureFullscreen() {
        var path = capturePath("screenshot", "png");
        if (!captureActionEnabled("fullscreen")) {
            captureStatus = "Missing tool";
            return;
        }
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && grim " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Fullscreen saved", path);
    }

    function captureRegion() {
        var path = capturePath("region", "png");
        if (!captureActionEnabled("region")) {
            captureStatus = "Missing tool";
            return;
        }
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && area=$(slurp) && [ -n \"$area\" ] && grim -g \"$area\" " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Region saved", path);
    }

    function captureWindow() {
        var path = capturePath("window", "png");
        if (!captureActionEnabled("window")) {
            captureStatus = "Missing tool";
            return;
        }
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && geom=$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"') && [ -n \"$geom\" ] && grim -g \"$geom\" " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Window saved", path);
    }

    function toggleRecording() {
        if (recording) {
            recordStopProc.running = true;
            recording = false;
            root.bar.captureLastPath = recordingPath;
            root.bar.persistSettings();
            captureStatus = "Recording stopped";
            return;
        }

        if (!captureActionEnabled("record")) {
            captureStatus = "Missing tool";
            return;
        }

        var path = capturePath("record", "mp4");
        root.bar.closeControlCenter();
        recordProc.command = ["sh", "-c", "sleep 0.15; mkdir -p " + shellQuote("/home/sado/Videos/Recordings") + " && area=$(slurp) && [ -n \"$area\" ] && wf-recorder -g \"$area\" -f " + shellQuote(path)];
        recordProc.running = true;
        recording = true;
        recordingPath = path;
        captureStatus = "Recording";
    }

    function pickColor() {
        if (!captureActionEnabled("color")) {
            captureStatus = "Missing tool";
            return;
        }
        runCapture("hyprpicker -a", "Color copied", "");
    }

    function openCaptureDirectory() {
        if (!root.bar.captureLastPath || root.bar.captureLastPath.length === 0) return;
        captureUtilityProc.command = ["sh", "-c", "xdg-open " + shellQuote(root.bar.captureLastPath.replace(/\/[^\/]+$/, ""))];
        captureUtilityProc.running = true;
    }

    function copyCapturePath() {
        if (!root.bar.captureLastPath || root.bar.captureLastPath.length === 0) return;
        captureUtilityProc.command = ["sh", "-c", "printf '%s' " + shellQuote(root.bar.captureLastPath) + " | wl-copy"];
        captureUtilityProc.running = true;
        captureStatus = "Path copied";
    }

    function refreshWindows() {
        windowStatus = "Loading";
        windowListProc.running = true;
    }

    function parseWindows(text) {
        try {
            var clients = JSON.parse(text || "[]");
            clients.sort(function(a, b) {
                var aw = a.workspace && a.workspace.id !== undefined ? a.workspace.id : 999;
                var bw = b.workspace && b.workspace.id !== undefined ? b.workspace.id : 999;
                if (aw !== bw) return aw - bw;
                return String(a.class || "").localeCompare(String(b.class || ""));
            });
            windowItems = clients;
            windowStatus = clients.length > 0 ? clients.length + " windows" : "No windows";
        } catch (error) {
            windowItems = [];
            windowStatus = "Could not parse windows";
        }
    }

    function windowName(window) {
        if (!window) return "Window";
        var title = String(window.title || "").trim();
        var app = String(window.class || window.initialClass || "").trim();
        if (title.length > 0) return title;
        return app.length > 0 ? app : "Window";
    }

    function windowSubtext(window) {
        if (!window) return "";
        var workspace = window.workspace && window.workspace.id !== undefined ? "ws " + window.workspace.id : "ws --";
        var app = String(window.class || window.initialClass || "app").trim();
        var flags = [];
        if (window.floating) flags.push("floating");
        if (window.fullscreen) flags.push("fullscreen");
        if (window.pinned) flags.push("pinned");
        return workspace + "  " + app + (flags.length > 0 ? "  " + flags.join(" ") : "");
    }

    function runWindowCommand(command, status, closePanel) {
        windowStatus = status || "Running";
        if (closePanel) root.bar.closeControlCenter();
        windowCommandProc.command = ["sh", "-c", command];
        windowCommandProc.running = true;
    }

    function focusWindow(window) {
        if (!window || !window.address) return;
        runWindowCommand("hyprctl dispatch focuswindow address:" + shellQuote(window.address), "Focused", true);
    }

    function closeWindow(window) {
        if (!window || !window.address) return;
        runWindowCommand("hyprctl dispatch closewindow address:" + shellQuote(window.address), "Closed", false);
    }

    function moveWindowToCurrentWorkspace(window) {
        if (!window || !window.address) return;
        runWindowCommand("ws=$(hyprctl activeworkspace -j | jq -r '.id'); hyprctl dispatch movetoworkspacesilent \"$ws,address:" + window.address + "\"", "Moved", false);
    }

    function toggleWindowFloating(window) {
        if (!window || !window.address) return;
        runWindowCommand("hyprctl dispatch togglefloating address:" + shellQuote(window.address), "Floating toggled", false);
    }

    function toggleWindowFullscreen(window) {
        if (!window || !window.address) return;
        runWindowCommand("hyprctl dispatch focuswindow address:" + shellQuote(window.address) + "; hyprctl dispatch fullscreen 1", "Fullscreen toggled", false);
    }

    function toggleWindowPin(window) {
        if (!window || !window.address) return;
        runWindowCommand("hyprctl dispatch focuswindow address:" + shellQuote(window.address) + "; hyprctl dispatch pin", "Pin toggled", false);
    }

    function refreshLauncher() {
        launcherStatus = "Loading apps";
        launcherAppsProc.running = true;
    }

    function parseLauncherApps(text) {
        var items = [];
        var seen = ({});
        var lines = String(text || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("\t");
            if (parts.length < 2) continue;

            var name = parts[0].trim();
            var id = parts[1].trim();
            var desktopPath = parts.length >= 3 ? parts[2].trim() : "";
            var execCommand = parts.length >= 4 ? cleanDesktopExec(parts.slice(3).join("\t")) : "";
            if (name.length === 0 || id.length === 0 || seen[id]) continue;

            seen[id] = true;
            items.push({ type: "app", icon: "󰣆", name: name, sub: id, action: id, desktopPath: desktopPath, execCommand: execCommand });
        }

        launcherApps = items;
        launcherStatus = items.length > 0 ? items.length + " apps" : "No apps";
    }

    function launcherResults() {
        var query = launcherQuery.toLowerCase().trim();
        var source = launcherBuiltins.concat(recentLauncherItems()).concat(launcherWindowItems()).concat(launcherApps);
        if (query.length === 0) return source.slice(0, 18);

        var results = [];
        for (var i = 0; i < source.length; i++) {
            var item = source[i];
            var haystack = (item.name + " " + item.sub + " " + item.action + " " + (item.execCommand || "")).toLowerCase();
            if (haystack.indexOf(query) >= 0) results.push(item);
            if (results.length >= 18) break;
        }
        return results;
    }

    function recentLauncherItems() {
        var items = [];
        var recent = root.bar.recentLauncherApps || [];
        for (var i = 0; i < recent.length; i++) {
            var id = recent[i];
            for (var j = 0; j < launcherApps.length; j++) {
                if (launcherApps[j].action === id) {
                    var app = launcherApps[j];
                    items.push({
                        type: "app",
                        icon: "󰋚",
                        name: app.name,
                        sub: "Recent · " + app.sub,
                        action: app.action,
                        desktopPath: app.desktopPath,
                        execCommand: app.execCommand
                    });
                    break;
                }
            }
        }
        return items;
    }

    function rememberLauncherApp(item) {
        if (!item || item.type !== "app") return;
        var next = [item.action];
        var recent = root.bar.recentLauncherApps || [];
        for (var i = 0; i < recent.length; i++) {
            if (recent[i] !== item.action && next.length < 8) next.push(recent[i]);
        }
        root.bar.recentLauncherApps = next;
        root.bar.persistSettings();
    }

    function launcherWindowItems() {
        var items = [];
        for (var i = 0; i < windowItems.length; i++) {
            var window = windowItems[i];
            if (!window || !window.address) continue;
            items.push({
                type: "window",
                icon: "󰖯",
                name: windowName(window),
                sub: windowSubtext(window),
                action: window.address,
                window: window
            });
        }
        return items;
    }

    function clampLauncherSelection() {
        var results = launcherResults();
        if (results.length === 0) {
            launcherSelectedIndex = 0;
            return;
        }
        launcherSelectedIndex = Math.max(0, Math.min(launcherSelectedIndex, results.length - 1));
    }

    function scrollLauncherSelectionIntoView() {
        if (!launcherFlick || launcherFlick.height <= 0) return;

        var rowHeight = 54;
        var itemHeight = 46;
        var itemTop = launcherSelectedIndex * rowHeight;
        var itemBottom = itemTop + itemHeight;
        var viewTop = launcherFlick.contentY;
        var viewBottom = viewTop + launcherFlick.height;
        var maxY = Math.max(0, launcherFlick.contentHeight - launcherFlick.height);

        if (itemTop < viewTop) {
            launcherFlick.contentY = Math.max(0, itemTop);
        } else if (itemBottom > viewBottom) {
            launcherFlick.contentY = Math.min(maxY, itemBottom - launcherFlick.height);
        }
    }

    function resetLauncherSelection() {
        launcherSelectedIndex = 0;
        if (launcherFlick) launcherFlick.contentY = 0;
    }

    function moveLauncherSelection(delta) {
        var results = launcherResults();
        if (results.length === 0) {
            launcherSelectedIndex = 0;
            return;
        }
        launcherSelectedIndex = (launcherSelectedIndex + delta + results.length) % results.length;
        scrollLauncherSelectionIntoView();
    }

    function launchItem(item) {
        if (!item) return;

        if (item.type === "app") {
            root.bar.closeControlCenter();
            rememberLauncherApp(item);
            var fallback = cleanDesktopExec(item.execCommand);
            var cleanEnv = "env -u ELECTRON_RUN_AS_NODE -u ELECTRON_NO_ATTACH_CONSOLE ";
            var command = "";
            if (fallback.length > 0) {
                command = "setsid -f sh -c " + shellQuote("exec " + cleanEnv + fallback) + " >/tmp/quickshell-launcher.log 2>&1";
            }
            if (item.desktopPath && item.desktopPath.length > 0) {
                command += (command.length > 0 ? " || " : "") + cleanEnv + "gio launch " + shellQuote(item.desktopPath) + " >/tmp/quickshell-launcher.log 2>&1";
            }
            command += (command.length > 0 ? " || " : "") + cleanEnv + "gtk-launch " + shellQuote(item.action) + " >/tmp/quickshell-launcher.log 2>&1";
            launcherStatus = "Launching " + item.name;
            launcherCommandProc.command = ["sh", "-c", command];
            launcherCommandProc.running = true;
            return;
        }

        if (item.type === "window") {
            focusWindow(item.window);
            return;
        }

        if (item.action === "lock") {
            root.bar.closeControlCenter();
            launcherCommandProc.command = ["hyprlock"];
            launcherCommandProc.running = true;
        } else if (item.action === "web") {
            var query = launcherQuery.trim();
            if (query.length === 0) {
                launcherStatus = "Type a query";
                return;
            }
            root.bar.closeControlCenter();
            launcherCommandProc.command = ["sh", "-c", "setsid -f xdg-open " + shellQuote("https://duckduckgo.com/?q=" + encodeURIComponent(query)) + " >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "files") {
            root.bar.closeControlCenter();
            launcherCommandProc.command = ["sh", "-c", "setsid -f xdg-open \"$HOME\" >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "terminal") {
            root.bar.closeControlCenter();
            launcherCommandProc.command = ["sh", "-c", "term=${TERMINAL:-}; if [ -n \"$term\" ]; then setsid -f $term; elif command -v alacritty >/dev/null 2>&1; then setsid -f alacritty; elif command -v kitty >/dev/null 2>&1; then setsid -f kitty; elif command -v foot >/dev/null 2>&1; then setsid -f foot; else exit 1; fi >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "reload") {
            root.bar.closeControlCenter();
            launcherCommandProc.command = ["sh", "-c", "qs kill -p /home/sado/.config/quickshell && qs -p /home/sado/.config/quickshell -d >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "settings") {
            root.bar.openHyprSettings();
        } else if (item.action === "capture") {
            root.bar.controlCenterPage = "capture";
        } else if (item.action === "clipboard") {
            root.bar.controlCenterPage = "clipboard";
            refreshClipboard();
        } else if (item.action === "windows") {
            root.bar.controlCenterPage = "windows";
            refreshWindows();
        } else if (item.action === "focus") {
            root.bar.toggleFocusMode();
        }
    }

    PopupWindow {
        id: popup
        parentWindow: root.bar
        visible: root.bar.controlCenterOpen || root.bar.controlCenterClosing
        implicitWidth: 520
        implicitHeight: controlCenterPanel.implicitHeight
        relativeX: Math.max(root.bar.barSideMargin, root.bar.width - implicitWidth - root.bar.barSideMargin)
        relativeY: root.bar.implicitHeight + 22
        color: "transparent"
        grabFocus: root.bar.controlCenterOpen && root.bar.controlCenterPage === "launcher"
        onClosed: root.bar.closeControlCenter()
        onVisibleChanged: {
            if (visible && root.bar.controlCenterPage === "launcher") {
                root.refreshLauncher();
                root.refreshWindows();
                Qt.callLater(function() { launcherSearch.forceActiveFocus(); });
            }
            if (visible && root.bar.controlCenterPage === "clipboard") root.refreshClipboard();
            if (visible && root.bar.controlCenterPage === "windows") root.refreshWindows();
            if (visible && root.bar.controlCenterPage === "capture") root.refreshCaptureTools();
        }

        Rectangle {
            id: controlCenterPanel
            width: parent.width
            y: root.bar.controlCenterOpen ? 0 : -root.bar.popupAnimationOffset
            opacity: root.bar.controlCenterOpen ? 1 : 0
            scale: root.bar.controlCenterOpen ? 1 : 0.96
            transformOrigin: Item.TopRight
            implicitHeight: controlCenterColumn.implicitHeight + 32
            radius: 22
            color: root.bar.popupColor
            border.color: root.bar.popupBorderColor
            border.width: 1

            Behavior on y { SpringAnimation { spring: 3.0; damping: 0.34; epsilon: 0.2 } }
            Behavior on opacity { NumberAnimation { duration: Math.max(90, root.bar.popupAnimationMs - 50); easing.type: Easing.OutQuad } }
            Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.36; epsilon: 0.001 } }

            Column {
                id: controlCenterColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    width: parent.width
                    height: 34
                    spacing: 10

                    Text {
                        text: "󰒓"
                        color: root.bar.networkTextColor
                        font.family: root.bar.iconFont
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: root.pageTitle()
                        color: root.bar.textColor
                        font.family: root.bar.barFont
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 15
                        color: closeMouse.containsMouse ? root.bar.activePillColor : root.bar.sectionPillColor

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: root.bar.mutedTextColor
                            font.family: root.bar.iconFont
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.bar.closeControlCenter()
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 38
                    spacing: 8

                    Repeater {
                        model: root.pages

                        Rectangle {
                            width: (controlCenterColumn.width - (root.pages.length - 1) * 8) / root.pages.length
                            height: 38
                            radius: 19
                            color: root.bar.controlCenterPage === modelData.key ? root.bar.activePillColor : tabMouse.containsMouse ? root.bar.sectionPillColor : "transparent"

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    color: root.bar.textColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.label
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.bar.controlCenterPage = modelData.key;
                                    if (modelData.key === "launcher") {
                                        root.refreshLauncher();
                                        root.refreshWindows();
                                        Qt.callLater(function() { launcherSearch.forceActiveFocus(); });
                                    }
                                    if (modelData.key === "clipboard") root.refreshClipboard();
                                    if (modelData.key === "windows") root.refreshWindows();
                                    if (modelData.key === "capture") root.refreshCaptureTools();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.pagePanelHeight()
                    radius: 18
                    color: root.bar.sectionPillColor

                    Column {
                        visible: root.bar.controlCenterPage !== "focus" && root.bar.controlCenterPage !== "clipboard" && root.bar.controlCenterPage !== "capture" && root.bar.controlCenterPage !== "windows" && root.bar.controlCenterPage !== "launcher"
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰏫"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.iconFont
                            font.pixelSize: 22
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.pageTitle() + " page"
                            color: root.bar.textColor
                            font.family: root.bar.barFont
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "功能会逐步接入"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 12
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "launcher"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 10

                        Rectangle {
                            width: parent.width
                            height: 42
                            radius: 18
                            color: root.bar.pillColor
                            border.color: launcherSearch.activeFocus ? root.bar.networkTextColor : "transparent"
                            border.width: launcherSearch.activeFocus ? 1 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: ""
                                    color: root.bar.mutedTextColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 14
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                TextInput {
                                    id: launcherSearch
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: root.launcherQuery
                                    color: root.bar.textColor
                                    selectionColor: root.bar.activePillColor
                                    selectedTextColor: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 13
                                    clip: true
                                    onTextChanged: {
                                        root.launcherQuery = text;
                                        root.resetLauncherSelection();
                                    }
                                    Keys.onEscapePressed: root.bar.closeControlCenter()
                                    Keys.onUpPressed: root.moveLauncherSelection(-1)
                                    Keys.onDownPressed: root.moveLauncherSelection(1)
                                    Keys.onReturnPressed: {
                                        var results = root.launcherResults();
                                        root.clampLauncherSelection();
                                        if (results.length > 0) root.launchItem(results[root.launcherSelectedIndex]);
                                    }
                                }

                                Text {
                                    text: root.launcherStatus
                                    color: root.bar.mutedTextColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        Flickable {
                            id: launcherFlick
                            width: parent.width
                            height: 270
                            contentWidth: width
                            contentHeight: launcherList.implicitHeight
                            clip: true

                            Behavior on contentY {
                                NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                            }

                            Column {
                                id: launcherList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.launcherResults()

                                    Rectangle {
                                        property bool isSelected: index === root.launcherSelectedIndex

                                        width: launcherList.width
                                        height: 46
                                        radius: 14
                                        color: isSelected || launcherMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            Text {
                                                text: modelData.icon
                                                color: root.bar.textColor
                                                font.family: root.bar.iconFont
                                                font.pixelSize: 15
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 2

                                                Text {
                                                    width: parent.width
                                                    text: modelData.name
                                                    color: root.bar.textColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    width: parent.width
                                                    text: modelData.sub
                                                    color: root.bar.mutedTextColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: launcherMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.launchItem(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "windows"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            width: parent.width
                            height: 32
                            spacing: 8

                            Text {
                                text: "󰖯"
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.windowStatus
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 30
                                radius: 15
                                color: refreshWindowMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "Refresh"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: refreshWindowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.refreshWindows()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.windowItems.length === 0
                            text: root.windowStatus
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            width: parent.width
                            height: 276
                            contentWidth: width
                            contentHeight: windowList.implicitHeight
                            clip: true
                            visible: root.windowItems.length > 0

                            Column {
                                id: windowList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.windowItems

                                    Rectangle {
                                        id: windowCard
                                        property var windowData: modelData

                                        width: windowList.width
                                        height: 86
                                        radius: 15
                                        color: windowItemMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                        Column {
                                            anchors.left: parent.left
                                            anchors.right: windowActions.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 10
                                            spacing: 4

                                            Text {
                                                width: parent.width
                                                text: root.windowName(modelData)
                                                color: root.bar.textColor
                                                font.family: root.bar.barFont
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                text: root.windowSubtext(modelData)
                                                color: root.bar.mutedTextColor
                                                font.family: root.bar.barFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Row {
                                            id: windowActions
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.rightMargin: 10
                                            spacing: 6

                                            Repeater {
                                                model: [
                                                    { icon: "󰌑", label: "focus", action: "focus" },
                                                    { icon: "󰍉", label: "move", action: "move" },
                                                    { icon: "󰹕", label: "float", action: "float" },
                                                    { icon: "󰊓", label: "full", action: "full" },
                                                    { icon: "󰐃", label: "pin", action: "pin" },
                                                    { icon: "", label: "close", action: "close" }
                                                ]

                                                Rectangle {
                                                    width: 28
                                                    height: 28
                                                    radius: 14
                                                    color: winActionMouse.containsMouse ? root.bar.sectionPillColor : "transparent"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.icon
                                                        color: modelData.action === "close" ? root.bar.cpuTextColor : root.bar.textColor
                                                        font.family: root.bar.iconFont
                                                        font.pixelSize: 12
                                                    }

                                                    MouseArea {
                                                        id: winActionMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: {
                                                            if (modelData.action === "focus") root.focusWindow(windowCard.windowData);
                                                            else if (modelData.action === "move") root.moveWindowToCurrentWorkspace(windowCard.windowData);
                                                            else if (modelData.action === "float") root.toggleWindowFloating(windowCard.windowData);
                                                            else if (modelData.action === "full") root.toggleWindowFullscreen(windowCard.windowData);
                                                            else if (modelData.action === "pin") root.toggleWindowPin(windowCard.windowData);
                                                            else if (modelData.action === "close") root.closeWindow(windowCard.windowData);
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: windowItemMouse
                                            anchors.left: parent.left
                                            anchors.right: windowActions.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            hoverEnabled: true
                                            onClicked: root.focusWindow(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "capture"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            width: parent.width
                            height: 32
                            spacing: 8

                            Text {
                                text: ""
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.captureStatus
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10

                            Repeater {
                                model: [
                                    { icon: "󰹑", label: "Fullscreen", sub: "Save + copy", action: "fullscreen", active: false },
                                    { icon: "󰆞", label: "Region", sub: "Select area", action: "region", active: false },
                                    { icon: "󰖯", label: "Window", sub: "Active window", action: "window", active: false },
                                    { icon: root.recording ? "" : "󰑊", label: root.recording ? "Stop recording" : "Record region", sub: root.recording ? "wf-recorder" : "Select area", action: "record", active: root.recording },
                                    { icon: "", label: "Color picker", sub: "Copy color", action: "color", active: false }
                                ]

                                Rectangle {
                                    property bool actionEnabled: root.captureActionEnabled(modelData.action)

                                    width: (parent.width - 10) / 2
                                    height: 62
                                    radius: 16
                                    opacity: actionEnabled ? 1 : 0.45
                                    color: modelData.active ? root.bar.activePillColor : captureButtonMouse.containsMouse && actionEnabled ? root.bar.activePillColor : root.bar.pillColor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: modelData.icon
                                            color: root.bar.textColor
                                            font.family: root.bar.iconFont
                                            font.pixelSize: 17
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 2

                                            Text {
                                                width: parent.width
                                                text: modelData.label
                                                color: root.bar.textColor
                                                font.family: root.bar.barFont
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                text: actionEnabled ? modelData.sub : "missing tool"
                                                color: root.bar.mutedTextColor
                                                font.family: root.bar.barFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: captureButtonMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (!parent.actionEnabled) {
                                                root.captureStatus = "Missing tool";
                                                return;
                                            }
                                            if (modelData.action === "fullscreen") root.captureFullscreen();
                                            else if (modelData.action === "region") root.captureRegion();
                                            else if (modelData.action === "window") root.captureWindow();
                                            else if (modelData.action === "record") root.toggleRecording();
                                            else if (modelData.action === "color") root.pickColor();
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 56
                            radius: 16
                            color: root.bar.pillColor
                            visible: root.bar.captureLastPath.length > 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Text {
                                    text: "󰉋"
                                    color: root.bar.networkTextColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 15
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: root.bar.captureLastPath.replace(/^.*\//, "")
                                        color: root.bar.textColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.bar.captureLastPath
                                        color: root.bar.mutedTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 10
                                        elide: Text.ElideMiddle
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: openCaptureDirMouse.containsMouse ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        color: root.bar.textColor
                                        font.family: root.bar.iconFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: openCaptureDirMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.openCaptureDirectory()
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: copyCapturePathMouse.containsMouse ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        color: root.bar.textColor
                                        font.family: root.bar.iconFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: copyCapturePathMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.copyCapturePath()
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "clipboard"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            width: parent.width
                            height: 32
                            spacing: 8

                            Text {
                                text: ""
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.clipboardStatus
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 30
                                radius: 15
                                color: refreshClipMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "Refresh"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: refreshClipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.refreshClipboard()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 58
                                Layout.preferredHeight: 30
                                radius: 15
                                color: clearClipMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "Clear"
                                    color: root.bar.mutedTextColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: clearClipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.clearClipboard()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.clipboardItems.length === 0
                            text: root.clipboardStatus === "Ready" ? "No clipboard history" : root.clipboardStatus
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            width: parent.width
                            height: 236
                            contentWidth: width
                            contentHeight: clipboardList.implicitHeight
                            clip: true
                            visible: root.clipboardItems.length > 0

                            Column {
                                id: clipboardList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.clipboardItems

                                    Rectangle {
                                        width: clipboardList.width
                                        height: 42
                                        radius: 13
                                        color: clipItemMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                        Text {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            text: root.clipboardPreview(modelData)
                                            color: root.bar.textColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            id: clipItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.copyClipboardItem(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "focus"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            width: parent.width
                            text: "Focus Mode"
                            color: root.bar.textColor
                            font.family: root.bar.barFont
                            font.pixelSize: 15
                        }

                        Text {
                            width: parent.width
                            text: root.bar.focusModeEnabled ? "勿扰已开启，媒体胶囊按设置隐藏" : "开启后会启用勿扰，并可隐藏媒体胶囊"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            width: parent.width
                            height: 44
                            spacing: 10

                            Text {
                                text: "勿扰模式"
                                color: root.bar.textColor
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 32
                                radius: 16
                                color: root.bar.focusModeEnabled ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.bar.focusModeEnabled ? "On" : "Off"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.bar.toggleFocusMode()
                                }
                            }
                        }

                        RowLayout {
                            width: parent.width
                            height: 44
                            spacing: 10

                            Text {
                                text: "隐藏媒体胶囊"
                                color: root.bar.textColor
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 32
                                radius: 16
                                color: root.bar.mediaHiddenInFocus ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.bar.mediaHiddenInFocus ? "On" : "Off"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.bar.toggleMediaHiddenInFocus()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: clipboardListProc
        command: ["sh", "-c", "if command -v cliphist >/dev/null 2>&1; then cliphist list | head -n 40; else exit 127; fi"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var lines = String(text || "").split("\n").filter(function(line) {
                    return line.trim().length > 0;
                });
                root.clipboardItems = lines;
                root.clipboardStatus = lines.length > 0 ? lines.length + " items" : "No clipboard history";
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.clipboardItems = [];
                root.clipboardStatus = "cliphist unavailable";
            }
        }
    }

    Process {
        id: clipboardCopyProc
        command: ["sh", "-c", "true"]
    }

    Process {
        id: clipboardClearProc
        command: ["sh", "-c", "if command -v cliphist >/dev/null 2>&1; then cliphist wipe; else exit 127; fi"]
        onExited: function(exitCode) {
            root.clipboardItems = [];
            root.clipboardStatus = exitCode === 0 ? "Cleared" : "cliphist unavailable";
        }
    }

    Process {
        id: captureProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.captureStatus = "Capture failed";
            } else if (root.bar.captureLastPath.length > 0) {
                root.bar.persistSettings();
            }
        }
    }

    Process {
        id: captureUtilityProc
        command: ["sh", "-c", "true"]
    }

    Process {
        id: captureToolsProc
        command: ["sh", "-c", "for tool in grim slurp wf-recorder hyprpicker wl-copy hyprctl jq; do command -v \"$tool\" >/dev/null 2>&1 && printf '%s=1\\n' \"$tool\" || printf '%s=0\\n' \"$tool\"; done"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var tools = ({});
                var lines = String(text || "").split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("=");
                    if (parts.length === 2) tools[parts[0].replace("-", "")] = parts[1].trim() === "1";
                }
                root.captureTools = tools;
                root.captureStatus = "Ready";
            }
        }
    }

    Process {
        id: recordProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            root.recording = false;
            if (exitCode !== 0 && root.captureStatus === "Recording") {
                root.captureStatus = "Recording failed";
            } else if (root.recordingPath.length > 0) {
                root.bar.captureLastPath = root.recordingPath;
                root.bar.persistSettings();
            }
        }
    }

    Process {
        id: recordStopProc
        command: ["pkill", "-INT", "wf-recorder"]
    }

    Process {
        id: windowListProc
        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseWindows(text)
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.windowItems = [];
                root.windowStatus = "Could not read windows";
            }
        }
    }

    Process {
        id: windowCommandProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            if (exitCode !== 0) root.windowStatus = "Window action failed";
            refreshWindowsTimer.restart();
        }
    }

    Timer {
        id: refreshWindowsTimer
        interval: 220
        repeat: false
        onTriggered: root.refreshWindows()
    }

    Process {
        id: launcherAppsProc
        command: ["sh", "-c", "for dir in /usr/share/applications \"$HOME/.local/share/applications\"; do [ -d \"$dir\" ] || continue; find \"$dir\" -maxdepth 1 -name '*.desktop' -type f; done | while IFS= read -r file; do if grep -qE '^(NoDisplay|Hidden)=true' \"$file\"; then continue; fi; name=$(grep -m1 '^Name=' \"$file\" | cut -d= -f2-); id=$(basename \"$file\" .desktop); exec_line=$(grep -m1 '^Exec=' \"$file\" | cut -d= -f2-); [ -n \"$name\" ] && printf '%s\\t%s\\t%s\\t%s\\n' \"$name\" \"$id\" \"$file\" \"$exec_line\"; done | sort -fu | head -n 180"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseLauncherApps(text)
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.launcherApps = [];
                root.launcherStatus = "Could not read apps";
            }
        }
    }

    Process {
        id: launcherCommandProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            if (exitCode !== 0) root.launcherStatus = "Launch failed";
        }
    }
}
