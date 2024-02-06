import QtQuick 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

Text {
    id: sustainml_custom_text

    enum Text_kind
    {
        App_name,
        Header_1,
        Header_2,
        Header_3,
        Body
    }
    // External properties
    property int text_kind: SML_Text.Text_kind.Body // Body kind as default
    required property string text_value             // Required text introduced by the user

    // Internal properties, based on the input selection
    property string __font_family: sustainml_custom_text.text_kind === SML_Text.Text_kind.App_name ? SustainML_font.sustainml_font  :
                                   sustainml_custom_text.text_kind === SML_Text.Text_kind.Body     ? SustainML_font.body_font       :
                                                                                                     SustainML_font.title_font
    property string __font_size:   sustainml_custom_text.text_kind === SML_Text.Text_kind.App_name ? Settings.app_name_size         :
                                   sustainml_custom_text.text_kind === SML_Text.Text_kind.Header_1 ? Settings.header1_font_size     :
                                   sustainml_custom_text.text_kind === SML_Text.Text_kind.Header_2 ? Settings.header2_font_size     :
                                   sustainml_custom_text.text_kind === SML_Text.Text_kind.Header_3 ? Settings.header3_font_size     :
                                                                                                     Settings.body_font_size
    property string __font_color : sustainml_custom_text.text_kind === SML_Text.Text_kind.App_name ? Screen_manager.app_name_color  :
                                   sustainml_custom_text.text_kind === SML_Text.Text_kind.Body     ? Screen_manager.body_font_color :
                                                                                                     Screen_manager.title_font_color
    // Text components set up
    text: sustainml_custom_text.text_value
    font.bold: sustainml_custom_text.text_kind === SML_Text.Text_kind.App_name
    font.family: sustainml_custom_text.__font_family
    font.pixelSize: sustainml_custom_text.__font_size
    color: sustainml_custom_text.__font_color
}
