import Quickshell
import Quickshell.Wayland
import QtQuick
import "icons.js" as Icons

// Volume / brightness indicator: a floating card sliding in at the right of
// the focused screen. Shows whenever either changes,
// then slides back. Takes no input.
ShellWindow {
    id: root

    property int cardLength: 180
    property int cardWidth: 48
    property int showFor: 1500

    // Which one changed last: "volume" or "brightness".
    property string kind: "volume"
    readonly property real value: kind === "volume" ? Audio.volume : Brightness.value
    readonly property bool muted: kind === "volume" && Audio.muted
    readonly property string glyph: {
        if (kind === "brightness")
            return Icons.level(Icons.brightness, value);
        return muted || value === 0 ? Icons.volumeOff : Icons.volumeLevel(value);
    }

    readonly property bool active: hideTimer.running

    // Volume settles right after startup; don't treat that as a change.
    property bool armed: false

    function show(newKind) {
        if (!visible && FocusedScreen.screen)
            root.screen = FocusedScreen.screen;
        kind = newKind;
        hideTimer.restart();
    }

    name: "osd"
    // Stay mapped until the slide-out finishes.
    shown: active || card.x < width
    implicitWidth: cardWidth + Theme.gap + Theme.shadowPad
    implicitHeight: cardLength + Theme.shadowPad * 2
    mask: Region {}

    anchors.right: true

    WlrLayershell.layer: WlrLayer.Overlay

    Timer {
        running: true
        interval: 2000
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: root.showFor
    }

    Connections {
        target: Audio

        function onVolumeChanged() {
            if (root.armed)
                root.show("volume");
        }

        function onMutedChanged() {
            if (root.armed)
                root.show("volume");
        }
    }

    Connections {
        target: Brightness

        function onAdjusted() {
            root.show("brightness");
        }
    }

    Card {
        id: card

        width: root.cardWidth
        height: root.cardLength
        radius: Math.min(Theme.radius, width / 2)
        x: root.active ? parent.width - width - Theme.gap : parent.width + Theme.shadowPad
        y: Theme.shadowPad

        Behavior on x {
            NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
        }

        // Percent on top, the level as a vertical track, icon at the bottom.
        Column {
            anchors.centerIn: parent
            spacing: 10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(root.value * 100)
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 6
                height: root.cardLength - 80
                radius: 3
                color: Theme.highlight

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * Math.min(1, root.value)
                    radius: parent.radius
                    color: root.muted ? Theme.textSecondary : Theme.accent

                    Behavior on height {
                        NumberAnimation { duration: 120 }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.glyph
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 18
            }
        }
    }
}
