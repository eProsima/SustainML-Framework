import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Every menu and context menu: rounded overlay card with 4 px padding. Declare its rows
    as SmlMenuItem.
 */
Menu {
    id: control

    padding: Theme.space1
    implicitWidth: 200

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFast } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFast } }

    background: Rectangle {
        implicitWidth: 200
        radius: Theme.radiusMd
        color: Theme.overlay
        border.width: 1
        border.color: Theme.borderStrong

        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.bottomMargin: -3
            radius: parent.radius
            color: Theme.shadow
        }
    }
}
