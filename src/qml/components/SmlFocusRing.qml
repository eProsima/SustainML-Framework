import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Keyboard focus outline of a control: 2 px in the focus colour, just outside it.
    Shown only for keyboard focus (visualFocus), never after a mouse click.

    Usage (inside a control):
        SmlFocusRing { shown: control.visualFocus; radius: Theme.radiusSm }
 */
Rectangle {
    property bool shown: parent && parent.visualFocus === true

    anchors.fill: parent
    anchors.margins: -3
    radius: Theme.radiusSm + 3
    color: Theme.transparent
    border.width: 2
    border.color: Theme.focusRing
    visible: shown
}
