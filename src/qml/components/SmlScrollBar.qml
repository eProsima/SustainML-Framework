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
        Horizontal,
        Both
    }

    // External properties
    property int rounded_radius: Settings.input_default_rounded_radius
    property int layout: SmlScrollBar.ScrollBarLayout.Vertical
    property int drag_width: Settings.scrollbar_default_size
    property string background_color: "transparent"             // Settings.app_color_light
    property string background_nightmode_color: "transparent"   // Settings.app_color_dark
    property string drag_color: Settings.app_color_green_4
    property string drag_nightmode_color: Settings.app_color_green_2

    // Content draggable item
    contentItem: Rectangle {
        radius: sustainml_custom_scrollbar.rounded_radius
        color: ScreenManager.night_mode
                ? sustainml_custom_scrollbar.drag_nightmode_color
                : sustainml_custom_scrollbar.drag_color

        Binding {
            target: parent
            property: "implicitWidth"
            value: sustainml_custom_scrollbar.drag_width
            when: sustainml_custom_scrollbar.layout !== SmlScrollBar.ScrollBarLayout.Horizontal
        }

        Binding {
            target: parent
            property: "implicitHeight"
            value: sustainml_custom_scrollbar.drag_width
            when: sustainml_custom_scrollbar.layout !== SmlScrollBar.ScrollBarLayout.Vertical
        }
    }

    // Background item
    background: Rectangle {
        implicitWidth: sustainml_custom_scrollbar.layout === SmlScrollBar.ScrollBarLayout.Horizontal
                ? parent.width : sustainml_custom_scrollbar.drag_width
        implicitHeight: sustainml_custom_scrollbar.layout === SmlScrollBar.ScrollBarLayout.Vertical
                ? parent.height : sustainml_custom_scrollbar.drag_width
        //radius: sustainml_custom_scrollbar.rounded_radius
        color: ScreenManager.night_mode
                ? sustainml_custom_scrollbar.background_nightmode_color
                : sustainml_custom_scrollbar.background_color

        Binding {
            target: parent
            property: "implicitWidth"
            value: sustainml_custom_scrollbar.drag_width
            when: sustainml_custom_scrollbar.layout !== SmlScrollBar.ScrollBarLayout.Horizontal
        }

        Binding {
            target: parent
            property: "implicitHeight"
            value: sustainml_custom_scrollbar.drag_width
            when: sustainml_custom_scrollbar.layout !== SmlScrollBar.ScrollBarLayout.Vertical
        }
    }

    MouseArea {
        id: drag_area
        anchors.fill: parent
        propagateComposedEvents: true
        hoverEnabled: true

        onEntered:  { drag_area.cursorShape = Qt.PointingHandCursor; }
        onExited:   { drag_area.cursorShape = Qt.ArrowCursor; }
        onPressed:  { mouse.accepted = false; }
        onReleased: { mouse.accepted = false; }
        onPressAndHold: { mouse.accepted = false; }
        onClicked: { mouse.accepted = false; }
        onDoubleClicked: { mouse.accepted = false; }
    }
}
