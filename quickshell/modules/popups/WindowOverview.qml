import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components

// Quick glance at every workspace in use: small live desktops in centered,
// evenly filled rows over the blurred wallpaper, with the apps open on each underneath. Only
// for looking: hold Super+Tab to peek and let go to dismiss. Opened another
// way it stays until Esc, a click, or Super+Tab again.
//   qs ipc call windows toggle
Popup {
    id: root

    readonly property var windows: Hyprland.toplevels.values
        .filter(toplevel => toplevel.wayland && toplevel.lastIpcObject.mapped && !toplevel.lastIpcObject.hidden)
    // Numbered ones in order, the focused one even if empty, then special ones.
    readonly property var workspaces: {
        const used = Hyprland.workspaces.values.filter(workspace => windowsOn(workspace).length > 0 || workspace.focused);
        const numbered = used.filter(workspace => workspace.id > 0).sort((a, b) => a.id - b.id);
        return numbered.concat(used.filter(workspace => workspace.id < 0));
    }

    // Opened by Super+Tab: letting go of Super closes it.
    property bool holding: false

    // Mini desktops: the monitor's shape, never narrower than minCardWidth.
    // As many fit in a row as can; past that they wrap into rows filled
    // evenly (7 -> 4 + 3), each centered.
    readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
    readonly property real monitorWidth: monitor ? monitor.width / monitor.scale : 1600
    readonly property real monitorHeight: monitor ? monitor.height / monitor.scale : 1000
    readonly property real aspect: monitorWidth / monitorHeight
    readonly property int count: Math.max(1, workspaces.length)
    readonly property int fitPerRow: Math.max(1, Math.floor((width * 0.9 + gap) / (minCardWidth + gap)))
    readonly property int rowCount: Math.ceil(count / fitPerRow)
    readonly property int perRow: Math.ceil(count / rowCount)
    // Widest that fits across, and (with the icons under each) down.
    readonly property real cardWidth: Math.min(maxCardWidth,
        (width * 0.9 - (perRow - 1) * gap) / perRow,
        ((height * 0.8 - 60 - (rowCount - 1) * gap) / rowCount - 34) * aspect)
    readonly property real cardHeight: cardWidth / aspect
    readonly property real cardScale: cardWidth / monitorWidth
    // The workspaces split into rows.
    readonly property var rows: {
        const rows = [];
        for (let i = 0; i < workspaces.length; i += perRow)
            rows.push(workspaces.slice(i, i + perRow));
        return rows;
    }
    property int minCardWidth: 280
    property int maxCardWidth: 380
    property int gap: 28
    property int stagger: 45 // ms between cards rising in

    function windowsOn(workspace) {
        return windows.filter(toplevel => toplevel.workspace === workspace);
    }

    function label(workspace) {
        return workspace.name.replace(/^special:/, "");
    }

    function iconOf(toplevel) {
        const windowClass = toplevel.lastIpcObject.class ?? "";
        return Quickshell.iconPath(DesktopEntries.heuristicLookup(windowClass)?.icon ?? windowClass, true);
    }

    name: "windows"
    surface: null // a click anywhere closes it

    onOpenChanged: {
        if (!open)
            return;
        holding = Popups.request === "hold";
        // Positions are only read on refresh.
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    IpcHandler {
        target: "windows"

        function toggle(): void {
            if (root.open)
                Popups.close();
            else
                Popups.open("windows", null, "hold");
        }
    }

    // The wallpaper, blurred and dimmed.
    Item {
        anchors.fill: parent
        opacity: root.reveal

        Image {
            id: backdrop
            anchors.fill: parent
            visible: false
            source: Wallpaper.current ? "file://" + Wallpaper.current : ""
            sourceSize: Qt.size(160, 160)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        MultiEffect {
            anchors.fill: parent
            source: backdrop
            blurEnabled: true
            blurMax: 64
            blur: 1
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            opacity: 0.6
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: root.gap
        opacity: root.reveal
        focus: true

        Keys.onReleased: event => {
            const super_ = [Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Meta].includes(event.key);
            if (super_ && root.holding && !event.isAutoRepeat) {
                event.accepted = true;
                Popups.close();
            }
        }

        // "5 windows · 3 workspaces"
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                const plural = (count, word) => `${count} ${word}${count === 1 ? "" : "s"}`;
                return `${plural(root.windows.length, "window")}  ·  ${plural(root.workspaces.length, "workspace")}`;
            }
            color: Theme.textSecondary
            font.pixelSize: Theme.fontNormal
            font.weight: Font.DemiBold
        }

        Repeater {
            // Only while open: live previews cost a capture each.
            model: root.open ? root.rows : []

            Row {
                id: row

                required property var modelData
                required property int index

                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.gap

                Repeater {
                    model: row.modelData

                    WorkspaceCard {
                        required property var modelData
                        required property int index
                        workspace: modelData
                        delay: (row.index * root.perRow + index) * root.stagger
                    }
                }
            }
        }
    }

    // A workspace in miniature, with its apps' icons under it. Rises in
    // `delay` ms after opening.
    component WorkspaceCard: Column {
        id: card

        property var workspace: null
        property int delay: 0
        readonly property var windows: root.windowsOn(workspace)
        property real rise: 0

        spacing: 12
        opacity: rise
        transform: Translate { y: (1 - card.rise) * 40 }

        Component.onCompleted: enter.start()

        SequentialAnimation {
            id: enter
            PauseAnimation { duration: card.delay }
            NumberAnimation { target: card; property: "rise"; to: 1; duration: 380; easing.type: Easing.OutCubic }
        }

        ClippingRectangle {
            width: root.cardWidth
            height: root.cardHeight
            radius: Theme.radius
            color: Theme.surface
            border.width: card.workspace.focused ? 2 : 1
            border.color: card.workspace.focused ? Theme.accent : Theme.border

            Image {
                anchors.fill: parent
                source: Wallpaper.current ? "file://" + Wallpaper.current : ""
                sourceSize.width: root.maxCardWidth
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: 0.6
            }

            Repeater {
                model: card.windows.slice().sort((a, b) => a.lastIpcObject.floating - b.lastIpcObject.floating)

                WindowTile {
                    required property var modelData
                    toplevel: modelData
                    monitor: card.workspace.monitor
                }
            }

            Text {
                anchors.centerIn: parent
                visible: card.windows.length === 0
                text: "Empty"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
            }

            // Workspace name, top left.
            Rectangle {
                x: 10
                y: 10
                width: workspaceName.implicitWidth + 16
                height: 22
                radius: 11
                color: card.workspace.focused ? Theme.accent : Qt.alpha(Theme.surface, 0.85)

                Text {
                    id: workspaceName
                    anchors.centerIn: parent
                    text: root.label(card.workspace)
                    color: card.workspace.focused ? Theme.accentText : Theme.textPrimary
                    font.pixelSize: Theme.fontSmall - 2
                    font.weight: Font.DemiBold
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Repeater {
                model: card.windows

                IconImage {
                    required property var modelData
                    implicitSize: 22
                    source: root.iconOf(modelData)
                }
            }
        }
    }

    // A window where it is on its workspace, live.
    component WindowTile: ClippingRectangle {
        id: tile

        property var toplevel: null
        property var monitor: null
        readonly property var info: toplevel.lastIpcObject

        x: (info.at[0] - (monitor?.x ?? 0)) * root.cardScale
        y: (info.at[1] - (monitor?.y ?? 0)) * root.cardScale
        width: info.size[0] * root.cardScale
        height: info.size[1] * root.cardScale
        z: info.floating ? 1 : 0
        radius: 6
        color: Theme.surface

        ScreencopyView {
            anchors.fill: parent
            captureSource: tile.toplevel.wayland
            live: true
        }
    }
}
