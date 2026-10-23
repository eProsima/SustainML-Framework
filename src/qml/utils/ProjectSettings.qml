pragma Singleton
import QtQuick 2.15

QtObject {
    // MAIN APP SETTINGS
    readonly property string app_name: "SustainML"
    readonly property int app_width:   1280
    readonly property int app_height:  720

    // SPACING
    readonly property int spacing_big:    30
    readonly property int spacing_normal: 15
    readonly property int spacing_small:  10

    // IMAGES
    readonly property string app_logo:      "qrc:/images/logos/sustainml.svg"
    readonly property string shape_light:   "qrc:/images/shape3.svg"
    readonly property string shape_dark:    "qrc:/images/shape3_dark.svg"
    readonly property string shape_2_light: "qrc:/images/shape1.svg"
    readonly property string shape_2_dark:  "qrc:/images/shape1_dark.svg"

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
    readonly property int logo_height:                  36

    // ICONS
    readonly property string back_icon_name:            "back"
    readonly property string bullet_point_icon_name:    "leaf"
    readonly property string home_icon_name:            "home"
    readonly property string start_icon_name:           "leaf"
    readonly property string settings_icon_name:        "gear"
    readonly property string add_tab_icon_name:         "plus"
    readonly property string close_tab_icon_name:       "cross"
    readonly property string refresh_icon_name:         "refresh"
    readonly property string stop_icon_name:            "square"
    readonly property string rename_icon_name:          "pencil"
    readonly property string delete_icon_name:          "trash"
    readonly property string save_icon_name:            "save"
    readonly property string load_icon_name:            "load"
    readonly property string compare_icon_name:         "scale"
    readonly property string comparisons_icon_name:     "history"
    readonly property string clear_icon_name:            "mop"
    readonly property string results_icon_name:          "checklist"
    readonly property string upload_icon_name:           "upload"
    readonly property string check_icon_name:            "check"
    readonly property string search_icon_name:           "search"
    readonly property string browse_icon_name:           "folder"

    // ANIMATIONS DURATION
    readonly property int background_movement_anim_duration:  400 //ms
    readonly property int screen_in_opacity_anim_duration:    400 //ms
    readonly property int screen_out_opacity_anim_duration:   100 //ms

    // ANIMATIONS SETTINGS
    readonly property int background_x_initial:      300
    readonly property int background_x_final:      -1100
    readonly property int background_y_initial:       50
    readonly property int background_y_final:       -750
    // Background 2 initially has the same coordinates as the main background
    readonly property int background_2_x_initial: background_x_initial
    readonly property int background_2_x_final:   background_x_final
    readonly property int background_2_y_initial: background_y_initial
    readonly property int background_2_y_final:   background_y_final
}
