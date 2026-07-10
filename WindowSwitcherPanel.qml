import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var bar
    readonly property int relativeX: popup.relativeX
    readonly property int relativeY: popup.relativeY
    implicitWidth: popup.implicitWidth
    implicitHeight: popup.implicitHeight

    property var windows: []

    function refresh() {
        var out = [];
        var workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (var i = 0; i < workspaces.length; i++) {
            var ws = workspaces[i];
            var toplevels = ws.toplevels ? ws.toplevels.values : [];
            for (var j = 0; j < toplevels.length; j++) {
                var top = toplevels[j];
                var ipc = top.lastIpcObject || {};
                out.push({
                    address: ipc.address || "",
                    app: ipc.class || top.appId || "Window",
                    title: top.title || "",
                    workspace: ws.name || ws.id || "?",
                    floating: !!ipc.floating,
                    fullscreen: !!ipc.fullscreen
                });
            }
        }
        windows = out;
    }

    function dispatchFor(window, command, status) {
        if (!window || window.address.length === 0) return;
        var focus = "hyprctl dispatch focuswindow address:" + window.address;
        bar.runQuickCommand(focus + "; " + command, status);
        if (command.indexOf("killactive") >= 0) Qt.callLater(refresh);
    }

    PopupWindow {
        id: popup
        parentWindow: root.bar
        visible: root.bar.windowSwitcherOpen || root.bar.windowSwitcherClosing
        implicitWidth: 520
        implicitHeight: panel.implicitHeight
        relativeX: Math.max(root.bar.barSideMargin, (root.bar.width - implicitWidth) / 2)
        relativeY: root.bar.implicitHeight + 24
        color: "transparent"
        grabFocus: root.bar.windowSwitcherOpen
        onClosed: root.bar.closeWindowSwitcher()

        FluidPanel {
            id: panel
            width: parent.width
            implicitHeight: content.implicitHeight + 34
            open: root.bar.windowSwitcherOpen
            hiddenY: -18
            shownY: 0
            transformOrigin: Item.Top
            animationMs: root.bar.popupAnimationMs + 70

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 17
                spacing: 12

                RowLayout {
                    width: parent.width
                    height: 36

                    Text {
                        Layout.fillWidth: true
                        text: "Windows"
                        color: root.bar.textColor
                        font.family: root.bar.barFont
                        font.pixelSize: 18
                    }

                    Text {
                        text: root.windows.length + ""
                        color: root.bar.mutedTextColor
                        font.family: root.bar.barFont
                        font.pixelSize: 12
                    }
                }

                Flickable {
                    width: parent.width
                    height: Math.min(460, Math.max(120, list.implicitHeight))
                    contentWidth: width
                    contentHeight: list.implicitHeight
                    clip: true

                    Column {
                        id: list
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.windows

                            Rectangle {
                                id: windowDelegate
                                property var win: modelData

                                width: parent.width
                                height: 74
                                radius: 18
                                color: mouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10

                                    Text {
                                        text: "󰖯"
                                        color: root.bar.textColor
                                        font.family: root.bar.iconFont
                                        font.pixelSize: 18
                                        Layout.preferredWidth: 24
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: modelData.app
                                            color: root.bar.textColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.title
                                            color: root.bar.mutedTextColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: "workspace " + modelData.workspace + (modelData.floating ? " · floating" : "") + (modelData.fullscreen ? " · fullscreen" : "")
                                            color: root.bar.mutedTextColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Row {
                                        spacing: 5

                                        Repeater {
                                            model: [
                                                { icon: "󰖲", command: "hyprctl dispatch movetoworkspace current", status: "Moved window" },
                                                { icon: "󰉈", command: "hyprctl dispatch togglefloating", status: "Toggled floating" },
                                                { icon: "󰊓", command: "hyprctl dispatch fullscreen 1", status: "Toggled fullscreen" },
                                                { icon: "", command: "hyprctl dispatch killactive", status: "Closed window" }
                                            ]

                                            Rectangle {
                                                width: 30
                                                height: 30
                                                radius: 15
                                                color: actionMouse.containsMouse ? root.bar.sectionPillColor : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    color: root.bar.textColor
                                                    font.family: root.bar.iconFont
                                                    font.pixelSize: 13
                                                }

                                                MouseArea {
                                                    id: actionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.dispatchFor(windowDelegate.win, modelData.command, modelData.status)
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: mouse
                                    anchors.fill: parent
                                    anchors.rightMargin: 150
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: {
                                        root.dispatchFor(modelData, "true", "Focused window");
                                        root.bar.closeWindowSwitcher();
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.windows.length === 0
                            text: "No windows"
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
}
