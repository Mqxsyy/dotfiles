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

    Slider {
        anchors.bottom: parent.bottom
        width: parent.width
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onMoved: value => root.moved(value)
    }
}
