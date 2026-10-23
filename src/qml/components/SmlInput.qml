import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Text field: raised fill, 1 px outline (3:1 against the surface), 2 px outline in the
    focus colour while editing. Single-line fields centre their text; taller ones wrap
    from the top. A disabled field is sunken, with dimmed text.

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
    // Monospaced text, for paths and ids
    property bool monospace: false

    // Internal properties
    property bool __edited: false
    readonly property bool __multiline: height > Theme.controlHeightLg

    leftPadding: Theme.space3
    rightPadding: Theme.space3
    topPadding: __multiline ? Theme.space2 + 2 : 0
    bottomPadding: __multiline ? Theme.space2 + 2 : 0
    verticalAlignment: __multiline ? TextInput.AlignTop : TextInput.AlignVCenter
    font.family: monospace ? Theme.monoFontFamily : Theme.uiFontFamily
    font.pixelSize: Theme.fontSizeBody
    wrapMode: TextInput.WordWrap
    clip: true
    color: disabled ? Theme.textDisabled : Theme.textPrimary

    selectByMouse: true
    selectionColor: Theme.accentSubtleStrong
    selectedTextColor: Theme.textPrimary
    enabled: !disabled

    Rectangle
    {
        id: background

        anchors.fill: parent
        z: -1

        radius: Theme.radiusSm
        color: sustainml_custom_input.disabled ? Theme.sunken : Theme.raised
        border.width: sustainml_custom_input.__edited ? 2 : 1
        border.color: sustainml_custom_input.disabled ? Theme.border
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
            verticalAlignment: sustainml_custom_input.__multiline ? Text.AlignTop : Text.AlignVCenter
            text: sustainml_custom_input.placeholder_text
            textFormat: Text.PlainText
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeBody
            color: sustainml_custom_input.disabled ? Theme.textDisabled : Theme.textMuted
            elide: Text.ElideRight
            wrapMode: sustainml_custom_input.__multiline ? Text.WordWrap : Text.NoWrap
            visible: sustainml_custom_input.text === ""
        }

        MouseArea
        {
            id: hover_area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.IBeamCursor
        }
    }
    onFocusChanged: sustainml_custom_input.__edited = focus
    onActiveFocusChanged: sustainml_custom_input.__edited = activeFocus
}
