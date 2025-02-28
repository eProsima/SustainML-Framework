// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

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
    readonly property int __scroll_view_content_height: 1800
    readonly property int __input_height: 80
    readonly property int __input_height_big: 200
    readonly property int __input_width: 900
    readonly property int __input_width_split: 425
    readonly property int __input_width_small: 250

    // Input values
    property string __problem_short_description: ""
    property string __modality: ""
    property var __metrics_values: {}
    property string __problem_definition: ""
    property string __inputs: ""
    property string __outputs: ""
    property int __minimum_samples: 1
    property int __maximum_samples: 1
    property bool __optimize_carbon_footprint_auto: false
    property string __goal: ""
    property bool __optimize_carbon_footprint_manual: false
    property int __previous_iteration: 0
    property double __desired_carbon_footprint: 0.0
    property int __max_memory_footprint: 0
    property string __hardware_required: ""
    property string __geo_location_continent: ""
    property string __geo_location_region: ""
    property string __extra_data: ""

    // Private properties
    property var __modality_list: []
    property var __goal_list: []
    property var __metrics: []
    property var __hardware_list: []
    property bool __refreshing: false

    // External signals
    signal go_home();
    signal go_results();
    signal send_task(
        string problem_short_description,
        string modality,
        string problem_definition,
        string inputs,
        string outputs,
        int minimum_samples,
        int maximum_samples,
        bool optimize_carbon_footprint_auto,
        string goal,
        bool optimize_carbon_footprint_manual,
        int previous_iteration,
        double desired_carbon_footprint,
        string max_memory_footprint,
        string hardware_required,
        string geo_location_continent,
        string geo_location_region,
        string extra_data
    );
    signal refresh();
    signal ask_metrics(
        string metric_req_type,
        string req_type_values
    );

    // Background mouse area
    MouseArea
    {
        anchors.fill: parent
        onClicked: focus = true
    }

    // Go home button
    SmlButton
    {
        id: home_button
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

    // Go results button
    SmlButton
    {
        icon_name: Settings.start_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: "Results"
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        anchors
        {
            top: parent.top
            topMargin: Settings.spacing_normal
            left: home_button.right
            leftMargin: Settings.spacing_normal
        }
        onClicked: root.go_results()
    }

    SmlScrollView
    {
        id: scroll_view

        anchors.fill: parent

        anchors
        {
            topMargin: root.__margin
            leftMargin: root.__margin
            rightMargin: root.__margin
            bottomMargin: root.__margin
        }

        width: root.__scroll_view_width
        height: root.__scroll_view_height
        content_width: root.__scroll_view_width
        content_height: root.__scroll_view_content_height + metrics_list.height

        // Background mouse area
        MouseArea
        {
            anchors.fill: parent
            onClicked: focus = true
        }

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
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height
            KeyNavigation.tab: modality_input
            anchors
            {
                top: problem_short_description_header.bottom
                topMargin: Settings.spacing_small
                left: problem_short_description_header.left
            }
            onTextChanged:
            {
                root.__problem_short_description = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(problem_short_description_input.y - Settings.spacing_big)
                }
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
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: modality_input
            placeholder_text: "Select the modality of the input data"
            model: root.__modality_list
            border_color: Settings.app_color_green_3
            border_editting_color: Settings.app_color_green_4
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: 60
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: problem_definition_input
            anchors
            {
                top: modality_header.bottom
                topMargin: Settings.spacing_small
                left: modality_header.left
            }
            onModelChanged:
            {
                modality_input.currentIndex = -1
            }
            onText_changed:
            {
                root.__modality = text;
                // root.__metrics = []


                // TODO: Get metrics with request of metrics given the modality
                if (text === "audio")
                {
                    // root.__metrics = ["Longiness", "Emptiness", "Something", "Metricable"]
                }
                if (text === "cv")
                {
                    root.ask_metrics(     // First word indicate type of metric reception (modality or problem)
                        "modality",       //  and second values for the search (in modalities ins & out modalities, and problem type in other case)
                        "Image, Label");
                }
                if (text === "nlp")
                {
                    root.ask_metrics(           // First word indicate type of metric reception (modality or problem)
                        "problem",              //  and second values for the search (in modalities ins & out modalities, and problem type in other case)
                        "audio-text-to-text");
                }

                root.__metrics_values = {}  // clear old data
                for (var i = 0; i < root.__metrics.length; i++) {
                    var metric = root.__metrics[i]
                    root.__metrics_values[metric] = ""
                }
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    modality_input.open()
                    modality_input.focus = true
                }
            }
            onTab_pressed: {
                problem_definition_input.focus = true
            }
        }

        // Metrics
        SmlText
        {
            id: metrics_header
            visible: root.__metrics.length > 0
            text_kind: SmlText.TextKind.Header_3
            text_value: "Metrics"
            anchors
            {
                top: modality_input.bottom
                topMargin: root.__metrics.length > 0 ? Settings.spacing_normal : 0
                left: parent.left
            }
        }

        // Metric Item
        Component
        {
            id: metric_item

            Row {
                required property string modelData
                spacing: Settings.spacing_normal

                SmlText {
                    id: metric_text
                    text_kind: SmlText.TextKind.Header_3
                    text_value: modelData
                    anchors.verticalCenter: parent.verticalCenter
                }

                SmlInput {
                    id: metric_input
                    placeholder_text: "Enter value for " + modelData
                    border_color: Settings.app_color_green_3
                    border_editting_color: Settings.app_color_green_4
                    border_nightmode_color: Settings.app_color_green_1
                    border_nightmode_editting_color: Settings.app_color_green_2
                    background_color: Settings.app_color_light
                    background_nightmode_color: Settings.app_color_dark
                    width: root.__input_width_split
                    height: root.__input_height
                    anchors.verticalCenter: parent.verticalCenter
                    onTextChanged: {
                        root.__metrics_values[modelData] = text;
                        // console.log(root.__metrics_values)
                    }
                    onFocusChanged: {
                        if (focus === true) {
                            scroll_view.scroll_to(y - Settings.spacing_big)
                        }
                    }
                }
            }
        }

        ListView {
            id: metrics_list
            visible: root.__metrics.length > 0
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__metrics.length * (root.__input_height + Settings.spacing_normal)
            spacing: Settings.spacing_normal
            anchors
            {
                top: metrics_header.bottom
                topMargin: root.__metrics.length > 0 ? Settings.spacing_small : 0
                left: parent.left
                leftMargin: Settings.spacing_big
            }
            model: root.__metrics
            delegate: metric_item
        }

        // Problem definition
        SmlText
        {
            id: problem_definition_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Problem definition"
            anchors
            {
                top: root.__metrics.length > 0 ? metrics_list.bottom : modality_input.bottom
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
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height_big
            KeyNavigation.tab: inputs_input
            anchors
            {
                top: problem_definition_header.bottom
                topMargin: Settings.spacing_small
                left: problem_definition_header.left
            }
            onTextChanged:
            {
                root.__problem_definition = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(problem_definition_input.y - Settings.spacing_big)
                }
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
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height_big
            KeyNavigation.tab: outputs_input
            anchors
            {
                top: inputs_header.bottom
                topMargin: Settings.spacing_small
                left: inputs_header.left
            }
            onTextChanged:
            {
                root.__inputs = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(inputs_input.y - Settings.spacing_big)
                }
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
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height_big
            KeyNavigation.tab: minimum_samples_input
            anchors
            {
                top: outputs_header.bottom
                topMargin: Settings.spacing_small
                left: outputs_header.left
            }
            onTextChanged:
            {
                root.__outputs = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(outputs_input.y - Settings.spacing_big)
                }
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
            KeyNavigation.tab: maximum_samples_input
            anchors
            {
                top: minimum_samples_header.bottom
                topMargin: Settings.spacing_small
                left: minimum_samples_header.left
            }
            onTextChanged:
            {
                root.__minimum_samples = parseInt(text);
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(minimum_samples_input.y - Settings.spacing_big)
                }
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
                left: minimum_samples_input.right
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
            KeyNavigation.tab: optimize_carbon_input
            anchors
            {
                top: maximum_samples_header.bottom
                topMargin: Settings.spacing_small
                left: maximum_samples_header.left
            }
            onTextChanged:
            {
                root.__maximum_samples = parseInt(text);
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(maximum_samples_input.y - Settings.spacing_big)
                }
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
                left: maximum_samples_input.right
                leftMargin: Settings.spacing_normal
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
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
            KeyNavigation.tab: goal_input
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
            onFocusChanged: {
                if(focus === true){
                    optimize_carbon_input.open()
                    optimize_carbon_input.focus = true
                }
            }
            onTab_pressed: {
                goal_input.focus = true
            }
        }

        // Goal selection
        SmlText
        {
            id: goal_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Model Goal"
            anchors
            {
                top: minimum_samples_input.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: goal_input
            placeholder_text: "Select your model goal"
            model: root.__goal_list
            border_color: Settings.app_color_green_3
            border_editting_color: Settings.app_color_green_4
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width_split
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: desired_carbon_footprint_input
            anchors
            {
                top: goal_header.bottom
                topMargin: Settings.spacing_small
                left: goal_header.left
            }
            onModelChanged:
            {
                goal_input.currentIndex = -1
            }
            onText_changed:
            {
                root.__goal = text;
            }
            onFocusChanged: {
                if(focus === true){
                    goal_input.open()
                    goal_input.focus = true
                }
            }
            onTab_pressed: {
                desired_carbon_footprint_input.focus = true
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
                top: goal_header.top
                left: goal_input.right
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
            KeyNavigation.tab: max_mem_footprint_input
            anchors
            {
                top: desired_carbon_footprint_header.bottom
                topMargin: Settings.spacing_small
                left: desired_carbon_footprint_header.left
            }
            onTextChanged:
            {
                root.__desired_carbon_footprint = parseFloat(text);
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(desired_carbon_footprint_input.y - Settings.spacing_big)
                }
            }
        }

        // Max mem footprint
        SmlText
        {
            id: max_mem_footprint_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Max memory footprint"
            anchors
            {
                top: goal_input.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
            }
        }
        SmlInput
        {
            id: max_mem_footprint_input
            placeholder_text: "Set maximum memory footprint allowed"
            border_color: Settings.app_color_green_3
            border_editting_color: Settings.app_color_green_4
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width_split
            height: root.__input_height
            KeyNavigation.tab: required_hardware_input
            anchors
            {
                top: max_mem_footprint_header.bottom
                topMargin: Settings.spacing_small
                left: max_mem_footprint_header.left
            }
            onTextChanged:
            {
                root.__max_memory_footprint = parseInt(text);
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(max_mem_footprint_input.y - Settings.spacing_big)
                }
            }
        }

        // Hardware required
        SmlText
        {
            id: required_hardware_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Required hardware"
            anchors
            {
                top: max_mem_footprint_header.top
                left: max_mem_footprint_input.right
                leftMargin: Settings.spacing_big
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: required_hardware_input
            placeholder_text: "Select hardware"
            model: root.__hardware_list
            border_color: Settings.app_color_green_3
            border_editting_color: Settings.app_color_green_4
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: 360
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: geo_location_continent_input
            anchors
            {
                top: required_hardware_header.bottom
                topMargin: Settings.spacing_small
                left: required_hardware_header.left
            }
            onText_changed:
            {
                root.__hardware_required = text;
            }
            onModelChanged:
            {
                required_hardware_input.currentIndex = -1
            }
            onFocusChanged: {
                if(focus === true){
                    required_hardware_input.open()
                    required_hardware_input.focus = true
                }
            }
            onTab_pressed: {
                geo_location_continent_input.focus = true
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
                top: max_mem_footprint_input.bottom
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
            KeyNavigation.tab: geo_location_region_input
            anchors
            {
                top: geo_location_continent_header.bottom
                topMargin: Settings.spacing_small
                left: geo_location_continent_header.left
            }
            onTextChanged:
            {
                root.__geo_location_continent = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(geo_location_continent_input.y - Settings.spacing_big)
                }
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
            onTextChanged:
            {
                root.__geo_location_region = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(geo_location_region_input.y - Settings.spacing_big)
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
        onClicked:
        {
            focus = true
            if (!root.__refreshing)
            {
                root.prepare_task()
            }
        }
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
                root.__goal,
                root.__optimize_carbon_footprint_manual,
                root.__previous_iteration,
                root.__desired_carbon_footprint,
                root.__max_memory_footprint,
                root.__hardware_required,
                root.__geo_location_continent,
                root.__geo_location_region,
                root.__extra_data);
    }

    // Refresh button
    SmlIcon
    {
        id: refresh_button
        name:   Settings.refresh_icon_name
        color:  Settings.app_color_green_1
        color_pressed:  Settings.app_color_green_2
        nightmode_color:  Settings.app_color_green_4
        nightmode_color_pressed:  Settings.app_color_green_3
        size: Settings.button_icon_size

        x: scroll_view.width + (size * 1.5)
        y: (size * 2)

        SmlMouseArea
        {
            anchors.centerIn: parent
            hoverEnabled: true
            width: parent.width * 1.5
            height: parent.height * 1.5
            onEntered: refresh_button.start_animation();
            onPressed: refresh_button.pressed = true;
            onReleased: refresh_button.pressed = false;
            onClicked:
            {
                root.refresh()
            }
        }
    }

    SequentialAnimation {
        id: tasking_animation
        running: root.__refreshing
        loops: Animation.Infinite
        NumberAnimation {
            target: refresh_button
            property: "rotation"
            to: 360
            duration: 4000
            easing.type: Easing.InOutQuad
        }
    }

    SmlText
    {
        id: loading_animation
        visible: root.__refreshing
        font.pixelSize: 14
        color: Settings.app_color_green_2
        text_value: "Refreshing..."
        anchors
        {
            right: refresh_button.left
            rightMargin: Settings.spacing_small
            verticalCenter: refresh_button.verticalCenter
        }
    }
}
