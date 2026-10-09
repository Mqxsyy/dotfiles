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

    readonly property int radius: values.radius
    readonly property real surfaceOpacity: values.surfaceOpacity
    readonly property string wallpaperTransition: values.wallpaperTransition
    readonly property bool nightLight: values.nightLight
    readonly property int nightLightTemperature: values.nightLightTemperature
    readonly property bool nightLightAuto: values.nightLightAuto
    readonly property int nightLightFrom: values.nightLightFrom
    readonly property int nightLightTo: values.nightLightTo
    readonly property int lockAfter: values.lockAfter
    readonly property bool screenshotFreeze: values.screenshotFreeze
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
            property string wallpaperTransition: "grow" // "grow" or "swipe" (WallpaperView.qml)
            property bool nightLight: false             // NightLight.qml
            property int nightLightTemperature: 4000    // kelvin, lower is warmer
            property bool nightLightAuto: false         // on from nightLightFrom to nightLightTo
            property int nightLightFrom: 20             // hour
            property int nightLightTo: 7                // hour
            property int lockAfter: 10                  // idle minutes before locking (Lock.qml), 0 = never
            property bool screenshotFreeze: false       // freeze the screen while picking a region (Recorder.qml)
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
            Popups.toggle("settings");
        }
    }
}
