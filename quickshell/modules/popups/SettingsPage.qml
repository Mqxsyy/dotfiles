import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/icons.js" as Icons

// Settings page, opened with "> settings" in the launcher or
//   qs ipc call settings toggle
// One category at a time, picked with the tabs at the top. Changes apply
// live and are saved by Settings.qml.
Popup {
    id: root

    property int cardWidth: 460

    readonly property var categories: ["Appearance", "Wallpaper", "Night light", "Lock"]
    property string category: categories[0]

    // How a new wallpaper comes in (WallpaperView.qml).
    readonly property var wallpaperTransitions: [
        { value: "grow", text: "Grow from center" },
        { value: "swipe", text: "Swipe from corner" },
    ]

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

    // "07:00"
    function hour(value) {
        return String(value).padStart(2, "0") + ":00";
    }

    name: "settings"
    surface: card

    Card {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: root.cardWidth
        height: content.implicitHeight + Theme.padding * 2 + 8
        opacity: root.reveal

        Column {
            id: content

            x: Theme.padding + 4
            y: Theme.padding + 4
            width: parent.width - x * 2
            spacing: 18

            // Title, categories on the right.
            Item {
                width: parent.width
                height: tabs.implicitHeight

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Settings"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontLarge
                    font.weight: Font.DemiBold
                }

                Tabs {
                    id: tabs
                    anchors.right: parent.right
                    tabs: root.categories
                    current: root.category
                    onPicked: tab => root.category = tab
                }
            }

            Column {
                width: parent.width
                visible: root.category === "Appearance"
                spacing: 16

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
            }

            Column {
                width: parent.width
                visible: root.category === "Wallpaper"
                spacing: 16

                Row {
                    spacing: 6

                    PanelButton {
                        icon: Icons.image
                        label: "Choose wallpaper"
                        onClicked: Popups.open("wallpapers")
                    }

                    PanelButton {
                        icon: Icons.shuffle
                        label: "Random"
                        onClicked: Wallpaper.randomize()
                    }
                }

                SettingChoice {
                    width: parent.width
                    label: "Transition"
                    options: root.wallpaperTransitions
                    value: Settings.wallpaperTransition
                    onPicked: value => Settings.set("wallpaperTransition", value)
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
            }

            Column {
                width: parent.width
                visible: root.category === "Night light"
                spacing: 16

                SettingToggle {
                    width: parent.width
                    label: "Warm colors"
                    description: "Easier on the eyes at night"
                    checked: Settings.nightLight
                    onToggled: checked => Settings.set("nightLight", checked)
                }

                SettingSlider {
                    width: parent.width
                    label: "Warmth"
                    valueText: Settings.nightLightTemperature + "K"
                    from: 6000
                    to: 2500
                    stepSize: 100
                    value: Settings.nightLightTemperature
                    onMoved: value => Settings.set("nightLightTemperature", value)
                }

                SettingToggle {
                    width: parent.width
                    label: "Automatic"
                    description: `On from ${root.hour(Settings.nightLightFrom)} to ${root.hour(Settings.nightLightTo)}`
                    checked: Settings.nightLightAuto
                    onToggled: checked => Settings.set("nightLightAuto", checked)
                }

                SettingSlider {
                    width: parent.width
                    visible: Settings.nightLightAuto
                    label: "Turns on"
                    valueText: root.hour(Settings.nightLightFrom)
                    from: 0
                    to: 23
                    stepSize: 1
                    value: Settings.nightLightFrom
                    onMoved: value => Settings.set("nightLightFrom", value)
                }

                SettingSlider {
                    width: parent.width
                    visible: Settings.nightLightAuto
                    label: "Turns off"
                    valueText: root.hour(Settings.nightLightTo)
                    from: 0
                    to: 23
                    stepSize: 1
                    value: Settings.nightLightTo
                    onMoved: value => Settings.set("nightLightTo", value)
                }
            }

            Column {
                width: parent.width
                visible: root.category === "Lock"
                spacing: 16

                SettingSlider {
                    width: parent.width
                    label: "Lock when idle"
                    valueText: Settings.lockAfter > 0 ? `After ${Settings.lockAfter} min` : "Never"
                    from: 0
                    to: 30
                    stepSize: 1
                    value: Settings.lockAfter
                    onMoved: value => Settings.set("lockAfter", value)
                }
            }
        }
    }
}
