import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Launcher {}
    Toasts {}
    Osd {}
    SettingsPage {}
}
