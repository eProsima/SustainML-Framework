import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Fingerprint of the selected results: one radar for the YOLO models of the Axelera board,
    with their accuracy gap from the model zoo, and one for the other models (Hugging Face,
    ONNX), which have no accuracy. Less is better on every axis, so a smaller shape is greener.

    entries: the selected results that have one, as
        {"iteration", "model", "hardware", "co2" (g), "energy" (Wh), "latency" (s),
         "memory" (MB, 0 unknown), "power" (W)}
    left_out: iterations selected without a result (error, or still running)
    catalog: the YOLO models of the Axelera board (HW resources node, "yolo_models")
 */
SmlCard {
    id: root

    property var entries: []
    property var left_out: []
    property var catalog: []

    // Green, violet, magenta, olive: apart for colour-blind readers too; the marker shape of
    // each series tells them apart as well
    readonly property var series_colors: ["#4DA626", "#6250d6", "#d55181", "#8a6a00"]
    readonly property int max_series: series_colors.length

    readonly property var __yolo: entries.filter(function(e) { return root.__catalog_entry(e.model) !== null })
    readonly property var __other: entries.filter(function(e) { return root.__catalog_entry(e.model) === null })

    title: "Model fingerprint"
    subtitle: "The selected iterations: on every axis the best of them sits near the centre and the worst on the outer ring, so a smaller shape is greener"
    icon_name: "scale"

    function __catalog_entry(name) {
        for (var i = 0; i < catalog.length; i++)
            if (catalog[i].name === name)
                return catalog[i]
        return null
    }

    // Accuracy points below the most accurate YOLO model of the same task (0 is the best)
    function __accuracy_gap(name) {
        var m = __catalog_entry(name)
        var best = 0
        catalog.forEach(function(c) { if (c.goal === m.goal) best = Math.max(best, c.accuracy_int8) })
        return best - m.accuracy_int8
    }

    function __fmt(v) {
        if (v === 0)
            return "0"
        return (Math.abs(v) < 0.01 || Math.abs(v) >= 1e5) ? v.toExponential(2) : String(parseFloat(v.toPrecision(3)))
    }

    function __name(e) {
        var m = __catalog_entry(e.model)
        return (m ? m.display_name : e.model) + " · it. " + e.iteration
    }

    // Axes and series of one radar. Memory only when every model has it.
    function __radar(list, with_accuracy) {
        list = list.slice(0, max_series)
        var axes = [
            {"name": "CO2", "log": true, "bold": true, "get": function(e) { return e.co2 }, "unit": " gCO2e"},
            {"name": "Energy", "log": true, "get": function(e) { return e.energy }, "unit": " Wh"},
            {"name": "Latency", "log": true, "get": function(e) { return e.latency }, "unit": " s"},
            {"name": "Memory", "log": true, "get": function(e) { return e.memory }, "unit": " MB"},
            {"name": "Power", "log": false, "get": function(e) { return e.power }, "unit": " W"}
        ]
        if (!list.every(function(e) { return e.memory > 0 }))
            axes = axes.filter(function(a) { return a.name !== "Memory" })
        if (with_accuracy)
            axes.push({"name": "Accuracy gap", "log": false, "get": function(e) { return root.__accuracy_gap(e.model) },
                       "unit": " points"})
        return {
            "axes": axes.map(function(a) { return {"name": a.name, "log": a.log, "bold": a.bold === true} }),
            "series": list.map(function(e, j) {
                return {
                    "name": root.__name(e),
                    "detail": e.hardware,
                    "color": root.series_colors[j],
                    "values": axes.map(function(a) { return a.get(e) }),
                    "texts": axes.map(function(a) {
                        var v = a.get(e)
                        return a.name === "Accuracy gap" && v < 0.005 ? "0 (the best of its task)" : root.__fmt(v) + a.unit
                    })
                }
            })
        }
    }

    Column {
        width: parent.width
        spacing: Theme.space3

        Row {
            width: parent.width
            spacing: Theme.space5

            Repeater {
                model: [
                    {"title": "Axelera YOLO models", "hint": "Accuracy gap: points below the most accurate YOLO model of the same task (0 is the best)",
                     "list": root.__yolo, "accuracy": true},
                    {"title": "Other models (Hugging Face, ONNX)", "hint": "No accuracy: these models have none in SustainML",
                     "list": root.__other, "accuracy": false}
                ]
                delegate: Column {
                    id: panel
                    required property var modelData
                    readonly property var radar_: root.__radar(modelData.list, modelData.accuracy)
                    visible: modelData.list.length > 0
                    // Both panels share the row; one alone takes all of it
                    width: (root.__yolo.length > 0 && root.__other.length > 0)
                           ? (parent.width - Theme.space5) / 2 : parent.width
                    spacing: Theme.space2

                    Text {
                        text: panel.modelData.title
                        font.family: Theme.uiFontFamily
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }
                    Text {
                        width: parent.width
                        text: panel.modelData.hint
                        wrapMode: Text.WordWrap
                        font.family: Theme.uiFontFamily
                        font.pixelSize: Theme.fontSizeMeta
                        color: Theme.textSecondary
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.space3

                        SmlRadarChart {
                            width: Math.min(420, parent.width * 0.6)
                            height: 280
                            axes: panel.radar_.axes
                            series: panel.radar_.series
                        }

                        // Legend: marker and colour of each model
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Math.min(420, parent.width * 0.6) - Theme.space3
                            spacing: Theme.space2
                            Repeater {
                                model: panel.radar_.series
                                delegate: Row {
                                    id: legend_row
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    spacing: Theme.space2
                                    Canvas {
                                        width: 14; height: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        Component.onCompleted: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.reset()
                                            ctx.fillStyle = legend_row.modelData.color
                                            ctx.beginPath()
                                            var shape = ["circle", "square", "triangle", "diamond"][legend_row.index % 4]
                                            if (shape === "square") ctx.rect(2.5, 2.5, 9, 9)
                                            else if (shape === "triangle") { ctx.moveTo(7, 1); ctx.lineTo(12.5, 11); ctx.lineTo(1.5, 11); ctx.closePath() }
                                            else if (shape === "diamond") { ctx.moveTo(7, 1); ctx.lineTo(13, 7); ctx.lineTo(7, 13); ctx.lineTo(1, 7); ctx.closePath() }
                                            else ctx.arc(7, 7, 5, 0, 2 * Math.PI)
                                            ctx.fill()
                                        }
                                    }
                                    Column {
                                        width: parent.width - 14 - Theme.space2
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            width: parent.width
                                            text: legend_row.modelData.name
                                            wrapMode: Text.WrapAnywhere
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeMeta
                                            color: Theme.textPrimary
                                        }
                                        Text {
                                            width: parent.width
                                            text: legend_row.modelData.detail
                                            elide: Text.ElideRight
                                            font.family: Theme.uiFontFamily
                                            font.pixelSize: Theme.fontSizeMicro
                                            color: Theme.textSecondary
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: panel.modelData.list.length > root.max_series
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "Only the first " + root.max_series + " of the " + panel.modelData.list.length + " selected are drawn."
                                font.family: Theme.uiFontFamily
                                font.pixelSize: Theme.fontSizeMeta
                                color: Theme.textSecondary
                            }
                            Text {
                                visible: panel.modelData.list.length === 1
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "Select another iteration to compare with."
                                font.family: Theme.uiFontFamily
                                font.pixelSize: Theme.fontSizeMeta
                                color: Theme.textSecondary
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.left_out.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: (root.left_out.length > 1 ? "Iterations " : "Iteration ") + root.left_out.join(", ") +
                  (root.left_out.length > 1 ? " have" : " has") + " no result (error, or still running) and " +
                  (root.left_out.length > 1 ? "are" : "is") + " left out."
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeMeta
            color: Theme.textSecondary
        }
    }
}
