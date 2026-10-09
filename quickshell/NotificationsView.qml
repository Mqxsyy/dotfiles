import Quickshell
import Quickshell.Widgets
import QtQuick
import "icons.js" as Icons
import "format.js" as Format

// Notification history (Notifications.qml), newest first, with do not
// disturb and clear all. Click one to open it (the app's default action),
// or its × to dismiss it. Shown when the bar's status card expands on the
// bell (or "> notifications").
Column {
    id: root

    // On screen: everything counts as read.
    property bool active: true
    property int listHeight: 400

    // For the "5m" ages; ticks while on screen.
    property real now: Date.now()

    spacing: 12

    onActiveChanged: {
        if (!active)
            return;
        now = Date.now();
        Notifications.markRead();
    }

    Connections {
        target: Notifications

        function onUnreadChanged() {
            if (root.active && Notifications.unread > 0)
                Notifications.markRead();
        }
    }

    Timer {
        running: root.active
        interval: 30000
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Item {
        width: parent.width
        height: 30

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontNormal
            font.weight: Font.DemiBold
        }

        Row {
            anchors.right: parent.right
            height: parent.height
            spacing: 6

            PanelButton {
                icon: Notifications.dnd ? Icons.bellOff : Icons.bell
                label: "Do not disturb"
                primary: Notifications.dnd
                onClicked: Notifications.dnd = !Notifications.dnd
            }

            PanelButton {
                visible: Notifications.history.length > 0
                icon: Icons.trash
                label: "Clear"
                onClicked: Notifications.clearHistory()
            }
        }
    }

    Text {
        visible: Notifications.history.length === 0
        text: Notifications.dnd ? "Nothing yet · toasts are hidden" : "Nothing yet"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }

    ListView {
        id: list

        width: parent.width
        height: Math.min(contentHeight, root.listHeight)
        visible: count > 0
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds

        // Keeps each entry's delegate while others come and go.
        model: ScriptModel {
            values: Notifications.history
            objectProp: "key"
        }

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 150 }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            id: entry

            required property var modelData

            width: list.width
            height: content.implicitHeight + 20
            radius: Theme.innerRadius
            color: hover.hovered ? Theme.tileHover : Theme.tile
            border.width: modelData.critical ? 1 : 0
            border.color: Theme.accent

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            // Not on the ×, which has its own.
            TapHandler {
                onTapped: {
                    if (!dismiss.hovered)
                        Notifications.activate(entry.modelData.key);
                }
            }

            Row {
                id: content

                x: 12
                y: 10
                width: parent.width - x * 2
                spacing: 12

                // App icon when there is one, otherwise the glyph.
                Item {
                    id: badge
                    width: 28
                    height: 28

                    IconImage {
                        anchors.fill: parent
                        visible: entry.modelData.icon !== ""
                        source: entry.modelData.icon
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: entry.modelData.icon === ""
                        text: entry.modelData.glyph
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.fontLarge + 2
                        font.weight: Font.DemiBold
                    }
                }

                Column {
                    width: parent.width - badge.width - parent.spacing
                    spacing: 2

                    // Title, and its age; the age turns into × on hover.
                    Item {
                        width: parent.width
                        height: Math.max(title.implicitHeight, dismiss.height)

                        Text {
                            id: title
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - dismiss.width - 8
                            text: entry.modelData.title
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSmall + 1
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !hover.hovered
                            text: Format.age(entry.modelData.time, root.now)
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSmall - 2
                        }

                        BarButton {
                            id: dismiss
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 24
                            implicitHeight: 24
                            visible: hover.hovered
                            icon: Icons.close
                            iconColor: Theme.textSecondary
                            onClicked: Notifications.remove(entry.modelData.key)
                        }
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: entry.modelData.app && entry.modelData.app !== entry.modelData.title ? entry.modelData.app : ""
                        color: Theme.accent
                        font.pixelSize: Theme.fontSmall - 2
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: entry.modelData.body
                        textFormat: Text.PlainText
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        lineHeight: 1.1
                    }
                }
            }
        }
    }
}
