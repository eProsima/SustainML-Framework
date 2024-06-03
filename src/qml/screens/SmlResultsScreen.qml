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

    // Public properties
    property int current_problem_id: -1


    // Public signals
    signal results_screen_loaded()
    signal go_home();
    signal go_back();

    // Private properties
    property var list_of_problems: []
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __tab_view_width: 1000
    readonly property int __tab_view_height: 600

    Connections
    {
        target: engine

        function onNew_app_requirements_node_output(problem_id, iteration_id, app_requirements)
        {
            if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, -1, problem_id, "problem_view")
            }
            tab_view.focus(undefined, problem_id)
        }

        function onNew_hw_constraints_node_output(problem_id, iteration_id, max_memory_footprint)
        {
            if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, -1, problem_id, "problem_view")
            }
            tab_view.focus(undefined, problem_id)
        }


        function onNew_ml_model_metadata_node_output(problem_id, iteration_id, metadata, keywords)
        {
            if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, -1, problem_id, "problem_view")
            }
            tab_view.focus(undefined, problem_id)
        }

        function onNew_ml_model_node_output(problem_id, iteration_id, model, model_path, properties, properties_path, input_batch, target_latency)
        {
            if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, -1, problem_id, "problem_view")
            }
            tab_view.focus(undefined, problem_id)
        }

        function onNew_hw_resources_node_output(problem_id, iteration_id, hw_description, power_consumption, latency, memory_footprint_of_ml_model, max_hw_memory_footprint)
        {
            if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, -1, problem_id, "problem_view")
            }
            tab_view.focus(undefined, problem_id)
        }

        function onNew_carbon_footprint_node_output(problem_id, iteration_id, carbon_footprint, energy_consumption, carbon_intensity)
        {
            if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, -1, problem_id, "problem_view")
            }
            tab_view.focus(undefined, problem_id)
        }
    }

    // Detect when data has been received to load tabs components
    onCurrent_problem_idChanged:
    {
        tab_view.update_problem_id(current_problem_id, -1)
        tab_view.update_tab_name("Problem " + current_problem_id, 0)
        if (!list_of_problems.includes(current_problem_id))
        {
            list_of_problems.push(current_problem_id)
        }
    }

    // Go home button
    SmlButton
    {
        id: go_home_button
        icon_name: Settings.home_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: "Home"
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
            left: parent.left
            leftMargin: Settings.spacing_normal
        }
        onClicked: root.go_home()
    }

    // Go back button
    SmlButton
    {
        icon_name: Settings.back_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: ""
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        anchors
        {
            top: go_home_button.top
            left: go_home_button.right
            leftMargin: Settings.spacing_small
        }
        onClicked: root.go_back()
    }


    SmlTabView
    {
        id: tab_view
        anchors
        {
            top: parent.top
            topMargin: root.__margin
            left: parent.left
            leftMargin: root.__margin
        }

        width: root.__tab_view_width
        height: root.__tab_view_height
        clip: true

        allowed_stack_components: {"problem_view": "qrc:/qml/fragments/SmlProblemFragment.qml"}
        default_stack_component: "problem_view"
        allow_close_tabs: false
        reduced_tabs: true

        onTab_view_loaded:
        {
            root.results_screen_loaded()
        }
        onRetrieve_default_data:
        {
            tab_view.create_new_tab("Problem " + current_problem_id, -1, current_problem_id, "problem_view")
            engine.request_current_data(true)
        }
    }
}
