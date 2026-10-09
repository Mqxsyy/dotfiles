import QtQuick
import QtQuick.Effects
import qs.config

// Two big soft glow circles, accent top-right and second accent
// bottom-left, behind a card's content. Card.qml shows it when `glows` is on.
Item {
    id: root

    readonly property real size: Math.max(width, height) * 0.45

    RectangularShadow {
        x: root.width * 0.7 - root.size / 2
        y: -root.size * 0.25
        width: root.size
        height: root.size
        radius: root.size / 2
        blur: 90
        color: Qt.alpha(Theme.accent, 0.09)
    }

    RectangularShadow {
        x: root.width * 0.15 - root.size / 2
        y: root.height - root.size * 0.6
        width: root.size
        height: root.size
        radius: root.size / 2
        blur: 100
        color: Qt.alpha(Theme.accent2, 0.07)
    }
}
