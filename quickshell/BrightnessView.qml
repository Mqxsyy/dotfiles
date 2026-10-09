import QtQuick
import "icons.js" as Icons

// Screen brightness slider. Shown when the bar's status card expands on the
// brightness icon.
Column {
    spacing: 10

    SectionTitle {
        text: "Brightness"
    }

    Row {
        width: parent.width
        spacing: 10

        Text {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.level(Icons.brightness, Brightness.value)
            color: Theme.textPrimary
            font.family: Theme.iconFont
            font.pixelSize: 16
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - glyph.width - percent.width - parent.spacing * 2
            value: Brightness.value
            onMoved: value => Brightness.set(value)
        }

        Text {
            id: percent
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(Brightness.value * 100) + "%"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSmall
        }
    }
}
