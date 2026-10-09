import Quickshell
import Quickshell.Networking as NetworkTypes
import QtQuick
import "icons.js" as Icons

// Wifi on/off and the networks in range. Click a network for its actions:
// connect (asking for the password when needed), disconnect, forget.
// Shown when the bar's status card expands on the wifi icon (or "> wifi").
Column {
    id: root

    // Scan for networks only while this is on screen.
    property bool active: true
    // A password field has focus; the bar stays open while it does.
    readonly property bool typing: typingIn !== null
    property var typingIn: null

    // The network whose actions are showing, and why connecting to it failed.
    property var expanded: null
    property string error: ""

    function expand(network) {
        error = "";
        expanded = expanded === network ? null : network;
    }

    function connectTo(network, password) {
        error = "";
        expanded = null;
        const needsPassword = !network.known && network.security !== NetworkTypes.WifiSecurityType.Open;
        if (needsPassword)
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function status(network) {
        if (network.stateChanging)
            return network.connected ? "Disconnecting…" : "Connecting…";
        if (network.connected)
            return Network.online ? "Connected" : "Connected · no internet";
        return network.known ? "Saved" : "";
    }

    spacing: 12

    onActiveChanged: if (!active) expanded = null

    Binding {
        when: root.active && Network.wifiDevice !== null
        target: Network.wifiDevice
        property: "scannerEnabled"
        value: true
    }

    SettingToggle {
        width: parent.width
        label: "Wi-Fi"
        description: {
            if (!Network.wifiEnabled)
                return "Off";
            return Network.wifi ? root.status(Network.wifi) + " to " + Network.wifi.name : "Not connected";
        }
        checked: Network.wifiEnabled
        onToggled: checked => Network.setWifi(checked)
    }

    ListView {
        id: list

        width: parent.width
        height: Math.min(contentHeight, 340)
        visible: Network.wifiEnabled
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds

        // Keeps each row (and a half-typed password) while the list re-sorts.
        model: ScriptModel {
            values: Network.networks
        }

        delegate: ListRow {
            id: row

            required property var modelData
            readonly property var network: modelData
            readonly property bool secured: network.security !== NetworkTypes.WifiSecurityType.Open
            readonly property bool needsPassword: secured && !network.known
            readonly property bool isExpanded: root.expanded === network

            width: list.width
            glyph: Icons.level(Icons.wifi, network.signalStrength)
            title: network.name
            subtitle: root.status(network)
            trailing: secured ? Icons.lock : ""
            selected: network.connected
            onClicked: root.expand(network)

            onIsExpandedChanged: {
                password.text = "";
                if (isExpanded && needsPassword)
                    password.input.forceActiveFocus();
            }

            Connections {
                target: row.network

                function onConnectionFailed(reason) {
                    root.expanded = row.network;
                    root.error = reason === NetworkTypes.ConnectionFailReason.NoSecrets ? "Wrong password" : "Couldn't connect";
                }
            }

            Column {
                visible: row.isExpanded
                width: parent.width
                leftPadding: 48
                rightPadding: 12
                bottomPadding: 12
                spacing: 8

                TextField {
                    id: password
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    visible: row.needsPassword
                    placeholder: "Password"
                    password: true
                    onAccepted: root.connectTo(row.network, text)
                    // Esc leaves the field (and lets the bar close); not handled, so a panel still closes too.
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Escape)
                            password.input.focus = false;
                    }

                    Connections {
                        target: password.input

                        function onActiveFocusChanged() {
                            if (password.input.activeFocus)
                                root.typingIn = password;
                            else if (root.typingIn === password)
                                root.typingIn = null;
                        }
                    }
                }

                Text {
                    visible: root.error !== ""
                    text: root.error
                    color: Theme.error
                    font.pixelSize: Theme.fontSmall - 1
                }

                Row {
                    spacing: 6

                    PanelButton {
                        primary: true
                        label: row.network.connected ? "Disconnect" : "Connect"
                        onClicked: {
                            if (row.network.connected) {
                                root.expanded = null;
                                row.network.disconnect();
                            } else {
                                root.connectTo(row.network, password.text);
                            }
                        }
                    }

                    PanelButton {
                        visible: row.network.known
                        label: "Forget"
                        onClicked: {
                            root.expanded = null;
                            row.network.forget();
                        }
                    }
                }
            }
        }
    }

    Text {
        visible: Network.wifiEnabled && list.count === 0
        text: "Looking for networks…"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }
}
