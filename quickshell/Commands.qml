pragma Singleton

import Quickshell
import QtQuick

// Commands the launcher runs when the query starts with ">", e.g. "> wallpaper".
// To add one, add an entry: name is what you type, run is what happens.
// With just ">" typed they're listed in this order.
Singleton {
    readonly property var list: [
        {
            name: "wallpaper",
            description: "Pick a wallpaper",
            run: () => Popups.open("wallpapers"),
        },
        {
            name: "shuffle",
            description: "Random wallpaper and new colors",
            run: () => Wallpaper.randomize(),
        },
        {
            name: "settings",
            description: "Roundness, opacity and color settings",
            run: () => Popups.open("settings"),
        },
        {
            name: "audio",
            description: "Volume per device and app",
            run: () => Popups.open("audio"),
        },
        {
            name: "media",
            description: "Now playing and favorites",
            run: () => Popups.open("media"),
        },
        {
            name: "system",
            description: "CPU, memory, GPU, disk and processes",
            run: () => Popups.open("system"),
        },
        {
            name: "clipboard",
            description: "Clipboard history",
            run: () => Popups.open("clipboard"),
        },
        {
            name: "screenshot",
            description: "Screenshot a region or the screen",
            run: () => Popups.open("screenshot"),
        },
        {
            name: "record",
            description: "Record a region or the screen",
            run: () => Popups.open("record"),
        },
        {
            name: "color",
            description: "Pick a color from the screen",
            run: () => Recorder.pickColor(),
        },
        {
            name: "reload",
            description: "Reload the quickshell config",
            run: () => Quickshell.reload(false),
        },
        {
            name: "dnd",
            description: "Toggle do not disturb",
            run: () => Notifications.dnd = !Notifications.dnd,
        },
        {
            name: "clear",
            description: "Dismiss all notifications",
            run: () => Notifications.clear(),
        },
        {
            name: "wifi",
            description: "Wifi networks",
            run: () => Popups.open("wifi"),
        },
    ]
}
