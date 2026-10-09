import Quickshell
import QtQuick
import "icons.js" as Icons

// Power menu: a floating card sliding in at the right, like the volume OSD.
// Opened from the power icon in the bar (or `qs ipc call popup toggle power`).
// Nothing runs on the first click: it arms the action ("Click to confirm")
// and a second click within a few seconds runs it.
Popup {
    id: root

    // To add one: what it's called, its glyph, what it does.
    readonly property var actions: [
        { text: "Lock", glyph: Icons.lock, run: () => Lock.lock() },
        { text: "Log out", glyph: Icons.logout, run: () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) },
        { text: "Suspend", glyph: Icons.suspend, run: () => Lock.suspend() }, // locked on wake
        { text: "Restart", glyph: Icons.restart, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { text: "Shut down", glyph: Icons.power, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
    ]

    property int cardWidth: 172
    property int rowHeight: 40
    property int confirmFor: 3000

    // Index of the action waiting for its confirming click, or -1.
    property int armed: -1

    function pick(index) {
        if (armed !== index) {
            armed = index;
            disarm.restart();
            return;
        }
        armed = -1;
        Popups.close();
        actions[index].run();
    }

    name: "power"
    surface: card

    onOpenChanged: armed = -1

    Timer {
        id: disarm
        interval: root.confirmFor
        onTriggered: root.armed = -1
    }

    Card {
        id: card

        width: root.cardWidth
        height: column.implicitHeight + 16
        x: parent.width - (width + Theme.gap) * root.reveal
        y: (parent.height - height) / 2
        opacity: root.reveal
        glows: true

        Column {
            id: column
            anchors.centerIn: parent
            width: parent.width - 16

            Repeater {
                model: root.actions

                Rectangle {
                    id: action

                    required property var modelData
                    required property int index
                    readonly property bool armed: root.armed === index

                    width: column.width
                    height: root.rowHeight
                    radius: Theme.innerRadius
                    color: armed ? Theme.error : hover.hovered ? Theme.highlight : "transparent"

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.pick(action.index)
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: action.modelData.glyph
                            color: action.armed ? Theme.errorText : Theme.textPrimary
                            font.family: Theme.iconFont
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: action.armed ? "Click to confirm" : action.modelData.text
                            color: action.armed ? Theme.errorText : Theme.textPrimary
                            font.pixelSize: Theme.fontSmall
                            font.weight: action.armed ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
