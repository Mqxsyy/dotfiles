pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// User settings, edited on the settings page ("> settings" in the launcher)
// and saved to ~/.local/state/quickshell/settings.json. The color settings
// are also read by scripts/generate-colors.sh.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"

    // Changing one of these regenerates the colors from the current wallpaper.
    readonly property var colorKeys: ["scheme", "mode", "contrast", "prefer"]

    property bool pageOpen: false

    readonly property int radius: values.radius
    readonly property real surfaceOpacity: values.surfaceOpacity
    readonly property bool glass: values.glass
    readonly property string scheme: values.scheme
    readonly property string mode: values.mode
    readonly property real contrast: values.contrast
    readonly property string prefer: values.prefer

    function set(key, value) {
        if (values[key] === value)
            return;
        values[key] = value;
        if (colorKeys.includes(key))
            recolor.restart();
    }

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // First run: save the defaults so the file exists for generate-colors.sh too.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: values

            property int radius: 18
            property real surfaceOpacity: 1
            property bool glass: false                  // blur what's behind see-through surfaces
            property string scheme: "scheme-tonal-spot" // matugen --type
            property string mode: "dark"                // matugen --mode
            property real contrast: 0                   // matugen --contrast, -1..1
            property string prefer: "saturation"        // matugen --prefer
        }
    }

    // Sliders change continuously; wait until they settle before regenerating.
    Timer {
        id: recolor
        interval: 500
        onTriggered: Wallpaper.recolor()
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            root.pageOpen = !root.pageOpen;
        }
    }
}
