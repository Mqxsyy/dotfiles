pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

// Current network connection (NetworkManager).
Singleton {
    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifi: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
    readonly property string name: wifi?.name ?? (wired ? "Ethernet" : "")
    readonly property real signal: wifi?.signalStrength ?? 0 // 0..1

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}
