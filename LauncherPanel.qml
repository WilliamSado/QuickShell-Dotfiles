import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "config" as Config

Item {
    id: root

    required property var bar
    readonly property int relativeX: popup.relativeX
    readonly property int relativeY: popup.relativeY
    implicitWidth: popup.implicitWidth
    implicitHeight: popup.implicitHeight

    property string query: ""
    property int selectedIndex: 0
    property var appEntries: []
    property var filteredEntries: []
    property var builtins: [
        { type: "command", icon: "", label: "Lock", sub: "hyprlock", command: "hyprlock" },
        { type: "command", icon: "󰑐", label: "Reload QS", sub: "quickshell reload", command: "qs -p /home/sado/.config/quickshell" },
        { type: "command", icon: "", label: "Open Settings", sub: "Hyprland Settings", action: "settings" },
        { type: "command", icon: "", label: "Screenshot", sub: "Capture Center", action: "capture" },
        { type: "command", icon: "󰑊", label: "Record", sub: "Capture Center", action: "capture" },
        { type: "command", icon: "󰒲", label: "Focus Mode", sub: "Toggle focus mode", action: "focus" }
    ]

    function refresh() {
        appsProc.running = true;
        rebuild();
    }

    function focusSearch() {
        searchInput.forceActiveFocus();
        searchInput.selectAll();
    }

    function windowEntries() {
        var entries = [];
        var workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (var i = 0; i < workspaces.length; i++) {
            var ws = workspaces[i];
            var toplevels = ws.toplevels ? ws.toplevels.values : [];
            for (var j = 0; j < toplevels.length; j++) {
                var top = toplevels[j];
                var ipc = top.lastIpcObject || {};
                var app = ipc.class || top.appId || "Window";
                var title = top.title || app;
                var address = ipc.address || "";
                entries.push({
                    type: "window",
                    icon: "󰖯",
                    label: app,
                    sub: title + " · workspace " + (ws.name || ws.id || "?"),
                    address: address
                });
            }
        }
        return entries;
    }

    function rebuild() {
        var q = query.toLowerCase();
        var all = builtins.concat(windowEntries()).concat(appEntries);
        var out = [];
        for (var i = 0; i < all.length; i++) {
            var entry = all[i];
            var haystack = (entry.label + " " + entry.sub).toLowerCase();
            if (q.length === 0 || haystack.indexOf(q) !== -1) out.push(entry);
        }
        filteredEntries = out.slice(0, 12);
        selectedIndex = Math.min(selectedIndex, Math.max(0, filteredEntries.length - 1));
    }

    function runEntry(entry) {
        if (!entry) return;

        if (entry.type === "app") {
            bar.runQuickCommand("gtk-launch " + bar.shellQuote(entry.desktopId) + " || gio launch " + bar.shellQuote(entry.desktopFile), "Launching " + entry.label);
        } else if (entry.type === "window") {
            if (entry.address.length > 0) bar.runQuickCommand("hyprctl dispatch focuswindow address:" + entry.address, "Focusing " + entry.label);
        } else if (entry.action === "settings") {
            bar.openHyprSettings();
        } else if (entry.action === "capture") {
            bar.openCapturePanel();
        } else if (entry.action === "focus") {
            bar.toggleFocusMode();
        } else if (entry.command) {
            bar.runQuickCommand(entry.command, entry.label);
        }
        bar.closeLauncher();
    }

    PopupWindow {
        id: popup
        parentWindow: root.bar
        visible: root.bar.launcherOpen || root.bar.launcherClosing
        implicitWidth: 620
        implicitHeight: panel.implicitHeight
        relativeX: Math.max(root.bar.barSideMargin, (root.bar.width - implicitWidth) / 2)
        relativeY: root.bar.implicitHeight + 24
        color: "transparent"
        grabFocus: false
        onClosed: root.bar.closeLauncher()

        FluidPanel {
            id: panel
            width: parent.width
            implicitHeight: content.implicitHeight + 34
            open: root.bar.launcherOpen
            hiddenY: -18
            shownY: 0
            hiddenScale: 0.92
            transformOrigin: Item.Top
            animationMs: root.bar.popupAnimationMs + 90

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 17
                spacing: 12

                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 24
                    color: root.bar.pillColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: ""
                            color: root.bar.mutedTextColor
                            font.family: root.bar.iconFont
                            font.pixelSize: 17
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: root.bar.textColor
                            selectionColor: root.bar.activePillColor
                            selectedTextColor: root.bar.textColor
                            font.family: root.bar.barFont
                            font.pixelSize: 16
                            text: root.query
                            clip: true
                            onTextChanged: {
                                root.query = text;
                                root.rebuild();
                            }
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Escape) {
                                    root.bar.closeLauncher();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(0, root.filteredEntries.length - 1));
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.runEntry(root.filteredEntries[root.selectedIndex]);
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: root.filteredEntries

                        Rectangle {
                            width: parent.width
                            height: 52
                            radius: 18
                            color: index === root.selectedIndex ? root.bar.activePillColor : mouse.containsMouse ? root.bar.sectionPillColor : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                Text {
                                    text: modelData.icon
                                    color: root.bar.textColor
                                    font.family: root.bar.iconFont
                                    font.pixelSize: 18
                                    Layout.preferredWidth: 24
                                    horizontalAlignment: Text.AlignHCenter
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
                                        font.pixelSize: 14
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
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.runEntry(modelData)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.filteredEntries.length === 0
                        text: "No results"
                        color: root.bar.mutedTextColor
                        font.family: root.bar.barFont
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    Process {
        id: appsProc
        command: ["sh", "-c", "for d in /usr/share/applications \"$HOME/.local/share/applications\"; do [ -d \"$d\" ] || continue; find \"$d\" -maxdepth 1 -name '*.desktop' -print; done | while IFS= read -r f; do name=$(awk -F= '/^NoDisplay=true/{hidden=1} /^Name=/{if (!name) name=$2} END{if (!hidden && name) print name}' \"$f\"); [ -n \"$name\" ] && printf '%s\\t%s\\t%s\\n' \"$name\" \"$(basename \"$f\" .desktop)\" \"$f\"; done | sort -f"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var lines = text.trim().length > 0 ? text.trim().split("\n") : [];
                var entries = [];
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t");
                    if (parts.length < 2) continue;
                    entries.push({
                        type: "app",
                        icon: "󰣆",
                        label: parts[0],
                        sub: parts[1],
                        desktopId: parts[1],
                        desktopFile: parts.length > 2 ? parts[2] : ""
                    });
                }
                root.appEntries = entries;
                root.rebuild();
            }
        }
    }

    onQueryChanged: rebuild()
}
