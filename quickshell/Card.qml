import QtQuick
import QtQuick.Effects

// The surface every component draws on: a soft accent-lit gradient, a
// border and a shadow. With `glows` on, big soft glow circles sit behind
// the content (Backdrop.qml). Leave Theme.shadowPad of window space around
// it so the shadow isn't cut off.
//
// The shadow is drawn separately behind the card (not as a layer effect on
// it), so the card's text stays sharp.
Rectangle {
    id: root

    property bool glows: false

    radius: Theme.radius
    border.color: Theme.border
    border.width: 1
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.surfaceTop }
        GradientStop { position: 0.5; color: Theme.surface }
        GradientStop { position: 1; color: Theme.surfaceBottom }
    }

    RectangularShadow {
        z: -1
        anchors.fill: parent
        radius: root.radius
        offset.y: 6
        blur: 24
        color: Theme.shadow
    }

    // A plain clip (cheap); the glows are faint enough at the corners.
    Item {
        anchors.fill: parent
        clip: true
        opacity: root.glows ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.expandDuration }
        }

        Backdrop {
            anchors.fill: parent
        }
    }
}
