import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import "config" as Config

Item {
    id: root

    required property var bar
    property string activeTab: "display"

    Config.ThemePresets { id: themePresets }

    readonly property int relativeX: popup.relativeX
    readonly property int relativeY: popup.relativeY
    implicitWidth: popup.implicitWidth
    implicitHeight: popup.implicitHeight

    function focusWallpaperInput() {
        if (activeTab !== "theme") return;
        wallpaperInput.forceActiveFocus();
    }

    function openTab(tab) {
        activeTab = tab;
        if (tab === "display") {
            root.bar.refreshHyprMonitors();
        } else if (tab === "wifi") {
            var wifiDevice = root.bar.networkDeviceByType(DeviceType.Wifi);
            if (wifiDevice) wifiDevice.scannerEnabled = true;
        } else if (tab === "bluetooth") {
            root.bar.updateBluetoothNameMap();
        } else if (tab === "theme") {
            Qt.callLater(function() {
                wallpaperInput.forceActiveFocus();
            });
        }
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
                    root.focusWallpaperInput();
                });
            }
        }

        Rectangle {
            id: hyprSettingsContent
            width: parent.width
            y: root.bar.hyprSettingsOpen ? 0 : -root.bar.popupAnimationOffset
            opacity: root.bar.hyprSettingsOpen ? 1 : 0
            scale: root.bar.hyprSettingsOpen ? 1 : 0.9
            transformOrigin: Item.Top
            implicitHeight: hyprSettingsColumn.implicitHeight + 28
            radius: 18
            color: root.bar.popupColor
            border.color: root.bar.popupBorderColor
            border.width: 1

            Behavior on y { SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.2 } }
            Behavior on opacity { NumberAnimation { duration: Math.max(90, root.bar.popupAnimationMs - 60); easing.type: Easing.OutQuad } }
            Behavior on scale { SpringAnimation { spring: 3.4; damping: 0.34; epsilon: 0.001 } }

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

                RowLayout {
                    width: parent.width
                    height: 36
                    spacing: 8

                    Repeater {
                        model: [
                            { key: "wifi", icon: "", label: "WiFi" },
                            { key: "bluetooth", icon: "", label: "Bluetooth" },
                            { key: "display", icon: "󰍹", label: "Display" },
                            { key: "theme", icon: "󰸉", label: "Theme" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 18
                            color: root.activeTab === modelData.key ? root.bar.activePillColor : tabMouse.containsMouse ? "#44282828" : root.bar.pillColor

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: modelData.icon
                                    color: root.activeTab === modelData.key ? root.bar.textColor : root.bar.mutedTextColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.label
                                    color: root.activeTab === modelData.key ? root.bar.textColor : root.bar.mutedTextColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.openTab(modelData.key)
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
                    visible: root.activeTab === "theme"

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
                                focus: root.bar.hyprSettingsOpen && root.activeTab === "theme"
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

                    RowLayout {
                        width: parent.width
                        height: 34
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 17
                            color: root.bar.pillColor
                            border.color: "#18ffffff"
                            border.width: 1

                            TextInput {
                                id: wallpaperDirInput
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                text: root.bar.wallpaperDirectoryInput
                                activeFocusOnPress: true
                                color: root.bar.textColor
                                selectionColor: root.bar.networkTextColor
                                selectedTextColor: "#121212"
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                onTextChanged: root.bar.wallpaperDirectoryInput = text
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 34
                            radius: 17
                            color: scanWallpaperMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                            Text {
                                anchors.centerIn: parent
                                text: "Scan"
                                color: root.bar.networkTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: scanWallpaperMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.bar.wallpaperDirectories = [root.bar.cleanInputPath(wallpaperDirInput.text)];
                                    root.bar.persistSettings();
                                    root.bar.refreshWallpapers();
                                }
                            }
                        }
                    }

                    Text {
                        text: root.bar.wallpaperBrowserStatus
                        color: root.bar.mutedTextColor
                        font.family: root.bar.barFont
                        font.pixelSize: 12
                    }

                    RowLayout {
                        width: parent.width
                        height: 34
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 17
                            color: dynamicThemeMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor
                            border.color: root.bar.dynamicThemeEnabled ? root.bar.popupBorderColor : "transparent"
                            border.width: root.bar.dynamicThemeEnabled ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: root.bar.dynamicThemeEnabled ? "Wallpaper theme on" : "Use wallpaper color"
                                color: root.bar.dynamicThemeEnabled ? root.bar.textColor : root.bar.networkTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: dynamicThemeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.bar.extractThemeFromWallpaper()
                            }
                        }

                        Text {
                            Layout.preferredWidth: 170
                            text: root.bar.dynamicThemeStatus
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Grid {
                        width: parent.width
                        columns: 4
                        rowSpacing: 8
                        columnSpacing: 8
                        visible: root.bar.wallpaperFiles.length > 0

                        Repeater {
                            model: root.bar.wallpaperFiles.slice(0, 12)

                            Rectangle {
                                width: (parent.width - 24) / 4
                                height: 82
                                radius: 12
                                color: wallpaperThumbMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor
                                clip: true

                                Image {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    height: 54
                                    source: "file://" + modelData
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    anchors.bottomMargin: 6
                                    text: modelData.replace(/^.*\//, "")
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: wallpaperThumbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        wallpaperInput.text = modelData;
                                        root.bar.selectWallpaper(modelData);
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Mode"
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
                            radius: 18
                            color: root.bar.themeMode === "dark" ? root.bar.activePillColor : root.bar.pillColor
                            border.color: root.bar.popupBorderColor
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Dark"
                                color: root.bar.themeMode === "dark" ? root.bar.textColor : root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (root.bar.themeMode !== "dark") root.bar.toggleThemeMode();
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 18
                            color: root.bar.themeMode === "light" ? root.bar.activePillColor : root.bar.pillColor
                            border.color: root.bar.popupBorderColor
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Light"
                                color: root.bar.themeMode === "light" ? root.bar.textColor : root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (root.bar.themeMode !== "light") root.bar.toggleThemeMode();
                                }
                            }
                        }
                    }

                    Text {
                        text: "Accent"
                        color: root.bar.mutedTextColor
                        font.family: root.bar.barFont
                        font.pixelSize: 13
                    }

                    Grid {
                        width: parent.width
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: themePresets.presets

                            Rectangle {
                                id: themePresetCard
                                property var tone: root.bar.themeTone(modelData)

                                width: (parent.width - 16) / 3
                                height: 58
                                radius: 16
                                color: themePresetMouse.containsMouse ? tone.active : tone.pill
                                border.color: tone.accent
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Row {
                                        Layout.preferredWidth: 50
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: -6

                                        Repeater {
                                            model: [themePresetCard.tone.accent, themePresetCard.tone.accent2, themePresetCard.tone.bluetooth]

                                            Rectangle {
                                                width: 18
                                                height: 18
                                                radius: 9
                                                color: modelData
                                                border.color: "#44ffffff"
                                                border.width: 1
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.name
                                        color: themePresetCard.tone.text
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: themePresetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.bar.applyThemePreset(modelData)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                    visible: root.activeTab === "theme"
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.activeTab === "display"

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
                    visible: root.activeTab === "display"
                }

                RowLayout {
                    width: parent.width
                    height: root.activeTab === "wifi" ? settingsNetworkCard.implicitHeight : root.activeTab === "bluetooth" ? settingsBluetoothCard.implicitHeight : 0
                    spacing: 10
                    visible: root.activeTab === "wifi" || root.activeTab === "bluetooth"

                    Rectangle {
                        id: settingsNetworkCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.activeTab === "wifi"
                        radius: 14
                        color: root.bar.pillColor
                        implicitHeight: settingsNetworkColumn.implicitHeight + 24

                        Column {
                            id: settingsNetworkColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            property var wifiDevice: root.bar.networkDeviceByType(DeviceType.Wifi)
                            property var wiredDevice: root.bar.networkDeviceByType(DeviceType.Wired)

                            RowLayout {
                                width: parent.width
                                height: 28
                                spacing: 8

                                Text {
                                    text: ""
                                    color: root.bar.networkTextColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "Network"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Rectangle {
                                    Layout.preferredWidth: networkRadioLabel.implicitWidth + 18
                                    Layout.preferredHeight: 26
                                    radius: 13
                                    color: root.bar.pillColor
                                    border.color: "#18ffffff"
                                    border.width: 1

                                    Text {
                                        id: networkRadioLabel
                                        anchors.centerIn: parent
                                        text: settingsNetworkColumn.wifiDevice ? "WiFi" : "Wired"
                                        color: root.bar.networkTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.bar.networkText()
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                width: parent.width
                                height: 30
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: wifiToggleMouse.containsMouse ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Toggle WiFi"
                                        color: root.bar.networkTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: wifiToggleMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.bar.toggleWifiRadio()
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: settingsNetworkColumn.wifiDevice && settingsNetworkColumn.wifiDevice.scannerEnabled ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: settingsNetworkColumn.wifiDevice && settingsNetworkColumn.wifiDevice.scannerEnabled ? "Scanning" : "Scan"
                                        color: root.bar.networkTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (settingsNetworkColumn.wifiDevice) {
                                                settingsNetworkColumn.wifiDevice.scannerEnabled = !settingsNetworkColumn.wifiDevice.scannerEnabled;
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                visible: !settingsNetworkColumn.wifiDevice
                                text: settingsNetworkColumn.wiredDevice ? root.bar.networkNameText(settingsNetworkColumn.wiredDevice) : "No network device"
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Repeater {
                                model: settingsNetworkColumn.wifiDevice ? root.bar.wifiNetworksForDevice(settingsNetworkColumn.wifiDevice).slice(0, 4) : []

                                Rectangle {
                                    width: settingsNetworkColumn.width
                                    height: 30
                                    radius: 15
                                    color: modelData.connected ? root.bar.activePillColor : settingsWifiMouse.containsMouse ? "#4a282828" : root.bar.sectionPillColor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.connected ? "" : root.bar.wifiNetworkLockIcon(modelData)
                                            color: root.bar.networkTextColor
                                            font.family: root.bar.iconFont
                                            font.pixelSize: 13
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: modelData.name || "Hidden network"
                                            color: root.bar.textColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: root.bar.wifiNetworkStatusText(modelData)
                                            color: root.bar.mutedTextColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 11
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        id: settingsWifiMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.bar.connectWifiNetwork(modelData)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: settingsBluetoothCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.activeTab === "bluetooth"
                        radius: 14
                        color: root.bar.pillColor
                        implicitHeight: settingsBluetoothColumn.implicitHeight + 24

                        Column {
                            id: settingsBluetoothColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                width: parent.width
                                height: 28
                                spacing: 8

                                Text {
                                    text: ""
                                    color: root.bar.bluetoothTextColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "Bluetooth"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Rectangle {
                                    Layout.preferredWidth: 54
                                    Layout.preferredHeight: 26
                                    radius: 13
                                    color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "On" : "Off"
                                        color: root.bar.bluetoothTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.bar.toggleBluetoothRadio();
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: Bluetooth.defaultAdapter ? root.bar.bluetoothConnectedDeviceText() || Bluetooth.defaultAdapter.name || "Bluetooth" : "No adapter"
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                width: parent.width
                                height: 30
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "Scanning" : "Scan"
                                        color: root.bar.bluetoothTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            var adapter = Bluetooth.defaultAdapter;
                                            if (!adapter || !adapter.enabled) return;
                                            adapter.discovering = !adapter.discovering;
                                            root.bar.updateBluetoothNameMap();
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                visible: !Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled
                                text: Bluetooth.defaultAdapter ? "Bluetooth off" : "No bluetooth adapter"
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Repeater {
                                model: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Bluetooth.defaultAdapter.devices.values.slice(0, 4) : []

                                Rectangle {
                                    width: settingsBluetoothColumn.width
                                    height: 30
                                    radius: 15
                                    color: modelData.connected ? root.bar.activePillColor : settingsBluetoothMouse.containsMouse ? "#4a282828" : root.bar.sectionPillColor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: modelData.connected ? "󰂱" : "󰂯"
                                            color: root.bar.bluetoothTextColor
                                            font.family: root.bar.iconFont
                                            font.pixelSize: 13
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: root.bar.bluetoothDeviceName(modelData)
                                            color: root.bar.textColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: root.bar.bluetoothDeviceStatus(modelData)
                                            color: root.bar.mutedTextColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 11
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        id: settingsBluetoothMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.bar.toggleBluetoothDevice(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                    visible: root.activeTab === "display"
                }

                RowLayout {
                    width: parent.width
                    height: root.activeTab === "display" ? 72 : 0
                    spacing: 10
                    visible: root.activeTab === "display"

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
                    height: root.activeTab === "display" ? 38 : 0
                    spacing: 8
                    visible: root.activeTab === "display"

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
