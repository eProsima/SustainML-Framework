// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15


// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Item
{
    id:root

    // Public signals
    signal go_home();
    signal go_back();
    
    // Internal properties
    readonly property int __margin: Settings.spacing_big * 1
    readonly property int __input_height: 50
    readonly property int __input_height_big: 120
    readonly property int __input_width: 900
    readonly property int __input_width_split: 435
    readonly property int __input_width_small: 293

    property bool tasking: false

    signal send_dataset_path_task();

    // Background mouse area
    MouseArea
    {
        anchors.fill: parent
        onClicked: focus = true
    }

    // Go home button
    SmlButton
    {
        id: go_home_button
        icon_name: Settings.home_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: "Home"
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        anchors
        {
            top: parent.top
            topMargin: Settings.spacing_normal
            left: parent.left
            leftMargin: Settings.spacing_normal
        }
        onClicked: root.go_home()

    }

    // Go back button
    SmlButton
    {
        id: go_back_button
        icon_name: Settings.back_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: ""
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        anchors
        {
            top: go_home_button.top
            left: go_home_button.right
            leftMargin: Settings.spacing_small
        }
        onClicked: root.go_back()
    }

    SmlText {
        id: dataset_selector
        text_kind: SmlText.TextKind.Header_1
        text_value: "Dataset Selector"
        color: Settings.app_color_green_1
        anchors
        {
            top: go_back_button.bottom
            topMargin: Settings.spacing_normal
            horizontalCenter: parent.horizontalCenter
        }
    }

    SmlInput {
        id: dataset_path_input
        border_color: Settings.app_color_green_4
        border_nightmode_color: Settings.app_color_green_1
        background_color: Settings.app_color_light
        background_nightmode_color: Settings.app_color_dark
        height: root.__input_height
        width: root.__input_width
        placeholder_text: "Select a dataset file..."
        readOnly: true
        anchors
        {
            horizontalCenter: parent.horizontalCenter
            top: dataset_selector.bottom
            topMargin: Settings.spacing_normal
        }
    }

    SmlButton {
        id: browse_button
        icon_name: Settings.start_icon_name
        text_kind: SmlText.TextKind.Header_2
        text_value: "Browse"
        rounded: true
        color: Settings.app_color_green_4
        color_pressed: Settings.app_color_green_1
        color_text: Settings.app_color_green_3
        nightmode_color: Settings.app_color_green_2
        nightmode_color_pressed: Settings.app_color_green_3
        nightmode_color_text: Settings.app_color_green_1
        anchors
        {
            top: dataset_path_input.bottom
            topMargin: Settings.spacing_normal
            horizontalCenter: parent.horizontalCenter
        }
        onClicked: dataset_file_dialog.open()
        height: root.__input_height
    }
    

    FileDialog {
        id: dataset_file_dialog
        title: "Select Dataset"
        selectFolder: false
        nameFilters: ["CSV Files (*.csv)", "JSON Files (*.json)", "All Files (*)"]
        onAccepted: {
            const file = dataset_file_dialog.fileUrl.toString();
            dataset_path_input.text = file
            engine.launch_dataset_path_task(file)
            root.send_dataset_path_task();
        }
    }

    // Tasking status text
    SmlText
    {
        id: tasking_status_text
        visible: root.tasking
        text_kind: SmlText.TextKind.Header_3
        font.pixelSize: 25
        text_value: "Extracting metadata, please wait"
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: browse_button.bottom
            topMargin: Settings.spacing_big
        }
    }

    // Tasking status icon
    SmlIcon
    {
        id: tasking_status_icon
        visible: root.tasking
        name:   Settings.bullet_point_icon_name
        color:  Settings.app_color_green_1
        color_pressed:  Settings.app_color_green_2
        nightmode_color:  Settings.app_color_green_4
        nightmode_color_pressed:  Settings.app_color_green_3
        size: Settings.button_icon_size

        anchors{
            verticalCenter: tasking_status_text.verticalCenter
            left: tasking_status_text.right
            leftMargin: Settings.spacing_normal
        }
    }

    SequentialAnimation {
        id: tasking_animation
        running: root.tasking
        loops: Animation.Infinite
        NumberAnimation {
            target: tasking_status_icon
            property: "rotation"
            to: 360
            duration: 4000
            easing.type: Easing.InOutQuad
        }
    }


}