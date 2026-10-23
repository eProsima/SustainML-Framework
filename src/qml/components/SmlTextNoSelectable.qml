import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.Theme 1.0

/*
    Non-selectable text in the type roles of SmlText (labels inside controls).
 */
Text
{
    id: sustainml_custom_text

    enum TextKind
    {
        App_name,
        Header_1,
        Header_2,
        Header_3,
        Body
    }
    // External properties
    property int text_kind: SmlText.TextKind.Body   // Body kind as default
    required property string text_value             // Required text introduced by the user
    property bool force_elide: false
    property bool force_color: false
    property string forced_color: "black"
    property bool force_size: false
    property int forced_size: Theme.fontSizeBody
    // Internal properties, based on the input selection
    property string __font_family: sustainml_custom_text.text_kind === SmlText.TextKind.App_name ? SustainMLFont.sustainml_font
                                                                                                    : Theme.uiFontFamily
    property int __font_size:      sustainml_custom_text.text_kind === SmlText.TextKind.App_name ? Theme.fontSizeDisplay     :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Header_1 ? Theme.fontSizePageTitle   :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Header_2 ? Theme.fontSizeCardTitle   :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Header_3 ? Theme.fontSizeLabel       :
                                                                                                     Theme.fontSizeBody
    property color __font_color:   sustainml_custom_text.text_kind === SmlText.TextKind.App_name ? (Theme.darkMode ? Theme.brandLime : Theme.brandGreenDeep) :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Header_3 ? Theme.textSecondary :
                                                                                                     Theme.textPrimary

    // Text components set up
    text: sustainml_custom_text.force_elide ? elided_text.elidedText : sustainml_custom_text.text_value
    textFormat: Text.PlainText
    font.family: sustainml_custom_text.__font_family
    font.weight: sustainml_custom_text.text_kind === SmlText.TextKind.Body ? Font.Normal
               : sustainml_custom_text.text_kind === SmlText.TextKind.App_name ? Font.Bold : Font.DemiBold
    font.pixelSize: sustainml_custom_text.force_size ? sustainml_custom_text.forced_size : sustainml_custom_text.__font_size
    color: sustainml_custom_text.force_color ? sustainml_custom_text.forced_color : sustainml_custom_text.__font_color
    wrapMode: Text.WordWrap

    TextMetrics {
        id: elided_text
        font: sustainml_custom_text.font
        text: sustainml_custom_text.text_value
        elide: Text.ElideRight
        elideWidth: sustainml_custom_text.width - sustainml_custom_text.leftPadding - sustainml_custom_text.rightPadding
    }
}
