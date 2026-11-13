import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

import "markers.js" as Markers

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

    // Vivid green, blue, purple, yellow, red and orange. Some look alike to colour-blind readers
    // and the yellow is light on a white background, so every marker has a darker outline and
    // its own shape, and any model can be hidden.
    readonly property var series_colors: ["#34b233", "#1e6ff0", "#8b3fd9", "#f2c200", "#e02828", "#f07c00"]
    readonly property int max_series: series_colors.length

    // Models hidden from the radars, by iteration (clicked in the legend)
    property var hidden: ({})

    // Space of a radar with the column on its right; side by side only when both fit
    // Height of a radar, set by the view to fill the space it has
    property real radar_height: 468
    readonly property int __radar_size: Math.round(radar_height * 1.28)
    readonly property int __side_width: 300
    readonly property bool __side_by_side: width >= 2 * (__radar_size + Theme.space3 + __side_width) + Theme.space5

    function __toggle(iteration) {
        var copy = Object.assign({}, hidden)
        if (copy[iteration])
            delete copy[iteration]
        else
            copy[iteration] = true
        hidden = copy
    }

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

    // Axes and series of one radar: every model for the legend ("series", colour and marker
    // shape by its place in the list) and the ones not hidden for the radar ("shown"). Memory
    // only when every model has it.
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
        var series = list.map(function(e, j) {
                return {
                    "iteration": e.iteration,
                    "shape": j,
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
        return {
            "axes": axes.map(function(a) { return {"name": a.name, "log": a.log, "bold": a.bold === true} }),
            "series": series,
            "shown": series.filter(function(sr) { return !root.hidden[sr.iteration] })
        }
    }

    Column {
        width: parent.width
        spacing: Theme.space4

        Flow {
            width: parent.width
            spacing: Theme.space5

            Repeater {
                model: [
                    {"title": "Axelera YOLO models", "hint": "Accuracy gap: points below the most accurate YOLO model of the same task (0 is the best)",
                     "list": root.__yolo, "accuracy": true},
                    {"title": "Other models (Hugging Face, ONNX)", "hint": "No accuracy: these models have none in SustainML",
                     "list": root.__other, "accuracy": false}
                ]
                // Radar on the left; title, hint and legend on its right
                delegate: Row {
                    id: panel
                    required property var modelData
                    readonly property var radar_: root.__radar(modelData.list, modelData.accuracy)
                    visible: modelData.list.length > 0
                    width: (root.__side_by_side && root.__yolo.length > 0 && root.__other.length > 0)
                           ? (parent.width - Theme.space5) / 2 : parent.width
                    spacing: Theme.space3

                    SmlRadarChart {
                        id: radar
                        width: root.__radar_size
                        height: root.radar_height
                        axes: panel.radar_.axes
                        series: panel.radar_.shown
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - radar.width - Theme.space3
                        spacing: Theme.space2

                        Text {
                            width: parent.width
                            text: panel.modelData.title
                            wrapMode: Text.WordWrap
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
                        Text {
                            visible: panel.radar_.series.length > 1
                            width: parent.width
                            topPadding: Theme.space2
                            text: "Click a model to hide or show it"
                            wrapMode: Text.WordWrap
                            font.family: Theme.uiFontFamily
                            font.pixelSize: Theme.fontSizeMicro
                            color: Theme.textMuted
                        }

                        // Legend: marker and colour of each model, a click hides or shows it
                        Repeater {
                            model: panel.radar_.series
                            delegate: Item {
                                id: legend_row
                                required property var modelData
                                readonly property bool hidden_: root.hidden[modelData.iteration] === true
                                width: parent.width
                                height: legend_text.implicitHeight + Theme.space2
                                opacity: hidden_ ? 0.4 : 1

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.radiusSm
                                    color: legend_mouse.containsMouse ? Theme.accentSubtle : "transparent"
                                }
                                Canvas {
                                    id: legend_marker
                                    x: Theme.space1
                                    width: 14; height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.fillStyle = legend_row.modelData.color
                                        ctx.strokeStyle = Qt.darker(legend_row.modelData.color, 1.5)
                                        ctx.lineWidth = 1.2
                                        Markers.path(ctx, legend_row.modelData.shape, 7, 7, 5.5)
                                        ctx.fill()
                                        ctx.stroke()
                                    }
                                }
                                Column {
                                    id: legend_text
                                    anchors { left: legend_marker.right; leftMargin: Theme.space2; right: parent.right; verticalCenter: parent.verticalCenter }
                                    Text {
                                        width: parent.width
                                        text: legend_row.modelData.name + (legend_row.hidden_ ? " (hidden)" : "")
                                        wrapMode: Text.Wrap
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
                                MouseArea {
                                    id: legend_mouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.__toggle(legend_row.modelData.iteration)
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
