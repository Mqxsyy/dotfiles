import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Spectrum of what's playing, like a terminal visualizer: bass on the left,
// treble on the right, each bar rising from the bottom with its band's
// loudness. Bars go from the accent to the second accent. The numbers come
// from cava (config/cava.conf sets the bar count and smoothing), which only
// runs while `active`.
Item {
    id: root

    property bool active: true
    property int spacing: 2
    // 0..1 per bar, from cava's latest frame.
    property var levels: []

    implicitHeight: 24

    // Paused: the bars rest flat.
    onActiveChanged: if (!active) levels = levels.map(() => 0)

    Process {
        running: root.active
        command: ["cava", "-p", Quickshell.shellDir + "/config/cava.conf"]

        // One frame per line: "12;40;33;..." (0-100, with a trailing ";").
        stdout: SplitParser {
            onRead: line => root.levels = line.split(";").filter(value => value !== "").map(value => value / 100)
        }
    }

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
