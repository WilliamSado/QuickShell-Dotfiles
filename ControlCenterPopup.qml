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

    function pagePanelHeight() {
        if (root.bar.controlCenterPage === "clipboard") return 310;
        if (root.bar.controlCenterPage === "capture") return 292;
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

    function runCapture(command, status) {
        captureStatus = status || "Running";
        root.bar.closeControlCenter();
        captureProc.command = ["sh", "-c", "sleep 0.15; " + command];
        captureProc.running = true;
    }

    function captureFullscreen() {
        var path = capturePath("screenshot", "png");
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && grim " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Fullscreen saved");
    }

    function captureRegion() {
        var path = capturePath("region", "png");
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && area=$(slurp) && [ -n \"$area\" ] && grim -g \"$area\" " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Region saved");
    }

    function captureWindow() {
        var path = capturePath("window", "png");
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && geom=$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"') && [ -n \"$geom\" ] && grim -g \"$geom\" " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Window saved");
    }

    function toggleRecording() {
        if (recording) {
            recordStopProc.running = true;
            recording = false;
            captureStatus = "Recording stopped";
            return;
        }

        var path = capturePath("record", "mp4");
        root.bar.closeControlCenter();
        recordProc.command = ["sh", "-c", "sleep 0.15; mkdir -p " + shellQuote("/home/sado/Videos/Recordings") + " && area=$(slurp) && [ -n \"$area\" ] && wf-recorder -g \"$area\" -f " + shellQuote(path)];
        recordProc.running = true;
        recording = true;
        captureStatus = "Recording";
    }

    function pickColor() {
        runCapture("hyprpicker -a", "Color copied");
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
        grabFocus: false
        onClosed: root.bar.closeControlCenter()
        onVisibleChanged: {
            if (visible && root.bar.controlCenterPage === "clipboard") root.refreshClipboard();
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
            color: root.bar.pillColor
            border.color: "#22ffffff"
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
                                    if (modelData.key === "clipboard") root.refreshClipboard();
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
                        visible: root.bar.controlCenterPage !== "focus" && root.bar.controlCenterPage !== "clipboard" && root.bar.controlCenterPage !== "capture"
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
                                    width: (parent.width - 10) / 2
                                    height: 62
                                    radius: 16
                                    color: modelData.active ? root.bar.activePillColor : captureButtonMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

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
                                                text: modelData.sub
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
            if (exitCode !== 0) root.captureStatus = "Capture failed";
        }
    }

    Process {
        id: recordProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            root.recording = false;
            if (exitCode !== 0 && root.captureStatus === "Recording") root.captureStatus = "Recording failed";
        }
    }

    Process {
        id: recordStopProc
        command: ["pkill", "-INT", "wf-recorder"]
    }
}
