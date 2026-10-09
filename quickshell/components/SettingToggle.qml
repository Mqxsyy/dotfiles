import QtQuick
import qs.config

// A labeled on/off switch for the settings page.
Item {
    id: root

    property string label: ""
    property string description: ""
    property bool checked: false

    signal toggled(bool checked)

    implicitHeight: Math.max(text.implicitHeight, track.height)

    Column {
        id: text
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - track.width - 12
        spacing: 2

        Text {
            text: root.label
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSmall
        }

        Text {
            width: parent.width
            visible: root.description !== ""
            text: root.description
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall - 1
            wrapMode: Text.Wrap
        }
    }

    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 22
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.highlight

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: root.checked ? Theme.accentText : Theme.textSecondary

            Behavior on x {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.toggled(!root.checked)
        }
    }
}
