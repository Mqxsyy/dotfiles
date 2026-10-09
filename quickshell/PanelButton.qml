import QtQuick

// A filled button for panels ("Connect", "Forget"). `primary` fills it with
// the accent color, for the main action.
BarButton {
    id: root

    property bool primary: false

    implicitWidth: contentWidth + 24
    implicitHeight: 30
    color: {
        if (primary)
            return hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent;
        return hovered ? Theme.tileHover : Theme.tile;
    }
    iconColor: primary ? Theme.accentText : Theme.textPrimary
    labelColor: primary ? Theme.accentText : Theme.textPrimary
}
