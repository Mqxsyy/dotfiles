import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components

// Stack of toasts in the top-right corner, Theme.gap from the edges like the
// bar's cards; while the bar shows, they sit under its status card
// (BarLayout.qml). What's shown lives in Notifications.qml; this only draws
// it. Click a toast to open/dismiss it.
ShellWindow {
    id: root

    property int cardWidth: 380
    // Where the stack starts: under the bar when it shows.
    readonly property real top: BarLayout.of(screen?.name).rightBottom + Theme.gap

    // Full height, so following the bar never resizes the window; the mask
    // keeps the rest from taking input.
    anchors {
        top: true
        bottom: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay

    // Linger briefly after the last toast closes so its exit animation can finish.
    name: "toasts"
    shown: Notifications.toasts.count > 0 || linger.running
    implicitWidth: Theme.shadowPad + cardWidth + Theme.gap
    mask: Region { item: list }

    Timer {
        id: linger
        interval: 400
    }

    Connections {
        target: Notifications.toasts
        function onCountChanged() {
            if (Notifications.toasts.count === 0)
                linger.restart();
        }
    }

    ListView {
        id: list

        x: Theme.shadowPad
        y: root.top
        width: root.cardWidth
        height: contentHeight
        spacing: 10
        interactive: false
        model: Notifications.toasts

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; from: 60; to: 0; duration: 380; easing.type: Easing.OutExpo }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; to: 60; duration: 260; easing.type: Easing.InCubic }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 320; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; to: 1; duration: 200 }
            NumberAnimation { property: "x"; to: 0; duration: 200 }
        }

        delegate: Card {
            id: card

            required property string key
            required property string title
            required property string body
            required property string glyph
            required property string icon
            required property string image
            required property bool critical
            required property int timeout
            required property string time
            required property int stamp

            property real progress: 1

            width: root.cardWidth
            height: content.implicitHeight + Theme.padding * 2 + 4
            border.color: critical ? Theme.accent : Theme.border

            onStampChanged: {
                if (timeout > 0)
                    countdown.restart();
                bump.restart();
            }
            Component.onCompleted: if (timeout > 0) countdown.start()

            NumberAnimation {
                id: countdown
                target: card
                property: "progress"
                from: 1
                to: 0
                duration: card.timeout
                paused: running && hover.hovered
                onFinished: Notifications.close(card.key)
            }

            SequentialAnimation {
                id: bump
                NumberAnimation { target: card; property: "scale"; to: 1.03; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: card; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Notifications.activate(card.key)
            }

            Row {
                id: content
                x: Theme.padding + 4
                y: Theme.padding
                width: parent.width - x * 2
                spacing: 14

                // App icon when there is one, otherwise the glyph.
                Item {
                    id: badge
                    width: Theme.iconSize
                    height: Theme.iconSize

                    IconImage {
                        anchors.fill: parent
                        visible: card.icon !== ""
                        source: card.icon
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: card.icon === ""
                        text: card.glyph
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.fontLarge + 5
                        font.weight: Font.DemiBold
                    }
                }

                Column {
                    width: content.width - badge.width - content.spacing
                    topPadding: (badge.height - titleText.implicitHeight) / 2 // title lines up with the badge
                    spacing: 3

                    Item {
                        width: parent.width
                        height: titleText.implicitHeight

                        Text {
                            id: titleText
                            width: parent.width - timeText.implicitWidth - 8
                            text: card.title
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontNormal
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            id: timeText
                            anchors.right: parent.right
                            anchors.verticalCenter: titleText.verticalCenter
                            text: card.time
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSmall - 1
                        }
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: card.body
                        textFormat: Text.PlainText
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        lineHeight: 1.15
                    }

                    Item {
                        width: 1
                        height: 6
                        visible: card.image !== ""
                    }

                    // A picture that came with it (screenshot preview).
                    ClippingRectangle {
                        visible: card.image !== ""
                        width: parent.width
                        height: preview.status === Image.Ready ? Math.min(200, width * preview.implicitHeight / preview.implicitWidth) : 0
                        radius: Theme.innerRadius
                        color: Theme.tile

                        Image {
                            id: preview
                            anchors.fill: parent
                            source: card.image ? "file://" + card.image : ""
                            sourceSize.width: 720
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                }
            }

            // Time left before the toast closes itself; critical toasts stay.
            Rectangle {
                visible: card.timeout > 0
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: Theme.padding + 4
                anchors.bottomMargin: 7
                height: 3
                radius: 2
                width: (parent.width - anchors.leftMargin * 2) * card.progress
                color: Theme.accent
                opacity: hover.hovered ? 0.4 : 0.85
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }
}
