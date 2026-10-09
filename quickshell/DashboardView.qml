import Quickshell
import QtQuick
import "icons.js" as Icons

// Dashboard, shown when the bar's clock tab expands. Time and date on top,
// with two tabs:
//   Overview: calendar, quick toggles, shortcuts to panels and capture tools
//   System:   SystemView (CPU, memory, GPU, disk, processes)
// Toggles and shortcuts are lists below; add an entry to add one.
Column {
    id: root

    // Where shortcut panels open.
    property ShellScreen screen: null
    // On screen; the System tab only measures while it is.
    property bool active: true

    readonly property var tabs: ["Overview", "System"]
    property string tab: tabs[0]

    // A shortcut ran; the bar closes the dashboard so it's out of the way.
    signal acted()

    readonly property bool micMuted: Audio.source?.audio?.muted ?? false

    // text, detail (second line), glyph, on, toggle()
    readonly property var toggles: [
        {
            text: "Wi-Fi",
            detail: Network.wifiEnabled ? (Network.name || "Not connected") : "Off",
            glyph: Network.wifiEnabled ? Icons.level(Icons.wifi, Network.signal) : Icons.wifiOff,
            on: Network.wifiEnabled,
            toggle: () => Network.toggleWifi(),
        },
        {
            text: "Do not disturb",
            detail: Notifications.dnd ? "On" : "Off",
            glyph: Notifications.dnd ? Icons.bellOff : Icons.bell,
            on: Notifications.dnd,
            toggle: () => Notifications.dnd = !Notifications.dnd,
        },
        {
            text: "Microphone",
            detail: micMuted ? "Muted" : "On",
            glyph: micMuted ? Icons.micOff : Icons.mic,
            on: !micMuted,
            toggle: () => Audio.toggleNodeMute(Audio.source),
        },
        {
            text: "Dark mode",
            detail: Settings.mode === "dark" ? "On" : "Off",
            glyph: Settings.mode === "dark" ? Icons.moon : Icons.sun,
            on: Settings.mode === "dark",
            toggle: () => Settings.set("mode", Settings.mode === "dark" ? "light" : "dark"),
        },
    ]

    // text, glyph, run()
    readonly property var shortcuts: [
        { text: "Screenshot", glyph: Icons.region, run: () => Popups.open("screenshot", root.screen) },
        { text: "Record", glyph: Icons.record, run: () => Popups.open("record", root.screen) },
        { text: "Color", glyph: Icons.colorPicker, run: () => Recorder.pickColor() },
        { text: "Clipboard", glyph: Icons.clipboard, run: () => Popups.open("clipboard", root.screen) },
        { text: "Wallpaper", glyph: Icons.image, run: () => Popups.open("wallpapers", root.screen) },
        { text: "Shuffle", glyph: Icons.shuffle, run: () => Wallpaper.randomize() },
        { text: "Settings", glyph: Icons.settings, run: () => Popups.open("settings", root.screen) },
        { text: "Power", glyph: Icons.power, run: () => Popups.open("power", root.screen) },
    ]

    spacing: 16

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Time and date, tabs on the right.
    Item {
        width: parent.width
        height: heading.implicitHeight

        Column {
            id: heading

            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.textPrimary
                font.pixelSize: 40
                font.weight: Font.Bold
                font.letterSpacing: -1
            }

            Text {
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: Theme.accent
                font.pixelSize: Theme.fontNormal
                font.weight: Font.DemiBold
            }
        }

        // Segmented control: the current tab is a filled pill.
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: tabRow.implicitWidth + 8
            height: 36
            radius: height / 2
            color: Theme.tile

            Row {
                id: tabRow
                anchors.centerIn: parent

                Repeater {
                    model: root.tabs

                    Rectangle {
                        id: tabButton

                        required property string modelData
                        readonly property bool current: root.tab === modelData

                        width: tabText.implicitWidth + 28
                        height: 28
                        radius: height / 2
                        color: tabHover.hovered ? Theme.tileHover : "transparent"
                        gradient: current ? Theme.accentGradient : null

                        Glow {
                            on: tabButton.current
                        }

                        HoverHandler {
                            id: tabHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: root.tab = tabButton.modelData
                        }

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: tabButton.modelData
                            color: tabButton.current ? Theme.accentText : Theme.textPrimary
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }

    // Overview: calendar on the left; toggles and shortcuts on the right.
    Row {
        width: parent.width
        spacing: 12
        visible: root.tab === "Overview"

        Group {
            id: calendarGroup
            height: rightColumn.height

            Calendar {
                cellSize: 30
                fillHeight: calendarGroup.height - 28
            }
        }

        Column {
            id: rightColumn
            width: parent.width - calendarGroup.width - parent.spacing
            spacing: 12

            Group {
                width: parent.width
                title: "Quick settings"

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 8

                    Repeater {
                        model: root.toggles

                        ToggleTile {
                            required property var modelData
                            width: (parent.width - parent.spacing) / 2
                            entry: modelData
                        }
                    }
                }
            }

            Group {
                width: parent.width
                title: "Shortcuts"

                Grid {
                    width: parent.width
                    columns: 4
                    spacing: 4

                    Repeater {
                        model: root.shortcuts

                        ShortcutTile {
                            required property var modelData
                            width: (parent.width - parent.spacing * 3) / 4
                            entry: modelData
                            onRan: root.acted()
                        }
                    }
                }
            }
        }
    }

    SystemView {
        width: parent.width
        visible: root.tab === "System"
        active: root.active && visible
    }

    // A tinted block with an optional title; content stacks inside.
    component Group: Rectangle {
        id: group

        property string title: ""
        default property alias content: body.data

        implicitWidth: body.implicitWidth + 28
        implicitHeight: column.implicitHeight + 28
        radius: Theme.innerRadius + 6
        color: Theme.tile

        Column {
            id: column
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 10

            SectionTitle {
                visible: group.title !== ""
                text: group.title
            }

            Item {
                id: body
                width: parent.width
                implicitWidth: childrenRect.width
                height: childrenRect.height
            }
        }
    }

    // On: filled with the accent color. Click to flip.
    component ToggleTile: Rectangle {
        id: tile

        property var entry: ({})

        height: 54
        radius: Theme.innerRadius + 4
        color: hover.hovered ? Theme.tileHover : Theme.tile
        gradient: entry.on ? Theme.accentGradient : null

        Glow {
            on: tile.entry.on ?? false
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: tile.entry.toggle()
        }

        Row {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 20
            spacing: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: width / 2
                color: tile.entry.on ? Qt.alpha(Theme.accentText, 0.15) : Theme.tile

                Text {
                    anchors.centerIn: parent
                    text: tile.entry.glyph ?? ""
                    color: tile.entry.on ? Theme.accentText : Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 15
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 42

                Text {
                    width: parent.width
                    text: tile.entry.text ?? ""
                    color: tile.entry.on ? Theme.accentText : Theme.textPrimary
                    font.pixelSize: Theme.fontSmall - 1
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: tile.entry.detail ?? ""
                    color: tile.entry.on ? Qt.alpha(Theme.accentText, 0.75) : Theme.textSecondary
                    font.pixelSize: Theme.fontSmall - 3
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Glyph over a name; click to run.
    component ShortcutTile: Rectangle {
        id: shortcut

        property var entry: ({})

        signal ran()

        height: 60
        radius: Theme.innerRadius + 4
        color: hover.hovered ? Theme.tileHover : "transparent"
        scale: tap.pressed ? 0.94 : 1

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            id: tap
            onTapped: {
                shortcut.ran();
                shortcut.entry.run();
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: shortcut.entry.glyph ?? ""
                color: hover.hovered ? Theme.accent : Theme.textPrimary
                font.family: Theme.iconFont
                font.pixelSize: 20
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: shortcut.entry.text ?? ""
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall - 2
            }
        }
    }
}
