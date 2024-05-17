// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Item
{
    id: root

    // External properties
    property string log: ""
    property string app: ""
    property string carbon: ""
    property string hw_constraints: ""
    property string hw_resources: ""
    property string model: ""
    property string metadata: ""

    // Internal properties
    readonly property int __margin: Settings.spacing_big * 2
    readonly property string __error_status: "#f44336"
    readonly property string __idle_status: Settings.app_color_green_2
    readonly property string __initializing_status: "#f1c232"
    readonly property string __running_status: "#3d85c6"
    readonly property int __font_status_size: 14
    readonly property int __status_margin: (Settings.spacing_big * 3) + 15
    readonly property int __status_width: 80
    readonly property int __status_height: 20

    // External signals
    signal go_home();

    Rectangle
    {
        color: "transparent"

        anchors.fill: parent

        // Go home button
        SmlButton
        {
            icon_name: Settings.home_icon_name
            text_kind: SmlText.TextKind.Header_2
            text_value: "Home"
            rounded: true
            color: Settings.app_color_green_3
            color_pressed: Settings.app_color_green_1
            nightmode_color: Settings.app_color_green_1
            nightmode_color_pressed: Settings.app_color_green_3
            anchors
            {
                top: parent.top
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
            onClicked: root.go_home()
        }

        // Node status
        SmlText {
            id: header
            text_value: "Node Status"
            text_kind: SmlText.TextKind.Header_3
            anchors
            {
                top: parent.top
                left: parent.left
                topMargin: root.__margin + Settings.spacing_big
                leftMargin: Settings.spacing_big
            }
        }

        SmlText {
            id: app_item
            text_value: "App Requirements"
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: header.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }

            Rectangle
            {
                color: app == "IDLE" ? root.__idle_status
                        : app == "RUNNING" ? root.__running_status
                        : app == "INITIALIZING" ? root.__initializing_status
                        : root.__error_status
                radius: Settings.input_default_rounded_radius
                width: root.__status_width
                height: root.__status_height
                anchors
                {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.__status_margin
                }

                SmlText {
                    text_value: app
                    text_kind: SmlText.TextKind.Body
                    force_size: true
                    forced_size: root.__font_status_size
                    anchors.centerIn: parent
                    force_color: true
                    forced_color: Settings.app_color_light
                }
            }
        }
        SmlText {
            id: carbon_item
            text_value: "Carbon Footprint"
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: app_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
            Rectangle
            {
                color: carbon == "IDLE" ? root.__idle_status
                        : carbon == "RUNNING" ? root.__running_status
                        : carbon == "INITIALIZING" ? root.__initializing_status
                        : root.__error_status
                radius: Settings.input_default_rounded_radius
                width: root.__status_width
                height: root.__status_height
                anchors
                {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.__status_margin
                }

                SmlText {
                    text_value: carbon
                    text_kind: SmlText.TextKind.Body
                    force_size: true
                    forced_size: root.__font_status_size
                    anchors.centerIn: parent
                    force_color: true
                    forced_color: Settings.app_color_light
                }
            }
        }
        SmlText {
            id: constraints_item
            text_value: "HW Constraints"
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: carbon_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
            Rectangle
            {
                color: hw_constraints == "IDLE" ? root.__idle_status
                        : hw_constraints == "RUNNING" ? root.__running_status
                        : hw_constraints == "INITIALIZING" ? root.__initializing_status
                        : root.__error_status
                radius: Settings.input_default_rounded_radius
                width: root.__status_width
                height: root.__status_height
                anchors
                {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.__status_margin
                }

                SmlText {
                    text_value: hw_constraints
                    text_kind: SmlText.TextKind.Body
                    force_size: true
                    forced_size: root.__font_status_size
                    anchors.centerIn: parent
                    force_color: true
                    forced_color: Settings.app_color_light
                }
            }
        }
        SmlText {
            id: resources_item
            text_value: "HW Resources"
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: constraints_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
            Rectangle
            {
                color: hw_resources == "IDLE" ? root.__idle_status
                        : hw_resources == "RUNNING" ? root.__running_status
                        : hw_resources == "INITIALIZING" ? root.__initializing_status
                        : root.__error_status
                radius: Settings.input_default_rounded_radius
                width: root.__status_width
                height: root.__status_height
                anchors
                {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.__status_margin
                }

                SmlText {
                    text_value: hw_resources
                    text_kind: SmlText.TextKind.Body
                    force_size: true
                    forced_size: root.__font_status_size
                    anchors.centerIn: parent
                    force_color: true
                    forced_color: Settings.app_color_light
                }
            }
        }
        SmlText {
            id: model_item
            text_value: "ML Model"
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: resources_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
            Rectangle
            {
                color: model == "IDLE" ? root.__idle_status
                        : model == "RUNNING" ? root.__running_status
                        : model == "INITIALIZING" ? root.__initializing_status
                        : root.__error_status
                radius: Settings.input_default_rounded_radius
                width: root.__status_width
                height: root.__status_height
                anchors
                {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.__status_margin
                }

                SmlText {
                    text_value: model
                    text_kind: SmlText.TextKind.Body
                    force_size: true
                    forced_size: root.__font_status_size
                    anchors.centerIn: parent
                    force_color: true
                    forced_color: Settings.app_color_light
                }
            }
        }
        SmlText {
            id: metadata_item
            text_value: "Model Metadata"
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: model_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
            Rectangle
            {
                color: metadata == "IDLE" ? root.__idle_status
                        : metadata == "RUNNING" ? root.__running_status
                        : metadata == "INITIALIZING" ? root.__initializing_status
                        : root.__error_status
                radius: Settings.input_default_rounded_radius
                width: root.__status_width
                height: root.__status_height
                anchors
                {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: root.__status_margin
                }

                SmlText {
                    text_value: metadata
                    text_kind: SmlText.TextKind.Body
                    force_size: true
                    forced_size: root.__font_status_size
                    anchors.centerIn: parent
                    force_color: true
                    forced_color: Settings.app_color_light
                }
            }
        }

        // Complete log
        SmlScrollView {

            anchors
            {
                top: parent.top
                topMargin: Settings.spacing_big
                left: header.right
                leftMargin: root.__margin
            }
            width: 800
            height: 700
            content_width: 800
            content_height: log_item.height

            SmlText {
                id: log_item
                text_value: root.log
                text_kind: SmlText.TextKind.Body
                force_elide: true
                width: parent.width
            }
        }
    }
}
