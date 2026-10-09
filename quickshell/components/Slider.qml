import QtQuick
import qs.config

// A plain horizontal slider: track, fill and knob. Click or drag to set.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property real value: 0
    property color fill: Theme.accent

    // The user dragged to a new value (already snapped to stepSize).
    signal moved(real value)

    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property bool pressed: mouse.pressed

    implicitWidth: 200
    implicitHeight: 20

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.tile

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.tint(root.fill, Qt.alpha(Theme.accent2, 0.6)) }
                GradientStop { position: 1; color: root.fill }
            }
        }
    }

    Rectangle {
        x: (parent.width - width) * root.ratio
        anchors.verticalCenter: parent.verticalCenter
        width: mouse.pressed || hover.hovered ? 16 : 12
        height: width
        radius: width / 2
        color: Theme.textPrimary
        border.color: root.fill
        border.width: 3

        Behavior on width {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function pick(x) {
            const ratio = Math.max(0, Math.min(1, x / width));
            const raw = root.from + ratio * (root.to - root.from);
            const snapped = Math.round(raw / root.stepSize) * root.stepSize;
            // Round away float noise from the step math (0.30000000000000004).
            root.moved(Number(snapped.toFixed(4)));
        }

        onPressed: mouse => pick(mouse.x)
        onPositionChanged: mouse => pick(mouse.x)
    }

    WheelHandler {
        onWheel: event => {
            const steps = event.angleDelta.y / 120;
            const next = Math.max(root.from, Math.min(root.to, root.value + steps * root.stepSize * 5));
            root.moved(Number(next.toFixed(4)));
        }
    }
}
