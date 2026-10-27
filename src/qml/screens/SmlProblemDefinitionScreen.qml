// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"
import "../utils/Countries.js" as Countries

Item
{
    id: root

    // Internal properties
    readonly property int __margin: Theme.space5

    // Input values
    property string __problem_short_description: ""
    property string __problem_definition: ""
    property string __inputs: ""
    property string __outputs: ""
    property int __minimum_samples: 1
    property int __maximum_samples: 1
    property bool __optimize_carbon_footprint_auto: false
    property string __goal: ""
    property string __types: "Transformers"
    property bool __optimize_carbon_footprint_manual: false
    property int __previous_iteration: 0
    property double __desired_carbon_footprint: 0.0
    property int __max_memory_footprint: 0
    property string __hardware_required: "PIM-AI-1chip"
    property string __geo_location_continent: ""
    property string __geo_location_region: ""
    property string __extra_data: ""
    property int __previous_problem_id: 0
    property int __num_outputs: 1
    property string __model_selected: ""
    // CNNs only run as a U-Net chosen by hand: the search, and so every field feeding it, is Transformers only
    readonly property bool __cnn_mode: root.__types.toLowerCase() === "cnns"
    on__Model_selectedChanged:
    {
        // A selected model skips the search, so its optimization fields no longer apply
        if (root.__model_selected === "")
            return
        root.__optimize_carbon_footprint_auto = false
        root.__optimize_carbon_footprint_manual = false
        root.__desired_carbon_footprint = 0.0
        root.__max_memory_footprint = 0
        desired_carbon_footprint_input.text = ""
        max_mem_footprint_input.text = ""
    }
    property string __model_selected_copy: __model_selected

    property string notSupportProblemMessage: ""

    // Private properties
    property var __goal_list: []
    property var __hardware_list: []
    property var __model_list: []
    property string __dataset_description: ""
    property string __dataset_topic: ""
    property string __dataset_profile: ""
    property string __dataset_keywords: ""
    property string __dataset_applications: ""
    property bool __refreshing: false
    // Iteration info view (the info button of a Results row): every field is read-only and
    // shows what that iteration ran with, and the footer actions are hidden
    property bool __reiterate: false
    property bool __initializing: true
    // The iteration evaluated a Hugging Face model (its Analyze button)
    property bool __hf_analyze: false
    // What the info view leaves out. A HF model was found for the problem description and
    // evaluated as is, so that description is all it shows. A model chosen from the list (always
    // a U-Net for CNNs) is evaluated as is too: the description, inputs, outputs, samples, search,
    // dataset and optimization fields never apply to it, so it shows the type, goal (none for
    // CNNs), hardware, model and location
    readonly property bool __info_hf: root.__reiterate && root.__hf_analyze
    readonly property bool __info_chosen: root.__reiterate && !root.__hf_analyze &&
                                          (root.__model_selected !== "" || root.__cnn_mode)
    readonly property bool __info_cnn: root.__info_chosen && root.__cnn_mode
    // The description the HF search used: the problem definition, else the short description
    readonly property bool __hf_used_definition: root.__problem_definition.trim() !== "" ||
                                                 root.__problem_short_description.trim() === ""

    property string __dataset_metadata_description: __dataset_description
    property string __dataset_metadata_topic: __dataset_topic
    property string __dataset_metadata_profile: __dataset_profile
    property string __dataset_metadata_keywords: __dataset_keywords
    property string __dataset_metadata_applications: __dataset_applications

    // External signals
    signal go_results()
    signal go_dataset_path()
    signal go_unet_models()
    signal send_task(
        string problem_short_description,
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
    )

    signal clear_all_clicked()
    // Reiterating a past problem needs to update main_window.dataset_description
    // (and siblings) - the true source __dataset_description etc. below are
    // one-way bound FROM - rather than assign root.__dataset_description
    // directly, which would permanently sever that binding (any subsequent
    // dataset upload would then update main_window's copy but never reach this
    // screen again). Same reasoning as clear_all_clicked() above.
    signal dataset_metadata_reiterated(
        string description,
        string topic,
        string profile,
        string keywords,
        string applications
    )
    signal ask_models(
        string goal_type
    )

    signal go_hf_models()
    signal ask_hf_models(string description)
    signal go_hf_results()
    signal go_hf_comparisons()

    property bool hf_results_available: false
    // Count (not just a flag) so the "Comparisons" button can badge how many are saved
    property int hf_comparisons_count: 0

    Connections
    {
        target: engine
        function onReiterate_user_inputs(problem_id, iteration_id, problem_short_description,
                          problem_definition, inputs, outputs, dataset_metadata_description,
                          dataset_metadata_topic, dataset_metadata_profile,
                          dataset_metadata_keywords, dataset_metadata_applications, minimum_samples,
                          maximum_samples, optimize_carbon_footprint_manual,
                          previous_iteration, optimize_carbon_footprint_auto,
                          desired_carbon_footprint, geo_location_continent,
                          geo_location_region, goal, hardware_required, max_memory_footprint, num_outputs, type, is_reiteration,
                          model_selected, hf_analyze)
        {
            // Each form takes only its own request: the iteration info view (is_reiteration)
            // or Back from Results (the problem definition form). Both are alive at once, and
            // opening an iteration's info must not refill the problem definition form, lock
            // its goal and turn its next submit into a new iteration of that problem.
            if (is_reiteration !== root.__reiterate)
                return
            root.__problem_short_description = problem_short_description
            root.__types = type
            root.__problem_definition = problem_definition
            root.__inputs = inputs
            root.__outputs = outputs
            root.__minimum_samples = minimum_samples
            root.__maximum_samples = maximum_samples
            root.__optimize_carbon_footprint_manual = optimize_carbon_footprint_manual
            root.__optimize_carbon_footprint_auto = optimize_carbon_footprint_auto
            root.__desired_carbon_footprint = desired_carbon_footprint
            root.__geo_location_continent = geo_location_continent
            root.__geo_location_region = geo_location_region
            if (root.__reiterate)
            {
                // Iteration info view: exactly what the iteration was run with. Its own copy of
                // the dataset metadata, as it is not bound to main_window's
                root.__dataset_description = dataset_metadata_description
                root.__dataset_topic = dataset_metadata_topic
                root.__dataset_profile = dataset_metadata_profile
                root.__dataset_keywords = dataset_metadata_keywords
                root.__dataset_applications = dataset_metadata_applications
                root.__goal = goal
                root.__model_selected = model_selected
                root.__model_selected_copy = model_selected
                root.__hardware_required = hardware_required
                root.__num_outputs = num_outputs > 0 ? num_outputs : 1
                num_outputs_input.text = root.__num_outputs
                root.__hf_analyze = hf_analyze
            }
            else
            {
                // Back from Results: an editable form for a new problem. A restored goal or model
                // would disable the problem description fields, so both are left empty (a model
                // from the CNN+FPGA direct selection would otherwise stay stuck for good,
                // disabling every field gated by "__model_selected !== \"\"")
                root.dataset_metadata_reiterated(dataset_metadata_description, dataset_metadata_topic,
                        dataset_metadata_profile, dataset_metadata_keywords, dataset_metadata_applications)
                root.__goal = ""
                root.__model_selected = ""
                root.__model_selected_copy = ""
                // After __types above, whose change resets the hardware to the type's default;
                // only if it is valid for the restored type
                if (hardware_required !== "" &&
                        root.filteredHardwareList().indexOf(hardware_required) !== -1)
                    root.__hardware_required = hardware_required
            }
            root.__max_memory_footprint = max_memory_footprint
            // Set explicitly: Clear all assigns these texts, which removes their bindings
            // (as does emptying a samples field), so the fields would otherwise look empty,
            // or keep older text, while the restored values are sent
            problem_short_description_input.text = problem_short_description
            problem_definition_input.text = problem_definition
            inputs_input.text = inputs
            outputs_input.text = outputs
            minimum_samples_input.text = minimum_samples > 1 ? minimum_samples : ""
            maximum_samples_input.text = maximum_samples > 1 ? maximum_samples : ""
            desired_carbon_footprint_input.text = desired_carbon_footprint === 0 ? "" : desired_carbon_footprint
            max_mem_footprint_input.text = max_memory_footprint === 0 ? "" : max_memory_footprint
            root.__previous_iteration = 0
            root.__previous_problem_id = 0
        }

        function onNotSupportProblem(error_msg)
        {
            if (!root.__reiterate) {
                root.notSupportProblemMessage = error_msg
                notSupportDialog.open()
            }
        }
    }

    // Background mouse area
    MouseArea
    {
        anchors.fill: parent
        onClicked: focus = true
    }


    // Widths of the form columns inside a card
    readonly property int __input_height: 38
    readonly property int __input_height_big: 104
    readonly property int __input_height_medium: 80
    // Multi-line fields grow in the iteration info view to show all their text (read-only, so
    // they cannot scroll)
    function __col(width, n) { return (width - (n - 1) * Theme.space4) / n }
    // Position of a field in the scrolled form, to bring it into view when focused
    function __form_y(item) { return item.mapToItem(scroll_view.contentItem, 0, 0).y }

    // Screen header: title, refresh status and the ways out of this screen
    SmlScreenHeader
    {
        id: header
        title: root.__reiterate ? "Iteration inputs" : "Problem definition"
        subtitle: root.__info_hf ? "The problem description the Hugging Face model was analyzed for"
                  : root.__reiterate ? "What this iteration was run with"
                  : "Describe the ML problem to find the most efficient model and hardware"
        reserved_right: root.__reiterate ? Theme.space5 : Theme.controlHeight + Theme.space4 + Theme.space3

        actions: [
            // Loading indicator: shown only while the app is starting up (__initializing),
            // never again afterwards - later refreshes (HF search, dataset metadata, U-Net
            // list) reuse the same __refreshing flag but must not bring this back
            SmlChip
            {
                id: loading_text
                anchors.verticalCenter: parent.verticalCenter
                visible: root.__initializing
                text: "Initializing..."
                tone: "accent"
                pulse: true
            },

            // Spins while initializing, then disappears for good - not interactive, there
            // is no click action (see loading_animation below for the spin)
            SmlIconButton
            {
                id: refresh_button
                visible: root.__initializing
                icon_name: Settings.refresh_icon_name
                focusPolicy: Qt.NoFocus
                hoverEnabled: false
            },

            // Go results button
            SmlButton
            {
                id: go_results
                icon_name: Settings.results_icon_name
                text_value: "Results"
                tooltip_text: "Go to Results screen"
                onClicked: root.go_results()
            },

            // Go dataset path button
            SmlButton
            {
                id: dataset_path_button
                visible: !root.__reiterate
                // The dataset metadata only feeds the Transformers search
                disabled: root.__cnn_mode
                icon_name: Settings.upload_icon_name
                text_value: "Upload dataset"
                tooltip_text: "Go to Dataset Selector screen"
                onClicked: root.go_dataset_path()
            },

            // Go unet models button
            SmlButton
            {
                id: unet_models_button
                visible: !root.__reiterate
                icon_name: "network"
                text_value: "U-Net models"
                tooltip_text: "Go to U-Net models screen"
                onClicked: {
                    var cfg = "U_NET_MODELS, FPGA (xczu19eg-ffvb1517-2-i), CNNs"
                    root.ask_models(cfg)
                    root.go_unet_models()
                }
            },

            // HF models button
            SmlButton
            {
                id: hf_search_button
                visible: !root.__reiterate
                icon_name: "sparkles"
                text_value: "HF models"
                tooltip_text: "Find best Hugging Face models for this description"
                onClicked: hf_choice_popup.open()
            }
        ]
    }

    SequentialAnimation {
        id: loading_animation
        running: root.__initializing
        loops: Animation.Infinite
        NumberAnimation {
            target: refresh_button
            property: "icon_rotation"
            from: 0
            to: 360
            duration: 1200
        }
        onStopped: refresh_button.icon_rotation = 0
    }

    Popup {
        id: hf_choice_popup
        parent: hf_search_button
        y: hf_search_button.height + Theme.space1
        x: hf_search_button.width - width
        padding: Theme.space1
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFast } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFast } }

        background: Rectangle {
            radius: Theme.radiusMd
            color: Theme.overlay
            border.color: Theme.borderStrong
            border.width: 1

            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: -3
                radius: parent.radius
                color: Theme.shadow
            }
        }

        Column {
            width: 220
            spacing: 2

            SmlButton {
                width: parent.width
                variant: "ghost"
                align_left: true
                text_value: "Search"
                icon_name: Settings.search_icon_name
                tooltip_text: "Search Hugging Face models for the problem description"
                disabled: root.__cnn_mode || (root.__problem_definition.trim() === "" && root.__problem_short_description.trim() === "")
                onClicked: {
                    hf_choice_popup.close()
                    var q = root.__problem_definition
                    if (!q || q.trim().length === 0)
                        q = root.__problem_short_description
                    root.go_hf_models()
                    Qt.callLater(function() { root.ask_hf_models(q) })
                }
            }

            SmlButton {
                width: parent.width
                variant: "ghost"
                align_left: true
                text_value: "Results"
                icon_name: Settings.results_icon_name
                tooltip_text: "Saved Hugging Face searches"
                disabled: !root.hf_results_available
                onClicked: {
                    hf_choice_popup.close()
                    root.go_hf_results()
                }
            }

            SmlButton {
                width: parent.width
                variant: "ghost"
                align_left: true
                text_value: "Comparisons"
                icon_name: Settings.comparisons_icon_name
                tooltip_text: "Saved Hugging Face model comparisons"
                disabled: root.hf_comparisons_count === 0
                onClicked: {
                    hf_choice_popup.close()
                    root.go_hf_comparisons()
                }
            }
        }
    }

    SmlScrollView
    {
        id: scroll_view

        anchors
        {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: footer.top
        }

        content_height: form_column.implicitHeight + 2 * Theme.space5

        // Background mouse area
        MouseArea
        {
            anchors.fill: parent
            onClicked: focus = true
        }

        Column
        {
            id: form_column
            y: Theme.space5
            width: Math.min(scroll_view.width - 2 * Theme.pagePadding, Theme.contentMaxWidth)
            x: (scroll_view.width - width) / 2
            spacing: Theme.space6

            // ---------------------------------------------------------------- Problem
            SmlCard
            {
                id: problem_card
                width: parent.width
                title: "Problem"
                subtitle: root.__info_hf ? "What the model has to do"
                          : root.__info_chosen ? "The kind of model"
                          : "What the model has to do, and the data it works with"
                icon_name: "file"

                Column
                {
                    id: problem_fields
                    width: problem_card.content_area.width
                    spacing: Theme.space4

                    // Problem short description
                    Column
                    {
                        width: parent.width
                        visible: !root.__info_chosen && !(root.__info_hf && root.__hf_used_definition)
                        SmlFieldLabel { text: "Problem short description"; active: problem_short_description_input.focus; width: parent.width }
                        SmlInput
                        {
                            read_only: root.__reiterate
                            id: problem_short_description_input
                            disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                            text: root.__problem_short_description
                            placeholder_text: "Resume briefly the objective of the problem"
                            width: parent.width
                            height: root.__input_height
                            KeyNavigation.tab: problem_definition_input
                            onTextChanged:
                            {
                                root.__problem_short_description = text
                            }
                            onFocusChanged:
                            {
                                if(focus === true)
                                {
                                    scroll_view.scroll_to(root.__form_y(problem_short_description_input) - Theme.space6)
                                }
                            }
                        }
                    }

                    // Problem definition
                    Column
                    {
                        width: parent.width
                        visible: !root.__info_chosen && !(root.__info_hf && !root.__hf_used_definition)
                        SmlFieldLabel { text: "Problem definition"; active: problem_definition_input.focus; width: parent.width }
                        SmlTextArea
                        {
                            read_only: root.__reiterate
                            id: problem_definition_input
                            disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                            text: root.__problem_definition
                            placeholder_text: "Define as precisely as possible the machine learning problem to be evaluated"
                            width: parent.width
                            height: root.__reiterate ? Math.max(root.__input_height_big, problem_definition_input.content_height) : root.__input_height_big
                            KeyNavigation.tab: types_input
                            onTextChanged:
                            {
                                root.__problem_definition = text
                            }
                            onFocusChanged:
                            {
                                if(focus === true)
                                {
                                    scroll_view.scroll_to(root.__form_y(problem_definition_input) - Theme.space6)
                                }
                            }
                        }
                    }

                    // Types
                    Column
                    {
                        width: root.__col(parent.width, 3)
                        visible: !root.__info_hf
                        SmlFieldLabel { text: "Type limiter"; active: types_input.popup.visible; width: parent.width }
                        SmlCombobox
                        {
                            read_only: root.__reiterate
                            activeFocusOnTab: true
                            focus: true
                            disabled: false
                            id: types_input
                            displayText: root.__types
                            placeholder_text: displayText !== "" ? "" : "Select type limiter"
                            model: ["Transformers", "CNNs"]
                            width: parent.width
                            height: root.__input_height
                            KeyNavigation.tab: inputs_input
                            onModelChanged:
                            {
                                types_input.currentIndex = -1
                            }
                            onText_changed:
                            {
                                root.__types = text

                                // A model chosen for the previous type (e.g. a U-Net for CNNs) does not apply
                                // to the new one, and while set it disables the goal and description fields
                                if (text !== "") {
                                    root.__model_selected = ""
                                    root.__model_selected_copy = ""
                                    model_select_input.currentIndex = -1
                                }

                                if (text.toLowerCase() === "cnns") {
                                    // Default hardware to FPGA when CNNs are selected
                                    root.__hardware_required = "FPGA (xczu19eg-ffvb1517-2-i)"
                                    required_hardware_input.currentIndex = -1    // use displayText

                                    // CNN + FPGA → U-NET fast path: clear goal & request models
                                    // (goal_input.disabled follows from __types/__hardware_required declaratively)
                                    root.__goal = ""

                                    var cfg = "U_NET_MODELS, " +
                                            root.__hardware_required + ", " + text
                                    root.ask_models(cfg)
                                }
                            }
                            onFocusChanged: {
                                if(focus === true){
                                    // Enabling selecting the same item in 2 consecutive runs
                                    types_input.currentIndex = -1
                                    types_input.open()
                                    types_input.focus = true
                                }
                            }
                            onTab_pressed: {
                                inputs_input.focus = true
                            }
                        }
                    }

                    Row
                    {
                        width: parent.width
                        spacing: Theme.space4
                        visible: !root.__info_hf && !root.__info_chosen

                        // Inputs
                        Column
                        {
                            width: root.__col(parent.width, 2)
                            SmlFieldLabel { text: "Inputs"; active: inputs_input.focus; width: parent.width }
                            SmlTextArea
                            {
                                read_only: root.__reiterate
                                id: inputs_input
                                disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                                text: root.__inputs
                                placeholder_text: "Describe a sequence of serialized batches of input data"
                                width: parent.width
                                height: root.__reiterate ? Math.max(root.__input_height_medium, inputs_input.content_height) : root.__input_height_medium
                                KeyNavigation.tab: outputs_input
                                onTextChanged:
                                {
                                    root.__inputs = text
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(inputs_input) - Theme.space6)
                                    }
                                }
                            }
                        }

                        // Outputs
                        Column
                        {
                            width: root.__col(parent.width, 2)
                            SmlFieldLabel { text: "Outputs"; active: outputs_input.focus; width: parent.width }
                            SmlTextArea
                            {
                                read_only: root.__reiterate
                                id: outputs_input
                                disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                                text: root.__outputs
                                placeholder_text: "Describe a sequence of serialized batches of output data"
                                width: parent.width
                                height: root.__reiterate ? Math.max(root.__input_height_medium, outputs_input.content_height) : root.__input_height_medium
                                KeyNavigation.tab: minimum_samples_input
                                onTextChanged:
                                {
                                    root.__outputs = text
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(outputs_input) - Theme.space6)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------------- Model and data
            SmlCard
            {
                id: model_card
                width: parent.width
                visible: !root.__info_hf
                title: "Model and data"
                subtitle: root.__info_cnn ? "Model and hardware of the problem"
                          : root.__info_chosen ? "Goal, model and hardware of the problem"
                          : "Goal, model, hardware and dataset of the problem"
                icon_name: "cpu"

                Column
                {
                    width: model_card.content_area.width
                    spacing: Theme.space4

                    Row
                    {
                        width: parent.width
                        spacing: Theme.space4
                        visible: !root.__info_cnn

                        // Minimum samples
                        Column
                        {
                            width: root.__col(parent.width, 3)
                            visible: !root.__info_chosen
                            SmlFieldLabel { text: "Minimum samples"; active: minimum_samples_input.focus; width: parent.width }
                            SmlInput
                            {
                                read_only: root.__reiterate
                                id: minimum_samples_input
                                disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                                text: root.__minimum_samples === 1 ? "" : root.__minimum_samples
                                // Not IntValidator: it's locale-aware and treats the locale's group
                                // separator (a comma, in many locales) as acceptable input. A plain
                                // digit-only pattern has no such leniency.
                                validator: RegExpValidator { regExp: /^[0-9]*$/ }
                                placeholder_text: "Min samples required (only numbers)"
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: maximum_samples_input
                                onTextChanged:
                                {
                                    var num = parseInt(text)
                                    if (!isNaN(num)) {
                                        root.__minimum_samples = num
                                    } else {
                                        // Emptied: back to 1, the "not specified" value, so the
                                        // previous number is not submitted again
                                        root.__minimum_samples = 1
                                        text = ""
                                    }
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(minimum_samples_input) - Theme.space6)
                                    }
                                }
                            }
                        }

                        // Maximum samples
                        Column
                        {
                            width: root.__col(parent.width, 3)
                            visible: !root.__info_chosen
                            SmlFieldLabel { text: "Maximum samples"; active: maximum_samples_input.focus; width: parent.width }
                            SmlInput
                            {
                                read_only: root.__reiterate
                                id: maximum_samples_input
                                disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                                text: root.__maximum_samples === 1 ? "" : root.__maximum_samples
                                validator: RegExpValidator { regExp: /^[0-9]*$/ }
                                placeholder_text: "Max samples required (only numbers)"
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: goal_input
                                onTextChanged:
                                {
                                    var num = parseInt(text)
                                    if (!isNaN(num)) {
                                        root.__maximum_samples = num
                                    } else {
                                        // Emptied: back to 1, the "not specified" value, so the
                                        // previous number is not submitted again
                                        root.__maximum_samples = 1
                                        text = ""
                                    }
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(maximum_samples_input) - Theme.space6)
                                    }
                                }
                            }
                        }

                        // Goal selection
                        Column
                        {
                            width: root.__col(parent.width, root.__info_chosen ? 2 : 3)
                            SmlFieldLabel { text: "Model goal"; active: goal_input.popup.visible; width: parent.width }
                            SmlCombobox
                            {
                                read_only: root.__reiterate
                                activeFocusOnTab: true
                                focus: true
                                id: goal_input
                                // Expressed fully declaratively (rather than toggled imperatively from
                                // required_hardware_input.onText_changed below) so this can never get
                                // permanently stuck: a direct "goal_input.disabled = ..." assignment
                                // would sever this binding for good, the same way direct assignments to
                                // the dataset-metadata properties elsewhere in this file used to.
                                disabled: root.__model_selected !== "" ||
                                    (root.__types.toLowerCase() === "cnns" && root.__hardware_required === "FPGA (xczu19eg-ffvb1517-2-i)")
                                displayText: root.__goal
                                placeholder_text: displayText !== "" ? "" : "Select your model goal"
                                model: root.__goal_list
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: required_hardware_input
                                onModelChanged:
                                {
                                    goal_input.currentIndex = -1
                                }
                                onText_changed:
                                {
                                    if (text === "(empty)") text = ""
                                    root.__goal = text

                                    // Reset any previously selected model when the goal changes so
                                    // dependent fields recompute their disabled state correctly.
                                    root.__model_selected = ""
                                    root.__model_selected_copy = ""
                                    model_select_input.currentIndex = -1

                                    if (text !== "")
                                    {
                                        if(root.__types !== "")
                                            root.ask_models(text + ", " + root.__types)
                                        else
                                            root.ask_models(text)
                                    }
                                    // When goal is empty we clear the selected model but keep the
                                    // __model_list binding coming from the main window so that
                                    // backend updates can populate it when available.
                                }
                                onFocusChanged: {
                                    if(focus === true){
                                        // Enabling selecting the same item in 2 consecutive runs
                                        goal_input.currentIndex = -1
                                        goal_input.open()
                                        goal_input.focus = true
                                    }
                                }
                                onTab_pressed: {
                                    required_hardware_input.focus = true
                                }
                            }
                        }
                    }

                    Row
                    {
                        width: parent.width
                        spacing: Theme.space4

                        // Hardware required
                        Column
                        {
                            width: root.__col(parent.width, root.__info_chosen ? 2 : 3)
                            SmlFieldLabel { text: "Required hardware"; active: required_hardware_input.popup.visible; width: parent.width }
                            SmlCombobox
                            {
                                read_only: root.__reiterate
                                activeFocusOnTab: true
                                focus: true
                                id: required_hardware_input
                                searchable: true
                                displayText: root.__hardware_required
                                placeholder_text: displayText !== "" ? "" : "Select hardware"
                                model: filteredHardwareList()
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: model_select_input
                                onText_changed:
                                {
                                    root.__hardware_required = text

                                    // Detect CNN + FPGA combo
                                    if (root.__types.toLowerCase() === "cnns" &&
                                        text === "FPGA (xczu19eg-ffvb1517-2-i)") {

                                        // Clear goal if set (goal_input.disabled reacts on its own,
                                        // declaratively, to __types/__hardware_required above)
                                        root.__goal = ""

                                        // Ask backend for U-Net models directly
                                        // The backend already supports this string
                                        var cfg = "U_NET_MODELS, " + text + ", " + root.__types
                                        root.ask_models(cfg)
                                    }
                                }
                                onModelChanged:
                                {
                                    if(!root.__reiterate)
                                    {
                                        required_hardware_input.currentIndex = -1
                                        if (root.__types && root.__types.toLowerCase() === "cnns") {
                                            root.__hardware_required = "FPGA (xczu19eg-ffvb1517-2-i)"
                                        } else {
                                            root.__hardware_required = "PIM-AI-1chip"
                                        }
                                    }
                                }
                                onFocusChanged: {
                                    if(focus === true){
                                        // Enabling selecting the same item in 2 consecutive runs
                                        required_hardware_input.currentIndex = -1
                                        required_hardware_input.open()
                                        required_hardware_input.focus = true
                                    }
                                }
                                onTab_pressed: {
                                    model_select_input.focus = true
                                }
                            }
                        }

                        // Model selector
                        Column
                        {
                            width: root.__col(parent.width, root.__info_chosen ? 2 : 3)
                            SmlFieldLabel { text: "Model selection"; active: model_select_input.popup.visible; width: parent.width }
                            SmlCombobox
                            {
                                read_only: root.__reiterate
                                activeFocusOnTab: true
                                focus: true
                                id: model_select_input
                                searchable: true
                                // Disable model selection if the goal is not selected unless CNNs + FPGA combo
                                disabled: (root.__goal === "" &&
                                    !(root.__types && root.__types.toLowerCase() === "cnns" &&
                                        root.__hardware_required === "FPGA (xczu19eg-ffvb1517-2-i)"))
                                displayText: root.__model_selected
                                placeholder_text: displayText !== "" ? "" : (root.__cnn_mode ? "Select a U-Net model (required for CNNs)" : "Select the ml model")
                                model: root.__model_list
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: num_outputs_input
                                onText_changed: {
                                    if (text === "(empty)" || text === "") {
                                        // No model selected
                                        root.__model_selected = ""
                                        root.__model_selected_copy = ""
                                        // Keep __num_outputs as-is; user can type whatever they want
                                    } else {
                                        // A specific model has been chosen
                                        root.__model_selected = text
                                        root.__model_selected_copy = text
                                        // Force num_outputs to 1 and show it in the box
                                        root.__num_outputs = 1
                                        num_outputs_input.text = "1"
                                    }
                                }
                                onModelChanged:
                                {
                                    model_select_input.currentIndex = -1
                                }
                                onFocusChanged: {
                                    if(focus === true){
                                        // Enabling selecting the same item in 2 consecutive runs
                                        model_select_input.currentIndex = -1
                                        model_select_input.open()
                                        model_select_input.focus = true
                                    }
                                }
                                onTab_pressed: {
                                    num_outputs_input.focus = true
                                }
                            }
                        }

                        // Number of outputs
                        Column
                        {
                            width: root.__col(parent.width, 3)
                            visible: !root.__info_chosen
                            SmlFieldLabel { text: "Nº output models"; active: num_outputs_input.focus; width: parent.width }
                            SmlInput
                            {
                                read_only: root.__reiterate
                                id: num_outputs_input
                                disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                                text: root.__num_outputs === 0 ? "" : root.__num_outputs
                                validator: RegExpValidator { regExp: /^[0-9]*$/ }
                                placeholder_text: text !== "" ? "" : "Set quantity of output models (only numbers)"
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: optimize_carbon_input
                                onTextChanged:
                                {
                                    var num = parseInt(text)
                                    if (!isNaN(num)) {
                                        root.__num_outputs = num
                                    } else {
                                        text = ""
                                    }
                                }
                                onFocusChanged: {
                                    if(focus === true){
                                        scroll_view.scroll_to(root.__form_y(num_outputs_input) - Theme.space6)
                                    }
                                }
                            }
                        }
                    }

                    // Dataset metadata, shown once a dataset has been uploaded
                    Rectangle
                    {
                        width: parent.width
                        height: 1
                        color: Theme.border
                        visible: dataset_title.visible
                    }

                    Text
                    {
                        id: dataset_title
                        visible: !root.__info_chosen && (root.__dataset_description !== "" || root.__dataset_topic !== ""
                                 || root.__dataset_keywords !== "" || root.__dataset_applications !== ""
                                 || root.__dataset_profile !== "")
                        text: "UPLOADED DATASET"
                        textFormat: Text.PlainText
                        font.family: Theme.uiFontFamily
                        font.pixelSize: Theme.fontSizeMicro
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        color: Theme.textMuted
                    }

                    // Dataset description
                    Column
                    {
                        width: parent.width
                        visible: !root.__info_chosen && root.__dataset_description !== ""
                        SmlFieldLabel { text: "Dataset description"; active: dataset_metadata_description_input.focus; width: parent.width }
                        SmlTextArea
                        {
                            read_only: root.__reiterate
                            id: dataset_metadata_description_input
                            // Only used to infer the goal, so ignored once a goal or a model is chosen
                            disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                            text: root.__dataset_description
                            placeholder_text: "Dataset description"
                            width: parent.width
                            height: root.__reiterate ? Math.max(root.__input_height_big, dataset_metadata_description_input.content_height) : root.__input_height_big
                            KeyNavigation.tab: problem_short_description_input
                            onTextEdited:
                            {
                                root.__dataset_metadata_description = text
                            }
                            onFocusChanged:
                            {
                                if(focus === true)
                                {
                                    scroll_view.scroll_to(root.__form_y(dataset_metadata_description_input) - Theme.space6)
                                }
                            }
                        }
                    }

                    Row
                    {
                        width: parent.width
                        spacing: Theme.space4
                        visible: !root.__info_chosen && (root.__dataset_topic !== "" || root.__dataset_keywords !== "")

                        //Dataset Topic
                        Column
                        {
                            width: root.__col(parent.width, 2)
                            opacity: root.__dataset_topic !== "" ? 1 : 0
                            SmlFieldLabel { text: "Dataset topic"; active: dataset_metadata_topic_input.focus; width: parent.width }
                            SmlInput
                            {
                                read_only: root.__reiterate
                                id: dataset_metadata_topic_input
                                visible: root.__dataset_topic !== ""
                                // Only used to infer the goal, so ignored once a goal or a model is chosen
                                disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                                text: root.__dataset_topic
                                placeholder_text: "Dataset description"
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: problem_short_description_input
                                onTextEdited:
                                {
                                    root.__dataset_metadata_topic = text
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(dataset_metadata_description_input) - Theme.space6)
                                    }
                                }
                            }
                        }

                        // Dataset Keywords
                        Column
                        {
                            width: root.__col(parent.width, 2)
                            opacity: root.__dataset_keywords !== "" ? 1 : 0
                            SmlFieldLabel { text: "Dataset keywords"; active: dataset_metadata_keywords_input.focus; width: parent.width }
                            SmlInput
                            {
                                read_only: root.__reiterate
                                id: dataset_metadata_keywords_input
                                visible: root.__dataset_keywords !== ""
                                // Only used to infer the goal, so ignored once a goal or a model is chosen
                                disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                                text: root.__dataset_keywords
                                placeholder_text: "Dataset keywords"
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: optimize_carbon_input
                                onTextEdited:
                                {
                                    root.__dataset_metadata_keywords = text
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(dataset_metadata_description_input) - Theme.space6)
                                    }
                                }
                            }
                        }
                    }

                    //Dataset Applications
                    Column
                    {
                        width: parent.width
                        visible: !root.__info_chosen && root.__dataset_applications !== ""
                        SmlFieldLabel { text: "Dataset applications"; active: dataset_metadata_applications_input.focus; width: parent.width }
                        SmlTextArea
                        {
                            read_only: root.__reiterate
                            id: dataset_metadata_applications_input
                            // Only used to infer the goal, so ignored once a goal or a model is chosen
                            disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                            text: root.__dataset_applications
                            placeholder_text: "Dataset applications"
                            width: parent.width
                            height: root.__reiterate ? Math.max(root.__input_height_medium, dataset_metadata_applications_input.content_height) : root.__input_height_medium
                            KeyNavigation.tab: optimize_carbon_input
                            onTextEdited:
                            {
                                root.__dataset_metadata_applications = text
                            }
                            onFocusChanged:
                            {
                                if(focus === true)
                                {
                                    scroll_view.scroll_to(root.__form_y(dataset_metadata_description_input) - Theme.space6)
                                }
                            }
                        }
                    }

                    // Dataset Profile
                    Column
                    {
                        width: parent.width
                        visible: !root.__info_chosen && root.__dataset_profile !== ""
                        SmlFieldLabel { text: "Dataset profile"; active: dataset_metadata_profile_input.focus; width: parent.width }
                        SmlTextArea
                        {
                            read_only: root.__reiterate
                            id: dataset_metadata_profile_input
                            // Only used to infer the goal, so ignored once a goal or a model is chosen
                            disabled: root.__goal !== "" || root.__model_selected !== "" || root.__cnn_mode
                            text: root.__dataset_profile
                            placeholder_text: "Dataset profile"
                            width: parent.width
                            height: root.__reiterate ? Math.max(root.__input_height_big, dataset_metadata_profile_input.content_height) : root.__input_height_big
                            KeyNavigation.tab: optimize_carbon_input
                            onTextEdited:
                            {
                                root.__dataset_metadata_profile = text
                            }
                            onFocusChanged:
                            {
                                if(focus === true)
                                {
                                    scroll_view.scroll_to(root.__form_y(dataset_metadata_description_input) - Theme.space6)
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------------- Sustainability
            SmlCard
            {
                id: sustainability_card
                width: parent.width
                visible: !root.__info_hf
                title: "Sustainability targets"
                subtitle: root.__info_chosen ? "Where the model will run" : "Carbon footprint, memory and where the model will run"
                icon_name: "leaf"

                Column
                {
                    width: sustainability_card.content_area.width
                    spacing: Theme.space4

                    Row
                    {
                        width: parent.width
                        spacing: Theme.space4
                        visible: !root.__info_chosen

                        // Carbon footprint optimization
                        Column
                        {
                            width: root.__col(parent.width, 3)
                            SmlFieldLabel { text: "Carbon footprint optimization"; active: optimize_carbon_input.popup.visible; width: parent.width }
                            SmlCombobox
                            {
                                read_only: root.__reiterate
                                activeFocusOnTab: true
                                focus: true
                                id: optimize_carbon_input
                                // A selected model is used as is: there is no search to optimize
                                disabled: root.__model_selected !== "" || root.__cnn_mode
                                displayText: root.__optimize_carbon_footprint_manual ? "Manual" : (root.__optimize_carbon_footprint_auto ? "Auto" : "")
                                placeholder_text: displayText !== "" ? "" : "Select optimization iteration method"
                                model: ["(empty)", "Manual", "Auto"]
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: desired_carbon_footprint_input
                                onText_changed:
                                {
                                    if (text === "Manual")
                                    {
                                        root.__optimize_carbon_footprint_auto = false
                                        root.__optimize_carbon_footprint_manual = true
                                    }
                                    else if (text === "Auto")
                                    {
                                        root.__optimize_carbon_footprint_auto = true
                                        root.__optimize_carbon_footprint_manual = false
                                    }
                                    else if (text === "(empty)")
                                    {
                                        root.__optimize_carbon_footprint_auto = false
                                        root.__optimize_carbon_footprint_manual = false
                                    }
                                }
                                onFocusChanged: {
                                    if(focus === true){
                                        optimize_carbon_input.currentIndex = -1
                                        optimize_carbon_input.open()
                                        optimize_carbon_input.focus = true
                                    }
                                }
                                onTab_pressed: {
                                    desired_carbon_footprint_input.focus = true
                                }
                            }
                        }

                        // Desired carbon footprint
                        Column
                        {
                            width: root.__col(parent.width, 3)
                            SmlFieldLabel { text: "Desired carbon footprint"; active: desired_carbon_footprint_input.focus; width: parent.width }
                            SmlInput
                            {
                                read_only: root.__reiterate
                                id: desired_carbon_footprint_input
                                // Only meaningful as the target of a Manual or Auto optimization
                                disabled: root.__model_selected !== "" || root.__cnn_mode ||
                                          (!root.__optimize_carbon_footprint_manual && !root.__optimize_carbon_footprint_auto)
                                text: root.__desired_carbon_footprint === 0.0 ? "" : root.__desired_carbon_footprint
                                validator: RegExpValidator { regExp: /^[0-9]*\.?[0-9]*$/ }
                                placeholder_text: disabled ? "Select an optimization method first" : "Target per inference in gCO2e (only numbers)"
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: max_mem_footprint_input
                                onTextChanged:
                                {
                                    var num = parseFloat(text)
                                    root.__desired_carbon_footprint = isNaN(num) ? 0.0 : num
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(desired_carbon_footprint_input) - Theme.space6)
                                    }
                                }
                            }
                        }

                        // Max mem footprint
                        Column
                        {
                            width: root.__col(parent.width, 3)
                            SmlFieldLabel { text: "Max memory footprint"; active: max_mem_footprint_input.focus; width: parent.width }
                            SmlInput
                            {
                                read_only: root.__reiterate
                                id: max_mem_footprint_input
                                disabled: root.__model_selected !== "" || root.__cnn_mode
                                text: root.__max_memory_footprint === 0 ? "" : root.__max_memory_footprint
                                validator: RegExpValidator { regExp: /^[0-9]*$/ }
                                placeholder_text: "Maximum model memory in MB, empty for no limit (only numbers)"
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: geo_location_continent_input
                                onTextChanged:
                                {
                                    var num = parseInt(text)
                                    root.__max_memory_footprint = isNaN(num) ? 0 : num
                                }
                                onFocusChanged:
                                {
                                    if(focus === true)
                                    {
                                        scroll_view.scroll_to(root.__form_y(max_mem_footprint_input) - Theme.space6)
                                    }
                                }
                            }
                        }
                    }

                    Row
                    {
                        width: parent.width
                        spacing: Theme.space4

                        // Geo location: continent
                        Column
                        {
                            width: root.__col(parent.width, 2)
                            SmlFieldLabel { text: "Geo location: continent"; active: geo_location_continent_input.popup.visible; width: parent.width }
                            SmlCombobox
                            {
                                read_only: root.__reiterate
                                activeFocusOnTab: true
                                id: geo_location_continent_input
                                displayText: root.__geo_location_continent
                                placeholder_text: displayText !== "" ? "" : "Select continent where the model will run"
                                model: ["(empty)"].concat(Countries.continents)
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: geo_location_region_input
                                onText_changed:
                                {
                                    if (text === "(empty)")
                                    {
                                        root.__geo_location_continent = ""
                                        root.__geo_location_region = ""
                                    }
                                    else if (Countries.continents.indexOf(text) !== -1 && text !== root.__geo_location_continent)
                                    {
                                        root.__geo_location_continent = text
                                        root.__geo_location_region = ""
                                    }
                                }
                                onFocusChanged: {
                                    if(focus === true){
                                        geo_location_continent_input.currentIndex = -1
                                        geo_location_continent_input.open()
                                        geo_location_continent_input.focus = true
                                    }
                                }
                                onTab_pressed: {
                                    geo_location_region_input.focus = true
                                }
                            }
                        }

                        // Geo location: country. Stored as its ISO alpha-2 code, used for the grid carbon intensity
                        Column
                        {
                            width: root.__col(parent.width, 2)
                            SmlFieldLabel { text: "Geo location: country"; active: geo_location_region_input.popup.visible; width: parent.width }
                            SmlCombobox
                            {
                                read_only: root.__reiterate
                                activeFocusOnTab: true
                                id: geo_location_region_input
                                disabled: root.__geo_location_continent === ""
                                searchable: true
                                displayText: Countries.name(root.__geo_location_continent, root.__geo_location_region)
                                placeholder_text: displayText !== "" ? "" : (disabled ? "Select a continent first" : "Select country where the model will run")
                                model: ["(empty)"].concat(Countries.names(root.__geo_location_continent))
                                width: parent.width
                                height: root.__input_height
                                KeyNavigation.tab: problem_short_description_input
                                onText_changed:
                                {
                                    if (text === "(empty)")
                                        root.__geo_location_region = ""
                                    var code = Countries.code(root.__geo_location_continent, text)
                                    if (code !== "")
                                        root.__geo_location_region = code
                                }
                                onModelChanged:
                                {
                                    geo_location_region_input.currentIndex = -1
                                }
                                onFocusChanged: {
                                    if(focus === true){
                                        geo_location_region_input.currentIndex = -1
                                        geo_location_region_input.open()
                                        geo_location_region_input.focus = true
                                    }
                                }
                                onTab_pressed: {
                                    problem_short_description_input.focus = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Footer: the form's actions (none in the iteration info view)
    Rectangle
    {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: !root.__reiterate
        height: visible ? 64 : 0
        color: Theme.surface

        Rectangle
        {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: Theme.border
        }

        Row
        {
            anchors
            {
                right: parent.right
                rightMargin: Math.max(Theme.pagePadding, (parent.width - Theme.contentMaxWidth) / 2)
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.space2

            // Clear all button
            SmlButton
            {
                id: clear_all_button
                icon_name: Settings.clear_icon_name
                text_value: "Clear all"
                tooltip_text: "Clear all fields and dataset metadata"
                onClicked: root.clear_all()
            }

            // Submit button
            SmlButton
            {
                id: submit_button
                variant: "primary"
                icon_name: Settings.check_icon_name
                text_value: "Submit"
                disabled: root.__refreshing || root.__initializing ||
                    (root.__cnn_mode && root.__model_selected === "") ||
                    (root.__problem_definition.trim() === "" &&
                     root.__problem_short_description.trim() === "" &&
                     root.__model_selected === "" &&
                     root.__dataset_description === "")
                tooltip_text: "Submit the problem and start task"
                onClicked:
                {
                    focus = true
                    root.prepare_task()
                }
            }
        }
    }


    function clear_all()
    {
        // Reset internal state
        root.__problem_short_description = ""
        root.__problem_definition = ""
        root.__inputs = ""
        root.__outputs = ""
        root.__minimum_samples = 1
        root.__maximum_samples = 1
        root.__optimize_carbon_footprint_auto = false
        root.__goal = ""
        root.__optimize_carbon_footprint_manual = false
        root.__previous_iteration = 0
        root.__desired_carbon_footprint = 0.0
        root.__max_memory_footprint = 0
        root.__hardware_required = "PIM-AI-1chip"
        root.__types = "Transformers"
        root.__geo_location_continent = ""
        root.__geo_location_region = ""
        root.__extra_data = ""
        root.__previous_problem_id = 0
        root.__num_outputs = 1
        root.__model_selected = ""
        root.__model_selected_copy = ""
        // __dataset_description/topic/profile/keywords/applications are NOT reset
        // here directly - they're one-way bound FROM main_window.dataset_description
        // etc., and a direct assignment would permanently sever that binding (any
        // dataset uploaded afterward would update main_window's copy but never
        // reach this screen again). clear_all_clicked(), emitted at the end of this
        // function, resets the true source in main.qml instead, which flows back
        // down through the still-intact binding.

        // Reset visible widgets explicitly
        problem_short_description_input.text = ""
        problem_definition_input.text = ""
        inputs_input.text = ""
        outputs_input.text = ""

        minimum_samples_input.text = ""
        maximum_samples_input.text = ""
        num_outputs_input.text = "1"
        desired_carbon_footprint_input.text = ""
        max_mem_footprint_input.text = ""

        // Reset combobox selections
        types_input.currentIndex = 0
        goal_input.currentIndex = -1
        required_hardware_input.currentIndex = -1
        model_select_input.currentIndex = -1
        optimize_carbon_input.currentIndex = -1
        geo_location_continent_input.currentIndex = -1
        geo_location_region_input.currentIndex = -1

        // Notify main.qml that we cleared everything
        root.clear_all_clicked()
    }

    function prepare_task()
    {
        root.send_task(
                root.__problem_short_description,
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
                root.__types)
    }

    // Remove FPGA from transformers hardware list and keep only FPGA for CNNs
    // Back from Results: leave the form editable straight away (the restored inputs
    // arrive asynchronously and onReiterate_user_inputs keeps the goal empty too)
    function unlock_for_back() {
        root.__goal = ""
        root.__model_selected = ""
        root.__model_selected_copy = ""
    }

    function filteredHardwareList() {
        if (root.__types && root.__types.toLowerCase() === "transformers") {
            return (root.__hardware_list || []).filter(function(h) {
                return h !== "FPGA (xczu19eg-ffvb1517-2-i)";
            });
        }
        if (root.__types && root.__types.toLowerCase() === "cnns") {
            return (root.__hardware_list || []).filter(function(h) {
                return h === "FPGA (xczu19eg-ffvb1517-2-i)";
            });
        }
        return root.__hardware_list || [];
    }


    // Error message dialog
    SmlDialog
    {
        id: notSupportDialog
        placeholder_text: "Problem not supported"
        text_value: notSupportProblemMessage
        tone: "warning"
    }
}
