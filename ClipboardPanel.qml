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

    property var entries: []

    function refresh() {
        listProc.running = true;
    }

    function copyEntry(entry) {
        if (!entry) return;
        bar.runQuickCommand("cliphist decode " + bar.shellQuote(entry.id) + " | wl-copy", "Clipboard restored");
        bar.closeClipboardPanel();
    }

    PopupWindow {
        id: popup
        parentWindow: root.bar
        visible: root.bar.clipboardOpen || root.bar.clipboardClosing
        implicitWidth: 430
        implicitHeight: panel.implicitHeight
        relativeX: Math.max(root.bar.barSideMargin, root.bar.width - implicitWidth - root.bar.barSideMargin)
        relativeY: root.bar.implicitHeight + 24
        color: "transparent"
        grabFocus: false
        onClosed: root.bar.closeClipboardPanel()

        FluidPanel {
            id: panel
            width: parent.width
            implicitHeight: content.implicitHeight + 34
            open: root.bar.clipboardOpen
            hiddenX: 22
            shownX: 0
            animationMs: root.bar.popupAnimationMs + 70

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 17
                spacing: 13

                RowLayout {
                    width: parent.width
                    height: 38

                    Text {
                        Layout.fillWidth: true
                        text: "Clipboard"
                        color: root.bar.textColor
                        font.family: root.bar.barFont
                        font.pixelSize: 18
                    }

                    Rectangle {
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 34
                        radius: 17
                        color: clearMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                        Text {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: root.bar.textColor
                            font.family: root.bar.barFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.bar.runQuickCommand("cliphist wipe", "Clipboard cleared");
                                root.entries = [];
                            }
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: Math.min(420, Math.max(120, list.implicitHeight))
                    contentWidth: width
                    contentHeight: list.implicitHeight
                    clip: true

                    Column {
                        id: list
                        width: parent.width
                        spacing: 7

                        Repeater {
                            model: root.entries

                            Rectangle {
                                width: parent.width
                                height: 48
                                radius: 16
                                color: mouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 13
                                    anchors.rightMargin: 13
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData.preview
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: mouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.copyEntry(modelData)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.entries.length === 0
                            text: "No clipboard history"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    Process {
        id: listProc
        command: ["sh", "-c", "cliphist list | head -40"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var lines = text.trim().length > 0 ? text.trim().split("\n") : [];
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    var split = line.indexOf("\t");
                    var id = split >= 0 ? line.slice(0, split) : line.split(/\s+/)[0];
                    var preview = split >= 0 ? line.slice(split + 1) : line.replace(id, "").trim();
                    out.push({ id: id, preview: preview.length > 0 ? preview : id });
                }
                root.entries = out;
            }
        }
    }
}
