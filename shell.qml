import Quickshell
import QtQuick

ShellRoot {
    id: shellRoot

    Bar {
        id: barWindow
    }

    QuickSettingsEdge {
        targetBar: barWindow
    }
}
