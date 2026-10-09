import QtQuick
import "icons.js" as Icons

// What can be cleaned and how much each frees (Cleanup.qml). Click an
// entry twice to clean it (the first click only arms it); hovering shows
// the command it runs. System entries open a terminal where sudo asks for
// the password. The dashboard's Clean tab.
Column {
    id: root

    // Measures when it comes on screen.
    property bool active: true
    property int confirmFor: 3000
    property int listHeight: 470 // about as tall as the System tab

    // Name of the entry waiting for its confirming click, or "".
    property string armed: ""

    function pick(entry) {
        if (armed !== entry.name) {
            armed = entry.name;
            disarm.restart();
            return;
        }
        armed = "";
        Cleanup.clean(entry);
    }

    spacing: 12

    onActiveChanged: {
        armed = "";
        if (active)
            Cleanup.refresh();
    }
    Component.onCompleted: if (active) Cleanup.refresh()

    Timer {
        id: disarm
        interval: root.confirmFor
        onTriggered: root.armed = ""
    }

    // Total, and measuring again.
    Item {
        width: parent.width
        height: refresh.height

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `${System.formatBytes(Cleanup.total)} can be freed`
            color: Theme.textPrimary
            font.pixelSize: Theme.fontNormal
            font.weight: Font.DemiBold
        }

        Rectangle {
            id: refresh

            anchors.right: parent.right
            width: 30
            height: 30
            radius: width / 2
            color: refreshHover.hovered ? Theme.tileHover : Theme.tile

            HoverHandler {
                id: refreshHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Cleanup.refresh()
            }

            Text {
                anchors.centerIn: parent
                text: Icons.refresh
                color: Theme.textPrimary
                font.family: Theme.iconFont
                font.pixelSize: 15
                opacity: Cleanup.measuring ? 0.4 : 1
            }
        }
    }

    // Scrolls when taller than `listHeight`: the bar's window only has
    // so much room (Bar.qml's panelRoom).
    Flickable {
        width: parent.width
        height: Math.min(contentHeight, root.listHeight)
        contentHeight: entries.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: entries

            width: parent.width
            spacing: 12

            SectionTitle {
                text: "Your files"
            }

            Column {
                width: parent.width

                Repeater {
                    model: Cleanup.list.filter(entry => !entry.root)

                    EntryRow {}
                }
            }

            SectionTitle {
                text: "System · asks for your password"
            }

            Column {
                width: parent.width

                Repeater {
                    model: Cleanup.list.filter(entry => entry.root)

                    EntryRow {}
                }
            }
        }
    }

    // Name and what it is; how much it frees on the right.
    component EntryRow: Rectangle {
        id: row

        required property var modelData
        readonly property bool armed: root.armed === modelData.name
        readonly property bool cleaning: Cleanup.cleaning === modelData.name
        readonly property var size: Cleanup.sizes[modelData.name] // undefined = unknown
        readonly property bool empty: size === 0
        readonly property bool canClean: !empty && Cleanup.cleaning === ""

        width: parent.width
        height: 46
        radius: Theme.innerRadius
        color: armed ? Theme.error : hover.hovered && canClean ? Theme.highlight : "transparent"
        opacity: empty ? 0.5 : 1

        HoverHandler {
            id: hover
            cursorShape: row.canClean ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            enabled: row.canClean
            onTapped: root.pick(row.modelData)
        }

        Column {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - amount.width - 20

            Text {
                width: parent.width
                text: row.armed ? `Click again to clean ${row.modelData.name}` : row.modelData.name
                color: row.armed ? Theme.errorText : Theme.textPrimary
                font.pixelSize: Theme.fontSmall
                font.weight: row.armed ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            // The command while pointed at, so it's easy to look up.
            Text {
                readonly property bool showCommand: hover.hovered && !row.empty

                width: parent.width
                text: showCommand ? Cleanup.cleanCommand(row.modelData) : row.modelData.detail
                color: row.armed ? Theme.errorText : Theme.textSecondary
                font.family: showCommand ? "monospace" : Qt.application.font.family
                font.pixelSize: Theme.fontSmall - 2
                elide: Text.ElideRight
            }
        }

        Text {
            id: amount

            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: !row.armed
            text: {
                if (row.cleaning)
                    return row.modelData.root ? "In the terminal" : "Cleaning…";
                if (row.size === undefined)
                    return Cleanup.measuring && Cleanup.sizeCommand(row.modelData) ? "…" : "";
                return row.empty ? "Nothing" : System.formatBytes(row.size);
            }
            color: row.cleaning ? Theme.accent : Theme.textPrimary
            font.pixelSize: Theme.fontSmall - 1
        }
    }
}
