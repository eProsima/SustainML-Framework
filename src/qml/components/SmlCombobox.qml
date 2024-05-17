import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Styles 1.4


// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

ComboBox {
    id: sustainml_custom_combobox

    // External properties
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
    signal tab_pressed()
    currentIndex: -1

    SmlMouseArea
    {
        anchors.fill: parent
        onWheel: { } // do nothing to avoid changing values while scrolling with the mouse wheel
        onPressed: { mouse.accepted = false; sustainml_custom_combobox.__edited = true; }
        onReleased: { mouse.accepted = false; sustainml_custom_combobox.__edited = true; }
    }

    // Custom placeholder field
    SmlTextNoSelectable
    {
        id: placeholder_text
        text_value: sustainml_custom_combobox.placeholder_text

        anchors
        {
            top: sustainml_custom_combobox.top
            topMargin: Settings.spacing_normal
            left: sustainml_custom_combobox.left
            leftMargin: Settings.spacing_normal
        }

        width: sustainml_custom_combobox.width - 2 * Settings.spacing_normal
        force_color: true
        forced_color: "#aaa"
        visible: sustainml_custom_combobox.currentIndex === -1
    }
    onCurrentIndexChanged:
    {
        sustainml_custom_combobox.text_changed(sustainml_custom_combobox.currentText)
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
    contentItem: SmlTextNoSelectable
    {
        text_value: sustainml_custom_combobox.displayText
        text_kind: SmlText.TextKind.Body
        width: parent.width
        leftPadding: Settings.spacing_normal
        rightPadding: sustainml_custom_combobox.indicator.width + sustainml_custom_combobox.spacing
        topPadding: Settings.spacing_normal
        horizontalAlignment: Text.AlignLeft
        force_elide: true
    }

    // Combobox text shown in the popup
    delegate: ItemDelegate {
        id: item_delegate
        width: sustainml_custom_combobox.width
        height: sustainml_custom_combobox.height * 0.75

        contentItem: Rectangle{
            width: parent.implicitWidth
            height: item_delegate.height
            color: "transparent"

            SmlTextNoSelectable {
                text_value: modelData
                text_kind: SmlText.TextKind.Body

                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                width: parent.width
                force_elide: true
                forced_color: ScreenManager.night_mode
                                ? sustainml_custom_combobox.border_nightmode_editting_color
                                : sustainml_custom_combobox.border_editting_color
                force_color: item_delegate.hovered
            }
        }
        background: Rectangle {
            color: "transparent"
        }

        // Cursor shaped Mouse Area that propagates events to the parent
        SmlMouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onPressed:  { mouse.accepted = false; }
            onReleased: { mouse.accepted = false; }
            onPressAndHold: { mouse.accepted = false; }
            onClicked: { mouse.accepted = false; }
            onDoubleClicked: { mouse.accepted = false; }
        }
    }

    // Combobox selection popup
    popup: Popup {
        id:comboPopup
        y: sustainml_custom_combobox.height - 1
        width: sustainml_custom_combobox.width
        height:contentItem.implicitHeigh
        padding: 10

        contentItem: ListView {
            id:listView
            implicitHeight: contentHeight
            model: sustainml_custom_combobox.popup.visible ? sustainml_custom_combobox.delegateModel : null

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
    Keys.onPressed: (event)=> {
        if (event.key == Qt.Key_Tab) {
            sustainml_custom_combobox.close();
            event.accepted = true;
        }
        else if (event.key == Qt.Key_Up) {
            if (currentIndex > 0)
            {
                currentIndex--;
            }
            else
            {
                currentIndex = count - 1;
            }
            event.accepted = true;
        }else if (event.key == Qt.Key_Down) {
            if (currentIndex < count - 1)
            {
                currentIndex++;
            }
            else
            {
                currentIndex = 0;
            }
            event.accepted = true;
        }
    }

    function open()
    {
        sustainml_custom_combobox.__edited = true
        sustainml_custom_combobox.popup.open()
    }
    function  close()
    {
        sustainml_custom_combobox.__edited = false
        sustainml_custom_combobox.popup.close()
        sustainml_custom_combobox.tab_pressed()
    }
}
