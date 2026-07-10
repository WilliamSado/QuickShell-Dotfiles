import QtQuick

QtObject {
    readonly property color primary: "#8fd8ff"
    readonly property color textOnPrimary: "#003548"
    readonly property color primaryContainer: "#164d63"
    readonly property color textOnPrimaryContainer: "#c4eaff"

    readonly property color secondary: "#b7c9d5"
    readonly property color textOnSecondary: "#22323b"
    readonly property color secondaryContainer: "#384951"
    readonly property color textOnSecondaryContainer: "#d3e5f0"

    readonly property color error: "#ffb4ab"
    readonly property color textOnError: "#690005"
    readonly property color errorContainer: "#93000a"
    readonly property color textOnErrorContainer: "#ffdad6"

    readonly property color surface: "#101416"
    readonly property color surfaceDim: "#0b0f11"
    readonly property color surfaceBright: "#343a3d"
    readonly property color surfaceContainerLowest: "#070b0d"
    readonly property color surfaceContainerLow: "#151a1c"
    readonly property color surfaceContainer: "#1a1f22"
    readonly property color surfaceContainerHigh: "#252b2e"
    readonly property color surfaceContainerHighest: "#303639"
    readonly property color textOnSurface: "#e1e3e5"
    readonly property color textOnSurfaceVariant: "#c0c8cd"
    readonly property color outline: "#8a9297"
    readonly property color outlineVariant: "#40484d"
    readonly property color scrim: "#000000"

    readonly property real surfacePanelOpacity: 0.82
    readonly property real surfacePillOpacity: 0.42
    readonly property real stateHoverOpacity: 0.08
    readonly property real stateFocusOpacity: 0.12
    readonly property real statePressedOpacity: 0.14
    readonly property real disabledOpacity: 0.38

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 18
    readonly property int radiusExtraLarge: 24
    readonly property int radiusFull: 999

    readonly property int elevationLevel0: 0
    readonly property int elevationLevel1: 1
    readonly property int elevationLevel2: 3
    readonly property int elevationLevel3: 6
    readonly property int elevationLevel4: 8
    readonly property int elevationLevel5: 12

    readonly property int motionShort: 140
    readonly property int motionMedium: 220
    readonly property int motionLong: 320
    readonly property real motionSpring: 3.2
    readonly property real motionDamping: 0.36
}
