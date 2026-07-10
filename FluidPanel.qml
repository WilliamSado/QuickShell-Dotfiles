import QtQuick
import QtQuick.Layouts
import "config" as Config

Rectangle {
    id: root

    property bool open: false
    property real hiddenX: 0
    property real hiddenY: 18
    property real shownX: 0
    property real shownY: 0
    property real hiddenScale: 0.94
    property real shownScale: 1.0
    property int animationMs: md3.motionMedium
    default property alias content: contentItem.data
    property alias contentItem: contentItem
    property color panelColor: Qt.rgba(md3.surfaceContainer.r, md3.surfaceContainer.g, md3.surfaceContainer.b, md3.surfacePanelOpacity)
    property color outlineColor: "#26ffffff"
    property color textColor: md3.textOnSurface

    Config.Md3 { id: md3 }

    x: open ? shownX : hiddenX
    y: open ? shownY : hiddenY
    opacity: open ? 1 : 0
    scale: open ? shownScale : hiddenScale
    radius: md3.radiusExtraLarge
    color: panelColor
    border.color: outlineColor
    border.width: 1
    transformOrigin: Item.TopRight
    antialiasing: true
    clip: true

    Behavior on x { SpringAnimation { spring: md3.motionSpring; damping: md3.motionDamping; epsilon: 0.2 } }
    Behavior on y { SpringAnimation { spring: md3.motionSpring; damping: md3.motionDamping; epsilon: 0.2 } }
    Behavior on scale { SpringAnimation { spring: md3.motionSpring + 0.2; damping: md3.motionDamping; epsilon: 0.001 } }
    Behavior on opacity { NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic } }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
