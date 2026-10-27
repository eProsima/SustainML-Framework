import QtQuick 2.15
import QtQuick.Templates 2.15 as T

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Icon-only button: screen header navigation, row actions, toolbars.

    A real button (Tab reaches it, Space / Enter press it) whose tooltip is also its
    accessible name, so every icon-only button must have one. Clicking it does not
    take the focus away from a text field being edited.

    Usage:
        SmlIconButton {
            icon_name: "home"
            tooltip_text: "Go to the Home screen"
            onClicked: ...
        }
 */
T.AbstractButton {
    id: control

    // External properties
    property string icon_name: ""
    property string tooltip_text: ""
    // Icon variant when idle, and when checked
    property string icon_variant: Theme.iconDefault
    property string checked_icon_variant: Theme.iconAccent
    // 28, 34 (default) or 40
    property int button_size: Theme.controlHeight
    property int icon_size: button_size >= 40 ? Theme.iconSizeLarge : button_size <= 28 ? Theme.iconSizeDense + 1 : Theme.iconSizeDefault + 2
    property bool disabled: false
    // Outlined, on a raised fill: for icon buttons that stand next to text buttons
    property bool outlined: false
    // Rotation of the icon only (e.g. a spinning refresh icon)
    property real icon_rotation: 0

    implicitWidth: button_size
    implicitHeight: button_size
    enabled: !disabled
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    opacity: enabled ? 1.0 : 0.4

    Accessible.role: Accessible.Button
    Accessible.name: tooltip_text

    background: Rectangle {
        radius: Theme.radiusSm
        color: control.outlined ? Theme.raised : Theme.transparent
        border.width: control.outlined ? 1 : 0
        border.color: control.hovered ? Theme.brandGreen : Theme.borderStrong

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: !control.enabled ? Theme.transparent
                 : control.down ? Theme.accentSubtleStrong
                 : (control.hovered || control.checked) ? Theme.accentSubtle
                 : Theme.transparent
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
    }

    contentItem: Item {
        SmlIcon {
            anchors.centerIn: parent
            name: control.icon_name
            size: control.icon_size
            variant: control.checked ? control.checked_icon_variant : control.icon_variant
            rotation: control.icon_rotation
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    SmlToolTip {
        visible: control.tooltip_text !== "" && (control.hovered || control.visualFocus) && !control.pressed
        text: control.tooltip_text
    }

    SmlFocusRing { shown: control.visualFocus }
}
