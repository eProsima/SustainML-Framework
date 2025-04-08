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

        rows: [
            // {"Reiterate" : "false",
            //  "Iteration" : "1",
            //  "Problem kind" : "ImageClassification",
            //  "Suggested model" : "InceptionV4",
            //  "Suggested hardware" : "NVIDIA GeForce RTX 3090",
            //  "Power consumption" : "60",
            //  "Memory footprint" : "1240",
            //  "Carbon footprint" : "68",
            //  "Carbon intensity" : "12,15"
            //  },
            //  {"Reiterate" : "false",
            //  "Iteration" : "2",
            //  "Problem kind" : "ImageClassification",
            //  "Suggested model" : "VIT",
            //  "Suggested hardware" : "NVIDIA GeForce RTX 3070",
            //  "Power consumption" : "65",
            //  "Memory footprint" : "1520",
            //  "Carbon footprint" : "82",
            //  "Carbon intensity" : "19,20"
            //  },
            //  {"Reiterate" : "false",
            //  "Iteration" : "3",
            //  "Problem kind" : "ImageClassification",
            //  "Suggested model" : "InceptionV4",
            //  "Suggested hardware" : "P3",
            //  "Power consumption" : "58",
            //  "Memory footprint" : "1120",
            //  "Carbon footprint" : "63",
            //  "Carbon intensity" : "10,85"
            //  }
        ]

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
                    table_model.appendRow(
                        {
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
                }
            }
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
                    table_model.appendRow(
                        {
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
                }
            }
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
                    table_model.appendRow(
                        {
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
                }
            }
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
                    table_model.appendRow(
                        {
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
                }
            }
        }
    }

    SmlScrollView
    {
        id: scroll_view

        anchors.fill: parent
        width: parent.width
        height: root.__scroll_view_height
        content_width: general_header_table.contentWidth
        content_height: general_header_table.height + general_table.height
        layout: SmlScrollBar.ScrollBarLayout.Both
        scrollbar_backgound_color: Settings.app_color_light
        scrollbar_backgound_nightmodel_color: Settings.app_color_dark

        Rectangle{
            id: general_header
            anchors.top: parent.top
            anchors.left: parent.left
            width: scroll_view.width > general_header_table.contentWidth ? scroll_view.width : general_header_table.contentWidth
            height: __header_height
            color: ScreenManager.night_mode ? __cell_background_nightmode_color : __cell_background_color

            TableView
            {
                id: general_header_table
                anchors{
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
                width: contentItem.childrenRect.width + 20
                contentWidth: contentItem.childrenRect.width + 20

                model: TableModel {
                    TableModelColumn {display: "Reiterate"}
                    TableModelColumn {display: "Iteration"}
                    TableModelColumn {display: "Problem kind"}
                    TableModelColumn {display: "Suggested model"}
                    TableModelColumn {display: "Suggested hardware"}
                    TableModelColumn {display: "Power consumption"}
                    TableModelColumn {display: "Memory footprint"}
                    TableModelColumn {display: "Carbon footprint"}
                    TableModelColumn {display: "Carbon intensity"}

                    rows: [
                        {"Reiterate" : "                    ",
                        "Iteration" : "Iteration",
                        "Problem kind" : "Problem kind              ",
                        "Suggested model" : "Suggested model",
                        "Suggested hardware" : "Suggested hardware",
                        "Power consumption" : "Power consumption [W]",
                        "Memory footprint" : "Memory footprint",
                        "Carbon footprint" : "Carbon footprint [kgCO2e]",
                        "Carbon intensity" : "Carbon intensity [gCO2/kW]"}
                    ]
                }

                delegate: SmlText
                {
                    height: __header_height
                    text_kind: SmlText.TextKind.Header_3
                    text_value: model.display
                    padding: __cell_padding +1
                    force_size: true
                    forced_size: 16
                }
            }
        }

        Rectangle{
            id: general_table_rect
            anchors.top: general_header.bottom
            anchors.topMargin: __cell_padding
            anchors.left: general_header.left
            // height: __header_height * table_model.rows.length
            width: general_header.width
            color: "transparent"

            TableView
            {
                id: general_table
                model: table_model
                anchors {
                    top: parent.top
                    left: parent.left
                }
                // height: parent.height
                height: __header_height * table_model.rows.length
                width: parent.width > contentItem.childrenRect.width + 20 ? parent.width : contentItem.childrenRect.width + 20
                contentWidth: contentItem.childrenRect.width + 20
                syncView: general_header_table

                delegate:  Item
                {
                    height: implicitHeight
                    implicitHeight: __header_height < value.implicitHeight ? value.implicitHeight : __header_height
                    implicitWidth: 1

                    SmlText
                    {
                        id: value
                        width: parent.width
                        visible: !(model.display === "true" || model.display === "false")
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
                        visible: model.display === "true" || model.display === "false"
                        name:   Settings.refresh_icon_name
                        color:  Settings.app_color_green_1
                        color_pressed:  Settings.app_color_green_2
                        nightmode_color:  Settings.app_color_green_4
                        nightmode_color_pressed:  Settings.app_color_green_3
                        size: Settings.button_icon_size

                        anchors
                        {
                            top: parent.top
                            topMargin: Settings.spacing_small
                            horizontalCenter: parent.horizontalCenter
                            horizontalCenterOffset: -Settings.spacing_normal
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
                        visible: model.display === "true" || model.display === "false"
                        checked: model.display === "true"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: Settings.spacing_big
                        anchors.verticalCenter: value.verticalCenter
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
                }
            }
        }
    }
}
