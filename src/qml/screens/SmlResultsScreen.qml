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

Item
{
    id: root

    // Public properties
    property int current_problem_id: -1
    property string errorMessage: ""
    property int current_iteration_id: -1
    // Gate: suppress HW error popup if the model stage already failed (Error/NO_MODEL)
    property var __suppress_hw_error: ({})   // key: "problem:iteration" -> true | false

    // Queue popups so both NO_MODEL and HW errors can show in order
    property var __errorQueue: []

    function __enqueueError(msg) {
        __errorQueue.push(msg)
        if (!errorDialog.visible) {
            __showNextError()
        }
    }

    function __showNextError() {
        if (__errorQueue.length > 0) {
            errorMessage = __errorQueue.shift()
            errorDialog.open()
        }
    }


    // Public signals
    signal results_screen_loaded()
    signal go_home();
    signal go_back_empty_input();
    signal go_back_previous_input();

    // Private properties
    property var list_of_problems: []
    // Tracks, per problem_id, which of the 6 node types have reported at least once -
    // Save is only enabled once a problem is here, i.e. fully complete, not just started.
    property var list_of_ready_problems: []
    property var __completed_nodes: ({})
    readonly property int __margin: Settings.spacing_big * 2
    readonly property int __tab_view_width: 1000
    readonly property int __tab_view_height: 600
    property bool tasking: false

    function __mark_node_complete(problem_id, node_key)
    {
        var seen = root.__completed_nodes[problem_id] || {}
        if (seen[node_key]) return
        seen[node_key] = true
        root.__completed_nodes[problem_id] = seen

        if (Object.keys(seen).length >= 6 && !root.list_of_ready_problems.includes(problem_id))
        {
            root.list_of_ready_problems = root.list_of_ready_problems.concat([problem_id])
        }
    }

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
                tab_view.update_tab_name(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id)
                list_of_problems = list_of_problems.concat([problem_id])
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems = list_of_problems.concat([problem_id])
                tab_view.create_new_tab(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
            root.__mark_node_complete(problem_id, "app_requirements")
        }

        function onNew_hw_constraints_node_output(problem_id, iteration_id, hw_required, max_memory_footprint)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id)
                list_of_problems = list_of_problems.concat([problem_id])
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems = list_of_problems.concat([problem_id])
                tab_view.create_new_tab(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
            root.__mark_node_complete(problem_id, "hw_constraints")
        }


        function onNew_ml_model_metadata_node_output(problem_id, iteration_id, metadata, keywords)
        {
            root.current_problem_id = problem_id;
            root.current_iteration_id = iteration_id;
            if (list_of_problems.length === 0)
            {
                tab_view.update_stack_id(problem_id, 0)
                tab_view.update_problem_id(problem_id, -1)
                tab_view.update_tab_name(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id)
                list_of_problems = list_of_problems.concat([problem_id])
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems = list_of_problems.concat([problem_id])
                tab_view.create_new_tab(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
            root.__mark_node_complete(problem_id, "ml_model_metadata")

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
                tab_view.update_tab_name(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id)
                list_of_problems = list_of_problems.concat([problem_id])
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems = list_of_problems.concat([problem_id])
                tab_view.create_new_tab(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
            root.__mark_node_complete(problem_id, "ml_model")

            var key = problem_id + ":" + iteration_id
            var modelFailed = (model === "Error" || model === "NO_MODEL")

            // 1) Record suppression for HW errors
            __suppress_hw_error[key] = modelFailed

            // 2) Always show NO_MODEL (priority), show ML error too when applicable
            if (model === "NO_MODEL") {
                __enqueueError("No suitable model found for this task. Please refine the problem or constraints.")
            } else if (model === "Error") {
                __enqueueError("Error in node ML Model Provider. Please check the logs for more details.")
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
                tab_view.update_tab_name(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id)
                list_of_problems = list_of_problems.concat([problem_id])
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems = list_of_problems.concat([problem_id])
                tab_view.create_new_tab(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
            root.__mark_node_complete(problem_id, "hw_resources")

            var key = problem_id + ":" + iteration_id
            var hwIsError = (typeof hw_description === "string") &&
                            (hw_description.toLowerCase().indexOf("error") !== -1)

            // If model outcome is still unknown, be conservative: do nothing now
            var suppress = __suppress_hw_error[key]
            if (suppress === undefined) {
                return
            }

            // Only show HW error if the model stage succeeded
            if (hwIsError && suppress === false) {
                __enqueueError("Error in node HW Resource. Please check the logs for more details.")
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
                tab_view.update_tab_name(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id)
                list_of_problems = list_of_problems.concat([problem_id])
            }
            else if (!list_of_problems.includes(problem_id))
            {
                list_of_problems = list_of_problems.concat([problem_id])
                tab_view.create_new_tab(engine.saved_display_name(problem_id) || ("Problem " + problem_id), problem_id, problem_id, "problem_view")
            }
            tab_view.focus(problem_id, problem_id)
            root.__mark_node_complete(problem_id, "carbon_footprint")

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

    SmlScreenHeader
    {
        id: header
        title: "Results"
        subtitle: "Model, hardware and footprint of every evaluated problem"

        navigation: [
            // Go home button
            SmlButton
            {
                id: go_home_button
                icon_name: Settings.home_icon_name
                text_value: "Home"
                disabled: root.tasking
                tooltip_text: "Go to Home screen"
                onClicked: root.go_home()
            },

            // Button for new problem with previous problem data
            SmlIconButton
            {
                id: new_previous_problem_button
                outlined: true
                icon_name: Settings.back_icon_name
                disabled: root.tasking
                tooltip_text: "Back to the previous screen (Problem Definition keeps the previous input)"
                onClicked: root.go_back_previous_input()
            }
        ]

        actions: [
            // Tasking status
            SmlChip
            {
                id: tasking_status_text
                anchors.verticalCenter: parent.verticalCenter
                visible: root.tasking
                text: "Working on task, please wait"
                tone: "accent"
                pulse: true
            },

            // Button for new problem from zero
            SmlButton
            {
                id: new_problem_button
                icon_name: Settings.add_tab_icon_name
                text_value: "New problem"
                disabled: root.tasking
                tooltip_text: "New Problem from Scratch"
                onClicked: root.go_back_empty_input()
            },

            // Button to stop the current tasking
            SmlButton
            {
                id: stop_button
                variant: "danger"
                icon_name: Settings.stop_icon_name
                text_value: "Stop"
                disabled: !root.tasking
                tooltip_text: "Stop Current Task"
                onClicked: {
                    engine.request_for_cancel()
                }
            },

            Rectangle
            {
                width: 1
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.border
            },

            // Button to save currently open results into a named file
            SmlButton
            {
                id: save_results_button
                icon_name: Settings.save_icon_name
                text_value: "Save"
                disabled: list_of_ready_problems.length === 0
                tooltip_text: "Save currently open results into a named file"
                onClicked: save_load_dialogs.open_save()
            },

            // Button to load results from a previously saved file
            SmlButton
            {
                id: load_results_button
                icon_name: Settings.load_icon_name
                text_value: "Load"
                tooltip_text: "Load results from a previously saved file"
                onClicked: save_load_dialogs.open_load()
            }
        ]
    }

    // Content card the problem tabs sit on: rounded corners, except the top-left one while the
    // first tab is selected, square so that tab joins it cleanly at the left end
    Rectangle
    {
        anchors
        {
            fill: tab_view
            topMargin: 38
        }
        radius: Theme.radiusSm
        color: Theme.surface
        border.width: 1
        border.color: Theme.borderStrong

        Item
        {
            visible: tab_view.__current_tab === 0
            anchors { top: parent.top; left: parent.left }
            width: parent.radius
            height: parent.radius
            Rectangle { anchors.fill: parent; color: parent.parent.color }
            Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right } height: 1; color: parent.parent.border.color }
            Rectangle { anchors { top: parent.top; bottom: parent.bottom; left: parent.left } width: 1; color: parent.parent.border.color }
        }
    }

    SmlTabView
    {
        id: tab_view
        anchors
        {
            top: header.bottom
            topMargin: Theme.space4
            left: parent.left
            leftMargin: Theme.pagePadding
            right: parent.right
            rightMargin: Theme.pagePadding
            bottom: parent.bottom
            bottomMargin: Theme.pagePadding
        }
        clip: true

        allowed_stack_components: {"problem_view": "qrc:/qml/fragments/SmlProblemFragment.qml"}
        default_stack_component: "problem_view"
        allow_close_tabs: true
        reduced_tabs: true
        allow_tab_rename: true

        onTab_view_loaded:
        {
            root.results_screen_loaded()
        }
        onTab_renamed:
        {
            // stack_id === problem_id once a tab's first result has arrived
            engine.persist_task_display_name(stack_id, new_title)
        }
        onTabClosed:
        {
            // stack_id_closed === problem_id, per the same convention as rename above
            root.list_of_problems = root.list_of_problems.filter(function(id) { return id !== stack_id_closed })
            root.list_of_ready_problems = root.list_of_ready_problems.filter(function(id) { return id !== stack_id_closed })
            delete root.__completed_nodes[stack_id_closed]
            engine.forget_task(stack_id_closed)
        }
        onRetrieve_default_data:
        {
            // All tabs were closed - show a neutral empty placeholder rather than
            // relabeling it with whatever problem_id was last active (which read as a
            // real, but uncloseable, "Problem N" tab).
            //
            // stack_id is 0, not -1: the six onNew_*_node_output handlers below convert
            // this placeholder into the first real tab in place (via update_stack_id/
            // update_problem_id) whenever list_of_problems is still empty, and that
            // conversion looks specifically for a tab whose stack_id is 0 (matching the
            // very first placeholder SmlTabView itself creates on startup). Using -1
            // here instead used to mean that conversion silently found no match after a
            // close-all-tabs cycle: the stale "New Tab" entry was left behind forever,
            // and the first loaded/live task after it was hijacked into its content slot
            // instead of getting its own correctly labeled tab.
            root.current_problem_id = -1
            tab_view.create_new_tab("New Tab", 0, -1, "problem_view")
            tab_view.focus(0, -1)
            engine.request_current_data(true)
        }
    }

SmlDialog
{
    id: errorDialog
    placeholder_text: "Error"
    tone: "danger"
    text_value: errorMessage

    // Optional: clear the state when leaving
    onClosed: {
        errorMessage = ""
        __showNextError()
    }
}

SmlSaveLoadDialogs
{
    id: save_load_dialogs
    anchors.fill: parent
    save_title: "Save Results"
    load_title: "Load Results"
    no_files_text: "No saved files yet."
    load_part: "tasks"
    onSave_requested: engine.save_current_tasks(name)
    onLoad_requested: engine.load_saved_tasks(name)
}

}
