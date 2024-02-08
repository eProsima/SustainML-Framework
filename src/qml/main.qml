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

Window {
    id: main_window

    // properties
    property bool in_use: true

    // Main view properties
    width:  Settings.app_width
    height: Settings.app_height
    visible: true
    title:  Settings.app_name

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
            duration: Settings.background_movement
            to: Settings.app_width
        }

        // Y axis movement motion animation
        NumberAnimation
        {
            id: background_y_animation
            target: background
            properties: "y"
            duration: Settings.background_movement
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

            Rectangle{
                color: "transparent"

                // Display the logo in the corner
                Image
                {
                    id: sustainML_logo

                    source: Settings.app_logo

                    // set image size
                    height: Settings.app_height / 2

                    // Layout constraints
                    anchors
                    {
                        left: parent.left
                        leftMargin: Settings.spacing_big
                        top: parent.top
                        topMargin: Settings.spacing_big
                    }

                    // Image smoothness
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true
                }

                SmlText
                {
                    id: sustainML_text
                    text_value: "SustainML"
                    text_kind: SmlText.App_name

                    // Layout constraints
                    anchors
                    {
                        horizontalCenter: sustainML_logo.horizontalCenter
                        top: sustainML_logo.bottom
                        topMargin: Settings.spacing_normal
                    }
                }

                SmlText
                {
                    id: title_text
                    text_value: "AI serving to reduce the footprint"
                    text_kind: SmlText.Header_3

                    // Layout constraints
                    anchors
                    {
                        top: sustainML_text.bottom
                        topMargin: -Settings.spacing_small
                        left: sustainML_text.left
                    }
                }

                SmlText
                {
                    id: example_text
                    text_value: "This is an example test to check \nthe style in the GUI"
                    text_kind: SmlText.Body

                    // Layout constraints
                    anchors
                    {
                        top: title_text.bottom
                        topMargin: Settings.spacing_small
                        left: title_text.left
                    }
                }
            }
        }

        // PROBLEM DEFINITION SCREEN
        Component
        {
            id: definition_screen

            Rectangle{
                color: "transparent"

                SmlText {
                    text_value: "this is the definition screen, where input data would be collected."
                    text_kind: SmlText.TextKind.Body

                    x: 50
                    y: 90
                }
            }
        }

        // RESULTS SCREEN
        Component
        {
            id: results_screen

            Rectangle{
                color: "transparent"

                SmlText {
                    text_value: "this is the results screen, where results are displayed to the user."
                    text_kind: SmlText.TextKind.Body

                    x: 50
                    y: 90
                }

                SmlText {
                    text_value: "CO2 footprint"
                    text_kind: SmlText.TextKind.Header_2

                    x: 50
                    y: 150
                }

                SmlText {
                    text_value: "180 g"
                    text_kind: SmlText.TextKind.Body

                    x: 50
                    y: 200
                }
            }
        }

        // LOG SCREEN
        Component
        {
            id: log_screen

            Rectangle{
                color: "transparent"
                ScrollView {
                    verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
                    horizontalScrollBarPolicy: Qt.ScrollBarAsNeeded
                    x: 50
                    y: 90
                    width: 900
                    height: 600

                    SML_Text {
                        id: logger
                        text_value: "LOG"
                        text_kind: SML_Text.Text_kind.Body

                        Connections
                        {
                            target: engine
                            function onUpdate_log(log) {
                                logger.text_value = logger.text_value + "\n" + log
                            }
                        }
                    }
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
                    duration: Settings.screen_in_opacity
                }
                PropertyAnimation
                {
                    target: exitItem
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Settings.screen_out_opacity
                }
            }
         }
    }

    Button
    {
        x: 1000
        y: 40
        text: "Go home screen, top-left"
        onClicked: {
            main_window.load_screen(ScreenManager.Screens.Home)
        }
    }

    Button
    {
        x: 1000
        y: 80
        text: "Go problem definition screen, top-right"
        onClicked: {
            main_window.load_screen(ScreenManager.Screens.Definition)
        }
    }

    Button
    {
        x: 1000
        y: 120
        text: "Go results screen, bottom-right"
        onClicked: {
            main_window.load_screen(ScreenManager.Screens.Results)
        }
    }

    Button
    {
        x: 1000
        y: 160
        text: "Go LOG screen, bottom-left"
        onClicked: {
            main_window.load_screen(ScreenManager.Screens.Log)
        }
    }

    Button
    {
        x: 1000
        y: 240
        text: "Send dummy task"
        onClicked: {
            engine.launch_task()
        }
    }

    Button
    {
        x: Settings.app_width - 200
        y: Settings.app_height - 60
        text: "Swap Color Theme"
        onClicked: {
            ScreenManager.night_mode = !ScreenManager.night_mode
        }
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
