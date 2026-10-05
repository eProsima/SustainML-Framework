// Native architecture visualization of one U-Net model: U-shaped diagram,
// summary tiles, compute share, comparison with the original U-Net, settings
// explanation and full layer table. The structure is derived from the model's
// unet_models_info.jsonl entry by utils/UnetModel.js.

import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

import "../utils/UnetModel.js" as UnetModel

Item {
    id: root

    // Public properties
    property var info: null                     // one entry of unet_models_info.jsonl

    // Public signals
    signal open_in_browser(string model_name)

    // Derived model (null when info is missing or malformed)
    readonly property var model: UnetModel.isValid(info) ? UnetModel.buildModel(info) : null
    readonly property var layout: model ? __compute_layout(model) : null

    implicitHeight: content.implicitHeight

    // Palette (light / night)
    readonly property bool __night: ScreenManager.night_mode
    readonly property color c_card:         __night ? "#303030" : "white"
    readonly property color c_surface:      __night ? "#3a3f3a" : "#eef1ee"
    readonly property color c_border:       __night ? "#4a524a" : "#d3dbd2"
    readonly property color c_text:         __night ? "#e6ebe5" : "#263026"
    readonly property color c_muted:        __night ? "#a3b0a2" : "#5d6b5d"
    readonly property color c_map_fill:     __night ? "#34512a" : "#d7ecc9"
    readonly property color c_map_stroke:   __night ? "#9fd97e" : "#3f6a2b"
    readonly property color c_bottleneck:   __night ? "#4b7a36" : "#a9d68f"
    readonly property color c_input_fill:   __night ? "#3a4450" : "#dfe4ea"
    readonly property color c_input_stroke: __night ? "#a8b6c6" : "#5b6b7d"
    readonly property color c_output_fill:  __night ? "#b6d816" : Settings.app_color_green_3
    readonly property color c_output_stroke:__night ? "#e6ebe5" : Settings.app_color_dark
    readonly property color c_k3:           __night ? "#6fa8e0" : Settings.app_color_blue
    readonly property color c_k5:           __night ? "#f0a040" : "#c26a00"
    readonly property color c_pool:         __night ? "#ef6f66" : "#b3261e"
    readonly property color c_up:           __night ? "#7cc257" : "#3d8a1f"
    readonly property color c_skip:         __night ? "#7a857a" : "#9aa39a"
    readonly property color c_1x1:          __night ? "#4fc4c4" : "#0f7c7c"
    readonly property color c_bar:          Settings.app_color_green_2
    readonly property color c_link:         __night ? "#9fd97e" : "#3d8a1f"   // same green as highlighted values; links are underlined
    readonly property color c_diff:         __night ? "#9fd97e" : "#3d8a1f"   // values that differ from the original U-Net
    readonly property color c_highlight:    Settings.app_color_green_3

    readonly property int __gap: Settings.spacing_normal
    property bool layers_expanded: false
    onInfoChanged: layers_expanded = false
    readonly property bool __wide: width >= 900

    function __color_of(key) {
        switch (key) {
            case "k3":   return c_k3
            case "k5":   return c_k5
            case "pool": return c_pool
            case "up":   return c_up
            case "skip": return c_skip
            case "1x1":  return c_1x1
        }
        return c_muted
    }

    // Diagram geometry, in unscaled diagram coordinates (same layout as the browser page)
    function __compute_layout(m) {
        var d = m.info.depth, S = m.info.input_size
        var GAP = 34, PAD_L = 40, PAD_R = 40, PAD_T = 34, LEVEL_GAP = 46
        // Block height is log-scaled with resolution so 8x8 and 512x512 both stay readable
        var hOf = function(res) { return Math.round(26 + 22 * Math.log(res / 4) / Math.LN2) }
        var wOf = function(ch) { return Math.round(6 + 5.2 * Math.log(Math.max(ch, 1)) / Math.LN2) }

        var levelY = [], y = PAD_T, l, i
        for (l = 0; l <= d; l++) {
            var h = hOf(S >> l)
            levelY[l] = y + h / 2   // centre line
            y += h + LEVEL_GAP
        }
        var height = y - LEVEL_GAP + 34

        // Assign x positions sequentially, like the original paper's figure
        var boxes = [], x = PAD_L
        for (i = 0; i < m.maps.length; i++) {
            var b = m.maps[i]
            var w = b.kind === "concat" ? wOf(b.skipCh) + wOf(b.upCh) : wOf(b.ch)
            var bh = hOf(b.res)
            boxes.push({ map: b, x: x, y: levelY[b.level] - bh / 2, w: w, h: bh,
                         wSkip: b.kind === "concat" ? wOf(b.skipCh) : 0 })
            x += w + GAP
        }
        var width = x - GAP + PAD_R

        var arrows = [], labels = []
        var kKey = function(k) { return k === 5 ? "k5" : "k3" }

        // Last encoder block of each level, source of the skip connections
        var encLast = {}
        for (i = 0; i < boxes.length; i++) {
            var cur = boxes[i].map, nxt = boxes[i + 1] ? boxes[i + 1].map : null
            if (cur.kind === "enc" && (!nxt || nxt.kind !== "enc" || nxt.level !== cur.level)) encLast[cur.level] = boxes[i]
        }

        for (i = 1; i < boxes.length; i++) {
            var a = boxes[i - 1], t = boxes[i]
            var ax = a.x + a.w, ay = levelY[a.map.level]
            if (t.map.level === a.map.level) {
                // same level: conv (or 1x1) arrow
                var key = t.map.kind === "output" ? "1x1" : kKey(t.map.k)
                arrows.push({ pts: [[ax + 2, ay], [t.x - 3, ay]], key: key, dashed: false })
                labels.push({ x: (ax + t.x) / 2, y: ay - 19, text: t.map.kind === "output" ? "1×1" : UnetModel.kx(t.map.k),
                              key: key, bold: true, align: "center" })
            } else if (t.map.level > a.map.level) {
                // going down: max-pool, followed by the first conv of the next level
                var sx = a.x + a.w / 2, ty = levelY[t.map.level]
                arrows.push({ pts: [[sx, a.y + a.h + 3], [sx, ty], [t.x - 3, ty]], key: "pool", dashed: false })
                labels.push({ x: (sx + t.x) / 2 + 4, y: ty - 19, text: UnetModel.kx(t.map.k), key: kKey(t.map.k), bold: true, align: "center" })
            } else {
                // going up: transposed conv into the concat block
                var tx = t.x + t.w - (t.w - t.wSkip) / 2
                arrows.push({ pts: [[ax + 2, ay], [tx, ay], [tx, t.y + t.h + 3]], key: "up", dashed: false })
            }
        }

        // Skip connections (copy)
        for (i = 0; i < boxes.length; i++) {
            if (boxes[i].map.kind !== "concat") continue
            var src = encLast[boxes[i].map.level]
            if (!src) continue
            var yy = levelY[boxes[i].map.level]
            arrows.push({ pts: [[src.x + src.w + 4, yy], [boxes[i].x - 3, yy]], key: "skip", dashed: true })
        }

        // Channel count above every block
        for (i = 0; i < boxes.length; i++) {
            labels.push({ x: boxes[i].x + boxes[i].w / 2, y: boxes[i].y - 18, text: String(boxes[i].map.ch),
                          key: "", bold: true, align: "center", strong: true })
        }

        // Resolution, once per level under its first feature map
        for (l = 0; l <= d; l++) {
            for (i = 0; i < boxes.length; i++) {
                if (boxes[i].map.level === l) {
                    var r = S >> l
                    labels.push({ x: boxes[i].x + boxes[i].w / 2, y: boxes[i].y + boxes[i].h + 3, text: r + "×" + r,
                                  key: "", bold: false, align: "center" })
                    break
                }
            }
        }

        return { width: width, height: height, boxes: boxes, arrows: arrows, labels: labels }
    }

    // Reusable pieces
    component Card: Rectangle {
        color: root.c_card
        radius: 14
        border.color: root.c_border
        border.width: 1
        default property alias contents: card_column.data
        property alias spacing: card_column.spacing
        implicitHeight: card_column.implicitHeight + 2 * 18
        Column {
            id: card_column
            x: 20; y: 18
            width: parent.width - 40
            spacing: 10
        }
    }

    component Heading: Text {
        color: root.c_text
        font.family: SustainMLFont.title_font
        font.pixelSize: Settings.header3_font_size
        font.bold: true
        width: parent ? parent.width : implicitWidth
        wrapMode: Text.WordWrap
    }

    component Body: Text {
        color: root.c_text
        font.family: SustainMLFont.body_font
        font.pixelSize: Settings.body_font_size
        width: parent ? parent.width : implicitWidth
        wrapMode: Text.WordWrap
        textFormat: Text.StyledText
        linkColor: root.c_link
        onLinkActivated: Qt.openUrlExternally(link)
        // hand cursor over links, clicks still reach the Text
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }

    component Muted: Body {
        color: root.c_muted
        font.pixelSize: 12
    }

    function __hl(text) {
        return "<b><font color=\"" + c_diff + "\">" + text + "</font></b>"
    }

    Column {
        id: content
        width: root.width
        spacing: root.__gap
        visible: root.model !== null

        // ----------------------------------------------------------------- Header
        Item {
            width: parent.width
            height: Math.max(header_left.implicitHeight, browser_button.height)

            Column {
                id: header_left
                anchors.left: parent.left
                anchors.right: browser_button.left
                anchors.rightMargin: root.__gap
                spacing: 6

                Text {
                    text: root.model ? root.model.name : ""
                    color: root.c_text
                    font.family: SustainMLFont.title_font
                    font.pixelSize: Settings.header2_font_size
                    font.bold: true
                }

                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: root.model ? [
                            ["Input", root.info.input_size + "×" + root.info.input_size + "×" + root.info.input_channels],
                            ["Depth", String(root.info.depth)],
                            ["Initial channels", String(root.info.initial_channels)],
                            ["Kernels", "[" + root.info.kernel_sizes.join(", ") + "]"]
                        ] : []
                        delegate: Rectangle {
                            id: chip
                            required property var modelData
                            height: 24
                            width: chip_text.implicitWidth + 20
                            radius: 12
                            color: root.c_surface
                            border.color: root.c_border
                            Text {
                                id: chip_text
                                anchors.centerIn: parent
                                text: chip.modelData[0] + " <b>" + chip.modelData[1] + "</b>"
                                textFormat: Text.StyledText
                                color: root.c_muted
                                font.family: SustainMLFont.body_font
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            SmlButton {
                id: browser_button
                anchors.right: parent.right
                anchors.top: parent.top
                icon_name: Settings.browse_icon_name
                text_kind: SmlText.TextKind.Header_2
                text_value: "Open in browser"
                rounded: true
                color: Settings.app_color_green_4
                color_pressed: Settings.app_color_green_1
                color_text: Settings.app_color_green_3
                nightmode_color: Settings.app_color_green_2
                nightmode_color_pressed: Settings.app_color_green_3
                nightmode_color_text: Settings.app_color_green_1
                tooltip_text: "Open this visualization as a web page, e.g. to share or print it"
                onClicked: if (root.model) root.open_in_browser(root.model.name)
            }
        }

        // ----------------------------------------------------------------- Diagram
        Card {
            width: parent.width

            Heading { text: "Architecture" }
            Muted {
                text: "Each box is a feature map: its height follows the spatial resolution (log scale), its width the number of channels (log scale, exact count above it). Hover a box for details."
            }

            Item {
                id: diagram
                width: parent.width
                readonly property real natural_w: root.layout ? root.layout.width : 1
                readonly property real natural_h: root.layout ? root.layout.height : 1
                readonly property real scale_factor: Math.min(1.25, width / natural_w)
                height: natural_h * scale_factor

                Item {
                    id: diagram_canvas_root
                    x: (diagram.width - diagram.natural_w * diagram.scale_factor) / 2
                    width: diagram.natural_w
                    height: diagram.natural_h
                    scale: diagram.scale_factor
                    transformOrigin: Item.TopLeft

                    // Arrows
                    Canvas {
                        id: arrows_canvas
                        anchors.fill: parent
                        antialiasing: true

                        Connections {
                            target: root
                            function onLayoutChanged() { arrows_canvas.requestPaint() }
                            function on__nightChanged() { arrows_canvas.requestPaint() }
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            if (!root.layout)
                                return
                            var arrows = root.layout.arrows
                            for (var i = 0; i < arrows.length; i++) {
                                var a = arrows[i], pts = a.pts
                                var col = root.__color_of(a.key)
                                ctx.strokeStyle = col
                                ctx.fillStyle = col
                                ctx.lineWidth = 2
                                ctx.beginPath()
                                for (var p = 1; p < pts.length; p++) {
                                    var x0 = pts[p - 1][0], y0 = pts[p - 1][1], x1 = pts[p][0], y1 = pts[p][1]
                                    if (a.dashed) {
                                        // manual dashes: 5 on, 4 off
                                        var len = Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
                                        var ux = (x1 - x0) / len, uy = (y1 - y0) / len
                                        for (var s = 0; s < len - 7; s += 9) {
                                            ctx.moveTo(x0 + ux * s, y0 + uy * s)
                                            ctx.lineTo(x0 + ux * Math.min(s + 5, len - 7), y0 + uy * Math.min(s + 5, len - 7))
                                        }
                                    } else {
                                        if (p === 1) ctx.moveTo(x0, y0)
                                        // stop the line where the arrow head starts
                                        var last = p === pts.length - 1
                                        var dl = Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
                                        var cut = last ? Math.min(6, dl) / dl : 0
                                        ctx.lineTo(x1 - (x1 - x0) * cut, y1 - (y1 - y0) * cut)
                                    }
                                }
                                ctx.stroke()

                                // arrow head
                                var e = pts[pts.length - 1], f = pts[pts.length - 2]
                                var ang = Math.atan2(e[1] - f[1], e[0] - f[0])
                                ctx.beginPath()
                                ctx.moveTo(e[0], e[1])
                                ctx.lineTo(e[0] - 9 * Math.cos(ang) + 4.5 * Math.sin(ang), e[1] - 9 * Math.sin(ang) - 4.5 * Math.cos(ang))
                                ctx.lineTo(e[0] - 9 * Math.cos(ang) - 4.5 * Math.sin(ang), e[1] - 9 * Math.sin(ang) + 4.5 * Math.cos(ang))
                                ctx.closePath()
                                ctx.fill()
                            }
                        }
                    }

                    // Feature maps
                    Repeater {
                        model: root.layout ? root.layout.boxes : []
                        delegate: Item {
                            id: box
                            required property var modelData
                            readonly property var fmap: modelData.map
                            x: modelData.x
                            y: modelData.y
                            width: modelData.w
                            height: modelData.h

                            // copied (skip) part of a concat block
                            Rectangle {
                                visible: box.fmap.kind === "concat"
                                width: box.modelData.wSkip
                                height: parent.height
                                radius: 2
                                color: root.c_card
                                border.width: box_mouse.containsMouse ? 2.5 : 1.5
                                border.color: root.c_map_stroke
                                // dashed look: thin gaps over the border
                                Column {
                                    anchors.fill: parent
                                    spacing: 3
                                    clip: true
                                    Repeater {
                                        model: Math.floor(box.height / 5)
                                        delegate: Item {
                                            width: parent ? parent.width : 0
                                            height: 2
                                            Rectangle { x: 0; width: 2; height: 2; color: root.c_card }
                                            Rectangle { anchors.right: parent.right; width: 2; height: 2; color: root.c_card }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                x: box.fmap.kind === "concat" ? box.modelData.wSkip : 0
                                width: parent.width - x
                                height: parent.height
                                radius: 2
                                color: box.fmap.kind === "input" ? root.c_input_fill
                                     : box.fmap.kind === "output" ? root.c_output_fill
                                     : box.fmap.kind === "bottleneck" ? root.c_bottleneck
                                     : root.c_map_fill
                                border.width: box_mouse.containsMouse ? 2.5 : 1.5
                                border.color: box.fmap.kind === "input" ? root.c_input_stroke
                                            : box.fmap.kind === "output" ? root.c_output_stroke
                                            : root.c_map_stroke
                            }

                            MouseArea {
                                id: box_mouse
                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                onEntered: diagram_tooltip.show_for(box.fmap, box_mouse)
                                onPositionChanged: diagram_tooltip.move_to(box_mouse, mouse.x, mouse.y)
                                onExited: diagram_tooltip.close()
                            }
                        }
                    }

                    // Labels: channels, kernels, resolutions
                    Repeater {
                        model: root.layout ? root.layout.labels : []
                        delegate: Text {
                            id: label
                            required property var modelData
                            x: modelData.x - implicitWidth / 2
                            y: modelData.y
                            text: modelData.text
                            color: modelData.key !== "" ? root.__color_of(modelData.key)
                                 : modelData.strong ? root.c_text : root.c_muted
                            font.family: SustainMLFont.body_font
                            font.pixelSize: 11
                            font.bold: modelData.bold
                        }
                    }
                }

                ToolTip {
                    id: diagram_tooltip
                    property var fmap: null
                    delay: 0
                    padding: 10

                    function show_for(fmap, area) {
                        diagram_tooltip.fmap = fmap
                        var lines = ["<b>" + fmap.title + "</b>", "<font color=\"#c8d0c8\">" + fmap.op + "</font>"]
                        if (fmap.kind === "concat")
                            lines.push("Copied + upsampled: <b>" + fmap.skipCh + " + " + fmap.upCh + " ch</b>")
                        lines.push("Shape (C×H×W): <b>" + UnetModel.shapeStr(fmap.ch, fmap.res) + "</b>")
                        lines.push("Memory (float32): <b>" + UnetModel.fmtBytes(fmap.ch * fmap.res * fmap.res * 4) + "</b>")
                        if (fmap.params !== undefined) {
                            lines.push("Parameters: <b>" + UnetModel.fmtInt(fmap.params) + "</b>")
                            lines.push("MACs: <b>" + UnetModel.fmtCount(fmap.macs) + "</b>")
                        }
                        text = lines.join("<br>")
                        move_to(area, area.mouseX, area.mouseY)
                        open()
                    }
                    function move_to(area, mx, my) {
                        var p = area.mapToItem(diagram, mx, my)
                        var nx = p.x + 14
                        if (nx + implicitWidth > diagram.width) nx = p.x - implicitWidth - 14
                        x = Math.max(0, nx)
                        y = p.y + 16
                    }

                    background: Rectangle {
                        color: Qt.rgba(0.18, 0.18, 0.18, 0.92)
                        radius: 8
                    }
                    contentItem: Text {
                        text: diagram_tooltip.text
                        textFormat: Text.StyledText
                        color: "white"
                        font.family: SustainMLFont.body_font
                        font.pixelSize: 12
                        lineHeight: 1.15
                    }
                }
            }

            // Legend
            Flow {
                width: parent.width
                spacing: 16
                Repeater {
                    model: [
                        ["k3", "Conv 3×3 + ReLU", "line"], ["k5", "Conv 5×5 + ReLU", "line"],
                        ["pool", "Max-pool 2×2", "line"], ["up", "Transposed conv 2×2", "line"],
                        ["skip", "Skip connection (copy)", "dash"], ["1x1", "Conv 1×1", "line"],
                        ["", "Copied feature map", "copy"], ["", "Output mask", "output"]
                    ]
                    delegate: Row {
                        id: legend_item
                        required property var modelData
                        spacing: 6
                        Item {
                            width: 26; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            Row {
                                visible: legend_item.modelData[2] === "line" || legend_item.modelData[2] === "dash"
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: legend_item.modelData[2] === "dash" ? 3 : 0
                                Repeater {
                                    model: legend_item.modelData[2] === "dash" ? 3 : 1
                                    delegate: Rectangle {
                                        width: legend_item.modelData[2] === "dash" ? 4 : 18
                                        height: 2
                                        color: root.__color_of(legend_item.modelData[0])
                                    }
                                }
                            }
                            Text {
                                visible: legend_item.modelData[2] === "line" || legend_item.modelData[2] === "dash"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▶"
                                font.pixelSize: 9
                                color: root.__color_of(legend_item.modelData[0])
                            }
                            Rectangle {
                                visible: legend_item.modelData[2] === "copy" || legend_item.modelData[2] === "output"
                                width: 14; height: 12; radius: 2
                                anchors.centerIn: parent
                                color: legend_item.modelData[2] === "output" ? root.c_output_fill : root.c_card
                                border.color: legend_item.modelData[2] === "output" ? root.c_output_stroke : root.c_map_stroke
                                border.width: 1.5
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: legend_item.modelData[1]
                            color: root.c_muted
                            font.family: SustainMLFont.body_font
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------------------- Tiles
        Flow {
            id: tiles
            width: parent.width
            spacing: root.__gap
            readonly property int per_row: root.width >= 1100 ? 5 : root.width >= 700 ? 3 : 2
            readonly property real tile_w: (width - (per_row - 1) * spacing) / per_row

            Repeater {
                model: root.model ? [
                    { label: "Parameters", value: UnetModel.fmtCount(root.model.params),
                      // shown only on a mismatch: the reconstructed layout disagrees with the metadata
                      note: UnetModel.fmtInt(root.model.params) + (root.model.paramsMatch ? ""
                            : " · <font color=\"" + root.c_pool + "\"><b>metadata says " + root.info.Mparams
                              + " M: this model may not follow the standard layout, so the graph may be inaccurate</b></font>") },
                    { label: "Compute (MACs)", value: UnetModel.fmtCount(root.model.macs),
                      note: "Metadata: " + root.info.Mflops.toFixed(1) + " MFLOPs*" },
                    { label: "Receptive field", value: root.model.rf + "×" + root.model.rf + " px",
                      note: root.model.rf >= root.info.input_size ? "covers the whole input tile"
                            : Math.round(100 * root.model.rf / root.info.input_size) + "% of the input width" },
                    { label: "Largest feature map", value: UnetModel.fmtBytes(root.model.peak), note: "float32, single image" },
                    { label: "Layers", value: root.model.convCount + " conv",
                      note: root.info.depth + " max-pool, " + root.info.depth + " transposed conv" }
                ] : []
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    width: tiles.tile_w
                    height: tile_col.implicitHeight + 24
                    radius: 12
                    color: root.c_card
                    border.color: root.c_border
                    Column {
                        id: tile_col
                        x: 14; y: 12
                        width: parent.width - 28
                        spacing: 2
                        Text {
                            text: tile.modelData.label.toUpperCase()
                            color: root.c_muted
                            font.family: SustainMLFont.body_font
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.6
                        }
                        Text {
                            text: tile.modelData.value
                            color: root.c_text
                            font.family: SustainMLFont.title_font
                            font.pixelSize: 22
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: tile.modelData.note
                            textFormat: Text.StyledText
                            color: root.c_muted
                            font.family: SustainMLFont.body_font
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------------------- Compute share + comparison
        Flow {
            width: parent.width
            spacing: root.__gap
            readonly property real half_w: root.__wide ? (width - spacing) / 2 : width

            Card {
                width: parent.half_w
                height: root.__wide ? Math.max(implicitHeight, comparison_card.implicitHeight) : implicitHeight

                Heading { text: "Where the compute goes" }
                Muted { text: "Share of multiply-accumulate operations per stage. High-resolution stages usually dominate." }

                Repeater {
                    model: root.model ? root.model.stages : []
                    delegate: Item {
                        id: bar_row
                        required property var modelData
                        readonly property real pct: 100 * modelData.macs / root.model.macs
                        width: parent ? parent.width : 0
                        height: 22
                        Text {
                            id: bar_label
                            width: 120
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar_row.modelData.name
                            color: root.c_text
                            font.family: SustainMLFont.body_font
                            font.pixelSize: 12
                        }
                        Rectangle {
                            id: bar_track
                            anchors.left: bar_label.right
                            anchors.right: bar_num.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            height: 14
                            radius: 4
                            color: root.c_surface
                            Rectangle {
                                width: parent.width * bar_row.pct / 100
                                height: parent.height
                                radius: 4
                                color: root.c_bar
                            }
                        }
                        Text {
                            id: bar_num
                            width: 54
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: (bar_row.pct > 0 && bar_row.pct < 0.1 ? "<0.1" : bar_row.pct.toFixed(1)) + "%"
                            color: root.c_muted
                            font.family: SustainMLFont.body_font
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Card {
                id: comparison_card
                width: parent.half_w

                Heading { text: "Compared with the original U-Net" }
                Muted { text: "Ronneberger et al., 2015 (Fig. 1). <font color=\"" + root.c_diff + "\"><b>Highlighted</b></font> values differ." }

                Repeater {
                    model: root.model ? (function() {
                        var i = root.info, m = root.model, K = i.kernel_sizes, d = i.depth, O = UnetModel.ORIGINAL
                        var allThree = K.every(function(k) { return k === 3 })
                        return [
                            ["", "Original", "This model", false, true],
                            ["Input", O.input, i.input_size + "×" + i.input_size + "×" + i.input_channels, true],
                            ["Output", O.output, i.input_size + "×" + i.input_size + "×1", true],
                            ["Padding", "none, maps shrink and skips are cropped", "\"same\", no cropping", true],
                            ["Kernels", O.kernels, "[" + K.join(", ") + "] per level", !allThree],
                            ["Pooling steps", String(O.levels), String(d), d !== O.levels],
                            ["Encoder channels", O.channels, m.encCh.join(" → "), true],
                            ["Bottleneck", O.bottleneck, (i.initial_channels << d) + " (not doubled)", true],
                            ["Upsampling", "2×2 up-conv halves channels", "2×2 up-conv keeps channels", true],
                            ["Conv layers", String(O.convLayers), String(m.convCount), m.convCount !== O.convLayers],
                            ["Parameters", UnetModel.fmtCount(O.params),
                             UnetModel.fmtCount(m.params) + " (" + (100 * m.params / O.params).toFixed(2) + "%)", true]
                        ]
                    })() : []
                    delegate: Item {
                        id: cmp_row
                        required property var modelData
                        readonly property bool header: modelData.length > 4
                        width: parent ? parent.width : 0
                        height: Math.max(c0.implicitHeight, c1.implicitHeight, c2.implicitHeight) + 10
                        Text {
                            id: c0
                            width: parent.width * 0.26
                            y: 5
                            text: cmp_row.modelData[0]
                            color: root.c_text
                            font.family: SustainMLFont.body_font
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            id: c1
                            x: parent.width * 0.27
                            width: parent.width * 0.37
                            y: 5
                            text: cmp_row.header ? cmp_row.modelData[1].toUpperCase() : cmp_row.modelData[1]
                            color: cmp_row.header ? root.c_muted : root.c_text
                            font.family: SustainMLFont.body_font
                            font.pixelSize: cmp_row.header ? 11 : 12
                            font.bold: cmp_row.header
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            id: c2
                            x: parent.width * 0.65
                            width: parent.width * 0.35
                            y: 5
                            text: cmp_row.header ? cmp_row.modelData[2].toUpperCase() : cmp_row.modelData[2]
                            color: cmp_row.header ? root.c_muted : cmp_row.modelData[3] ? root.c_diff : root.c_text
                            font.family: SustainMLFont.body_font
                            font.pixelSize: cmp_row.header ? 11 : 12
                            font.bold: cmp_row.header || cmp_row.modelData[3]
                            wrapMode: Text.WordWrap
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: root.c_border
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------------------- Explanation
        Card {
            width: parent.width
            spacing: 10

            Heading { text: "What this model is for, and what its settings mean" }

            Body {
                text: "A U-Net labels <b>every pixel</b> of an image (semantic segmentation). The encoder, on the left, shrinks the image to gather context. The decoder, on the right, grows it back to full resolution. The skip connections carry fine detail across, so object borders stay sharp. The design comes from biomedical image segmentation and is now common for medical scans, satellite imagery, industrial defect inspection and similar tasks."
            }
            Body {
                text: "This model ends in a single output channel, so it produces <b>one value per pixel</b>. For a U-Net this is typically a binary mask (foreground vs. background), although one channel could also hold a per-pixel regression. The graph has no final activation and returns raw scores. For a mask, a sigmoid and a threshold are applied afterwards."
            }
            Body {
                visible: root.model !== null
                text: !root.model ? "" :
                    "• <b>Input size</b> (" + root.__hl(root.info.input_size + "×" + root.info.input_size) + "): the tile the model processes at once. Doubling it quadruples the compute, because every layer is a convolution. Larger tiles keep finer detail per image.<br><br>" +
                    "• <b>Depth</b> (" + root.__hl(root.info.depth + (root.info.depth === 1 ? " level" : " levels")) + "): each extra level halves the resolution once more. This widens how far each pixel can \"see\" (here " + root.model.rf + "×" + root.model.rf + " px), which helps with large objects. A new level has a quarter of the pixels but twice the channels of the level above it, so it costs about as much compute as the other levels and adds many more parameters. Among these models, one extra level multiplies compute by 1.2 to 3 and parameters by 2.6 to 8.<br><br>" +
                    "• <b>Initial channels</b> (" + root.__hl(String(root.info.initial_channels)) + "): the width of the network, i.e. its capacity. Doubling it roughly quadruples both parameters and compute. The first encoder level already uses " + (root.info.initial_channels << 1) + " channels. <i>initial_channels</i> only appears at the last decoder level.<br><br>" +
                    "• <b>Kernel sizes</b> (" + root.__hl("[" + root.info.kernel_sizes.join(", ") + "]") + "): one per encoder level plus the bottleneck. The decoder reuses the kernel of the matching encoder level. A 5×5 kernel sees more context than 3×3, but costs about 2.8× as much per layer."
            }
        }

        // ----------------------------------------------------------------- Layer table
        // (expanded flag lives on root: declaring a property on a Card instance breaks its default-property routing in Qt 5.15)
        Card {
            id: layers_card
            width: parent.width

            Item {
                width: parent.width
                height: layers_heading.implicitHeight
                Heading {
                    id: layers_heading
                    text: (root.layers_expanded ? "▾  " : "▸  ") + "All layers"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.layers_expanded = !root.layers_expanded
                }
            }

            Column {
                visible: root.layers_expanded
                width: parent.width

                Repeater {
                    model: !(root.model && root.layers_expanded) ? [] : (function() {
                        var m = root.model, rows = [], last = ""
                        rows.push({ kind: "head", cells: ["Operation", "In ch", "Out ch", "Output H×W", "Parameters", "MACs"] })
                        rows.push({ kind: "stage", cells: ["Input"] })
                        rows.push({ kind: "row", cells: ["RGB image", "", String(root.info.input_channels), root.info.input_size + "×" + root.info.input_size, "", ""] })
                        for (var i = 0; i < m.ops.length; i++) {
                            var o = m.ops[i]
                            if (o.stage !== last) { rows.push({ kind: "stage", cells: [o.stage] }); last = o.stage }
                            rows.push({ kind: "row", cells: [o.op, String(o.cin), String(o.cout), o.res + "×" + o.res,
                                                             o.params ? UnetModel.fmtInt(o.params) : "", o.macs ? UnetModel.fmtCount(o.macs) : ""] })
                        }
                        rows.push({ kind: "total", cells: ["Total", "", "", "", UnetModel.fmtInt(m.params), UnetModel.fmtCount(m.macs)] })
                        return rows
                    })()
                    delegate: Rectangle {
                        id: layer_row
                        required property var modelData
                        readonly property var widths: [0.36, 0.1, 0.1, 0.14, 0.15, 0.15]
                        width: parent ? parent.width : 0
                        height: 26
                        color: modelData.kind === "stage" || modelData.kind === "total" ? root.c_surface : "transparent"
                        Repeater {
                            model: layer_row.modelData.cells.length
                            delegate: Text {
                                id: cell
                                required property int index
                                x: {
                                    var s = 0
                                    for (var i = 0; i < cell.index; i++) s += layer_row.widths[i]
                                    return s * layer_row.width + 6
                                }
                                width: (layer_row.modelData.kind === "stage" ? 1 : layer_row.widths[cell.index]) * layer_row.width - 12
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: cell.index > 0 ? Text.AlignRight : Text.AlignLeft
                                text: layer_row.modelData.kind === "head" ? layer_row.modelData.cells[cell.index].toUpperCase()
                                                                          : layer_row.modelData.cells[cell.index]
                                color: layer_row.modelData.kind === "head" ? root.c_muted
                                     : layer_row.modelData.kind === "row" ? root.c_text : root.c_diff
                                font.family: SustainMLFont.body_font
                                font.pixelSize: layer_row.modelData.kind === "head" ? 11 : 12
                                font.bold: layer_row.modelData.kind !== "row"
                                elide: Text.ElideRight
                            }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: root.c_border
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------------------- Footnote
        Muted {
            width: parent.width
            textFormat: Text.RichText   // StyledText does not underline links
            text: "* <i>Mflops</i> and <i>Mparams</i> come from unet_models_info.jsonl. The metadata's FLOP figure counts one operation per multiply-accumulate, counts each transposed convolution per output pixel (4× its actual multiply-accumulates here), and adds the ReLU and max-pool operations. That is why it is slightly higher than the MAC count above, and not 2× MACs as in some other FLOP conventions. " +
                  "The layer structure is derived from the metadata and matches the ONNX graphs of all 217 models. " +
                  "Reference: O. Ronneberger, P. Fischer, T. Brox, <a href=\"https://arxiv.org/abs/1505.04597\" style=\"color:" + root.c_link + "\">U-Net: Convolutional Networks for Biomedical Image Segmentation</a>, MICCAI 2015."
        }
    }

    // Shown when the model info is missing (e.g. info file not loaded)
    Text {
        visible: root.model === null
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 60
        text: "No architecture information available for this model."
        color: root.c_muted
        font.family: SustainMLFont.body_font
        font.pixelSize: Settings.body_font_size
    }
}
