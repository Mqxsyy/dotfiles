import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components
import "../../utils/icons.js" as Icons

// Now playing: art next to the track and a visualizer; under the art
// previous / play / next, under the visualizer the seek bar with times and
// shuffle / repeat, and the player's own volume down the right edge; click
// the art to bring up the player. With several players, chips on top
// pick which one the bar controls. Shown when the bar's media card
// expands (or "> media").
Column {
    id: root

    // Only ask the player for its position while this is on screen.
    property bool active: true
    readonly property MprisPlayer player: Media.player

    // Repeat cycles off -> playlist -> track.
    readonly property var repeatOrder: [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track]

    // Art to the track text; the buttons and seek bar line up with them.
    property int gap: 18

    spacing: 12

    Timer {
        running: root.active && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }

    Flow {
        width: parent.width
        visible: Media.players.length > 1
        spacing: 6

        Repeater {
            model: Media.players

            PanelButton {
                required property var modelData
                primary: modelData === root.player
                label: modelData.identity
                onClicked: Media.chosen = modelData
            }
        }
    }

    Text {
        visible: !root.player
        text: "Nothing playing"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }

    // The player on the left, its volume down the right edge.
    Row {
        visible: root.player !== null
        width: parent.width
        spacing: 12

        Column {
            id: main
            width: parent.width - volume.width - parent.spacing
            spacing: 12

            // Art, then title and artist, with the visualizer under them.
            Row {
                visible: root.player !== null
                width: parent.width
                spacing: root.gap

                Item {
                    id: art
                    width: 100
                    height: 100

                    RectangularShadow {
                        anchors.fill: parent
                        radius: Theme.innerRadius
                        offset.y: 6
                        blur: 20
                        color: Theme.shadow
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Theme.innerRadius
                        color: Theme.tile

                        ArtImage {
                            anchors.fill: parent
                            sources: Media.artSources
                        }

                        // Click the art to bring up the player.
                        HoverHandler {
                            enabled: root.player?.canRaise ?? false
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            enabled: root.player?.canRaise ?? false
                            onTapped: root.player.raise()
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: Media.artSources.length === 0
                            text: Icons.music
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: 34
                        }
                    }
                }

                Item {
                    width: parent.width - art.width - parent.spacing
                    height: art.height

                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            width: parent.width
                            text: root.player?.trackTitle ?? ""
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontLarge + 3
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: root.player?.trackArtist ?? ""
                            color: Theme.textPrimary
                            opacity: 0.85
                            font.pixelSize: Theme.fontSmall + 1
                            elide: Text.ElideRight
                        }
                    }

                    Visualizer {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        active: root.active && Spectrum.listening
                    }
                }
            }

            // Previous / play / next under the art; the seek bar under the
            // visualizer, with the times and shuffle / repeat under it.
            Row {
                visible: root.player !== null
                width: parent.width
                spacing: root.gap

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: art.width
                    height: transport.height

                    // A bit wider than the art; spaced so prev / next aren't misclicked.
                    Row {
                        id: transport
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        BarButton {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 30
                            implicitHeight: 30
                            iconSize: 20
                            icon: Icons.previous
                            interactive: root.player?.canGoPrevious ?? false
                            onClicked: root.player.previous()
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            height: 30
                            radius: width / 2
                            gradient: Theme.accentGradient
                            scale: playTap.pressed ? 0.92 : playHover.hovered ? 1.05 : 1

                            Behavior on scale {
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }

                            HoverHandler {
                                id: playHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                id: playTap
                                onTapped: root.player.togglePlaying()
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.player?.isPlaying ? Icons.pause : Icons.play
                                color: Theme.accentText
                                font.family: Theme.iconFont
                                font.pixelSize: 15
                            }
                        }

                        BarButton {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 30
                            implicitHeight: 30
                            iconSize: 20
                            icon: Icons.next
                            interactive: root.player?.canGoNext ?? false
                            onClicked: root.player.next()
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - art.width - parent.spacing

                    // Until the length is known (see Media.length) the bar stays
                    // empty and the total shows --:--.
                    readonly property bool known: Media.length > 0

                    Slider {
                        id: seek
                        width: parent.width
                        live: false
                        from: 0
                        to: parent.known ? Media.length : 1
                        stepSize: 1
                        value: parent.known ? root.player.position : 0
                        enabled: parent.known && root.player.canSeek
                        onMoved: value => Media.seek(value)
                    }

                    Item {
                        width: parent.width
                        height: modes.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Media.formatTime(seek.pressed || seek.settling ? seek.dragValue : root.player?.position ?? 0)
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSmall - 3
                        }

                        Row {
                            id: modes
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2

                            BarButton {
                                visible: root.player?.shuffleSupported ?? false
                                implicitHeight: 22
                                icon: Icons.shuffle
                                iconColor: root.player?.shuffle ? Theme.accent : Theme.textSecondary
                                onClicked: root.player.shuffle = !root.player.shuffle
                            }

                            BarButton {
                                visible: root.player?.loopSupported ?? false
                                implicitHeight: 22
                                icon: root.player?.loopState === MprisLoopState.Track ? Icons.repeatOne : Icons.repeat
                                iconColor: root.player?.loopState === MprisLoopState.None ? Theme.textSecondary : Theme.accent
                                onClicked: {
                                    const next = (root.repeatOrder.indexOf(root.player.loopState) + 1) % root.repeatOrder.length;
                                    root.player.loopState = root.repeatOrder[next];
                                }
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.parent.known ? Media.formatTime(Media.length) : "--:--"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSmall - 3
                        }
                    }
                }
            }
        }

        // The player's own volume, apart from the speakers' (see
        // Media.stream): a vertical slider, the icon under it mutes. Dimmed
        // while the player makes no sound.
        Item {
            id: volume

            readonly property real level: Media.stream?.audio?.volume ?? 0
            readonly property bool muted: Media.stream?.audio?.muted ?? false

            width: 30
            height: main.height
            enabled: Media.stream !== null
            opacity: enabled ? 1 : 0.4

            // A horizontal slider turned upright: empty at the bottom.
            Item {
                width: parent.width
                height: parent.height - mute.height - 6

                Slider {
                    anchors.centerIn: parent
                    width: parent.height
                    rotation: -90
                    value: volume.level
                    fill: volume.muted ? Theme.textSecondary : Theme.accent
                    onMoved: value => Audio.setNodeVolume(Media.stream, value)
                }
            }

            BarButton {
                id: mute
                anchors.bottom: parent.bottom
                implicitWidth: 30
                implicitHeight: 26
                icon: volume.muted || volume.level === 0 ? Icons.volumeOff : Icons.volumeLevel(volume.level)
                iconColor: volume.muted ? Theme.textSecondary : Theme.textPrimary
                onClicked: Audio.toggleNodeMute(Media.stream)
                onScrolled: steps => Audio.setNodeVolume(Media.stream, volume.level + steps * 0.05)
            }
        }
    }
}
