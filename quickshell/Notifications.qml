pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Every notification the shell gets, shown as toasts (Toasts.qml) and kept
// in `history` (NotificationsView.qml: the bar's bell, "> notifications").
// They come from:
//   - apps, through the notification server (notify-send, browsers, ...)
//   - Claude Code:  qs ipc call claude notify "<title>" "<body>"
//   - the shell itself, e.g. Battery warnings
// Do not disturb hides the toasts (except critical ones); they still go to
// the history. History is saved to ~/.local/state/quickshell/notifications.json.
Singleton {
    id: root

    property bool dnd: false
    property int maxToasts: 4
    property int maxHistory: 100
    property int timeout: 6000 // ms, unless the toast asks for its own

    readonly property ListModel toasts: model
    // Newest first: { key, app, title, body, glyph, icon, image, critical, time (ms) }
    readonly property var history: saved.entries
    // Arrived since the history was last looked at.
    property int unread: 0

    // Key -> the app's Notification, so closing one closes it for the app too.
    property var sources: ({})
    // Key -> function to run when clicked.
    property var actions: ({})
    property int nextKey: 1

    // Show a toast and add it to the history. entry: { title, body, app, glyph,
    // icon, image, critical, timeout, notification, action, history }.
    //   image:   path of a picture shown large under the text (screenshot previews)
    //   action:  function run when it's clicked (the shell's own notifications)
    //   history: false keeps it out of the history (short-lived notices)
    // One with the same title and body as a visible toast refreshes it instead.
    // Returns its key, or "" when it was merged.
    function notify(entry) {
        const time = Qt.formatTime(new Date(), "hh:mm");
        const body = entry.body ?? "";

        for (let i = 0; i < model.count; i++) {
            const toast = model.get(i);
            if (toast.title === entry.title && toast.body === body) {
                model.setProperty(i, "time", time);
                model.setProperty(i, "stamp", toast.stamp + 1);
                return "";
            }
        }

        // Unique across restarts, since the history is saved.
        const key = `${Date.now()}-${nextKey++}`;
        const fields = {
            key: key,
            app: entry.app ?? "",
            title: entry.title,
            body: body,
            glyph: entry.glyph ?? "",
            icon: entry.icon ?? "",
            image: entry.image ?? "",
            critical: !!entry.critical,
        };

        if (entry.notification)
            sources[key] = entry.notification;
        if (entry.action)
            actions[key] = entry.action;

        if (entry.history !== false) {
            // image:// icons only live as long as the app's notification.
            const kept = Object.assign({}, fields, { time: Date.now() });
            if (kept.icon.startsWith("image://"))
                kept.icon = "";
            saved.entries = [kept, ...saved.entries].slice(0, maxHistory);
            unread++;
        }

        if (dnd && !entry.critical)
            return key;

        model.insert(0, Object.assign(fields, {
            timeout: entry.critical ? 0 : (entry.timeout ?? timeout), // 0 = stays until clicked
            time: time,
            stamp: 0,
        }));
        while (model.count > maxToasts)
            close(model.get(model.count - 1).key);
        return key;
    }

    // Hide a toast; it stays in the history, and so does the app's
    // notification (its actions still work from there).
    function close(key) {
        const index = indexOf(key);
        if (index !== -1)
            model.remove(index);
    }

    // Clicking a toast or history entry runs its action (the app's default
    // action, or the shell's own) and removes it everywhere.
    function activate(key) {
        const appAction = sources[key]?.actions.find(a => a.identifier === "default");
        if (appAction)
            appAction.invoke();
        const shellAction = actions[key];
        if (shellAction)
            shellAction();
        remove(key);
    }

    // Gone from the toasts and the history; the app is told it was dismissed.
    function remove(key) {
        close(key);
        const notification = sources[key];
        if (notification)
            notification.dismiss();
        release(key);
        saved.entries = saved.entries.filter(entry => entry.key !== key);
    }

    // Hide all toasts; the history stays.
    function clear() {
        model.clear();
    }

    function clearHistory() {
        for (const entry of saved.entries)
            remove(entry.key);
        model.clear();
        unread = 0;
    }

    function markRead() {
        unread = 0;
    }

    function release(key) {
        delete sources[key];
        delete actions[key];
    }

    function indexOf(key) {
        for (let i = 0; i < model.count; i++) {
            if (model.get(i).key === key)
                return i;
        }
        return -1;
    }

    // The app closed its notification itself: it's no longer relevant.
    function forget(key) {
        release(key);
        remove(key);
    }

    // App icons come as theme names or file paths.
    function iconSource(notification) {
        if (notification.image)
            return notification.image;
        const icon = notification.appIcon;
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.startsWith("file://"))
            return icon;
        return icon ? Quickshell.iconPath(icon, true) : "";
    }

    ListModel {
        id: model
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/notifications.json"
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: saved
            property var entries: []
        }
    }

    NotificationServer {
        imageSupported: true
        actionsSupported: true

        onNotification: notification => {
            const key = root.notify({
                app: notification.appName,
                title: notification.summary || notification.appName,
                body: notification.body,
                icon: root.iconSource(notification),
                glyph: (notification.appName || "?").charAt(0).toUpperCase(),
                critical: notification.urgency === NotificationUrgency.Critical,
                timeout: notification.expireTimeout > 0 ? notification.expireTimeout : undefined, // ms
                notification: notification,
            });
            if (key !== "") {
                notification.tracked = true;
                notification.closed.connect(reason => {
                    if (reason === NotificationCloseReason.CloseRequested)
                        root.forget(key);
                    else
                        root.release(key); // we dismissed it, or it timed out by itself
                });
            }
        }
    }

    IpcHandler {
        target: "claude"

        function notify(title: string, body: string): void {
            root.notify({ app: "Claude Code", title: title, body: body, glyph: "✻" });
        }

        function dismiss(): void {
            root.clear();
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            root.dnd = !root.dnd;
        }

        function clear(): void {
            root.clear();
        }

        function clearHistory(): void {
            root.clearHistory();
        }
    }
}
