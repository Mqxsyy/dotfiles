pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

// Network connections (NetworkManager).
//   wifi:     the connected wifi network, if any
//   networks: wifi networks in range, connected first, then saved ones,
//             then by signal
Singleton {
    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifi: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
    readonly property string name: wifi?.name ?? (wired ? "Ethernet" : "")
    readonly property real signal: wifi?.signalStrength ?? 0 // 0..1

    // Signal is compared in whole bars so the list doesn't reshuffle on every
    // small change.
    readonly property var networks: (wifiDevice?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected)
            || (b.known - a.known)
            || (bars(b.signalStrength) - bars(a.signalStrength))
            || a.name.localeCompare(b.name))

    function bars(strength) {
        return Math.floor(strength * 4);
    }

    function setWifi(enabled) {
        Networking.wifiEnabled = enabled;
    }

    function toggleWifi() {
        setWifi(!Networking.wifiEnabled);
    }
}
