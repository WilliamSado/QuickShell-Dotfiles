import QtQuick

QtObject {
    property bool bluetoothPopupOpen: false
    property bool volumePopupOpen: false
    property bool networkPopupOpen: false
    property bool clockPopupOpen: false
    property bool powerPopupOpen: false
    property bool hyprSettingsOpen: false
    property bool quickSettingsOpen: false
    property bool bluetoothPopupClosing: false
    property bool volumePopupClosing: false
    property bool networkPopupClosing: false
    property bool clockPopupClosing: false
    property bool powerPopupClosing: false
    property bool hyprSettingsClosing: false
    property bool quickSettingsClosing: false
    property bool suppressQuickSettingsCloseAnimation: false
    property bool audioOutputScanInSinks: false
    property bool audioInputScanInSources: false
    property bool audioOutputsExpanded: false
    property bool audioInputsExpanded: false
    property bool clockShowDate: false
    property bool volumeMuted: false
    property bool sourceMuted: false
    property bool networkShowIp: false
    property bool performancePopupOpen: false
    property bool performancePopupClosing: false
    property bool notificationCenterOpen: false
    property bool notificationCenterClosing: false
    property bool launcherOpen: false
    property bool launcherClosing: false
    property bool clipboardOpen: false
    property bool clipboardClosing: false
    property bool captureOpen: false
    property bool captureClosing: false
    property bool windowSwitcherOpen: false
    property bool windowSwitcherClosing: false
    property bool focusModeEnabled: false
    property bool mediaHiddenInFocus: true
}
