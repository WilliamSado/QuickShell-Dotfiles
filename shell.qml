//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: shellRoot

    Bar {
        id: barWindow
    }

    IpcHandler {
        target: "control"

        function openLauncher() {
            barWindow.openControlCenter("launcher");
        }

        function openCapture() {
            barWindow.openControlCenter("capture");
        }

        function openClipboard() {
            barWindow.openControlCenter("clipboard");
        }

        function openWindows() {
            barWindow.openControlCenter("windows");
        }

        function openFocus() {
            barWindow.openControlCenter("focus");
        }
    }

    BrightnessOverlay {
        brightnessPercent: barWindow.quickBrightnessPercent
    }

    StatusToast {
        bar: barWindow
    }

    QuickSettingsEdge {
        targetBar: barWindow
    }
}
