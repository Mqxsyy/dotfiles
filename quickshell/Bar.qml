import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import "icons.js" as Icons

// Top bar: slides down while the pointer touches the top edge anywhere.
// One per screen (see shell.qml).
//   top-left:  floating card, now playing + controls (only while there is a player)
//   center:    clock tab hanging from the top edge; click for the calendar
//   top-right: floating card, do not disturb, wifi, volume, battery
// Hovering a status item shows its hint underneath it.
ShellWindow {
    id: root

    required property ShellScreen modelData

    // Spacing rule: every control is Theme.controlSize, `inset` from its card's
    // top and bottom and `padding` from its sides; all three parts end on the
    // same line.
    property int cardHeight: 36   // the floating corner cards
    property int cardGap: 8       // floating cards' distance from the screen edges
    property int spacing: 12      // between items inside a card
    property int padding: 10      // card side to its first/last control
    readonly property int inset: (cardHeight - Theme.controlSize) / 2 // card top/bottom to its controls
    readonly property int clockDepth: cardGap + cardHeight // clock tab ends where the cards end
    property int triggerHeight: 2 // strip along the top edge that reveals the bar
    property int hideDelay: 300
    property int popupGap: 8      // space between the bar and the calendar/hint under it

    property bool calendarOpen: false

    readonly property bool revealed: hover.hovered || hideTimer.running
    readonly property MprisPlayer player: Media.player

    // The hovered status item, if it has a hint to show.
    readonly property BarButton hinted: [dnd, wifi, volume, battery].find(item => item.visible && item.hovered && item.hint) ?? null

    onRevealedChanged: if (!revealed) calendarOpen = false

    name: "bar"
    screen: modelData

    // Always tall enough for the calendar: resizing the window while hovering
    // makes the pointer leave and re-enter, which flickers the bar and hints.
    // The mask keeps the empty part from taking input.
    implicitHeight: clockDepth + popupGap + calendar.height + Theme.shadowPad

    anchors {
        top: true
        left: true
        right: true
    }

    // Input only along the top edge plus whatever is shown, so the rest of
    // the window doesn't block clicks underneath. Hidden parts sit above the
    // window, outside it.
    mask: Region {
        item: trigger

        Region { item: mediaTab }
        Region { item: clockTab }
        Region { item: statusTab }
        Region { item: calendarArea }
    }

    Item {
        id: trigger
        width: parent.width
        height: root.triggerHeight
    }

    Item {
        id: calendarArea
        x: calendar.x
        y: calendar.y
        width: calendar.width
        height: root.calendarOpen ? calendar.height : 0
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Everything visible lives in here so its HoverHandler stays hovered over
    // the buttons too (a sibling underneath would lose hover to them).
    Item {
        id: content
        anchors.fill: parent

        HoverHandler {
            id: hover
            onHoveredChanged: if (!hovered) hideTimer.restart()
        }

        Card {
            id: mediaTab

            x: root.cardGap
            y: root.revealed && root.player ? root.cardGap : -height - Theme.shadowPad
            width: media.implicitWidth + root.padding * 2
            height: root.cardHeight
            radius: Math.min(Theme.radius, height / 2)

            Behavior on y {
                NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
            }

            Row {
                id: media
                anchors.centerIn: parent
                spacing: root.spacing

                // Album art, or a note when the player has none.
                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.controlSize
                    height: Theme.controlSize
                    radius: Theme.innerRadius
                    color: Theme.highlight

                    Image {
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        sourceSize: Qt.size(56, 56)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.player?.trackArtUrl
                        text: Icons.music
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: Math.min(implicitWidth, 200)
                        text: root.player?.trackTitle ?? ""
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: Math.min(implicitWidth, 200)
                        visible: text !== ""
                        text: root.player?.trackArtist ?? ""
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSmall - 2
                        elide: Text.ElideRight
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    BarButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons.previous
                        interactive: root.player?.canGoPrevious ?? false
                        onClicked: root.player.previous()
                    }

                    // Play/pause stands out as an accent circle.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.controlSize
                        height: Theme.controlSize
                        radius: width / 2
                        color: playHover.hovered ? Qt.lighter(Theme.accent, 1.15) : Theme.accent

                        HoverHandler {
                            id: playHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: root.player.togglePlaying()
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.player?.isPlaying ? Icons.pause : Icons.play
                            color: Theme.accentText
                            font.family: Theme.iconFont
                            font.pixelSize: 16
                        }
                    }

                    BarButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons.next
                        interactive: root.player?.canGoNext ?? false
                        onClicked: root.player.next()
                    }
                }
            }
        }

        EdgeShape {
            id: clockTab

            edge: "top"
            depth: root.clockDepth
            length: time.implicitWidth + Theme.padding * 2
            x: (parent.width - width) / 2
            y: root.revealed ? 0 : -height - Theme.shadowPad

            Behavior on y {
                NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.calendarOpen = !root.calendarOpen
            }

            Text {
                id: time
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.textPrimary
                font.pixelSize: Theme.fontNormal + 1
                font.weight: Font.DemiBold
            }
        }

        Card {
            id: statusTab

            x: parent.width - width - root.cardGap
            y: root.revealed ? root.cardGap : -height - Theme.shadowPad
            width: status.implicitWidth + root.padding * 2
            height: root.cardHeight
            radius: Math.min(Theme.radius, height / 2)

            Behavior on y {
                NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
            }

            Row {
                id: status
                anchors.centerIn: parent
                spacing: 6

                BarButton {
                    id: dnd
                    visible: Notifications.dnd
                    icon: Icons.bellOff
                    iconColor: Theme.accent
                    hint: "Do not disturb · click to turn off"
                    onClicked: Notifications.dnd = false
                }

                BarButton {
                    id: wifi
                    icon: {
                        if (Network.wired)
                            return Icons.ethernet;
                        if (!Network.wifiEnabled || !Network.wifi)
                            return Icons.wifiOff;
                        return Icons.level(Icons.wifi, Network.signal);
                    }
                    iconColor: Network.online ? Theme.accent : Theme.textSecondary
                    interactive: false
                    hint: {
                        if (!Network.name)
                            return Network.wifiEnabled ? "Not connected" : "Wifi off";
                        const strength = Network.wifi ? ` · ${Math.round(Network.signal * 100)}%` : "";
                        return Network.name + strength + (Network.online ? "" : " · no internet");
                    }
                }

                BarButton {
                    id: volume
                    icon: Audio.muted || Audio.volume === 0 ? Icons.volumeOff : Icons.volumeLevel(Audio.volume)
                    iconColor: Audio.muted ? Theme.textSecondary : Theme.accent
                    label: Math.round(Audio.volume * 100) + "%"
                    labelColor: Audio.muted ? Theme.textSecondary : Theme.textPrimary
                    hint: Audio.sink?.description ?? ""
                    onClicked: Audio.toggleMute()
                    onScrolled: steps => Audio.setVolume(Audio.volume + steps * 0.05)
                }

                BarButton {
                    id: battery
                    readonly property bool low: !Battery.pluggedIn && Battery.percentage <= 0.15

                    visible: Battery.available
                    icon: Battery.pluggedIn ? Icons.batteryCharging : Icons.level(Icons.battery, Battery.percentage)
                    iconColor: low ? Theme.error : Theme.accent
                    label: Math.round(Battery.percentage * 100) + "%"
                    labelColor: low ? Theme.error : Theme.textPrimary
                    interactive: false
                    hint: {
                        if (!Battery.timeLeft)
                            return Battery.pluggedIn ? "Plugged in" : "";
                        return Battery.pluggedIn ? `${Battery.timeLeft} until full` : `${Battery.timeLeft} left`;
                    }
                }
            }
        }

        Calendar {
            id: calendar
            x: (parent.width - width) / 2
            y: root.clockDepth + root.popupGap
            visible: root.calendarOpen
        }

        // Under the hovered item, kept on screen.
        Card {
            id: hintCard

            readonly property real anchorX: root.hinted ? root.hinted.mapToItem(content, root.hinted.width / 2, 0).x : 0

            x: Math.max(root.cardGap, Math.min(parent.width - width - root.cardGap, anchorX - width / 2))
            y: root.clockDepth + root.popupGap
            width: hintText.implicitWidth + Theme.padding * 2
            height: hintText.implicitHeight + 14
            radius: Theme.innerRadius
            visible: root.hinted !== null && !root.calendarOpen

            Text {
                id: hintText
                anchors.centerIn: parent
                text: root.hinted?.hint ?? ""
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
