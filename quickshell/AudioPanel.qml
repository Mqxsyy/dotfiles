import QtQuick

// Sound settings as a panel, for "> audio" (qs ipc call popup toggle audio).
// The bar shows the same thing when hovering its volume icon.
Popup {
    id: root

    name: "audio"
    surface: card

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: 400
        opacity: root.reveal

        AudioView {
            width: parent.width
        }
    }
}
