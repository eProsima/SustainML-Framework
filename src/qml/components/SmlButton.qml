import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

Item {
    id: sustainml_custom_button

    // External properties
    property int text_kind: SmlText.TextKind.Body   // Text body kind as default
    required property string text_value             // Required text introduced by the user
    required property string icon_name              // Required icon name introduced by the user
    required property bool rounded                  // Required if the button has rounded corners
    property string color: Settings.app_color_dark
    property string color_pressed: color
    property string color_text: ""
    property string color_disable: Settings.app_color_disable
    property string nightmode_color: Settings.app_color_light
    property string nightmode_color_pressed: nightmode_color
    property string nightmode_color_text: ""
    property int size: Settings.button_icon_size
    property real scalingFactor: 1
    property int anim_angle: Settings.button_movement_anim_angle
    property int anim_duration: Settings.button_movement_anim_duration
    property bool disabled: false


    property string __font_color:  sustainml_custom_button.text_kind === SmlText.TextKind.App_name ? ScreenManager.app_name_color  :
                                   sustainml_custom_button.text_kind === SmlText.TextKind.Body     ? ScreenManager.body_font_color :
                                                                                                     ScreenManager.title_font_color

    // Internal properties
    property bool __pressed: false

    width: background.width
    height: background.height

    // External signals
    signal clicked();

    Rectangle
    {
        id: background
        color: ScreenManager.night_mode
                ? sustainml_custom_button.nightmode_color
                : sustainml_custom_button.disabled
                ? sustainml_custom_button.color_disable
                : sustainml_custom_button.color
        height: sustainml_custom_button.size * 2
        border.color: text.force_color ? text.forced_color : __font_color
        border.width: 0.5
        // width: text_value === "" ? height : text.width + sustainml_custom_button.size + Settings.spacing_normal * 3
        anchors
        {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        width: contentContainer.width + sustainml_custom_button.size
        radius: rounded ? height / 2.5 : 0
    }

    Rectangle {
        id: contentContainer
        anchors {
            left: background.left
            leftMargin: sustainml_custom_button.size / 2
            right: background.right
            rightMargin: sustainml_custom_button.size / 2
            verticalCenter: background.verticalCenter
        }
        width: (text_value !== "" && icon_name !== "")
                ? text.width + icon.width + 2 * Settings.spacing_normal
                : (text_value !== "" ? text.width : (icon_name !== "" ? icon.width : height))
        color: "transparent"
        height: background.height

        SmlIcon {
            id: icon
            name: sustainml_custom_button.icon_name
            size: sustainml_custom_button.size
            scalingFactor: sustainml_custom_button.scalingFactor
            color: text.color
            nightmode_color: text.color
            color_pressed: sustainml_custom_button.color_pressed
            nightmode_color_pressed: sustainml_custom_button.nightmode_color_pressed
            anim_angle: sustainml_custom_button.anim_angle
            anim_duration: sustainml_custom_button.anim_duration
            pressed: sustainml_custom_button.__pressed
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: (sustainml_custom_button.icon_name !== "" && sustainml_custom_button.text_value !== "") ? sustainml_custom_button.size / 4 : 0
            }
        }

        SmlText {
            id: text
            text_kind: sustainml_custom_button.text_kind
            text_value: sustainml_custom_button.text_value
            force_color: sustainml_custom_button.__pressed === true ? true : ScreenManager.night_mode
                ? sustainml_custom_button.nightmode_color_text !== ""
                : sustainml_custom_button.color_text !== ""
            forced_color: !sustainml_custom_button.__pressed && sustainml_custom_button.nightmode_color_text !== ""
                     && sustainml_custom_button.color_text !== ""
                ? ScreenManager.night_mode
                    ? sustainml_custom_button.nightmode_color_text
                    : sustainml_custom_button.color_text
                : ScreenManager.night_mode
                    ? sustainml_custom_button.nightmode_color_pressed
                    : sustainml_custom_button.color_pressed
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: 2
                left: icon.right
                leftMargin: (sustainml_custom_button.icon_name === "" || sustainml_custom_button.text_value === "")
                             ? 0 : Settings.spacing_normal
            }
        }
    }

    MouseArea
    {
        id: mouse_area
        anchors.centerIn: background
        hoverEnabled: true
        width: background.width
        height: background.height
        onPressed: { if (!sustainml_custom_button.disabled) sustainml_custom_button.__pressed = true; }
        onReleased: { if (!sustainml_custom_button.disabled) sustainml_custom_button.__pressed = false; }
        onClicked: { if (!sustainml_custom_button.disabled) sustainml_custom_button.clicked(); }
        onEntered: { if (!sustainml_custom_button.disabled) { mouse_area.cursorShape = Qt.PointingHandCursor; icon.start_animation(); } }
        onExited:  { if (!sustainml_custom_button.disabled) mouse_area.cursorShape = Qt.ArrowCursor; }
    }
}
