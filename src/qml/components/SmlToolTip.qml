import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Tooltip in the SustainML style: short plain text on the overlay surface.

    Declared inside the item it describes, which places it centred above that item.

    Usage:
        SmlToolTip { visible: mouse.containsMouse; text: "Go to the Results screen" }
 */
ToolTip {
    id: control

    delay: 600
    padding: Theme.space2
    leftPadding: Theme.space3
    rightPadding: Theme.space3
    margins: Theme.space2

    font.family: Theme.uiFontFamily
    font.pixelSize: Theme.fontSizeMeta

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFast } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFast } }

    contentItem: Text {
        text: control.text
        textFormat: Text.PlainText
        font: control.font
        color: Theme.textPrimary
        wrapMode: Text.WordWrap
        width: Math.min(implicitWidth, 320)
    }

    background: Rectangle {
        color: Theme.overlay
        radius: Theme.radiusSm
        border.width: 1
        border.color: Theme.borderStrong

        // Soft drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -2
            radius: parent.radius
            color: Theme.shadow
        }
    }
}
