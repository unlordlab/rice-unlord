import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_command: commandField.text
    property alias cfg_interval: intervalSpin.value
    property alias cfg_maxTicker: maxSpin.value
    property alias cfg_terminalUrl: urlField.text
    property alias cfg_notify: notifyBox.checked

    Kirigami.FormLayout {
        QQC2.TextField { id: commandField; Kirigami.FormData.label: "Ordre de dades:" }
        QQC2.SpinBox { id: intervalSpin; from: 1; to: 120; Kirigami.FormData.label: "Actualitzar cada (min):" }
        QQC2.SpinBox { id: maxSpin; from: 0; to: 10; Kirigami.FormData.label: "Valors a la barra:" }
        QQC2.TextField { id: urlField; Kirigami.FormData.label: "Adreça de RSU Terminal:" }
        QQC2.CheckBox { id: notifyBox; text: "Avisar quan hi hagi un informe nou" }
    }
}
