import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Busy indicator: a sprout that grows from the ground and fades, over and over.
    Animates only while shown (an animation repaints the whole window every frame).

    Usage:
        SmlGrowingLoader { running: root.tasking; size: Theme.iconSizeLarge }
 */
Item {
    id: loader

    property int size: Theme.iconSizeDefault
    property string variant: Theme.iconAccent
    property bool running: true

    implicitWidth: size
    implicitHeight: size

    SmlIcon {
        id: sprout
        anchors.fill: parent
        size: loader.size
        name: "sprout"
        variant: loader.variant
        // Grows from its base, like a plant
        transformOrigin: Item.Bottom

        SequentialAnimation {
            running: loader.running && loader.visible && !Theme.reduceMotion
            loops: Animation.Infinite
            onRunningChanged: if (!running) { sprout.scale = 1; sprout.opacity = 1 }

            ParallelAnimation {
                NumberAnimation { target: sprout; property: "scale"; from: 0.35; to: 1; duration: 900; easing.type: Easing.OutBack }
                NumberAnimation { target: sprout; property: "opacity"; from: 0.25; to: 1; duration: 500 }
            }
            PauseAnimation { duration: 350 }
            NumberAnimation { target: sprout; property: "opacity"; to: 0.25; duration: 350; easing.type: Easing.InQuad }
        }
    }
}
