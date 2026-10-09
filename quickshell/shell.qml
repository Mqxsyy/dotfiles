import Quickshell
import QtQuick
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

    // Panels; Popups.qml opens one at a time.
    PowerMenu {}
    ClipboardPanel {}
    CapturePanel {
        name: "screenshot"
    }
    CapturePanel {
        name: "record"
    }
    WallpaperPicker {}
    SettingsPage {}
    PolkitPrompt {}
    WindowOverview {}
}
