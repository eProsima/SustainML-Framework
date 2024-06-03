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

    // Public properties
    required property int problem_id
    required property int stack_id

    // Public signals
    signal component_signal(string signal_kind, string id)

    // Private properties
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __scroll_view_width: 1000
    readonly property int __scroll_view_height: height
    readonly property int __scroll_view_content_height: 700
    readonly property int __header_height: 40
    readonly property int __cell_padding: 10
    readonly property string __cell_background_color: "#fafafa"
    readonly property string __cell_background_nightmode_color: "#fafafa"
    readonly property int __check_column: 0
    readonly property int __iteration_column: 1
    readonly property int __problem_kind_column: 2
    readonly property int __suggested_model_column: 3
    readonly property int __power_consumption_column: 4
    readonly property int __memory_footprint_column: 5
    readonly property int __carbon_footprint_column: 6
    readonly property int __carbon_intensity_column: 7

    color: ScreenManager.night_mode ? Settings.app_color_dark : Settings.app_color_light

    TableModel {
        id: table_model
        TableModelColumn {display: "Check"}
        TableModelColumn {display: "Iteration"}
        TableModelColumn {display: "Problem kind"}
        TableModelColumn {display: "Suggested model"}
        TableModelColumn {display: "Power consumption"}
        TableModelColumn {display: "Memory footprint"}
        TableModelColumn {display: "Carbon footprint"}
        TableModelColumn {display: "Carbon intensity"}

        rows: []
            /*{"Check" : "false",
             "Iteration" : "1",
             "Problem kind" : "ImageClassification",
             "Suggested model" : "InceptionV4",
             "Power consumption" : "60",
             "Memory footprint" : "1240",
             "Carbon footprint" : "68",
             "Carbon intensity" : "12,15"
             },
             {"Check" : "true",
             "Iteration" : "2",
             "Problem kind" : "ImageClassification",
             "Suggested model" : "VIT",
             "Power consumption" : "65",
             "Memory footprint" : "1520",
             "Carbon footprint" : "82",
             "Carbon intensity" : "19,20"
             },
             {"Check" : "false",
             "Iteration" : "3",
             "Problem kind" : "ImageClassification",
             "Suggested model" : "InceptionV4",
             "Power consumption" : "58",
             "Memory footprint" : "1120",
             "Carbon footprint" : "63",
             "Carbon intensity" : "10,85"
             }
        ]*/

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
                    table_model.appendRow(
                        {
                            "Check" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : keywords,
                            "Suggested model" : "",
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
                }
                else
                {
                    table_model.appendRow(
                        {
                            "Check" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : model,
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
                    table_model.setData(table_model.index(row, __power_consumption_column), "display", power_consumption)
                    table_model.setData(table_model.index(row, __memory_footprint_column), "display", memory_footprint_of_ml_model)
                }
                else
                {
                    table_model.appendRow(
                        {
                            "Check" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : "",
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
                }
                else
                {
                    table_model.appendRow(
                        {
                            "Check" : "false",
                            "Iteration" : iteration_id,
                            "Problem kind" : "",
                            "Suggested model" : "",
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

        anchors
        {
            top: parent.top
            left: parent.left
        }
        width: root.__scroll_view_width
        height: root.__scroll_view_height
        content_width: general_header_table.contentWidth < general_table.contentWidth
                ? general_table.contentWidth + Settings.spacing_normal
                : general_header_table.contentWidth + Settings.spacing_normal
        content_height: general_header_table.height + general_table.height
        layout: SmlScrollBar.ScrollBarLayout.Both
        scrollbar_backgound_color: Settings.app_color_light
        scrollbar_backgound_nightmodel_color: Settings.app_color_dark

        TableView
        {
            id: general_header_table
            model: TableModel {
                TableModelColumn {display: "Check"}
                TableModelColumn {display: "Iteration"}
                TableModelColumn {display: "Problem kind"}
                TableModelColumn {display: "Suggested model"}
                TableModelColumn {display: "Power consumption"}
                TableModelColumn {display: "Memory footprint"}
                TableModelColumn {display: "Carbon footprint"}
                TableModelColumn {display: "Carbon intensity"}

                rows: [
                    {"Check" : "Check",
                     "Iteration" : "Iteration",
                     "Problem kind" : "Problem kind              ",
                     "Suggested model" : "Suggested model",
                     "Power consumption" : "Power consumption [W]",
                     "Memory footprint" : "Memory footprint",
                     "Carbon footprint" : "Carbon footprint [kgCO2e]",
                     "Carbon intensity" : "Carbon intensity [gCO2/kW]"}
                ]
            }
            anchors.top: parent.top
            anchors.left: parent.left
            width: root.__scroll_view_width * 2

            delegate: SmlText
            {
                height: __header_height
                text_kind: SmlText.TextKind.Header_3
                text_value: model.display
                padding: __cell_padding +1
                force_size: true
                forced_size: 16


                Rectangle
                {
                    anchors.fill: parent
                    color: ScreenManager.night_mode ? __cell_background_nightmode_color : __cell_background_color
                    z: -1
                }
            }
        }

        TableView
        {
            id: general_table
            model: table_model
            anchors.top: general_header_table.bottom
            anchors.topMargin: __header_height + __cell_padding
            anchors.left: parent.left
            width: root.__scroll_view_width * 2
            syncView: general_header_table

            delegate:  Item
            {
                height: implicitHeight
                implicitHeight: __header_height < value.implicitHeight ? value.implicitHeight : __header_height

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
                CheckBox
                {
                    visible: model.display === "true" || model.display === "false"
                    checked: model.display === "true"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: value.verticalCenter
                    indicator.height: __header_height /2
                    indicator.width: indicator.height
                }
            }
        }
    }
}
