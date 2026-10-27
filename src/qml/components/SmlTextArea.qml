import QtQuick 2.15
import QtQuick.Controls 2.15

import eProsima.SustainML.Theme 1.0

/*
    Multi-line text field, in the style of SmlInput: Enter starts a new line, the text wraps,
    and it scrolls inside the field (wheel, scroll bar, or following the cursor) once it no
    longer fits. Tab and Shift+Tab move to the next / previous field (KeyNavigation set on
    this item), as in a single-line field. A disabled field is sunken, with dimmed text. A
    read-only field only shows its value: sunken, full-contrast text, no placeholder, no
    interaction. Neither scrolls nor takes focus, as in SmlInput; content_height lets the
    screen grow a read-only field to show all its text.

    Usage:
        SmlTextArea {
            placeholder_text: "Define the machine learning problem"
            height: 104
            onTextChanged: ...
        }
 */
FocusScope {
    id: sustainml_text_area

    // External properties
    property alias text: edit.text
    property string placeholder_text: ""
    property bool disabled: false
    property bool read_only: false

    // Text changed by the user (typing), not by the screen setting text (as TextInput.textEdited)
    signal textEdited()

    // Height that shows the whole text without scrolling
    readonly property real content_height: edit.implicitHeight + 2 * flick.anchors.margins

    readonly property bool __edited: edit.activeFocus

    enabled: !disabled && !read_only

    Rectangle
    {
        id: background

        anchors.fill: parent

        radius: Theme.radiusSm
        color: sustainml_text_area.disabled || sustainml_text_area.read_only ? Theme.sunken : Theme.raised
        border.width: sustainml_text_area.__edited ? 2 : 1
        border.color: sustainml_text_area.disabled || sustainml_text_area.read_only ? Theme.border
                    : sustainml_text_area.__edited ? Theme.focusRing
                    : hover_area.containsMouse ? Theme.brandGreen
                    : Theme.borderInput
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
    }

    Flickable
    {
        id: flick

        anchors.fill: parent
        anchors.margins: 2      // inside the (focus) outline
        contentWidth: width
        contentHeight: edit.height
        clip: true
        // Scrolled by the wheel area below and the scroll bar, so dragging selects text
        interactive: false
        boundsBehavior: Flickable.StopAtBounds

        readonly property bool overflows_: contentHeight > height + 1

        // Keep the cursor in view while typing or moving it with the keys
        function ensure_visible(rect)
        {
            if (contentY >= rect.y)
                contentY = rect.y
            else if (contentY + height <= rect.y + rect.height)
                contentY = rect.y + rect.height - height
        }

        ScrollBar.vertical: SmlScrollBar { policy: ScrollBar.AsNeeded }

        TextEdit
        {
            id: edit

            focus: true
            width: flick.width
            height: Math.max(implicitHeight, flick.height)
            leftPadding: Theme.space3 - 2
            rightPadding: Theme.space3 + Theme.space1
            topPadding: Theme.space2
            bottomPadding: Theme.space2
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeBody
            color: !sustainml_text_area.read_only && sustainml_text_area.disabled ? Theme.textDisabled : Theme.textPrimary
            selectByMouse: true
            selectionColor: Theme.accentSubtleStrong
            selectedTextColor: Theme.textPrimary

            onCursorRectangleChanged: if (activeFocus) flick.ensure_visible(cursorRectangle)
            onTextChanged: if (activeFocus) sustainml_text_area.textEdited()

            // Tab moves between fields instead of inserting a tab character
            Keys.onTabPressed: (event) => {
                var next = sustainml_text_area.KeyNavigation.tab || edit.nextItemInFocusChain(true)
                if (next)
                    next.forceActiveFocus(Qt.TabFocusReason)
                event.accepted = true
            }
            Keys.onBacktabPressed: (event) => {
                var previous = sustainml_text_area.KeyNavigation.backtab || sustainml_text_area.nextItemInFocusChain(false)
                if (previous)
                    previous.forceActiveFocus(Qt.BacktabFocusReason)
                event.accepted = true
            }

            // Placeholder, shown while the field is empty
            Text
            {
                anchors.fill: parent
                leftPadding: edit.leftPadding
                rightPadding: edit.rightPadding
                topPadding: edit.topPadding
                bottomPadding: edit.bottomPadding
                text: sustainml_text_area.placeholder_text
                textFormat: Text.PlainText
                font: edit.font
                color: sustainml_text_area.disabled ? Theme.textDisabled : Theme.textMuted
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                visible: edit.text === "" && !sustainml_text_area.read_only
            }
        }
    }

    // Hover outline and I-beam cursor; the wheel scrolls the text only while it overflows,
    // otherwise it goes on to scroll the page
    MouseArea
    {
        id: hover_area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: sustainml_text_area.read_only ? Qt.ArrowCursor : Qt.IBeamCursor
        onWheel: (wheel) => {
            if (!flick.overflows_)
            {
                wheel.accepted = false
                return
            }
            var max_y = flick.contentHeight - flick.height
            var y = Math.max(0, Math.min(max_y, flick.contentY - wheel.angleDelta.y / 2))
            wheel.accepted = y !== flick.contentY
            flick.contentY = y
        }
    }
}
