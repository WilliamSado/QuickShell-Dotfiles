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
    property string capturePendingPath: ""
    property var captureTools: ({})
    property var windowItems: []
    property string windowFilter: "all"
    property int activeWorkspaceId: -1
    property string windowStatus: "Ready"
    property string scratchStatus: "Ready"
    property string maintenanceStatus: "Ready"
    property string maintenanceUpdates: "--"
    property string maintenanceAurUpdates: "--"
    property string maintenanceCacheSize: "--"
    property bool maintenanceBusy: false
    property var vpnItems: []
    property string vpnStatus: "Ready"
    property bool vpnBusy: false
    property var serviceItems: []
    property string servicesStatus: "Ready"
    property bool servicesBusy: false
    property var keybindItems: []
    property string keybindsStatus: "Ready"
    property string todoInput: ""
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
        { type: "builtin", icon: "󰄱", name: "Todo", sub: "Quick tasks", action: "todo" },
        { type: "builtin", icon: "󰖯", name: "Windows", sub: "Window manager", action: "windows" },
        { type: "builtin", icon: "󰹑", name: "Scratchpad", sub: "Special workspace", action: "scratch" },
        { type: "builtin", icon: "󰖂", name: "VPN", sub: "Network tunnel", action: "vpn" },
        { type: "builtin", icon: "󰏖", name: "Maintenance", sub: "Updates / cache", action: "maintenance" },
        { type: "builtin", icon: "󰒋", name: "Services", sub: "User session daemons", action: "services" },
        { type: "builtin", icon: "󰌌", name: "Keybinds", sub: "Hyprland shortcuts", action: "keybinds" },
        { type: "builtin", icon: "󰊴", name: "Game Mode", sub: "Performance focus", action: "game" },
        { type: "builtin", icon: "󰒲", name: "Focus", sub: "Toggle focus mode", action: "focus" }
    ]

    readonly property int relativeX: popup.relativeX
    readonly property int relativeY: popup.relativeY
    implicitWidth: popup.implicitWidth
    implicitHeight: popup.implicitHeight

    Connections {
        target: root.bar

        function onControlCenterPageChanged() {
            if (!root.bar.controlCenterOpen) return;
            if (root.bar.controlCenterPage === "launcher") {
                root.refreshLauncher();
                root.refreshWindows();
            } else if (root.bar.controlCenterPage === "todo") {
                Qt.callLater(function() { todoInputField.forceActiveFocus(); });
            } else if (root.bar.controlCenterPage === "clipboard") {
                root.refreshClipboard();
            } else if (root.bar.controlCenterPage === "capture") {
                root.refreshCaptureTools();
            } else if (root.bar.controlCenterPage === "windows") {
                root.refreshWindows();
            } else if (root.bar.controlCenterPage === "scratch") {
                root.refreshWindows();
            } else if (root.bar.controlCenterPage === "vpn") {
                root.refreshVpn();
            } else if (root.bar.controlCenterPage === "maintenance") {
                root.refreshMaintenance();
            } else if (root.bar.controlCenterPage === "services") {
                root.refreshServices();
            } else if (root.bar.controlCenterPage === "keybinds") {
                root.refreshKeybinds();
            }
        }
    }

    readonly property var pages: [
        { key: "launcher", label: "Launch", icon: "" },
        { key: "clipboard", label: "Clip", icon: "" },
        { key: "todo", label: "Todo", icon: "󰄱" },
        { key: "capture", label: "Shot", icon: "" },
        { key: "windows", label: "Win", icon: "󰖯" },
        { key: "scratch", label: "Pad", icon: "󰹑" },
        { key: "vpn", label: "VPN", icon: "󰖂" },
        { key: "maintenance", label: "Clean", icon: "󰏖" },
        { key: "services", label: "Svc", icon: "󰒋" },
        { key: "keybinds", label: "Keys", icon: "󰌌" },
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
        if (root.bar.controlCenterPage === "todo") return 310;
        if (root.bar.controlCenterPage === "capture") return 292;
        if (root.bar.controlCenterPage === "windows") return 350;
        if (root.bar.controlCenterPage === "scratch") return 310;
        if (root.bar.controlCenterPage === "vpn") return 310;
        if (root.bar.controlCenterPage === "maintenance") return 310;
        if (root.bar.controlCenterPage === "services") return 310;
        if (root.bar.controlCenterPage === "keybinds") return 330;
        if (root.bar.controlCenterPage === "focus") return 330;
        return 170;
    }

    function refreshClipboard() {
        clipboardStatus = "Loading";
        clipboardListProc.running = true;
    }

    function todoRemaining() {
        var count = 0;
        var items = root.bar.todoItems || [];
        for (var i = 0; i < items.length; i++) {
            if (!items[i].done) count++;
        }
        return count;
    }

    function addTodo() {
        var text = todoInput.trim();
        if (text.length === 0) return;

        var items = (root.bar.todoItems || []).slice();
        items.unshift({
            id: Date.now(),
            text: text,
            done: false
        });
        root.bar.todoItems = items.slice(0, 40);
        todoInput = "";
        root.bar.persistSettings();
        root.bar.showToast("󰄱", "Todo", "Added", "success", -1, 1200);
    }

    function toggleTodo(index) {
        var items = (root.bar.todoItems || []).slice();
        if (index < 0 || index >= items.length) return;
        var item = items[index];
        items[index] = {
            id: item.id,
            text: item.text,
            done: !item.done
        };
        root.bar.todoItems = items;
        root.bar.persistSettings();
        root.bar.showToast("󰄱", "Todo", items[index].done ? "Completed" : "Restored", "info", -1, 1000);
    }

    function deleteTodo(index) {
        var items = (root.bar.todoItems || []).slice();
        if (index < 0 || index >= items.length) return;
        items.splice(index, 1);
        root.bar.todoItems = items;
        root.bar.persistSettings();
        root.bar.showToast("󰄱", "Todo", "Deleted", "info", -1, 1000);
    }

    function clipboardPreview(line) {
        var text = String(line || "").replace(/^\s*\d+\s+/, "");
        text = text.replace(/\s+/g, " ").trim();
        return text.length > 0 ? text : "Clipboard item";
    }

    function copyClipboardItem(line) {
        if (!line) return;
        clipboardStatus = "Copied";
        root.bar.showToast("", "Clipboard", "Item copied", "success", -1, 1200);
        clipboardCopyProc.command = ["sh", "-c", "printf '%s' " + shellQuote(line) + " | cliphist decode | wl-copy"];
        clipboardCopyProc.running = true;
    }

    function clearClipboard() {
        clipboardStatus = "Clearing";
        root.bar.showToast("", "Clipboard", "Clearing history", "info", -1, 1200);
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
        capturePendingPath = path || "";
        if (path) root.bar.captureLastPath = path;
        root.bar.closeControlCenter();
        root.bar.showToast("", "Capture", status || "Running", "info", -1, 1200);
        captureProc.command = ["sh", "-c", "sleep 0.15; " + command];
        captureProc.running = true;
    }

    function captureFullscreen() {
        var path = capturePath("screenshot", "png");
        if (!captureActionEnabled("fullscreen")) {
            captureStatus = "Missing tool";
            root.bar.showToast("", "Capture", captureStatus, "error", -1, 1600);
            return;
        }
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && grim " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Fullscreen saved", path);
    }

    function captureRegion() {
        var path = capturePath("region", "png");
        if (!captureActionEnabled("region")) {
            captureStatus = "Missing tool";
            root.bar.showToast("", "Capture", captureStatus, "error", -1, 1600);
            return;
        }
        runCapture("mkdir -p " + shellQuote("/home/sado/Pictures/Screenshots") + " && area=$(slurp) && [ -n \"$area\" ] && grim -g \"$area\" " + shellQuote(path) + " && wl-copy < " + shellQuote(path), "Region saved", path);
    }

    function captureWindow() {
        var path = capturePath("window", "png");
        if (!captureActionEnabled("window")) {
            captureStatus = "Missing tool";
            root.bar.showToast("", "Capture", captureStatus, "error", -1, 1600);
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
            root.bar.showToast("󰑊", "Recording", "Stopped", "success", -1, 1500);
            return;
        }

        if (!captureActionEnabled("record")) {
            captureStatus = "Missing tool";
            root.bar.showToast("󰑊", "Recording", captureStatus, "error", -1, 1600);
            return;
        }

        var path = capturePath("record", "mp4");
        root.bar.closeControlCenter();
        recordProc.command = ["sh", "-c", "sleep 0.15; mkdir -p " + shellQuote("/home/sado/Videos/Recordings") + " && area=$(slurp) && [ -n \"$area\" ] && wf-recorder -g \"$area\" -f " + shellQuote(path)];
        recordProc.running = true;
        recording = true;
        recordingPath = path;
        captureStatus = "Recording";
        root.bar.showToast("󰑊", "Recording", "Started", "info", -1, 1500);
    }

    function pickColor() {
        if (!captureActionEnabled("color")) {
            captureStatus = "Missing tool";
            root.bar.showToast("", "Color Picker", captureStatus, "error", -1, 1600);
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
        root.bar.showToast("", "Capture", "Path copied", "success", -1, 1200);
    }

    function refreshWindows() {
        windowStatus = "Loading";
        activeWorkspaceProc.running = true;
        windowListProc.running = true;
    }

    function parseWindows(text) {
        try {
            var clients = JSON.parse(text || "[]");
            clients.sort(function(a, b) {
                var af = a.focusHistoryID !== undefined ? a.focusHistoryID : 9999;
                var bf = b.focusHistoryID !== undefined ? b.focusHistoryID : 9999;
                if (af !== bf) return af - bf;
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

    function visibleWindowItems() {
        if (windowFilter !== "current" || activeWorkspaceId < 0) return windowItems;
        return windowItems.filter(function(window) {
            return window && window.workspace && window.workspace.id === activeWorkspaceId;
        });
    }

    function scratchWindowItems() {
        return windowItems.filter(function(window) {
            if (!window || !window.workspace) return false;
            var name = String(window.workspace.name || "");
            return name.indexOf("special") === 0 || window.workspace.id < 0;
        });
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
        root.bar.showToast("󰖯", "Window", windowStatus, "info", -1, 1200);
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

    function toggleScratchpad() {
        scratchStatus = "Toggled";
        root.bar.showToast("󰹑", "Scratchpad", "Toggle special workspace", "info", -1, 1200);
        scratchCommandProc.command = ["hyprctl", "dispatch", "togglespecialworkspace", "scratch"];
        scratchCommandProc.running = true;
    }

    function moveActiveToScratchpad() {
        scratchStatus = "Moving active window";
        root.bar.showToast("󰹑", "Scratchpad", scratchStatus, "info", -1, 1200);
        scratchCommandProc.command = ["hyprctl", "dispatch", "movetoworkspacesilent", "special:scratch"];
        scratchCommandProc.running = true;
    }

    function moveScratchWindowToCurrent(window) {
        if (!window || !window.address) return;
        scratchStatus = "Moving window back";
        root.bar.showToast("󰹑", "Scratchpad", scratchStatus, "info", -1, 1200);
        scratchCommandProc.command = ["sh", "-c", "ws=$(hyprctl activeworkspace -j | jq -r '.id'); hyprctl dispatch movetoworkspacesilent \"$ws,address:" + window.address + "\""];
        scratchCommandProc.running = true;
    }

    function focusScratchWindow(window) {
        if (!window || !window.address) return;
        scratchStatus = "Focusing";
        root.bar.showToast("󰹑", "Scratchpad", scratchStatus, "info", -1, 1000);
        scratchCommandProc.command = ["hyprctl", "dispatch", "focuswindow", "address:" + window.address];
        scratchCommandProc.running = true;
    }

    function refreshLauncher() {
        launcherStatus = "Loading apps";
        launcherAppsProc.running = true;
    }

    function refreshMaintenance() {
        if (maintenanceBusy) return;
        maintenanceBusy = true;
        maintenanceStatus = "Checking";
        maintenanceUpdates = "--";
        maintenanceAurUpdates = "--";
        maintenanceCacheSize = "--";
        maintenanceRefreshProc.running = true;
    }

    function runMaintenanceAction(action) {
        if (action === "refresh") {
            refreshMaintenance();
            return;
        }

        if (maintenanceBusy) return;
        maintenanceBusy = true;

        if (action === "upgrade") {
            maintenanceStatus = "Opening updater";
            root.bar.showToast("󰏖", "Maintenance", maintenanceStatus, "info", -1, 1300);
            maintenanceCommandProc.command = ["sh", "-c", "term=${TERMINAL:-}; cmd='if command -v paru >/dev/null 2>&1; then paru -Syu; elif command -v yay >/dev/null 2>&1; then yay -Syu; else sudo pacman -Syu; fi; printf \"\\nPress enter to close...\"; read _'; if [ -n \"$term\" ]; then setsid -f $term -e sh -lc \"$cmd\"; elif command -v alacritty >/dev/null 2>&1; then setsid -f alacritty -e sh -lc \"$cmd\"; elif command -v kitty >/dev/null 2>&1; then setsid -f kitty sh -lc \"$cmd\"; elif command -v foot >/dev/null 2>&1; then setsid -f foot sh -lc \"$cmd\"; else exit 1; fi >/tmp/quickshell-maintenance.log 2>&1"];
        } else if (action === "clean") {
            maintenanceStatus = "Cleaning cache";
            root.bar.showToast("󰏖", "Maintenance", maintenanceStatus, "info", -1, 1300);
            maintenanceCommandProc.command = ["sh", "-c", "if command -v paccache >/dev/null 2>&1; then paccache -rk2; elif command -v paru >/dev/null 2>&1; then paru -Sc --noconfirm; elif command -v yay >/dev/null 2>&1; then yay -Sc --noconfirm; else exit 127; fi >/tmp/quickshell-maintenance.log 2>&1"];
        } else {
            maintenanceBusy = false;
            return;
        }

        maintenanceCommandProc.running = true;
    }

    function parseMaintenance(text) {
        var lines = String(text || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            var idx = line.indexOf("=");
            if (idx < 0) continue;

            var key = line.slice(0, idx);
            var value = line.slice(idx + 1).trim();
            if (key === "pacman") maintenanceUpdates = value;
            else if (key === "aur") maintenanceAurUpdates = value;
            else if (key === "cache") maintenanceCacheSize = value;
            else if (key === "status") maintenanceStatus = value;
        }
    }

    function refreshVpn() {
        if (vpnBusy) return;
        vpnBusy = true;
        vpnStatus = "Loading";
        vpnListProc.running = true;
    }

    function parseVpnItems(text) {
        var items = [];
        var byName = ({});
        var lines = String(text || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.length === 0) continue;
            if (line.indexOf("status=") === 0) {
                vpnStatus = line.slice(7);
                continue;
            }

            var parts = line.split("\t");
            if (parts.length < 3) continue;
            var name = parts[0];
            var next = {
                name: parts[0],
                type: parts[1],
                active: parts[2] === "active",
                device: parts.length >= 4 ? parts[3] : ""
            };

            if (byName[name] !== undefined) {
                if (next.active) items[byName[name]] = next;
            } else {
                byName[name] = items.length;
                items.push(next);
            }
        }

        vpnItems = items;
        if (vpnStatus === "Loading" || vpnStatus === "Ready") {
            var activeCount = 0;
            for (var j = 0; j < items.length; j++) {
                if (items[j].active) activeCount++;
            }
            vpnStatus = items.length === 0 ? "No VPN profiles" : activeCount > 0 ? activeCount + " active" : items.length + " profiles";
        }
    }

    function toggleVpn(item) {
        if (!item || !item.name || vpnBusy) return;
        vpnBusy = true;
        vpnStatus = item.active ? "Disconnecting " + item.name : "Connecting " + item.name;
        root.bar.showToast("󰖂", "VPN", vpnStatus, "info", -1, 1400);
        vpnCommandProc.command = ["nmcli", "connection", item.active ? "down" : "up", item.name];
        vpnCommandProc.running = true;
    }

    function refreshServices() {
        if (servicesBusy) return;
        servicesBusy = true;
        servicesStatus = "Checking";
        serviceItems = [];
        servicesListProc.running = true;
    }

    function parseServices(text) {
        var items = [];
        var activeCount = 0;
        var lines = String(text || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.length === 0) continue;
            if (line.indexOf("status=") === 0) {
                servicesStatus = line.slice(7);
                continue;
            }

            var parts = line.split("\t");
            if (parts.length < 4) continue;
            var active = parts[1] === "active";
            if (active) activeCount++;
            items.push({
                unit: parts[0],
                active: active,
                state: parts[1],
                subState: parts[2],
                description: parts[3]
            });
        }

        serviceItems = items;
        if (servicesStatus === "Checking" || servicesStatus === "Ready") {
            servicesStatus = items.length === 0 ? "No user services" : activeCount + " active / " + items.length;
        }
    }

    function restartService(item) {
        if (!item || !item.unit || servicesBusy) return;
        servicesBusy = true;
        servicesStatus = "Restarting " + item.unit;
        root.bar.showToast("󰒋", "Services", servicesStatus, "info", -1, 1400);
        servicesCommandProc.command = ["systemctl", "--user", "restart", item.unit];
        servicesCommandProc.running = true;
    }

    function refreshKeybinds() {
        keybindsStatus = "Loading";
        keybindItems = [];
        keybindsListProc.running = true;
    }

    function parseKeybinds(text) {
        var items = [];
        var group = "General";
        var lines = String(text || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var raw = lines[i];
            var line = raw.trim();
            if (line.length === 0) continue;
            if (line[0] === "#") {
                var nextGroup = line.replace(/^#+\s*/, "").trim();
                if (nextGroup.length > 0) group = nextGroup;
                continue;
            }
            if (line.indexOf("bind") !== 0 || line.indexOf("=") < 0) continue;

            var value = line.slice(line.indexOf("=") + 1).trim();
            var parts = value.split(",");
            if (parts.length < 3) continue;

            var mods = parts[0].trim();
            var key = parts[1].trim();
            var action = parts[2].trim();
            var args = parts.slice(3).join(",").trim();
            if (key.length === 0) key = "special";

            items.push({
                group: group,
                combo: (mods.length > 0 ? mods.replace(/\$mainMod/g, "Super") + " + " : "") + key,
                action: action,
                args: args,
                raw: raw
            });
        }

        keybindItems = items;
        keybindsStatus = items.length > 0 ? items.length + " shortcuts" : "No keybinds";
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
        var rawQuery = launcherQuery.trim();
        if (rawQuery.length > 1 && rawQuery[0] === "=") {
            return [{ type: "command", icon: "󰃬", name: "Calculate", sub: rawQuery.slice(1).trim(), action: "calc", commandText: rawQuery.slice(1).trim() }];
        }
        if (rawQuery.length > 1 && rawQuery[0] === "?") {
            return [{ type: "command", icon: "󰖟", name: "Search web", sub: rawQuery.slice(1).trim(), action: "webQuery", commandText: rawQuery.slice(1).trim() }];
        }
        if (rawQuery.length > 1 && rawQuery[0] === "@") {
            return [{ type: "command", icon: "󰖟", name: "Open URL", sub: rawQuery.slice(1).trim(), action: "openUrl", commandText: rawQuery.slice(1).trim() }];
        }
        if (rawQuery.length > 1 && rawQuery[0] === ">") {
            return [{ type: "command", icon: "󰘳", name: "Hyprland dispatch", sub: rawQuery.slice(1).trim(), action: "hyprDispatch", commandText: rawQuery.slice(1).trim() }];
        }

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
            root.bar.showToast("", "Launcher", item.name, "info", -1, 1400);
            launcherCommandProc.command = ["sh", "-c", command];
            launcherCommandProc.running = true;
            return;
        }

        if (item.type === "window") {
            focusWindow(item.window);
            return;
        }

        if (item.type === "command") {
            launchCommandItem(item);
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
                root.bar.showToast("󰖟", "Web Search", launcherStatus, "warning", -1, 1400);
                return;
            }
            root.bar.closeControlCenter();
            root.bar.showToast("󰖟", "Web Search", query, "info", -1, 1400);
            launcherCommandProc.command = ["sh", "-c", "setsid -f xdg-open " + shellQuote("https://duckduckgo.com/?q=" + encodeURIComponent(query)) + " >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "files") {
            root.bar.closeControlCenter();
            root.bar.showToast("", "Files", "Opening home", "info", -1, 1200);
            launcherCommandProc.command = ["sh", "-c", "setsid -f xdg-open \"$HOME\" >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "terminal") {
            root.bar.closeControlCenter();
            root.bar.showToast("", "Terminal", "Opening terminal", "info", -1, 1200);
            launcherCommandProc.command = ["sh", "-c", "term=${TERMINAL:-}; if [ -n \"$term\" ]; then setsid -f $term; elif command -v alacritty >/dev/null 2>&1; then setsid -f alacritty; elif command -v kitty >/dev/null 2>&1; then setsid -f kitty; elif command -v foot >/dev/null 2>&1; then setsid -f foot; else exit 1; fi >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "reload") {
            root.bar.closeControlCenter();
            root.bar.showToast("󰑓", "Quickshell", "Reloading", "info", -1, 1200);
            launcherCommandProc.command = ["sh", "-c", "qs kill -p /home/sado/.config/quickshell && qs -p /home/sado/.config/quickshell -d >/tmp/quickshell-launcher.log 2>&1"];
            launcherCommandProc.running = true;
        } else if (item.action === "settings") {
            root.bar.openHyprSettings();
        } else if (item.action === "capture") {
            root.bar.controlCenterPage = "capture";
        } else if (item.action === "clipboard") {
            root.bar.controlCenterPage = "clipboard";
            refreshClipboard();
        } else if (item.action === "todo") {
            root.bar.controlCenterPage = "todo";
            Qt.callLater(function() { todoInputField.forceActiveFocus(); });
        } else if (item.action === "windows") {
            root.bar.controlCenterPage = "windows";
            refreshWindows();
        } else if (item.action === "scratch") {
            root.bar.controlCenterPage = "scratch";
            refreshWindows();
        } else if (item.action === "vpn") {
            root.bar.controlCenterPage = "vpn";
            refreshVpn();
        } else if (item.action === "maintenance") {
            root.bar.controlCenterPage = "maintenance";
            refreshMaintenance();
        } else if (item.action === "services") {
            root.bar.controlCenterPage = "services";
            refreshServices();
        } else if (item.action === "keybinds") {
            root.bar.controlCenterPage = "keybinds";
            refreshKeybinds();
        } else if (item.action === "game") {
            root.bar.toggleGameMode();
            root.bar.closeControlCenter();
        } else if (item.action === "focus") {
            root.bar.toggleFocusMode();
        }
    }

    function launchCommandItem(item) {
        var text = String(item.commandText || "").trim();
        if (text.length === 0) {
            launcherStatus = "Empty command";
            root.bar.showToast("", "Launcher", launcherStatus, "warning", -1, 1300);
            return;
        }

        root.bar.closeControlCenter();
        if (item.action === "calc") {
            launcherStatus = "Calculating";
            var py = "import math; expr=" + JSON.stringify(text) + "; allowed={k:getattr(math,k) for k in dir(math) if not k.startswith('_')}; allowed.update({'abs':abs,'round':round,'min':min,'max':max,'pow':pow}); print(eval(expr, {'__builtins__':{}}, allowed))";
            launcherCommandProc.command = ["sh", "-c", "python3 -c " + shellQuote(py) + " >/tmp/quickshell-launcher.log 2>&1 && wl-copy < /tmp/quickshell-launcher.log"];
            root.bar.showToast("󰃬", "Calculator", text, "info", -1, 1300);
            launcherCommandProc.running = true;
            return;
        }

        if (item.action === "webQuery") {
            launcherStatus = "Searching";
            launcherCommandProc.command = ["sh", "-c", "setsid -f xdg-open " + shellQuote("https://duckduckgo.com/?q=" + encodeURIComponent(text)) + " >/tmp/quickshell-launcher.log 2>&1"];
            root.bar.showToast("󰖟", "Web Search", text, "info", -1, 1300);
            launcherCommandProc.running = true;
            return;
        }

        if (item.action === "openUrl") {
            launcherStatus = "Opening URL";
            var url = text.match(/^https?:\/\//) ? text : "https://" + text;
            launcherCommandProc.command = ["sh", "-c", "setsid -f xdg-open " + shellQuote(url) + " >/tmp/quickshell-launcher.log 2>&1"];
            root.bar.showToast("󰖟", "Open URL", url, "info", -1, 1300);
            launcherCommandProc.running = true;
            return;
        }

        if (item.action === "hyprDispatch") {
            launcherStatus = "Dispatching";
            launcherCommandProc.command = ["sh", "-c", "hyprctl dispatch " + shellQuote(text) + " >/tmp/quickshell-launcher.log 2>&1"];
            root.bar.showToast("󰘳", "Hyprland", text, "info", -1, 1300);
            launcherCommandProc.running = true;
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
        grabFocus: root.bar.controlCenterOpen && (root.bar.controlCenterPage === "launcher" || root.bar.controlCenterPage === "todo")
        onClosed: root.bar.closeControlCenter()
        onVisibleChanged: {
            if (visible && root.bar.controlCenterPage === "launcher") {
                root.refreshLauncher();
                root.refreshWindows();
                Qt.callLater(function() { launcherSearch.forceActiveFocus(); });
            }
            if (visible && root.bar.controlCenterPage === "todo") Qt.callLater(function() { todoInputField.forceActiveFocus(); });
            if (visible && root.bar.controlCenterPage === "clipboard") root.refreshClipboard();
            if (visible && root.bar.controlCenterPage === "windows") root.refreshWindows();
            if (visible && root.bar.controlCenterPage === "scratch") root.refreshWindows();
            if (visible && root.bar.controlCenterPage === "capture") root.refreshCaptureTools();
            if (visible && root.bar.controlCenterPage === "vpn") root.refreshVpn();
            if (visible && root.bar.controlCenterPage === "maintenance") root.refreshMaintenance();
            if (visible && root.bar.controlCenterPage === "services") root.refreshServices();
            if (visible && root.bar.controlCenterPage === "keybinds") root.refreshKeybinds();
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
                                    visible: root.pages.length <= 7
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
                                    if (modelData.key === "todo") Qt.callLater(function() { todoInputField.forceActiveFocus(); });
                                    if (modelData.key === "clipboard") root.refreshClipboard();
                                    if (modelData.key === "windows") root.refreshWindows();
                                    if (modelData.key === "scratch") root.refreshWindows();
                                    if (modelData.key === "capture") root.refreshCaptureTools();
                                    if (modelData.key === "vpn") root.refreshVpn();
                                    if (modelData.key === "maintenance") root.refreshMaintenance();
                                    if (modelData.key === "services") root.refreshServices();
                                    if (modelData.key === "keybinds") root.refreshKeybinds();
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
                        visible: root.bar.controlCenterPage !== "focus" && root.bar.controlCenterPage !== "clipboard" && root.bar.controlCenterPage !== "todo" && root.bar.controlCenterPage !== "capture" && root.bar.controlCenterPage !== "windows" && root.bar.controlCenterPage !== "scratch" && root.bar.controlCenterPage !== "vpn" && root.bar.controlCenterPage !== "maintenance" && root.bar.controlCenterPage !== "launcher"
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
                                text: root.windowFilter === "current" ? root.visibleWindowItems().length + " current" : root.windowStatus
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
                            visible: root.visibleWindowItems().length === 0
                            text: root.windowStatus
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        RowLayout {
                            width: parent.width
                            height: 34
                            spacing: 8

                            Repeater {
                                model: [
                                    { key: "all", label: "All" },
                                    { key: "current", label: "Current" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    radius: 17
                                    color: root.windowFilter === modelData.key ? root.bar.activePillColor : root.bar.pillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: root.windowFilter === modelData.key ? root.bar.textColor : root.bar.mutedTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.windowFilter = modelData.key
                                    }
                                }
                            }
                        }

                        Flickable {
                            width: parent.width
                            height: 232
                            contentWidth: width
                            contentHeight: windowList.implicitHeight
                            clip: true
                            visible: root.visibleWindowItems().length > 0

                            Column {
                                id: windowList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.visibleWindowItems()

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
                        visible: root.bar.controlCenterPage === "scratch"
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
                                text: "󰹑"
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.scratchWindowItems().length + " scratch windows"
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
                                color: scratchRefreshMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "Refresh"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: scratchRefreshMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.refreshWindows()
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
                                    { icon: "󰹑", label: "Toggle pad", sub: "Show / hide", action: "toggle" },
                                    { icon: "󰍉", label: "Send active", sub: "Move focused window", action: "send" }
                                ]

                                Rectangle {
                                    width: (parent.width - 10) / 2
                                    height: 58
                                    radius: 16
                                    color: scratchActionMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: modelData.icon
                                            color: root.bar.textColor
                                            font.family: root.bar.iconFont
                                            font.pixelSize: 16
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
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: scratchActionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (modelData.action === "toggle") root.toggleScratchpad();
                                            else if (modelData.action === "send") root.moveActiveToScratchpad();
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.scratchWindowItems().length === 0
                            text: "No scratchpad windows"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            width: parent.width
                            height: 174
                            contentWidth: width
                            contentHeight: scratchList.implicitHeight
                            clip: true
                            visible: root.scratchWindowItems().length > 0

                            Column {
                                id: scratchList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.scratchWindowItems()

                                    Rectangle {
                                        id: scratchCard
                                        property var windowData: modelData

                                        width: scratchList.width
                                        height: 58
                                        radius: 15
                                        color: scratchItemMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 10

                                            Text {
                                                text: "󰖯"
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
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 30
                                                Layout.preferredHeight: 30
                                                radius: 15
                                                color: scratchMoveMouse.containsMouse ? root.bar.sectionPillColor : "transparent"
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰍉"
                                                    color: root.bar.textColor
                                                    font.family: root.bar.iconFont
                                                    font.pixelSize: 12
                                                }

                                                MouseArea {
                                                    id: scratchMoveMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.moveScratchWindowToCurrent(scratchCard.windowData)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: scratchItemMouse
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.rightMargin: 44
                                            hoverEnabled: true
                                            onClicked: root.focusScratchWindow(modelData)
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
                        visible: root.bar.controlCenterPage === "todo"
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
                            border.color: todoInputField.activeFocus ? root.bar.networkTextColor : "transparent"
                            border.width: todoInputField.activeFocus ? 1 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "󰄱"
                                    color: root.bar.mutedTextColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 14
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                TextInput {
                                    id: todoInputField
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: root.todoInput
                                    color: root.bar.textColor
                                    selectionColor: root.bar.activePillColor
                                    selectedTextColor: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 13
                                    clip: true
                                    onTextChanged: root.todoInput = text
                                    Keys.onEscapePressed: root.bar.closeControlCenter()
                                    Keys.onReturnPressed: root.addTodo()
                                }

                                Rectangle {
                                    Layout.preferredWidth: 54
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: addTodoMouse.containsMouse ? root.bar.activePillColor : root.bar.sectionPillColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Add"
                                        color: root.bar.textColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        id: addTodoMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.addTodo()
                                    }
                                }
                            }
                        }

                        RowLayout {
                            width: parent.width
                            height: 28
                            spacing: 8

                            Text {
                                text: root.todoRemaining() + " active"
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: (root.bar.todoItems || []).length + " total"
                                color: root.bar.mutedTextColor
                                font.family: root.bar.barFont
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        Text {
                            width: parent.width
                            visible: (root.bar.todoItems || []).length === 0
                            text: "No tasks yet"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            width: parent.width
                            height: 208
                            contentWidth: width
                            contentHeight: todoList.implicitHeight
                            clip: true
                            visible: (root.bar.todoItems || []).length > 0

                            Column {
                                id: todoList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.bar.todoItems || []

                                    Rectangle {
                                        width: todoList.width
                                        height: 48
                                        radius: 14
                                        color: todoItemMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor
                                        opacity: modelData.done ? 0.72 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            Rectangle {
                                                Layout.preferredWidth: 24
                                                Layout.preferredHeight: 24
                                                radius: 12
                                                color: modelData.done ? root.bar.networkTextColor : "transparent"
                                                border.color: root.bar.mutedTextColor
                                                border.width: 1
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.done ? "" : ""
                                                    color: root.bar.textColor
                                                    font.family: root.bar.iconFont
                                                    font.pixelSize: 11
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: root.toggleTodo(index)
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                text: modelData.text
                                                color: modelData.done ? root.bar.mutedTextColor : root.bar.textColor
                                                font.family: root.bar.barFont
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 28
                                                Layout.preferredHeight: 28
                                                radius: 14
                                                color: deleteTodoMouse.containsMouse ? root.bar.sectionPillColor : "transparent"
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: ""
                                                    color: root.bar.cpuTextColor
                                                    font.family: root.bar.iconFont
                                                    font.pixelSize: 11
                                                }

                                                MouseArea {
                                                    id: deleteTodoMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.deleteTodo(index)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: todoItemMouse
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 42
                                            anchors.rightMargin: 42
                                            hoverEnabled: true
                                            onClicked: root.toggleTodo(index)
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
                        visible: root.bar.controlCenterPage === "maintenance"
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
                                text: "󰏖"
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.maintenanceStatus
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
                                opacity: root.maintenanceBusy ? 0.55 : 1
                                color: maintenanceRefreshMouse.containsMouse && !root.maintenanceBusy ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.maintenanceBusy ? "Busy" : "Refresh"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: maintenanceRefreshMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.runMaintenanceAction("refresh")
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
                                    { icon: "󰏗", label: "Pacman", value: root.maintenanceUpdates },
                                    { icon: "󰣇", label: "AUR", value: root.maintenanceAurUpdates },
                                    { icon: "󰃨", label: "Cache", value: root.maintenanceCacheSize }
                                ]

                                Rectangle {
                                    width: (parent.width - 20) / 3
                                    height: 74
                                    radius: 16
                                    color: root.bar.pillColor

                                    Column {
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.icon
                                            color: root.bar.networkTextColor
                                            font.family: root.bar.iconFont
                                            font.pixelSize: 16
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.value
                                            color: root.bar.textColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 14
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.label
                                            color: root.bar.mutedTextColor
                                            font.family: root.bar.barFont
                                            font.pixelSize: 10
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "升级会在终端中执行；清理缓存优先使用 paccache -rk2"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: [
                                    { icon: "󰚰", label: "Open updater", sub: "paru/yay/pacman -Syu", action: "upgrade" },
                                    { icon: "󰃢", label: "Clean package cache", sub: "Keep latest 2 versions", action: "clean" }
                                ]

                                Rectangle {
                                    width: parent.width
                                    height: 54
                                    radius: 15
                                    opacity: root.maintenanceBusy ? 0.55 : 1
                                    color: maintenanceActionMouse.containsMouse && !root.maintenanceBusy ? root.bar.activePillColor : root.bar.pillColor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
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
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: maintenanceActionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.runMaintenanceAction(modelData.action)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "keybinds"
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
                                text: "󰌌"
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.keybindsStatus
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
                                color: keybindRefreshMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "Refresh"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: keybindRefreshMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.refreshKeybinds()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "读取 hypr/conf.d/hyprland.d/binds.conf；这里仅做速查，不修改快捷键"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            visible: root.keybindItems.length === 0
                            text: root.keybindsStatus
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            width: parent.width
                            height: 242
                            contentWidth: width
                            contentHeight: keybindsList.implicitHeight
                            clip: true
                            visible: root.keybindItems.length > 0

                            Column {
                                id: keybindsList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.keybindItems

                                    Rectangle {
                                        width: keybindsList.width
                                        height: 54
                                        radius: 15
                                        color: keybindItemMouse.containsMouse ? root.bar.activePillColor : root.bar.pillColor

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 10

                                            Column {
                                                Layout.preferredWidth: 154
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 2

                                                Text {
                                                    width: parent.width
                                                    text: modelData.combo
                                                    color: root.bar.textColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    width: parent.width
                                                    text: modelData.group
                                                    color: root.bar.mutedTextColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 2

                                                Text {
                                                    width: parent.width
                                                    text: modelData.action
                                                    color: root.bar.networkTextColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    width: parent.width
                                                    text: modelData.args.length > 0 ? modelData.args : modelData.raw
                                                    color: root.bar.mutedTextColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: keybindItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "services"
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
                                text: "󰒋"
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.servicesStatus
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
                                opacity: root.servicesBusy ? 0.55 : 1
                                color: servicesRefreshMouse.containsMouse && !root.servicesBusy ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.servicesBusy ? "Busy" : "Refresh"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: servicesRefreshMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.refreshServices()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: "只管理 systemd --user 会话服务；系统级服务不在这里重启"
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            visible: root.serviceItems.length === 0
                            text: root.servicesStatus === "Ready" ? "No user services" : root.servicesStatus
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            width: parent.width
                            height: 222
                            contentWidth: width
                            contentHeight: servicesList.implicitHeight
                            clip: true
                            visible: root.serviceItems.length > 0

                            Column {
                                id: servicesList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.serviceItems

                                    Rectangle {
                                        id: serviceCard
                                        property bool serviceAvailable: modelData.state !== "missing"
                                        width: servicesList.width
                                        height: 58
                                        radius: 16
                                        opacity: root.servicesBusy ? 0.6 : 1
                                        color: serviceItemMouse.containsMouse && !root.servicesBusy ? root.bar.activePillColor : root.bar.pillColor

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 10

                                            Text {
                                                text: modelData.active ? "󰄬" : "󰅖"
                                                color: modelData.active ? root.bar.networkTextColor : root.bar.mutedTextColor
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
                                                    text: modelData.unit
                                                    color: root.bar.textColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    width: parent.width
                                                    text: modelData.state + " / " + modelData.subState + " · " + modelData.description
                                                    color: root.bar.mutedTextColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 74
                                                Layout.preferredHeight: 30
                                                radius: 15
                                                opacity: serviceCard.serviceAvailable ? 1 : 0.45
                                                color: serviceRestartMouse.containsMouse && !root.servicesBusy && serviceCard.serviceAvailable ? root.bar.sectionPillColor : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: serviceCard.serviceAvailable ? "Restart" : "--"
                                                    color: root.bar.mutedTextColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 10
                                                }

                                                MouseArea {
                                                    id: serviceRestartMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        if (serviceCard.serviceAvailable) root.restartService(modelData);
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: serviceItemMouse
                                            anchors.fill: parent
                                            anchors.rightMargin: 86
                                            hoverEnabled: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.bar.controlCenterPage === "vpn"
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
                                text: "󰖂"
                                color: root.bar.networkTextColor
                                font.family: root.bar.iconFont
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.vpnStatus
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
                                opacity: root.vpnBusy ? 0.55 : 1
                                color: vpnRefreshMouse.containsMouse && !root.vpnBusy ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.vpnBusy ? "Busy" : "Refresh"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: vpnRefreshMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.refreshVpn()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.vpnItems.length === 0
                            text: root.vpnStatus === "Ready" ? "No VPN profiles" : root.vpnStatus
                            color: root.bar.mutedTextColor
                            font.family: root.bar.barFont
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            width: parent.width
                            height: 236
                            contentWidth: width
                            contentHeight: vpnList.implicitHeight
                            clip: true
                            visible: root.vpnItems.length > 0

                            Column {
                                id: vpnList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.vpnItems

                                    Rectangle {
                                        width: vpnList.width
                                        height: 58
                                        radius: 16
                                        opacity: root.vpnBusy ? 0.6 : 1
                                        color: modelData.active ? root.bar.activePillColor : vpnItemMouse.containsMouse && !root.vpnBusy ? root.bar.activePillColor : root.bar.pillColor

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 10

                                            Text {
                                                text: modelData.active ? "󰖂" : "󰦝"
                                                color: root.bar.textColor
                                                font.family: root.bar.iconFont
                                                font.pixelSize: 16
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
                                                    text: modelData.active ? "Active" + (modelData.device.length > 0 ? " · " + modelData.device : "") : "Disconnected"
                                                    color: root.bar.mutedTextColor
                                                    font.family: root.bar.barFont
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Text {
                                                text: modelData.active ? "Down" : "Up"
                                                color: root.bar.mutedTextColor
                                                font.family: root.bar.barFont
                                                font.pixelSize: 11
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }

                                        MouseArea {
                                            id: vpnItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.toggleVpn(modelData)
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
                                text: "专注计时"
                                color: root.bar.textColor
                                font.family: root.bar.barFont
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle {
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 32
                                radius: 16
                                color: root.bar.pillColor

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    Text {
                                        text: "-"
                                        color: root.bar.networkTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 14
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -8
                                            onClicked: root.bar.adjustFocusTimerMinutes(-5)
                                        }
                                    }

                                    Text {
                                        text: root.bar.focusTimerText()
                                        color: root.bar.textColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "+"
                                        color: root.bar.networkTextColor
                                        font.family: root.bar.barFont
                                        font.pixelSize: 14
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -8
                                            onClicked: root.bar.adjustFocusTimerMinutes(5)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 78
                                Layout.preferredHeight: 32
                                radius: 16
                                color: focusTimerMouse.containsMouse ? root.bar.activePillColor : root.bar.focusTimerRunning ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.bar.focusTimerRunning ? "Stop" : "Start"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: focusTimerMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (root.bar.focusTimerRunning) root.bar.stopFocusTimer();
                                        else root.bar.startFocusTimer();
                                    }
                                }
                            }
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

                        RowLayout {
                            width: parent.width
                            height: 44
                            spacing: 10

                            Text {
                                text: "降低通知强调度"
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
                                color: root.bar.focusDimNotifications ? root.bar.activePillColor : root.bar.pillColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.bar.focusDimNotifications ? "On" : "Off"
                                    color: root.bar.textColor
                                    font.family: root.bar.barFont
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.bar.toggleFocusDimNotifications()
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
                root.bar.showToast("", "Clipboard", root.clipboardStatus, "error", -1, 1600);
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
            root.bar.showToast("", "Clipboard", root.clipboardStatus, exitCode === 0 ? "success" : "error", -1, 1400);
        }
    }

    Process {
        id: captureProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.captureStatus = "Capture failed";
                root.bar.showToast("", "Capture", root.captureStatus, "error", -1, 1700);
            } else if (root.capturePendingPath.length > 0) {
                root.bar.persistSettings();
                root.bar.showToast("", "Capture", root.capturePendingPath.replace(/^.*\//, ""), "success", -1, 1700);
            } else {
                root.bar.showToast("", "Capture", root.captureStatus, "success", -1, 1400);
            }
            root.capturePendingPath = "";
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
                root.bar.showToast("󰑊", "Recording", root.captureStatus, "error", -1, 1700);
            } else if (root.recordingPath.length > 0) {
                root.bar.captureLastPath = root.recordingPath;
                root.bar.persistSettings();
                root.bar.showToast("󰑊", "Recording", root.recordingPath.replace(/^.*\//, ""), "success", -1, 1700);
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
            if (exitCode !== 0) {
                root.windowStatus = "Window action failed";
                root.bar.showToast("󰖯", "Window", root.windowStatus, "error", -1, 1600);
            } else {
                root.bar.showToast("󰖯", "Window", root.windowStatus, "success", -1, 1300);
            }
            refreshWindowsTimer.restart();
        }
    }

    Process {
        id: scratchCommandProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            root.scratchStatus = exitCode === 0 ? "Done" : "Scratch action failed";
            root.bar.showToast("󰹑", "Scratchpad", root.scratchStatus, exitCode === 0 ? "success" : "error", -1, 1300);
            refreshWindowsTimer.restart();
        }
    }

    Process {
        id: activeWorkspaceProc
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    var workspace = JSON.parse(text || "{}");
                    root.activeWorkspaceId = workspace.id !== undefined ? workspace.id : -1;
                } catch (error) {
                    root.activeWorkspaceId = -1;
                }
            }
        }
    }

    Timer {
        id: refreshWindowsTimer
        interval: 220
        repeat: false
        onTriggered: root.refreshWindows()
    }

    Process {
        id: vpnListProc
        command: ["sh", "-c", "if ! command -v nmcli >/dev/null 2>&1; then printf 'status=nmcli unavailable\\n'; exit 0; fi; nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2 ~ /vpn|wireguard/ { printf \"%s\\t%s\\tdisconnected\\t\\n\", $1, $2 }'; nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | awk -F: '$2 ~ /vpn|wireguard/ { printf \"%s\\t%s\\tactive\\t%s\\n\", $1, $2, $3 }'; printf 'status=Ready\\n'"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseVpnItems(text)
        }

        onExited: function(exitCode) {
            root.vpnBusy = false;
            if (exitCode !== 0) {
                root.vpnItems = [];
                root.vpnStatus = "VPN check failed";
                root.bar.showToast("󰖂", "VPN", root.vpnStatus, "error", -1, 1600);
            }
        }
    }

    Process {
        id: vpnCommandProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            root.vpnBusy = false;
            root.vpnStatus = exitCode === 0 ? "Command sent" : "VPN action failed";
            root.bar.showToast("󰖂", "VPN", root.vpnStatus, exitCode === 0 ? "success" : "error", -1, 1500);
            vpnRefreshDelay.restart();
        }
    }

    Timer {
        id: vpnRefreshDelay
        interval: 700
        repeat: false
        onTriggered: root.refreshVpn()
    }

    Process {
        id: maintenanceRefreshProc
        command: ["sh", "-c", "pacman_count=$(pacman -Qu 2>/dev/null | wc -l); if command -v paru >/dev/null 2>&1; then aur_count=$(paru -Qua 2>/dev/null | wc -l); elif command -v yay >/dev/null 2>&1; then aur_count=$(yay -Qua 2>/dev/null | wc -l); else aur_count=--; fi; cache=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}'); [ -n \"$cache\" ] || cache=--; printf 'pacman=%s\\naur=%s\\ncache=%s\\nstatus=Ready\\n' \"$pacman_count\" \"$aur_count\" \"$cache\""]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseMaintenance(text)
        }

        onExited: function(exitCode) {
            root.maintenanceBusy = false;
            if (exitCode !== 0) {
                root.maintenanceStatus = "Check failed";
                root.bar.showToast("󰏖", "Maintenance", root.maintenanceStatus, "error", -1, 1600);
            } else {
                root.bar.showToast("󰏖", "Maintenance", root.maintenanceUpdates + " pacman / " + root.maintenanceAurUpdates + " AUR", "success", -1, 1400);
            }
        }
    }

    Process {
        id: maintenanceCommandProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            root.maintenanceBusy = false;
            root.maintenanceStatus = exitCode === 0 ? "Command sent" : "Command failed";
            root.bar.showToast("󰏖", "Maintenance", root.maintenanceStatus, exitCode === 0 ? "success" : "error", -1, 1500);
            maintenanceRefreshDelay.restart();
        }
    }

    Timer {
        id: maintenanceRefreshDelay
        interval: 900
        repeat: false
        onTriggered: root.refreshMaintenance()
    }

    Process {
        id: servicesListProc
        command: ["sh", "-c", "if ! command -v systemctl >/dev/null 2>&1; then printf 'status=systemctl unavailable\\n'; exit 0; fi; units='pipewire.service pipewire-pulse.service wireplumber.service xdg-desktop-portal.service xdg-desktop-portal-hyprland.service fcitx5.service'; for unit in $units; do state=$(systemctl --user is-active \"$unit\" 2>/dev/null || true); [ -n \"$state\" ] || state=missing; sub=$(systemctl --user show \"$unit\" -p SubState --value 2>/dev/null || true); [ -n \"$sub\" ] || sub=missing; desc=$(systemctl --user show \"$unit\" -p Description --value 2>/dev/null || true); [ -n \"$desc\" ] || desc=\"$unit\"; printf '%s\\t%s\\t%s\\t%s\\n' \"$unit\" \"$state\" \"$sub\" \"$desc\"; done; printf 'status=Ready\\n'"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseServices(text)
        }

        onExited: function(exitCode) {
            root.servicesBusy = false;
            if (exitCode !== 0) {
                root.serviceItems = [];
                root.servicesStatus = "Service check failed";
                root.bar.showToast("󰒋", "Services", root.servicesStatus, "error", -1, 1600);
            }
        }
    }

    Process {
        id: servicesCommandProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            root.servicesBusy = false;
            root.servicesStatus = exitCode === 0 ? "Restart sent" : "Restart failed";
            root.bar.showToast("󰒋", "Services", root.servicesStatus, exitCode === 0 ? "success" : "error", -1, 1500);
            servicesRefreshDelay.restart();
        }
    }

    Timer {
        id: servicesRefreshDelay
        interval: 900
        repeat: false
        onTriggered: root.refreshServices()
    }

    Process {
        id: keybindsListProc
        command: ["sh", "-c", "cat /home/sado/.config/hypr/conf.d/hyprland.d/binds.conf 2>/dev/null"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseKeybinds(text)
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.keybindItems = [];
                root.keybindsStatus = "Could not read binds";
                root.bar.showToast("󰌌", "Keybinds", root.keybindsStatus, "error", -1, 1600);
            }
        }
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
                root.bar.showToast("", "Launcher", root.launcherStatus, "error", -1, 1600);
            }
        }
    }

    Process {
        id: launcherCommandProc
        command: ["sh", "-c", "true"]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.launcherStatus = "Launch failed";
                root.bar.showToast("", "Launcher", root.launcherStatus, "error", -1, 1600);
            } else {
                root.bar.showToast("", "Launcher", "Command sent", "success", -1, 1100);
            }
        }
    }
}
