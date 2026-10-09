import QtQuick

// Wifi networks as a panel, for "> wifi" (qs ipc call popup toggle wifi).
// The bar shows the same thing when hovering its wifi icon.
Popup {
    id: root

    name: "wifi"
    surface: card

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: 360
        opacity: root.reveal

        WifiView {
            width: parent.width
            active: root.open
        }
    }
}
