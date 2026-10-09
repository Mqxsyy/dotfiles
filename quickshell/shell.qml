import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        RecordingCard {}
    }

    Launcher {}
    Toasts {}
    Osd {}

    // Panels; Popups.qml opens one at a time.
    WifiPanel {}
    AudioPanel {}
    MediaPanel {}
    PowerMenu {}
    SystemPanel {}
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
