import Quickshell
import QtQuick

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
}
