import QtQuick 2.15
import QtQuick.Window 2.2

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

MouseArea {
    id: sustainml_custom_mouse_area

    property var default_cursor_shape: Qt.ArrowCursor
    property var custom_cursor_shape:  Qt.PointingHandCursor

    hoverEnabled: true

    onEntered: {
        if (enabled && acceptedButtons !== Qt.NoButton)
            cursorShape = custom_cursor_shape
        else
            cursorShape = default_cursor_shape
    }
    onExited:  {
        cursorShape = default_cursor_shape
    }
}
