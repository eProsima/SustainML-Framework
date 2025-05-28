// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

Dialog {
    id: notSupportDialog

    // External properties
    property bool rounded: true
    property int border_width: 1
    property string background_color: Settings.app_color_light
    property string border_color: Settings.app_color_green_4
    property string placeholder_text: "WARNING!!"
    property string placeholder_text_color: Settings.app_color_blue
    property string text_color: Settings.app_color_blue
    required property string text_value

    anchors.centerIn: parent
    modal: true

    width: contentColumn.implicitWidth
    height: contentColumn.implicitHeight

    background: Rectangle {
        anchors.fill: parent
        radius: rounded ? 10 : 0
        color: background_color
        border.color: border_color
        border.width: border_width
    }

    header: Item { }

    Column {
        id: contentColumn
        spacing: 16
        padding: 16
        anchors.centerIn: parent

        Text {
            text: placeholder_text
            font.pixelSize: 20
            font.bold: true
            color: placeholder_text_color
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: text_value
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            color: text_color
            horizontalAlignment: Text.AlignHCenter
        }

        Button {
            anchors.right: parent.right
            anchors.rightMargin: Settings.spacing_small
            font.pixelSize: 14
            height: 32
            width: 80
            onClicked: notSupportDialog.close()

            background: Rectangle {
                anchors.fill: parent
                radius: 5
                color: Settings.app_color_green_1
            }
            contentItem: Text {
                text: "Ok"
                font.pixelSize: parent.font.pixelSize
                color: Settings.app_color_light
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
