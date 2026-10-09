import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/icons.js" as Icons

// Settings page, opened with "> settings" in the launcher or
//   qs ipc call settings toggle
// Categories on the left (Up/Down switch them), the picked one on the right.
// Changes apply live and are saved by Settings.qml.
Popup {
    id: root

    property int sidebarWidth: 180
    property int pageWidth: 420
    property int itemHeight: 38

    readonly property var categories: [
        { name: "Appearance", glyph: Icons.palette },
        { name: "Wallpaper", glyph: Icons.image },
        { name: "Night light", glyph: Icons.nightLight },
        { name: "Screenshots", glyph: Icons.screenshot },
        { name: "Lock", glyph: Icons.lock },
    ]
    property int selected: 0
    readonly property string category: categories[selected].name

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

        readonly property real pageHeight: Math.max(...pages.children.map(page => page.implicitHeight))

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: root.sidebarWidth + root.pageWidth + Theme.padding * 3
        height: Math.max(sidebar.implicitHeight, heading.height + 18 + pageHeight) + Theme.padding * 2
        opacity: root.reveal
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                const step = event.key === Qt.Key_Down ? 1 : -1;
                root.selected = (root.selected + step + root.categories.length) % root.categories.length;
                event.accepted = true;
            }
        }

        Column {
            id: sidebar

            x: Theme.padding
            y: Theme.padding
            width: root.sidebarWidth
            spacing: 4

            Text {
                height: 40
                leftPadding: 12
                verticalAlignment: Text.AlignVCenter
                text: "Settings"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontLarge
                font.weight: Font.DemiBold
            }

            Item {
                width: parent.width
                height: list.height

                // Slides to the picked category.
                Rectangle {
                    y: root.selected * (root.itemHeight + list.spacing)
                    width: parent.width
                    height: root.itemHeight
                    radius: Theme.innerRadius + 2
                    gradient: Theme.accentGradient

                    Behavior on y {
                        NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
                    }

                    Glow {}
                }

                Column {
                    id: list

                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.categories

                        Rectangle {
                            id: item

                            required property var modelData
                            required property int index
                            readonly property bool current: root.selected === index

                            width: parent.width
                            height: root.itemHeight
                            radius: Theme.innerRadius + 2
                            color: hover.hovered && !current ? Theme.tile : "transparent"

                            HoverHandler {
                                id: hover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: root.selected = item.index
                            }

                            Row {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 18
                                    text: item.modelData.glyph
                                    color: item.current ? Theme.accentText : Theme.textSecondary
                                    font.family: Theme.iconFont
                                    font.pixelSize: 16

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animationDuration }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: item.modelData.name
                                    color: item.current ? Theme.accentText : Theme.textPrimary
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: item.current ? Font.DemiBold : Font.Normal

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animationDuration }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Divider between the categories and the page.
        Rectangle {
            x: sidebar.x + sidebar.width + Theme.padding / 2
            y: Theme.padding
            width: 1
            height: parent.height - Theme.padding * 2
            color: Theme.border
            opacity: 0.6
        }

        Text {
            id: heading

            x: sidebar.x + sidebar.width + Theme.padding * 2
            y: Theme.padding
            height: 40
            verticalAlignment: Text.AlignVCenter
            text: root.category
            color: Theme.textPrimary
            font.pixelSize: Theme.fontLarge
            font.weight: Font.DemiBold
        }

        // All pages are here; the picked one fades and slides in, the old
        // one out.
        Item {
            id: pages

            x: heading.x
            y: heading.y + heading.height + 18
            width: root.pageWidth - Theme.padding
            height: card.pageHeight

            Page {
                name: "Appearance"

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

            Page {
                name: "Wallpaper"

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

            Page {
                name: "Night light"

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

            Page {
                name: "Screenshots"

                SettingToggle {
                    width: parent.width
                    label: "Freeze"
                    description: "Hold the screen still while picking a region (also for Super P)"
                    checked: Settings.screenshotFreeze
                    onToggled: checked => Settings.set("screenshotFreeze", checked)
                }
            }

            Page {
                name: "Lock"

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

    // One category's settings. Fades and slides in when picked.
    component Page: Column {
        required property string name
        readonly property bool current: root.category === name

        width: parent.width
        spacing: 16
        opacity: current ? 1 : 0
        visible: opacity > 0
        transform: Translate {
            y: current ? 0 : 12

            Behavior on y {
                NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationDuration; easing.type: Easing.OutCubic }
        }
    }
}
