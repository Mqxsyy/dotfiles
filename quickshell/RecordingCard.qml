import Quickshell
import Quickshell.Wayland
import QtQuick
import "icons.js" as Icons

// While recording: red dot, time and the stop hotkey, at the top center of
// each screen just below the bar's strip. It never moves and reaching it
// doesn't reveal the bar, so it's easy to hit. On the overlay layer, so it
// stays above fullscreen windows. Hover turns the dot into a stop button;
// click to stop. One per screen (see shell.qml).
ShellWindow {
    id: root

    required property ShellScreen modelData
    property int cardHeight: 36 // same as the bar's cards
    // Below the bar's cards (Theme.gap + cardHeight), with a gap.
    readonly property int top: Theme.gap * 2 + cardHeight

    name: "recording"
    screen: modelData
    // Stay mapped until the fade-out finishes.
    shown: Recorder.recording || card.opacity > 0
    implicitHeight: top + cardHeight + Theme.shadowPad
    mask: Region { item: card }

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay

    Card {
        id: card

        x: Math.round((parent.width - width) / 2)
        y: root.top
        opacity: Recorder.recording ? 1 : 0
        scale: Recorder.recording ? 1 : 0.9
        width: recordingRow.implicitWidth + 24
        height: root.cardHeight
        radius: Math.min(Theme.radius, height / 2)
        border.color: recordingHover.hovered ? Theme.error : Theme.border

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationDuration }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            id: recordingHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: Recorder.stop()
        }

        Row {
            id: recordingRow
            anchors.centerIn: parent
            spacing: 8

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14

                Rectangle {
                    anchors.centerIn: parent
                    visible: !recordingHover.hovered
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.error

                    SequentialAnimation on opacity {
                        running: Recorder.recording
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 700 }
                        NumberAnimation { to: 1; duration: 700 }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: recordingHover.hovered
                    text: Icons.stop
                    color: Theme.error
                    font.family: Theme.iconFont
                    font.pixelSize: 15
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: recordingHover.hovered ? "Stop" : Media.formatTime(Recorder.elapsed)
                color: recordingHover.hovered ? Theme.error : Theme.textPrimary
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
            }

            KeyHint {
                anchors.verticalCenter: parent.verticalCenter
                keys: Recorder.keys.stop
            }
        }
    }
}
