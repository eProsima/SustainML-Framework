import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Item
{
    id: root

    // External signals
    signal go_problem_definition();

    Rectangle
    {
        color: "transparent"

        // Dummy Header
        SmlText
        {
            id: header_text
            text_value: "eProsima. This would be a header with multiple options"
            text_kind: SmlText.Header_2

            // Layout constraints
            anchors
            {
                top: parent.top
                topMargin: Settings.spacing_big
                left: parent.left
                leftMargin: Settings.spacing_big
            }
        }

        // SustainML Logo
        Image
        {
            id: sustainML_logo

            source: Settings.app_logo

            // set image size
            height: Settings.app_height / 2

            // Layout constraints
            anchors
            {
                left: parent.left
                leftMargin: (Settings.app_width / 2) - Settings.spacing_normal
                top: header_text.bottom
                topMargin: Settings.spacing_big
            }

            // Image smoothness
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
        }

        // SustainML Title
        SmlText
        {
            id: sustainML_text
            text_value: "SustainML"
            text_kind: SmlText.App_name

            // Layout constraints
            anchors
            {
                left: parent.left
                leftMargin: Settings.spacing_big
                top: header_text.bottom
                topMargin: Settings.spacing_big
            }
        }

        // SustainML subtitle
        SmlText
        {
            id: title_text
            text_value: "AI serving to reduce the footprint"
            text_kind: SmlText.Header_3

            // Layout constraints
            anchors
            {
                top: sustainML_text.bottom
                topMargin: -Settings.spacing_small
                left: sustainML_text.left
            }
        }

        // SustainML introduction text
        SmlText
        {
            id: subtitle_text
            text_value: "Sustainable and interactive ML framework"
            text_kind: SmlText.Body

            // Layout constraints
            anchors
            {
                top: title_text.bottom
                topMargin: Settings.spacing_small
                left: title_text.left
            }
        }

        // Bullet points
        SmlIcon
        {
            id: bullet_point_1
            name: Settings.bullet_point_icon_name
            color: Settings.app_color_green_1
            nightmode_color: Settings.app_color_green_3
            size: Settings.bullet_point_icon_size

            // Layout constraints
            anchors
            {
                top: subtitle_text.bottom
                topMargin: Settings.spacing_normal
                left: subtitle_text.left
            }
        }
        SmlText
        {
            id: bullet_point_1_text
            text_value: "Comprehensively prioritize and advocate energy\nefficiency across the  lifecycle of an application"
            text_kind: SmlText.Body

            // Layout constraints
            anchors
            {
                top: bullet_point_1.top
                topMargin: -3
                left: bullet_point_1.right
                leftMargin: Settings.spacing_small
            }
        }
        SmlIcon
        {
            id: bullet_point_2
            name: Settings.bullet_point_icon_name
            color: Settings.app_color_green_1
            nightmode_color: Settings.app_color_green_3
            size: Settings.bullet_point_icon_size

            // Layout constraints
            anchors
            {
                top: bullet_point_1_text.bottom
                topMargin: Settings.spacing_small
                left: bullet_point_1.left
            }
        }
        SmlText
        {
            text_value: "Avoid AI-waste and reduce the carbon footprint"
            text_kind: SmlText.Body

            // Layout constraints
            anchors
            {
                top: bullet_point_2.top
                topMargin: -3
                left: bullet_point_2.right
                leftMargin: Settings.spacing_small
            }
        }

        // Start button
        SmlButton
        {
            id: start_button
            icon_name: Settings.start_icon_name
            text_kind: SmlText.Header_2
            text_value: "Start now"
            rounded: true
            color: Settings.app_color_green_3
            color_pressed: Settings.app_color_green_1
            nightmode_color: Settings.app_color_green_1
            nightmode_color_pressed: Settings.app_color_green_3
            size: Settings.button_big_icon_size

            // Layout constraints
            anchors
            {
                top: bullet_point_2.bottom
                topMargin: Settings.spacing_big
                left: header_text.left
                leftMargin: Settings.spacing_big
            }

            // Button actions
            onClicked: root.go_problem_definition();
        }
    }
}
