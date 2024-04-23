import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Styles 1.4


// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

Item {
    id: sustainml_custom_combobox

    // External properties
    required property var model
    property int rounded_radius: 0 //Settings.input_default_rounded_radius
    property int border_width: Settings.input_default_border_width
    property string background_color: ""
    property string background_nightmode_color: ""
    property string border_color: ""
    property string border_editting_color: ""
    property string border_nightmode_color: ""
    property string border_nightmode_editting_color: ""
    property string placeholder_text: ""

    // Internal properties
    property bool __edited: false

    // External signal
    signal text_changed(string text)

    ComboBox
    {
        id: combobox
        anchors.fill: parent
        model: sustainml_custom_combobox.model
        currentIndex: -1

        MouseArea
        {
            anchors.fill: parent
            onWheel: { } // do nothing to avoid changing values while scrolling with the mouse wheel
            onPressed: { mouse.accepted = false; sustainml_custom_combobox.__edited = true; }
            onReleased: { mouse.accepted = false; sustainml_custom_combobox.__edited = true; }
        }

        // Custom placeholder field
        SmlText
        {
            id: placeholder_text
            text: sustainml_custom_combobox.placeholder_text

            anchors
            {
                top: combobox.top
                topMargin: Settings.spacing_normal
                left: combobox.left
                leftMargin: Settings.spacing_normal
            }

            width: sustainml_custom_combobox.width - 2 * Settings.spacing_normal

            force_color: true
            forced_color: "#aaa"
            visible: combobox.currentIndex === -1
        }
        onCurrentIndexChanged:
        {
            sustainml_custom_combobox.text_changed(combobox.currentText)
            sustainml_custom_combobox.__edited = false
        }

        // Combobox background
        background: Rectangle
        {
            id: background
            anchors.fill: parent
            radius: sustainml_custom_combobox.rounded_radius
            color: ScreenManager.night_mode
                    ? sustainml_custom_combobox.background_nightmode_color
                    : sustainml_custom_combobox.background_color
            border.color: ScreenManager.night_mode ? sustainml_custom_combobox.__edited
                        ? sustainml_custom_combobox.border_nightmode_editting_color
                        : sustainml_custom_combobox.border_nightmode_color
                    : sustainml_custom_combobox.__edited
                        ? sustainml_custom_combobox.border_editting_color
                        : sustainml_custom_combobox.border_color
            border.width: sustainml_custom_combobox.border_width
        }

        // Combobox displayed text
        contentItem: SmlText {
            text_value: combobox.displayText
            text_kind: SmlText.TextKind.Body

            leftPadding: Settings.spacing_normal
            rightPadding: combobox.indicator.width + combobox.spacing
            topPadding: Settings.spacing_normal
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
        }

        // Combobox text shown in the popup
        delegate: ItemDelegate {
            id: item_delegate
            width: combobox.width
            height: combobox.height * 0.75

            contentItem: Rectangle{
                width: parent.implicitWidth
                height: item_delegate.height
                color: "transparent"

                SmlText {
                    text_value: modelData
                    text_kind: SmlText.TextKind.Body

                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight

                    forced_color: ScreenManager.night_mode
                                    ? sustainml_custom_combobox.border_nightmode_editting_color
                                    : sustainml_custom_combobox.border_editting_color
                    force_color: item_delegate.hovered
                }
            }
            background: Rectangle {
                color: "transparent"
            }
        }

        // Combobox selection popup
        popup: Popup {
            id:comboPopup
            y: combobox.height - 1
            width: combobox.width
            height:contentItem.implicitHeigh
            padding: 10

            contentItem: ListView {
                id:listView
                implicitHeight: contentHeight
                model: combobox.popup.visible ? combobox.delegateModel : null

            ScrollIndicator.vertical: ScrollIndicator { }
            }

            background: Rectangle {
                radius: sustainml_custom_combobox.rounded_radius
                color: ScreenManager.night_mode
                        ? sustainml_custom_combobox.background_nightmode_color
                        : sustainml_custom_combobox.background_color
                border.color: ScreenManager.night_mode
                            ? sustainml_custom_combobox.border_nightmode_editting_color
                            : sustainml_custom_combobox.border_editting_color
                border.width: sustainml_custom_combobox.border_width
            }
            onClosed: sustainml_custom_combobox.__edited = false;
        }

        // Combobox indicator
        indicator: SmlIcon {
            id: icon
            name: Settings.arrow_down_icon_name
            size: Settings.spacing_normal 
            color: sustainml_custom_combobox.__edited
                    ? sustainml_custom_combobox.border_editting_color
                    : sustainml_custom_combobox.border_color
            nightmode_color: sustainml_custom_combobox.__edited
                    ? sustainml_custom_combobox.border_nightmode_editting_color
                    : sustainml_custom_combobox.border_nightmode_color
            color_pressed: sustainml_custom_combobox.border_editting_color
            nightmode_color_pressed: sustainml_custom_combobox.border_nightmode_editting_color

            anchors
            {
                right: parent.right
                rightMargin: Settings.spacing_normal
                verticalCenter: parent.verticalCenter
            }
        }
    }
}
