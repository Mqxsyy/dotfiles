pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../utils/icons.js" as Icons

// Laptop battery, and toast warnings when it runs low.
Singleton {
    id: root

    // Checked from lowest level up; each warns once per discharge.
    readonly property var warnings: [
        { level: 5, title: "Battery critical", critical: true },
        { level: 15, title: "Battery low", critical: false },
    ]

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device.ready && device.isLaptopBattery
    readonly property real percentage: device.percentage // 0..1
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property real rate: device.changeRate // W, charging or draining
    readonly property string timeLeft: formatDuration(pluggedIn ? device.timeToFull : device.timeToEmpty)

    property int lastWarning: 101

    // "2h 14m", "35m", or "" when unknown.
    function formatDuration(seconds) {
        if (!seconds)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor(seconds % 3600 / 60);
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }

    function checkWarnings() {
        if (!available)
            return;
        if (pluggedIn) {
            lastWarning = 101;
            return;
        }
        const percent = Math.round(percentage * 100);
        for (const warning of warnings) {
            if (percent <= warning.level && warning.level < lastWarning) {
                lastWarning = warning.level;
                Notifications.notify({
                    title: warning.title,
                    body: `${percent}% left` + (timeLeft ? `, about ${timeLeft}` : ""),
                    glyph: Icons.batteryAlert,
                    critical: warning.critical,
                });
                return;
            }
        }
    }

    onPercentageChanged: checkWarnings()
    onPluggedInChanged: checkWarnings()
}
