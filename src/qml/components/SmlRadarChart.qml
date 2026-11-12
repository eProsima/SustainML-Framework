import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Radar of a few models over the same axes, where less is better on every axis. Each axis is
    scaled from the best of the series (near the centre) to the worst (outer ring), on a log
    scale when the axis asks for it, so a smaller shape is the better model.

    Usage:
        SmlRadarChart {
            axes: [{"name": "CO2", "log": true, "bold": true}, {"name": "Power", "log": false}]
            series: [{"name": "YOLO11n", "color": "#4DA626",
                      "values": [0.002, 9.1], "texts": ["0.002 g", "9.1 W"]}]
        }
 */
Item {
    id: root

    property var axes: []
    property var series: []

    // Marker of each series, the second encoding next to its colour
    readonly property var shapes: ["circle", "square", "triangle", "diamond"]

    property var __labels: []
    property var __points: []

    onAxesChanged: canvas.requestPaint()
    onSeriesChanged: canvas.requestPaint()

    // Position 0-1 of each value of each series on its axis
    function __scaled() {
        return axes.map(function(axis, i) {
            var log = axis.log && series.every(function(s) { return s.values[i] > 0 })
            var v = series.map(function(s) { return log ? Math.log(s.values[i]) : s.values[i] })
            var lo = Math.min.apply(null, v), hi = Math.max.apply(null, v)
            return v.map(function(x) { return hi > lo ? 0.12 + 0.88 * (x - lo) / (hi - lo) : 0.56 })
        })
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var n = root.axes.length
            if (n < 3 || root.series.length === 0) {
                root.__labels = []
                root.__points = []
                return
            }
            var cx = width / 2, cy = height / 2 + 4
            var R = Math.min(width / 2 - 90, height / 2 - 34)
            var angle = function(i) { return -Math.PI / 2 + i * 2 * Math.PI / n }
            var at = function(i, r) { return [cx + Math.cos(angle(i)) * R * r, cy + Math.sin(angle(i)) * R * r] }

            // Rings and spokes
            ctx.strokeStyle = Theme.border
            ctx.lineWidth = 1
            ;[0.25, 0.5, 0.75, 1].forEach(function(r) {
                ctx.beginPath()
                for (var i = 0; i < n; i++) {
                    var p = at(i, r)
                    if (i === 0) ctx.moveTo(p[0], p[1]); else ctx.lineTo(p[0], p[1])
                }
                ctx.closePath()
                ctx.stroke()
            })
            var labels = []
            for (var i = 0; i < n; i++) {
                var p = at(i, 1)
                ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(p[0], p[1]); ctx.stroke()
                var q = at(i, 1.12)
                labels.push({"t": root.axes[i].name, "x": q[0], "y": q[1],
                             "align": Math.abs(q[0] - cx) < 10 ? "center" : (q[0] > cx ? "left" : "right"),
                             "bold": root.axes[i].bold === true})
            }

            // Series: tinted shape, outline and markers
            var scaled = root.__scaled()
            var points = []
            root.series.forEach(function(s, j) {
                var pts = []
                for (var i = 0; i < n; i++)
                    pts.push(at(i, scaled[i][j]))
                ctx.beginPath()
                pts.forEach(function(p, i) { if (i === 0) ctx.moveTo(p[0], p[1]); else ctx.lineTo(p[0], p[1]) })
                ctx.closePath()
                ctx.fillStyle = s.color
                ctx.globalAlpha = 0.12
                ctx.fill()
                ctx.globalAlpha = 1
                ctx.strokeStyle = s.color
                ctx.lineWidth = 2
                ctx.stroke()
                pts.forEach(function(p, i) {
                    root.__marker(ctx, root.shapes[j % root.shapes.length], p[0], p[1], s.color)
                    points.push({"x": p[0], "y": p[1], "series": s.name, "axis": root.axes[i].name, "text": s.texts[i]})
                })
            })
            root.__labels = labels
            root.__points = points
        }
    }

    function __marker(ctx, shape, x, y, color) {
        ctx.fillStyle = color
        ctx.strokeStyle = Theme.surface
        ctx.lineWidth = 2
        ctx.beginPath()
        if (shape === "square")
            ctx.rect(x - 4.5, y - 4.5, 9, 9)
        else if (shape === "triangle") {
            ctx.moveTo(x, y - 6); ctx.lineTo(x + 5.5, y + 4); ctx.lineTo(x - 5.5, y + 4); ctx.closePath()
        }
        else if (shape === "diamond") {
            ctx.moveTo(x, y - 6); ctx.lineTo(x + 6, y); ctx.lineTo(x, y + 6); ctx.lineTo(x - 6, y); ctx.closePath()
        }
        else
            ctx.arc(x, y, 5, 0, 2 * Math.PI)
        ctx.fill()
        ctx.stroke()
    }

    // Axis names as Text items: the Canvas fills glyphs with holes where their strokes overlap
    Repeater {
        model: root.__labels
        delegate: Text {
            required property var modelData
            text: modelData.t
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeMeta
            font.weight: modelData.bold ? Font.Bold : Font.Normal
            color: Theme.textPrimary
            x: modelData.align === "center" ? modelData.x - implicitWidth / 2
               : (modelData.align === "right" ? modelData.x - implicitWidth : modelData.x)
            y: modelData.y - implicitHeight / 2
        }
    }

    // Hover: the value at the nearest marker
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        property var hit_: null
        onPositionChanged: {
            var best = null, best_d = 144
            root.__points.forEach(function(p) {
                var d = (p.x - mouse.x) * (p.x - mouse.x) + (p.y - mouse.y) * (p.y - mouse.y)
                if (d < best_d) { best_d = d; best = p }
            })
            hit_ = best
        }
        onExited: hit_ = null
    }
    Rectangle {
        visible: mouse.hit_ !== null
        x: mouse.hit_ ? Math.max(0, Math.min(mouse.hit_.x + 12, root.width - width)) : 0
        y: mouse.hit_ ? Math.max(0, mouse.hit_.y - height - 8) : 0
        width: tip.implicitWidth + 2 * Theme.space3
        height: tip.implicitHeight + 2 * Theme.space2
        radius: Theme.radiusSm
        color: Theme.overlay
        border.width: 1
        border.color: Theme.borderStrong
        z: 2
        Text {
            id: tip
            anchors.centerIn: parent
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeMeta
            color: Theme.textPrimary
            text: mouse.hit_ ? mouse.hit_.series + "\n" + mouse.hit_.axis + ": " + mouse.hit_.text : ""
        }
    }
}
