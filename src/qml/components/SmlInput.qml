import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Single-line text field: raised fill, 1 px outline (3:1 against the surface), 2 px outline
    in the focus colour while editing. For text that may need several lines (Enter starting
    a new one) use SmlTextArea. A disabled field is sunken, with dimmed text. A read-only field only shows its value: sunken, full-contrast text, no
    placeholder, no interaction.

    Usage:
        SmlInput {
            placeholder_text: "Briefly describe the objective of the problem"
            height: Theme.controlHeight
            onTextChanged: ...
        }
 */
TextInput {
    id: sustainml_custom_input

    // External properties
    property string placeholder_text: ""
    property bool disabled: false
    property bool read_only: false
    // Monospaced text, for paths and ids
    property bool monospace: false

    // Internal properties
    property bool __edited: false

    leftPadding: Theme.space3
    rightPadding: Theme.space3
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: TextInput.AlignVCenter
    font.family: monospace ? Theme.monoFontFamily : Theme.uiFontFamily
    font.pixelSize: Theme.fontSizeBody
    wrapMode: TextInput.WordWrap
    clip: true
    color: !read_only && disabled ? Theme.textDisabled : Theme.textPrimary

    selectByMouse: true
    selectionColor: Theme.accentSubtleStrong
    selectedTextColor: Theme.textPrimary
    enabled: !disabled && !read_only

    Rectangle
    {
        id: background

        anchors.fill: parent
        z: -1

        radius: Theme.radiusSm
        color: sustainml_custom_input.disabled || sustainml_custom_input.read_only ? Theme.sunken : Theme.raised
        border.width: sustainml_custom_input.__edited ? 2 : 1
        border.color: sustainml_custom_input.disabled || sustainml_custom_input.read_only ? Theme.border
                    : sustainml_custom_input.__edited ? Theme.focusRing
                    : hover_area.containsMouse ? Theme.brandGreen
                    : Theme.borderInput
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

        // Placeholder, shown while the field is empty
        Text
        {
            id: placeholder_text
            anchors.fill: parent
            leftPadding: sustainml_custom_input.leftPadding
            rightPadding: sustainml_custom_input.rightPadding
            topPadding: sustainml_custom_input.topPadding
            bottomPadding: sustainml_custom_input.bottomPadding
            verticalAlignment: Text.AlignVCenter
            text: sustainml_custom_input.placeholder_text
            textFormat: Text.PlainText
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeBody
            color: sustainml_custom_input.disabled ? Theme.textDisabled : Theme.textMuted
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            visible: sustainml_custom_input.text === "" && !sustainml_custom_input.read_only
        }

        MouseArea
        {
            id: hover_area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: sustainml_custom_input.read_only ? Qt.ArrowCursor : Qt.IBeamCursor
        }
    }
    onFocusChanged: sustainml_custom_input.__edited = focus
    onActiveFocusChanged: sustainml_custom_input.__edited = activeFocus
}
