import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

Text {
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

    // Internal properties, based on the input selection
    property string __font_family: sustainml_custom_text.text_kind === SmlText.TextKind.App_name ? SustainMLFont.sustainml_font  :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Body     ? SustainMLFont.body_font       :
                                                                                                     SustainMLFont.title_font
    property string __font_size:   sustainml_custom_text.text_kind === SmlText.TextKind.App_name ? Settings.app_name_size         :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Header_1 ? Settings.header1_font_size     :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Header_2 ? Settings.header2_font_size     :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Header_3 ? Settings.header3_font_size     :
                                                                                                     Settings.body_font_size
    property string __font_color : sustainml_custom_text.text_kind === SmlText.TextKind.App_name ? ScreenManager.app_name_color  :
                                   sustainml_custom_text.text_kind === SmlText.TextKind.Body     ? ScreenManager.body_font_color :
                                                                                                     ScreenManager.title_font_color
    // Text components set up
    text: sustainml_custom_text.text_value
    font.bold: sustainml_custom_text.text_kind === SmlText.TextKind.App_name
    font.family: sustainml_custom_text.__font_family
    font.pixelSize: sustainml_custom_text.__font_size
    color: sustainml_custom_text.__font_color
}
