import QtQuick
import "icons.js" as Icons

// Screenshot or screen recording tools (Recorder.qml), one panel each:
// shell.qml makes this twice, named "screenshot" and "record".
//   screenshot: region / screen
//   record:     region / screen, sound; Stop while recording
// Opened with "> screenshot" / "> record" in the launcher, the dashboard, or
// `qs ipc call popup toggle screenshot|record`. While recording,
// RecordingCard.qml shows the time; click it to stop.
Popup {
    id: root

    readonly property bool recording: name === "record"

    property int cardWidth: 380

    readonly property var sounds: [
        { value: "none", text: "No sound" },
        { value: "all", text: "All sounds" },
    ]

    surface: card

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: root.cardWidth
        opacity: root.reveal

        SectionTitle {
            visible: !root.recording
            text: "Screenshot"
        }

        Row {
            width: parent.width
            spacing: 8
            visible: !root.recording

            CaptureButton {
                glyph: Icons.region
                text: "Region"
                onClicked: Recorder.screenshot("region")
            }

            CaptureButton {
                glyph: Icons.monitor
                text: "Screen"
                onClicked: Recorder.screenshot("screen")
            }
        }

        SectionTitle {
            visible: root.recording
            text: Recorder.recording ? `Recording · ${Media.formatTime(Recorder.elapsed)}` : "Record"
        }

        Row {
            width: parent.width
            spacing: 8
            visible: root.recording && !Recorder.busy

            CaptureButton {
                glyph: Icons.region
                text: "Region"
                onClicked: Recorder.record("region")
            }

            CaptureButton {
                glyph: Icons.monitor
                text: "Screen"
                onClicked: Recorder.record("screen")
            }
        }

        PanelButton {
            visible: root.recording && Recorder.busy
            primary: true
            icon: Icons.stop
            label: "Stop recording"
            onClicked: Recorder.stop()
        }

        SettingChoice {
            width: parent.width
            visible: root.recording && !Recorder.busy
            label: "Sound"
            options: root.sounds
            value: Recorder.audio
            onPicked: value => Recorder.audio = value
        }

        // Hotkeys for next time, under a thin line.
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        // One hint per line; labels share a width so the keys line up.
        Column {
            spacing: 6

            KeyHint {
                visible: !root.recording
                label: "Region"
                keys: Recorder.keys.screenshot
            }

            KeyHint {
                visible: root.recording
                label: "Open"
                labelWidth: 44
                keys: Recorder.keys.record
            }

            KeyHint {
                visible: root.recording
                label: "Stop"
                labelWidth: 44
                keys: Recorder.keys.stop
            }
        }
    }

    // A big button with a glyph over its name.
    component CaptureButton: Rectangle {
        id: button

        property string glyph: ""
        property string text: ""

        signal clicked()

        width: (parent.width - 8) / 2
        height: 64
        radius: Theme.innerRadius
        color: hover.hovered ? Qt.alpha(Theme.textPrimary, 0.14) : Theme.highlight

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: button.clicked()
        }

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.glyph
                color: Theme.textPrimary
                font.family: Theme.iconFont
                font.pixelSize: 20
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.text
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
