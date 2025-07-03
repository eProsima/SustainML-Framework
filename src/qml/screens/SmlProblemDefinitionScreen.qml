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
    readonly property int __margin: Settings.spacing_big * 1
    readonly property int __input_height: 50
    readonly property int __input_height_big: 120
    readonly property int __input_width: 900
    readonly property int __input_width_split: 435
    readonly property int __input_width_small: 293

    // Input values
    property string __problem_short_description: ""
    property string __modality: ""
    property string __dataset_path: ""
    property string __metric: ""
    property string __problem_definition: ""
    property string __inputs: ""
    property string __outputs: ""
    property int __minimum_samples: 1
    property int __maximum_samples: 1
    property bool __optimize_carbon_footprint_auto: false
    property string __goal: ""
    property string __types: "transformers"
    property bool __optimize_carbon_footprint_manual: false
    property int __previous_iteration: 0
    property double __desired_carbon_footprint: 0.0
    property int __max_memory_footprint: 0
    property string __hardware_required: "PIM-AI-1chip"
    property string __geo_location_continent: ""
    property string __geo_location_region: ""
    property string __extra_data: ""
    property int __previous_problem_id: 0
    property int __num_outputs: 0
    property string __model_selected: ""
    property string __model_selected_copy: __model_selected

    property string notSupportProblemMessage: ""

    // Private properties
    property var __modality_list: []
    property var __goal_list: []
    property var __metrics: []
    property var __hardware_list: []
    property var __model_list: []
    property string __dataset_description: ""
    property string __dataset_topic: ""
    property string __dataset_profile: ""
    property string __dataset_keywords: ""
    property string __dataset_applications: ""
    property bool __refreshing: false
    property bool __reiterate: false
    property bool __initializing: true

    property string __dataset_metadata_description: __dataset_description
    property string __dataset_metadata_topic: __dataset_topic
    property string __dataset_metadata_profile: __dataset_profile
    property string __dataset_metadata_keywords: __dataset_keywords
    property string __dataset_metadata_applications: __dataset_applications

    // External signals
    signal go_home();
    signal go_results();
    signal send_task(
        string problem_short_description,
        string modality,
        string metric,
        string problem_definition,
        string inputs,
        string outputs,
        string dataset_metadata_description,
        string dataset_metadata_topic,
        string dataset_metadata_profile,
        string dataset_metadata_keywords,
        string dataset_metadata_applications,
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
        string extra_data,
        int previous_problem_id,
        int num_outputs,
        string model_selected,
        string type
    );

    signal send_dataset_path_task(
        string dataset_path
    );

    signal refresh();
    signal ask_metrics(
        string metric_req_type,
        string req_type_values
    );
    signal ask_models(
        string goal_type
    );

    Connections
    {
        target: engine
        function onReiterate_user_inputs(problem_id, iteration_id, modality, metric, problem_short_description,
                          problem_definition, inputs, outputs, dataset_metadata_description,
                          dataset_metadata_topic, dataset_metadata_profile,
                          dataset_metadata_keywords, dataset_metadata_applications, minimum_samples,
                          maximum_samples, optimize_carbon_footprint_manual,
                          previous_iteration, optimize_carbon_footprint_auto,
                          desired_carbon_footprint, geo_location_continent,
                          geo_location_region, goal, hardware_required, max_memory_footprint, num_outputs, type)
        {
            root.__problem_short_description = problem_short_description
            root.__modality = modality
            root.__metric = metric
            root.__types = type
            root.__problem_definition = problem_definition
            root.__inputs = inputs
            root.__outputs = outputs
            root.__dataset_description = dataset_metadata_description
            root.__dataset_topic = dataset_metadata_topic
            root.__dataset_profile = dataset_metadata_profile
            root.__dataset_keywords = dataset_metadata_keywords
            root.__dataset_applications = dataset_metadata_applications
            root.__minimum_samples = minimum_samples
            root.__maximum_samples = maximum_samples
            root.__optimize_carbon_footprint_manual = optimize_carbon_footprint_manual
            root.__optimize_carbon_footprint_auto = optimize_carbon_footprint_auto
            root.__desired_carbon_footprint = desired_carbon_footprint
            root.__geo_location_continent = geo_location_continent
            root.__geo_location_region = geo_location_region
            root.__goal = goal
            // root.__hardware_required = hardware_required
            root.__max_memory_footprint = max_memory_footprint
            root.__previous_iteration = iteration_id
            root.__previous_problem_id = problem_id
            root.__num_outputs = 1
        }

        function onNotSupportProblem(error_msg)
        {
            root.notSupportProblemMessage = error_msg
            notSupportDialog.open()
        }
    }

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

        anchors
        {
            top: home_button.bottom
            topMargin: Settings.spacing_normal
            left: parent.left
            leftMargin: root.__margin
            right: parent.right
            rightMargin: root.__margin
            bottom: submit_button.top
            bottomMargin: Settings.spacing_normal
        }

        content_height: geo_location_region_input.y + geo_location_region_input.height - problem_short_description_header.y

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
            color: problem_short_description_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
            top: parent.top
            left: parent.left
            }
        }
        SmlInput
        {
            id: problem_short_description_input
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            text: root.__problem_short_description
            placeholder_text: "Resume briefly the objective of the problem"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height
            KeyNavigation.tab: problem_definition_input
            anchors
            {
                top: problem_short_description_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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

        // Problem definition
        SmlText
        {
            id: problem_definition_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Problem definition"
            color: problem_definition_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: problem_short_description_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlInput
        {
            id: problem_definition_input
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            text: root.__problem_definition
            placeholder_text: "Define as precisely as possible the machine learning problem to be evaluated"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height_big
            KeyNavigation.tab: modality_input
            anchors
            {
                top: problem_definition_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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

        // Dataset Path
        SmlText
        {
            id: dataset_path_header
            visible: !root.__reiterate
            text_kind: SmlText.TextKind.Header_3
            color: dataset_path_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            text_value: "Dataset Path"
            anchors
            {
                top: problem_shortdescription_header.top
                left: problem_short_description_input.right
                leftMargin: Settings.spacing_big
            }
        }

        SmlInput
        {
            id: dataset_path_input
            visible: !root.__reiterate
            text: root.__dataset_path
            placeholder_text: "Path to the dataset for which metadata will be collected"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color:Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_small)/3 * 0.9 + 1 : root.__input_width_small - 16
            height: root.__input_height
            KeyNavigation.tab: modality_input
            anchors
            {
                top: problem_short_description_input.top
                left: problem_short_description_input.right
                leftMargin: Settings.spacing_big
            }
            onTextChanged:
            {
                root.__dataset_path = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(dataset_path_input.y - Settings.spacing_big)
                }

            }
        }

        // Extract Dataset Metadata Button
        SmlButton
        {
            id: submit_dataset_path_button
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
                top: dataset_path_input.bottom
                topMargin: Settings.spacing_small
                horizontalCenter: dataset_path_input.horizontalCenter
            }
            onClicked:
            {
                focus = true
                if (!root.__refreshing && !root.__initializing)
                {
                    scroll_view.prepare_dataset_path_task()
                }
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(dataset_path_input.y - Settings.spacing_big)
                }

            }

        }

        function prepare_dataset_path_task()
        {
            root.send_dataset_path_task(
                        root.__dataset_path
                    );
        }

        // Modality
        SmlText
        {
            id: modality_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Modality"
            color: modality_input.popup.visible ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: problem_definition_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: modality_input
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            displayText: root.__modality
            placeholder_text: displayText !== "" ? "" : "Select the modality of the input data"
            model: root.__modality_list
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__metrics.length > 0 ? root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split :
                   root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: inputs_input
            anchors
            {
                top: modality_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: modality_header.left
            }
            onModelChanged:
            {
                modality_input.currentIndex = -1
            }
            onText_changed:
            {
                if (text === "(empty)") text = "";
                root.__modality = text;
                if (text !== "" && text !== "(empty)")
                {
                    root.ask_metrics("cover_tag", text);
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
                inputs_input.focus = true
            }
        }

        // Metrics
        SmlText
        {
            id: metrics_header
            visible: root.__metrics.length > 0
            text_kind: SmlText.TextKind.Header_3
            text_value: "Metrics"
            color: metrics_input.popup.visible ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: modality_header.top
                left: modality_input.right
                leftMargin: Settings.spacing_big
            }
        }

        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: metrics_input
            visible: root.__metrics.length > 0
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            displayText: root.__metric
            placeholder_text: displayText !== "" ? "" : "Select the metrics for the model"
            model: root.__metrics
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: inputs_input
            anchors
            {
                top: metrics_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: metrics_header.left
            }
            onModelChanged:
            {
                metrics_input.currentIndex = -1
            }
            onText_changed:
            {
                root.__metric = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    metrics_input.open()
                    metrics_input.focus = true
                }
            }
            onTab_pressed: {
                inputs_input.focus = true
            }
        }

         // Types
        SmlText
        {
            id: types_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Type limiter"
            color: types_input.popup.visible ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: modality_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            disabled: true  // Right now, this is not editable
            id: types_input
            displayText: root.__types
            placeholder_text: displayText !== "" ? "" : "Select type limiter"
            model: ["transformers", "..."]
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: inputs_input
            anchors
            {
                top: types_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: types_header.left
            }
            onModelChanged:
            {
                types_input.currentIndex = -1
            }
            onText_changed:
            {
                root.__types = text;
            }
            onFocusChanged: {
                if(focus === true){
                    types_input.open()
                    types_input.focus = true
                }
            }
            onTab_pressed: {
                inputs_input.focus = true
            }
        }

        // Inputs
        SmlText
        {
            id: inputs_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Inputs"
            color: inputs_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: types_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlInput
        {
            id: inputs_input
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            text: root.__inputs
            placeholder_text: "Describe a sequence of serialized batches of input data"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height_big * 0.75
            KeyNavigation.tab: outputs_input
            anchors
            {
                top: inputs_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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
            color: outputs_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: inputs_header.top
                left: inputs_input.right
                leftMargin: Settings.spacing_big
            }
        }
        SmlInput
        {
            id: outputs_input
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            text: root.__outputs
            placeholder_text: "Describe a sequence of serialized batches of output data"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height_big * 0.75
            KeyNavigation.tab: minimum_samples_input
            anchors
            {
                top: outputs_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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
            color: minimum_samples_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: outputs_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlInput
        {
            id: minimum_samples_input
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            text: root.__minimum_samples === 1 ? "" : root.__minimum_samples
            placeholder_text: "Min samples required (only numbers)"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - 2*Settings.spacing_small)/3 * 0.9 : root.__input_width_small
            height: root.__input_height
            KeyNavigation.tab: maximum_samples_input
            anchors
            {
                top: minimum_samples_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: minimum_samples_header.left
            }
            onTextChanged:
            {
                var num = parseInt(text);
                if (!isNaN(num)) {
                    root.__minimum_samples = num;
                } else {
                    text = "";
                }
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
            color: maximum_samples_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: minimum_samples_header.top
                left: minimum_samples_input.right
                leftMargin: Settings.spacing_small
            }
        }
        SmlInput
        {
            id: maximum_samples_input
            disabled: root.__reiterate || root.__goal !== "" || root.__model_selected !== ""
            text: root.__maximum_samples === 1 ? "" : root.__maximum_samples
            placeholder_text: "Max samples required (only numbers)"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - 2*Settings.spacing_small)/3 * 0.9 : root.__input_width_small
            height: root.__input_height
            KeyNavigation.tab: goal_input
            anchors
            {
                top: maximum_samples_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: maximum_samples_header.left
            }
            onTextChanged:
            {
                var num = parseInt(text);
                if (!isNaN(num)) {
                    root.__maximum_samples = num;
                } else {
                    text = "";
                }
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(maximum_samples_input.y - Settings.spacing_big)
                }
            }
        }

        // Goal selection
        SmlText
        {
            id: goal_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Model Goal"
            color: goal_input.popup.visible ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: maximum_samples_header.top
                left: maximum_samples_input.right
                leftMargin: Settings.spacing_small
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: goal_input
            disabled: root.__reiterate || root.__model_selected !== ""
            displayText: root.__goal
            placeholder_text: displayText !== "" ? "" : "Select your model goal"
            model: root.__goal_list
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - 2*Settings.spacing_small)/3 * 0.9 + 1 : root.__input_width_small + 1
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: required_hardware_input
            anchors
            {
                top: goal_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: goal_header.left
            }
            onModelChanged:
            {
                goal_input.currentIndex = -1
            }
            onText_changed:
            {
                if (text === "(empty)") text = "";
                root.__goal = text;
                if (text !== "")
                {
                    if(root.__types !== "")

                        root.ask_models(text + ", " + root.__types);
                    else
                        root.ask_models(text);
                }
            }
            onFocusChanged: {
                if(focus === true){
                    goal_input.open()
                    goal_input.focus = true
                }
            }
            onTab_pressed: {
                required_hardware_input.focus = true
            }
        }

        // Hardware required
        SmlText
        {
            id: required_hardware_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Required hardware"
            color: required_hardware_input.popup.visible ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: goal_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: required_hardware_input
            displayText: root.__hardware_required
            placeholder_text: displayText !== "" ? "" : "Select hardware"
            model: root.__hardware_list
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - 2*Settings.spacing_small)/3 * 0.9 : root.__input_width_small
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: model_select_input
            anchors
            {
                top: required_hardware_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: required_hardware_header.left
            }
            onText_changed:
            {
                root.__hardware_required = text;
            }
            onModelChanged:
            {
                if(!root.__reiterate)
                {
                    required_hardware_input.currentIndex = -1
                    root.__hardware_required = "PIM-AI-1chip"
                }
            }
            onFocusChanged: {
                if(focus === true){
                    required_hardware_input.open()
                    required_hardware_input.focus = true
                }
            }
            onTab_pressed: {
                model_select_input.focus = true
            }
        }

        // Model selector
        SmlText
        {
            id: model_select_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Model selection"
            color: model_select_input.popup.visible ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: required_hardware_header.top
                left: required_hardware_input.right
                leftMargin: Settings.spacing_small
            }
        }
        SmlCombobox
        {
            activeFocusOnTab: true
            focus: true
            id: model_select_input
            displayText: root.__model_selected
            placeholder_text: displayText !== "" ? "" : "Select the ml model"
            model: root.__model_list
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - 2*Settings.spacing_small)/3 * 0.9 : root.__input_width_small
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: num_outputs_input
            anchors
            {
                top: model_select_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: model_select_header.left
            }
            onText_changed:
            {
                if (text === "(empty)") text = "";
                if (model_select_input.currentIndex == -1)
                {
                    root.__model_selected = root.__model_selected_copy
                    root.__model_selected_copy = "";
                } else {
                    root.__model_selected_copy = root.__model_selected;
                    root.__model_selected = text;
                }
            }
            onModelChanged:
            {
                model_select_input.currentIndex = -1
            }
            onFocusChanged: {
                if(focus === true){
                    model_select_input.open()
                    model_select_input.focus = true
                }
            }
            onTab_pressed: {
                num_outputs_input.focus = true
            }
        }

        // Number of outputs
        SmlText
        {
            id: num_outputs_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Nº outputs models"
            color: num_outputs_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: required_hardware_header.top
                left: model_select_input.right
                leftMargin: Settings.spacing_small
            }
        }
        SmlInput
        {
            id: num_outputs_input
            text: root.__num_outputs === 0 ? "" : root.__num_outputs
            placeholder_text: text !== "" ? "" : "Set quantity of output models (only numbers)"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - 2*Settings.spacing_small)/3 * 0.9 : root.__input_width_small
            height: root.__input_height
            KeyNavigation.tab: optimize_carbon_input
            anchors
            {
                top: num_outputs_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: num_outputs_header.left
            }
            onTextChanged:
            {
                var num = parseInt(text);
                if (!isNaN(num)) {
                    root.__num_outputs = num;
                } else {
                    text = "";
                }
            }
            onFocusChanged: {
                if(focus === true){
                    scroll_view.scroll_to(num_outputs_input.y - Settings.spacing_big)
                }
            }
        }

        // Dataset description
        SmlText
        {
            id: dataset_metadata_description_header
            visible: root.__dataset_description !== ""
            text_kind: SmlText.TextKind.Header_3
            text_value: "Dataset description"
            color: dataset_metadata_description_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: num_outputs_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }

        SmlInput
        {
            id: dataset_metadata_description_input
            visible: root.__dataset_description !== ""
            disabled: root.__reiterate
            text: root.__dataset_description
            placeholder_text: "Dataset description"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width:root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height_big
            KeyNavigation.tab: problem_short_description_input
            anchors
            {
                top: dataset_metadata_description_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: dataset_metadata_description_header.left
            }
            onTextEdited:
            {
                root.__dataset_metadata_description = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(dataset_metadata_description_input.y - Settings.spacing_big)
                }
            }
        }

        //Dataset Topic

        SmlText
        {
            id: dataset_metadata_topic_header
            visible: root.__dataset_topic !== ""
            text_kind: SmlText.TextKind.Header_3
            text_value: "Dataset Topic"
            color: dataset_metadata_topic_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: dataset_metadata_description_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }

        SmlInput
        {
            id: dataset_metadata_topic_input
            visible: root.__dataset_topic !== ""
            disabled: root.__reiterate
            text: root.__dataset_topic
            placeholder_text: "Dataset description"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height:root.__input_height
            KeyNavigation.tab: problem_short_description_input
            anchors
            {
                top: dataset_metadata_topic_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: dataset_metadata_description_header.left
            }
            onTextEdited:
            {
                root.__dataset_metadata_topic = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(dataset_metadata_description_input.y - Settings.spacing_big)
                }
            }
        }

        // Dataset Keywords
        SmlText
        {
            id: dataset_metadata_keywords_header
            visible: root.__dataset_keywords !== ""
            text_kind: SmlText.TextKind.Header_3
            text_value: "Dataset Keywords"
            color: dataset_metadata_keywords_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: dataset_metadata_description_input.bottom
                topMargin: Settings.spacing_small
                left: dataset_metadata_topic_input.right
                leftMargin: Settings.spacing_big
            }
        }
        SmlInput
        {
            id: dataset_metadata_keywords_input
            visible: root.__dataset_keywords !== ""
            disabled: root.__reiterate
            text: root.__dataset_keywords
            placeholder_text: "Dataset keywords"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height
            KeyNavigation.tab: optimize_carbon_input
            anchors
            {
                top: dataset_metadata_keywords_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: dataset_metadata_keywords_header.left
            }
            onTextEdited:
            {
                root.__dataset_metadata_keywords = text
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(dataset_metadata_description_input.y - Settings.spacing_big)
                }
            }
        }

        //Dataset Applications
        SmlText
        {
            id: dataset_metadata_applications_header
            visible: root.__dataset_applications !== ""
            text_kind: SmlText.TextKind.Header_3
            text_value: "Dataset Applications"
            color: dataset_metadata_applications_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: dataset_metadata_keywords_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlInput
        {
            id: dataset_metadata_applications_input
            visible: root.__dataset_applications !== ""
            disabled: root.__reiterate
            text: root.__dataset_applications
            placeholder_text: "Dataset applications"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height * 2
            KeyNavigation.tab: optimize_carbon_input
            anchors
            {
                top: dataset_metadata_applications_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: dataset_metadata_applications_header.left
            }
            onTextEdited:
            {
                root.__dataset_metadata_applications = text
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(dataset_metadata_description_input.y - Settings.spacing_big)
                }
            }
        }

        // Dataset Profile

        SmlText
        {
            id: dataset_metadata_profile_header
            visible: root.__dataset_profile !== ""
            text_kind: SmlText.TextKind.Header_3
            text_value: "Dataset Profile"
            color: dataset_metadata_profile_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: dataset_metadata_applications_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlInput
        {
            id: dataset_metadata_profile_input
            visible: root.__dataset_profile !== ""
            disabled: root.__reiterate
            text: root.__dataset_profile
            placeholder_text: "Dataset profile"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height_big
            KeyNavigation.tab: optimize_carbon_input
            anchors
            {
                top: dataset_metadata_profile_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: dataset_metadata_profile_header.left
            }
            onTextEdited:
            {
                root.__dataset_metadata_profile = text;
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(dataset_metadata_description_input.y - Settings.spacing_big)
                }
            }
        }


        // Carbon footprint optimization
        SmlText
        {
            id: optimize_carbon_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Carbon footprint optimization"
            color: optimize_carbon_input.popup.visible ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: dataset_metadata_profile_input.visible ? dataset_metadata_profile_input.bottom : num_outputs_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlCombobox
        {
            disabled: true
            activeFocusOnTab: true
            focus: true
            id: optimize_carbon_input
            displayText: root.__optimize_carbon_footprint_manual ? "Manual" : (root.__optimize_carbon_footprint_auto ? "Auto" : "")
            placeholder_text: displayText !== "" ? "" : "Select optimization iteration method"
            model: ["Manual", "Auto"]
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? scroll_view.width * 0.9 : root.__input_width
            height: root.__input_height
            rounded_radius: Settings.input_default_rounded_radius
            KeyNavigation.tab: desired_carbon_footprint_input
            anchors
            {
                top: optimize_carbon_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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
                desired_carbon_footprint_input.focus = true
            }
        }

        // Desired carbon footprint
        SmlText
        {
            id: desired_carbon_footprint_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Desired carbon footprint"
            color: desired_carbon_footprint_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: optimize_carbon_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlInput
        {
            id: desired_carbon_footprint_input
            disabled: true
            text: root.__desired_carbon_footprint === 0.0 ? "" : root.__desired_carbon_footprint
            placeholder_text: "Optimization aimed value for carbon footprint"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height
            KeyNavigation.tab: max_mem_footprint_input
            anchors
            {
                top: desired_carbon_footprint_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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
            color: max_mem_footprint_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: desired_carbon_footprint_header.top
                left: desired_carbon_footprint_input.right
                leftMargin: Settings.spacing_big
            }
        }
        SmlInput
        {
            id: max_mem_footprint_input
            disabled: true
            text: root.__max_memory_footprint === 0 ? "" : root.__max_memory_footprint
            placeholder_text: "Set maximum memory footprint allowed (only number)"
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height
            KeyNavigation.tab: geo_location_continent_input
            anchors
            {
                top: max_mem_footprint_header.bottom
                topMargin: -Settings.spacing_small * 0.25
                left: max_mem_footprint_header.left
            }
            onTextChanged:
            {
                var num = parseInt(text);
                if (!isNaN(num)) {
                    root.__max_memory_footprint = num;
                } else {
                    text = "";
                }
            }
            onFocusChanged:
            {
                if(focus === true)
                {
                    scroll_view.scroll_to(max_mem_footprint_input.y - Settings.spacing_big)
                }
            }
        }

        // Geo location: continent
        SmlText
        {
            id: geo_location_continent_header
            text_kind: SmlText.TextKind.Header_3
            text_value: "Geo location: continent"
            color: geo_location_continent_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
            anchors
            {
                top: max_mem_footprint_input.bottom
                topMargin: Settings.spacing_small
                left: parent.left
            }
        }
        SmlInput
        {
            id: geo_location_continent_input
            disabled: true
            text: root.__geo_location_continent
            placeholder_text: "Set continent for the geo location" // TODO combobox
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height
            KeyNavigation.tab: geo_location_region_input
            anchors
            {
                top: geo_location_continent_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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
            color: geo_location_region_input.focus ? Settings.app_color_blue : Settings.app_color_green_1
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
            disabled: true
            text: root.__geo_location_region
            placeholder_text: "Set region for the geo location" // TODO combobox
            border_color: Settings.app_color_green_4
            border_editting_color: Settings.app_color_blue
            border_nightmode_color: Settings.app_color_green_1
            border_nightmode_editting_color: Settings.app_color_green_2
            background_color: Settings.app_color_light
            background_nightmode_color: Settings.app_color_dark
            width: root.__input_width > scroll_view.width * 0.9 ? (scroll_view.width - Settings.spacing_big)/2 * 0.9 : root.__input_width_split
            height: root.__input_height
            KeyNavigation.tab: problem_short_description_input
            anchors
            {
                top: geo_location_region_header.bottom
                topMargin: -Settings.spacing_small * 0.25
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
        id: submit_button
        icon_name: Settings.submit_icon_name
        text_kind: SmlText.TextKind.Header_3
        text_value: "Submit"
        disabled: root.__refreshing || root.__initializing
        rounded: true
        color: Settings.app_color_light
        color_pressed: Settings.app_color_green_1
        nightmode_color: Settings.app_color_dark
        nightmode_color_pressed: Settings.app_color_green_3
        anchors
        {
            bottom: parent.bottom
            bottomMargin: root.__margin - Settings.spacing_small
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: -root.__margin
        }
        onClicked:
        {
            focus = true
            root.prepare_task()
        }
    }

    function prepare_task()
    {
        root.send_task(
                root.__problem_short_description,
                root.__modality,
                root.__metric,
                root.__problem_definition,
                root.__inputs,
                root.__outputs,
                root.__dataset_metadata_description,
                root.__dataset_metadata_topic,
                root.__dataset_metadata_profile,
                root.__dataset_metadata_keywords,
                root.__dataset_metadata_applications,
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
                root.__extra_data,
                root.__previous_problem_id,
                root.__num_outputs,
                root.__model_selected,
                root.__types);
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

        x: scroll_view.width - size/2 - Settings.spacing_big * 2
        y: Settings.spacing_big + size/2

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
        id: loading_animation
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
        id: loading_text
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

    SmlText
    {
        id: initializing_text
        visible: !root.__refreshing && root.__initializing
        font.pixelSize: 14
        color: Settings.app_color_green_2
        text_value: "Initializing..."
        anchors
        {
            right: refresh_button.left
            rightMargin: Settings.spacing_small
            verticalCenter: refresh_button.verticalCenter
        }
    }

    // Error message dialog
    SmlDialog
    {
        id: notSupportDialog
        placeholder_text: "WARNING!!"
        text_value: notSupportProblemMessage
        background_color: Settings.app_color_light
        border_color: Settings.app_color_green_4
        border_width: 1
        rounded: true
        placeholder_text_color: Settings.app_color_blue
        text_color: Settings.app_color_blue
    }

    // Dialog {
    //     id: notSupportDialog
    //     anchors.centerIn: parent
    //     modal: true

    //     width: contentColumn.implicitWidth
    //     height: contentColumn.implicitHeight

    //     background: Rectangle {
    //         anchors.fill: parent
    //         radius: 10
    //         color: Settings.app_color_light
    //         border.color: Settings.app_color_green_4
    //         border.width: 1
    //     }

    //     header: Item { }

    //     Column {
    //         id: contentColumn
    //         spacing: 16
    //         padding: 16
    //         anchors.centerIn: parent

    //         Text {
    //             text: "WARNING!!"
    //             font.pixelSize: 20
    //             font.bold: true
    //             color: Settings.app_color_blue
    //             horizontalAlignment: Text.AlignHCenter
    //         }

    //         Text {
    //             text: notSupportProblemMessage
    //             wrapMode: Text.WordWrap
    //             font.pixelSize: 16
    //             color: Settings.app_color_blue
    //             horizontalAlignment: Text.AlignHCenter
    //         }

    //         Button {
    //             anchors.right: parent.right
    //             anchors.rightMargin: Settings.spacing_small
    //             font.pixelSize: 14
    //             height: 32
    //             width: 80
    //             onClicked: notSupportDialog.close()

    //             background: Rectangle {
    //                 anchors.fill: parent
    //                 radius: 5
    //                 color: Settings.app_color_green_1
    //             }
    //             contentItem: Text {
    //                 text: "Ok"
    //                 font.pixelSize: parent.font.pixelSize
    //                 color: Settings.app_color_light
    //                 horizontalAlignment: Text.AlignHCenter
    //                 verticalAlignment: Text.AlignVCenter
    //             }
    //         }
    //     }
    // }
}
