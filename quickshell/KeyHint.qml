import QtQuick

// A hotkey reminder: a quiet label and the keys as small key caps,
// e.g. "Stop  [Super] []]". keys: ["Super", "]"].
Row {
    id: root

    property string label: ""
    property int labelWidth: 0 // 0 = as wide as the label; set to line up a column of hints
    property var keys: []

    spacing: 4

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.label !== ""
        width: root.labelWidth > 0 ? root.labelWidth : implicitWidth
        rightPadding: 4
        text: root.label
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall - 1
    }

    Repeater {
        model: root.keys

        Rectangle {
            required property string modelData

            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(height, keyText.implicitWidth + 12)
            height: 20
            radius: 5
            color: Theme.tile
            border.color: Theme.border

            Text {
                id: keyText
                anchors.centerIn: parent
                text: parent.modelData
                color: Theme.textPrimary
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontSmall - 3
                font.weight: Font.DemiBold
            }
        }
    }
}
