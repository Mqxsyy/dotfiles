pragma Singleton

import Quickshell
import QtQuick
import qs.services

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
            run: () => BarLayout.open("audio"),
        },
        {
            name: "media",
            description: "Now playing",
            run: () => BarLayout.open("media"),
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
            name: "lock",
            description: "Lock the screen",
            run: () => Lock.lock(),
        },
        // Power actions open the power menu, waiting for a confirm.
        {
            name: "logout",
            description: "Log out (asks to confirm)",
            run: () => Popups.open("power", null, "logout"),
        },
        {
            name: "suspend",
            description: "Suspend (asks to confirm)",
            run: () => Popups.open("power", null, "suspend"),
        },
        {
            name: "restart",
            description: "Restart (asks to confirm)",
            run: () => Popups.open("power", null, "restart"),
        },
        {
            name: "shutdown",
            description: "Shut down (asks to confirm)",
            run: () => Popups.open("power", null, "shutdown"),
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
            name: "notifications",
            description: "Notification history",
            run: () => BarLayout.open("notifications"),
        },
        {
            name: "clear",
            description: "Clear all notifications",
            run: () => Notifications.clearHistory(),
        },
        {
            name: "night",
            description: "Toggle night light",
            run: () => NightLight.toggle(),
        },
        {
            name: "bluetooth",
            description: "Bluetooth devices",
            run: () => BarLayout.open("bluetooth"),
        },
        {
            name: "windows",
            description: "All open windows",
            run: () => Popups.open("windows"),
        },
        {
            name: "wifi",
            description: "Wifi networks",
            run: () => BarLayout.open("wifi"),
        },
    ]
}
