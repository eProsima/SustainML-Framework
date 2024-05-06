import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

ScrollBar {
    id: sustainml_custom_scrollbar

    enum ScrollBarLayout {
        Vertical,
        Horizontal
    }

    // External properties
    property int rounded_radius: Settings.input_default_rounded_radius
    property int layout: SmlScrollBar.ScrollBarLayout.Vertical
    property int drag_width: Settings.scrollbar_default_size
    property string background_color: ""
    property string background_nightmode_color: ""
    property string drag_color: ""
    property string drag_nightmode_color: ""

    // Content draggable item
    contentItem: Rectangle {
        //implicitWidth: sustainml_custom_scrollbar.layout == SmlScrollBar.ScrollBarLayout.Vertical
        //    ? sustainml_custom_scrollbar.drag_width : parent.width
        implicitWidth: sustainml_custom_scrollbar.drag_width
        radius: sustainml_custom_scrollbar.rounded_radius
        color: ScreenManager.night_mode
                ? sustainml_custom_scrollbar.drag_nightmode_color
                : sustainml_custom_scrollbar.drag_color
    }

    // Background item
    background: Rectangle {
        implicitWidth: sustainml_custom_scrollbar.drag_width
        radius: sustainml_custom_scrollbar.rounded_radius
        color: ScreenManager.night_mode
                ? sustainml_custom_scrollbar.background_nightmode_color
                : sustainml_custom_scrollbar.background_color
    }
}
