import QtQuick 2.15
import QtQuick.Templates 2.15 as T

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Text button, with an optional leading icon, in one of five roles:

      - "secondary" (default): an ordinary action, on a raised fill with an outline
      - "primary":   the one action a screen or dialog is for, filled in SustainML green
      - "ghost":     a light action among others (navigation), no fill until hovered
      - "subtle":    a toolbar action on the screen header, tinted fill
      - "danger":    an action that deletes or clears: red text and outline on the raised fill

    Pressing changes the colour only, so nothing beside the button moves. A disabled
    button is dimmed and does not react. It is a real button: Tab reaches it and
    Space / Enter press it.

    Usage:
        SmlButton {
            variant: "primary"
            icon_name: "check"
            text_value: "Submit"
            tooltip_text: "Submit the problem and start the task"
            onClicked: ...
        }
 */
T.AbstractButton {
    id: control

    // External properties
    property string text_value: ""
    property string icon_name: ""
    property string variant: "secondary"
    // "sm", "md" (default) or "lg"
    property string size: "md"
    property bool disabled: false
    property string tooltip_text: ""
    property int tooltip_delay: 600
    // Icon and label at the left edge instead of centred (menu rows)
    property bool align_left: false

    readonly property bool primary_: variant === "primary"
    readonly property bool ghost_: variant === "ghost"
    readonly property bool subtle_: variant === "subtle"
    readonly property bool danger_: variant === "danger"

    // Only when set: dialog standard buttons get their text ("Save", "Cancel") from the
    // button box, which a plain "text: text_value" binding would overwrite with ""
    Binding on text { value: control.text_value; when: control.text_value !== "" }
    enabled: !disabled
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    opacity: enabled ? 1.0 : 0.45

    implicitHeight: size === "sm" ? Theme.controlHeightSm : size === "lg" ? Theme.controlHeightLg : Theme.controlHeight
    implicitWidth: Math.max(implicitHeight, contentItem.implicitWidth + leftPadding + rightPadding)
    leftPadding: text === "" ? 0 : (size === "lg" ? Theme.space5 : size === "sm" ? Theme.space2 + 2 : Theme.space3 + 2)
    rightPadding: leftPadding
    topPadding: 0
    bottomPadding: 0

    font.family: Theme.uiFontFamily
    font.pixelSize: size === "lg" ? 15 : Theme.fontSizeBody
    font.weight: Font.DemiBold

    Accessible.role: Accessible.Button
    Accessible.name: text !== "" ? text : tooltip_text

    readonly property string icon_variant_: primary_ ? Theme.iconOnAccent
                                          : danger_ ? Theme.iconDanger
                                          : Theme.iconDefault
    readonly property color text_color_: primary_ ? Theme.onAccent
                                       : danger_ ? Theme.danger
                                       : Theme.textPrimary

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: Math.max(label.implicitHeight, icon.height)

        Row {
            id: row
            x: control.align_left ? 0 : Math.round((parent.width - width) / 2)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space2

            SmlIcon {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                visible: control.icon_name !== ""
                name: control.icon_name
                size: control.size === "lg" ? Theme.iconSizeLarge
                    : control.size === "sm" ? Theme.iconSizeDense : Theme.iconSizeDefault
                variant: control.icon_variant_
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                visible: control.text !== ""
                textFormat: Text.PlainText
                text: control.text
                font: control.font
                color: control.text_color_
            }
        }
    }

    background: Rectangle {
        implicitWidth: control.implicitHeight
        implicitHeight: control.implicitHeight
        radius: control.size === "lg" ? Theme.radiusMd : Theme.radiusSm
        color: control.primary_ ? (control.down ? Theme.accentFillPressed
                                                : control.hovered ? Theme.accentFillHover : Theme.accentFill)
             : control.subtle_ ? Theme.sunken
             : control.ghost_ ? Theme.transparent
             : Theme.raised
        border.width: control.ghost_ || control.subtle_ ? 0 : 1
        border.color: control.primary_ ? Theme.accentBorder
                    : control.danger_ ? Theme.danger
                    : control.hovered ? Theme.brandGreen : Theme.borderStrong

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

        // Hover and press for the unfilled variants, as a veil over whatever fill they have
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !control.primary_
            color: control.danger_ ? (control.down ? Theme.alpha(Theme.danger, 0.2)
                                                   : control.hovered ? Theme.alpha(Theme.danger, 0.1) : Theme.transparent)
                 : control.down ? Theme.accentSubtleStrong
                 : control.hovered ? Theme.accentSubtle : Theme.transparent
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
    }

    // Pointing hand over an enabled button
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    SmlToolTip {
        visible: control.tooltip_text !== "" && control.hovered && !control.pressed
        text: control.tooltip_text
        delay: control.tooltip_delay
    }

    SmlFocusRing { shown: control.visualFocus }
}
