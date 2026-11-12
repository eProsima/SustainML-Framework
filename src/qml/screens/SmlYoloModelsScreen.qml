// Library imports
import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"

/*
    The YOLO models of the Axelera board in two views:
      - a matrix of every task and architecture (rows) by size (columns), each cell coloured by the
        CO2 it emits per accuracy point in the chosen country, with a marker where the CO2 jumps
        from one size to the next. Clicking a cell selects its model.
      - for the selected models (at least 10), where extra CO2 stops buying accuracy: CO2 as a
        multiple of the smallest model of the same task against the share of that task's best
        accuracy, with the lines where the curve changes.

    The CO2 of a model is its energy per inference (measured latency x estimated power, from the
    HW resources node) x the grid carbon intensity of the country (from the carbon footprint node).
 */
Item
{
    id: root

    // Data, from the HW resources and carbon footprint nodes
    property var models: []          // one map per model, see Engine::yolo_models_available
    property var intensities: ({})   // ISO alpha-2 code -> {country, year, g_per_kwh}
    property string country: "WORLD"

    // Models selected in the matrix, by name
    property var selected: ({})
    readonly property int selected_count: Object.keys(selected).length
    readonly property int min_selected: 10

    signal go_home()
    signal go_back()
    signal request_data()

    readonly property var sizes_: ["n", "s", "m", "l", "x"]
    readonly property var goal_names_: ({
        "object-detection": "Object detection",
        "oriented-object-detection": "Oriented object detection",
        "instance-segmentation": "Instance segmentation",
        "semantic-segmentation": "Semantic segmentation",
        "keypoint-detection": "Keypoint (pose) detection"
    })
    readonly property var goal_order_: ["object-detection", "oriented-object-detection",
        "instance-segmentation", "semantic-segmentation", "keypoint-detection"]
    // Light to dark: less to more CO2 per accuracy point, 9 steps of the same width on a log scale
    readonly property var ramp_: ["#ffecc9", "#f8d19b", "#f0b56e", "#e69841", "#da7b00",
        "#cc5f00", "#b94200", "#9c3200", "#7a2a01"]
    readonly property int first_dark_step_: 5   // white text from this step on
    readonly property color yolo11_color_: Theme.accentFill
    readonly property color yolo26_color_: "#E09A1A"
    readonly property real jump_ratio_: 1.8   // CO2 x this or more from the previous size
    // Accuracy points (share of the task's best) gained per doubling of CO2 that split the zones
    readonly property real steep_gain_: 10
    readonly property real saturated_gain_: 3

    readonly property real intensity_: intensities[country] ? intensities[country].g_per_kwh : 0
    readonly property string country_name_: intensities[country] ? intensities[country].country : ""
    readonly property var countries_: country_list(intensities)
    readonly property var rows_: build_rows(models)
    readonly property var stats_: catalog_stats(models)

    readonly property bool loaded_: models.length > 0 && Object.keys(intensities).length > 0

    Component.onCompleted: if (!loaded_) root.request_data()

    // The nodes may still be starting: ask again until both answers are in
    Timer {
        interval: 3000
        repeat: true
        running: !root.loaded_ && root.visible
        onTriggered: root.request_data()
    }

    onSelectedChanged: curve_canvas.requestPaint()
    onModelsChanged: curve_canvas.requestPaint()

    // ---------------------------------------------------------------- helpers

    function country_list(map) {
        var list = []
        for (var code in map)
            if (code !== "WORLD")
                list.push({"code": code, "name": map[code].country})
        list.sort(function(a, b) { return a.name.localeCompare(b.name) })
        if (map["WORLD"])
            list.unshift({"code": "WORLD", "name": map["WORLD"].country})
        return list
    }

    function country_code(name) {
        for (var i = 0; i < countries_.length; i++)
            if (countries_[i].name === name)
                return countries_[i].code
        return ""
    }

    // Rows of the matrix: each task with each architecture it has, cells by size (null if absent)
    function build_rows(list) {
        var rows = []
        goal_order_.forEach(function(goal) {
            ["YOLO11", "YOLO26"].forEach(function(arch) {
                var cells = sizes_.map(function(size) {
                    for (var i = 0; i < list.length; i++)
                        if (list[i].goal === goal && list[i].architecture === arch && list[i].size === size)
                            return list[i]
                    return null
                })
                if (cells.some(function(c) { return c !== null }))
                    rows.push({"goal": goal, "architecture": arch, "cells": cells})
            })
        })
        return rows
    }

    // Per task: the smallest energy and the best accuracy, and where the accuracy curve changes
    function catalog_stats(list) {
        var min_energy = {}, best_acc = {}
        list.forEach(function(m) {
            if (min_energy[m.goal] === undefined || m.energy_per_inference_j < min_energy[m.goal])
                min_energy[m.goal] = m.energy_per_inference_j
            if (best_acc[m.goal] === undefined || m.accuracy_int8 > best_acc[m.goal])
                best_acc[m.goal] = m.accuracy_int8
        })
        var per_point = list.map(function(m) { return Math.log(m.energy_per_inference_j / m.accuracy_int8) })
        return {
            "min_energy": min_energy,
            "best_acc": best_acc,
            "log_lo": per_point.length ? Math.min.apply(null, per_point) : 0,
            "log_hi": per_point.length ? Math.max.apply(null, per_point) : 1
        }
    }

    // g CO2 per million inferences in the chosen country
    function co2(m) { return m.energy_per_inference_j * 1e6 / 3.6e6 * intensity_ }
    function per_point(m) { return co2(m) / m.accuracy_int8 }
    function rel_co2(m) { return m.energy_per_inference_j / stats_.min_energy[m.goal] }
    function pct_acc(m) { return 100 * m.accuracy_int8 / stats_.best_acc[m.goal] }

    // Position 0-1 of a model on the colour scale (the same for every country: the intensity
    // multiplies every cell by the same number)
    function shade(m) {
        var span = stats_.log_hi - stats_.log_lo
        return span > 0 ? (Math.log(m.energy_per_inference_j / m.accuracy_int8) - stats_.log_lo) / span : 0
    }

    // Step of the colour scale of a model
    function step(m) {
        return Math.max(0, Math.min(ramp_.length - 1, Math.floor(shade(m) * ramp_.length)))
    }

    // g CO2 per million inferences per accuracy point at the ends of the colour scale
    function per_point_range() {
        if (models.length === 0)
            return [0, 0]
        var v = models.map(per_point)
        return [Math.min.apply(null, v), Math.max.apply(null, v)]
    }

    function fmt(v, digits) {
        var s = v.toFixed(digits)
        if (s.indexOf(".") >= 0)
            s = s.replace(/0+$/, "").replace(/\.$/, "")
        return s
    }

    function previous_in_row(row, column) {
        for (var j = column - 1; j >= 0; j--)
            if (row.cells[j] !== null)
                return j === column - 1 ? row.cells[j] : null   // jumps only between neighbouring sizes
        return null
    }

    function toggle(name) {
        var copy = Object.assign({}, selected)
        if (copy[name])
            delete copy[name]
        else
            copy[name] = true
        selected = copy
    }

    function select_all() {
        var all = {}
        models.forEach(function(m) { all[m.name] = true })
        selected = all
    }

    function median(values) {
        var v = values.slice().sort(function(a, b) { return a - b })
        var n = v.length
        return n % 2 ? v[(n - 1) / 2] : (v[n / 2 - 1] + v[n / 2]) / 2
    }

    function selected_models() {
        return models.filter(function(m) { return selected[m.name] === true })
    }

    function zone_of(gain) {
        return gain >= steep_gain_ ? "steep" : (gain >= saturated_gain_ ? "flattening" : "saturated")
    }

    // The curve of the selected models. A step is a model to the next bigger one selected of the
    // same task and architecture (a family): accuracy points gained per doubling of CO2. The
    // steps between the same sizes are joined (median), in order of CO2, and each one gets the
    // zone of its gain, never steeper than the zone before it: past the point where accuracy
    // flattens, a bigger model of one task does not make the curve steep again.
    function curve_of(list) {
        var families = {}
        list.forEach(function(m) {
            var key = m.goal + "|" + m.architecture
            if (!families[key])
                families[key] = []
            families[key].push(m)
        })
        var lines = [], groups = {}
        for (var key in families) {
            var f = families[key].slice().sort(function(a, b) { return sizes_.indexOf(a.size) - sizes_.indexOf(b.size) })
            lines.push(f)
            for (var i = 1; i < f.length; i++) {
                var x0 = rel_co2(f[i - 1]), x1 = rel_co2(f[i])
                if (x1 <= x0 * 1.05)
                    continue
                var k = f[i - 1].size + ">" + f[i].size
                if (!groups[k])
                    groups[k] = {"from": f[i - 1].size, "to": f[i].size, "x0": [], "x1": [], "gain": []}
                groups[k].x0.push(x0)
                groups[k].x1.push(x1)
                groups[k].gain.push((pct_acc(f[i]) - pct_acc(f[i - 1])) / (Math.log(x1 / x0) / Math.LN2))
            }
        }
        var steps = []
        for (var g in groups)
            steps.push({"from": groups[g].from, "to": groups[g].to, "x0": median(groups[g].x0),
                        "x1": median(groups[g].x1), "gain": median(groups[g].gain), "count": groups[g].gain.length})
        steps.sort(function(a, b) { return a.x0 * a.x1 - b.x0 * b.x1 })
        var order = ["steep", "flattening", "saturated"], worst = 0
        steps.forEach(function(st) {
            worst = Math.max(worst, order.indexOf(zone_of(st.gain)))
            st.zone = order[worst]
        })
        var bands = []
        steps.forEach(function(st) {
            var last = bands.length ? bands[bands.length - 1] : null
            if (last && last.zone === st.zone)
                last.steps.push(st)
            else
                bands.push({"zone": st.zone, "steps": [st],
                            "x": Math.max(st.x0, last ? last.x : 0)})   // where the zone starts
        })
        return {"lines": lines, "steps": steps, "bands": bands}
    }

    // The conclusion written under the curve, from the selected models
    function curve_summary() {
        var list = selected_models()
        if (list.length < min_selected)
            return ""
        var bands = curve_of(list).bands
        if (bands.length === 0)
            return "Select at least two sizes of the same task and architecture to see how the accuracy grows with the CO2."
        var names = {"steep": "Steep", "flattening": "Flattening", "saturated": "Saturated"}
        var text = bands.map(function(b) {
            return names[b.zone] + ": " + b.steps.map(function(st) {
                return st.from + " → " + st.to + " " + (st.gain >= 0 ? "+" : "") + fmt(st.gain, 1)
            }).join(", ") + " accuracy points per doubling of CO2."
        }).join(" ")
        var worse = list.filter(function(m) {
            if (m.size !== "x") return false
            for (var i = 0; i < models.length; i++)
                if (models[i].goal === m.goal && models[i].size === "l" && models[i].accuracy_int8 > m.accuracy_int8)
                    return true
            return false
        })
        if (worse.length)
            text += " " + worse.map(function(m) { return m.display_name }).join(", ") +
                    (worse.length > 1 ? " are" : " is") + " less accurate than an l model of the same task."
        return text
    }

    // ---------------------------------------------------------------- layout

    SmlScreenHeader
    {
        id: yolo_header
        title: "YOLO models"
        subtitle: "The " + root.models.length + " YOLO models of the Axelera Edge 130p: CO2 per accuracy point, and where extra CO2 stops buying accuracy"

        navigation: [
            SmlButton
            {
                icon_name: Settings.home_icon_name
                text_value: "Home"
                tooltip_text: "Go to Home screen"
                onClicked: root.go_home()
            },
            SmlIconButton
            {
                outlined: true
                icon_name: Settings.back_icon_name
                tooltip_text: "Go to Problem Definition screen"
                onClicked: root.go_back()
            }
        ]
    }

    SmlEmptyState
    {
        anchors.centerIn: parent
        visible: root.models.length === 0 || root.intensity_ === 0
        busy: true
        title: "Waiting for the YOLO models"
        hint: "They come from the HW resources and carbon footprint nodes once these are running."
    }

    Flickable
    {
        id: yolo_flick
        visible: root.models.length > 0 && root.intensity_ > 0
        anchors {
            top: yolo_header.bottom
            topMargin: Theme.space5
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        contentWidth: width
        contentHeight: content_column.height + Theme.pagePadding
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: SmlScrollBar { }

        Column
        {
            id: content_column
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(yolo_flick.width - 2 * Theme.pagePadding, Theme.contentMaxWidth)
            spacing: Theme.space6

            // ------------------------------------------------ matrix
            SmlCard
            {
                id: matrix_card
                width: parent.width
                title: "CO2 per accuracy point"
                subtitle: "g CO2 per million inferences in " + root.country_name_ + " (" + fmt(root.intensity_, 0) +
                          " g/kWh), divided by the accuracy: lighter is better. Click the models to compare below."
                icon_name: "table"
                actions: [
                    SmlChip
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.selected_count + " of " + root.models.length + " selected"
                        tone: root.selected_count >= root.min_selected ? "accent" : "neutral"
                    },
                    SmlButton
                    {
                        icon_name: "checklist"
                        text_value: "Select all"
                        tooltip_text: "Select every model of the matrix"
                        onClicked: root.select_all()
                    },
                    SmlButton
                    {
                        icon_name: "cross"
                        text_value: "Clear"
                        disabled: root.selected_count === 0
                        tooltip_text: "Unselect every model"
                        onClicked: root.selected = ({})
                    }
                ]

                Column
                {
                    width: parent.width
                    spacing: Theme.space3

                    Row
                    {
                        spacing: Theme.space3
                        SmlText
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            text_value: "Country"
                        }
                        SmlCombobox
                        {
                            id: country_input
                            width: 280
                            height: Theme.controlHeight
                            searchable: true
                            model: root.countries_.map(function(c) { return c.name })
                            displayText: root.country_name_
                            onText_changed: {
                                var code = root.country_code(text)
                                if (code !== "")
                                    root.country = code
                            }
                        }
                    }

                    // Legend
                    Row
                    {
                        spacing: Theme.space5
                        Row {
                            spacing: Theme.space2
                            SmlText {
                                anchors.verticalCenter: parent.verticalCenter
                                text_value: root.per_point_range()[0].toFixed(2) + " g/pt"
                                force_size: true; forced_size: Theme.fontSizeMeta
                            }
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Repeater {
                                    model: root.ramp_
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 14; height: 12; radius: 2
                                        color: modelData
                                    }
                                }
                            }
                            SmlText {
                                anchors.verticalCenter: parent.verticalCenter
                                text_value: root.per_point_range()[1].toFixed(2) + " g/pt: less → more CO2 per accuracy point"
                                force_size: true; forced_size: Theme.fontSizeMeta
                            }
                        }
                        Row {
                            spacing: Theme.space2
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 14; radius: 2; color: Theme.danger }
                            SmlText { text_value: "CO2 ×" + root.jump_ratio_ + " or more from the previous size"; force_size: true; forced_size: Theme.fontSizeMeta }
                        }
                        Row {
                            spacing: Theme.space2
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 3; color: "transparent"; border.width: 2; border.color: Theme.accentBorder }
                            SmlText { text_value: "Selected"; force_size: true; forced_size: Theme.fontSizeMeta }
                        }
                    }

                    // Matrix
                    Column
                    {
                        id: matrix
                        width: parent.width
                        spacing: Theme.space1

                        readonly property int label_width: 200
                        readonly property real cell_width: (width - label_width - 4 * Theme.space1) / 5
                        readonly property int cell_height: 64

                        // Size header
                        Row
                        {
                            spacing: Theme.space1
                            Item { width: matrix.label_width; height: 20 }
                            Repeater {
                                model: root.sizes_
                                delegate: Item {
                                    id: size_header
                                    required property var modelData
                                    width: matrix.cell_width
                                    height: 20
                                    Text {
                                        anchors.centerIn: parent
                                        text: size_header.modelData
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeCardTitle
                                        font.weight: Font.DemiBold
                                        color: Theme.textPrimary
                                    }
                                }
                            }
                        }

                        Repeater
                        {
                            model: root.rows_
                            delegate: Row {
                                id: matrix_row
                                required property var modelData
                                spacing: Theme.space1

                                Column {
                                    width: matrix.label_width
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: matrix_row.modelData.architecture
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeBody
                                        font.weight: Font.DemiBold
                                        color: Theme.textPrimary
                                    }
                                    Text {
                                        text: root.goal_names_[matrix_row.modelData.goal]
                                        font.family: Theme.uiFontFamily
                                        font.pixelSize: Theme.fontSizeMeta
                                        color: Theme.textMuted
                                    }
                                }

                                Repeater
                                {
                                    model: 5
                                    delegate: Item {
                                        id: cell
                                        required property int index
                                        readonly property var model_: matrix_row.modelData.cells[cell.index]
                                        readonly property var previous_: root.previous_in_row(matrix_row.modelData, cell.index)
                                        readonly property real jump_: (model_ && previous_)
                                            ? model_.energy_per_inference_j / previous_.energy_per_inference_j : 0
                                        readonly property bool is_selected_: model_ !== null && root.selected[model_.name] === true
                                        readonly property int step_: model_ ? root.step(model_) : 0
                                        readonly property color ink_: step_ >= root.first_dark_step_ ? "#ffffff" : "#2a1a0a"
                                        width: matrix.cell_width
                                        height: matrix.cell_height

                                        // Not in the Axelera model zoo
                                        Rectangle {
                                            visible: cell.model_ === null
                                            anchors.fill: parent
                                            radius: Theme.radiusSm
                                            color: "transparent"
                                            border.width: 1
                                            border.color: Theme.border
                                        }

                                        Rectangle {
                                            id: cell_fill
                                            visible: cell.model_ !== null
                                            anchors.fill: parent
                                            radius: Theme.radiusSm
                                            color: cell.model_ ? root.ramp_[cell.step_] : "transparent"
                                            border.width: cell.is_selected_ ? 3 : 0
                                            border.color: Theme.accentBorder

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 1
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: cell.model_ ? root.per_point(cell.model_).toFixed(2) + " g/pt" : ""
                                                    font.family: Theme.monoFontFamily
                                                    font.pixelSize: Theme.fontSizeBody
                                                    font.weight: Font.Bold
                                                    color: cell.ink_
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: cell.model_ ? root.fmt(root.co2(cell.model_), root.co2(cell.model_) < 10 ? 1 : 0) + " g CO2" : ""
                                                    font.family: Theme.uiFontFamily
                                                    font.pixelSize: Theme.fontSizeMicro
                                                    color: cell.ink_
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: cell.model_ ? cell.model_.accuracy_int8 + " " + cell.model_.metric : ""
                                                    font.family: Theme.uiFontFamily
                                                    font.pixelSize: Theme.fontSizeMicro
                                                    color: cell.ink_
                                                }
                                            }

                                            // Selected mark
                                            Rectangle {
                                                visible: cell.is_selected_
                                                anchors { top: parent.top; right: parent.right; margins: 4 }
                                                width: 16; height: 16; radius: 8
                                                color: Theme.accentFill
                                                SmlIcon {
                                                    anchors.centerIn: parent
                                                    name: "check"
                                                    size: 12
                                                    variant: Theme.iconOnAccent
                                                }
                                            }
                                        }

                                        // CO2 jump from the previous size
                                        Rectangle {
                                            visible: cell.jump_ >= root.jump_ratio_
                                            x: -Theme.space1 / 2 - 2
                                            y: 4
                                            width: 4
                                            height: parent.height - 8
                                            radius: 2
                                            color: Theme.danger
                                            z: 2
                                        }
                                        Rectangle {
                                            visible: cell.jump_ >= root.jump_ratio_
                                            x: -Theme.space1 / 2 - width / 2
                                            y: -6
                                            width: jump_text.implicitWidth + 10
                                            height: 16
                                            radius: 8
                                            color: Theme.danger
                                            z: 3
                                            Text {
                                                id: jump_text
                                                anchors.centerIn: parent
                                                text: "×" + root.fmt(cell.jump_, 1)
                                                font.family: Theme.monoFontFamily
                                                font.pixelSize: Theme.fontSizeMicro
                                                font.weight: Font.Bold
                                                color: "#ffffff"
                                            }
                                        }

                                        SmlMouseArea {
                                            id: cell_mouse
                                            anchors.fill: parent
                                            enabled: cell.model_ !== null
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggle(cell.model_.name)
                                        }
                                        SmlToolTip {
                                            visible: cell_mouse.containsMouse && cell.model_ !== null
                                            text: cell.model_ ? cell.model_.display_name + " · " + root.goal_names_[cell.model_.goal] +
                                                  "\n" + root.fmt(root.co2(cell.model_), 2) + " g CO2 per million inferences" +
                                                  "\n" + root.fmt(cell.model_.energy_per_inference_j * 1000, 1) + " mJ per inference" +
                                                  "\n" + cell.model_.metric + " " + cell.model_.accuracy_int8 + " after int8 (fp32 " + cell.model_.accuracy_fp32 + ")" +
                                                  (cell.previous_ ? "\nvs " + cell.previous_.display_name + ": ×" + root.fmt(cell.jump_, 2) + " CO2, " +
                                                      (cell.model_.accuracy_int8 >= cell.previous_.accuracy_int8 ? "+" : "") +
                                                      root.fmt(cell.model_.accuracy_int8 - cell.previous_.accuracy_int8, 2) + " points" : "") : ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------ accuracy curve
            SmlCard
            {
                id: curve_card
                width: parent.width
                title: "Where extra CO2 stops buying accuracy"
                subtitle: "Each selected model against its own task: CO2 as a multiple of the task's smallest model, accuracy as a share of the task's best"
                icon_name: "leaf"

                Column
                {
                    width: parent.width
                    spacing: Theme.space3

                    Item {
                        width: parent.width
                        height: 120
                        visible: root.selected_count < root.min_selected
                        SmlEmptyState {
                            anchors.centerIn: parent
                            title: "Select at least " + root.min_selected + " models in the matrix"
                            hint: root.selected_count + " selected so far. \"Select all\" takes all " + root.models.length + "."
                        }
                    }

                    Item
                    {
                        id: curve_frame
                        visible: root.selected_count >= root.min_selected
                        width: parent.width
                        height: 440

                        property var points_: []   // drawn points, for the hover
                        property var labels_: []   // text of the curve, set by the Canvas

                        Canvas
                        {
                            id: curve_canvas
                            anchors.fill: parent
                            renderStrategy: Canvas.Cooperative
                            onWidthChanged: requestPaint()
                            onVisibleChanged: if (visible) requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var labels = []
                                // Text is drawn by the Repeater below: the Canvas fills the glyphs
                                // with holes where their strokes overlap
                                var label = function(t, x, y, align, px, bold, color, rot, halo) {
                                    labels.push({"t": t, "x": x, "y": y, "align": align, "px": px,
                                                 "bold": bold, "color": color, "rot": rot || 0, "halo": halo === true})
                                }
                                var W = width, H = height
                                var ml = 64, mr = 20, mt = 36, mb = 48
                                var list = root.selected_models()
                                if (list.length === 0) {
                                    curve_frame.labels_ = []
                                    curve_frame.points_ = []
                                    return
                                }
                                var curve = root.curve_of(list)
                                var rels = list.map(root.rel_co2), pcts = list.map(root.pct_acc)
                                var x_hi = Math.max(2, Math.max.apply(null, rels) * 1.2)
                                var y_lo = Math.min(60, Math.floor((Math.min.apply(null, pcts) - 3) / 10) * 10)
                                var xs = function(v) { return ml + Math.log(v / 0.9) / Math.log(x_hi / 0.9) * (W - ml - mr) }
                                var ys = function(v) { return H - mb - (v - y_lo) / (102 - y_lo) * (H - mb - mt) }

                                // Zones: from the first to the last band, the outer ones to the edges
                                var tints = {
                                    "steep": Qt.rgba(Theme.accentFill.r, Theme.accentFill.g, Theme.accentFill.b, 0.08),
                                    "flattening": Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08),
                                    "saturated": Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.10)
                                }
                                var names = {
                                    "steep": ["Steep: accuracy climbs fast", "Steep"],
                                    "flattening": ["Flattening", "Flattening"],
                                    "saturated": ["Saturated: little gain", "Saturated"]
                                }
                                curve.bands.forEach(function(band, i) {
                                    var x0 = i === 0 ? xs(0.9) : xs(band.x)
                                    var x1 = i === curve.bands.length - 1 ? xs(x_hi) : xs(curve.bands[i + 1].x)
                                    ctx.fillStyle = tints[band.zone]
                                    ctx.fillRect(x0, mt, x1 - x0, H - mb - mt)
                                    if (x1 - x0 >= 60)
                                        label(names[band.zone][x1 - x0 >= 200 ? 0 : 1], (x0 + x1) / 2, mt - 14, "center",
                                              Theme.fontSizeBody, true, band.zone === "saturated" ? Theme.danger : Theme.textPrimary)
                                })

                                // Grid and axes
                                ctx.strokeStyle = Theme.border
                                ctx.lineWidth = 1
                                for (var p = Math.ceil(y_lo / 10) * 10; p <= 100; p += 10) {
                                    ctx.beginPath(); ctx.moveTo(ml, ys(p)); ctx.lineTo(W - mr, ys(p)); ctx.stroke()
                                    label(p + "%", ml - 8, ys(p) + 4, "right", Theme.fontSizeMeta, false, Theme.textMuted)
                                }
                                // Finer ticks when the selected models stay close in CO2
                                var tick = x_hi < 4 ? Math.SQRT2 : 2
                                for (var k = 1; k <= x_hi; k *= tick) {
                                    ctx.beginPath(); ctx.moveTo(xs(k), mt); ctx.lineTo(xs(k), H - mb); ctx.stroke()
                                    label("×" + root.fmt(k, 1), xs(k), H - mb + 18, "center", Theme.fontSizeMeta, false, Theme.textMuted)
                                }
                                label("CO2 per inference, as a multiple of the smallest model of the same task (log scale)",
                                      (ml + W - mr) / 2, H - 8, "center", Theme.fontSizeMeta, false, Theme.textSecondary)
                                label("Share of the task's best accuracy", 16, (mt + H - mb) / 2, "center",
                                      Theme.fontSizeMeta, false, Theme.textSecondary, -90)

                                // Lines where the curve changes zone
                                ctx.strokeStyle = Theme.danger
                                ctx.lineWidth = 2
                                ctx.setLineDash([6, 4])
                                for (var i = 1; i < curve.bands.length; i++) {
                                    var v = curve.bands[i].x
                                    ctx.beginPath(); ctx.moveTo(xs(v), mt); ctx.lineTo(xs(v), H - mb); ctx.stroke()
                                    label("×" + root.fmt(v, 1) + " (from " + curve.bands[i].steps[0].from + ")", xs(v) + 5, H - mb - 8,
                                          "left", Theme.fontSizeMeta, true, Theme.danger)
                                }

                                // Each family of the selected models, smallest to biggest
                                ctx.strokeStyle = Theme.textMuted
                                ctx.lineWidth = 1
                                ctx.setLineDash([])
                                curve.lines.forEach(function(f) {
                                    if (f.length < 2)
                                        return
                                    ctx.beginPath()
                                    f.forEach(function(m, i) {
                                        var x = xs(root.rel_co2(m)), y = ys(root.pct_acc(m))
                                        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                                    })
                                    ctx.stroke()
                                })

                                // Models: YOLO11 circles, YOLO26 squares
                                var drawn = []
                                list.forEach(function(m) {
                                    var x = xs(root.rel_co2(m)), y = ys(root.pct_acc(m))
                                    ctx.fillStyle = m.architecture === "YOLO26" ? root.yolo26_color_ : root.yolo11_color_
                                    ctx.strokeStyle = Theme.surface
                                    ctx.lineWidth = 2
                                    ctx.beginPath()
                                    if (m.architecture === "YOLO26")
                                        ctx.rect(x - 5, y - 5, 10, 10)
                                    else
                                        ctx.arc(x, y, 5.5, 0, 2 * Math.PI)
                                    ctx.fill()
                                    ctx.stroke()
                                    drawn.push({"x": x, "y": y, "m": m})
                                })
                                curve_frame.points_ = drawn
                                curve_frame.labels_ = labels
                            }
                        }

                        // The text of the curve: x is the anchor of the alignment, y the baseline
                        Repeater {
                            model: curve_frame.labels_
                            delegate: Text {
                                required property var modelData
                                text: modelData.t
                                font.family: Theme.uiFontFamily
                                font.pixelSize: modelData.px
                                font.weight: modelData.bold ? Font.Bold : Font.Normal
                                color: modelData.color
                                rotation: modelData.rot
                                style: modelData.halo ? Text.Outline : Text.Normal
                                styleColor: Theme.surface
                                x: modelData.align === "center" ? modelData.x - implicitWidth / 2
                                   : (modelData.align === "right" ? modelData.x - implicitWidth : modelData.x)
                                y: modelData.rot !== 0 ? modelData.y - implicitHeight / 2 : modelData.y - baselineOffset
                            }
                        }

                        // Hover: the nearest model
                        MouseArea {
                            id: curve_mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            property var hit_: null
                            onPositionChanged: {
                                var best = null, best_d = 144
                                curve_frame.points_.forEach(function(p) {
                                    var d = (p.x - mouse.x) * (p.x - mouse.x) + (p.y - mouse.y) * (p.y - mouse.y)
                                    if (d < best_d) { best_d = d; best = p }
                                })
                                hit_ = best
                            }
                            onExited: hit_ = null
                        }
                        Rectangle {
                            visible: curve_mouse.hit_ !== null
                            x: curve_mouse.hit_ ? Math.min(curve_mouse.hit_.x + 12, curve_frame.width - width) : 0
                            y: curve_mouse.hit_ ? Math.max(0, curve_mouse.hit_.y - height - 8) : 0
                            width: hover_text.implicitWidth + 2 * Theme.space3
                            height: hover_text.implicitHeight + 2 * Theme.space2
                            radius: Theme.radiusSm
                            color: Theme.overlay
                            border.width: 1
                            border.color: Theme.borderStrong
                            Text {
                                id: hover_text
                                anchors.centerIn: parent
                                font.family: Theme.uiFontFamily
                                font.pixelSize: Theme.fontSizeMeta
                                color: Theme.textPrimary
                                text: curve_mouse.hit_ ? curve_mouse.hit_.m.display_name + " · " + root.goal_names_[curve_mouse.hit_.m.goal] +
                                      "\n" + root.fmt(root.pct_acc(curve_mouse.hit_.m), 1) + "% of the task's best accuracy (" +
                                      curve_mouse.hit_.m.accuracy_int8 + " " + curve_mouse.hit_.m.metric + ")" +
                                      "\n×" + root.fmt(root.rel_co2(curve_mouse.hit_.m), 2) + " the CO2 of the task's smallest model" : ""
                            }
                        }
                    }

                    // Legend and conclusion
                    Row {
                        visible: curve_frame.visible
                        spacing: Theme.space5
                        Row {
                            spacing: Theme.space2
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 11; height: 11; radius: 6; color: root.yolo11_color_ }
                            SmlText { text_value: "YOLO11"; force_size: true; forced_size: Theme.fontSizeMeta }
                        }
                        Row {
                            spacing: Theme.space2
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 2; color: root.yolo26_color_ }
                            SmlText { text_value: "YOLO26"; force_size: true; forced_size: Theme.fontSizeMeta }
                        }
                        Row {
                            spacing: Theme.space2
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 18; height: 1; color: Theme.textMuted }
                            SmlText { text_value: "Same task and architecture, smallest to biggest"; force_size: true; forced_size: Theme.fontSizeMeta }
                        }
                        Row {
                            spacing: Theme.space2
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 14; color: Theme.danger }
                            SmlText {
                                text_value: "Zone change. Accuracy points per doubling of CO2: steep " + root.steep_gain_ + "+, flattening " +
                                            root.saturated_gain_ + "-" + root.steep_gain_ + ", saturated under " + root.saturated_gain_
                                force_size: true; forced_size: Theme.fontSizeMeta
                            }
                        }
                    }

                    Rectangle {
                        visible: curve_frame.visible && summary_text.text !== ""
                        width: parent.width
                        height: summary_text.implicitHeight + 2 * Theme.space3
                        radius: Theme.radiusSm
                        color: Theme.accentSubtle
                        Text {
                            id: summary_text
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.space4 }
                            wrapMode: Text.WordWrap
                            font.family: Theme.uiFontFamily
                            font.pixelSize: Theme.fontSizeBody
                            color: Theme.textPrimary
                            text: root.selected_count >= 0 ? root.curve_summary() : ""
                        }
                    }
                }
            }
        }
    }
}
