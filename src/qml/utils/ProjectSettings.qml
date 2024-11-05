pragma Singleton
import QtQuick 2.15

QtObject {
    // MAIN APP SETTINGS
    readonly property string app_name: "SustainML"
    readonly property int app_width:   1280
    readonly property int app_height:  800

    // COLORS
    readonly property color app_color_green_1: "#3f6a2b"
    readonly property color app_color_green_2: "#62a343"
    readonly property color app_color_green_3: "#cbee19"
    readonly property color app_color_green_4: "#64c537"
    readonly property color app_color_light:   "#eaeeea"
    readonly property color app_color_dark:    "#394039"

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

    // IMAGES
    readonly property string app_logo:      "qrc:/images/logos/sustainml.svg"
    readonly property string shape_light:   "qrc:/images/shape3.svg"
    readonly property string shape_dark:    "qrc:/images/shape3_dark.svg"

    // LOGOS
    readonly property string eProsima_logo:             "qrc:/images/logos/eprosima.png"
    readonly property string eProsima_nightmode_logo:   "qrc:/images/logos/eprosima_w.png"
    readonly property string dfki_logo:                 "qrc:/images/logos/dfki.jpeg"
    readonly property string dfki_nightmode_logo:       "qrc:/images/logos/dfki.jpeg"
    readonly property string ibm_logo:                  "qrc:/images/logos/ibm.svg"
    readonly property string ibm_nightmode_logo:        "qrc:/images/logos/ibm_w.svg"
    readonly property string inria_logo:                "qrc:/images/logos/inria.png"
    readonly property string inria_nightmode_logo:      "qrc:/images/logos/inria.png"
    readonly property string ku_logo:                   "qrc:/images/logos/ku.png"
    readonly property string ku_nightmode_logo:         "qrc:/images/logos/ku_w.png"
    readonly property string rptu_logo:                 "qrc:/images/logos/rptu.png"
    readonly property string rptu_nightmode_logo:       "qrc:/images/logos/rptu_w.png"
    readonly property string upmem_logo:                "qrc:/images/logos/upmem.jpeg"
    readonly property string upmem_nightmode_logo:      "qrc:/images/logos/upmem.jpeg"
    readonly property int logo_height:                  48

    // ICONS
    readonly property string back_icon_name:            "back"
    readonly property string bullet_point_icon_name:    "leaf"
    readonly property string home_icon_name:            "home"
    readonly property string start_icon_name:           "leaf"
    readonly property string settings_icon_name:        "gear"
    readonly property string submit_icon_name:          "leaf"
    readonly property string arrow_down_icon_name:      "down"
    readonly property string add_tab_icon_name:         "plus"
    readonly property string close_tab_icon_name:       "cross"

    // ICON SIZES
    readonly property int button_icon_size:         30
    readonly property int button_big_icon_size:     50
    readonly property int bullet_point_icon_size:   20

    // ELEMENTS SPECIFICATIONS
    readonly property int input_default_rounded_radius: 20
    readonly property int input_default_border_width:    3
    readonly property int scrollbar_default_size:       10

    // ANIMATIONS DURATION
    readonly property int background_movement_anim_duration:  400 //ms
    readonly property int screen_in_opacity_anim_duration:    400 //ms
    readonly property int screen_out_opacity_anim_duration:   100 //ms
    readonly property int button_movement_anim_duration:      200 //ms

    // ANIMATIONS SETTINGS
    readonly property int background_x_initial:      300
    readonly property int background_x_medium:      -400
    readonly property int background_x_final:      -1100
    readonly property int background_y_initial:       50
    readonly property int background_y_medium:      -350
    readonly property int background_y_final:       -750
    readonly property int button_movement_anim_angle: 30
}
