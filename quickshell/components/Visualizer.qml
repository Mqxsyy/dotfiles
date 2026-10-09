import Quickshell.Services.Pipewire
import QtQuick
import qs.config
import qs.services

// What's playing right now, as bars: the default output's sound level
// sampled every `interval` ms, newest on the right, scrolling left. Bars go
// from the accent to the second accent. Only measures while `active`.
// Music sits in a narrow loudness range (peaks of 0.3-0.5), so bars are
// scaled between the quietest and loudest of what's on screen.
Item {
    id: root

    property bool active: true
    property int bars: 56
    property int interval: 40
    property var levels: new Array(bars).fill(0)
    readonly property real low: Math.min(...levels)
    readonly property real high: Math.max(...levels)

    // 0.1..1 for a level, relative to what's on screen.
    function scaled(level) {
        return 0.1 + 0.9 * (level - low) / Math.max(0.05, high - low);
    }

    implicitHeight: 40

    PwNodePeakMonitor {
        id: monitor
        node: Audio.sink
        enabled: root.active
    }

    Timer {
        running: root.active
        interval: root.interval
        repeat: true
        onTriggered: root.levels = [...root.levels.slice(1), monitor.peak]
    }

    Row {
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.bars

            Rectangle {
                required property int index

                anchors.verticalCenter: parent.verticalCenter
                width: (root.width - (root.bars - 1) * 2) / root.bars
                height: Math.max(3, root.height * root.scaled(root.levels[index] ?? 0))
                radius: width / 2
                color: Qt.tint(Theme.accent, Qt.alpha(Theme.accent2, index / root.bars * 0.8))
                opacity: 0.35 + 0.65 * index / root.bars
            }
        }
    }
}
