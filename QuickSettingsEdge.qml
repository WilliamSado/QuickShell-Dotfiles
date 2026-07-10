import Quickshell
import QtQuick

PanelWindow {
    id: edgeWindow

    required property var targetBar

    anchors.top: true
    anchors.bottom: true
    anchors.right: true
    margins.top: targetBar.implicitHeight
    implicitWidth: Math.min(targetBar.quickSettingsEdgeWidth, 24)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
        id: quickSettingsEdgeArea
        anchors.fill: parent
        hoverEnabled: true
        property real pressX: 0

        onPressed: function(mouse) {
            pressX = mouse.x;
        }

        onPositionChanged: function(mouse) {
            if (pressed && mouse.x < pressX - 18) targetBar.openQuickSettings();
        }

        onClicked: function(mouse) {
            if (mouse.x >= width - 8) targetBar.openQuickSettings();
        }
    }
}
