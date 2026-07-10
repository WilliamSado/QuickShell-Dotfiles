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
}
