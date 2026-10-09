pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Every toast the shell shows (drawn by Toasts.qml). They come from:
//   - apps, through the notification server (notify-send, browsers, ...)
//   - Claude Code:  qs ipc call claude notify "<title>" "<body>"
//   - the shell itself, e.g. Battery warnings
// Do not disturb hides everything except critical toasts.
Singleton {
    id: root

    property bool dnd: false
    property int maxToasts: 4
    property int timeout: 6000 // ms, unless the toast asks for its own

    readonly property ListModel toasts: model

    // Toast key -> the app's Notification, so closing a toast closes it for the app too.
    property var sources: ({})
    // Toast key -> function to run when clicked.
    property var actions: ({})
    property int nextKey: 1

    // Show a toast. entry: { title, body, glyph, icon, image, critical, timeout, notification, action }.
    // image: path of a picture shown large under the text (screenshot previews).
    // action: function run when the toast is clicked (the shell's own toasts).
    // A toast with the same title and body as a visible one refreshes it instead.
    // Returns the new toast's key, or 0 when it was hidden by dnd or merged.
    function notify(entry) {
        if (dnd && !entry.critical)
            return 0;

        const time = Qt.formatTime(new Date(), "hh:mm");
        const body = entry.body ?? "";

        for (let i = 0; i < model.count; i++) {
            const toast = model.get(i);
            if (toast.title === entry.title && toast.body === body) {
                model.setProperty(i, "time", time);
                model.setProperty(i, "stamp", toast.stamp + 1);
                return 0;
            }
        }

        const key = nextKey++;
        if (entry.notification)
            sources[key] = entry.notification;
        if (entry.action)
            actions[key] = entry.action;

        model.insert(0, {
            key: key,
            title: entry.title,
            body: body,
            glyph: entry.glyph ?? "",
            icon: entry.icon ?? "",
            image: entry.image ?? "",
            critical: !!entry.critical,
            timeout: entry.critical ? 0 : (entry.timeout ?? timeout), // 0 = stays until clicked
            time: time,
            stamp: 0,
        });

        while (model.count > maxToasts)
            close(model.get(model.count - 1).key, false);
        return key;
    }

    // Remove a toast. byUser tells the app it was dismissed rather than timed out.
    function close(key, byUser) {
        const index = indexOf(key);
        if (index !== -1)
            model.remove(index);

        const notification = sources[key];
        delete sources[key];
        delete actions[key];
        if (notification)
            byUser ? notification.dismiss() : notification.expire();
    }

    // Clicking a toast runs its action: the app's default action, or the
    // shell's own, if it has one.
    function activate(key) {
        const appAction = sources[key]?.actions.find(a => a.identifier === "default");
        if (appAction)
            appAction.invoke();
        const shellAction = actions[key];
        if (shellAction)
            shellAction();
        close(key, true);
    }

    function clear() {
        while (model.count > 0)
            close(model.get(0).key, true);
    }

    function indexOf(key) {
        for (let i = 0; i < model.count; i++) {
            if (model.get(i).key === key)
                return i;
        }
        return -1;
    }

    // The app closed its notification itself.
    function forget(notification) {
        for (const key in sources) {
            if (sources[key] === notification) {
                delete sources[key];
                const index = indexOf(Number(key));
                if (index !== -1)
                    model.remove(index);
            }
        }
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

    NotificationServer {
        imageSupported: true
        actionsSupported: true

        onNotification: notification => {
            const key = root.notify({
                title: notification.summary || notification.appName,
                body: notification.body,
                icon: root.iconSource(notification),
                glyph: (notification.appName || "?").charAt(0).toUpperCase(),
                critical: notification.urgency === NotificationUrgency.Critical,
                timeout: notification.expireTimeout > 0 ? notification.expireTimeout : undefined, // ms
                notification: notification,
            });
            if (key !== 0) {
                notification.tracked = true;
                notification.closed.connect(() => root.forget(notification));
            }
        }
    }

    IpcHandler {
        target: "claude"

        function notify(title: string, body: string): void {
            root.notify({ title: title, body: body, glyph: "✻" });
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
    }
}
