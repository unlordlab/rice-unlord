// Unlord / RSU — tema de inicio de sesión (SDDM, Qt 6)
import QtQuick 2.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#D3CCB8"

    readonly property color cBg: "#D3CCB8"
    readonly property color cBg2: "#C6BFA9"
    readonly property color cInk: "#2D2B26"
    readonly property color cText: "#3A3730"
    readonly property color cSub: "#6E685A"
    readonly property color cRed: "#C8553D"
    readonly property real s: Math.min(width / 1920, height / 1080)

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string sessionName: ""
    property string message: ""

    FontLoader { id: mono; source: "fonts/ShareTechMono.ttf" }
    FontLoader { id: cond; source: "fonts/BarlowCondensed-Medium.ttf" }

    // Session names (read from the model through an invisible Repeater)
    Item {
        visible: false
        Repeater {
            id: sessionNames
            model: sessionModel
            delegate: Item { property string sname: model.name }
            onItemAdded: root.updateSessionName()
        }
    }
    function updateSessionName() {
        var it = sessionNames.itemAt(sessionIndex)
        sessionName = it ? it.sname : ""
    }
    onSessionIndexChanged: updateSessionName()

    function doLogin() {
        message = "VERIFICANT..."
        sddm.login(userField.text, passField.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = "ACCÉS DENEGAT · TORNA-HO A PROVAR"
            passField.text = ""
            passField.forceActiveFocus()
        }
        function onLoginSucceeded() { root.message = "" }
    }

    Image {
        anchors.fill: parent
        source: config.background ? config.background : "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    // ---------- Clock (top centre) ----------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 150 * s
        spacing: 6 * s
        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: cond.name
            font.pixelSize: 96 * s
            font.letterSpacing: 10 * s
            color: root.cInk
            text: Qt.formatTime(new Date(), "hh:mm")
        }
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: mono.name
            font.pixelSize: 16 * s
            font.letterSpacing: 4 * s
            color: root.cSub
            text: Qt.formatDate(new Date(), "yyyy.MM.dd")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: { clock.text = Qt.formatTime(new Date(), "hh:mm"); dateText.text = Qt.formatDate(new Date(), "yyyy.MM.dd") }
        }
    }

    // ---------- Left column: title + user ----------
    Column {
        x: 182 * s
        y: 300 * s
        spacing: 14 * s
        Text {
            font.family: cond.name
            font.pixelSize: 64 * s
            font.letterSpacing: 8 * s
            color: root.cInk
            text: "INICI DE SESSIÓ"
        }
        Rectangle { width: 420 * s; height: 2 * s; color: root.cInk; opacity: 0.6 }
        Rectangle { width: 40 * s; height: 4 * s; color: root.cRed }
        Item { width: 1; height: 16 * s }
        Text { font.family: mono.name; font.pixelSize: 13 * s; font.letterSpacing: 3 * s; color: root.cSub; text: "USUARI" }
        Rectangle {
            width: 420 * s; height: 52 * s
            color: root.cInk
            TextInput {
                id: userField
                anchors.fill: parent
                anchors.leftMargin: 18 * s
                verticalAlignment: TextInput.AlignVCenter
                font.family: mono.name
                font.pixelSize: 20 * s
                font.letterSpacing: 3 * s
                color: root.cBg
                selectionColor: root.cRed
                text: userModel.lastUser
                KeyNavigation.tab: passField
                Keys.onReturnPressed: passField.forceActiveFocus()
                Keys.onEnterPressed: passField.forceActiveFocus()
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 16 * s
                anchors.verticalCenter: parent.verticalCenter
                font.family: mono.name; font.pixelSize: 16 * s; color: root.cRed
                text: "◆"
            }
        }
        Text {
            font.family: mono.name; font.pixelSize: 13 * s; font.letterSpacing: 3 * s; color: root.cSub
            text: "EQUIP: " + (sddm.hostName ? sddm.hostName.toUpperCase() : "")
        }
    }

    // ---------- Right column: password + actions ----------
    Column {
        x: parent.width - 182 * s - 420 * s
        y: 300 * s
        spacing: 12 * s

        Rectangle {
            width: 420 * s; height: 34 * s; color: root.cInk
            Text { anchors.verticalCenter: parent.verticalCenter; x: 14 * s; font.family: mono.name; font.pixelSize: 15 * s; font.letterSpacing: 3 * s; color: root.cBg; text: "AUTENTICACIÓ" }
        }
        Rectangle {
            width: 420 * s; height: 54 * s
            color: root.cBg
            border.color: passField.activeFocus ? root.cRed : root.cInk
            border.width: 2 * s
            TextInput {
                id: passField
                anchors.fill: parent
                anchors.leftMargin: 18 * s
                anchors.rightMargin: 60 * s
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "■"
                font.family: mono.name
                font.pixelSize: 20 * s
                font.letterSpacing: 6 * s
                color: root.cInk
                focus: true
                KeyNavigation.backtab: userField
                Keys.onReturnPressed: root.doLogin()
                Keys.onEnterPressed: root.doLogin()
            }
            Rectangle {
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.margins: 6 * s
                width: 44 * s
                color: goArea.containsMouse ? root.cRed : root.cInk
                Text { anchors.centerIn: parent; font.family: mono.name; font.pixelSize: 18 * s; color: root.cBg; text: "▶" }
                MouseArea { id: goArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.doLogin() }
            }
        }
        Text {
            width: 420 * s
            font.family: mono.name; font.pixelSize: 13 * s; font.letterSpacing: 2 * s
            color: root.cRed
            text: root.message
        }
        Item { width: 1; height: 10 * s }

        Repeater {
            model: [
                { label: "APAGAR", act: "power", show: sddm.canPowerOff },
                { label: "REINICIAR", act: "reboot", show: sddm.canReboot },
                { label: "SESSIÓ: " + root.sessionName.toUpperCase(), act: "session", show: true }
            ]
            delegate: Rectangle {
                visible: modelData.show
                width: 420 * s; height: 44 * s
                color: btn.containsMouse ? root.cRed : root.cInk
                opacity: btn.containsMouse ? 1.0 : 0.92
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 14 * s; spacing: 12 * s
                    Text { font.family: mono.name; font.pixelSize: 12 * s; color: root.cBg; text: "◆"; anchors.verticalCenter: parent.verticalCenter }
                    Text { font.family: mono.name; font.pixelSize: 15 * s; font.letterSpacing: 3 * s; color: root.cBg; text: modelData.label }
                }
                MouseArea {
                    id: btn; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (modelData.act === "power") sddm.powerOff()
                        else if (modelData.act === "reboot") sddm.reboot()
                        else root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessionNames.count)
                    }
                }
            }
        }
    }

    // ---------- Bottom hints ----------
    Text {
        x: 182 * s; y: parent.height - 130 * s
        font.family: mono.name; font.pixelSize: 13 * s; font.letterSpacing: 3 * s; color: "#E6E0CE"
        text: "RSU · REDISTRIBUTION RESEARCH UNIT"
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 180 * s
        y: parent.height - 130 * s
        font.family: mono.name; font.pixelSize: 13 * s; font.letterSpacing: 3 * s; color: "#E6E0CE"
        text: "INTRO ENTRAR · TAB CANVIAR CAMP"
    }

    Component.onCompleted: {
        updateSessionName()
        if (userField.text === "") userField.forceActiveFocus()
        else passField.forceActiveFocus()
    }
}
