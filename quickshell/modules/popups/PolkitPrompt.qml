import Quickshell.Services.Polkit
import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/icons.js" as Icons

// Asks for your password when an app needs admin rights (pkexec, mounting
// a drive in Nautilus, ...). The shell is the session's polkit agent.
// Esc or a click outside cancels.
Popup {
    id: root

    readonly property AuthFlow flow: agent.flow
    property string error: ""

    property int cardWidth: 380

    function submit() {
        if (!flow || password.text === "")
            return;
        error = "";
        flow.submit(password.text);
        password.text = "";
    }

    name: "polkit"
    surface: card

    // Closed without finishing: cancel, so the app isn't left waiting.
    onOpenChanged: {
        if (open) {
            error = "";
            password.text = "";
            password.input.forceActiveFocus();
        } else if (flow && !flow.isCompleted) {
            flow.cancelAuthenticationRequest();
        }
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: Popups.open("polkit")
    }

    Connections {
        target: root.flow

        function onAuthenticationFailed() {
            root.error = "Wrong password";
        }

        function onIsCompletedChanged() {
            if (root.flow.isCompleted && root.open)
                Popups.close();
        }
    }

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: root.cardWidth
        opacity: root.reveal

        Row {
            width: parent.width
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.lock
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 22
            }

            Column {
                width: parent.width - 34
                spacing: 2

                Text {
                    text: "Authentication required"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: root.flow?.message ?? ""
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSmall - 1
                    wrapMode: Text.Wrap
                }
            }
        }

        TextField {
            id: password

            width: parent.width
            password: root.flow?.responseVisible === false
            placeholder: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
            onAccepted: root.submit()
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.error || (root.flow?.supplementaryMessage ?? "")
            color: root.error || root.flow?.supplementaryIsError ? Theme.error : Theme.textSecondary
            font.pixelSize: Theme.fontSmall - 1
            wrapMode: Text.Wrap
        }

        Row {
            anchors.right: parent.right
            spacing: 6

            PanelButton {
                label: "Cancel"
                onClicked: Popups.close()
            }

            PanelButton {
                primary: true
                label: "Authenticate"
                onClicked: root.submit()
            }
        }
    }
}
