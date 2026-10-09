import QtQuick
import qs.config

// One-line text input on a filled background, with a placeholder.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool password: false

    signal accepted()
    signal keyPressed(var event) // set event.accepted to stop the input handling it

    implicitHeight: 34
    radius: Theme.innerRadius
    color: Theme.highlight
    border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.6) : "transparent"

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        color: Theme.textPrimary
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        font.pixelSize: Theme.fontSmall
        clip: true
        onAccepted: root.accepted()
        Keys.onPressed: event => root.keyPressed(event)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Theme.textSecondary
            font: input.font
        }
    }
}
