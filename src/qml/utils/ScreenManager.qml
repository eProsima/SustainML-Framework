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
        DatasetPath,
        Log,
        Reiterate,
        UNet,
        HFsearch,
        Compare,
        HFresults,
        UNetGraph,
        Start           // launch splash (Start button + gear); Home is an alias for Definition
    }

    // Variables that user might change during the app execution
    property bool night_mode:     false // Default light mode
    property int  current_screen: 0     // ScreenManager.Screens.Home

    // Background shapes of the current theme (colours: see Theme.qml)
    readonly property string background_shape:   night_mode ? Settings.shape_dark        : Settings.shape_light
    readonly property string background_2_shape: night_mode ? Settings.shape_2_dark      : Settings.shape_2_light
}
