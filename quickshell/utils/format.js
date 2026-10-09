.pragma library

// Time since `time` (ms since epoch), short: "now", "5m", "3h", "2d".
// Pass `now` from a timer to keep a binding up to date.
function age(time, now = Date.now()) {
    const minutes = Math.floor((now - time) / 60000);
    if (minutes < 1)
        return "now";
    if (minutes < 60)
        return `${minutes}m`;
    if (minutes < 1440)
        return `${Math.floor(minutes / 60)}h`;
    return `${Math.floor(minutes / 1440)}d`;
}
