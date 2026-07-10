import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var bar

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
                                onClicked: root.bar.controlCenterPage = modelData.key
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.bar.controlCenterPage === "focus" ? 210 : 170
                    radius: 18
                    color: root.bar.sectionPillColor

                    Column {
                        visible: root.bar.controlCenterPage !== "focus"
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
}
