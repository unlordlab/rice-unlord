// RSU · Vigilància — plasmoide per al rice Unlord (Plasma 6)
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property var dades: ({ tickers: [], informes: [], actualitzat: "", error: "" })
    property var vistos: ({})
    property bool primeraLectura: true

    readonly property bool fosc: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
    readonly property color cText: Kirigami.Theme.textColor
    readonly property color cSub: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
    readonly property color cLine: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
    readonly property color cRed: fosc ? "#D8654B" : "#C8553D"
    readonly property color cUp: fosc ? "#9CB07A" : "#4F6B3A"
    readonly property string mono: "Share Tech Mono"
    readonly property string cond: "Barlow Condensed Medium"

    preferredRepresentation: compactRepresentation
    toolTipMainText: "RSU · Vigilància"
    toolTipSubText: dades.error ? dades.error : (dades.actualitzat ? "Actualitzat " + dades.actualitzat : "Carregant…")

    function pct(c) { return (c >= 0 ? "+" : "−") + Math.abs(c).toFixed(2) + "%" }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source)
            if (source.indexOf("notify-send") === 0) return
            try {
                var d = JSON.parse(data["stdout"])
                root.revisarNous(d.informes || [])
                root.dades = d
            } catch (e) {
                root.dades = Object.assign({}, root.dades, { error: "No s'han pogut llegir les dades" })
            }
        }
    }

    function refrescar() { exec.connectSource(Plasmoid.configuration.command) }

    function revisarNous(llista) {
        var v = Object.assign({}, vistos)
        for (var i = 0; i < llista.length; i++) {
            var k = llista[i].t + "|" + llista[i].hora
            if (!v[k] && !primeraLectura && Plasmoid.configuration.notify) {
                var cos = (llista[i].nota ? "Nota " + llista[i].nota + " · " : "") + "obrir a RSU Terminal"
                exec.connectSource("notify-send -a 'RSU' -i office-chart-line " +
                                   "'INFORME LLEST · " + llista[i].t + "' '" + cos + "'")
            }
            v[k] = true
        }
        vistos = v
        primeraLectura = false
    }

    Timer {
        interval: Math.max(1, Plasmoid.configuration.interval) * 60000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refrescar()
    }

    // ---------- A la barra ----------
    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: fila.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: fila
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: root.dades.tickers.slice(0, Plasmoid.configuration.maxTicker)
                delegate: Row {
                    spacing: 5
                    Text { text: modelData.s; color: root.cText; font.family: root.mono; font.letterSpacing: 1 }
                    Text { text: root.pct(modelData.c); color: modelData.c >= 0 ? root.cUp : root.cRed; font.family: root.mono }
                }
            }
            Text {
                visible: root.dades.informes.length > 0
                text: "● " + root.dades.informes.length + (root.dades.informes.length === 1 ? " INFORME" : " INFORMES")
                color: root.cRed; font.family: root.mono; font.letterSpacing: 1
            }
            Text {
                visible: root.dades.tickers.length === 0 && root.dades.informes.length === 0
                text: root.dades.error ? "RSU ·  !" : "RSU"
                color: root.dades.error ? root.cRed : root.cText; font.family: root.mono; font.letterSpacing: 2
            }
        }
    }

    // ---------- Finestra en fer clic ----------
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: 0

            Text { text: "RSU · VIGILÀNCIA"; color: root.cText; font.family: root.cond; font.pixelSize: 26; font.letterSpacing: 3 }
            Rectangle { width: 34; height: 3; color: root.cRed; Layout.topMargin: 4; Layout.bottomMargin: 10 }

            Repeater {
                model: root.dades.tickers
                delegate: ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: 5; Layout.bottomMargin: 5
                        Text { text: modelData.s; color: root.cText; font.family: root.mono; Layout.preferredWidth: 70 }
                        Item { Layout.fillWidth: true }
                        Text { text: modelData.p.toFixed(2); color: root.cText; font.family: root.mono }
                        Text { text: root.pct(modelData.c); color: modelData.c >= 0 ? root.cUp : root.cRed; font.family: root.mono
                               horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 80 }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cLine }
                }
            }

            Text {
                text: "INFORMES NOUS"; color: root.cSub; font.family: root.mono; font.pixelSize: 11; font.letterSpacing: 2
                Layout.topMargin: 12; Layout.bottomMargin: 2
            }
            Text {
                visible: root.dades.informes.length === 0
                text: "Cap informe en les últimes 24 h"; color: root.cSub; font.family: root.mono; Layout.topMargin: 4
            }
            Repeater {
                model: root.dades.informes
                delegate: MouseArea {
                    Layout.fillWidth: true; implicitHeight: r.implicitHeight + 10
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (modelData.ruta) Qt.openUrlExternally("file://" + modelData.ruta)
                    Rectangle { anchors.fill: parent; color: root.cRed; opacity: parent.containsMouse ? 0.12 : 0 }
                    RowLayout {
                        id: r; anchors.fill: parent; anchors.topMargin: 5; anchors.bottomMargin: 5
                        Text { text: modelData.t; color: root.cText; font.family: root.mono; Layout.preferredWidth: 70 }
                        Text { text: modelData.nota ? "NOTA " + modelData.nota : ""; color: root.cText; font.family: root.mono }
                        Item { Layout.fillWidth: true }
                        Text { text: modelData.hora; color: root.cText; font.family: root.mono }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cLine }
                }
            }

            MouseArea {
                Layout.fillWidth: true; Layout.topMargin: 12
                implicitHeight: peu.implicitHeight
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally(Plasmoid.configuration.terminalUrl)
                Text {
                    id: peu
                    text: (root.dades.error ? root.dades.error.toUpperCase() : "ACTUALITZAT " + root.dades.actualitzat) + "  ·  OBRIR RSU TERMINAL ▶"
                    color: parent.containsMouse ? root.cRed : root.cSub
                    font.family: root.mono; font.pixelSize: 11; font.letterSpacing: 2
                }
            }
        }
    }
}
