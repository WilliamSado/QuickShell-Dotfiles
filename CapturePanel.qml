import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var bar
    readonly property int relativeX: popup.relativeX
    readonly property int relativeY: popup.relativeY
    implicitWidth: popup.implicitWidth
    implicitHeight: popup.implicitHeight

    property bool recording: false

    function screenshotDirCommand() {
        return "mkdir -p \"$HOME/Pictures/Screenshots\"; file=\"$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png\"; ";
    }

    function recordingDirCommand() {
        return "mkdir -p \"$HOME/Videos/Recordings\"; file=\"$HOME/Videos/Recordings/$(date +%Y%m%d-%H%M%S).mp4\"; ";
    }

    function runCapture(command, status) {
        bar.runQuickCommand(command, status);
        if (status.indexOf("Recording") !== 0) bar.closeCapturePanel();
    }

    PopupWindow {
        id: popup
        parentWindow: root.bar
        visible: root.bar.captureOpen || root.bar.captureClosing
        implicitWidth: 390
        implicitHeight: panel.implicitHeight
        relativeX: Math.max(root.bar.barSideMargin, root.bar.width - implicitWidth - root.bar.barSideMargin)
        relativeY: root.bar.implicitHeight + 24
        color: "transparent"
        grabFocus: false
        onClosed: root.bar.closeCapturePanel()

        FluidPanel {
            id: panel
            width: parent.width
            implicitHeight: content.implicitHeight + 34
            open: root.bar.captureOpen
            hiddenX: 22
            shownX: 0
            animationMs: root.bar.popupAnimationMs + 70

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 17
                spacing: 12

                Text {
                    width: parent.width
                    text: "Capture"
                    color: root.bar.textColor
                    font.family: root.bar.barFont
                    font.pixelSize: 18
                }

                Grid {
                    width: parent.width
                    columns: 2
                    rowSpacing: 9
                    columnSpacing: 9

                    Repeater {
                        model: [
                            { icon: "󰹑", label: "Fullscreen", command: root.screenshotDirCommand() + "grim \"$file\" && wl-copy < \"$file\"", status: "Screenshot saved" },
                            { icon: "󰩭", label: "Region", command: root.screenshotDirCommand() + "grim -g \"$(slurp)\" \"$file\" && wl-copy < \"$file\"", status: "Region saved" },
                            { icon: "󱂬", label: "Window", command: root.screenshotDirCommand() + "geom=$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"'); grim -g \"$geom\" \"$file\" && wl-copy < \"$file\"", status: "Window saved" },
                            { icon: root.recording ? "" : "", label: root.recording ? "Stop record" : "Region record", command: "", status: "Recording" },
                            { icon: "󰈋", label: "Pick color", command: "hyprpicker -a", status: "Color copied" }
                        ]

                        Rectangle {
                            width: (content.width - 9) / 2
                            height: 72
                            radius: 20
                            color: mouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    color: root.bar.textColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 20
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.label === "Region record") {
                                        root.recording = true;
                                        root.bar.quickSettingsStatusText = "Recording started";
                                        recordProc.command = ["sh", "-c", root.recordingDirCommand() + "wf-recorder -g \"$(slurp)\" -f \"$file\""];
                                        recordProc.running = true;
                                    } else if (modelData.label === "Stop record") {
                                        stopRecordProc.running = true;
                                    } else {
                                        root.runCapture(modelData.command, modelData.status);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: recordProc
        command: ["sh", "-c", "true"]
        onExited: {
            root.recording = false;
            root.bar.quickSettingsStatusText = "Recording stopped";
        }
    }

    Process {
        id: stopRecordProc
        command: ["sh", "-c", "pkill -INT wf-recorder"]
        onExited: {
            root.recording = false;
            root.bar.quickSettingsStatusText = "Recording stopped";
        }
    }
}
