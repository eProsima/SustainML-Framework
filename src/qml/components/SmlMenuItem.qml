import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Row of an SmlMenu: 30 px, optional icon, rounded green hover tint.
 */
MenuItem {
    id: control

    property string icon_name: ""

    implicitHeight: 30
    leftPadding: Theme.space3
    rightPadding: Theme.space3
    font.family: Theme.uiFontFamily
    font.pixelSize: Theme.fontSizeBody
    hoverEnabled: true

    contentItem: Row {
        spacing: Theme.space2

        SmlIcon {
            visible: control.icon_name !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: control.icon_name
            size: Theme.iconSizeDefault
            variant: Theme.iconDefault
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            textFormat: Text.PlainText
            font: control.font
            color: control.enabled ? Theme.textPrimary : Theme.textDisabled
        }
    }

    background: Rectangle {
        implicitWidth: 192
        radius: Theme.radiusSm
        color: control.down ? Theme.accentSubtleStrong
             : control.highlighted || control.hovered ? Theme.accentSubtle
             : Theme.transparent
    }
}
