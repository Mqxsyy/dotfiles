pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// The screen of the focused Hyprland monitor; popups open there.
Singleton {
    readonly property ShellScreen screen: Array.from(Quickshell.screens).find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
}
