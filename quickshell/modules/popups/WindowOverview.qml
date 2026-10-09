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

// Every workspace as a small live desktop over the blurred wallpaper.
// Super+Tab opens it and steps through windows, most recent first; arrows
// and Tab too. Enter or a click goes to a window, a click on a workspace
// goes there, number keys pick a workspace. Drag a window onto another
// workspace (or "+", a new one) to move it; middle click closes it.
//   qs ipc call windows next | previous
Popup {
    id: root

    // Windows, most recently used first.
    readonly property var windows: Hyprland.toplevels.values
        .filter(toplevel => toplevel.wayland && toplevel.lastIpcObject.mapped && !toplevel.lastIpcObject.hidden)
        .sort((a, b) => a.lastIpcObject.focusHistoryID - b.lastIpcObject.focusHistoryID)
    // Numbered ones in order, the focused one even if empty, then special ones.
    readonly property var workspaces: {
        const used = Hyprland.workspaces.values.filter(workspace => workspace.toplevels.values.length > 0 || workspace.focused);
        const numbered = used.filter(workspace => workspace.id > 0).sort((a, b) => a.id - b.id);
        return numbered.concat(used.filter(workspace => workspace.id < 0));
    }
    readonly property int newWorkspace: Math.max(0, ...workspaces.map(workspace => workspace.id)) + 1

    property int selected: 0
    // Picked by hand since opening; until then it follows the list order.
    property bool moved: false
    readonly property var current: windows[selected] ?? null
    property var dragging: null

    // Mini desktops: the monitor's shape, at most `cardWidth` wide.
    readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
    readonly property real monitorWidth: monitor ? monitor.width / monitor.scale : 1600
    readonly property real monitorHeight: monitor ? monitor.height / monitor.scale : 1000
    readonly property int count: workspaces.length + 1
    readonly property int columns: Math.min(count, 3)
    readonly property real cardWidth: Math.min(460, (width * 0.86 - (columns - 1) * gap) / columns)
    readonly property real cardHeight: cardWidth * monitorHeight / monitorWidth
    readonly property real cardScale: cardWidth / monitorWidth
    property int gap: 24

    function step(by) {
        if (windows.length === 0)
            return;
        moved = true;
        selected = (selected + by + windows.length) % windows.length;
    }

    function goToWindow(toplevel) {
        Popups.close();
        toplevel.wayland.activate();
    }

    function goToWorkspace(id) {
        Popups.close();
        if (id < 0)
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${workspaceLabel(id)}")`);
        else
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    function moveWindow(toplevel, id) {
        const workspace = id < 0 ? `"special:${workspaceLabel(id)}"` : id;
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${workspace}, follow = false, window = "address:${toplevel.lastIpcObject.address}" })`);
        Hyprland.refreshToplevels();
    }

    function workspaceLabel(id) {
        const workspace = workspaces.find(workspace => workspace.id === id);
        return (workspace?.name ?? String(id)).replace(/^special:/, "");
    }

    name: "windows"
    surface: grid

    onOpenChanged: {
        if (!open)
            return;
        moved = false;
        selected = Math.min(1, windows.length - 1);
        // Positions and focus order are only read on refresh.
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    onWindowsChanged: {
        if (!moved)
            selected = Math.max(0, Math.min(1, windows.length - 1));
    }

    IpcHandler {
        target: "windows"

        function next(): void {
            if (root.open)
                root.step(1);
            else
                Popups.open("windows");
        }

        function previous(): void {
            if (root.open)
                root.step(-1);
            else
                Popups.open("windows");
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
            opacity: 0.55
        }
    }

    Flow {
        id: grid

        anchors.centerIn: parent
        width: root.columns * root.cardWidth + (root.columns - 1) * root.gap
        spacing: root.gap
        opacity: root.reveal
        scale: 0.92 + 0.08 * root.reveal
        focus: true

        Keys.onPressed: event => {
            const keys = {
                [Qt.Key_Right]: () => root.step(1),
                [Qt.Key_Left]: () => root.step(-1),
                [Qt.Key_Tab]: () => root.step(1),
                [Qt.Key_Backtab]: () => root.step(-1),
                [Qt.Key_Return]: () => root.current && root.goToWindow(root.current),
                [Qt.Key_Enter]: () => root.current && root.goToWindow(root.current),
            };
            const digit = event.key - Qt.Key_0;
            if (keys[event.key])
                keys[event.key]();
            else if (digit >= 1 && digit <= 9)
                root.goToWorkspace(digit);
            else
                return;
            event.accepted = true;
        }

        Repeater {
            // Only while open: live previews cost a capture each.
            model: root.open ? root.workspaces : []

            WorkspaceCard {
                required property var modelData
                workspace: modelData
            }
        }

        WorkspaceCard {
            visible: root.open
            workspace: null
        }
    }

    // The selected (or hovered) window's title, under the workspaces.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: grid.y + grid.height + 28
        width: Math.min(implicitWidth, parent.width * 0.6)
        opacity: root.reveal
        text: root.current ? `${root.current.title}  ·  ${root.workspaceLabel(root.current.workspace?.id ?? 0)}` : ""
        color: Theme.textPrimary
        font.pixelSize: Theme.fontNormal
        font.weight: Font.DemiBold
        elide: Text.ElideMiddle
    }

    // Follows the pointer while a window is dragged to another workspace.
    ClippingRectangle {
        id: ghost

        width: root.dragging ? root.dragging.lastIpcObject.size[0] * root.cardScale * 0.9 : 0
        height: root.dragging ? root.dragging.lastIpcObject.size[1] * root.cardScale * 0.9 : 0
        visible: root.dragging !== null
        radius: 8
        opacity: 0.9
        border.color: Theme.accent
        border.width: 2
        Drag.active: visible
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        ScreencopyView {
            anchors.fill: parent
            captureSource: root.dragging?.wayland ?? null
            live: true
        }
    }

    // A workspace in miniature; `workspace` null is "+", a new workspace.
    component WorkspaceCard: ClippingRectangle {
        id: card

        property var workspace: null
        readonly property int workspaceId: workspace ? workspace.id : root.newWorkspace
        readonly property bool focused: workspace?.focused ?? false
        readonly property bool dropping: drop.containsDrag

        width: root.cardWidth
        height: root.cardHeight
        radius: Theme.radius
        color: Theme.surface
        border.width: focused || dropping ? 2 : 1
        border.color: focused || dropping ? Theme.accent : Theme.border

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        Image {
            anchors.fill: parent
            visible: card.workspace !== null
            source: Wallpaper.current ? "file://" + Wallpaper.current : ""
            sourceSize.width: 460
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0.7
        }

        // New workspace: a plus.
        Text {
            anchors.centerIn: parent
            visible: card.workspace === null
            text: "+"
            color: card.dropping ? Theme.accent : Theme.textSecondary
            font.pixelSize: 40
            font.weight: Font.Light
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        // Not when the click was on a window (it handles that itself).
        TapHandler {
            onTapped: eventPoint => {
                const target = card.childAt(eventPoint.position.x, eventPoint.position.y);
                if (!target?.toplevel)
                    root.goToWorkspace(card.workspaceId);
            }
        }

        DropArea {
            id: drop
            anchors.fill: parent
            onDropped: {
                if (root.dragging && root.dragging.workspace !== card.workspace)
                    root.moveWindow(root.dragging, card.workspaceId);
            }
        }

        Repeater {
            model: card.workspace
                ? root.windows.filter(toplevel => toplevel.workspace === card.workspace)
                    .sort((a, b) => a.lastIpcObject.floating - b.lastIpcObject.floating)
                : []

            WindowTile {
                required property var modelData
                toplevel: modelData
                monitor: card.workspace.monitor
            }
        }

        // Workspace name, top left.
        Rectangle {
            x: 10
            y: 10
            width: label.implicitWidth + 16
            height: 22
            radius: 11
            visible: card.workspace !== null
            color: card.focused ? Theme.accent : Qt.alpha(Theme.surface, 0.8)

            Text {
                id: label
                anchors.centerIn: parent
                text: root.workspaceLabel(card.workspaceId)
                color: card.focused ? Theme.accentText : Theme.textPrimary
                font.pixelSize: Theme.fontSmall - 2
                font.weight: Font.DemiBold
            }
        }
    }

    // A window where it is on its workspace, live.
    component WindowTile: Item {
        id: tile

        property var toplevel: null
        property var monitor: null
        property real radius: 6
        readonly property var info: toplevel.lastIpcObject
        readonly property bool selected: root.current === toplevel
        readonly property real originX: monitor?.x ?? 0
        readonly property real originY: monitor?.y ?? 0

        x: (info.at[0] - originX) * root.cardScale
        y: (info.at[1] - originY) * root.cardScale
        width: info.size[0] * root.cardScale
        height: info.size[1] * root.cardScale
        z: info.floating ? 1 : 0
        scale: hover.hovered && !root.dragging ? 1.03 : 1
        opacity: root.dragging === toplevel ? 0.3 : 1

        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered && !root.dragging) {
                    root.moved = true;
                    root.selected = root.windows.indexOf(tile.toplevel);
                }
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: root.goToWindow(tile.toplevel)
        }

        TapHandler {
            acceptedButtons: Qt.MiddleButton
            onTapped: tile.toplevel.wayland.close()
        }

        DragHandler {
            target: null
            onActiveChanged: {
                if (active) {
                    root.dragging = tile.toplevel;
                } else {
                    ghost.Drag.drop();
                    root.dragging = null;
                }
            }
            onCentroidChanged: {
                if (!active)
                    return;
                ghost.x = centroid.scenePosition.x - ghost.width / 2;
                ghost.y = centroid.scenePosition.y - ghost.height / 2;
            }
        }

        Glow {
            on: tile.selected
        }

        ClippingRectangle {
            anchors.fill: parent
            radius: tile.radius
            color: Theme.surface
            border.width: tile.selected ? 2 : 0
            border.color: Theme.accent

            ScreencopyView {
                anchors.fill: parent
                captureSource: tile.toplevel.wayland
                live: true
            }
        }

        // App icon, bottom center.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -8
            width: 26
            height: 26
            radius: 13
            color: Theme.surface
            border.color: tile.selected ? Theme.accent : Theme.border

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(tile.info.class ?? "")?.icon ?? tile.info.class ?? "", true)
            }
        }
    }
}
