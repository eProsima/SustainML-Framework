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

Rectangle
{
    id: sustainml_fragment_iteration

    // Public properties
    required property int problem_id
    required property int stack_id

    color: ScreenManager.night_mode ? Settings.app_color_dark : Settings.app_color_light

    SmlText
    {
        anchors.centerIn: parent
        text_value: "Here would be the iteration view"
    }
}
