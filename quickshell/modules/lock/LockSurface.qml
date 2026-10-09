import Quickshell.Wayland
import QtQuick
import qs.services

// The locked session on one screen (LockScreen.qml): LockView, checking
// the password with Lock.qml. Usually LockCover.qml has already faded the
// same picture in over the desktop, so it's fully shown at once. Locked
// from the start (boot), it fades in from black once the new wallpaper and
// its colors are ready.
WlSessionLockSurface {
    id: root

    color: "black"

    LockView {
        id: view

        anchors.fill: parent
        auth: Lock
        focus: true
        reveal: Lock.fromBlack && (Lock.preparing || !ready) ? 0 : 1

        Behavior on reveal {
            NumberAnimation {
                duration: Lock.fadeDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
