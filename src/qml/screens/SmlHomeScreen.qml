import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"

Item
{
    id: root

    // External signals
    signal go_problem_definition();

    // Hero: what SustainML is, and the way in
    Item
    {
        id: body
        width: Math.min(parent.width - 2 * Theme.space7, 1120)
        height: Math.max(text_column.implicitHeight, logo_halo.height)
        anchors
        {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -partners.height / 2
        }

        Column
        {
            id: text_column
            width: parent.width * 0.52
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space4

            // SustainML introduction text
            SmlChip
            {
                id: subtitle_text
                text: "Sustainable and interactive ML framework"
                tone: "accent"
                icon_name: Settings.bullet_point_icon_name
            }

            // SustainML Title
            SmlText
            {
                id: sustainML_text
                text_value: "SustainML"
                text_kind: SmlText.App_name
                font.pixelSize: 64
                topPadding: Theme.space1
            }

            // SustainML subtitle
            Text
            {
                id: title_text
                width: parent.width
                text: "AI serving to reduce the footprint"
                textFormat: Text.PlainText
                font.family: Theme.uiFontFamily
                font.pixelSize: 24
                font.weight: Font.DemiBold
                font.letterSpacing: -0.3
                color: Theme.textPrimary
                wrapMode: Text.WordWrap
            }

            Item { width: 1; height: Theme.space1 }

            // Bullet points
            Repeater
            {
                model: [
                    "Comprehensively prioritize and advocate energy efficiency across the lifecycle of an application",
                    "Avoid AI-waste and reduce the carbon footprint"
                ]

                delegate: Row
                {
                    required property string modelData
                    spacing: Theme.space3

                    Rectangle
                    {
                        width: 30
                        height: 30
                        radius: Theme.radiusMd
                        color: Theme.accentSubtle

                        SmlIcon
                        {
                            anchors.centerIn: parent
                            name: Settings.bullet_point_icon_name
                            size: Theme.iconSizeDefault
                            variant: Theme.iconAccent
                        }
                    }

                    Text
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        width: text_column.width - 30 - Theme.space3
                        text: modelData
                        textFormat: Text.PlainText
                        font.family: Theme.uiFontFamily
                        font.pixelSize: 15
                        lineHeight: 1.25
                        color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item { width: 1; height: Theme.space3 }

            // Start button
            SmlButton
            {
                id: start_button
                variant: "primary"
                size: "lg"
                icon_name: Settings.start_icon_name
                text_value: "Start now"
                tooltip_text: "Define a new machine learning problem"

                // Button actions
                onClicked: root.go_problem_definition();
            }
        }

        // SustainML Logo on a soft green halo
        Rectangle
        {
            id: logo_halo
            anchors
            {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            width: Math.min(parent.width * 0.42, 400)
            height: width
            radius: width / 2
            color: Theme.alpha(Theme.brandGreenBright, Theme.darkMode ? 0.16 : 0.3)

            Rectangle
            {
                anchors.centerIn: parent
                width: parent.width * 0.82
                height: width
                radius: width / 2
                color: Theme.surface
                border.width: 1
                border.color: Theme.alpha(Theme.brandGreen, 0.35)
            }

            Image
            {
                id: sustainML_logo

                source: Settings.app_logo

                // set image size
                anchors.centerIn: parent
                width: parent.width * 0.62
                height: width

                // Image smoothness
                sourceSize.width: width
                sourceSize.height: height * 2   // sharp on high-DPI screens
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true
            }
        }
    }

    // Project partners, straight on the page background
    Rectangle
    {
        id: partners
        anchors
        {
            bottom: parent.bottom
            bottomMargin: Theme.space5
            horizontalCenter: parent.horizontalCenter
        }
        width: partners_column.implicitWidth
        height: partners_column.implicitHeight + Theme.space4
        color: Theme.transparent

        Column
        {
            id: partners_column
            anchors.centerIn: parent
            spacing: Theme.space3

            // Header
            Row
            {
                id: header
                anchors.horizontalCenter: parent.horizontalCenter
                height: Settings.logo_height
                spacing: Theme.space6

                // eProsima Logo
                Image
                {
                    id: eProsima_logo

                    source: ScreenManager.night_mode ?   Settings.eProsima_nightmode_logo : Settings.eProsima_logo

                    // set image size
                    height: Settings.logo_height
                    anchors.verticalCenter: parent.verticalCenter

                    // Image smoothness
                    sourceSize.height: height * 2   // sharp on high-DPI screens
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
                    height: Settings.logo_height
                    anchors.verticalCenter: parent.verticalCenter

                    // Image smoothness
                    sourceSize.height: height * 2   // sharp on high-DPI screens
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
                    anchors.verticalCenter: parent.verticalCenter

                    // Image smoothness
                    sourceSize.height: height * 2   // sharp on high-DPI screens
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
                    anchors.verticalCenter: parent.verticalCenter

                    // Image smoothness
                    sourceSize.height: height * 2   // sharp on high-DPI screens
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

                    // set image size (a wide word mark with fine lettering: a little larger than the others)
                    height: Settings.logo_height * 1.6
                    anchors.verticalCenter: parent.verticalCenter

                    // Image smoothness
                    sourceSize.height: height * 2   // sharp on high-DPI screens
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
                    height: Settings.logo_height * 1.5
                    anchors.verticalCenter: parent.verticalCenter

                    // Image smoothness
                    sourceSize.height: height * 2   // sharp on high-DPI screens
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true

                    SmlMouseArea
                    {
                        anchors.fill: parent
                        onClicked: Qt.openUrlExternally("https://rptu.de/en/");
                    }
                }
            }
        }
    }
}
