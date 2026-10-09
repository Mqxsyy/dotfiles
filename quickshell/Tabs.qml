import QtQuick

// Segmented control: one pill per tab, the current one filled.
// Set `tabs` and `current`; `picked` tells which one was clicked.
Rectangle {
    id: root

    property var tabs: []
    property string current: ""

    signal picked(string tab)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 36
    radius: height / 2
    color: Theme.tile

    Row {
        id: row
        anchors.centerIn: parent

        Repeater {
            model: root.tabs

            Rectangle {
                id: tab

                required property string modelData
                readonly property bool current: root.current === modelData

                width: label.implicitWidth + 28
                height: 28
                radius: height / 2
                color: hover.hovered ? Theme.tileHover : "transparent"
                gradient: current ? Theme.accentGradient : null

                Glow {
                    on: tab.current
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.picked(tab.modelData)
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: tab.modelData
                    color: tab.current ? Theme.accentText : Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
