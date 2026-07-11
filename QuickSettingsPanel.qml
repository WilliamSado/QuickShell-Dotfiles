import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var bar

    readonly property int relativeX: popup.relativeX
    readonly property int relativeY: popup.relativeY
    implicitWidth: popup.implicitWidth
    implicitHeight: popup.implicitHeight

    PopupWindow {
        id: popup
        parentWindow: root.bar
        visible: root.bar.quickSettingsOpen || root.bar.quickSettingsClosing
        implicitWidth: root.bar.quickSettingsWidth
        implicitHeight: quickSettingsPanel.implicitHeight
        relativeX: Math.max(root.bar.barSideMargin, root.bar.width - implicitWidth - root.bar.barSideMargin)
        relativeY: root.bar.implicitHeight + 22
        color: "transparent"
        grabFocus: root.bar.quickSettingsOpen
        onClosed: root.bar.closeQuickSettings()
        onVisibleChanged: {
            if (!visible) root.bar.quickSettingsOpen = false;
        }

        Rectangle {
            id: quickSettingsPanel
            width: parent.width
            x: root.bar.quickSettingsOpen ? 0 : parent.width + 28
            opacity: root.bar.quickSettingsOpen ? 1 : 0
            scale: root.bar.quickSettingsOpen ? 1 : 0.96
            transformOrigin: Item.Right
            implicitHeight: quickSettingsColumn.implicitHeight + 36
            radius: 24
            color: root.bar.popupColor
            border.color: root.bar.popupBorderColor
            border.width: 1

            Behavior on x { SpringAnimation { spring: 2.8; damping: 0.30; epsilon: 0.3 } }
            Behavior on opacity { NumberAnimation { duration: Math.max(100, root.bar.popupAnimationMs - 40); easing.type: Easing.OutQuad } }
            Behavior on scale { SpringAnimation { spring: 3.0; damping: 0.34; epsilon: 0.001 } }

            Column {
                id: quickSettingsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    width: parent.width
                    height: 46
                    spacing: 10

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: Qt.formatTime(new Date(), "hh:mm")
                            color: root.bar.textColor
                            font.family: root.bar.barFont
                            font.pixelSize: 28
                        }

                        Text {
                            text: Qt.formatDate(new Date(), "yyyy-MM-dd ddd")
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 21
                        color: closeQuickMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: root.bar.textColor
                            font.family: root.bar.iconFont
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: closeQuickMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.bar.closeQuickSettings()
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: [
                            { icon: "", label: "WiFi", sub: root.bar.networkText(), action: "wifi", active: root.bar.networkText() !== "Disconnected" },
                            { icon: "", label: "Bluetooth", sub: root.bar.bluetoothText(), action: "bluetooth", active: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled },
                            { icon: root.bar.volumeIconText(), label: "Sound", sub: root.bar.volumeMuted ? "Muted" : root.bar.volumePercent + "%", action: "mute", active: !root.bar.volumeMuted },
                            { icon: "󰖨", label: "Display", sub: root.bar.displaySummary(), action: "display", active: true },
                            { icon: root.bar.notificationsDnd ? "󰂛" : "", label: "Notifications", sub: root.bar.unreadNotifications > 0 ? root.bar.unreadNotifications + " unread" : root.bar.notificationsDnd ? "DND" : "Clear", action: "notifications", active: root.bar.unreadNotifications > 0 || root.bar.notificationsDnd },
                            { icon: "󰓅", label: "Power mode", sub: root.bar.powerProfile, action: "power", active: root.bar.powerProfile === "performance" },
                            { icon: "", label: "Launcher", sub: "Control center", action: "launcher", active: root.bar.controlCenterOpen && root.bar.controlCenterPage === "launcher" },
                            { icon: "", label: "Clipboard", sub: "History", action: "clipboard", active: root.bar.controlCenterOpen && root.bar.controlCenterPage === "clipboard" },
                            { icon: "", label: "Capture", sub: "Screenshot", action: "capture", active: root.bar.controlCenterOpen && root.bar.controlCenterPage === "capture" },
                            { icon: "󰖯", label: "Windows", sub: "Manager", action: "windows", active: root.bar.controlCenterOpen && root.bar.controlCenterPage === "windows" },
                            { icon: "󰏖", label: "Maintain", sub: "Updates", action: "maintenance", active: root.bar.controlCenterOpen && root.bar.controlCenterPage === "maintenance" },
                            { icon: "󰒲", label: "Focus", sub: root.bar.focusModeEnabled ? "DND on" : "Off", action: "focus", active: root.bar.focusModeEnabled },
                            { icon: "󰊴", label: "Game mode", sub: root.bar.gameModeEnabled ? "Performance" : "Off", action: "game", active: root.bar.gameModeEnabled },
                            { icon: "󰂄", label: "Animations", sub: root.bar.hyprAnimationsEnabled ? "On" : "Off", action: "animations", active: root.bar.hyprAnimationsEnabled },
                            { icon: "󰖑", label: "Blur", sub: root.bar.hyprBlurEnabled ? "On" : "Off", action: "blur", active: root.bar.hyprBlurEnabled }
                        ]

                        Rectangle {
                            width: (quickSettingsColumn.width - 10) / 2
                            height: 86
                            radius: 22
                            color: modelData.active ? root.bar.activePillColor : root.bar.pillColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: modelData.active ? root.bar.textColor : root.bar.mutedTextColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 22
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: modelData.label
                                        color: root.bar.textColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.sub
                                        color: root.bar.mutedTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.action === "wifi") root.bar.toggleWifiRadio();
                                    else if (modelData.action === "bluetooth") root.bar.toggleBluetoothRadio();
                                    else if (modelData.action === "mute") root.bar.toggleMute();
                                    else if (modelData.action === "display") root.bar.openHyprSettingsFromQuickSettings();
                                    else if (modelData.action === "notifications") root.bar.openNotificationCenter();
                                    else if (modelData.action === "power") {
                                        root.bar.closePopupsExcept("power");
                                        root.bar.powerPopupOpen = true;
                                    }
                                    else if (modelData.action === "launcher") root.bar.openControlCenterFromQuickSettings("launcher");
                                    else if (modelData.action === "clipboard") root.bar.openControlCenterFromQuickSettings("clipboard");
                                    else if (modelData.action === "capture") root.bar.openControlCenterFromQuickSettings("capture");
                                    else if (modelData.action === "windows") root.bar.openControlCenterFromQuickSettings("windows");
                                    else if (modelData.action === "maintenance") root.bar.openControlCenterFromQuickSettings("maintenance");
                                    else if (modelData.action === "focus") root.bar.openControlCenterFromQuickSettings("focus");
                                    else if (modelData.action === "game") root.bar.toggleGameMode();
                                    else if (modelData.action === "animations") root.bar.toggleHyprAnimations();
                                    else if (modelData.action === "blur") root.bar.toggleHyprBlur();
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10

                    RowLayout {
                        width: parent.width
                        height: 42
                        spacing: 12

                        Text {
                            text: root.bar.volumeIconText()
                            color: root.bar.audioTextColor
                            font.family: root.bar.iconFont
                            font.pixelSize: 18
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 10
                            radius: 5
                            color: "#24ffffff"
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                width: parent.width * Math.min(root.bar.volumePercent, 100) / 100
                                height: parent.height
                                radius: parent.radius
                                color: root.bar.audioTextColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) { root.bar.setVolumePercent(mouse.x / width * 100); }
                                onPositionChanged: function(mouse) {
                                    if (pressed) root.bar.setVolumePercent(mouse.x / width * 100);
                                }
                            }
                        }

                        Text {
                            text: root.bar.volumePercent + "%"
                            color: root.bar.audioTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            Layout.preferredWidth: 44
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    RowLayout {
                        width: parent.width
                        height: 42
                        spacing: 12

                        Text {
                            text: "󰃠"
                            color: root.bar.clockTextColor
                            font.family: root.bar.iconFont
                            font.pixelSize: 18
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 10
                            radius: 5
                            color: "#24ffffff"
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                width: parent.width * root.bar.quickBrightnessPercent / 100
                                height: parent.height
                                radius: parent.radius
                                color: root.bar.clockTextColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) { root.bar.setBrightnessPercent(mouse.x / width * 100); }
                                onPositionChanged: function(mouse) {
                                    if (pressed) root.bar.setBrightnessPercent(mouse.x / width * 100);
                                }
                            }
                        }

                        Text {
                            text: root.bar.quickBrightnessPercent + "%"
                            color: root.bar.clockTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            Layout.preferredWidth: 44
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: [
                            { icon: "", label: "Lock", command: ["hyprlock"] },
                            { icon: "", label: "Reload", shell: "hyprctl reload" },
                            { icon: "", label: "Power", command: ["systemctl", "poweroff"] }
                        ]

                        Rectangle {
                            width: (quickSettingsColumn.width - 20) / 3
                            height: 54
                            radius: 18
                            color: quickActionMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: modelData.icon
                                    color: root.bar.textColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.label
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: quickActionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.command) root.bar.runPowerCommand(modelData.command);
                                    else root.bar.runQuickCommand(modelData.shell, modelData.label);
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: root.bar.quickSettingsStatusText
                    color: root.bar.mutedTextColor
                    font.family: root.bar.barFont
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
