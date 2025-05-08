pragma Singleton
import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0

Item
{
    id: screen_manager

    enum Screens {
        Home,
        Definition,
        Results,
        Log,
        Reiterate,
        NewScreen2TODOrename,
        NewScreen3TODOrename,
        NewScreen4TODOrename
    }

    // Variables that user might change during the app execution
    property bool night_mode:     false // Default light mode
    property int  current_screen: 0     // ScreenManager.Screens.Home

    // Properties set based on the theme color
    readonly property color  background_color:   night_mode ? Settings.app_color_dark    : Settings.app_color_light
    readonly property string background_shape:   night_mode ? Settings.shape_dark        : Settings.shape_light
    readonly property string background_2_shape: night_mode ? Settings.shape_2_dark      : Settings.shape_2_light
    readonly property color  app_name_color:     night_mode ? Settings.app_color_green_3 : Settings.app_color_green_1
    readonly property color  title_font_color:   night_mode ? Settings.app_color_green_4 : Settings.app_color_green_2
    readonly property color  body_font_color:    night_mode ? Settings.app_color_light   : Settings.app_color_dark
}
