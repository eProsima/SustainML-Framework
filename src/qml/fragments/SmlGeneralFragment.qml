// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Qt.labs.qmlmodels 1.0

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Rectangle
{
    id: root
    anchors.fill: parent

    // Public properties
    required property int problem_id
    required property int stack_id

    // Public signals
    signal component_signal(string viewType, string signal_kind, string id)
    // signal go_reiterate();

    // Private properties
    property var minColumnWidths: [45, 45, 100, 160, 180, 160, 170, 170, 185, 185]
    property int sumMinColumnWidths: {
        var total = 0;
        for (var i = 0; i < minColumnWidths.length; i++) {
            total += minColumnWidths[i];
        }
        return total;
    }
    property var columnWidths: [45, 45, 100, 160, 180, 160, 170, 170, 185, 185]

    // Width of both tables, from the columns' widths. Set explicitly by relayout_tables()
    // rather than bound to the tables' own contentItem.childrenRect: that binding made each
    // table's width depend on its own laid-out cells, so every relayout changed the width it
    // was computed from, a binding loop.
    property real __tables_width: __columns_width() + 1

    function __columns_width() {
        var w = 0
        for (var i = 0; i < columnWidths.length; i++)
            w += columnWidths[i]
        return w
    }

    // Relayout both tables, then size them (columnWidthProvider may update columnWidths).
    // Results call it through Qt.callLater, so a burst of them (e.g. loading a file) costs one
    // relayout instead of a synchronous one per result.
    function relayout_tables() {
        general_header_table.forceLayout()
        general_table.forceLayout()
        __tables_width = __columns_width() + 1
    }
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __scroll_view_height: height - __summary_height
    readonly property int __scroll_view_content_height: 700
    readonly property int __header_height: 40
    readonly property int __data_height: __header_height * 1.5
    readonly property int __cell_padding: 10
    readonly property string __cell_background_color: "#e0e0e0"
    readonly property string __cell_background_nightmode_color: "#505050"
    readonly property int __reiterate_column: 0
    readonly property int __check_column: 1
    readonly property int __iteration_column: 2
    readonly property int __problem_kind_column: 3
    readonly property int __suggested_model_column: 4
    readonly property int __hw_description_column: 5
    readonly property int __power_consumption_column: 6
    readonly property int __carbon_footprint_column: 7
    readonly property int __carbon_intensity_column: 8
    readonly property int __memory_footprint_column: 9

    // Ranking of the iterations when the problem has a desired carbon footprint (Manual/Auto
    // optimization) or a max memory footprint: the models within the limits first, then by
    // lowest carbon footprint. __summary names the best one, or the closest if none fits.
    property string __summary: ""
    // Limits of the latest submission of this problem (requested per iteration, see onProblem_limits)
    property int __limits_iteration: -1
    property real __desired_carbon_footprint: 0
    property real __max_memory_footprint: 0
    readonly property int __summary_height: __summary === "" ? 0 : __header_height


    color: ScreenManager.night_mode ?  Settings.app_color_dark : Settings.app_color_light

    TableModel {
        id: table_model
        TableModelColumn {display: "Reiterate"}
        TableModelColumn {display: "Checkbox"}
        TableModelColumn {display: "Iteration"}
        TableModelColumn {display: "Problem kind"}
        TableModelColumn {display: "Suggested model"}
        TableModelColumn {display: "Suggested hardware"}
        TableModelColumn {display: "Power consumption"}
        TableModelColumn {display: "Carbon footprint"}
        TableModelColumn {display: "Carbon intensity"}
        TableModelColumn {display: "Memory footprint"}

        rows: []

        function contains (iteration_id)
        {
            var row = -1
            for (var i = 0; i < rows.length; i++)
            {
                if (rows[i].Iteration === iteration_id)
                {
                    row = i
                    break; // end loop
                }
            }
            return row
        }
    }

    Connections
    {
        target: engine

        function onNew_ml_model_metadata_node_output(problem_id, iteration_id, metadata, keywords)
        {
            if (problem_id === root.problem_id)
            {
                var row = table_model.contains(iteration_id)
                if(row >= 0)
                {
                    table_model.setData(table_model.index(row, __problem_kind_column), "display", keywords)
                }
                else
                {
                    table_model.appendRow({
                            "Reiterate" : "",
                            "Checkbox" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : keywords,
                            "Suggested model" : "",
                            "Suggested hardware" : "",
                            "Power consumption" : "",
                            "Carbon footprint" : "",
                            "Carbon intensity" : "",
                            "Memory footprint" : ""
                        }
                    )
                }
            }
            Qt.callLater(root.relayout_tables)
        }

        function onNew_ml_model_node_output(problem_id, iteration_id, model, model_path, properties, properties_path, input_batch, target_latency)
        {
            if (problem_id === root.problem_id)
            {
                var row = table_model.contains(iteration_id)
                if(row >= 0)
                {
                    table_model.setData(table_model.index(row, __suggested_model_column), "display", model)
                }
                else
                {
                    table_model.appendRow({
                            "Reiterate" : "",
                            "Checkbox" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : model,
                            "Suggested hardware" : "",
                            "Power consumption" : "",
                            "Carbon footprint" : "",
                            "Carbon intensity" : "",
                            "Memory footprint" : ""
                        }
                    )
                }
            }
            Qt.callLater(root.relayout_tables)
        }

        function onNew_hw_resources_node_output(problem_id, iteration_id, hw_description, power_consumption, latency, memory_footprint_of_ml_model, max_hw_memory_footprint)
        {
            if (problem_id === root.problem_id)
            {
                var row = table_model.contains(iteration_id)
                if(row >= 0)
                {
                    table_model.setData(table_model.index(row, __hw_description_column), "display", hw_description)
                    table_model.setData(table_model.index(row, __power_consumption_column), "display", power_consumption)
                    table_model.setData(table_model.index(row, __memory_footprint_column), "display", root.__memory_text(memory_footprint_of_ml_model))
                }
                else
                {
                    table_model.appendRow({
                            "Reiterate" : "",
                            "Checkbox" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : "",
                            "Suggested hardware" : hw_description,
                            "Power consumption" : power_consumption,
                            "Carbon footprint" : "",
                            "Carbon intensity" : "",
                            "Memory footprint" : root.__memory_text(memory_footprint_of_ml_model)
                        }
                    )
                }
            }
            Qt.callLater(root.relayout_tables)
        }

        function onProblem_iteration_results(problem_id, iteration_id, results)
        {
            if (problem_id === root.problem_id)
                root.__fill_row(iteration_id, results)
        }

        function onProblem_limits(problem_id, iteration_id, optimize, desired_carbon_footprint, max_memory_footprint)
        {
            if (problem_id !== root.problem_id)
                return
            if (iteration_id >= root.__limits_iteration)
            {
                root.__limits_iteration = iteration_id
                root.__desired_carbon_footprint = optimize ? desired_carbon_footprint : 0
                root.__max_memory_footprint = max_memory_footprint
            }
            root.__update_ranking()
        }

        function onNew_carbon_footprint_node_output(problem_id, iteration_id, carbon_footprint, energy_consumption, carbon_intensity)
        {
            if (problem_id === root.problem_id)
            {
                var row = table_model.contains(iteration_id)
                if(row >= 0)
                {
                    table_model.setData(table_model.index(row, __carbon_footprint_column), "display", carbon_footprint)
                    table_model.setData(table_model.index(row, __carbon_intensity_column), "display", carbon_intensity)
                }
                else
                {
                    table_model.appendRow({
                            "Reiterate" : "",
                            "Checkbox" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : "",
                            "Suggested hardware" : "",
                            "Power consumption" : "",
                            "Carbon footprint" : carbon_footprint,
                            "Carbon intensity" : carbon_intensity,
                            "Memory footprint" : ""
                        }
                    )
                }
                engine.request_problem_limits(problem_id, iteration_id)
            }
            Qt.callLater(root.relayout_tables)
        }
    }

    // Results that arrive before this view has its problem_id (the first results of a problem
    // create its tab) never reach it, so once it has one, fetch the problem's results again
    onProblem_idChanged: __fetch_results()
    Component.onCompleted: __fetch_results()

    function __fetch_results()
    {
        if (root.problem_id >= 0)
            engine.request_problem_results(root.problem_id)
    }

    // Fill the cells of an iteration still empty with its results (all nodes, keyed by node name)
    function __fill_row(iteration_id, results)
    {
        var metadata = results["ML_MODEL_METADATA"] || {}
        var model = results["ML_MODEL"] || {}
        var hw = results["HW_RESOURCES"] || {}
        var carbon = results["CARBON_FOOTPRINT"] || {}
        function text(v) { return (v === undefined || v === null) ? "" : String(v) }
        function number(v) { return (v === undefined || v === null) ? "" : String(parseFloat(Number(v).toPrecision(6))) }
        var values = {
            "Problem kind": text(metadata["metadata"]),
            "Suggested model": text(model["model"]),
            "Suggested hardware": text(hw["hw_description"]),
            "Power consumption": number(hw["power_consumption"]),
            "Carbon footprint": number(carbon["carbon_footprint"]),
            "Carbon intensity": number(carbon["carbon_intensity"]),
            "Memory footprint": root.__memory_text(number(hw["memory_footprint_of_ml_model"]))
        }
        var columns = {
            "Problem kind": __problem_kind_column,
            "Suggested model": __suggested_model_column,
            "Suggested hardware": __hw_description_column,
            "Power consumption": __power_consumption_column,
            "Carbon footprint": __carbon_footprint_column,
            "Carbon intensity": __carbon_intensity_column,
            "Memory footprint": __memory_footprint_column
        }
        var row = table_model.contains(iteration_id)
        if (row < 0)
        {
            var new_row = {"Reiterate": "", "Checkbox": "false", "Iteration": iteration_id}
            for (var key in values)
                new_row[key] = values[key]
            table_model.appendRow(new_row)
        }
        else
        {
            var current = table_model.rows[row]
            for (var k in values)
            {
                if (current[k] === "" && values[k] !== "")
                    table_model.setData(table_model.index(row, columns[k]), "display", values[k])
            }
        }
        Qt.callLater(root.relayout_tables)
        if (values["Carbon footprint"] !== "")
            engine.request_problem_limits(root.problem_id, iteration_id)
    }

    // 0 means unknown: saved before the memory was measured, or the model failed to load
    function __memory_text(val)
    {
        return Number(val) > 0 ? val : ""
    }

    function __format_number(val)
    {
        var num = Number(val)
        if (Math.abs(num) >= 1e5 || (Math.abs(num) > 0 && Math.abs(num) < 1e-3))
            return num.toExponential(4)
        return num.toFixed(4)
    }

    function __update_ranking()
    {
        var desired = root.__desired_carbon_footprint
        var max_memory = root.__max_memory_footprint
        if (desired <= 0 && max_memory <= 0)
        {
            root.__summary = ""
            return
        }

        // Rows without a valid result (still running, no model, error) go last, in iteration order
        function complete(r) { return r["Carbon footprint"] !== "" && Number(r["Carbon intensity"]) > 0 }
        function meets(r) {
            return (desired <= 0 || Number(r["Carbon footprint"]) <= desired) &&
                   (max_memory <= 0 || Number(r["Memory footprint"]) <= max_memory)
        }
        // How far a row is over the limits, relative to each limit (0 when within them)
        function excess(r) {
            var e = 0
            if (desired > 0) e += Math.max(0, Number(r["Carbon footprint"]) / desired - 1)
            if (max_memory > 0) e += Math.max(0, Number(r["Memory footprint"]) / max_memory - 1)
            return e
        }
        var rows = table_model.rows.slice()
        rows.sort(function(a, b) {
            if (complete(a) !== complete(b)) return complete(a) ? -1 : 1
            if (!complete(a)) return a["Iteration"] - b["Iteration"]
            // Within the limits first; the rest by how close they are to them
            if (excess(a) !== excess(b)) return excess(a) - excess(b)
            return Number(a["Carbon footprint"]) - Number(b["Carbon footprint"])
        })
        table_model.rows = rows

        var limits = []
        if (desired > 0) limits.push("carbon footprint up to " + desired + " gCO2e")
        if (max_memory > 0) limits.push("memory up to " + max_memory + " MB")
        if (rows.length === 0 || !complete(rows[0]))
        {
            root.__summary = "Limits: " + limits.join(", ") + "."
            return
        }
        var best = rows[0]["Suggested model"] + " (iteration " + rows[0]["Iteration"] + "): " +
                   root.__format_number(rows[0]["Carbon footprint"]) + " gCO2e" +
                   (Number(rows[0]["Memory footprint"]) > 0 ? ", " + Number(rows[0]["Memory footprint"]).toFixed(2) + " MB" : "")
        root.__summary = meets(rows[0])
                ? "Best model within the limits (" + limits.join(", ") + "): " + best
                : "No model has met the limits (" + limits.join(", ") + ") yet. Closest: " + best
    }

    SmlText {
        id: summary_text
        visible: root.__summary !== ""
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.width
        height: root.__summary_height
        verticalAlignment: Text.AlignVCenter
        text_kind: SmlText.TextKind.Body
        text_value: root.__summary
        padding: __cell_padding
        force_elide: true
    }

    Rectangle {
        id: splitRow
        anchors.top: summary_text.bottom
        anchors.left: parent.left
        width: root.width
        height: root.height - root.__summary_height

        SmlScrollView
        {
            id: scroll_view

            // anchors.fill: parent
            anchors.left: parent.left
            width: root.width
            height: root.__scroll_view_height
            content_width: general_header_table.contentWidth
            // content_height: general_header_table.height + general_table.height + 1
            layout: SmlScrollBar.ScrollBarLayout.Horizontal
            scrollbar_background_color: Settings.app_color_light
            scrollbar_background_nightmodel_color: Settings.app_color_dark
            interactive: false
            onWidthChanged: {
                Qt.callLater(root.relayout_tables)
            }

            // Header
            Rectangle {
                id: headerRect
                anchors.top: parent.top
                anchors.left: parent.left
                width: scroll_view.width > general_header_table.contentWidth ? scroll_view.width : general_header_table.contentWidth
                height: __header_height
                color: ScreenManager.night_mode ? __cell_background_nightmode_color : __cell_background_color
                onWidthChanged: {
                    Qt.callLater(root.relayout_tables)
                }

                TableView
                {
                    id: general_header_table
                    anchors{
                        top: parent.top
                        left: parent.left
                        bottom: parent.bottom
                    }
                    // columnSpacing: 1
                    // rowSpacing: 1
                    boundsBehavior: Flickable.StopAtBounds
                    columnWidthProvider: function (column) {
                        {
                            var currentWidth = columnWidths[column];
                            if (column === columnWidths.length - 1 && scroll_view.width > sumMinColumnWidths) {
                                var sum = 0;
                                for (var i = 0; i < columnWidths.length - 1; i++) {
                                    sum += columnWidths[i];
                                }
                                var total = scroll_view.width - sum;
                                if (total <= minColumnWidths[column]) {
                                    columnWidths[column] = minColumnWidths[column];
                                    var reduction = columnWidths[column];
                                    var idx = columnWidths.length - 2;
                                    while (reduction > 0 && idx >= 0) {
                                        var available = columnWidths[idx] - minColumnWidths[idx];
                                        if (available >= reduction) {
                                            columnWidths[idx] -= reduction;
                                            reduction = 0;
                                        } else {
                                            columnWidths[idx] = minColumnWidths[idx];
                                            reduction -= available;
                                        }
                                        idx--;
                                    }
                                    return minColumnWidths[column];
                                }
                                columnWidths[column] = total;
                                return total;
                            }
                            return currentWidth;
                        }
                    }
                    width: root.__tables_width
                    contentWidth: root.__tables_width
                    // onWidthChanged: forceLayout()
                    // columnWidthProvider: getColumnWidth(column)

                    model: TableModel {
                        TableModelColumn {display: "Reiterate"}
                        TableModelColumn {display: "Checkbox"}
                        TableModelColumn {display: "Iteration"}
                        TableModelColumn {display: "Problem kind"}
                        TableModelColumn {display: "Suggested model"}
                        TableModelColumn {display: "Suggested hardware"}
                        TableModelColumn {display: "Power consumption"}
                        TableModelColumn {display: "Carbon footprint"}
                        TableModelColumn {display: "Carbon intensity"}
                        TableModelColumn {display: "Memory footprint"}

                        rows: [
                            {"Reiterate" : "  ",
                            "Checkbox" : "  ",
                            "Iteration" : "Iteration",
                            "Problem kind" : "Problem",
                            "Suggested model" : "ML Model",
                            "Suggested hardware" : "Hardware",
                            "Power consumption" : "Power Consumption [W]",
                            "Carbon footprint" : "Carbon Footprint [gCO2e]",
                            "Carbon intensity" : "Carbon Intensity [gCO2/kW]",
                            "Memory footprint" : "Memory Footprint [MB]"}
                        ]
                    }

                    delegate: Rectangle
                    {
                        implicitWidth: width
                        implicitHeight: __header_height
                        color: "transparent"
                        // border.width: 1
                        SmlText
                        {
                            anchors.centerIn: parent
                            height: __header_height
                            text_kind: SmlText.TextKind.Header_3
                            text_value: model.display
                            padding: __cell_padding + 1
                            force_size: true
                        }

                        // Bottom horizontal border (dark tone)
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 0.5

                            color: "#666666"
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 0.5
                            color: "#666666"
                        }

                        // Right vertical border (lighter tone)
                        Rectangle {
                            visible: index !== 0
                            anchors.top: parent.top
                            anchors.topMargin: parent.height * 0.125
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.height * 0.125
                            anchors.right: parent.right
                            width: 0.5
                            color: "#AAAAAA"
                        }

                        MouseArea {
                            id: resizeArea
                            z: 1
                            anchors {
                                right: parent.right
                                rightMargin: -5
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: 10
                            cursorShape: Qt.SizeHorCursor
                            // Only allow left-button presses in the resize area
                            acceptedButtons: Qt.LeftButton
                            property real initialGlobalX: 0
                            property real initialWidth: 0

                            onPressed: {
                                initialGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                initialWidth = columnWidths[index];
                            }
                            onPositionChanged: {
                                var currentGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                var delta = currentGlobalX - initialGlobalX;
                                var newWidth = Math.max(minColumnWidths[index], initialWidth + delta);
                                if (Math.abs(newWidth - columnWidths[index]) > 1) {
                                    columnWidths[index] = newWidth;
                                    root.relayout_tables();
                                }
                            }
                        }
                    }
                }
            }

            // Data Table
            SmlScrollView {
                id: verticalScrollView
                anchors.top: headerRect.bottom
                anchors.left: headerRect.left
                width: headerRect.width
                height: root.__scroll_view_height - headerRect.height
                contentHeight: general_table.contentHeight + 20
                layout: SmlScrollBar.ScrollBarLayout.Vertical
                scrollbar_background_color: Settings.app_color_light
                scrollbar_background_nightmodel_color: Settings.app_color_dark
                flickableDirection: Flickable.VerticalFlick

                Rectangle {
                    id: tableRect
                    width: headerRect.width
                    height: general_table.contentHeight
                    color: "transparent"
                    onWidthChanged: {
                        Qt.callLater(root.relayout_tables)
                    }

                    TableView {
                        id: general_table
                        model: table_model
                        anchors{
                            top: parent.top
                            left: parent.left
                            bottom: parent.bottom
                        }
                        boundsBehavior: Flickable.StopAtBounds
                        rowHeightProvider: function(row) { return root.__data_height }
                        columnWidthProvider: function (column) {
                            {
                                var currentWidth = columnWidths[column];
                                if (column === columnWidths.length - 1 && scroll_view.width > sumMinColumnWidths) {
                                    var sum = 0;
                                    for (var i = 0; i < columnWidths.length - 1; i++) {
                                        sum += columnWidths[i];
                                    }
                                    var total = scroll_view.width - sum;
                                    if (total <= minColumnWidths[column]) {
                                        columnWidths[column] = minColumnWidths[column];
                                        var reduction = columnWidths[column];
                                        var idx = columnWidths.length - 2;
                                        while (reduction > 0 && idx >= 0) {
                                            var available = columnWidths[idx] - minColumnWidths[idx];
                                            if (available >= reduction) {
                                                columnWidths[idx] -= reduction;
                                                reduction = 0;
                                            } else {
                                                columnWidths[idx] = minColumnWidths[idx];
                                                reduction -= available;
                                            }
                                            idx--;
                                        }
                                        return minColumnWidths[column];
                                    }
                                    columnWidths[column] = total;
                                    return total;
                                }
                                return currentWidth;
                            }
                        }
                        width: root.__tables_width
                        contentWidth: root.__tables_width

                        delegate: Rectangle {
                            color: "transparent"
                            height: root.__data_height
                            implicitHeight: root.__data_height
                            implicitWidth: width

                            // Default renderer for all columns EXCEPT ML Model (column 2)
                            SmlText {
                                id: value
                                visible: column !== __suggested_model_column
                                width: parent.width
                                anchors.centerIn: parent
                                text_kind: SmlText.TextKind.Body
                                text_value: model.display
                                padding: __cell_padding
                                force_size: true
                                forced_size: 14
                                wrapMode: Text.WrapAnywhere
                            }

                            // ML Model (column 2): max 2 lines + ellipsis
                            Item {
                                id: mlModelCell
                                visible: column === __suggested_model_column
                                anchors.fill: parent
                                clip: true

                                MouseArea {
                                    id: mlHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }

                                // Custom styled tooltip
                                ToolTip {
                                    id: modelTip
                                    visible: mlHover.containsMouse
                                    delay: 250
                                    text: model.display
                                    y: -5

                                    background: Rectangle {
                                        radius: 8
                                        color: "#B0000000" // Opacity
                                        border.color: "#40FFFFFF"
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        text: modelTip.text
                                        color: "white"
                                        wrapMode: Text.WrapAnywhere
                                        width: 320
                                        font.pixelSize: 12
                                        padding: 10
                                    }
                                }

                                Text {
                                    anchors.fill: parent
                                    text: model.display

                                    wrapMode: Text.WrapAnywhere
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    clip: true

                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter

                                    leftPadding: __cell_padding
                                    rightPadding: __cell_padding + 10
                                    topPadding: 4
                                    bottomPadding: 4

                                    font.family: SustainMLFont.body_font
                                    font.pixelSize: 14
                                    color: ScreenManager.body_font_color
                                }
                            }

                            // Go reiterate button
                            SmlIcon
                            {
                                id: reiterate_button
                                visible: column === 0
                                name:   Settings.refresh_icon_name
                                color:  Settings.app_color_green_1
                                color_pressed:  Settings.app_color_green_2
                                nightmode_color:  Settings.app_color_green_4
                                nightmode_color_pressed:  Settings.app_color_green_3
                                size: Settings.button_icon_size
                                clickable_text: "Reiterate"

                                anchors
                                {
                                    verticalCenter: value.verticalCenter
                                    horizontalCenter: parent.horizontalCenter
                                }

                                onClicked: main_window.reiterate_problem(root.problem_id, table_model.rows[row])
                            }

                            // Checkbox to select iterations
                            CheckBox
                            {
                                visible: column === 1
                                checked: table_model.data(table_model.index(row, __check_column), "display") === "true"
                                enabled: !main_window.tasking
                                anchors{
                                    verticalCenter: value.verticalCenter
                                    horizontalCenter: parent.horizontalCenter
                                }
                                indicator.height: __data_height /2
                                indicator.width: indicator.height

                                onClicked: {
                                    var idx = table_model.index(row, __check_column)
                                    table_model.setData(idx, "display", checked ? "true" : "false")
                                    if (checked) {
                                        root.component_signal("general_view", "add_to_compare", table_model.rows[row]["Iteration"])
                                    }
                                    else{
                                        root.component_signal("general_view", "out_of_compare", table_model.rows[row]["Iteration"])
                                    }
                                }
                            }

                            // Bottom horizontal border (dark tone)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 0.5
                                color: "#666666"
                            }

                            // Right vertical border (lighter tone)
                            Rectangle {
                                anchors.top: parent.top
                                anchors.topMargin: parent.height * 0.125
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: parent.height * 0.125
                                anchors.right: parent.right
                                width: 0.5
                                color: "#AAAAAA"
                            }

                            MouseArea {
                                id: resizeArea
                                z: 1
                                anchors {
                                    right: parent.right
                                    rightMargin: -5
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: 10
                                cursorShape: Qt.SizeHorCursor
                                // Only allow left-button presses in the resize area
                                acceptedButtons: Qt.LeftButton
                                property real initialGlobalX: 0
                                property real initialWidth: 0

                                onPressed: {
                                    initialGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                    initialWidth = columnWidths[column];
                                }
                                onPositionChanged: {
                                    var currentGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                    var delta = currentGlobalX - initialGlobalX;
                                    var newWidth = Math.max(minColumnWidths[column], initialWidth + delta);
                                    if (Math.abs(newWidth - columnWidths[column]) > 1) {
                                        columnWidths[column] = newWidth;
                                        root.relayout_tables();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
