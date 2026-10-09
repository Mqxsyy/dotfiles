import QtQuick
import qs.config

// A clickable row in a panel list: glyph, title and subtitle, trailing text.
// `selected` marks the current choice (the active device, the connected
// network). Extra content (buttons, a password field) can go in `below`.
Rectangle {
    id: root

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""   // glyph on the right, e.g. a lock
    property bool selected: false
    property bool interactive: true
    default property alias below: extra.data

    signal clicked()

    implicitHeight: column.implicitHeight
    radius: Theme.innerRadius
    color: interactive && hover.hovered ? Theme.tile : "transparent"

    HoverHandler {
        id: hover
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Column {
        id: column
        width: parent.width

        Item {
            width: parent.width
            height: 44

            // Only the row itself is clickable, not the content below it.
            TapHandler {
                enabled: root.interactive
                onTapped: root.clicked()
            }

            // Glyph in a round badge, filled when selected.
            Rectangle {
                id: glyphText
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: width / 2
                color: Theme.tile
                gradient: root.selected ? Theme.accentGradient : null

                Glow {
                    on: root.selected
                    blur: 12
                }

                Text {
                    anchors.centerIn: parent
                    text: root.glyph
                    color: root.selected ? Theme.accentText : Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 15
                }
            }

            Column {
                anchors.left: glyphText.right
                anchors.leftMargin: 10
                anchors.right: trailingText.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: root.title
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                    font.weight: root.selected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.subtitle
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSmall - 2
                    elide: Text.ElideRight
                }
            }

            Text {
                id: trailingText
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.trailing
                color: Theme.textSecondary
                font.family: Theme.iconFont
                font.pixelSize: 14
            }
        }

        Column {
            id: extra
            width: parent.width
        }
    }
}
