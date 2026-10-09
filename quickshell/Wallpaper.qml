pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper and the colors generated from it.
//   randomize(): new random wallpaper, then new colors (launcher "> wallpaper")
//   recolor():   new colors from the current wallpaper (after color settings change)
Singleton {
    id: root

    readonly property string scripts: Quickshell.env("HOME") + "/dotfiles/scripts/"
    readonly property bool running: randomizer.running || recolorer.running

    // A recolor asked for while one runs; it runs again after, with the newest settings.
    property bool recolorPending: false

    function randomize() {
        if (!randomizer.running)
            randomizer.running = true;
    }

    function recolor() {
        if (recolorer.running)
            recolorPending = true;
        else
            recolorer.running = true;
    }

    Process {
        id: randomizer
        command: [root.scripts + "randomize-wallpaper.sh"]
    }

    Process {
        id: recolorer
        command: [root.scripts + "generate-colors.sh"]
        onExited: {
            if (root.recolorPending) {
                root.recolorPending = false;
                running = true;
            }
        }
    }
}
