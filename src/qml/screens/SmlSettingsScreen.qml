// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 1.4

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
            text_value: "App Requirm.:\t" + app
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: header.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
        }
        SmlText {
            id: carbon_item
            text_value: "Carbon Footprint:\t" + carbon
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: app_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
        }
        SmlText {
            id: constraints_item
            text_value: "HW Constraints:\t" + hw_constraints
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: carbon_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
        }
        SmlText {
            id: resources_item
            text_value: "HW Resources:\t" + hw_resources
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: constraints_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
        }
        SmlText {
            id: model_item
            text_value: "ML Model:\t" + model
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: resources_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
        }
        SmlText {
            id: metadata_item
            text_value: "Model Metadata:\t" + metadata
            text_kind: SmlText.TextKind.Body
            anchors
            {
                top: model_item.bottom
                topMargin: Settings.spacing_normal
                left: parent.left
                leftMargin: Settings.spacing_normal
            }
        }

        // Complete log
        ScrollView {
            verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

            anchors
            {
                top: parent.top
                topMargin: Settings.spacing_big
                left: header.right
                leftMargin: root.__margin
            }
            width: 800
            height: 700

            SmlText {
                id: log_item
                text_value: root.log
                text_kind: SmlText.TextKind.Body
            }
        }
    }
}
