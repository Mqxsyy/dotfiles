import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/icons.js" as Icons

// Power menu: a floating card sliding in at the right, like the volume OSD.
// Opened from the power icon in the bar (or `qs ipc call popup toggle power`),
// or by a power command ("> restart", ...) with that action already armed.
// Nothing runs on the first click: it arms the action ("Click to confirm"),
// and a second click (or Enter) within a few seconds runs it, once the menu
// has slid away.
Popup {
    id: root

    // To add one: its name (for Popups.open requests), what it's called, its
    // glyph, what it does.
    readonly property var actions: [
        { name: "lock", text: "Lock", glyph: Icons.lock, run: () => Lock.lock() },
        { name: "logout", text: "Log out", glyph: Icons.logout, run: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]) },
        { name: "suspend", text: "Suspend", glyph: Icons.suspend, run: () => Lock.suspend() }, // locked on wake
        { name: "restart", text: "Restart", glyph: Icons.restart, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { name: "shutdown", text: "Shut down", glyph: Icons.power, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
    ]

    property int cardWidth: 172
    property int rowHeight: 40
    property int fadeDuration: 150

    // Confirmed, runs once the menu has closed.
    property var pending: null

    function pick(index) {
        if (!open || !confirm.check(index))
            return;
        pending = actions[index];
        Popups.close();
    }

    name: "power"
    surface: card

    onOpenChanged: {
        if (!open)
            return; // keeps the confirmed row lit while it slides away
        pending = null;
        confirm.reset();
        const requested = actions.findIndex(action => action.name === Popups.request);
        if (requested !== -1)
            confirm.check(requested);
    }

    onRevealChanged: {
        if (reveal > 0 || !pending)
            return;
        const action = pending;
        pending = null;
        action.run();
    }

    Confirm {
        id: confirm
    }

    Card {
        id: card

        width: root.cardWidth
        height: column.implicitHeight + 16
        x: parent.width - (width + Theme.gap) * root.reveal
        y: (parent.height - height) / 2
        opacity: root.reveal
        glows: true
        focus: true

        Keys.onReturnPressed: if (confirm.armed !== null) root.pick(confirm.armed)
        Keys.onEnterPressed: if (confirm.armed !== null) root.pick(confirm.armed)

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
                    readonly property bool armed: confirm.armed === index

                    width: column.width
                    height: root.rowHeight
                    radius: Theme.innerRadius
                    clip: true
                    color: armed ? Theme.error : hover.hovered ? Theme.highlight : "transparent"
                    scale: tap.pressed ? 0.96 : 1

                    Behavior on color {
                        ColorAnimation { duration: root.fadeDuration }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: tap
                        onTapped: root.pick(action.index)
                    }

                    Text {
                        id: glyph
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        text: action.modelData.glyph
                        color: action.armed ? Theme.errorText : Theme.textPrimary
                        font.family: Theme.iconFont
                        font.pixelSize: 16

                        Behavior on color {
                            ColorAnimation { duration: root.fadeDuration }
                        }
                    }

                    // The name and "Click to confirm" fade into each other.
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: glyph.x + glyph.width + 12
                        text: action.modelData.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSmall
                        opacity: action.armed ? 0 : 1

                        Behavior on opacity {
                            NumberAnimation { duration: root.fadeDuration }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: glyph.x + glyph.width + 12
                        text: "Click to confirm"
                        color: Theme.errorText
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                        opacity: action.armed ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: root.fadeDuration }
                        }
                    }

                    // Time left to confirm, shrinking along the bottom.
                    Rectangle {
                        anchors.bottom: parent.bottom
                        height: 2
                        color: Qt.alpha(Theme.errorText, 0.4)
                        visible: action.armed && root.open

                        NumberAnimation on width {
                            running: action.armed && root.open
                            from: action.width
                            to: 0
                            duration: confirm.interval
                        }
                    }
                }
            }
        }
    }
}
