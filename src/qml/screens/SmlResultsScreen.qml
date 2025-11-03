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
    property string errorMessage: ""
    property int current_iteration_id: -1


    // Public signals
    signal results_screen_loaded()
    signal go_home();
    signal go_back_empty_input();
    signal go_back_previous_input();

    // Private properties
    property var list_of_problems: []
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __tab_view_width: 1000
    readonly property int __tab_view_height: 600
    property bool tasking: false

    Connections
    {
        target: engine

        function onNew_app_requirements_node_output(problem_id, iteration_id, app_requirements)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name("Problem " + problem_id, problem_id)
                list_of_problems.push(problem_id)
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
        }

        function onNew_hw_constraints_node_output(problem_id, iteration_id, hw_required, max_memory_footprint)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name("Problem " + problem_id, problem_id)
                list_of_problems.push(problem_id)
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
        }


        function onNew_ml_model_metadata_node_output(problem_id, iteration_id, metadata, keywords)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name("Problem " + problem_id, problem_id)
                list_of_problems.push(problem_id)
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)

            if (keywords === "Error" && !errorDialog.visible) {
                errorMessage = "Error in node ML Model Metadata. Please check the logs for more details."
                errorDialog.open()
            }
        }

        function onNew_ml_model_node_output(problem_id, iteration_id, model, model_path, properties, properties_path, input_batch, target_latency)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name("Problem " + problem_id, problem_id)
                list_of_problems.push(problem_id)
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)

            if (!errorDialog.visible) {
                if (model === "NO_MODEL") {
                    errorMessage = "No suitable model found for this task. Please refine the problem or constraints."
                    errorDialog.open()
                } else if (model === "Error") {
                    errorMessage = "Error in node ML Model Provider. Please check the logs for more details."
                    errorDialog.open()
                }
            }
        }

        function onNew_hw_resources_node_output(problem_id, iteration_id, hw_description, power_consumption, latency, memory_footprint_of_ml_model, max_hw_memory_footprint)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name("Problem " + problem_id, problem_id)
                list_of_problems.push(problem_id)
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)

            if (hw_description === "Error" && model !== "Error" && model !== "NO_MODEL"  && !errorDialog.visible) {
                errorMessage = "Error in node HW Resource. Please check the logs for more details."
                errorDialog.open()
            }
        }

        function onNew_carbon_footprint_node_output(problem_id, iteration_id, carbon_footprint, energy_consumption, carbon_intensity)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name("Problem " + problem_id, problem_id)
                list_of_problems.push(problem_id)
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems.push(problem_id)
                tab_view.create_new_tab("Problem " + problem_id, problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)

            if (carbon_intensity === 0 && !errorDialog.visible) {
                errorMessage = "Error in node Carbon Footprint. Please check the logs for more details."
                errorDialog.open()
            }

        }

    }

    // Detect when data has been received to load tabs components
    // onCurrent_problem_idChanged:
    // {
    //     tab_view.update_problem_id(current_problem_id, -1)
    //     tab_view.update_tab_name("Problem " + current_problem_id, 0)
    //     if (!list_of_problems.includes(current_problem_id))
    //     {
    //         list_of_problems.push(current_problem_id)
    //     }
    // }

    // Go home button
    SmlButton
    {
        id: go_home_button
        icon_name: Settings.home_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: "Home"
        disabled: root.tasking
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        tooltip_text: "Go to Home screen"
        anchors
        {
            top: parent.top
            topMargin: Settings.spacing_normal
            left: parent.left
            leftMargin: Settings.spacing_normal
        }
        onClicked: root.go_home()
    }

    // Button for new problem with previous problem data
    SmlButton
    {
        id: new_previous_problem_button
        icon_name: Settings.back_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: ""
        disabled: root.tasking
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        tooltip_text: "New Problem with Previous Input"
        anchors
        {
            top: go_home_button.top
            left: go_home_button.right
            leftMargin: Settings.spacing_small
        }
        onClicked: root.go_back_previous_input()
    }

    // Button for new problem from zero
    SmlButton
    {
        id: new_problem_button
        icon_name: Settings.add_tab_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: ""
        disabled: root.tasking
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        tooltip_text: "New Problem from Scratch"
        anchors
        {
            top: go_home_button.top
            left: new_previous_problem_button.right
            leftMargin: Settings.spacing_small
        }
        onClicked: root.go_back_empty_input()
    }

    // Button to stop the current tasking
    SmlButton
    {
        id: stop_button
        icon_name: Settings.stop_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: ""
        disabled: !root.tasking
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        tooltip_text: "Stop Current Task"
        anchors
        {
            top: go_home_button.top
            left: new_problem_button.right
            leftMargin: Settings.spacing_small
        }
        onClicked: {
            engine.cancel_request()  // Stop the current tasking TODO
        }
    }

    // Tasking status text
    SmlText
    {
        id: tasking_status_text
        visible: root.tasking
        text_kind: SmlText.TextKind.Header_3
        font.pixelSize: 25
        text_value: "Working on task, please wait"
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Settings.spacing_normal
        }
    }

    // Tasking status icon
    SmlIcon
    {
        id: tasking_status_icon
        visible: root.tasking
        name:   Settings.bullet_point_icon_name
        color:  Settings.app_color_green_1
        color_pressed:  Settings.app_color_green_2
        nightmode_color:  Settings.app_color_green_4
        nightmode_color_pressed:  Settings.app_color_green_3
        size: Settings.button_icon_size

        anchors{
            verticalCenter: tasking_status_text.verticalCenter
            left: tasking_status_text.right
            leftMargin: Settings.spacing_normal
        }
    }

    SequentialAnimation {
        id: tasking_animation
        running: root.tasking
        loops: Animation.Infinite
        NumberAnimation {
            target: tasking_status_icon
            property: "rotation"
            to: 360
            duration: 4000
            easing.type: Easing.InOutQuad
        }
    }

    SmlTabView
    {
        id: tab_view
        anchors
        {
            horizontalCenter: parent.horizontalCenter
            top: go_home_button.bottom
            topMargin: Settings.spacing_normal
            bottom: parent.bottom
        }

        width: parent.width
        height: parent.height * 0.75
        clip: true

        allowed_stack_components: {"problem_view": "qrc:/qml/fragments/SmlProblemFragment.qml"}
        default_stack_component: "problem_view"
        allow_close_tabs: false
        reduced_tabs: true
        allow_tab_rename: true

        onTab_view_loaded:
        {
            root.results_screen_loaded()
        }
        onRetrieve_default_data:
        {
            tab_view.create_new_tab("Problem " + current_problem_id, -1, current_problem_id, "problem_view")
            tab_view.focus(current_problem_id, current_problem_id)
            engine.request_current_data(true)
        }
    }

SmlDialog
{
    id: errorDialog
    placeholder_text: "ERROR!!"
    text_value: errorMessage
    background_color: Settings.app_color_light
    border_color: Settings.app_color_green_4
    border_width: 1
    rounded: true
    placeholder_text_color: Settings.app_color_blue
    text_color: Settings.app_color_blue

    // Opcional: limpiar estado al cerrar
    onClosed: errorMessage = ""
}

}
