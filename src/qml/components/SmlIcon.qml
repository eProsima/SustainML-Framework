import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    An icon of the generated Lucide set (see style/icons.md).

    variant is a colour variant name, not a colour: use the Theme names
    (Theme.iconDefault, iconMuted, iconAccent, iconOnAccent, iconDanger...), which
    follow the light and dark themes.

    clickable_text turns the icon into a small clickable target with that tooltip;
    new icon-only controls should be an SmlIconButton instead.

    Usage:
        SmlIcon { name: "leaf"; variant: Theme.iconAccent; size: Theme.iconSizeLarge }
 */
Image {
    id: sustainml_custom_icon

    // External properties
    // Not "required": an object with a required property inside a Repeater/ComboBox delegate
    // makes Qt 5.15 withhold modelData and index from that whole delegate
    property string name: ""
    property string variant: Theme.iconDefault
    property int size: Theme.iconSizeDefault
    property string clickable_text: ""
    property int tooltip_delay: 600
    property int tooltip_timeout: 0
    property bool pressed: false

    signal clicked()

    width: size
    height: size
    sourceSize.width: size * 2
    sourceSize.height: size * 2
    fillMode: Image.PreserveAspectFit
    antialiasing: true
    smooth: true
    mipmap: true

    source: name !== "" ? "qrc:/images/icons/" + name + "/" + name + "_" + variant + ".svg" : ""

    Accessible.role: clickable_text !== "" ? Accessible.Button : Accessible.Graphic
    Accessible.name: clickable_text

    // Hover tint behind a clickable icon
    Rectangle {
        z: -1
        visible: sustainml_custom_icon.clickable_text !== ""
        anchors.centerIn: parent
        width: parent.width + 2 * Theme.space1 + 2
        height: width
        radius: Theme.radiusSm
        color: mouse_area.pressed ? Theme.pressedBackground
             : mouse_area.containsMouse ? Theme.hoverBackground : Theme.transparent
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    SmlMouseArea {
        id: mouse_area
        anchors.centerIn: parent
        width: parent.width + 2 * Theme.space1 + 2
        height: width
        enabled: sustainml_custom_icon.clickable_text !== "" && !main_window.tasking
        acceptedButtons: !main_window.tasking ? Qt.AllButtons : Qt.NoButton
        default_cursor_shape: Qt.ArrowCursor
        custom_cursor_shape: main_window.tasking ? Qt.ArrowCursor : Qt.PointingHandCursor

        onPressed:  if (!main_window.tasking) parent.pressed = true;
        onReleased: if (!main_window.tasking) parent.pressed = false;
        onClicked:  if (!main_window.tasking) parent.clicked();
    }

    SmlToolTip {
        visible: sustainml_custom_icon.clickable_text !== "" && mouse_area.containsMouse
        text: sustainml_custom_icon.clickable_text
        delay: sustainml_custom_icon.tooltip_delay
        timeout: sustainml_custom_icon.tooltip_timeout
    }
}
