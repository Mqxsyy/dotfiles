import Quickshell
import Quickshell.Wayland
import QtQuick

// Base for every quickshell window: transparent, drawn over other windows,
// and blurred behind when glass is on in the settings. The blur itself is
// done by Hyprland: the layer rule in hyprland.lua blurs layers whose
// namespace starts with "qs-blur-".
PanelWindow {
    id: root

    required property string name // layer namespace without prefix, e.g. "bar"
    property bool shown: true

    // Hyprland only reads a layer's namespace when it appears, so toggling
    // glass hides and shows the window for a moment.
    property bool remapping: false

    visible: shown && !remapping
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: (Settings.glass ? "qs-blur-" : "qs-") + name

    Connections {
        target: Settings

        function onGlassChanged() {
            root.remapping = true;
            Qt.callLater(() => root.remapping = false);
        }
    }
}
