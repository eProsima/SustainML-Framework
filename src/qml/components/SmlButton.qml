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
    property string nightmode_color: Settings.app_color_light
    property string color_pressed: color
    property string nightmode_color_pressed: nightmode_color
    property int size: Settings.button_icon_size
    property real scalingFactor: 1
    property int anim_angle: Settings.button_movement_anim_angle
    property int anim_duration: Settings.button_movement_anim_duration

    // External signals
    signal clicked();

    Rectangle
    {
        id: background
        color: ScreenManager.night_mode
                ? sustainml_custom_button.nightmode_color
                : sustainml_custom_button.color
        height: sustainml_custom_button.size * 2
        width: text.width + sustainml_custom_button.size + Settings.spacing_normal * 3
        radius: rounded ? height / 2 : 0
    }

    SmlIcon
    {
        id: icon
        name: sustainml_custom_button.icon_name
        size: sustainml_custom_button.size
        scalingFactor: sustainml_custom_button.scalingFactor
        color: text.__font_color
        nightmode_color: text.__font_color
        color_pressed: sustainml_custom_button.color_pressed
        nightmode_color_pressed: sustainml_custom_button.nightmode_color_pressed
        anim_angle: sustainml_custom_button.anim_angle
        anim_duration: sustainml_custom_button.anim_duration
        anchors
        {
            verticalCenter: background.verticalCenter
            left: background.left
            leftMargin: Settings.spacing_normal
        }
    }

    SmlText
    {
        id: text
        text_kind: sustainml_custom_button.text_kind
        text_value: sustainml_custom_button.text_value
        forced_color: ScreenManager.night_mode
                ? sustainml_custom_button.nightmode_color_pressed
                : sustainml_custom_button.color_pressed
        anchors
        {
            verticalCenter: background.verticalCenter
            verticalCenterOffset: 2
            left: icon.right
            leftMargin: Settings.spacing_normal
        }
    }

    MouseArea
    {
        anchors.centerIn: background
        hoverEnabled: true
        width: background.width * 1.5
        height: background.height * 1.5
        onEntered: icon.start_animation();
        onPressed: { icon.pressed = true; text.force_color = true; }
        onReleased: { icon.pressed = false; text.force_color = false; }
        onClicked: sustainml_custom_button.clicked();
    }
}
