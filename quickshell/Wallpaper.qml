pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper and the colors generated from it. The wallpaper on screen is
// the path in `stateFile`, written by scripts/set-wallpaper.sh and shown by
// Background.qml.
//   set(path):   show that wallpaper, then new colors (wallpaper picker)
//   randomize(): random wallpaper from `folder`, then new colors
//   recolor():   new colors from the current wallpaper (after color settings change)
//   load():      list the images in `folder` into `images`
Singleton {
    id: root

    readonly property string scripts: Quickshell.shellDir + "/scripts/"
    readonly property string directory: Quickshell.env("HOME") + "/dotfiles/wallpapers/"
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/quickshell/wallpaper"

    // Folders the picker can show, relative to `directory`.
    readonly property var folders: [
        { name: "Hand-picked", path: "wallpapers-hand-picked" },
        { name: "All", path: "wallpapers" },
    ]
    property string folder: folders[0].path

    // Image paths in `folder` (absolute, sorted); filled by load().
    property var images: []
    // The wallpaper on screen, absolute path.
    property string current: ""

    readonly property bool running: setter.running || randomizer.running || recolorer.running

    // A recolor asked for while one runs; it runs again after, with the newest settings.
    property bool recolorPending: false

    function set(path) {
        current = path;
        setter.exec([scripts + "set-wallpaper.sh", path]);
    }

    function randomize() {
        if (!randomizer.running)
            randomizer.exec([scripts + "randomize-wallpaper.sh", directory + folder]);
    }

    function recolor() {
        if (recolorer.running)
            recolorPending = true;
        else
            recolorer.running = true;
    }

    function load() {
        lister.exec(["find", directory + folder, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", ")"]);
    }

    onFolderChanged: load()

    Process {
        id: setter
    }

    Process {
        id: randomizer
        onExited: wallpaperFile.reload()
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

    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: root.images = text.split("\n").filter(line => line !== "").sort()
        }
    }

    // The wallpaper on screen, from the state file.
    FileView {
        id: wallpaperFile
        path: root.stateFile
        watchChanges: true
        onFileChanged: reload()
        // First run: no wallpaper picked yet.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.randomize();
        }
        // Empty while the script is writing it; the next change has the path.
        onLoaded: {
            const path = text().trim();
            if (path)
                root.current = path;
        }
    }
}
