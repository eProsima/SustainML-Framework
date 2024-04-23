import QtQuick 2.0

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.ScreenMan 1.0

Image {
    id: sustainml_custom_icon
    antialiasing: true
    smooth: true
    visible: true

    // External properties
    required property string name
    property string color: Settings.app_color_dark
    property string nightmode_color: Settings.app_color_light
    property string color_pressed: color
    property string nightmode_color_pressed: nightmode_color
    property int size: Settings.button_icon_size
    property real scalingFactor: 1
    property int anim_angle: Settings.button_movement_anim_angle
    property int anim_duration: Settings.button_movement_anim_duration
    property bool pressed: false    // if icon has hover effect, change this to true

    // Internal properties, based on the input selection
    readonly property string __final_color: pressed
        ? ScreenManager.night_mode ? nightmode_color_pressed : color_pressed
        : ScreenManager.night_mode ? nightmode_color : color
    sourceSize.width: size * scalingFactor
    sourceSize.height: size * scalingFactor

    source: name ?
                __final_color == Settings.app_color_green_1 ?
                    "qrc:/images/icons/" + name + "/" + name + "_1.svg" :
                __final_color == Settings.app_color_green_2 ?
                    "qrc:/images/icons/" + name + "/" + name + "_2.svg" :
                __final_color == Settings.app_color_green_3 ?
                    "qrc:/images/icons/" + name + "/" + name + "_3.svg" :
                __final_color == Settings.app_color_green_4 ?
                    "qrc:/images/icons/" + name + "/" + name + "_4.svg" :
                __final_color == Settings.app_color_light ?
                    "qrc:/images/icons/" + name + "/" + name + "_w.svg" :
                "qrc:/images/icons/" + name + "/" + name + ".svg" :
            ""
    SequentialAnimation {
        id: rotate
        running: false
        NumberAnimation { target: sustainml_custom_icon; property: "rotation"; to: anim_angle; duration: anim_duration }
        NumberAnimation { target: sustainml_custom_icon; property: "rotation"; to: anim_angle-5; duration: anim_duration / 5 }
        NumberAnimation { target: sustainml_custom_icon; property: "rotation"; to: 0; duration: anim_duration / 3 }
    }

    function start_animation() {
        rotate.running = true
    }
}
