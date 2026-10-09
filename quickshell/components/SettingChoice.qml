import QtQuick
import qs.config

// A labeled set of options for the settings page; the current one is filled.
// options: [{ value, text }, ...]
Column {
    id: root

    property string label: ""
    property var options: []
    property string value: ""

    signal picked(string value)

    spacing: 8

    Text {
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSmall
    }

    Flow {
        width: parent.width
        spacing: 6

        Repeater {
            model: root.options

            Rectangle {
                id: option

                required property var modelData
                readonly property bool selected: modelData.value === root.value

                width: optionText.implicitWidth + 20
                height: 28
                radius: Theme.innerRadius
                color: selected ? Theme.accent : hover.hovered ? Qt.alpha(Theme.textPrimary, 0.14) : Theme.highlight

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.picked(option.modelData.value)
                }

                Text {
                    id: optionText
                    anchors.centerIn: parent
                    text: option.modelData.text
                    color: option.selected ? Theme.accentText : Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
