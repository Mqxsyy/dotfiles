import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "icons.js" as Icons

// Top bar: slides down when the pointer reaches the top center of the
// screen, and stays until the pointer leaves the bar (its strip along the
// top, or an expanded card).
// One per screen (see shell.qml). Its three parts grow into panels while
// hovered:
//   top-left:  now playing card (only while there is a player)  -> MediaView
//   center:    clock card                                         -> DashboardView
//   top-right: status card: notifications, wifi, volume, brightness,
//              battery, power. Hover the bell -> NotificationsView, wifi ->
//              WifiView, volume -> AudioView, brightness -> BrightnessView;
//              click the bell for do not disturb, scroll volume or
//              brightness to change it, click volume to mute; click power
//              for the power menu
// While recording, RecordingCard.qml shows the time under the clock.
// The bar stays while the pointer is on it, a part is expanded, a button is
// held (dragging a slider) or a password is being typed. Panels it opens
// (power menu, settings, ...) don't keep it out.
// A part can also open without the pointer, on the focused screen:
//   a launcher command (BarLayout.open: "> audio", "> wifi", ...): the bar
//     shows with that part expanded, until the pointer has been in and out
//     of it, or `openDuration` passes without it coming
//   a media key: the now playing card alone, for `peekDuration`
ShellWindow {
    id: root

    required property ShellScreen modelData

    // Spacing rule: every control is Theme.controlSize, centered in a
    // cardHeight card, `padding` from its sides.
    property int cardHeight: 36
    property int cardGap: Theme.gap // floating cards' distance from the screen edges
    property int spacing: 12        // between items inside a card
    property int padding: 10        // card side to its first/last control
    readonly property int barBottom: cardGap + cardHeight
    property int revealWidth: 320   // area at the top center that reveals the bar
    property int cornerGap: 50      // the shown bar's strip leaves the corners to apps
    property int popupGap: 8        // space between the bar and a hint under it

    // Expanded sizes.
    property int mediaWidth: 440
    property int statusWidth: 380
    property int dashboardWidth: 660
    property int panelRoom: 620     // tallest a part grows; the window is this tall

    property int hideDelay: 400
    property int openDuration: 5000
    property int peekDuration: 1500
    property int openDelay: 80      // hover this long before a part expands
    property int closeDelay: 250

    readonly property MprisPlayer player: Media.player

    // The part the pointer is on: "media", "dashboard", "notifications",
    // "wifi", "audio", "brightness" or "".
    readonly property var statusParts: ["notifications", "wifi", "audio", "brightness"]
    readonly property string hoverTarget: {
        if (mediaHover.hovered)
            return "media";
        if (clockHover.hovered)
            return "dashboard";
        if (statusHover.hovered)
            return statusPick;
        return "";
    }
    // The last status icon with a panel the pointer was on.
    property string statusPick: ""
    // A dashboard shortcut ran: stay closed until the pointer moves to another part.
    property bool suppressed: false
    // The part opened without the pointer (see the top), and whether it shows
    // without the rest of the bar.
    property string opened: ""
    property bool openedAlone: false
    // The pointer picks over `opened`.
    readonly property string wanted: opened !== "" && hoverTarget === "" ? opened : suppressed ? "" : hoverTarget

    // The expanded part, following `wanted` after a short delay.
    property string expanded: ""
    // The last status panel shown; stays while the card shrinks back.
    property string statusShown: "wifi"

    // Holding a button, typing or picking a screenshot region keeps
    // everything as it is.
    readonly property bool busy: press.active || wifiView.typing || Recorder.shooting
    readonly property bool revealed: hover.hovered || hideTimer.running || (expanded !== "" && !openedAlone) || busy

    // The hovered status item, if it has a hint to show.
    readonly property BarButton hinted: [battery, power].find(item => item.visible && item.hovered && item.hint) ?? null

    // Bottom of the status card on screen, for toasts to sit under.
    readonly property real rightBottom: Math.max(0, statusIsland.y + statusIsland.height)

    // Tell windows placed around the bar (toasts) where it is.
    readonly property var layout: ({ rightBottom: rightBottom })

    onLayoutChanged: BarLayout.report(modelData.name, layout)
    Component.onCompleted: BarLayout.report(modelData.name, layout)

    onHoverTargetChanged: suppressed = false

    onWantedChanged: {
        if (wanted === "") {
            openTimer.stop();
            closeTimer.restart();
        } else if (expanded !== "") {
            closeTimer.stop();
            expanded = wanted; // already open: switch right away
        } else {
            closeTimer.stop();
            openTimer.restart();
        }
    }

    onExpandedChanged: {
        if (statusParts.includes(expanded))
            statusShown = expanded;
    }

    name: "bar"
    screen: modelData

    // Always as tall as the biggest panel: resizing the window while hovering
    // makes the pointer leave and re-enter, which flickers. The mask keeps
    // the empty part from taking input.
    implicitHeight: cardGap + panelRoom + Theme.shadowPad

    // Keyboard only for typing a wifi password.
    WlrLayershell.keyboardFocus: expanded === "wifi" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    // Input only where the bar is or would be. Hidden: just the reveal area
    // at the top center, so the rest of the top of the screen stays
    // clickable for windows. Shown: the whole bar strip and the cards
    // (expanded ones are bigger). Hidden cards sit above the window.
    mask: Region {
        item: revealArea

        Region { item: strip }
        Region { item: mediaIsland }
        Region { item: clockIsland }
        Region { item: statusIsland }
    }

    function dismiss() {
        suppressed = true;
        expanded = "";
    }

    function open(part, duration, alone) {
        opened = part;
        openedAlone = alone;
        openedTimer.interval = duration;
        openedTimer.restart();
    }

    // Pointing here, at the top center, reveals the bar.
    Item {
        id: revealArea
        x: Math.round((parent.width - width) / 2)
        width: root.revealWidth
        height: root.barBottom
    }

    // While shown: the whole bar height across the screen (minus the
    // corners), so the bar stays until the pointer leaves it.
    Item {
        id: strip
        x: root.cornerGap
        width: root.revealed ? parent.width - root.cornerGap * 2 : 0
        height: root.barBottom
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
    }

    // Closes `opened` if the pointer never comes.
    Timer {
        id: openedTimer
        onTriggered: root.opened = ""
    }

    Connections {
        target: Media

        function onKeyPressed() {
            if (FocusedScreen.screen === root.modelData)
                root.open("media", root.peekDuration, true);
        }
    }

    Connections {
        target: BarLayout

        function onOpenRequested(part) {
            if (FocusedScreen.screen === root.modelData)
                root.open(part, root.openDuration, false);
        }
    }

    Timer {
        id: openTimer
        interval: root.openDelay
        onTriggered: root.expanded = root.wanted
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: {
            if (root.busy)
                restart();
            else
                root.expanded = root.wanted;
        }
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
            onHoveredChanged: {
                if (hovered) {
                    openedTimer.stop(); // stays while the pointer is in
                } else {
                    hideTimer.restart();
                    root.opened = "";
                }
            }
        }

        // Active while a button is held anywhere in the bar, even when the
        // pointer is dragged outside it.
        PointHandler {
            id: press
        }

        // Now playing.
        Island {
            id: mediaIsland

            readonly property bool open: root.expanded === "media"

            x: root.cardGap
            y: (root.revealed || open) && root.player ? root.cardGap : -height - Theme.shadowPad
            width: open ? root.mediaWidth : mediaHeader.implicitWidth + root.padding * 2
            height: open ? mediaView.implicitHeight + Theme.padding * 2 : root.cardHeight
            radius: open ? Theme.radius : Math.min(Theme.radius, root.cardHeight / 2)
            glows: open

            HoverHandler {
                id: mediaHover
            }

            // Expanded: tinted from the top with the art's own color.
            Rectangle {
                anchors.fill: parent
                opacity: mediaIsland.open ? 1 : 0
                visible: opacity > 0
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(Media.artColor, 0.3) }
                    GradientStop { position: 1; color: Qt.alpha(Media.artColor, 0.04) }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.expandDuration }
                }
            }

            // Collapsed: art, track, and bars moving while it plays.
            Row {
                id: mediaHeader

                x: root.padding
                y: (root.cardHeight - height) / 2
                spacing: 10
                opacity: mediaIsland.open ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.controlSize
                    height: Theme.controlSize
                    radius: Theme.innerRadius
                    color: Theme.tile

                    ArtImage {
                        anchors.fill: parent
                        sources: Media.artSources
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: Media.artSources.length === 0
                        text: Icons.music
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: 15
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

                // Only animates while it can be seen: an animation redraws
                // the whole bar every frame, hidden or not.
                PlayingBars {
                    anchors.verticalCenter: parent.verticalCenter
                    playing: (root.player?.isPlaying ?? false) && root.revealed && !mediaIsland.open
                }
            }

            MediaView {
                id: mediaView

                x: Theme.padding
                y: Theme.padding
                width: root.mediaWidth - Theme.padding * 2
                active: mediaIsland.open
                visible: opacity > 0
                opacity: mediaIsland.open ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.expandDuration }
                }
            }
        }

        // Clock, growing into the dashboard.
        Island {
            id: clockIsland

            readonly property bool open: root.expanded === "dashboard"

            x: Math.round((parent.width - width) / 2)
            y: root.revealed ? root.cardGap : -height - Theme.shadowPad
            width: open ? root.dashboardWidth : clockRow.implicitWidth + root.padding * 2 + 8
            height: open ? dashboard.implicitHeight + Theme.padding * 2 : root.cardHeight
            radius: open ? Theme.radius : Math.min(Theme.radius, root.cardHeight / 2)
            glows: open

            HoverHandler {
                id: clockHover
            }

            Row {
                id: clockRow

                anchors.horizontalCenter: parent.horizontalCenter
                y: (root.cardHeight - height) / 2
                spacing: 10
                opacity: clockIsland.open ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                // The colon in the accent color.
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.StyledText
                    text: Qt.formatDateTime(clock.date, "HH") + `<font color="${Theme.accent}">:</font>` + Qt.formatDateTime(clock.date, "mm")
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontNormal + 1
                    font.weight: Font.Bold
                }
            }

            DashboardView {
                id: dashboard

                x: Theme.padding
                y: Theme.padding
                width: root.dashboardWidth - Theme.padding * 2
                screen: root.screen
                active: clockIsland.open
                visible: opacity > 0
                opacity: clockIsland.open ? 1 : 0
                onActed: root.dismiss()

                Behavior on opacity {
                    NumberAnimation { duration: Theme.expandDuration }
                }
            }
        }

        // Status, growing into the wifi or sound panel.
        Island {
            id: statusIsland

            readonly property bool open: root.statusParts.includes(root.expanded)

            x: parent.width - width - root.cardGap
            y: root.revealed ? root.cardGap : -height - Theme.shadowPad
            width: open ? root.statusWidth : status.implicitWidth + root.padding * 2
            height: open ? root.cardHeight + statusBody.height + Theme.padding : root.cardHeight
            radius: open ? Theme.radius : Math.min(Theme.radius, root.cardHeight / 2)
            glows: open

            HoverHandler {
                id: statusHover
                onHoveredChanged: if (!hovered) root.statusPick = ""
            }

            // Pinned to the right, so the icons stay put while the card grows.
            Row {
                id: status

                x: parent.width - width - root.padding
                y: (root.cardHeight - height) / 2
                spacing: 6

                BarButton {
                    id: bell
                    icon: Notifications.dnd ? Icons.bellOff : Icons.bell
                    iconColor: Notifications.dnd ? Theme.accent : Theme.textPrimary
                    color: root.expanded === "notifications" || hovered ? Theme.highlight : "transparent"
                    onHoveredChanged: if (hovered) root.statusPick = "notifications"
                    onClicked: Notifications.dnd = !Notifications.dnd

                    // New since the history was last looked at.
                    Rectangle {
                        x: parent.width - width - 5
                        y: 5
                        width: 7
                        height: 7
                        radius: 4
                        visible: Notifications.unread > 0
                        color: Theme.accent
                    }
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
                    iconColor: Network.online ? Theme.textPrimary : Theme.textSecondary
                    color: root.expanded === "wifi" || hovered ? Theme.highlight : "transparent"
                    onHoveredChanged: if (hovered) root.statusPick = "wifi"
                }

                BarButton {
                    id: volume
                    icon: Audio.muted || Audio.volume === 0 ? Icons.volumeOff : Icons.volumeLevel(Audio.volume)
                    iconColor: Audio.muted ? Theme.textSecondary : Theme.textPrimary
                    color: root.expanded === "audio" || hovered ? Theme.highlight : "transparent"
                    onHoveredChanged: if (hovered) root.statusPick = "audio"
                    onClicked: Audio.toggleMute()
                    onScrolled: steps => Audio.setVolume(Audio.volume + steps * 0.05)
                }

                BarButton {
                    id: brightness
                    icon: Icons.level(Icons.brightness, Brightness.value)
                    color: root.expanded === "brightness" || hovered ? Theme.highlight : "transparent"
                    onHoveredChanged: if (hovered) root.statusPick = "brightness"
                    onScrolled: steps => steps > 0 ? Brightness.up() : Brightness.down()
                }

                BarButton {
                    id: battery
                    readonly property bool low: !Battery.pluggedIn && Battery.percentage <= 0.15

                    visible: Battery.available
                    icon: Battery.pluggedIn ? Icons.batteryCharging : Icons.level(Icons.battery, Battery.percentage)
                    iconColor: low ? Theme.error : Theme.textPrimary
                    label: Math.round(Battery.percentage * 100) + "%"
                    labelColor: low ? Theme.error : Theme.textPrimary
                    hint: {
                        if (!Battery.timeLeft)
                            return Battery.pluggedIn ? "Plugged in" : "";
                        return Battery.pluggedIn ? `${Battery.timeLeft} until full` : `${Battery.timeLeft} left`;
                    }
                    interactive: false
                }

                BarButton {
                    id: power
                    icon: Icons.power
                    hint: "Power"
                    onClicked: Popups.toggle("power", root.screen)
                }
            }

            Item {
                id: statusBody

                x: Theme.padding
                y: root.cardHeight + 4
                width: root.statusWidth - Theme.padding * 2
                height: ({ notifications: notificationsView, wifi: wifiView, audio: audioView, brightness: brightnessView })[root.statusShown].implicitHeight
                visible: opacity > 0
                opacity: statusIsland.open ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.expandDuration }
                }

                NotificationsView {
                    id: notificationsView
                    width: parent.width
                    visible: root.statusShown === "notifications"
                    active: root.expanded === "notifications"
                }

                WifiView {
                    id: wifiView
                    width: parent.width
                    visible: root.statusShown === "wifi"
                    active: root.expanded === "wifi"
                }

                AudioView {
                    id: audioView
                    width: parent.width
                    visible: root.statusShown === "audio"
                }

                BrightnessView {
                    id: brightnessView
                    width: parent.width
                    visible: root.statusShown === "brightness"
                }
            }
        }

        // Under the hovered status item, kept on screen.
        Card {
            id: hintCard

            readonly property real anchorX: root.hinted ? root.hinted.mapToItem(content, root.hinted.width / 2, 0).x : 0

            x: Math.max(root.cardGap, Math.min(parent.width - width - root.cardGap, anchorX - width / 2))
            y: root.barBottom + root.popupGap
            width: hintText.implicitWidth + Theme.padding * 2
            height: hintText.implicitHeight + 14
            radius: Theme.innerRadius
            visible: root.hinted !== null && !statusIsland.open

            Text {
                id: hintText
                anchors.centerIn: parent
                text: root.hinted?.hint ?? ""
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
            }
        }
    }

    // A floating card that grows and shrinks smoothly. Children are clipped to
    // its rectangle while it animates (a plain clip: rounded clipping renders
    // everything into a texture every frame, which lags); the content's
    // padding keeps it clear of the rounded corners.
    component Island: Card {
        id: island

        default property alias content: clip.data

        Behavior on y {
            NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuint }
        }
        Behavior on height {
            NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuint }
        }
        Behavior on radius {
            NumberAnimation { duration: Theme.expandDuration }
        }

        Item {
            id: clip
            anchors.fill: parent
            clip: true
        }
    }

    // Three bars bouncing while music plays, resting low when paused.
    component PlayingBars: Row {
        id: bars

        property bool playing: false

        height: 14
        spacing: 2

        Repeater {
            model: [520, 380, 640] // a different speed per bar

            Rectangle {
                id: bar

                required property int modelData

                anchors.bottom: parent.bottom
                width: 3
                height: 4
                radius: 1.5
                color: Theme.accent

                SequentialAnimation on height {
                    running: bars.playing
                    loops: Animation.Infinite
                    NumberAnimation { to: 14; duration: bar.modelData; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 4; duration: bar.modelData; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
