import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Label of a form field, above it: 13 px DemiBold in the secondary text colour, in the
    accent colour while its field is being edited.

    Usage:
        SmlFieldLabel { text: "Problem definition"; active: problem_definition_input.focus }
 */
Text {
    property bool active: false

    textFormat: Text.PlainText
    font.family: Theme.uiFontFamily
    font.pixelSize: Theme.fontSizeLabel
    font.weight: Font.DemiBold
    color: active ? Theme.accentText : Theme.textSecondary
    elide: Text.ElideRight
    bottomPadding: Theme.space1 + 2
    Behavior on color { ColorAnimation { duration: Theme.durFast } }
}
