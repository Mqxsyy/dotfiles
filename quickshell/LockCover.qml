import Quickshell
import Quickshell.Wayland
import QtQuick

// The lock screen fading in over the desktop before the session locks, and
// out after it unlocks (Lock.qml times both), one per screen. Hyprland swaps
// to and from a locked session at once; this makes it a fade.
PanelWindow {
    id: root

    required property ShellScreen modelData
    property real reveal: Lock.shown ? 1 : 0

    screen: modelData
    visible: reveal > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-lock-cover"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Behavior on reveal {
        NumberAnimation {
            duration: Lock.fadeDuration
            easing.type: Easing.OutCubic
        }
    }

    LockView {
        anchors.fill: parent
        reveal: root.reveal
        auth: Lock
    }
}
