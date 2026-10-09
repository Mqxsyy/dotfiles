import Quickshell.Bluetooth
import QtQuick
import qs.config
import qs.components
import "../../utils/icons.js" as Icons

// Bluetooth on/off and devices. Click a device to connect, disconnect,
// pair or forget it. Looks for new devices while shown.
// Shown when the bar's status card expands on the bluetooth icon (or "> bluetooth").
Column {
    id: root

    property bool active: true
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    // Paired devices first, then the rest by name.
    readonly property var devices: (adapter?.devices.values ?? [])
        .filter(device => device.paired || device.name !== "")
        .sort((a, b) => (b.paired - a.paired) || a.name.localeCompare(b.name))

    // The device whose actions are showing.
    property var expanded: null

    function status(device) {
        const states = {
            [BluetoothDeviceState.Connecting]: "Connecting…",
            [BluetoothDeviceState.Disconnecting]: "Disconnecting…",
        };
        if (states[device.state])
            return states[device.state];
        if (device.pairing)
            return "Pairing…";
        if (device.connected)
            return device.batteryAvailable ? `Connected · ${Math.round(device.battery * 100)}%` : "Connected";
        return device.paired ? "Paired" : "";
    }

    spacing: 12

    onActiveChanged: if (!active) expanded = null

    Binding {
        when: root.active && (root.adapter?.enabled ?? false)
        target: root.adapter
        property: "discovering"
        value: true
    }

    SettingToggle {
        width: parent.width
        label: "Bluetooth"
        description: !root.adapter ? "Not available" : root.adapter.enabled ? `${root.devices.filter(device => device.connected).length} connected` : "Off"
        checked: root.adapter?.enabled ?? false
        onToggled: checked => {
            if (root.adapter)
                root.adapter.enabled = checked;
        }
    }

    // bluetoothd isn't running (the service is disabled).
    Text {
        width: parent.width
        visible: !root.adapter
        text: "Start it with: sudo systemctl enable --now bluetooth"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall - 1
        wrapMode: Text.Wrap
    }

    ListView {
        id: list

        width: parent.width
        height: Math.min(contentHeight, 340)
        visible: root.adapter?.enabled ?? false
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.devices

        delegate: ListRow {
            id: row

            required property var modelData
            readonly property var device: modelData

            width: list.width
            glyph: device.connected ? Icons.bluetoothConnected : Icons.bluetooth
            title: device.name || device.address
            subtitle: root.status(device)
            selected: device.connected
            onClicked: root.expanded = root.expanded === device ? null : device

            Row {
                visible: root.expanded === row.device
                leftPadding: 48
                bottomPadding: 12
                spacing: 6

                PanelButton {
                    primary: true
                    label: row.device.connected ? "Disconnect" : row.device.paired ? "Connect" : "Pair"
                    onClicked: {
                        root.expanded = null;
                        if (row.device.connected)
                            row.device.disconnect();
                        else if (row.device.paired)
                            row.device.connect();
                        else
                            row.device.pair();
                    }
                }

                PanelButton {
                    visible: row.device.paired
                    label: "Forget"
                    onClicked: {
                        root.expanded = null;
                        row.device.forget();
                    }
                }
            }
        }
    }

    Text {
        visible: list.visible && list.count === 0
        text: "Looking for devices…"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }
}
