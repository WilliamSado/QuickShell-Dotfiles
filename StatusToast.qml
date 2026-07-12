import Quickshell
import QtQuick
import QtQuick.Layouts
import "config" as Config

PanelWindow {
    id: toastWindow

    required property var bar

    Config.Numbers { id: numbers }

    property string toastIcon: "󰋽"
    property string toastTitle: ""
    property string toastMessage: ""
    property string toastLevel: "info"
    property real toastProgress: -1

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: numbers.toastTopMargin + toastCard.implicitHeight + 16
    visible: toastTimer.running || toastCard.opacity > 0.001
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    function show(icon, title, message, level, progress, durationMs) {
        if (!bar.toastEnabled) return;

        toastIcon = icon && icon.length > 0 ? icon : "󰋽";
        toastTitle = title || "";
        toastMessage = message || "";
        toastLevel = level || "info";
        toastProgress = progress === undefined ? -1 : progress;
        toastTimer.interval = durationMs && durationMs > 0 ? durationMs : numbers.toastDurationMs;
        toastCard.opacity = 1;
        toastCard.y = numbers.toastTopMargin;
        toastCard.scale = 1;
        toastTimer.restart();
    }

    function levelColor() {
        if (toastLevel === "success") return bar.networkTextColor;
        if (toastLevel === "warning") return bar.memoryTextColor;
        if (toastLevel === "error") return bar.cpuTextColor;
        return bar.audioTextColor;
    }

    Connections {
        target: bar
        function onToastRequested(icon, title, message, level, progress, durationMs) {
            toastWindow.show(icon, title, message, level, progress, durationMs);
        }
    }

    Timer {
        id: toastTimer
        interval: numbers.toastDurationMs
        repeat: false
        onTriggered: {
            toastCard.opacity = 0;
            toastCard.y = numbers.toastTopMargin - 14;
            toastCard.scale = 0.96;
        }
    }

    Rectangle {
        id: toastCard

        width: Math.min(numbers.toastWidth, toastWindow.width - 32)
        implicitHeight: toastColumn.implicitHeight + 24
        x: (toastWindow.width - width) / 2
        y: numbers.toastTopMargin - 26
        opacity: 0
        scale: 0.88
        transformOrigin: Item.Top
        radius: numbers.toastRadius
        color: bar.popupColor
        border.color: bar.popupBorderColor
        border.width: 1

        Behavior on y { SpringAnimation { spring: 5.4; damping: 0.24; epsilon: 0.12 } }
        Behavior on opacity { NumberAnimation { duration: numbers.toastAnimationMs; easing.type: Easing.OutCubic } }
        Behavior on scale { SpringAnimation { spring: 5.8; damping: 0.25; epsilon: 0.001 } }

        Column {
            id: toastColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 9

            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    Layout.alignment: Qt.AlignVCenter
                    radius: 17
                    color: bar.activePillColor

                    Text {
                        anchors.centerIn: parent
                        text: toastIcon
                        color: toastWindow.levelColor()
                        font.family: bar.iconFont
                        font.pixelSize: 16
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: toastTitle
                        color: bar.textColor
                        font.family: bar.barFont
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: toastMessage.length > 0
                        text: toastMessage
                        color: bar.mutedTextColor
                        font.family: bar.barFont
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: numbers.toastProgressHeight
                radius: height / 2
                color: bar.sectionPillColor
                visible: toastProgress >= 0

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, toastProgress))
                    height: parent.height
                    radius: parent.radius
                    color: toastWindow.levelColor()

                    Behavior on width {
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
