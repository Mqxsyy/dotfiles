import QtQuick
import qs.config

// Thin scrollbar on a Flickable's right edge; hidden when everything fits.
// Drag the thumb to scroll.
Rectangle {
    id: root

    required property Flickable flickable
    readonly property bool active: hover.hovered || mouse.pressed

    parent: flickable // not its contentItem, so it stays put while scrolling
    x: flickable.width - width
    y: flickable.visibleArea.yPosition * flickable.height
    width: active ? 6 : 4
    height: flickable.visibleArea.heightRatio * flickable.height
    radius: width / 2
    color: Qt.alpha(Theme.textPrimary, active ? 0.5 : 0.25)
    visible: flickable.contentHeight > flickable.height

    Behavior on width {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        id: mouse

        property real startY: 0
        property real startContentY: 0

        anchors.fill: parent
        anchors.leftMargin: -4 // easier to grab
        preventStealing: true

        onPressed: event => {
            startY = mapToItem(root.flickable, 0, event.y).y;
            startContentY = root.flickable.contentY;
        }
        onPositionChanged: event => {
            const flick = root.flickable;
            const moved = mapToItem(flick, 0, event.y).y - startY;
            const maxY = flick.contentHeight - flick.height;
            flick.contentY = Math.max(0, Math.min(maxY, startContentY + moved * flick.contentHeight / flick.height));
        }
    }
}
