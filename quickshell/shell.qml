import Quickshell
import QtQuick
import qs.components
import qs.modules.background
import qs.modules.bar
import qs.modules.launcher
import qs.modules.lock
import qs.modules.overlays
import qs.modules.popups

ShellRoot {
    Variants {
        model: Quickshell.screens

        Background {}
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        RecordingCard {}
    }

    Variants {
        model: Quickshell.screens

        LockCover {}
    }

    LockScreen {}
    Launcher {}
    Toasts {}
    Osd {}

    // Panels; Popups.qml opens one at a time. Each is made only while open.
    LazyPopup {
        name: "power"
        PowerMenu {}
    }
    LazyPopup {
        name: "clipboard"
        ClipboardPanel {}
    }
    LazyPopup {
        name: "screenshot"
        CapturePanel {
            name: "screenshot"
        }
    }
    LazyPopup {
        name: "record"
        CapturePanel {
            name: "record"
        }
    }
    LazyPopup {
        name: "wallpapers"
        WallpaperPicker {}
    }
    LazyPopup {
        name: "settings"
        SettingsPage {}
    }
    LazyPopup {
        name: "windows"
        WindowOverview {}
    }
    // Always there: it is the session's polkit agent, waiting for requests.
    PolkitPrompt {}
}
