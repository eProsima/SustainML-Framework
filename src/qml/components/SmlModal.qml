import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Every dialog of the application. A drop-in Dialog that:

      - centres itself on the window and dims the rest with Theme.scrim
      - draws an overlay card (radiusLg) with a header: optional icon tile in the tone
        colour, title, optional subtitle and a close button
      - shows standardButtons as SmlButtons in an SmlDialogButtonBox footer (the
        accepting one primary); declare a footer of your own for custom buttons

    Usage:
        SmlModal {
            title: "Clear saved data"
            icon_name: "trash"
            tone: "danger"
            standardButtons: Dialog.Yes | Dialog.No
            SmlText { text_value: "..." }
            onAccepted: ...
        }
 */
Dialog {
    id: control

    // External properties
    property string subtitle: ""
    property string icon_name: ""
    // "accent" (default), "info", "warning", "danger" or "success": colour of the icon tile
    property string tone: "accent"
    property bool show_close: true
    property int dialog_width: 440

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    focus: true
    width: Math.min(dialog_width, (parent ? parent.width : dialog_width) - 2 * Theme.space6)
    padding: Theme.space5
    topPadding: Theme.space2
    bottomPadding: Theme.space5

    font.family: Theme.uiFontFamily
    font.pixelSize: Theme.fontSizeBody

    readonly property string tone_icon_variant_: tone === "danger" ? Theme.iconDanger
                                               : tone === "warning" ? Theme.iconWarning
                                               : tone === "success" ? Theme.iconSuccess
                                               : Theme.iconAccent
    readonly property color tone_color_: tone === "accent" ? Theme.brandGreen : Theme.toneColor(tone)

    Overlay.modal: Rectangle {
        color: Theme.scrim
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durEnter; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: Theme.durEnter; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durExit; easing.type: Easing.InCubic }
    }

    background: Rectangle {
        radius: Theme.radiusLg
        color: Theme.overlay
        border.width: 1
        border.color: Theme.darkMode ? Theme.borderStrong : Theme.border

        // Soft drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.margins: -1
            anchors.topMargin: 4
            anchors.bottomMargin: -6
            radius: parent.radius + 1
            color: Theme.shadow
        }
    }

    header: Item {
        implicitHeight: header_row.implicitHeight + Theme.space5 + Theme.space3

        Row {
            id: header_row
            anchors.left: parent.left
            anchors.leftMargin: Theme.space5
            anchors.right: close_button.left
            anchors.rightMargin: Theme.space2
            anchors.top: parent.top
            anchors.topMargin: Theme.space5
            spacing: Theme.space3

            // Icon tile in the tone colour
            Rectangle {
                visible: control.icon_name !== ""
                width: 36
                height: 36
                radius: Theme.radiusMd
                color: Theme.alpha(control.tone_color_, Theme.darkMode ? 0.18 : 0.12)

                SmlIcon {
                    anchors.centerIn: parent
                    name: control.icon_name
                    size: Theme.iconSizeLarge
                    variant: control.tone_icon_variant_
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: header_row.width - (control.icon_name !== "" ? 36 + header_row.spacing : 0)
                spacing: 2

                Text {
                    width: parent.width
                    text: control.title
                    textFormat: Text.PlainText
                    font.family: Theme.uiFontFamily
                    font.pixelSize: Theme.fontSizeDialogTitle
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    visible: control.subtitle !== ""
                    text: control.subtitle
                    textFormat: Text.PlainText
                    font.family: Theme.uiFontFamily
                    font.pixelSize: Theme.fontSizeMeta
                    color: Theme.textMuted
                    wrapMode: Text.WordWrap
                }
            }
        }

        SmlIconButton {
            id: close_button
            visible: control.show_close
            anchors.right: parent.right
            anchors.rightMargin: Theme.space3
            anchors.top: parent.top
            anchors.topMargin: Theme.space3
            button_size: Theme.controlHeightSm
            icon_name: "cross"
            icon_variant: Theme.iconMuted
            tooltip_text: "Close"
            onClicked: control.reject()
        }
    }

    footer: SmlDialogButtonBox { }
}
