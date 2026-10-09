import QtQuick.Effects

// Drop shadow shared by every surface. Use as `layer.effect: Shadow {}`.
// Lighter with glass on, so Hyprland's blur (which skips pixels below its
// ignore_alpha) doesn't also blur the shadow.
MultiEffect {
    shadowEnabled: true
    shadowColor: "#000000"
    shadowOpacity: Settings.glass ? 0.2 : 0.5
    shadowBlur: 1.0
    shadowVerticalOffset: 6
    blurMax: 32
}
