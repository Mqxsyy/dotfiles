import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/icons.js" as Icons

// CPU, memory, GPU and disk tiles, network speed, battery, and the busiest
// processes (System.qml). Click a process twice to end it (the first click
// only arms it). The dashboard's System tab.
Column {
    id: root

    // Measure only while this is on screen.
    property bool active: true
    property int confirmFor: 3000

    // pid of the process waiting for its confirming click, or -1.
    property int armed: -1

    function percent(fraction) {
        return fraction < 0 ? "–" : Math.round(fraction * 100) + "%";
    }

    function pick(pid) {
        if (armed !== pid) {
            armed = pid;
            disarm.restart();
            return;
        }
        armed = -1;
        System.kill(pid);
    }

    spacing: 12

    // Whether this view is counted in System.viewers; kept in step with `active`.
    property bool counted: false

    function count() {
        if (counted === active)
            return;
        counted = active;
        System.viewers += active ? 1 : -1;
    }

    onActiveChanged: {
        armed = -1;
        count();
    }
    Component.onCompleted: count()
    Component.onDestruction: if (counted) System.viewers--

    Timer {
        id: disarm
        interval: root.confirmFor
        onTriggered: root.armed = -1
    }

    Grid {
        width: parent.width
        columns: 2
        spacing: 8

        StatTile {
            width: (parent.width - parent.spacing) / 2
            glyph: Icons.cpu
            title: "CPU"
            value: root.percent(System.cpu)
            detail: System.cpuTemp >= 0 ? `${Math.round(System.cpuTemp)}°C` : ""
            level: System.cpu
            history: System.cpuHistory
        }

        StatTile {
            width: (parent.width - parent.spacing) / 2
            glyph: Icons.memory
            title: "Memory"
            value: System.memoryTotal ? root.percent(System.memoryUsed / System.memoryTotal) : "–"
            detail: `${System.formatBytes(System.memoryUsed)} of ${System.formatBytes(System.memoryTotal)}`
            level: System.memoryTotal ? System.memoryUsed / System.memoryTotal : 0
            history: System.memoryHistory
        }

        StatTile {
            width: (parent.width - parent.spacing) / 2
            glyph: Icons.gpu
            title: "GPU"
            value: root.percent(System.gpu)
            detail: {
                const parts = [];
                if (System.gpuTemp >= 0)
                    parts.push(`${Math.round(System.gpuTemp)}°C`);
                if (System.gpuPower >= 0)
                    parts.push(`${System.gpuPower.toFixed(1)} W`);
                if (System.gpuMemoryTotal)
                    parts.push(`${System.formatBytes(System.gpuMemoryUsed)} VRAM`);
                return parts.join(" · ");
            }
            level: Math.max(0, System.gpu)
        }

        StatTile {
            width: (parent.width - parent.spacing) / 2
            glyph: Icons.disk
            title: "Disk"
            value: System.diskTotal ? root.percent(System.diskUsed / System.diskTotal) : "–"
            detail: `${System.formatBytes(System.diskUsed)} of ${System.formatBytes(System.diskTotal)}`
            level: System.diskTotal ? System.diskUsed / System.diskTotal : 0
        }
    }

    // Network speed and battery.
    Row {
        width: parent.width
        spacing: 16

        Text {
            text: `${Icons.download} ${System.formatBytes(System.download)}/s   ${Icons.upload} ${System.formatBytes(System.upload)}/s`
            color: Theme.textSecondary
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSmall - 1
        }

        Text {
            visible: Battery.available
            text: {
                const parts = [Math.round(Battery.percentage * 100) + "%"];
                if (Battery.rate > 0)
                    parts.push(`${Battery.rate.toFixed(1)} W`);
                if (Battery.timeLeft)
                    parts.push(Battery.pluggedIn ? `${Battery.timeLeft} to full` : `${Battery.timeLeft} left`);
                return `${Battery.pluggedIn ? Icons.batteryCharging : Icons.level(Icons.battery, Battery.percentage)} ${parts.join(" · ")}`;
            }
            color: Theme.textSecondary
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSmall - 1
        }
    }

    SectionTitle {
        topPadding: 4
        text: "Processes"
    }

    Column {
        width: parent.width

        Repeater {
            model: System.processes

            Rectangle {
                id: process

                required property var modelData
                readonly property bool armed: root.armed === modelData.pid

                width: parent.width
                height: 32
                radius: Theme.innerRadius
                color: armed ? Theme.error : hover.hovered ? Theme.highlight : "transparent"

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.pick(process.modelData.pid)
                }

                Text {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - usage.width - 20
                    text: process.armed ? `Click to end ${process.modelData.name}` : process.modelData.name
                    color: process.armed ? Theme.errorText : Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                    font.weight: process.armed ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                Row {
                    id: usage
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !process.armed
                    spacing: 4

                    Text {
                        width: 52
                        horizontalAlignment: Text.AlignRight
                        text: `${(process.modelData.cpu * 100).toFixed(1)}%`
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSmall - 1
                    }

                    Text {
                        width: 64
                        horizontalAlignment: Text.AlignRight
                        text: System.formatBytes(process.modelData.memory * System.memoryTotal)
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSmall - 1
                    }
                }
            }
        }
    }

    // A stat with its level as a bar, or as a graph when it has history.
    component StatTile: Rectangle {
        id: tile

        property string glyph: ""
        property string title: ""
        property string value: ""
        property string detail: ""
        property real level: 0       // 0..1
        property var history: null   // [0..1], oldest first

        height: 92
        radius: Theme.innerRadius
        color: Theme.highlight

        Column {
            x: 12
            y: 10
            width: parent.width - 24
            spacing: 2

            Item {
                width: parent.width
                height: valueText.implicitHeight

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tile.glyph
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.fontSmall
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tile.title
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSmall - 1
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    id: valueText
                    anchors.right: parent.right
                    text: tile.value
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.DemiBold
                }
            }

            Text {
                width: parent.width
                text: tile.detail || " "
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall - 2
                elide: Text.ElideRight
            }
        }

        // Graph: one bar per sample, newest on the right.
        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 12
            height: 28
            spacing: 1
            visible: tile.history !== null
            layoutDirection: Qt.RightToLeft

            Repeater {
                model: (tile.history ?? []).slice().reverse()

                Rectangle {
                    required property real modelData
                    anchors.bottom: parent.bottom
                    width: (tile.width - 24) / System.historyLength - 1
                    height: Math.max(1, 28 * modelData)
                    radius: 1
                    color: Qt.alpha(Theme.accent, 0.8)
                }
            }
        }

        // Bar, for stats without history.
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            x: 12
            width: parent.width - 24
            height: 6
            radius: 3
            visible: tile.history === null
            color: Theme.highlight

            Rectangle {
                width: parent.width * Math.min(1, tile.level)
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }
    }
}
