import QtQuick
import qs.config
import qs.services

// Spectrum of what's playing, like a terminal visualizer: bass on the left,
// treble on the right, each bar rising from the bottom with its band's
// loudness (Spectrum.qml). Bars go from the accent to the second accent.
// Only follows the sound while `active`; otherwise the bars rest flat.
Item {
    id: root

    property bool active: true
    property int spacing: 2
    // Off screen it doesn't follow every frame.
    readonly property var levels: active ? Spectrum.levels : new Array(Spectrum.bands).fill(0)

    implicitHeight: 24

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.spacing

        Repeater {
            model: root.levels.length

            Rectangle {
                required property int index

                anchors.bottom: parent.bottom
                width: (root.width - (root.levels.length - 1) * root.spacing) / root.levels.length
                height: Math.max(2, root.height * root.levels[index])
                radius: Math.min(2, width / 2)
                color: Qt.tint(Theme.accent, Qt.alpha(Theme.accent2, index / root.levels.length * 0.8))
            }
        }
    }
}
