pragma Singleton
import QtQuick 2.15

QtObject {
    // MAIN APP SETTINGS
    readonly property string app_name: "SustainML"
    readonly property int app_width:   1280
    readonly property int app_height:  800

    // COLORS
    readonly property color app_color_green_1: "#3F6A2B"
    readonly property color app_color_green_2: "#62A343"
    readonly property color app_color_green_3: "#CBEE19"
    readonly property color app_color_green_4: "#64C537"
    readonly property color app_color_light:   "#EAEEEA"
    readonly property color app_color_dark:   "#394039"

    // SPACING
    readonly property int spacing_big:    50
    readonly property int spacing_normal: 20
    readonly property int spacing_small:  10

    // FONT SIZES
    readonly property int app_name_size:     90
    readonly property int header1_font_size: 60
    readonly property int header2_font_size: 40
    readonly property int header3_font_size: 30
    readonly property int body_font_size:    20

    //IMAGES
    readonly property string app_logo:    "qrc:/images/logo.svg"
    readonly property string shape_light: "qrc:/images/shape3.svg"
    readonly property string shape_dark:  "qrc:/images/shape3_dark.svg"

    // ANIMATIONS DURATION
    readonly property int background_movement:  400 //ms
    readonly property int screen_in_opacity:    400 //ms
    readonly property int screen_out_opacity:   100 //ms

    // ANIMATIONS SETTINGS
    readonly property int background_x_initial: 100
    readonly property int background_x_medium: -500
    readonly property int background_x_final: -1200
    readonly property int background_y_initial:   0
    readonly property int background_y_medium: -400
    readonly property int background_y_final:  -800
}
