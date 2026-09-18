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
    property var __saved_file_names: []
    property bool __opening_save_dialog: false
    // Which save is currently selected (highlighted) in the Load picker - loading
    // now requires an explicit Load click, a row click only selects it.
    property string __selected_saved_file: ""

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

        function onSaved_files_available(names)
        {
            root.__saved_file_names = names
            if (root.__opening_save_dialog)
            {
                root.__opening_save_dialog = false
                save_name_dialog.open()
            }
            else
            {
                root.__selected_saved_file = ""
                load_picker_dialog.open()
            }
        }

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
            engine.request_for_cancel()
        }
    }

    // Button to save currently open results into a named file
    SmlButton
    {
        id: save_results_button
        icon_name: ""
        text_kind: SmlText.TextKind.Header_2
        text_value: "Save"
        disabled: list_of_ready_problems.length === 0
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        tooltip_text: "Save currently open results into a named file"
        anchors
        {
            top: go_home_button.top
            left: stop_button.right
            leftMargin: Settings.spacing_small
        }
        onClicked: {
            save_name_field.text = ""
            root.__opening_save_dialog = true
            engine.request_saved_files_list()
        }
    }

    // Button to load results from a previously saved file
    SmlButton
    {
        id: load_results_button
        icon_name: ""
        text_kind: SmlText.TextKind.Header_2
        text_value: "Load"
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        tooltip_text: "Load results from a previously saved file"
        anchors
        {
            top: go_home_button.top
            left: save_results_button.right
            leftMargin: Settings.spacing_small
        }
        onClicked: engine.request_saved_files_list()
    }

    // Tasking status text
    SmlText
    {
        id: tasking_status_text
        visible: root.tasking
        text_kind: SmlText.TextKind.Header_3
        font.pixelSize: 25
        text_value: "Working on task, please wait"
        // Center when there's room, but never let it overlap the button row on narrow windows
        x: Math.max((parent.width - width) / 2, load_results_button.x + load_results_button.width + Settings.spacing_big)
        anchors {
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
            root.current_problem_id = -1
            tab_view.create_new_tab("New Tab", -1, -1, "problem_view")
            tab_view.focus(-1, -1)
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

    // Optional: clear the state when leaving
    onClosed: {
        errorMessage = ""
        __showNextError()
    }
}

Dialog
{
    id: save_name_dialog
    anchors.centerIn: parent
    modal: true
    padding: 16
    standardButtons: Dialog.Save | Dialog.Cancel

    background: Rectangle
    {
        anchors.fill: parent
        radius: 10
        color: Settings.app_color_light
        border.color: Settings.app_color_green_4
        border.width: 1
    }

    header: Item { }

    contentItem: Column
    {
        id: save_dialog_column
        spacing: 16

        SmlText
        {
            text_value: "Save Results"
            text_kind: SmlText.TextKind.Header_2
            width: 280
            horizontalAlignment: Text.AlignHCenter
        }

        SmlText
        {
            text_value: "Name this save, or pick an existing one below to overwrite it:"
            text_kind: SmlText.TextKind.Body
            width: 280
        }

        TextField
        {
            id: save_name_field
            width: 280
            placeholderText: "e.g. experiment 1"
        }

        SmlText
        {
            visible: root.__saved_file_names.length > 0
            text_value: "Existing saves:"
            text_kind: SmlText.TextKind.Body
            width: 280
        }

        ScrollView
        {
            width: 280
            height: Math.min(save_existing_column.implicitHeight, 160)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column
            {
                id: save_existing_column
                // Narrower than the ScrollView itself, leaving clearance on the right
                // for its overlay scrollbar so it doesn't cover the row content.
                width: 280 - 16
                spacing: 8

                Repeater
                {
                    model: root.__saved_file_names

                    delegate: Rectangle
                    {
                        id: existing_save_row
                        required property var modelData

                        width: save_existing_column.width
                        height: 36
                        radius: height / 2.5
                        // "Selected" here just means it matches whatever's currently
                        // typed in the name field - the same thing clicking a row sets,
                        // so it also highlights correctly if someone types a match by hand.
                        color: existing_save_row.modelData === save_name_field.text
                            ? Settings.app_color_green_1
                            : (ScreenManager.night_mode ? Settings.app_color_green_2 : Settings.app_color_green_4)

                        SmlText
                        {
                            anchors
                            {
                                left: parent.left
                                leftMargin: Settings.spacing_normal
                                right: parent.right
                                rightMargin: Settings.spacing_normal
                                verticalCenter: parent.verticalCenter
                            }
                            force_elide: true
                            text_value: existing_save_row.modelData
                            text_kind: SmlText.TextKind.Body
                            force_color: true
                            forced_color: ScreenManager.night_mode ? Settings.app_color_green_1 : Settings.app_color_green_3
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: save_name_field.text = existing_save_row.modelData
                        }
                    }
                }
            }
        }
    }

    onAccepted:
    {
        var chosen_name = save_name_field.text.trim()
        if (chosen_name.length > 0)
        {
            engine.save_current_tasks(chosen_name)
        }
    }
}

Dialog
{
    id: load_picker_dialog
    anchors.centerIn: parent
    modal: true
    padding: 16
    standardButtons: Dialog.Open | Dialog.Cancel

    width: 320

    Component.onCompleted:
    {
        var open_button = load_picker_dialog.standardButton(Dialog.Open)
        open_button.text = "Load"
        open_button.enabled = Qt.binding(function() { return root.__selected_saved_file !== "" })
    }

    onAccepted:
    {
        if (root.__selected_saved_file !== "")
        {
            engine.load_saved_tasks(root.__selected_saved_file)
        }
    }

    background: Rectangle
    {
        anchors.fill: parent
        radius: 10
        color: Settings.app_color_light
        border.color: Settings.app_color_green_4
        border.width: 1
    }

    header: Item { }

    contentItem: Column
    {
        id: load_dialog_column
        spacing: 12
        width: load_picker_dialog.availableWidth

        SmlText
        {
            text_value: "Load Results"
            text_kind: SmlText.TextKind.Header_2
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        SmlText
        {
            visible: root.__saved_file_names.length === 0
            text_value: "No saved files yet."
            text_kind: SmlText.TextKind.Body
            width: parent.width
        }

        ScrollView
        {
            width: parent.width
            height: Math.min(load_files_column.implicitHeight, 260)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column
            {
                id: load_files_column
                // Narrower than the ScrollView itself, leaving clearance on the right
                // for its overlay scrollbar so it doesn't cover the row content
                // (including the delete X, which sits at the row's right edge).
                width: load_picker_dialog.contentItem.width - 16
                spacing: 8

                Repeater
                {
                    model: root.__saved_file_names

                    delegate: Rectangle
                    {
                        id: saved_file_row
                        required property var modelData

                        width: load_files_column.width
                        height: 36
                        radius: height / 2.5
                        color: saved_file_row.modelData === root.__selected_saved_file
                            ? Settings.app_color_green_1
                            : (ScreenManager.night_mode ? Settings.app_color_green_2 : Settings.app_color_green_4)

                        SmlText
                        {
                            id: saved_file_label
                            anchors
                            {
                                left: parent.left
                                leftMargin: Settings.spacing_normal
                                right: delete_icon.left
                                rightMargin: Settings.spacing_small
                                verticalCenter: parent.verticalCenter
                            }
                            force_elide: true
                            text_value: saved_file_row.modelData
                            text_kind: SmlText.TextKind.Body
                            force_color: true
                            forced_color: ScreenManager.night_mode ? Settings.app_color_green_1 : Settings.app_color_green_3
                        }

                        SmlIcon
                        {
                            id: delete_icon
                            anchors
                            {
                                right: parent.right
                                rightMargin: Settings.spacing_normal
                                verticalCenter: parent.verticalCenter
                            }
                            name: Settings.close_tab_icon_name
                            size: Settings.spacing_normal
                            color: Settings.app_color_green_3
                            nightmode_color: Settings.app_color_green_1
                        }

                        // Click anywhere but the X to select this saved file - loading
                        // itself happens via the separate Load button below
                        MouseArea
                        {
                            anchors
                            {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                                right: delete_icon.left
                                rightMargin: -Settings.spacing_small
                            }
                            onClicked: root.__selected_saved_file = saved_file_row.modelData
                        }

                        // Click the X to delete just this one saved file
                        MouseArea
                        {
                            anchors
                            {
                                left: delete_icon.left
                                leftMargin: -Settings.spacing_small
                                top: parent.top
                                bottom: parent.bottom
                                right: parent.right
                            }
                            onClicked:
                            {
                                engine.delete_saved_file(saved_file_row.modelData)
                                root.__saved_file_names = root.__saved_file_names.filter(function(n) { return n !== saved_file_row.modelData })
                                if (root.__selected_saved_file === saved_file_row.modelData)
                                {
                                    root.__selected_saved_file = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

}
