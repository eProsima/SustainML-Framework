import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

TextInput {
    id: sustainml_custom_input

    // External properties
    property bool rounded: true
    property int border_width: Settings.input_default_border_width
    property string background_color: ""
    property string background_nightmode_color: ""
    property string background_disable_color: Settings.app_color_disable
    property string border_color: ""
    property string border_editting_color: ""
    property string border_nightmode_color: ""
    property string border_nightmode_editting_color: ""
    property string placeholder_text: ""
    property bool disabled: false

    // Internal properties
    property bool __edited: false
    readonly property int __radius: Settings.input_default_rounded_radius
    readonly property string __font_family: SustainMLFont.body_font
    readonly property string __font_size:   Settings.body_font_size
    readonly property string __font_color: ScreenManager.body_font_color

    padding: Settings.spacing_normal
    font.family: sustainml_custom_input.__font_family
    font.pixelSize: sustainml_custom_input.__font_size
    wrapMode: TextEdit.WordWrap
    color: sustainml_custom_input.__font_color

    //focus: sustainml_custom_input.focus
    selectByMouse: true
    selectionColor: ScreenManager.night_mode ? Settings.app_color_green_2 : Settings.app_color_green_4
    enabled: !disabled

    Rectangle
    {
        id: background

        anchors.fill: parent
        z:-1

        radius: rounded ? sustainml_custom_input.__radius : 0
        color: ScreenManager.night_mode
                ? sustainml_custom_input.background_nightmode_color
                : sustainml_custom_input.disabled
                ? sustainml_custom_input.background_disable_color
                : sustainml_custom_input.background_color
        border.color: ScreenManager.night_mode ? sustainml_custom_input.__edited
                    ? sustainml_custom_input.border_nightmode_editting_color
                    : sustainml_custom_input.border_nightmode_color
                : sustainml_custom_input.__edited
                    ? sustainml_custom_input.border_editting_color
                    : sustainml_custom_input.border_color
        border.width: sustainml_custom_input.border_width


        // Custom placeholder field
        SmlText
        {
            id: placeholder_text
            text_value: sustainml_custom_input.placeholder_text

            width: sustainml_custom_input.width
            leftPadding: sustainml_custom_input.padding
            topPadding: sustainml_custom_input.padding

            force_color: true
            forced_color: sustainml_custom_input.disabled ? "#888" : "#aaa"
            visible: sustainml_custom_input.text === ""

            SmlMouseArea
            {
                anchors.fill: parent
                custom_cursor_shape: Qt.IBeamCursor

                onPressed:  { sustainml_custom_input.forceActiveFocus(); }
                onClicked: { sustainml_custom_input.forceActiveFocus(); }
                onDoubleClicked: { sustainml_custom_input.forceActiveFocus(); }
            }
        }
        SmlMouseArea
        {
            anchors.fill: parent
            custom_cursor_shape: Qt.IBeamCursor
            propagateComposedEvents: true

            onPressed:  { mouse.accepted = false; }
            onReleased: { mouse.accepted = false; }
            onPressAndHold: { mouse.accepted = false; }
            onClicked: { mouse.accepted = false; }
            onDoubleClicked: { mouse.accepted = false; }
        }
    }
    onFocusChanged: sustainml_custom_input.__edited = focus
    onActiveFocusChanged: sustainml_custom_input.__edited = activeFocus
}
