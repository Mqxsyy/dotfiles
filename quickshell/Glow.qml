import QtQuick
import QtQuick.Effects

// Soft accent light behind an active element (a lit toggle, today, play).
// Put it inside the element; it fades with `on`.
RectangularShadow {
    property bool on: true

    z: -1
    anchors.fill: parent
    radius: parent.radius
    blur: 14
    color: Theme.glow
    opacity: on ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
}
