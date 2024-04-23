// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 1.4

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Item
{
    id: root

    // Internal properties
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __scroll_view_width: 1000
    readonly property int __scroll_view_height: 600
    readonly property int __scroll_view_content_height: 1680
    readonly property int __input_height: 80
    readonly property int __input_height_big: 200
    readonly property int __input_width: 900
    readonly property int __input_width_split: 425
    readonly property int __input_width_small: 250

    // Input values
    property string __problem_short_description: ""
    property string __modality: ""
    property string __problem_definition: ""
    property string __inputs: ""
    property string __outputs: ""
    property int __minimum_samples: 1
    property int __maximum_samples: 1
    property bool __optimize_carbon_footprint_auto: false
    property bool __optimize_carbon_footprint_manual: false
    property int __previous_iteration: 0
    property double __desired_carbon_footprint: 0.0
    property string __geo_location_continent: ""
    property string __geo_location_region: ""
    property string __extra_data: ""

    // External signals
    signal go_home();
    signal send_task(
        string problem_short_description,
        string modality,
        string problem_definition,
        string inputs,
        string outputs,
        int minimum_samples,
        int maximum_samples,
        bool optimize_carbon_footprint_auto,
        bool optimize_carbon_footprint_manual,
        int previous_iteration,
        double desired_carbon_footprint,
        string geo_location_continent,
        string geo_location_region,
        string extra_data
    );

    // Go home button
    SmlButton
    {
        icon_name: Settings.home_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: "Home"
        rounded: true
        color: Settings.app_color_green_3
        color_pressed: Settings.app_color_green_1
        nightmode_color: Settings.app_color_green_1
        nightmode_color_pressed: Settings.app_color_green_3
        anchors
        {
            top: parent.top
            topMargin: Settings.spacing_normal
            left: parent.left
            leftMargin: Settings.spacing_normal
        }
        onClicked: root.go_home()
    }

    ScrollView
    {
        id: scroll_view
        verticalScrollBarPolicy: Qt.ScrollBarAlwaysOn
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        anchors
        {
            top: parent.top
            topMargin: root.__margin
            left: parent.left
            leftMargin: root.__margin
        }
        width: root.__scroll_view_width
        height: root.__scroll_view_height

        contentItem: Rectangle
        {
            color: "transparent"
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.width
            height: root.__scroll_view_content_height

            // Problem short description
            SmlText
            {
                id: problem_short_description_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Problem short description"
                anchors
                {
                    top: parent.top
                    left: parent.left
                }
            }
            SmlInput
            {
                id: problem_short_description_input
                placeholder_text: "Resume briefly the objetive of the problem"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width
                height: root.__input_height
                anchors
                {
                    top: problem_short_description_header.bottom
                    topMargin: Settings.spacing_small
                    left: problem_short_description_header.left
                }
                onText_changed:
                {
                    root.__problem_short_description = text;
                }
            }

            // Modality
            SmlText
            {
                id: modality_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Modality"
                anchors
                {
                    top: problem_short_description_input.bottom
                    topMargin: Settings.spacing_normal
                    left: parent.left
                }
            }
            SmlInput
            {
                id: modality_input
                placeholder_text: "Define the modality of the input data: image, video, audio, sensor..."
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width
                height: root.__input_height
                anchors
                {
                    top: modality_header.bottom
                    topMargin: Settings.spacing_small
                    left: modality_header.left
                }
                onText_changed:
                {
                    root.__modality = text;
                }
            }

            // Problem definition
            SmlText
            {
                id: problem_definition_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Problem definition"
                anchors
                {
                    top: modality_input.bottom
                    topMargin: Settings.spacing_normal
                    left: parent.left
                }
            }
            SmlInput
            {
                id: problem_definition_input
                placeholder_text: "Define as precisely as possible the machine learning problem to be evaluated"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width
                height: root.__input_height_big
                anchors
                {
                    top: problem_definition_header.bottom
                    topMargin: Settings.spacing_small
                    left: problem_definition_header.left
                }
                onText_changed:
                {
                    root.__problem_definition = text;
                }
            }

            // Inputs
            SmlText
            {
                id: inputs_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Inputs"
                anchors
                {
                    top: problem_definition_input.bottom
                    topMargin: Settings.spacing_normal
                    left: parent.left
                }
            }
            SmlInput
            {
                id: inputs_input
                placeholder_text: "Describe a sequence of serialized batches of input data"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width
                height: root.__input_height_big
                anchors
                {
                    top: inputs_header.bottom
                    topMargin: Settings.spacing_small
                    left: inputs_header.left
                }
                onText_changed:
                {
                    root.__inputs = text;
                }
            }

            // Outputs
            SmlText
            {
                id: outputs_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Outputs"
                anchors
                {
                    top: inputs_input.bottom
                    topMargin: Settings.spacing_normal
                    left: parent.left
                }
            }
            SmlInput
            {
                id: outputs_input
                placeholder_text: "Describe a sequence of serialized batches of output data"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width
                height: root.__input_height_big
                anchors
                {
                    top: outputs_header.bottom
                    topMargin: Settings.spacing_small
                    left: outputs_header.left
                }
                onText_changed:
                {
                    root.__outputs = text;
                }
            }

            // Minimum samples
            SmlText
            {
                id: minimum_samples_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Minimum samples"
                anchors
                {
                    top: outputs_input.bottom
                    topMargin: Settings.spacing_normal
                    left: parent.left
                }
            }
            SmlInput
            {
                id: minimum_samples_input
                placeholder_text: "Min samples required"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width_small
                height: root.__input_height
                anchors
                {
                    top: minimum_samples_header.bottom
                    topMargin: Settings.spacing_small
                    left: minimum_samples_header.left
                }
                onText_changed:
                {
                    root.__minimum_samples = parseInt(text);
                }
            }

            // Maximum samples
            SmlText
            {
                id: maximum_samples_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Maximum samples"
                anchors
                {
                    top: minimum_samples_header.top
                    left: minimum_samples_header.right
                    leftMargin: Settings.spacing_normal
                }
            }
            SmlInput
            {
                id: maximum_samples_input
                placeholder_text: "Max samples required"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width_small
                height: root.__input_height
                anchors
                {
                    top: maximum_samples_header.bottom
                    topMargin: Settings.spacing_small
                    left: maximum_samples_header.left
                }
                onText_changed:
                {
                    root.__maximum_samples = parseInt(text);
                }
            }

            // Carbon footprint optimization
            SmlText
            {
                id: optimize_carbon_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Carbon footprint optimization"
                anchors
                {
                    top: maximum_samples_header.top
                    left: maximum_samples_header.right
                    leftMargin: Settings.spacing_normal
                }
            }
            SmlCombobox
            {
                id: optimize_carbon_input
                placeholder_text: "Select optimization iteration method"
                model: ["Manual", "Auto"]
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: 360
                height: root.__input_height
                rounded_radius: Settings.input_default_rounded_radius
                anchors
                {
                    top: optimize_carbon_header.bottom
                    topMargin: Settings.spacing_small
                    left: optimize_carbon_header.left
                }
                onText_changed:
                {
                    if (text === "Manual")
                    {
                        root.__optimize_carbon_footprint_auto = false;
                        root.__optimize_carbon_footprint_manual = true;
                    }
                    else if (text === "Auto")
                    {
                        root.__optimize_carbon_footprint_auto = true;
                        root.__optimize_carbon_footprint_manual = false;
                    }
                    else
                    {
                        root.__optimize_carbon_footprint_auto = false;
                        root.__optimize_carbon_footprint_manual = false;
                    }
                }
            }

            // Previous iteration
            SmlText
            {
                id: previous_iteration_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Previous iteration"
                anchors
                {
                    top: minimum_samples_input.bottom
                    topMargin: Settings.spacing_normal
                    left: parent.left
                }
            }
            SmlInput
            {
                id: previous_iteration_input
                placeholder_text: "Set previous iteration from which to perform the optimization (-1 takes last one)"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width_split
                height: root.__input_height
                anchors
                {
                    top: previous_iteration_header.bottom
                    topMargin: Settings.spacing_small
                    left: previous_iteration_header.left
                }
                onText_changed:
                {
                    root.__previous_iteration = parseInt(text);
                }
            }

            // Desired carbon footprint
            SmlText
            {
                id: desired_carbon_footprint_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Desired carbon footprint"
                anchors
                {
                    top: previous_iteration_header.top
                    left: previous_iteration_input.right
                    leftMargin: Settings.spacing_big
                }
            }
            SmlInput
            {
                id: desired_carbon_footprint_input
                placeholder_text: "Optimization aimed value for carbon footprint"
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width_split
                height: root.__input_height
                anchors
                {
                    top: desired_carbon_footprint_header.bottom
                    topMargin: Settings.spacing_small
                    left: desired_carbon_footprint_header.left
                }
                onText_changed:
                {
                    root.__desired_carbon_footprint = parseFloat(text);
                }
            }

            // Geo location: continent
            SmlText
            {
                id: geo_location_continent_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Geo location: continent"
                anchors
                {
                    top: previous_iteration_input.bottom
                    topMargin: Settings.spacing_normal
                    left: parent.left
                }
            }
            SmlInput
            {
                id: geo_location_continent_input
                placeholder_text: "Set continent for the geo location" // TODO combobox
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width_split
                height: root.__input_height
                anchors
                {
                    top: geo_location_continent_header.bottom
                    topMargin: Settings.spacing_small
                    left: geo_location_continent_header.left
                }
                onText_changed:
                {
                    root.__geo_location_continent = text;
                }
            }

            // Geo location: region
            SmlText
            {
                id: geo_location_region_header
                text_kind: SmlText.TextKind.Header_3
                text_value: "Geo location: region"
                anchors
                {
                    top: geo_location_continent_header.top
                    left: geo_location_continent_input.right
                    leftMargin: Settings.spacing_big
                }
            }
            SmlInput
            {
                id: geo_location_region_input
                placeholder_text: "Set region for the geo location" // TODO combobox
                border_color: Settings.app_color_green_3
                border_editting_color: Settings.app_color_green_4
                border_nightmode_color: Settings.app_color_green_1
                border_nightmode_editting_color: Settings.app_color_green_2
                background_color: Settings.app_color_light
                background_nightmode_color: Settings.app_color_dark
                width: root.__input_width_split
                height: root.__input_height
                anchors
                {
                    top: geo_location_region_header.bottom
                    topMargin: Settings.spacing_small
                    left: geo_location_region_header.left
                }
                onText_changed:
                {
                    root.__geo_location_region = text;
                }
            }
        }
    }

    // Submit button
    SmlButton
    {
        icon_name: Settings.submit_icon_name
        text_kind: SmlText.TextKind.Header_3
        text_value: "Submit"
        rounded: true
        color: Settings.app_color_light
        color_pressed: Settings.app_color_green_1
        nightmode_color: Settings.app_color_dark
        nightmode_color_pressed: Settings.app_color_green_3
        anchors
        {
            bottom: parent.bottom
            bottomMargin: root.__margin - Settings.spacing_normal
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: -root.__margin
        }
        onClicked: root.prepare_task()
    }

    function prepare_task()
    {
        root.send_task(
                root.__problem_short_description,
                root.__modality,
                root.__problem_definition,
                root.__inputs,
                root.__outputs,
                root.__minimum_samples,
                root.__maximum_samples,
                root.__optimize_carbon_footprint_auto,
                root.__optimize_carbon_footprint_manual,
                root.__previous_iteration,
                root.__desired_carbon_footprint,
                root.__geo_location_continent,
                root.__geo_location_region,
                root.__extra_data);
    }
}
