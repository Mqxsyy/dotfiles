import Quickshell
import Quickshell.Widgets
import QtQuick
import "icons.js" as Icons

// Sound: output and input volume, mute and default device, and volume per
// app playing sound. Shown when the bar's status card expands on the volume
// icon, and in the audio panel ("> audio").
Column {
    id: root

    spacing: 10

    SectionTitle {
        text: "Output"
    }

    VolumeControl {
        width: parent.width
        node: Audio.sink
        glyph: Icons.volumeLevel(Audio.volume)
        mutedGlyph: Icons.volumeOff
    }

    DeviceList {
        width: parent.width
        devices: Audio.sinks
        current: Audio.sink
        glyph: Icons.speaker
    }

    SectionTitle {
        topPadding: 6
        text: "Input"
    }

    VolumeControl {
        width: parent.width
        node: Audio.source
        glyph: Icons.mic
        mutedGlyph: Icons.micOff
    }

    DeviceList {
        width: parent.width
        devices: Audio.sources
        current: Audio.source
        glyph: Icons.mic
    }

    SectionTitle {
        topPadding: 6
        visible: Audio.streams.length > 0
        text: "Apps"
    }

    Repeater {
        model: Audio.streams

        AppVolume {
            required property var modelData
            width: parent.width
            node: modelData
        }
    }

    // Mute button, slider and percent for one node.
    component VolumeControl: Row {
        id: control

        property var node: null
        property string glyph: ""
        property string mutedGlyph: ""
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0

        spacing: 8

        BarButton {
            id: mute
            anchors.verticalCenter: parent.verticalCenter
            icon: control.muted ? control.mutedGlyph : control.glyph
            iconColor: control.muted ? Theme.textSecondary : Theme.textPrimary
            onClicked: Audio.toggleNodeMute(control.node)
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: control.width - mute.width - percent.width - control.spacing * 2
            value: control.volume
            fill: control.muted ? Theme.textSecondary : Theme.accent
            onMoved: value => Audio.setNodeVolume(control.node, value)
        }

        Text {
            id: percent
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(control.volume * 100) + "%"
            color: control.muted ? Theme.textSecondary : Theme.textPrimary
            font.pixelSize: Theme.fontSmall
        }
    }

    // The devices to pick the default from; hidden when there's only one.
    component DeviceList: Column {
        id: deviceList

        property var devices: []
        property var current: null
        property string glyph: ""

        visible: devices.length > 1

        Repeater {
            model: deviceList.devices

            ListRow {
                required property var modelData
                width: deviceList.width
                glyph: deviceList.glyph
                title: Audio.deviceName(modelData)
                selected: modelData === deviceList.current
                onClicked: Audio.setDefault(modelData)
            }
        }
    }

    // App icon (click to mute), name and what it's playing, volume slider.
    component AppVolume: Row {
        id: app

        property var node: null
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0
        readonly property string iconPath: Quickshell.iconPath(Audio.appIcon(node), true)

        spacing: 10

        Rectangle {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.controlSize + 4
            height: width
            radius: Theme.innerRadius
            color: iconHover.hovered ? Theme.highlight : "transparent"
            opacity: app.muted ? 0.4 : 1

            HoverHandler {
                id: iconHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Audio.toggleNodeMute(app.node)
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 22
                visible: app.iconPath !== ""
                source: app.iconPath
            }

            Text {
                anchors.centerIn: parent
                visible: app.iconPath === ""
                text: Icons.app
                color: Theme.textPrimary
                font.family: Theme.iconFont
                font.pixelSize: 18
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: app.width - icon.width - appPercent.width - app.spacing * 2

            Text {
                width: parent.width
                text: {
                    const title = Audio.streamTitle(app.node);
                    const name = Audio.appName(app.node);
                    return title && title !== name ? `${name} · ${title}` : name;
                }
                color: app.muted ? Theme.textSecondary : Theme.textPrimary
                font.pixelSize: Theme.fontSmall - 1
                elide: Text.ElideRight
            }

            Slider {
                width: parent.width
                value: app.volume
                fill: app.muted ? Theme.textSecondary : Theme.accent
                onMoved: value => Audio.setNodeVolume(app.node, value)
            }
        }

        Text {
            id: appPercent
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(app.volume * 100) + "%"
            color: app.muted ? Theme.textSecondary : Theme.textPrimary
            font.pixelSize: Theme.fontSmall
        }
    }
}
