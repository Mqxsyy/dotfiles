import QtQuick

// The surface every component draws on: themed background, border and shadow.
// Leave Theme.shadowPad of window space around it so the shadow isn't cut off.
Rectangle {
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    layer.enabled: true
    layer.effect: Shadow {}
}
