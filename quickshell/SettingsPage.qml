import Quickshell
import Quickshell.Wayland
import QtQuick
import "icons.js" as Icons

// Settings page, opened with "> settings" in the launcher or
//   qs ipc call settings toggle
// Changes apply live and are saved by Settings.qml. Esc or clicking outside closes it.
ShellWindow {
    id: root

    property int cardWidth: 460

    // matugen --type values.
    readonly property var schemes: [
        { value: "scheme-tonal-spot", text: "Tonal spot" },
        { value: "scheme-content", text: "Content" },
        { value: "scheme-expressive", text: "Expressive" },
        { value: "scheme-fidelity", text: "Fidelity" },
        { value: "scheme-fruit-salad", text: "Fruit salad" },
        { value: "scheme-monochrome", text: "Monochrome" },
        { value: "scheme-neutral", text: "Neutral" },
        { value: "scheme-rainbow", text: "Rainbow" },
        { value: "scheme-vibrant", text: "Vibrant" },
    ]

    // matugen --mode values.
    readonly property var modes: [
        { value: "dark", text: "Dark" },
        { value: "light", text: "Light" },
    ]

    // matugen --prefer values: which wallpaper color the scheme is built from.
    readonly property var preferences: [
        { value: "saturation", text: "Most saturated" },
        { value: "less-saturation", text: "Least saturated" },
        { value: "darkness", text: "Darkest" },
        { value: "lightness", text: "Lightest" },
        { value: "value", text: "Brightest" },
    ]

    name: "settings"
    shown: Settings.pageOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: if (visible) keys.forceActiveFocus()

    Connections {
        target: Settings

        // Open on the focused screen.
        function onPageOpenChanged() {
            if (Settings.pageOpen && FocusedScreen.screen)
                root.screen = FocusedScreen.screen;
        }
    }

    Item {
        id: keys
        Keys.onEscapePressed: Settings.pageOpen = false
    }

    // Clicking anywhere outside the card closes the page.
    MouseArea {
        anchors.fill: parent
        onClicked: Settings.pageOpen = false
    }

    Card {
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: root.cardWidth
        height: content.implicitHeight + Theme.padding * 2 + 8

        // Swallow clicks on the card itself so they don't reach the close area behind it.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content

            x: Theme.padding + 4
            y: Theme.padding + 4
            width: parent.width - x * 2
            spacing: 16

            Text {
                text: "Settings"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontLarge
                font.weight: Font.DemiBold
            }

            SectionTitle {
                text: "Appearance"
            }

            SettingSlider {
                width: parent.width
                label: "Roundness"
                valueText: Settings.radius + "px"
                from: 0
                to: 24
                stepSize: 1
                value: Settings.radius
                onMoved: value => Settings.set("radius", value)
            }

            SettingSlider {
                width: parent.width
                label: "Opacity"
                valueText: Math.round(Settings.surfaceOpacity * 100) + "%"
                from: 0.2
                to: 1
                stepSize: 0.01
                value: Settings.surfaceOpacity
                onMoved: value => Settings.set("surfaceOpacity", value)
            }

            SettingToggle {
                width: parent.width
                label: "Glass"
                description: "Blur what's behind see-through surfaces"
                checked: Settings.glass
                onToggled: checked => Settings.set("glass", checked)
            }

            SectionTitle {
                text: Wallpaper.running ? "Colors · applying…" : "Colors"
            }

            SettingChoice {
                width: parent.width
                label: "Scheme"
                options: root.schemes
                value: Settings.scheme
                onPicked: value => Settings.set("scheme", value)
            }

            SettingChoice {
                width: parent.width
                label: "Mode"
                options: root.modes
                value: Settings.mode
                onPicked: value => Settings.set("mode", value)
            }

            SettingSlider {
                width: parent.width
                label: "Contrast"
                valueText: Settings.contrast.toFixed(1)
                from: -1
                to: 1
                stepSize: 0.1
                value: Settings.contrast
                onMoved: value => Settings.set("contrast", value)
            }

            SettingChoice {
                width: parent.width
                label: "Base color"
                options: root.preferences
                value: Settings.prefer
                onPicked: value => Settings.set("prefer", value)
            }

            BarButton {
                icon: Icons.refresh
                iconColor: Theme.accent
                label: "New wallpaper"
                onClicked: Wallpaper.randomize()
            }
        }
    }

    component SectionTitle: Text {
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall - 1
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }
}
