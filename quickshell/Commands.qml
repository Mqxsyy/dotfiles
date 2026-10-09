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
            description: "New random wallpaper and colors",
            run: () => Wallpaper.randomize(),
        },
        {
            name: "settings",
            description: "Roundness, opacity and color settings",
            run: () => Settings.pageOpen = true,
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
            description: "Turn wifi on or off",
            run: () => Network.toggleWifi(),
        },
    ]
}
