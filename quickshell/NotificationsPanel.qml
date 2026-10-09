import QtQuick

// Notification history as a panel, for "> notifications" and SUPER + N
// (qs ipc call popup toggle notifications). The bar shows the same thing
// when hovering its bell.
Popup {
    id: root

    name: "notifications"
    surface: card

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: 420
        opacity: root.reveal

        NotificationsView {
            width: parent.width
            active: root.open
        }
    }
}
