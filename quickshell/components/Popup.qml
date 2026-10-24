import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

// Base for the panels (wifi, audio, media, power, wallpapers, settings).
// Opens and closes through Popups.qml. The window covers the screen so a
// click outside `surface` closes it; Esc closes it too.
//
// A panel puts its card (or tab) in here and sets `surface` to it. `reveal`
// goes 0 -> 1 while opening; use it to fade or slide the card in.
// shell.qml makes most panels only while open (LazyPopup.qml), so `open`
// starts false and turns true once made: onOpenChanged runs and it animates in.
ShellWindow {
    id: root

    property Item surface: null
    property bool open: false
    property real reveal: open ? 1 : 0

    default property alias content: area.data

    Behavior on reveal {
        NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
    }

    // Stay mapped until the closing animation finishes.
    shown: open || reveal > 0

    Component.onCompleted: {
        if (Popups.screen)
            screen = Popups.screen;
        open = Qt.binding(() => Popups.current === name);
    }

    // Closed and gone from screen: LazyPopup can free it. Later, so handlers
    // still reacting to this change finish first.
    onShownChanged: {
        if (!shown)
            Qt.callLater(() => Popups.closed(name));
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        if (!open)
            return;
        if (Popups.screen)
            screen = Popups.screen;
        area.forceActiveFocus();
    }

    // Glass on/off hides and shows the window, which drops keyboard focus.
    onVisibleChanged: if (visible && open) area.forceActiveFocus()

    MouseArea {
        id: outside
        anchors.fill: parent
        onClicked: mouse => {
            const inside = root.surface && root.surface.contains(root.surface.mapFromItem(outside, mouse.x, mouse.y));
            if (!inside)
                Popups.close();
        }
    }

    // Keys from anything inside that doesn't handle them end up here.
    FocusScope {
        id: area
        anchors.fill: parent
        Keys.onEscapePressed: Popups.close()
    }
}
