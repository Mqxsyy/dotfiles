import QtQuick

// A labeled slider for the settings page: label and value on top, track below.
Item {
    id: root

    property string label: ""
    property string valueText: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0.1
    property real value: 0

    // The user dragged to a new value (already snapped to stepSize).
    signal moved(real value)

    readonly property real ratio: (value - from) / (to - from)

    implicitHeight: 46

    Text {
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSmall
    }

    Text {
        anchors.right: parent.right
        text: root.valueText
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }

    Item {
        id: track
        anchors.bottom: parent.bottom
        width: parent.width
        height: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.highlight

            Rectangle {
                width: parent.width * root.ratio
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        Rectangle {
            x: (parent.width - width) * root.ratio
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: Theme.accent
            border.color: Theme.surface
            border.width: 2
        }

        MouseArea {
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
    }
}
