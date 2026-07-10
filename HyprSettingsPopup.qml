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

    function focusWallpaperInput() {
        wallpaperInput.forceActiveFocus();
    }

    PopupWindow {
        id: popup
        parentWindow: root.bar
        visible: root.bar.hyprSettingsOpen || root.bar.hyprSettingsClosing
        implicitWidth: 620
        implicitHeight: hyprSettingsContent.implicitHeight
        relativeX: Math.max(root.bar.barSideMargin, (root.bar.width - implicitWidth) / 2)
        relativeY: root.bar.implicitHeight + 14
        color: "transparent"
        grabFocus: root.bar.hyprSettingsOpen
        onClosed: root.bar.closeHyprSettings()
        onVisibleChanged: {
            if (!visible) root.bar.hyprSettingsOpen = false;
            if (visible) {
                root.bar.refreshHyprMonitors();
                Qt.callLater(function() {
                    wallpaperInput.forceActiveFocus();
                });
            }
        }

        Rectangle {
            id: hyprSettingsContent
            width: parent.width
            y: root.bar.hyprSettingsOpen ? 0 : -root.bar.popupAnimationOffset
            opacity: root.bar.hyprSettingsOpen ? 1 : 0
            scale: root.bar.hyprSettingsOpen ? 1 : 0.96
            transformOrigin: Item.Top
            implicitHeight: hyprSettingsColumn.implicitHeight + 28
            radius: 18
            color: "#cc121212"
            border.color: "#22ffffff"
            border.width: 1

            Behavior on y { NumberAnimation { duration: root.bar.popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: root.bar.popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: root.bar.popupAnimationMs; easing.type: Easing.OutCubic } }

            Column {
                id: hyprSettingsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    width: parent.width
                    height: 32
                    spacing: 10

                    Text {
                        text: ""
                        color: root.bar.networkTextColor
                        font.family: root.bar.iconFont
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "Hyprland Settings"
                        color: root.bar.textColor
                        font.family: root.bar.barFont
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: hyprStatusLabel.implicitWidth + 18
                        Layout.preferredHeight: 28
                        radius: 14
                        color: root.bar.pillColor

                        Text {
                            id: hyprStatusLabel
                            anchors.centerIn: parent
                            text: root.bar.hyprStatusText
                            color: root.bar.networkTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 15
                        color: closeSettingsMouse.containsMouse ? "#44282828" : root.bar.pillColor

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: root.bar.mutedTextColor
                            font.family: root.bar.iconFont
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: closeSettingsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.bar.closeHyprSettings()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Wallpaper"
                        color: root.bar.mutedTextColor
                        font.family: root.bar.barFont
                        font.pixelSize: 13
                    }

                    RowLayout {
                        width: parent.width
                        height: 36
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 12
                            color: root.bar.pillColor
                            border.color: "#18ffffff"
                            border.width: 1

                            TextInput {
                                id: wallpaperInput
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                text: root.bar.hyprWallpaperPath
                                focus: root.bar.hyprSettingsOpen
                                activeFocusOnPress: true
                                color: root.bar.textColor
                                selectionColor: root.bar.networkTextColor
                                selectedTextColor: "#121212"
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                onEditingFinished: root.bar.hyprWallpaperPath = text
                                Keys.onReturnPressed: {
                                    root.bar.hyprWallpaperPath = text;
                                    root.bar.applyWallpaper();
                                }
                                Keys.onPressed: function(event) {
                                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
                                        root.bar.pasteClipboardInto(wallpaperInput);
                                        event.accepted = true;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 86
                            Layout.preferredHeight: 36
                            radius: 18
                            color: wallpaperApplyMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                            Text {
                                anchors.centerIn: parent
                                text: "Apply"
                                color: root.bar.networkTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: wallpaperApplyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.bar.hyprWallpaperPath = root.bar.cleanInputPath(wallpaperInput.text);
                                    wallpaperInput.text = root.bar.hyprWallpaperPath;
                                    root.bar.applyWallpaper();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                }

                Column {
                    width: parent.width
                    spacing: 8

                    RowLayout {
                        width: parent.width
                        height: 28
                        spacing: 8

                        Text {
                            text: "Display"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: root.bar.hyprMonitorText
                            color: root.bar.textColor
                            font.family: root.bar.barFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Grid {
                        width: parent.width
                        columns: 4
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: [
                                { label: "Refresh", mode: "refresh" },
                                { label: "Preferred", mode: "preferred" },
                                { label: "1920x1080", mode: "1920x1080@60" },
                                { label: "2560x1440", mode: "2560x1440@60" },
                                { label: "3440x1440", mode: "3440x1440@144" },
                                { label: "3840x2160", mode: "3840x2160@60" },
                                { label: "Scale 1.0", scale: 1.0 },
                                { label: "Scale 1.25", scale: 1.25 },
                                { label: "Scale 1.5", scale: 1.5 },
                                { label: "Scale 1.75", scale: 1.75 },
                                { label: "Scale 2.0", scale: 2.0 },
                                { label: "Reload", mode: "reload" }
                            ]

                            Rectangle {
                                width: (hyprSettingsColumn.width - 24) / 4
                                height: 34
                                radius: 17
                                color: hyprDisplayMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.bar.networkTextColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: hyprDisplayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (modelData.mode === "refresh") root.bar.refreshHyprMonitors();
                                        else if (modelData.mode === "reload") root.bar.runHyprCommand("hyprctl reload", "Reloading");
                                        else if (modelData.mode) root.bar.applyMonitorMode(modelData.mode);
                                        else root.bar.applyMonitorScale(modelData.scale);
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        height: 34
                        spacing: 8

                        Text {
                            text: "Refresh rate"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 12
                            Layout.preferredWidth: 92
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Repeater {
                            model: root.bar.hyprRefreshRates

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 17
                                color: Math.round(root.bar.hyprMonitorRefreshRate) === modelData ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "Hz"
                                    color: root.bar.networkTextColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.bar.applyMonitorRefresh(modelData)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                }

                RowLayout {
                    width: parent.width
                    height: 72
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: root.bar.pillColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "Gaps"
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.bar.hyprGaps
                                color: root.bar.textColor
                                font.family: root.bar.barFont
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: 36
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Repeater {
                                model: [
                                    { label: "-", delta: -1 },
                                    { label: "+", delta: 1 },
                                    { label: "Apply", apply: true }
                                ]

                                Rectangle {
                                    Layout.preferredWidth: modelData.apply ? 72 : 34
                                    Layout.preferredHeight: 34
                                    radius: 17
                                    color: gapsMouse.containsMouse ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: root.bar.networkTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 13
                                    }

                                    MouseArea {
                                        id: gapsMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (modelData.apply) root.bar.applyHyprSpacing();
                                            else root.bar.hyprGaps = Math.max(0, Math.min(30, root.bar.hyprGaps + modelData.delta));
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: root.bar.pillColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "Rounding"
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.bar.hyprRounding
                                color: root.bar.textColor
                                font.family: root.bar.barFont
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: 36
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Repeater {
                                model: [
                                    { label: "-", delta: -1 },
                                    { label: "+", delta: 1 },
                                    { label: "Apply", apply: true }
                                ]

                                Rectangle {
                                    Layout.preferredWidth: modelData.apply ? 72 : 34
                                    Layout.preferredHeight: 34
                                    radius: 17
                                    color: roundingMouse.containsMouse ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: root.bar.networkTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 13
                                    }

                                    MouseArea {
                                        id: roundingMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (modelData.apply) root.bar.applyHyprRounding();
                                            else root.bar.hyprRounding = Math.max(0, Math.min(30, root.bar.hyprRounding + modelData.delta));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    height: 38
                    spacing: 8

                    Repeater {
                        model: [
                            { label: root.bar.hyprAnimationsEnabled ? "Animations on" : "Animations off", action: "animations" },
                            { label: root.bar.hyprBlurEnabled ? "Blur on" : "Blur off", action: "blur" },
                            { label: "Reload Hyprland", action: "reload" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 19
                            color: effectsMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.bar.networkTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: effectsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.action === "animations") root.bar.toggleHyprAnimations();
                                    else if (modelData.action === "blur") root.bar.toggleHyprBlur();
                                    else root.bar.runHyprCommand("hyprctl reload", "Reloading");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
