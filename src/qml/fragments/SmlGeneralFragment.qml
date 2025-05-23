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
    property var minColumnWidths: [90, 80, 110, 160, 150, 160, 170, 180, 185]
    property int sumMinColumnWidths: {
        var total = 0;
        for (var i = 0; i < minColumnWidths.length; i++) {
            total += minColumnWidths[i];
        }
        return total;
    }
    property var columnWidths: [90, 80, 110, 160, 150, 160, 170, 180, 185]
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __scroll_view_height: height
    readonly property int __scroll_view_content_height: 700
    readonly property int __header_height: 40
    readonly property int __cell_padding: 10
    readonly property string __cell_background_color: "#e0e0e0"
    readonly property string __cell_background_nightmode_color: "#505050"
    readonly property int __check_column: 0
    readonly property int __iteration_column: 1
    readonly property int __problem_kind_column: 2
    readonly property int __suggested_model_column: 3
    readonly property int __hw_description_column: 4
    readonly property int __power_consumption_column: 5
    readonly property int __memory_footprint_column: 6
    readonly property int __carbon_footprint_column: 7
    readonly property int __carbon_intensity_column: 8

    color: ScreenManager.night_mode ?  Settings.app_color_dark : Settings.app_color_light

    TableModel {
        id: table_model
        TableModelColumn {display: "Reiterate"}
        TableModelColumn {display: "Iteration"}
        TableModelColumn {display: "Problem kind"}
        TableModelColumn {display: "Suggested model"}
        TableModelColumn {display: "Suggested hardware"}
        TableModelColumn {display: "Power consumption"}
        TableModelColumn {display: "Memory footprint"}
        TableModelColumn {display: "Carbon footprint"}
        TableModelColumn {display: "Carbon intensity"}

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
                    general_table.height = __header_height * table_model.rows.length;
                }
                else
                {
                    var newRows = table_model.rows
                    newRows.push({
                            "Reiterate" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : keywords,
                            "Suggested model" : "",
                            "Suggested hardware" : "",
                            "Power consumption" : "",
                            "Memory footprint" : "",
                            "Carbon footprint" : "",
                            "Carbon intensity" : ""
                        }
                    )
                    table_model.rows = newRows
                }
            }
            general_table.forceLayout();
        }

        function onNew_ml_model_node_output(problem_id, iteration_id, model, model_path, properties, properties_path, input_batch, target_latency)
        {
            if (problem_id === root.problem_id)
            {
                var row = table_model.contains(iteration_id)
                if(row >= 0)
                {
                    table_model.setData(table_model.index(row, __suggested_model_column), "display", model)
                    general_table.height = __header_height * table_model.rows.length;
                }
                else
                {
                    var newRows = table_model.rows
                    newRows.push({
                            "Reiterate" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : model,
                            "Suggested hardware" : "",
                            "Power consumption" : "",
                            "Memory footprint" : "",
                            "Carbon footprint" : "",
                            "Carbon intensity" : ""
                        }
                    )
                    table_model.rows = newRows
                }
            }
            general_table.forceLayout();
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
                    table_model.setData(table_model.index(row, __memory_footprint_column), "display", memory_footprint_of_ml_model)
                    general_table.height = __header_height * table_model.rows.length;
                }
                else
                {
                    var newRows = table_model.rows
                    newRows.push({
                            "Reiterate" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : "",
                            "Suggested hardware" : hw_description,
                            "Power consumption" : power_consumption,
                            "Memory footprint" : memory_footprint_of_ml_model,
                            "Carbon footprint" : "",
                            "Carbon intensity" : ""
                        }
                    )
                    table_model.rows = newRows
                }
            }
            general_table.forceLayout();
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
                    general_table.height = __header_height * table_model.rows.length;
                }
                else
                {
                    console.log("Creando una nueva fila para iteration_id:", iteration_id)
                    var newRows = table_model.rows
                    newRows.push({
                            "Reiterate" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : "",
                            "Suggested hardware" : "",
                            "Power consumption" : "",
                            "Memory footprint" : "",
                            "Carbon footprint" : carbon_footprint,
                            "Carbon intensity" : carbon_intensity
                        }
                    )
                    table_model.rows = newRows;
                }
            }
            general_table.forceLayout();
        }
    }

    Rectangle {
        id: splitRow
        anchors.fill: parent

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
            scrollbar_backgound_color: Settings.app_color_light
            scrollbar_backgound_nightmodel_color: Settings.app_color_dark
            interactive: false

            // Header
            Rectangle {
                id: headerRect
                anchors.top: parent.top
                anchors.left: parent.left
                width: scroll_view.width > general_header_table.contentWidth ? scroll_view.width : general_header_table.contentWidth
                height: __header_height
                color: ScreenManager.night_mode ? __cell_background_nightmode_color : __cell_background_color
                onWidthChanged: {
                    general_header_table.forceLayout(),
                    general_table.forceLayout();
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
                            if (column === 8 && scroll_view.width > sumMinColumnWidths) {
                                var sum = 0;
                                for (var i = 0; i < columnWidths.length - 1; i++) {
                                    sum += columnWidths[i];
                                }
                                var total = scroll_view.width - sum;
                                if (total <= minColumnWidths[column]) {
                                    return minColumnWidths[column];
                                }
                                columnWidths[column] = total;
                                return total;
                            }
                            return currentWidth;
                        }
                    }
                    width: contentItem.childrenRect.width + 1
                    contentWidth: contentItem.childrenRect.width + 1
                    // onWidthChanged: forceLayout()
                    // columnWidthProvider: getColumnWidth(column)

                    model: TableModel {
                        TableModelColumn {display: "Reiterate"}
                        TableModelColumn {display: "Iteration"}
                        TableModelColumn {display: "Problem kind"}
                        TableModelColumn {display: "Suggested model"}
                        TableModelColumn {display: "Suggested hardware"}
                        TableModelColumn {display: "Memory footprint"}
                        TableModelColumn {display: "Power consumption"}
                        TableModelColumn {display: "Carbon footprint"}
                        TableModelColumn {display: "Carbon intensity"}

                        rows: [
                            {"Reiterate" : "        ",
                            "Iteration" : "Iteration",
                            "Problem kind" : "Problem",
                            "Suggested model" : "ML Model",
                            "Suggested hardware" : "Hardware",
                            "Memory footprint" : "Memory Footprint [MB]",
                            "Power consumption" : "Power Consumption [W]",
                            "Carbon footprint" : "Carbon Footprint [kgCO2e]",
                            "Carbon intensity" : "Carbon Intensity [gCO2/kW]"}
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
                            anchors.top: parent.top - 0.5
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
                                initialWidth = columnWidths[index];
                            }
                            onPositionChanged: {
                                var currentGlobalX = mapToItem(null, mouse.x, mouse.y).x;
                                var delta = currentGlobalX - initialGlobalX;
                                var newWidth = Math.max(minColumnWidths[index], initialWidth + delta);
                                if (Math.abs(newWidth - columnWidths[index]) > 1) {
                                    columnWidths[index] = newWidth;
                                    general_header_table.forceLayout();
                                }
                            }
                            onReleased: {
                                console.log("Nuevo ancho para la columna", index, ":", columnWidths[index]);
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
                height: root.height - headerRect.height
                contentHeight: general_table.height + 20
                layout: SmlScrollBar.ScrollBarLayout.Vertical
                scrollbar_backgound_color: Settings.app_color_light
                scrollbar_backgound_nightmodel_color: Settings.app_color_dark
                // interactive: false

                // Background mouse area
                MouseArea
                {
                    anchors.fill: parent
                    onClicked: focus = true
                }

                Rectangle {
                    id: tableRect
                    width: headerRect.width
                    height: __header_height * table_model.rows.length
                    color: "transparent"

                    TableView {
                        id: general_table
                        model: table_model
                        anchors.fill: parent
                        syncView: general_header_table

                        delegate: Rectangle {
                            color: "transparent"
                            height: implicitHeight
                            implicitHeight: __header_height < value.implicitHeight ? value.implicitHeight : __header_height

                            SmlText {
                                id: value
                                visible: column !== 0
                                width: parent.width
                                anchors.centerIn: parent
                                text_kind: SmlText.TextKind.Body
                                text_value: model.display
                                padding: __cell_padding
                                force_size: true
                                forced_size: 14
                                wrapMode: TextEdit.Wrap
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

                                anchors
                                {
                                    verticalCenter: value.verticalCenter
                                    left: parent.left
                                    leftMargin: Settings.spacing_small
                                }

                                SmlMouseArea
                                {
                                    anchors.centerIn: parent
                                    hoverEnabled: true
                                    width: parent.width * 1.5
                                    height: parent.height * 1.5
                                    onPressed: reiterate_button.pressed = true;
                                    onReleased: reiterate_button.pressed = false;
                                    onClicked:
                                    {
                                        main_window.reiterate_problem(root.problem_id, table_model.rows[index])
                                    }
                                }
                            }

                            // Checkbox to select iterations
                            CheckBox
                            {
                                visible: column === 0
                                // checked: model.display === "true"
                                anchors{
                                    verticalCenter: value.verticalCenter
                                    right: parent.right
                                    rightMargin: Settings.spacing_small
                                }
                                indicator.height: __header_height /2
                                indicator.width: indicator.height

                                onCheckedChanged: {
                                    console.log("Checked changed to: " + checked)
                                    if (checked) {
                                        root.component_signal("general_view", "add_to_compare", table_model.rows[index]["Iteration"])
                                    }
                                    else{
                                        root.component_signal("general_view", "out_of_compare", table_model.rows[index]["Iteration"])
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
                                        general_header_table.forceLayout();
                                    }
                                }
                                onReleased: {
                                    console.log("Nuevo ancho para la columna", column, ":", columnWidths[column]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
