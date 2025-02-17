// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 1.4

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "components"
import "screens"

Window {
    id: main_window

    // properties
    property bool in_use: true
    property string log: "LOG"
    property string app_requirements_node_last_status: "INACTIVE"
    property string carbon_footprint_node_last_status: "INACTIVE"
    property string hw_constraints_node_last_status: "INACTIVE"
    property string hw_resources_node_last_status: "INACTIVE"
    property string ml_model_node_last_status: "INACTIVE"
    property string ml_model_metadata_node_last_status: "INACTIVE"
    property int current_problem_id: -1
    property int current_iteration_id: -1

    property var modality_list: []
    property var goal_list: []
    property var hardware_list: []
    property bool refreshing: false
    property bool tasking: false

    // Main view properties
    width:  Settings.app_width
    height: Settings.app_height
    visible: true
    title:  Settings.app_name

    Connections
    {
        target: engine
        function onTask_sent(problem_id, iteration_id)
        {
            main_window.current_problem_id = problem_id
            main_window.current_iteration_id = iteration_id
            main_window.tasking = true
            main_window.load_screen(ScreenManager.Screens.Results)
        }

        function onUpdate_log(new_log)
        {
            main_window.log = main_window.log + "\n" + new_log
        }

        function onUpdate_app_requirements_node_status(new_status)
        {
            main_window.app_requirements_node_last_status = new_status
        }

        function onUpdate_carbon_footprint_node_status(new_status)
        {
            main_window.carbon_footprint_node_last_status = new_status
        }

        function onUpdate_hw_constraints_node_status(new_status)
        {
            main_window.hw_constraints_node_last_status = new_status
        }

        function onUpdate_hw_resources_node_status(new_status)
        {
            main_window.hw_resources_node_last_status = new_status
        }

        function onUpdate_ml_model_node_status(new_status)
        {
            main_window.ml_model_node_last_status = new_status
        }

        function onUpdate_ml_model_metadata_node_status(new_status)
        {
            main_window.ml_model_metadata_node_last_status = new_status
        }

        function onRefreshing_on()
        {
            main_window.refreshing = true
        }

        function onModalities_available(list_modalities, list_goals)
        {
            main_window.modality_list = list_modalities
            main_window.goal_list = list_goals
            main_window.refreshing = false
        }

        function onHardwares_available(list_hardwares)
        {
            main_window.hardware_list = list_hardwares
            main_window.refreshing = false
        }

        function onTask_end()
        {
            main_window.tasking = false
        }
    }

    // Background
    Rectangle
    {
        color: ScreenManager.background_color

        // set background size two times the app size
        width:  2 * Settings.app_width
        height: 2 * Settings.app_height

        // Initial position
        x: 0
        y: 0

        // Background shape image
        Image
        {
            id: background
            source: ScreenManager.background_shape

            // set image size two times the app size
            width:  2 * Settings.app_width
            height: 2 * Settings.app_height

            // Initial position
            x: Settings.background_x_initial
            y: 0

            // Image smoothness
            sourceSize.width: Settings.app_width
            sourceSize.height: Settings.app_height
            smooth: true
            antialiasing: true
        }

        // Background shape image #2
        Image
        {
            id: background_2
            source: ScreenManager.background_2_shape

            // set image size two times the app size
            width:  2 * Settings.app_width
            height: 2 * Settings.app_height

            // Initial position hidden
            x: 2 * Settings.app_width
            y: 2 * Settings.app_height

            // Image smoothness
            sourceSize.width: Settings.app_width
            sourceSize.height: Settings.app_height
            smooth: true
            antialiasing: true
        }

        // X axis movement motion animation
        NumberAnimation
        {
            id: background_x_animation
            target: background
            properties: "x"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_width
        }

        // Y axis movement motion animation
        NumberAnimation
        {
            id: background_y_animation
            target: background
            properties: "y"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_height
        }

        // X axis movement motion animation #2
        NumberAnimation
        {
            id: background_2_x_animation
            target: background_2
            properties: "x"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_width
        }

        // Y axis movement motion animation #2
        NumberAnimation
        {
            id: background_2_y_animation
            target: background_2
            properties: "y"
            duration: Settings.background_movement_anim_duration
            to: Settings.app_height
        }
    }

    // Screen view
    StackView
    {
        id: stack_view
        anchors.fill: parent
        initialItem: home_screen

        // HOME SCREEN
        Component
        {
            id: home_screen

            SmlHomeScreen
            {
                id: home_screen_component

                onGo_problem_definition: main_window.load_screen(ScreenManager.Screens.Definition)
            }
        }

        // PROBLEM DEFINITION SCREEN
        Component
        {
            id: definition_screen

            SmlProblemDefinitionScreen
            {
                id: definition_screen_component

                // Pass modalities
                __modality_list: main_window.modality_list
                __goal_list: main_window.goal_list
                __hardware_list: main_window.hardware_list
                __refreshing: main_window.refreshing

                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
                onGo_results: main_window.load_screen(ScreenManager.Screens.Results)
                onSend_task:
                {
                    engine.launch_task(
                            problem_short_description,
                            modality,
                            problem_definition,
                            inputs,
                            outputs,
                            minimum_samples,
                            maximum_samples,
                            optimize_carbon_footprint_auto,
                            goal,
                            optimize_carbon_footprint_manual,
                            previous_iteration,
                            desired_carbon_footprint,
                            max_memory_footprint,
                            hardware_required,
                            geo_location_continent,
                            geo_location_region,
                            extra_data)
                }
                onRefresh:
                {
                    main_window.refreshing = true
                    engine.request_model()
                    engine.request_hardwares()
                }
            }
        }

        // RESULTS SCREEN
        Component
        {
            id: results_screen

            SmlResultsScreen
            {
                id: results_screen_component
                current_problem_id: -1
                tasking: main_window.tasking
                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
                onGo_back: main_window.load_screen(ScreenManager.Screens.Definition) // todo update this
                onResults_screen_loaded:
                {
                    results_screen_component.current_problem_id = main_window.current_problem_id
                    engine.request_current_data(true)
                }
            }
        }

        // LOG SCREEN
        Component
        {
            id: log_screen

            SmlSettingsScreen
            {
                id: log_screen_component

                log: main_window.log
                app: main_window.app_requirements_node_last_status
                carbon: main_window.carbon_footprint_node_last_status
                hw_constraints: main_window.hw_constraints_node_last_status
                hw_resources: main_window.hw_resources_node_last_status
                model: main_window.ml_model_node_last_status
                metadata: main_window.ml_model_metadata_node_last_status

                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
            }
        }

        // New empty screen 1 TO BE USED
        Component
        {
            id: new_screen_1_todo_rename

            Rectangle
            {
                color: "transparent"
                SmlText
                {
                    text_value: "this is a new screen #1"
                    text_kind: SmlText.TextKind.Body

                    anchors.centerIn: parent
                }
            }
        }
        // New empty screen 2 TO BE USED
        Component
        {
            id: new_screen_2_todo_rename

            Rectangle
            {
                color: "transparent"
                SmlText
                {
                    text_value: "this is a new screen #2"
                    text_kind: SmlText.TextKind.Body

                    anchors.centerIn: parent
                }
            }
        }
        // New empty screen 3 TO BE USED
        Component
        {
            id: new_screen_3_todo_rename

            Rectangle
            {
                color: "transparent"
                SmlText
                {
                    text_value: "this is a new screen #3"
                    text_kind: SmlText.TextKind.Body

                    anchors.centerIn: parent
                }
            }
        }
        // New empty screen 4 TO BE USED
        Component
        {
            id: new_screen_4_todo_rename

            Rectangle
            {
                color: "transparent"
                SmlText
                {
                    text_value: "this is a new screen #4"
                    text_kind: SmlText.TextKind.Body

                    anchors.centerIn: parent
                }
            }
        }

        // Transition
        delegate: StackViewDelegate {
            function transitionFinished(properties)
            {
                properties.exitItem.opacity = 1
            }

            pushTransition: StackViewTransition
            {
                PropertyAnimation
                {
                    target: enterItem
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Settings.screen_in_opacity_anim_duration
                }
                PropertyAnimation
                {
                    target: exitItem
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Settings.screen_out_opacity_anim_duration
                }
            }
         }
    }

    SmlIcon
    {
        id: settings_icon
        name:   Settings.settings_icon_name
        color:  Settings.app_color_green_1
        color_pressed:  Settings.app_color_green_2
        nightmode_color:  Settings.app_color_green_4
        nightmode_color_pressed:  Settings.app_color_green_3
        size: Settings.button_big_icon_size

        x: parent.width -  (size * 2)
        y: parent.height - (size * 2)

        SmlMouseArea
        {
            anchors.centerIn: parent
            hoverEnabled: true
            width: parent.width * 1.5
            height: parent.height * 1.5
            onEntered: settings_icon.start_animation();
            onPressed: settings_icon.pressed = true;
            onReleased: settings_icon.pressed = false;
            //onClicked: main_window.load_screen(ScreenManager.Screens.Log);
            onClicked: ScreenManager.night_mode = !ScreenManager.night_mode
        }
    }

    // Logs button
    SmlButton
    {
        id: logs_button
        icon_name: ""
        text_kind: SmlText.Header_3
        text_value: "Logs"
        rounded: true
        color: "transparent" //Settings.app_color_green_3
        color_pressed: Settings.app_color_green_1
        nightmode_color: "transparent" //Settings.app_color_green_1
        nightmode_color_pressed: Settings.app_color_green_3

        // Layout constraints
        anchors
        {
            top: settings_icon.top
            topMargin: Settings.spacing_normal
            verticalCenter: settings_icon.verticalCenter
        }

        // Button actions
        onClicked: main_window.load_screen(ScreenManager.Screens.Log)
    }

    // Screen loader plus background animation trigger
    function load_screen(screen)
    {
        var screen_to_be_loaded  = ScreenManager.current_screen // current screen as default

        // Check if actual change is required
        if (ScreenManager.current_screen !== screen)
        {
            // Select actual screen identifier
            switch (screen)
            {
                case ScreenManager.Screens.Definition:
                    screen_to_be_loaded = definition_screen
                    break
                case ScreenManager.Screens.Results:
                    screen_to_be_loaded = results_screen
                    break
                case ScreenManager.Screens.Log:
                    screen_to_be_loaded = log_screen
                    break
                // Add new screens here
                case ScreenManager.Screens.NewScreen1TODOrename:
                    screen_to_be_loaded = new_screen_1_todo_rename
                    break
                case ScreenManager.Screens.NewScreen2TODOrename:
                    screen_to_be_loaded = new_screen_2_todo_rename
                    break
                case ScreenManager.Screens.NewScreen3TODOrename:
                    screen_to_be_loaded = new_screen_3_todo_rename
                    break
                case ScreenManager.Screens.NewScreen4TODOrename:
                    screen_to_be_loaded = new_screen_4_todo_rename
                    break
                default:
                case ScreenManager.Screens.Home:
                    screen_to_be_loaded = home_screen
                    break
            }

            // Select actual screen location
            var position_to_be_moved = main_window.get_movement(screen)

            // Set background animation
            background_x_animation.to = position_to_be_moved[0]
            background_y_animation.to = position_to_be_moved[1]
            background_2_x_animation.to = position_to_be_moved[2]
            background_2_y_animation.to = position_to_be_moved[3]

            // update current status variables
            ScreenManager.current_screen = screen

            // Run the animations and perform screen change
            stack_view.replace({item: screen_to_be_loaded, replace: true, destroyOnPop: true})
            background_x_animation.start()
            background_y_animation.start()
            background_2_x_animation.start()
            background_2_y_animation.start()
        }
    }

    // Determine location of each screen
    function get_movement (screen)
    {
        var movement = [0,0,0,0]
        switch (screen)
        {
            case ScreenManager.Screens.Definition:
                movement[0] = Settings.background_x_final
                movement[1] = Settings.background_y_initial
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
            case ScreenManager.Screens.Results:
                movement[0] = Settings.background_x_final
                movement[1] = Settings.background_y_final
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
            case ScreenManager.Screens.Log:
                movement[0] = Settings.background_x_initial
                movement[1] = Settings.background_y_final
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
            // Add new screens here
            case ScreenManager.Screens.NewScreen1TODOrename:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_initial
                movement[3] = Settings.background_2_y_initial
                break
            case ScreenManager.Screens.NewScreen2TODOrename:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_initial
                movement[3] = Settings.background_2_y_final
                break
            case ScreenManager.Screens.NewScreen3TODOrename:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_final
                movement[3] = Settings.background_2_y_initial
                break
            case ScreenManager.Screens.NewScreen4TODOrename:
                movement[0] = Settings.app_width * 5
                movement[1] = Settings.app_height * 5
                movement[2] = Settings.background_2_x_final
                movement[3] = Settings.background_2_y_final
                break
            default:
            case ScreenManager.Screens.Home:
                movement[0] = Settings.background_x_initial
                movement[1] = Settings.background_y_initial
                movement[2] = Settings.app_width * 5
                movement[3] = Settings.app_height * 5
                break
        }
        return movement
    }
}
