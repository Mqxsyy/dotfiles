pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Shared look for every component: colors, sizes, fonts, motion.
// Roundness and opacity come from Settings (the settings page).
//
// Colors follow the wallpaper. scripts/randomize-wallpaper.sh runs matugen,
// which renders matugen/templates/quickshell-colors.json to colorsPath. The
// file is watched, so a new wallpaper recolors everything live. The defaults
// in the adapter below are used until that file exists.
Singleton {
    id: root

    readonly property string colorsPath: Quickshell.env("HOME") + "/.local/state/quickshell/colors.json"

    readonly property color surface: Qt.alpha(colors.surface, Settings.surfaceOpacity)
    // Cards fade from surfaceTop through surface to surfaceBottom: a faint
    // accent glow above, a faint second accent below.
    readonly property color surfaceTop: Qt.alpha(Qt.tint(colors.surface, Qt.alpha(colors.accent, 0.08)), Settings.surfaceOpacity)
    readonly property color surfaceBottom: Qt.alpha(Qt.tint(colors.surface, Qt.alpha(colors.accent2, 0.06)), Settings.surfaceOpacity)
    readonly property color glow: Qt.alpha(colors.accent, 0.3)   // around active elements

    // Fill for active elements: accent fading into the second accent.
    readonly property Gradient accentGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.accent }
        GradientStop { position: 1; color: Qt.tint(root.accent, Qt.alpha(root.accent2, 0.6)) }
    }
    // Solid, not translucent: a border is drawn over what's behind the card
    // (not over the card's fill), so a translucent one disappears on dark
    // backgrounds.
    readonly property color border: Qt.tint(colors.surface, Qt.alpha(colors.textPrimary, 0.18))
    readonly property color shadow: Qt.alpha("#000000", Settings.glass ? 0.25 : 0.45)
    readonly property color textPrimary: colors.textPrimary
    readonly property color textSecondary: colors.textSecondary
    readonly property color accent: colors.accent
    readonly property color accent2: colors.accent2  // second accent, for gradients with accent
    readonly property color accentText: colors.accentText
    readonly property color error: colors.error
    readonly property color errorText: colors.errorText
    readonly property color highlight: Qt.alpha(colors.textPrimary, 0.08)
    readonly property color tile: Qt.alpha(colors.accent, 0.08)             // buttons, tiles and groups in panels
    readonly property color tileHover: Qt.alpha(colors.accent, 0.16)
    readonly property color accentSoft: Qt.alpha(colors.accent, 0.18)       // selected, but quieter than accent

    readonly property int radius: Settings.radius                  // cards
    readonly property int innerRadius: Math.round(radius * 0.55)   // rows and buttons inside cards
    readonly property int padding: 16     // card edge to content
    readonly property int gap: 8          // floating cards to the screen edges
    readonly property int iconSize: 28
    readonly property int controlSize: 26 // buttons and album art in the bar
    readonly property int shadowPad: 24   // room around a card for its shadow

    readonly property int fontSmall: 13
    readonly property int fontNormal: 15
    readonly property int fontLarge: 17
    readonly property string iconFont: "FiraCode Nerd Font Propo"

    readonly property int animationDuration: 220
    readonly property int expandDuration: 280  // bar parts growing into panels

    FileView {
        id: colorsFile

        path: root.colorsPath
        watchChanges: true
        onFileChanged: reload()
        // Changes are only noticed once the file exists, so keep checking until it does.
        onLoadFailed: retry.start()

        JsonAdapter {
            id: colors

            property string surface: "#1c1b22"
            property string border: "#3a3842"
            property string textPrimary: "#f2efe9"
            property string textSecondary: "#a8a39b"
            property string accent: "#d97757"
            property string accent2: "#c49bff"
            property string accentText: "#1c1b22"
            property string error: "#ffb4ab"
            property string errorText: "#690005"
        }
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: colorsFile.reload()
    }
}
