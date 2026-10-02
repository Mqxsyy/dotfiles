import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

// Stacking toast popups driven over IPC:
//   qs ipc call claude notify "<title>" "<body>"
//   qs ipc call claude dismiss
// A toast with the same title and body as a visible one refreshes it instead of stacking.
PanelWindow {
    id: root

    property int timeout: 6000
    property int maxToasts: 4
    property int cardWidth: 380
    property int shadowPad: 24

    readonly property color surface: "#e61c1b22"
    readonly property color border: "#2effffff"
    readonly property color textPrimary: "#f2efe9"
    readonly property color textSecondary: "#a8a39b"
    readonly property color accent: "#d97757"

    function notify(title, body) {
        const time = Qt.formatTime(new Date(), "hh:mm");

        for (let i = 0; i < toasts.count; i++) {
            const t = toasts.get(i);
            if (t.title === title && t.body === body) {
                toasts.setProperty(i, "time", time);
                toasts.setProperty(i, "stamp", t.stamp + 1);
                return;
            }
        }

        toasts.insert(0, { title: title, body: body, time: time, stamp: 0 });
        while (toasts.count > root.maxToasts)
            toasts.remove(toasts.count - 1);
    }

    function dismissAll() {
        toasts.clear();
    }

    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "claude-popup"
    exclusionMode: ExclusionMode.Ignore

    // Linger briefly after the last toast closes so its exit animation can finish.
    visible: toasts.count > 0 || linger.running
    color: "transparent"
    implicitWidth: cardWidth + shadowPad * 2
    implicitHeight: maxToasts * 110 + shadowPad * 2
    mask: Region { item: list }

    IpcHandler {
        target: "claude"

        function notify(title: string, body: string): void {
            root.notify(title, body);
        }

        function dismiss(): void {
            root.dismissAll();
        }
    }

    Timer {
        id: linger
        interval: 400
    }

    ListModel {
        id: toasts
        onCountChanged: if (count === 0) linger.restart()
    }

    ListView {
        id: list

        x: root.shadowPad
        y: root.shadowPad
        width: root.cardWidth
        height: contentHeight
        spacing: 10
        interactive: false
        model: toasts

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

        delegate: Rectangle {
            id: card

            required property int index
            required property string title
            required property string body
            required property string time
            required property int stamp

            property real progress: 1

            function close() {
                countdown.stop();
                if (index >= 0)
                    toasts.remove(index);
            }

            width: root.cardWidth
            height: content.implicitHeight + 36
            radius: 18
            color: root.surface
            border.color: root.border
            border.width: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.55
                shadowBlur: 1.0
                shadowVerticalOffset: 6
                blurMax: 32
            }

            onStampChanged: {
                countdown.restart();
                bump.restart();
            }
            Component.onCompleted: countdown.start()

            NumberAnimation {
                id: countdown
                target: card
                property: "progress"
                from: 1
                to: 0
                duration: root.timeout
                paused: running && hover.hovered
                onFinished: card.close()
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
                onTapped: card.close()
            }

            Row {
                id: content
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 14

                Rectangle {
                    id: badge
                    width: 40
                    height: 40
                    radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(root.accent, 1.2) }
                        GradientStop { position: 1; color: Qt.darker(root.accent, 1.25) }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✻"
                        color: "white"
                        font.pixelSize: 22
                        font.bold: true
                    }
                }

                Column {
                    width: content.width - badge.width - content.spacing
                    anchors.verticalCenter: badge.verticalCenter
                    spacing: 3

                    Item {
                        width: parent.width
                        height: titleText.implicitHeight

                        Text {
                            id: titleText
                            width: parent.width - timeText.implicitWidth - 8
                            text: card.title
                            color: root.textPrimary
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            id: timeText
                            anchors.right: parent.right
                            anchors.verticalCenter: titleText.verticalCenter
                            text: card.time
                            color: root.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: card.body
                        color: root.textSecondary
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        lineHeight: 1.15
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 18
                anchors.bottomMargin: 7
                height: 3
                radius: 2
                width: (parent.width - 36) * card.progress
                color: root.accent
                opacity: hover.hovered ? 0.4 : 0.85
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }
}
