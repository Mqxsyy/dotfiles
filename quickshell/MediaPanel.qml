import QtQuick

// Now playing as a panel, for "> media" (qs ipc call popup toggle media).
// The bar shows the same thing when hovering its media card.
Popup {
    id: root

    name: "media"
    surface: card

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: 380
        opacity: root.reveal

        MediaView {
            width: parent.width
            active: root.open
        }
    }
}
