import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Locks the session while Lock.locked, with a LockSurface on every screen.
// If quickshell dies while locked, Hyprland keeps the session locked; see
// guides/quickshell.md for getting back in.
WlSessionLock {
    locked: Lock.locked

    LockSurface {}
}
