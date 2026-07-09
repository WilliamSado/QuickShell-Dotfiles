import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "config" as Config


PanelWindow {
    id: barWindow

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 52
    color: "transparent"

    Config.Numbers { id: numbers }
    Config.Colors { id: colors }
    Config.Booleans { id: booleans }

    property alias barTopMargin: numbers.barTopMargin
    property alias barSideMargin: numbers.barSideMargin
    property alias pillHeight: numbers.pillHeight
    property alias pillRadius: numbers.pillRadius
    property alias pillHPadding: numbers.pillHPadding
    property alias windowPillHPadding: numbers.windowPillHPadding
    property alias trayIconSize: numbers.trayIconSize
    property alias itemSpacing: numbers.itemSpacing
    property alias traySpacing: numbers.traySpacing
    property alias groupSpacing: numbers.groupSpacing
    property alias popupAnimationMs: numbers.popupAnimationMs
    property alias popupAnimationOffset: numbers.popupAnimationOffset
    property alias memoryPillWidth: numbers.memoryPillWidth
    property alias cpuPillWidth: numbers.cpuPillWidth
    property alias barFontSize: numbers.barFontSize
    property alias archIconFontSize: numbers.archIconFontSize

    property string barFont: "JetBrainsMono Nerd Font"
    property string iconFont: "JetBrainsMono Nerd Font"

    property alias pillColor: colors.pillColor
    property alias sectionPillColor: colors.sectionPillColor
    property alias activePillColor: colors.activePillColor
    property alias textColor: colors.textColor
    property alias mutedTextColor: colors.mutedTextColor
    property alias windowTextColor: colors.windowTextColor
    property alias bluetoothTextColor: colors.bluetoothTextColor
    property alias clockTextColor: colors.clockTextColor
    property alias cpuTextColor: colors.cpuTextColor
    property alias memoryTextColor: colors.memoryTextColor
    property alias audioTextColor: colors.audioTextColor
    property alias networkTextColor: colors.networkTextColor

    property alias bluetoothPopupOpen: booleans.bluetoothPopupOpen
    property alias volumePopupOpen: booleans.volumePopupOpen
    property alias networkPopupOpen: booleans.networkPopupOpen
    property alias clockPopupOpen: booleans.clockPopupOpen
    property alias powerPopupOpen: booleans.powerPopupOpen
    property alias bluetoothPopupClosing: booleans.bluetoothPopupClosing
    property alias volumePopupClosing: booleans.volumePopupClosing
    property alias networkPopupClosing: booleans.networkPopupClosing
    property alias clockPopupClosing: booleans.clockPopupClosing
    property alias powerPopupClosing: booleans.powerPopupClosing
    property alias audioOutputScanInSinks: booleans.audioOutputScanInSinks
    property alias audioOutputsExpanded: booleans.audioOutputsExpanded
    property alias clockShowDate: booleans.clockShowDate
    property alias volumeMuted: booleans.volumeMuted
    property alias networkShowIp: booleans.networkShowIp

    property string networkPopupMode: "active"
    property var bluetoothNameMap: ({})
    property var audioOutputDevices: []
    readonly property string shownWindowTitle: activeWindowTitle()

    onBluetoothPopupOpenChanged: {
        if (bluetoothPopupOpen) {
            bluetoothPopupClosing = false;
        } else if (!bluetoothPopupClosing) {
            bluetoothPopupClosing = true;
            bluetoothPopupCloseTimer.restart();
        }
    }

    onPowerPopupOpenChanged: {
        if (powerPopupOpen) {
            powerPopupClosing = false;
        } else if (!powerPopupClosing) {
            powerPopupClosing = true;
            powerPopupCloseTimer.restart();
        }
    }

    onVolumePopupOpenChanged: {
        if (volumePopupOpen) {
            volumePopupClosing = false;
        } else if (!volumePopupClosing) {
            volumePopupClosing = true;
            volumePopupCloseTimer.restart();
        }
    }

    onNetworkPopupOpenChanged: {
        if (networkPopupOpen) {
            networkPopupClosing = false;
        } else if (!networkPopupClosing) {
            networkPopupClosing = true;
            networkPopupCloseTimer.restart();
        }
    }

    onClockPopupOpenChanged: {
        if (clockPopupOpen) {
            clockPopupClosing = false;
        } else if (!clockPopupClosing) {
            clockPopupClosing = true;
            clockPopupCloseTimer.restart();
        }
    }

    function closeBluetoothPopup() {
        if (!bluetoothPopupOpen) return;
        bluetoothPopupClosing = true;
        bluetoothPopupCloseTimer.restart();
        bluetoothPopupOpen = false;
    }

    function closePowerPopup() {
        if (!powerPopupOpen) return;
        powerPopupClosing = true;
        powerPopupCloseTimer.restart();
        powerPopupOpen = false;
    }

    function closeVolumePopup() {
        if (!volumePopupOpen) return;
        volumePopupClosing = true;
        volumePopupCloseTimer.restart();
        volumePopupOpen = false;
    }

    function closeNetworkPopup() {
        if (!networkPopupOpen) return;
        networkPopupClosing = true;
        networkPopupCloseTimer.restart();
        networkPopupOpen = false;
    }

    function closeClockPopup() {
        if (!clockPopupOpen) return;
        clockPopupClosing = true;
        clockPopupCloseTimer.restart();
        clockPopupOpen = false;
    }

    function closePopupsExcept(name) {
        if (name !== "bluetooth") closeBluetoothPopup();
        if (name !== "power") closePowerPopup();
        if (name !== "volume") closeVolumePopup();
        if (name !== "network") closeNetworkPopup();
        if (name !== "clock") closeClockPopup();
    }

    function volumeIconText() {
        if (volumeMuted) return "";
        if (volumePercent < 35) return "";
        if (volumePercent < 70) return "";
        return "";
    }

    function bluetoothText() {
        var adapter = Bluetooth.defaultAdapter;
        if (!adapter) return "--";
        if (!adapter.enabled) return "off";

        var devices = adapter.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) return devices[i].name || devices[i].deviceName || "Connected";
        }

        return "on";
    }

    function looksLikeBluetoothAddress(value) {
        if (!value) return false;

        return /^[0-9a-f]{2}([:-][0-9a-f]{2}){1,5}$/i.test(value);
    }

    function bluetoothDeviceName(device) {
        if (!device) return "Unknown device";

        var mappedName = bluetoothNameMap[device.address || ""];
        if (mappedName && !looksLikeBluetoothAddress(mappedName)) return mappedName;

        var name = device.name || device.deviceName || "";
        if (name && !looksLikeBluetoothAddress(name)) return name;

        return "Unknown device";
    }

    function updateBluetoothNameMap() {
        bluetoothNameMap = ({});
        bluetoothNamesProc.running = true;
    }

    function bluetoothConnectedDeviceText() {
        var adapter = Bluetooth.defaultAdapter;
        if (!adapter || !adapter.enabled) return "";

        var devices = adapter.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) return bluetoothDeviceName(devices[i]);
        }

        return "No connected device";
    }

    function bluetoothDeviceStatus(device) {
        if (device.connected) return "connected";
        if (device.state === BluetoothDeviceState.Connecting) return "connecting";
        if (device.state === BluetoothDeviceState.Disconnecting) return "disconnecting";
        if (device.pairing) return "pairing";
        if (device.paired) return "paired";
        return "available";
    }

    function toggleBluetoothDevice(device) {
        if (device.connected) {
            device.disconnect();
            return;
        }

        device.connect();
    }

    function popupXForItem(item, popupWidth) {
        if (!item) return 0;

        var point = itemPositionInWindow(item);
        var centered = point.x + item.width / 2 - popupWidth / 2;
        var minX = barSideMargin;
        var maxX = barWindow.width - popupWidth - barSideMargin;

        if (centered < minX) return Math.max(minX, point.x);
        if (centered > maxX) return Math.max(minX, point.x + item.width - popupWidth);
        return centered;
    }

    function popupYForItem(item) {
        if (!item) return barWindow.implicitHeight + 4;

        var point = itemPositionInWindow(item);
        return point.y + item.height + 6;
    }

    function itemPositionInWindow(item) {
        var x = 0;
        var y = 0;
        var current = item;

        while (current) {
            x += current.x || 0;
            y += current.y || 0;
            current = current.parent;
        }

        return { "x": x, "y": y };
    }

    function networkIconText() {
        var devices = Networking.devices.values;
        for (var i = 0; i < devices.length; i++) {
            var device = devices[i];
            if (device.connected) {
                return device.type === 1 ? "" : "";
            }
        }

        return "";
    }

    function networkText() {
        if (networkShowIp) return networkIpText || "No IP";

        var devices = Networking.devices.values;
        for (var i = 0; i < devices.length; i++) {
            var device = devices[i];
            if (device.connected) {
                if (device.type !== 1) return device.name || "Wired";

                var nets = device.networks.values;
                for (var j = 0; j < nets.length; j++) {
                    if (nets[j].connected) return nets[j].name + " (" + Math.round(nets[j].signalStrength) + "%)";
                }

                return "WiFi";
            }
        }

        return "Disconnected";
    }

    function activeNetworkDevice() {
        var devices = Networking.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) return devices[i];
        }

        return null;
    }

    function networkDeviceByType(type) {
        var devices = Networking.devices.values;
        var fallback = null;

        for (var i = 0; i < devices.length; i++) {
            if (devices[i].type !== type) continue;
            if (devices[i].connected) return devices[i];
            if (!fallback) fallback = devices[i];
        }

        return fallback;
    }

    function networkPopupDevice() {
        if (networkPopupMode === "wifi") return networkDeviceByType(DeviceType.Wifi);
        if (networkPopupMode === "wired") return networkDeviceByType(DeviceType.Wired);
        return activeNetworkDevice();
    }

    function networkIconForDevice(device) {
        if (!device || !device.connected) return "";
        if (device.type === DeviceType.Wifi) return "";
        if (device.type === DeviceType.Wired) return "";
        return "";
    }

    function connectedWifiNetwork(device) {
        if (!device || device.type !== DeviceType.Wifi) return null;

        var nets = device.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }

        return null;
    }

    function networkTypeText(device) {
        if (!device) return "Disconnected";
        if (device.type === DeviceType.Wifi) return "WiFi";
        if (device.type === DeviceType.Wired) return "Wired";
        return "Network";
    }

    function networkNameText(device) {
        if (!device) return "No active connection";

        var wifi = connectedWifiNetwork(device);
        if (wifi) return wifi.name;

        return device.name || networkTypeText(device);
    }

    function networkSignalText(device) {
        var wifi = connectedWifiNetwork(device);
        if (!wifi) return "";

        return Math.round(wifi.signalStrength) + "%";
    }

    function wifiNetworksForDevice(device) {
        if (!device || device.type !== DeviceType.Wifi) return [];

        var networks = device.networks.values.slice();
        networks.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });

        return networks;
    }

    function wifiNetworkStatusText(network) {
        if (network.connected) return "connected";
        if (network.stateChanging) return "connecting";
        if (network.known) return "known";
        return network.security === WifiSecurityType.Open ? "open" : "secured";
    }

    function wifiNetworkLockIcon(network) {
        if (network.security === WifiSecurityType.Open) return "";
        return "";
    }

    function connectWifiNetwork(network) {
        if (!network || network.connected || network.stateChanging) return;

        if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
        }
    }

    function activeNetworkInterface() {
        var selected = networkPopupOpen ? networkPopupDevice() : activeNetworkDevice();
        if (selected && selected.connected) return selected.name || "";

        return "";
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function updateNetworkIp() {
        var iface = activeNetworkInterface();
        if (iface.length === 0) {
            networkIpText = "No IP";
            return;
        }

        netIpProc.command = ["sh", "-c", "ip -o -4 addr show dev " + shellQuote(iface) + " | awk '{print $4}' | head -1"];
        netIpProc.running = true;
    }

    function formatAppName(name) {
        if (!name) return "";

        var normalized = name.toLowerCase();
        if (normalized === "yesplaymusic") return "YesPlayMusic";

        return name;
    }

    function activeWindowTitle() {
        var workspace = Hyprland.focusedWorkspace;
        if (!workspace || !workspace.toplevels || workspace.toplevels.values.length === 0) return "";
        var toplevel = Hyprland.activeToplevel;
        if (!toplevel) return "";

        var ipc = toplevel.lastIpcObject || {};
        if (ipc.class) return formatAppName(ipc.class);

        var title = toplevel.title || "";
        var suffixes = [
            " - Code - OSS",
            " - Visual Studio Code",
            " - Google Chrome",
            " - Chromium",
            " - Mozilla Firefox",
            " - Firefox",
            " - YesPlayMusic"
        ];

        for (var i = 0; i < suffixes.length; i++) {
            if (title.endsWith(suffixes[i])) return formatAppName(suffixes[i].slice(3));
        }

        return title;
    }

    // ====================  CPU  ====================
    property int cpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: function(data) {
                var p = data.trim().split(/\s+/);
                var idle = parseInt(p[4]) + parseInt(p[5]);
                var total = p.slice(1, 8).reduce(function(a, b) { return a + parseInt(b); }, 0);
                var diffIdle = idle - lastCpuIdle;
                var diffTotal = total - lastCpuTotal;
                if (lastCpuTotal > 0 && diffTotal > 0) {
                    cpuUsage = Math.round((1 - diffIdle / diffTotal) * 100);
                }
                lastCpuIdle = idle;
                lastCpuTotal = total;
            }
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: cpuProc.running = true
    }

    // ====================  内存  ====================
    property int memUsage: 0
    property string memUsedText: "0.0G"

    Process {
        id: memProc
        command: ["sh", "-c", "free -m | awk 'NR==2 {printf \"%d %.1fG\", $3*100/$2, $3/1024}'"]
        stdout: SplitParser {
            onRead: function(data) {
                var parts = data.trim().split(/\s+/);
                memUsage = parseInt(parts[0]);
                if (parts.length > 1) memUsedText = parts[1];
            }
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: memProc.running = true
    }

    // ====================  蓝牙名称  ====================
    Process {
        id: bluetoothNamesProc
        command: ["bluetoothctl", "devices"]
        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim();
                var match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
                if (!match) return;

                var names = Object.assign({}, bluetoothNameMap);
                if (!looksLikeBluetoothAddress(match[2])) names[match[1]] = match[2];
                bluetoothNameMap = names;
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: bluetoothPopupOpen
        onTriggered: updateBluetoothNameMap()
    }

    // ====================  时钟  ====================
    property string currentTime: ""

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            updateClock();
        }
    }

    // ====================  音量  ====================
    property int volumePercent: 0
    property string networkIpText: ""

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim();
                // format: "Volume: 0.65" or "Volume: 0.65 [MUTED]"
                var match = line.match(/Volume:\s*([\d.]+)/);
                if (match) volumePercent = Math.round(parseFloat(match[1]) * 100);
                volumeMuted = line.indexOf("MUTED") !== -1;
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: volProc.running = true
    }

    Component.onCompleted: {
        cpuProc.running = true;
        memProc.running = true;
        updateClock();
        volProc.running = true;
        refreshAudioOutputs();
    }

    function updateClock() {
        var now = new Date();
        currentTime = clockShowDate ? Qt.formatDateTime(now, "yyyy-MM-dd hh:mm:ss") : Qt.formatTime(now, "hh:mm:ss");
    }

    function clockIconText() {
        return clockShowDate ? "" : "";
    }

    function runPowerCommand(command) {
        closePowerPopup();
        powerProc.command = command;
        powerProc.running = true;
    }

    function calendarMonthTitle() {
        return Qt.formatDate(new Date(), "yyyy-MM");
    }

    function calendarCellDay(index) {
        var now = new Date();
        var first = new Date(now.getFullYear(), now.getMonth(), 1);
        var firstWeekday = first.getDay();
        var days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
        var day = index - firstWeekday + 1;

        return day >= 1 && day <= days ? day : "";
    }

    function calendarCellIsToday(index) {
        var day = calendarCellDay(index);
        return day !== "" && day === new Date().getDate();
    }

    function toggleMute() {
        volMuteProc.running = true;
    }

    function volumeSinkName() {
        var sink = Pipewire.defaultAudioSink;
        if (!sink) return "Default output";

        return sink.description || sink.nickname || sink.name || "Default output";
    }

    function audioSinkName(sink) {
        if (!sink) return "Unknown output";

        return sink.description || sink.nickname || sink.name || "Unknown output";
    }

    function audioSinks() {
        return audioOutputDevices;
    }

    function isDefaultAudioSink(sink) {
        return sink && sink.active;
    }

    function setDefaultAudioSink(sink) {
        if (!sink) return;

        audioDefaultProc.command = ["wpctl", "set-default", String(sink.id)];
        audioDefaultProc.running = true;
    }

    function refreshAudioOutputs() {
        audioOutputDevices = [];
        audioOutputScanInSinks = false;
        audioOutputsProc.running = true;
    }

    function parseAudioOutputLine(line) {
        var clean = line.replace(/[│├└─]/g, " ").trim();

        if (clean === "Sinks:") {
            audioOutputScanInSinks = true;
            return;
        }

        if (audioOutputScanInSinks && clean.match(/^(Sources|Sink endpoints|Source endpoints|Streams|Filters|Video|Settings):/)) {
            audioOutputScanInSinks = false;
        }

        if (audioOutputScanInSinks) {
            var sinkMatch = clean.match(/^(\*)?\s*(\d+)\.\s+(.+?)(?:\s+\[vol:.*)?$/);
            if (!sinkMatch) return;

            var outputs = audioOutputDevices.slice();
            outputs.push({
                "id": parseInt(sinkMatch[2]),
                "name": sinkMatch[3],
                "active": sinkMatch[1] === "*"
            });
            audioOutputDevices = outputs;
            return;
        }
    }

    function setVolumePercent(percent) {
        var clamped = Math.max(0, Math.min(100, Math.round(percent)));
        volSetProc.command = ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (clamped / 100).toFixed(2)];
        volSetProc.running = true;
    }

    function adjustVolume(delta) {
        var newVol = Math.max(0, Math.min(1.0, (volumePercent / 100) + delta));
        volSetProc.command = ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + newVol.toFixed(2)];
        volSetProc.running = true;
    }

    Process {
        id: volMuteProc
        command: ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]
    }

    Process {
        id: volSetProc
        command: ["sh", "-c", "echo 0"]
    }

    Process {
        id: audioOutputsProc
        command: ["wpctl", "status"]
        stdout: SplitParser {
            onRead: function(data) {
                parseAudioOutputLine(data);
            }
        }
    }

    Process {
        id: audioDefaultProc
        command: ["sh", "-c", "echo 0"]
        onExited: {
            refreshAudioOutputs();
            volProc.running = true;
        }
    }

    Process {
        id: netIpProc
        command: ["sh", "-c", "echo"]
        stdout: SplitParser {
            onRead: function(data) {
                var ip = data.trim();
                networkIpText = ip.length > 0 ? ip : "No IP";
            }
        }
    }

    Process {
        id: powerProc
        command: ["sh", "-c", "echo"]
    }

    Timer {
        interval: 1000
        repeat: true
        running: networkShowIp || networkPopupOpen
        onTriggered: updateNetworkIp()
    }

    Timer {
        interval: 3000
        repeat: true
        running: volumePopupOpen
        onTriggered: refreshAudioOutputs()
    }

    Timer {
        id: bluetoothPopupCloseTimer
        interval: popupAnimationMs
        repeat: false
        onTriggered: bluetoothPopupClosing = false
    }

    Timer {
        id: powerPopupCloseTimer
        interval: popupAnimationMs
        repeat: false
        onTriggered: powerPopupClosing = false
    }

    Timer {
        id: volumePopupCloseTimer
        interval: popupAnimationMs
        repeat: false
        onTriggered: volumePopupClosing = false
    }

    Timer {
        id: networkPopupCloseTimer
        interval: popupAnimationMs
        repeat: false
        onTriggered: networkPopupClosing = false
    }

    Timer {
        id: clockPopupCloseTimer
        interval: popupAnimationMs
        repeat: false
        onTriggered: clockPopupClosing = false
    }

    // ====================  布局  ====================
    RowLayout {
        anchors.fill: parent
        anchors.topMargin: barTopMargin
        anchors.leftMargin: barSideMargin
        anchors.rightMargin: barSideMargin
        spacing: 0

        // ============ 左侧区域 ============
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignVCenter
            spacing: groupSpacing

            Rectangle {
                id: archPill
                Layout.preferredWidth: pillHeight
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: sectionPillColor

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: textColor
                    font.family: barFont
                    font.pixelSize: archIconFontSize
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (powerPopupOpen) {
                            closePowerPopup();
                            return;
                        }

                        closePopupsExcept("power");
                        powerPopupOpen = true;
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: Math.min(Math.max(titleIcon.implicitWidth + titleText.implicitWidth + itemSpacing + windowPillHPadding * 2, 42), 260)
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: sectionPillColor
                clip: true

                Row {
                    id: titleRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: windowPillHPadding
                    spacing: itemSpacing

                    Text {
                        id: titleIcon
                        text: ""
                        color: windowTextColor
                        font.family: iconFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: titleText
                        text: shownWindowTitle
                        color: windowTextColor
                        font.family: barFont
                        font.pixelSize: barFontSize
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 190)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // ============ 居中: 工作区 ============
        Rectangle {
            Layout.preferredWidth: workspaceRow.implicitWidth + 10
            Layout.preferredHeight: pillHeight
            Layout.alignment: Qt.AlignVCenter
            radius: pillRadius
            color: sectionPillColor

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e+1" : "workspace e-1");
                }
            }

            Row {
                id: workspaceRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: 10

                    Rectangle {
                        property var ws: Hyprland.workspaces.values.find(workspace => workspace.id === index + 1)
                        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                        property bool hasWindows: ws && ws.toplevels && ws.toplevels.values.length > 0

                        width: 30
                        height: 30
                        radius: 15
                        color: isActive ? activePillColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            color: parent.isActive || parent.hasWindows ? textColor : mutedTextColor
                            font.family: barFont
                            font.pixelSize: barFontSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + (index + 1))
                            onWheel: function(wheel) {
                                Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e+1" : "workspace e-1");
                            }
                        }
                    }
                }
            }
        }

        // ============ 右侧区域 ============
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignVCenter
            spacing: groupSpacing

            Item { Layout.fillWidth: true }

            // ---- 蓝牙 ----
            Rectangle {
                id: bluetoothPill
                Layout.preferredWidth: btRow.implicitWidth + pillHPadding * 2
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: pillColor

                Row {
                    id: btRow
                    anchors.centerIn: parent
                    spacing: itemSpacing

                    Text {
                        text: ""
                        color: bluetoothTextColor
                        font.family: iconFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: bluetoothText()
                        color: bluetoothTextColor
                        font.family: barFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        var adapter = Bluetooth.defaultAdapter;
                        if (mouse.button === Qt.RightButton) {
                            if (adapter) adapter.enabled = !adapter.enabled;
                            return;
                        }

                        if (bluetoothPopupOpen) {
                            closeBluetoothPopup();
                            return;
                        }

                        closePopupsExcept("bluetooth");
                        bluetoothPopupOpen = true;
                        if (bluetoothPopupOpen && adapter && adapter.enabled) {
                            adapter.discovering = true;
                            updateBluetoothNameMap();
                        }
                    }
                }
            }

            // ---- 音量 ----
            Rectangle {
                id: volumePill
                Layout.preferredWidth: volRow.implicitWidth + pillHPadding * 2
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: pillColor

                Row {
                    id: volRow
                    anchors.centerIn: parent
                    spacing: itemSpacing

                    Text {
                        text: volumeIconText()
                        color: audioTextColor
                        font.family: iconFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: !volumeMuted
                        text: volumePercent + "%"
                        color: audioTextColor
                        font.family: barFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            toggleMute();
                            return;
                        }

                        if (volumePopupOpen) {
                            closeVolumePopup();
                            return;
                        }

                        closePopupsExcept("volume");
                        volumePopupOpen = true;
                        if (volumePopupOpen) refreshAudioOutputs();
                    }
                    onWheel: function(w) { adjustVolume(w.angleDelta.y / 1200) }
                }
            }

            // ---- 网络 ----
            Rectangle {
                id: networkPill
                Layout.preferredWidth: netRow.implicitWidth + pillHPadding * 2
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: pillColor

                Row {
                    id: netRow
                    anchors.centerIn: parent
                    spacing: itemSpacing

                    Text {
                        text: networkIconText()
                        color: networkTextColor
                        font.family: iconFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: networkText()
                        color: networkTextColor
                        font.family: barFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            networkShowIp = !networkShowIp;
                            if (networkShowIp) updateNetworkIp();
                            return;
                        }

                        if (networkPopupOpen) {
                            closeNetworkPopup();
                            return;
                        }

                        closePopupsExcept("network");
                        networkPopupOpen = true;
                        if (networkPopupOpen) {
                            var active = activeNetworkDevice();
                            networkPopupMode = active && active.type === DeviceType.Wifi ? "wifi" : "wired";
                            var wifiDevice = networkDeviceByType(DeviceType.Wifi);
                            if (networkPopupMode === "wifi" && wifiDevice) wifiDevice.scannerEnabled = true;
                            updateNetworkIp();
                        }
                    }
                }
            }

            // ---- 内存 ----
            Rectangle {
                Layout.preferredWidth: memoryPillWidth
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: pillColor

                Row {
                    id: memRow
                    anchors.centerIn: parent
                    spacing: itemSpacing

                    Text {
                        text: ""
                        color: memoryTextColor
                        font.family: iconFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: memUsedText
                        color: memoryTextColor
                        font.family: barFont
                        font.pixelSize: barFontSize
                        width: 48
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ---- CPU ----
            Rectangle {
                Layout.preferredWidth: cpuPillWidth
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: pillColor

                Row {
                    id: cpuRow
                    anchors.centerIn: parent
                    spacing: itemSpacing

                    Text {
                        text: ""
                        color: cpuTextColor
                        font.family: iconFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: cpuUsage + "%"
                        color: cpuTextColor
                        font.family: barFont
                        font.pixelSize: barFontSize
                        width: 42
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ---- 系统托盘 ----
            Rectangle {
                Layout.preferredWidth: trayRow.implicitWidth + pillHPadding * 2
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: sectionPillColor

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: traySpacing

                    Repeater {
                        model: SystemTray.items

                        IconImage {
                            source: modelData.icon
                            width: trayIconSize
                            height: trayIconSize
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) { mouse.button === Qt.RightButton ? modelData.secondaryActivate() : modelData.activate() }
                                onWheel: function(wheel) { modelData.scroll(wheel.angleDelta.y, false) }
                            }
                        }
                    }
                }
            }

            // ---- 时钟 ----
            Rectangle {
                id: clockPill
                Layout.preferredWidth: timeRow.implicitWidth + pillHPadding * 2
                Layout.preferredHeight: pillHeight
                Layout.alignment: Qt.AlignVCenter
                radius: pillRadius
                color: pillColor

                Row {
                    id: timeRow
                    anchors.centerIn: parent
                    spacing: itemSpacing

                    Text {
                        text: clockIconText()
                        color: clockTextColor
                        font.family: iconFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: currentTime
                        color: clockTextColor
                        font.family: barFont
                        font.pixelSize: barFontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            clockShowDate = !clockShowDate;
                            updateClock();
                            return;
                        }

                        if (clockPopupOpen) {
                            closeClockPopup();
                            return;
                        }

                        closePopupsExcept("clock");
                        clockPopupOpen = true;
                    }
                }
            }
        }
    }

    PopupWindow {
        id: bluetoothPopup
        parentWindow: barWindow
        visible: bluetoothPopupOpen || bluetoothPopupClosing
        implicitWidth: 320
        implicitHeight: Math.min(bluetoothPopupContent.implicitHeight, 360)
        relativeX: popupXForItem(bluetoothPill, implicitWidth)
        relativeY: popupYForItem(bluetoothPill)
        color: "transparent"
        grabFocus: bluetoothPopupOpen
        onVisibleChanged: {
            if (!visible) bluetoothPopupOpen = false;
        }

        Rectangle {
            id: bluetoothPopupContent
            width: parent.width
            y: bluetoothPopupOpen ? 0 : -popupAnimationOffset
            opacity: bluetoothPopupOpen ? 1 : 0
            scale: bluetoothPopupOpen ? 1 : 0.96
            transformOrigin: Item.Top
            implicitHeight: bluetoothPopupColumn.implicitHeight + 24
            radius: 18
            color: "#cc121212"
            border.color: "#22ffffff"
            border.width: 1

            Behavior on y { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }

            Column {
                id: bluetoothPopupColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    width: parent.width
                    height: 28
                    spacing: 8

                    Text {
                        text: ""
                        color: bluetoothTextColor
                        font.family: iconFont
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: Bluetooth.defaultAdapter ? (Bluetooth.defaultAdapter.enabled ? Bluetooth.defaultAdapter.name || "Bluetooth" : "Bluetooth off") : "No adapter"
                        color: textColor
                        font.family: barFont
                        font.pixelSize: 15
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: scanLabel.implicitWidth + 18
                        Layout.preferredHeight: 28
                        radius: 14
                        color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? activePillColor : pillColor
                        visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled

                        Text {
                            id: scanLabel
                            anchors.centerIn: parent
                            text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "scan" : "idle"
                            color: bluetoothTextColor
                            font.family: barFont
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var adapter = Bluetooth.defaultAdapter;
                                if (adapter) adapter.discovering = !adapter.discovering;
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                }

                Text {
                    width: parent.width
                    visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                    text: bluetoothConnectedDeviceText()
                    color: bluetoothTextColor
                    font.family: barFont
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: !Bluetooth.defaultAdapter
                    text: "No bluetooth adapter"
                    color: mutedTextColor
                    font.family: barFont
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    visible: Bluetooth.defaultAdapter && !Bluetooth.defaultAdapter.enabled
                    text: "Right click capsule to enable"
                    color: mutedTextColor
                    font.family: barFont
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled && Bluetooth.defaultAdapter.devices.values.length === 0
                    text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "Scanning..." : "No devices"
                    color: mutedTextColor
                    font.family: barFont
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Bluetooth.defaultAdapter.devices.values : []

                    Rectangle {
                        width: bluetoothPopupColumn.width
                        height: 38
                        radius: 12
                        color: deviceMouse.containsMouse ? "#44282828" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: modelData.connected ? "󰂱" : "󰂯"
                                color: modelData.connected ? bluetoothTextColor : mutedTextColor
                                font.family: iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: bluetoothDeviceName(modelData)
                                color: textColor
                                font.family: barFont
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: bluetoothDeviceStatus(modelData)
                                color: modelData.connected ? bluetoothTextColor : mutedTextColor
                                font.family: barFont
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: deviceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: toggleBluetoothDevice(modelData)
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: powerPopup
        parentWindow: barWindow
        visible: powerPopupOpen || powerPopupClosing
        implicitWidth: 220
        implicitHeight: powerPopupContent.implicitHeight
        relativeX: popupXForItem(archPill, implicitWidth)
        relativeY: popupYForItem(archPill)
        color: "transparent"
        grabFocus: powerPopupOpen
        onVisibleChanged: {
            if (!visible) powerPopupOpen = false;
        }

        Rectangle {
            id: powerPopupContent
            width: parent.width
            y: powerPopupOpen ? 0 : -popupAnimationOffset
            opacity: powerPopupOpen ? 1 : 0
            scale: powerPopupOpen ? 1 : 0.96
            transformOrigin: Item.Top
            implicitHeight: powerPopupColumn.implicitHeight + 24
            radius: 18
            color: "#cc121212"
            border.color: "#22ffffff"
            border.width: 1

            Behavior on y { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }

            Column {
                id: powerPopupColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        text: ""
                        color: cpuTextColor
                        font.family: iconFont
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "Power"
                        color: textColor
                        font.family: barFont
                        font.pixelSize: 15
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                }

                Repeater {
                    model: [
                        { icon: "", label: "Lock", command: ["hyprlock"] },
                        { icon: "", label: "Reboot", command: ["systemctl", "reboot"] },
                        { icon: "", label: "Power off", command: ["systemctl", "poweroff"] }
                    ]

                    Rectangle {
                        width: powerPopupColumn.width
                        height: 38
                        radius: 12
                        color: powerItemMouse.containsMouse ? "#44282828" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                text: modelData.icon
                                color: modelData.label === "Power off" ? cpuTextColor : textColor
                                font.family: iconFont
                                font.pixelSize: 15
                                Layout.preferredWidth: 20
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: modelData.label
                                color: textColor
                                font.family: barFont
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: powerItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: runPowerCommand(modelData.command)
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: volumePopup
        parentWindow: barWindow
        visible: volumePopupOpen || volumePopupClosing
        implicitWidth: 300
        implicitHeight: volumePopupContent.implicitHeight
        relativeX: popupXForItem(volumePill, implicitWidth)
        relativeY: popupYForItem(volumePill)
        color: "transparent"
        grabFocus: volumePopupOpen
        onVisibleChanged: {
            if (!visible) {
                volumePopupOpen = false;
                audioOutputsExpanded = false;
            }
        }

        Rectangle {
            id: volumePopupContent
            width: parent.width
            y: volumePopupOpen ? 0 : -popupAnimationOffset
            opacity: volumePopupOpen ? 1 : 0
            scale: volumePopupOpen ? 1 : 0.96
            transformOrigin: Item.Top
            implicitHeight: volumePopupColumn.implicitHeight + 24
            radius: 18
            color: "#cc121212"
            border.color: "#22ffffff"
            border.width: 1

            Behavior on y { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }

            Column {
                id: volumePopupColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 12

                RowLayout {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        text: volumeIconText()
                        color: audioTextColor
                        font.family: iconFont
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: volumeSinkName()
                        color: textColor
                        font.family: barFont
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: muteLabel.implicitWidth + 18
                        Layout.preferredHeight: 28
                        radius: 14
                        color: volumeMuted ? activePillColor : pillColor

                        Text {
                            id: muteLabel
                            anchors.centerIn: parent
                            text: volumeMuted ? "muted" : "sound"
                            color: audioTextColor
                            font.family: barFont
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: toggleMute()
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
                    height: 28
                    spacing: 10

                    Text {
                        text: volumePercent + "%"
                        color: audioTextColor
                        font.family: barFont
                        font.pixelSize: 15
                        Layout.preferredWidth: 52
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        id: volumeTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: "#24ffffff"
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: parent.width * Math.min(volumePercent, 100) / 100
                            height: parent.height
                            radius: parent.radius
                            color: audioTextColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: function(mouse) {
                                setVolumePercent(mouse.x / width * 100);
                            }
                            onPositionChanged: function(mouse) {
                                if (pressed) setVolumePercent(mouse.x / width * 100);
                            }
                            onWheel: function(wheel) {
                                adjustVolume(wheel.angleDelta.y / 1200);
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                }

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 12
                    color: outputHeaderMouse.containsMouse ? "#44282828" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: audioOutputsExpanded ? "" : ""
                            color: audioTextColor
                            font.family: iconFont
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "Output"
                            color: mutedTextColor
                            font.family: barFont
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: volumeSinkName()
                            color: textColor
                            font.family: barFont
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: outputHeaderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            audioOutputsExpanded = !audioOutputsExpanded;
                            if (audioOutputsExpanded) refreshAudioOutputs();
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: audioOutputsExpanded && audioSinks().length === 0
                    text: "No output devices"
                    color: mutedTextColor
                    font.family: barFont
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: audioOutputsExpanded ? audioSinks() : []

                    Rectangle {
                        width: volumePopupColumn.width
                        height: 38
                        radius: 12
                        color: isDefaultAudioSink(modelData) ? activePillColor : (sinkMouse.containsMouse ? "#44282828" : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: isDefaultAudioSink(modelData) ? "" : "󰓃"
                                color: isDefaultAudioSink(modelData) ? audioTextColor : mutedTextColor
                                font.family: iconFont
                                font.pixelSize: 15
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: audioSinkName(modelData)
                                color: textColor
                                font.family: barFont
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: setDefaultAudioSink(modelData)
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: networkPopup
        parentWindow: barWindow
        visible: networkPopupOpen || networkPopupClosing
        implicitWidth: 300
        implicitHeight: networkPopupContent.implicitHeight
        relativeX: popupXForItem(networkPill, implicitWidth)
        relativeY: popupYForItem(networkPill)
        color: "transparent"
        grabFocus: networkPopupOpen
        onVisibleChanged: {
            if (!visible) networkPopupOpen = false;
        }

        Rectangle {
            id: networkPopupContent
            width: parent.width
            y: networkPopupOpen ? 0 : -popupAnimationOffset
            opacity: networkPopupOpen ? 1 : 0
            scale: networkPopupOpen ? 1 : 0.96
            transformOrigin: Item.Top
            implicitHeight: networkPopupColumn.implicitHeight + 24
            radius: 18
            color: "#cc121212"
            border.color: "#22ffffff"
            border.width: 1

            Behavior on y { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }

            Column {
                id: networkPopupColumn
                property var device: networkPopupDevice()

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 12

                RowLayout {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        text: networkIconForDevice(networkPopupColumn.device)
                        color: networkTextColor
                        font.family: iconFont
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: networkNameText(networkPopupColumn.device)
                        color: textColor
                        font.family: barFont
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: typeLabel.implicitWidth + 18
                        Layout.preferredHeight: 28
                        radius: 14
                        color: pillColor

                        Text {
                            id: typeLabel
                            anchors.centerIn: parent
                            text: networkTypeText(networkPopupColumn.device)
                            color: networkTextColor
                            font.family: barFont
                            font.pixelSize: 13
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
                    height: 30
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: 15
                        color: networkPopupMode === "wired" ? activePillColor : pillColor

                        Text {
                            anchors.centerIn: parent
                            text: " Wired"
                            color: networkPopupMode === "wired" ? textColor : networkTextColor
                            font.family: barFont
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                networkPopupMode = "wired";
                                updateNetworkIp();
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: 15
                        color: networkPopupMode === "wifi" ? activePillColor : pillColor

                        Text {
                            anchors.centerIn: parent
                            text: " WiFi"
                            color: networkPopupMode === "wifi" ? textColor : networkTextColor
                            font.family: barFont
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                networkPopupMode = "wifi";
                                var wifiDevice = networkDeviceByType(DeviceType.Wifi);
                                if (wifiDevice) wifiDevice.scannerEnabled = true;
                                updateNetworkIp();
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
                    height: 24
                    spacing: 10

                    Text {
                        text: "Interface"
                        color: mutedTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        Layout.preferredWidth: 86
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: networkPopupColumn.device ? networkPopupColumn.device.name || "--" : "--"
                        color: textColor
                        font.family: barFont
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                RowLayout {
                    width: parent.width
                    height: 24
                    spacing: 10

                    Text {
                        text: "IP"
                        color: mutedTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        Layout.preferredWidth: 86
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: networkPopupColumn.device && networkPopupColumn.device.connected ? networkIpText || "No IP" : "Disconnected"
                        color: networkTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                RowLayout {
                    width: parent.width
                    height: 24
                    spacing: 10
                    visible: networkSignalText(networkPopupColumn.device).length > 0

                    Text {
                        text: "Signal"
                        color: mutedTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        Layout.preferredWidth: 86
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: "#24ffffff"
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: parent.width * parseInt(networkSignalText(networkPopupColumn.device) || "0") / 100
                            height: parent.height
                            radius: parent.radius
                            color: networkTextColor
                        }
                    }

                    Text {
                        text: networkSignalText(networkPopupColumn.device)
                        color: networkTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: networkPopupMode === "wifi"

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#18ffffff"
                    }

                    RowLayout {
                        width: parent.width
                        height: 26
                        spacing: 8

                        Text {
                            text: "Networks"
                            color: mutedTextColor
                            font.family: barFont
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            Layout.preferredWidth: wifiScanLabel.implicitWidth + 18
                            Layout.preferredHeight: 26
                            radius: 13
                            color: networkPopupColumn.device && networkPopupColumn.device.scannerEnabled ? activePillColor : pillColor

                            Text {
                                id: wifiScanLabel
                                anchors.centerIn: parent
                                text: networkPopupColumn.device && networkPopupColumn.device.scannerEnabled ? "scanning" : "scan"
                                color: networkTextColor
                                font.family: barFont
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (networkPopupColumn.device) {
                                        networkPopupColumn.device.scannerEnabled = !networkPopupColumn.device.scannerEnabled;
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: !networkPopupColumn.device || networkPopupColumn.device.type !== DeviceType.Wifi
                        text: "No WiFi device"
                        color: mutedTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        visible: networkPopupColumn.device
                            && networkPopupColumn.device.type === DeviceType.Wifi
                            && wifiNetworksForDevice(networkPopupColumn.device).length === 0
                        text: networkPopupColumn.device.scannerEnabled ? "Scanning..." : "No networks found"
                        color: mutedTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Repeater {
                        model: wifiNetworksForDevice(networkPopupColumn.device)

                        Rectangle {
                            width: networkPopupColumn.width
                            height: 34
                            radius: 17
                            color: modelData.connected ? activePillColor : networkMouse.containsMouse ? "#4a282828" : pillColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: modelData.connected ? "" : ""
                                    color: networkTextColor
                                    font.family: iconFont
                                    font.pixelSize: 14
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.name || "Hidden network"
                                    color: textColor
                                    font.family: barFont
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: wifiNetworkLockIcon(modelData)
                                    color: mutedTextColor
                                    font.family: iconFont
                                    font.pixelSize: 12
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: Math.round(modelData.signalStrength) + "%"
                                    color: networkTextColor
                                    font.family: barFont
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: wifiNetworkStatusText(modelData)
                                    color: mutedTextColor
                                    font.family: barFont
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 72
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: networkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: connectWifiNetwork(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: clockPopup
        parentWindow: barWindow
        visible: clockPopupOpen || clockPopupClosing
        implicitWidth: 300
        implicitHeight: clockPopupContent.implicitHeight
        relativeX: popupXForItem(clockPill, implicitWidth)
        relativeY: popupYForItem(clockPill)
        color: "transparent"
        grabFocus: clockPopupOpen
        onVisibleChanged: {
            if (!visible) clockPopupOpen = false;
        }

        Rectangle {
            id: clockPopupContent
            width: parent.width
            y: clockPopupOpen ? 0 : -popupAnimationOffset
            opacity: clockPopupOpen ? 1 : 0
            scale: clockPopupOpen ? 1 : 0.96
            transformOrigin: Item.Top
            implicitHeight: clockPopupColumn.implicitHeight + 24
            radius: 18
            color: "#cc121212"
            border.color: "#22ffffff"
            border.width: 1

            Behavior on y { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: popupAnimationMs; easing.type: Easing.OutCubic } }

            Column {
                id: clockPopupColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 12

                RowLayout {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        text: ""
                        color: clockTextColor
                        font.family: iconFont
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: calendarMonthTitle()
                        color: textColor
                        font.family: barFont
                        font.pixelSize: 15
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: Qt.formatDate(new Date(), "ddd")
                        color: clockTextColor
                        font.family: barFont
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#18ffffff"
                }

                Grid {
                    width: parent.width
                    columns: 7
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                        Text {
                            width: (clockPopupColumn.width - 36) / 7
                            height: 22
                            text: modelData
                            color: mutedTextColor
                            font.family: barFont
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Repeater {
                        model: 42

                        Rectangle {
                            property var day: calendarCellDay(index)
                            property bool isToday: day !== "" && day === new Date().getDate()

                            width: (clockPopupColumn.width - 36) / 7
                            height: width
                            radius: width / 2
                            color: isToday ? clockTextColor : "transparent"
                            border.color: isToday ? clockTextColor : "transparent"
                            border.width: isToday ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: parent.day
                                color: parent.isToday ? "#121212" : (parent.day === "" ? "transparent" : textColor)
                                font.family: barFont
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss")
                    color: clockTextColor
                    font.family: barFont
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
