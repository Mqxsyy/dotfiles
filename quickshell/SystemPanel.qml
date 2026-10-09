import QtQuick

// System stats as a panel: "> system" or `qs ipc call popup toggle system`.
// Also a tab in the dashboard.
Popup {
    id: root

    name: "system"
    surface: card

    PanelCard {
        id: card

        x: parent.width - width - Theme.gap
        y: Theme.gap - (1 - root.reveal) * 12
        width: 400
        opacity: root.reveal

        SystemView {
            width: parent.width
            active: root.open
        }
    }
}
