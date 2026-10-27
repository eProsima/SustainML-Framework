// Library imports
import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Message dialog: a title, a message and an OK button.

    Usage:
        SmlDialog { id: error_dialog; placeholder_text: "Error"; tone: "danger"; text_value: message }
 */
SmlModal {
    id: notSupportDialog

    // External properties
    property string placeholder_text: "Warning"
    required property string text_value

    title: placeholder_text
    icon_name: tone === "danger" ? "error" : tone === "info" ? "info" : "warning"
    tone: "warning"
    standardButtons: Dialog.Ok

    Text {
        width: notSupportDialog.availableWidth
        text: notSupportDialog.text_value
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        font.family: Theme.uiFontFamily
        font.pixelSize: Theme.fontSizeBody
        lineHeight: 1.3
        color: Theme.textSecondary
    }
}
