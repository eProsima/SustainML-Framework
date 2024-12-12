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

                onGo_home: main_window.load_screen(ScreenManager.Screens.Home)
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
                            optimize_carbon_footprint_manual,
                            previous_iteration,
                            desired_carbon_footprint,
                            geo_location_continent,
                            geo_location_region,
                            extra_data)
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

        x: Settings.app_width -  (size * 2)
        y: Settings.app_height - (size * 2)

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

            // update current status variables
            ScreenManager.current_screen = screen

            // Run the animations and perform screen change
            stack_view.replace({item: screen_to_be_loaded, replace: true, destroyOnPop: true})
            background_x_animation.start()
            background_y_animation.start()
        }
    }

    // Detemine location of each screen
    function get_movement (screen)
    {
        var movement = [0,0]
        switch (screen)
        {
            case ScreenManager.Screens.Definition:
                movement[0] = Settings.background_x_final
                movement[1] = Settings.background_y_initial
                break
            case ScreenManager.Screens.Results:
                movement[0] = Settings.background_x_final
                movement[1] = Settings.background_y_final
                break
            case ScreenManager.Screens.Log:
                movement[0] = Settings.background_x_initial
                movement[1] = Settings.background_y_final
                break
            default:
            case ScreenManager.Screens.Home:
                movement[0] = Settings.background_x_initial
                movement[1] = Settings.background_y_initial
                break
        }
        return movement
    }
}
