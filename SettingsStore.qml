import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property string path: "/home/sado/.config/quickshell/state/settings.json"
    property string languageCode: "zh_CN"
    property string themeName: "Tela Cyan"
    property string themeMode: "dark"
    property string wallpaperPath: ""
    property var wallpaperDirectories: ["/home/sado/Pictures/wallpapers"]
    property bool wallpaperRotationEnabled: false
    property int wallpaperRotationMinutes: 30
    property bool wallpaperRotationRandom: true
    property int popupAnimationMs: 260
    property int popupAnimationOffset: 32
    property bool hyprBlurEnabled: true
    property int hyprBlurSize: 8
    property int hyprBlurPasses: 2
    property real hyprBlurVibrancy: 0.2
    property bool hyprAnimationsEnabled: true
    property bool qsAnimationsEnabled: true
    property real popupOpacity: 0.8
    property real pillOpacity: 0.2
    property bool doNotDisturb: false
    property string powerProfile: "balanced"
    property int rememberedVolumePercent: -1
    property int rememberedBrightnessPercent: -1
    property int rememberedSourcePercent: -1
    property bool rememberedMuted: false
    property bool rememberedSourceMuted: false
    property bool focusModeEnabled: false
    property bool mediaHiddenInFocus: true
    property int focusTimerMinutes: 25
    property bool dynamicThemeEnabled: false
    property var dynamicThemeColors: ({})
    property var recentLauncherApps: []
    property bool focusDimNotifications: false
    property string captureLastPath: ""
    property bool gameModeEnabled: false
    property var todoItems: []

    signal loaded()
    signal saved()

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function load() {
        loadProc.running = true;
    }

    function save() {
        var data = {
            "languageCode": languageCode,
            "themeName": themeName,
            "themeMode": themeMode,
            "wallpaperPath": wallpaperPath,
            "wallpaperDirectories": wallpaperDirectories,
            "wallpaperRotationEnabled": wallpaperRotationEnabled,
            "wallpaperRotationMinutes": wallpaperRotationMinutes,
            "wallpaperRotationRandom": wallpaperRotationRandom,
            "popupAnimationMs": popupAnimationMs,
            "popupAnimationOffset": popupAnimationOffset,
            "hyprBlurEnabled": hyprBlurEnabled,
            "hyprBlurSize": hyprBlurSize,
            "hyprBlurPasses": hyprBlurPasses,
            "hyprBlurVibrancy": hyprBlurVibrancy,
            "hyprAnimationsEnabled": hyprAnimationsEnabled,
            "qsAnimationsEnabled": qsAnimationsEnabled,
            "popupOpacity": popupOpacity,
            "pillOpacity": pillOpacity,
            "doNotDisturb": doNotDisturb,
            "powerProfile": powerProfile,
            "rememberedVolumePercent": rememberedVolumePercent,
            "rememberedBrightnessPercent": rememberedBrightnessPercent,
            "rememberedSourcePercent": rememberedSourcePercent,
            "rememberedMuted": rememberedMuted,
            "rememberedSourceMuted": rememberedSourceMuted,
            "focusModeEnabled": focusModeEnabled,
            "mediaHiddenInFocus": mediaHiddenInFocus,
            "focusTimerMinutes": focusTimerMinutes,
            "dynamicThemeEnabled": dynamicThemeEnabled,
            "dynamicThemeColors": dynamicThemeColors,
            "recentLauncherApps": recentLauncherApps,
            "focusDimNotifications": focusDimNotifications,
            "captureLastPath": captureLastPath,
            "gameModeEnabled": gameModeEnabled,
            "todoItems": todoItems
        };

        var text = JSON.stringify(data, null, 2);
        saveProc.command = ["sh", "-c", "mkdir -p " + shellQuote(path.replace(/\/[^\/]+$/, "")) + " && printf '%s' " + shellQuote(text) + " > " + shellQuote(path)];
        saveProc.running = true;
    }

    Process {
        id: loadProc
        command: ["sh", "-c", "test -f " + root.shellQuote(root.path) + " && cat " + root.shellQuote(root.path) + " || printf '{}'"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    var data = JSON.parse(text || "{}");
                    if (data.languageCode !== undefined) root.languageCode = data.languageCode;
                    if (data.themeName !== undefined) root.themeName = data.themeName;
                    if (data.themeMode !== undefined) root.themeMode = data.themeMode;
                    if (data.wallpaperPath !== undefined) root.wallpaperPath = data.wallpaperPath;
                    if (data.wallpaperDirectories !== undefined && data.wallpaperDirectories.length !== undefined) root.wallpaperDirectories = data.wallpaperDirectories;
                    if (data.wallpaperRotationEnabled !== undefined) root.wallpaperRotationEnabled = data.wallpaperRotationEnabled;
                    if (data.wallpaperRotationMinutes !== undefined) root.wallpaperRotationMinutes = data.wallpaperRotationMinutes;
                    if (data.wallpaperRotationRandom !== undefined) root.wallpaperRotationRandom = data.wallpaperRotationRandom;
                    if (data.popupAnimationMs !== undefined) root.popupAnimationMs = data.popupAnimationMs;
                    if (data.popupAnimationOffset !== undefined) root.popupAnimationOffset = data.popupAnimationOffset;
                    if (data.hyprBlurEnabled !== undefined) root.hyprBlurEnabled = data.hyprBlurEnabled;
                    if (data.hyprBlurSize !== undefined) root.hyprBlurSize = data.hyprBlurSize;
                    if (data.hyprBlurPasses !== undefined) root.hyprBlurPasses = data.hyprBlurPasses;
                    if (data.hyprBlurVibrancy !== undefined) root.hyprBlurVibrancy = data.hyprBlurVibrancy;
                    if (data.hyprAnimationsEnabled !== undefined) root.hyprAnimationsEnabled = data.hyprAnimationsEnabled;
                    if (data.qsAnimationsEnabled !== undefined) root.qsAnimationsEnabled = data.qsAnimationsEnabled;
                    if (data.popupOpacity !== undefined) root.popupOpacity = data.popupOpacity;
                    if (data.pillOpacity !== undefined) root.pillOpacity = data.pillOpacity;
                    if (data.doNotDisturb !== undefined) root.doNotDisturb = data.doNotDisturb;
                    if (data.powerProfile !== undefined) root.powerProfile = data.powerProfile;
                    if (data.rememberedVolumePercent !== undefined) root.rememberedVolumePercent = data.rememberedVolumePercent;
                    if (data.rememberedBrightnessPercent !== undefined) root.rememberedBrightnessPercent = data.rememberedBrightnessPercent;
                    if (data.rememberedSourcePercent !== undefined) root.rememberedSourcePercent = data.rememberedSourcePercent;
                    if (data.rememberedMuted !== undefined) root.rememberedMuted = data.rememberedMuted;
                    if (data.rememberedSourceMuted !== undefined) root.rememberedSourceMuted = data.rememberedSourceMuted;
                    if (data.focusModeEnabled !== undefined) root.focusModeEnabled = data.focusModeEnabled;
                    if (data.mediaHiddenInFocus !== undefined) root.mediaHiddenInFocus = data.mediaHiddenInFocus;
                    if (data.focusTimerMinutes !== undefined) root.focusTimerMinutes = data.focusTimerMinutes;
                    if (data.dynamicThemeEnabled !== undefined) root.dynamicThemeEnabled = data.dynamicThemeEnabled;
                    if (data.dynamicThemeColors !== undefined) root.dynamicThemeColors = data.dynamicThemeColors;
                    if (data.recentLauncherApps !== undefined && data.recentLauncherApps.length !== undefined) root.recentLauncherApps = data.recentLauncherApps;
                    if (data.focusDimNotifications !== undefined) root.focusDimNotifications = data.focusDimNotifications;
                    if (data.captureLastPath !== undefined) root.captureLastPath = data.captureLastPath;
                    if (data.gameModeEnabled !== undefined) root.gameModeEnabled = data.gameModeEnabled;
                    if (data.todoItems !== undefined && data.todoItems.length !== undefined) root.todoItems = data.todoItems;
                } catch (error) {
                    console.warn("Could not parse quickshell settings:", error);
                }

                root.loaded();
            }
        }
    }

    Process {
        id: saveProc
        command: ["sh", "-c", "true"]
        onExited: root.saved()
    }

    Component.onCompleted: load()
}
