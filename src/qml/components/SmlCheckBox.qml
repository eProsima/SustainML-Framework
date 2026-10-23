import QtQuick 2.15
import QtQuick.Templates 2.15 as T

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Check box: 18 px box with a 1 px outline (3:1), filled in SustainML green with a
    white check when checked.
 */
T.CheckBox {
    id: control

    implicitWidth: implicitIndicatorWidth + leftPadding + rightPadding
    implicitHeight: implicitIndicatorHeight + topPadding + bottomPadding
    padding: 0
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.4

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: Theme.radiusXs
        color: control.checked ? Theme.accentFill : Theme.raised
        border.width: 1
        border.color: control.checked ? Theme.accentBorder : control.hovered ? Theme.brandGreen : Theme.borderInput
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        SmlIcon {
            anchors.centerIn: parent
            visible: control.checked
            name: "check"
            size: Theme.iconSizeDense
            variant: Theme.iconOnAccent
        }
    }

    contentItem: Item { }

    SmlFocusRing { shown: control.visualFocus; radius: Theme.radiusXs + 3 }
}
