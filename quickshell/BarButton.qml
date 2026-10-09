import QtQuick

// Icon and/or label used for everything in the bar. When interactive it
// highlights on hover and reacts to clicks and scrolling.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: Theme.textPrimary
    property color labelColor: Theme.textPrimary
    property bool interactive: true
    property int maxLabelWidth: 0 // 0 = no limit; longer labels are elided
    property string hint: ""      // shown under the bar while hovered
    readonly property bool hovered: hover.hovered

    signal clicked()
    signal scrolled(real steps)   // +1 per wheel notch up, fractions on touchpads

    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.controlSize
    radius: Theme.innerRadius
    color: interactive && hover.hovered ? Theme.highlight : "transparent"

    HoverHandler {
        id: hover
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.interactive
        onTapped: root.clicked()
    }

    WheelHandler {
        enabled: root.interactive
        onWheel: event => root.scrolled(event.angleDelta.y / 120)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            color: root.iconColor
            font.family: Theme.iconFont
            font.pixelSize: 16
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: root.maxLabelWidth > 0 ? Math.min(implicitWidth, root.maxLabelWidth) : implicitWidth
            visible: root.label !== ""
            elide: Text.ElideRight
            text: root.label
            color: root.labelColor
            font.pixelSize: Theme.fontSmall
        }
    }
}
