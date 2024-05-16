import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

Item {
    id: sustainml_custom_input

    // External properties
    property bool rounded: true
    property int border_width: Settings.input_default_border_width
    property string background_color: ""
    property string background_nightmode_color: ""
    property string border_color: ""
    property string border_editting_color: ""
    property string border_nightmode_color: ""
    property string border_nightmode_editting_color: ""
    property string placeholder_text: ""

    // Internal properties
    property bool __edited: false
    readonly property int __radius: Settings.input_default_rounded_radius
    readonly property string __font_family: SustainMLFont.body_font
    readonly property string __font_size:   Settings.body_font_size
    readonly property string __font_color: ScreenManager.body_font_color

    // External signals
    signal text_changed(string text)

    Rectangle
    {
        id: background

        anchors.fill: parent

        radius: rounded ? sustainml_custom_input.__radius : 0
        color: ScreenManager.night_mode
                ? sustainml_custom_input.background_nightmode_color
                : sustainml_custom_input.background_color
        border.color: ScreenManager.night_mode ? sustainml_custom_input.__edited
                    ? sustainml_custom_input.border_nightmode_editting_color
                    : sustainml_custom_input.border_nightmode_color
                : sustainml_custom_input.__edited
                    ? sustainml_custom_input.border_editting_color
                    : sustainml_custom_input.border_color
        border.width: sustainml_custom_input.border_width

        TextInput
        {
            id: input

            anchors.fill: parent
            anchors.margins: Settings.spacing_normal

            font.family: sustainml_custom_input.__font_family
            font.pixelSize: sustainml_custom_input.__font_size
            wrapMode: TextEdit.WordWrap
            color: sustainml_custom_input.__font_color

            onTextChanged: sustainml_custom_input.text_changed(text)
            onFocusChanged: sustainml_custom_input.__edited = focus
            onActiveFocusChanged: sustainml_custom_input.__edited = activeFocus

            // Custom placeholder field
            SmlText
            {
                id: placeholder_text
                text: sustainml_custom_input.placeholder_text

                width: sustainml_custom_input.width - 2 * Settings.spacing_normal

                force_color: true
                forced_color: "#aaa"
                visible: input.text === ""
            }
        }
    }

    SmlMouseArea
    {
        anchors.fill: parent
        custom_cursor_shape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus()
    }
}
