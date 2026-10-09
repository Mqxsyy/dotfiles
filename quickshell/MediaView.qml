import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "icons.js" as Icons

// Now playing: big art next to the track, seek bar with times, and
// shuffle / previous / play / next / repeat; click the art to bring up the
// player. With several players, chips on
// top pick which one the bar controls. Shown when the bar's media card
// expands, and in the media panel ("> media").
Column {
    id: root

    // Only ask the player for its position while this is on screen.
    property bool active: true
    readonly property MprisPlayer player: Media.player

    // Repeat cycles off -> playlist -> track.
    readonly property var repeatOrder: [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track]

    spacing: 16

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

    // Art, then title, artist and album.
    Row {
        visible: root.player !== null
        width: parent.width
        spacing: 18

        Item {
            id: art
            width: 124
            height: 124

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
                    font.pixelSize: 40
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - art.width - parent.spacing
            spacing: 6

            Text {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                color: Theme.textPrimary
                font.pixelSize: Theme.fontLarge + 3
                font.weight: Font.Bold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                lineHeight: 1.05
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                color: Theme.textPrimary
                opacity: 0.85
                font.pixelSize: Theme.fontSmall + 1
                maximumLineCount: 2
                wrapMode: Text.Wrap
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall - 1
                elide: Text.ElideRight
            }
        }
    }

    Visualizer {
        width: parent.width
        visible: root.player !== null
        active: root.active && (root.player?.isPlaying ?? false)
    }

    // Elapsed, seek bar, total.
    Row {
        visible: root.player !== null && root.player.lengthSupported && root.player.length > 0
        width: parent.width
        spacing: 10

        Text {
            id: elapsed
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            text: Media.formatTime(root.player?.position ?? 0)
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall - 2
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - elapsed.width - total.width - parent.spacing * 2
            from: 0
            to: root.player?.length ?? 1
            stepSize: 1
            value: root.player?.position ?? 0
            enabled: root.player?.canSeek ?? false
            onMoved: value => root.player.position = value
        }

        Text {
            id: total
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: Media.formatTime(root.player?.length ?? 0)
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall - 2
        }
    }

    // Shuffle, previous, play/pause, next, repeat.
    Row {
        visible: root.player !== null
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 18

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.player?.shuffleSupported ?? false
            icon: Icons.shuffle
            iconColor: root.player?.shuffle ? Theme.accent : Theme.textSecondary
            onClicked: root.player.shuffle = !root.player.shuffle
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.previous
            interactive: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            height: 52
            radius: width / 2
            gradient: Theme.accentGradient
            scale: playTap.pressed ? 0.92 : playHover.hovered ? 1.05 : 1

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Glow {}

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
                font.pixelSize: 24
            }
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.next
            interactive: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }

        BarButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.player?.loopSupported ?? false
            icon: root.player?.loopState === MprisLoopState.Track ? Icons.repeatOne : Icons.repeat
            iconColor: root.player?.loopState === MprisLoopState.None ? Theme.textSecondary : Theme.accent
            onClicked: {
                const next = (root.repeatOrder.indexOf(root.player.loopState) + 1) % root.repeatOrder.length;
                root.player.loopState = root.repeatOrder[next];
            }
        }
    }
}
