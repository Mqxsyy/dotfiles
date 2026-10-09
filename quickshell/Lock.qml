pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick

// The lock screen's state. LockCover.qml fades the lock screen in over the
// desktop, then LockScreen.qml locks the session behind the same picture;
// unlocking goes the other way.
//   lock():    fade in, then lock the session
//   submit():  check `password`; right, and it unlocks and fades out
//   suspend(): lock, then suspend (the power menu's Suspend)
// The password is checked by PAM with pam/lock (just the user's password).
// Also locks after Settings.lockAfter idle minutes (0 = never).
//   qs ipc call lock lock
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

    PamContext {
        id: pam

        configDirectory: Quickshell.shellDir + "/pam"
        config: "lock"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.password = "";
            if (result === PamResult.Success) {
                kept.locked = false;
                kept.shown = false;
                return;
            }
            root.error = result === PamResult.MaxTries ? "Too many tries" : "Wrong password";
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
