pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick
import qs.config

// The lock screen's state. LockCover.qml fades the lock screen in over the
// desktop, then LockScreen.qml locks the session behind the same picture;
// unlocking goes the other way.
//   lock():    fade in, then lock the session
//   submit():  check `password`; right, and it unlocks and fades out
//   suspend(): lock, then suspend (the power menu's Suspend)
// The password is checked like logging in (PAM's "login": the password,
// and too many wrong tries lock the account for a while).
// Also locks after Settings.lockAfter idle minutes (0 = never).
//   qs ipc call lock lock
//
// At boot it is the login screen: greetd logs in and starts Hyprland
// already locked (greetd/config.toml); Hyprland's --locked-cmd,
// scripts/start-locked.sh, leaves `startLockedFlag` for the shell to put
// its lock screen up as soon as it starts. If it never does, Hyprland
// stays locked.
Singleton {
    id: root

    // The session is locked while this is true. Kept across config reloads,
    // so saving a file doesn't unlock it.
    readonly property bool locked: kept.locked
    // The lock screen is (fading) in.
    readonly property bool shown: kept.shown
    property string password: ""
    property string error: "" // why the last try failed
    readonly property bool checking: pam.active
    property int fadeDuration: 500
    // Locked from the start (boot): nothing has faded the lock screen in
    // over the desktop, so it fades in from black (LockSurface.qml).
    property bool fromBlack: false
    // At boot a new wallpaper is picked; the lock screen waits for it and
    // its colors (or `prepareLimit` at most), so it doesn't change once shown.
    property bool preparing: false
    property int prepareLimit: 3000 // ms

    readonly property string startLockedFlag: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-start-locked"

    // A wrong password (the field shakes).
    signal failed()

    function lock() {
        if (kept.shown)
            return;
        password = "";
        error = "";
        kept.shown = true;
        lockDelay.restart();
    }

    // Lock at once, without the fade over the desktop: Hyprland has kept
    // the session locked since it started. Then a new wallpaper for the day.
    function startLocked() {
        password = "";
        error = "";
        fromBlack = true;
        kept.shown = true;
        kept.locked = true;
        preparing = true;
        prepareLimitTimer.start();
        Wallpaper.randomize();
    }

    function submit() {
        if (password === "" || pam.active)
            return;
        error = "";
        pam.start();
    }

    function suspend() {
        lock();
        suspendDelay.restart();
    }

    PersistentProperties {
        id: kept
        reloadableId: "lock"

        property bool locked: false
        property bool shown: false

        // Reloaded while fading in: lock now.
        onReloaded: {
            if (shown)
                locked = true;
        }
    }

    // The new wallpaper and its colors are written; give the files a moment
    // to be read back (Theme.qml, Wallpaper.qml) before showing them.
    Connections {
        target: Wallpaper

        function onRunningChanged() {
            if (root.preparing && !Wallpaper.running)
                prepared.start();
        }
    }

    Timer {
        id: prepared
        interval: 150
        onTriggered: root.preparing = false
    }

    Timer {
        id: prepareLimitTimer
        interval: root.prepareLimit
        onTriggered: root.preparing = false
    }

    // Taken (removed) on the shell's first start after boot; a reload or a
    // later start finds nothing.
    Process {
        running: true
        command: ["rm", root.startLockedFlag]
        onExited: exitCode => {
            if (exitCode === 0)
                root.startLocked();
        }
    }

    PamContext {
        id: pam

        config: "login"

        // Why it refuses, when it says (e.g. locked after too many tries).
        property string refusal: ""

        onActiveChanged: {
            if (active)
                refusal = "";
        }

        onPamMessage: {
            if (messageIsError)
                refusal = message.trim();
        }

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.password = "";
            if (result === PamResult.Success) {
                root.fromBlack = false;
                kept.locked = false;
                kept.shown = false;
                return;
            }
            root.error = refusal || "Wrong password";
            root.failed();
        }

        onError: () => {
            root.password = "";
            root.error = "Couldn't check the password";
            root.failed();
        }
    }

    // Lock once the lock screen has faded in.
    Timer {
        id: lockDelay
        interval: root.fadeDuration
        onTriggered: kept.locked = true
    }

    // Suspend once the lock screen is up, so it's what shows on wake.
    Timer {
        id: suspendDelay
        interval: root.fadeDuration + 1000
        onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
    }

    IdleMonitor {
        enabled: Settings.lockAfter > 0 && !root.locked
        timeout: Settings.lockAfter * 60 // seconds
        onIsIdleChanged: {
            if (isIdle)
                root.lock();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }
}
