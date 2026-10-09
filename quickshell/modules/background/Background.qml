import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

// The wallpaper, behind every window, one per screen (see shell.qml).
// Shows Wallpaper.current; a new one comes in with the "Wallpaper
// transition" picked on the settings page (see WallpaperView.qml).
PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qs-wallpaper"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WallpaperView {
        anchors.fill: parent
        source: Wallpaper.current
        transition: Settings.wallpaperTransition
        pixelRatio: root.modelData.devicePixelRatio
    }
}
