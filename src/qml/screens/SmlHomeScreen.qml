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

        anchors.fill: parent

        // Header
        Rectangle
        {
            id: header
            color: "transparent"
            height: Settings.logo_height * 1.5
            width: (eProsima_logo.width + dfki_logo.width + ibm_logo.width + inria_logo.width + ku_logo.width + rptu_logo.width + upmem_logo.width + Settings.spacing_big + Settings.spacing_normal * 5 - 10)


            // Layout constraints
            anchors
            {
                top: parent.top
                topMargin: Settings.spacing_big
                horizontalCenter: parent.horizontalCenter
            }

            // eProsima Logo
            Image
            {
                id: eProsima_logo

                source: ScreenManager.night_mode ?   Settings.eProsima_nightmode_logo : Settings.eProsima_logo

                // set image size
                height: Settings.logo_height * 1.5

                // Layout constraints
                anchors
                {
                    left: parent.left
                    leftMargin: -Settings.spacing_small
                    top: parent.top
                }

                // Image smoothness
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                SmlMouseArea
                {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://www.eprosima.com/");
                }
            }
            // dfki logo
            Image
            {
                id: dfki_logo

                source: ScreenManager.night_mode ?   Settings.dfki_nightmode_logo : Settings.dfki_logo

                // set image size
                height: Settings.logo_height * 0.8

                // Layout constraints
                anchors
                {
                    left: eProsima_logo.right
                    leftMargin: Settings.spacing_big
                    verticalCenter: eProsima_logo.verticalCenter
                }

                // Image smoothness
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                SmlMouseArea
                {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://www.dfki.de/en/web");
                }
            }
            // ibm logo
            Image
            {
                id: ibm_logo

                source: ScreenManager.night_mode ?   Settings.ibm_nightmode_logo : Settings.ibm_logo

                // set image size
                height: Settings.logo_height * 1.5

                // Layout constraints
                anchors
                {
                    left: dfki_logo.right
                    leftMargin: Settings.spacing_normal
                    verticalCenter: dfki_logo.verticalCenter
                }

                // Image smoothness
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                SmlMouseArea
                {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://www.ibm.com/contact/global");
                }
            }
            // inria logo
            Image
            {
                id: inria_logo

                source: ScreenManager.night_mode ?   Settings.inria_nightmode_logo : Settings.inria_logo

                // set image size
                height: Settings.logo_height

                // Layout constraints
                anchors
                {
                    left: ibm_logo.right
                    leftMargin: Settings.spacing_normal
                    verticalCenter: ibm_logo.verticalCenter
                }

                // Image smoothness
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                SmlMouseArea
                {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://www.inria.fr/en");
                }
            }
            // ku logo
            Image
            {
                id: ku_logo

                source: ScreenManager.night_mode ?   Settings.ku_nightmode_logo : Settings.ku_logo

                // set image size
                height: Settings.logo_height * 3

                // Layout constraints
                anchors
                {
                    left: inria_logo.right
                    leftMargin: Settings.spacing_normal -10
                    verticalCenter: inria_logo.verticalCenter
                }

                // Image smoothness
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                SmlMouseArea
                {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://www.ku.dk/english/");
                }
            }
            // rptu logo
            Image
            {
                id: rptu_logo

                source: ScreenManager.night_mode ?   Settings.rptu_nightmode_logo : Settings.rptu_logo

                // set image size
                height: Settings.logo_height

                // Layout constraints
                anchors
                {
                    left: ku_logo.right
                    leftMargin: Settings.spacing_normal
                    verticalCenter: ku_logo.verticalCenter
                }

                // Image smoothness
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                SmlMouseArea
                {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://rptu.de/en/");
                }
            }
            // upmem logo
            Image
            {
                id: upmem_logo

                source: ScreenManager.night_mode ?   Settings.upmem_nightmode_logo : Settings.upmem_logo

                // set image size
                height: Settings.logo_height

                // Layout constraints
                anchors
                {
                    left: rptu_logo.right
                    leftMargin: Settings.spacing_normal
                    verticalCenter: rptu_logo.verticalCenter
                }

                // Image smoothness
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                SmlMouseArea
                {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://www.upmem.com/");
                }
            }
        }

        // Body
        Rectangle
        {
            id: body
            color: "transparent"
            height: Settings.app_height / 2
            width: (sustainML_logo.width * 2 + Settings.spacing_big)

            // Layout constraints
            anchors
            {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }

            // SustainML Logo
            Image
            {
                id: sustainML_logo

                source: Settings.app_logo

                // set image size
                height: parent.height * 1.1

                // Layout constraints
                anchors
                {
                    right: parent.right
                    topMargin: Settings.spacing_big
                    verticalCenter: parent.verticalCenter
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
                    top: header.bottom
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
                    horizontalCenter: subtitle_text.horizontalCenter
                }

                // Button actions
                onClicked: root.go_problem_definition();
            }
        }
    }
}
