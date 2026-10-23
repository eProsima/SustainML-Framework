import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Drop-down choice in the style of SmlInput: raised fill, 1 px outline, 2 px focus
    outline while open, chevron indicator, and a rounded overlay popup with hover-tint
    rows and a check on the current value. searchable adds a filter field on top.
 */
ComboBox {
    id: sustainml_custom_combobox

    // External properties
    property string placeholder_text: ""
    property bool disabled: false
    property bool searchable: false

    enabled: !disabled

    // Internal properties
    property bool __edited: false
    property string __search_text: ""
    property bool __index_changed: false   // set by onCurrentIndexChanged, consumed by onActivated

    // External signal
    signal text_changed(string text)
    signal tab_pressed()
    currentIndex: -1

    SmlMouseArea
    {
        anchors.fill: parent
        enabled: !sustainml_custom_combobox.disabled  // Disable interaction when disabled is true
        onWheel: { } // do nothing to avoid changing values while scrolling with the mouse wheel
        onPressed:
        {
            if (!sustainml_custom_combobox.disabled)
                sustainml_custom_combobox.__edited = true;
        }
        onReleased:
        {
            if (!sustainml_custom_combobox.disabled)
                sustainml_custom_combobox.__edited = true;
        }
        onClicked:
        {
            if (!sustainml_custom_combobox.disabled)
            {
                sustainml_custom_combobox.popup.visible
                    ? sustainml_custom_combobox.close()
                    : sustainml_custom_combobox.open()
            }
        }
    }

    implicitHeight: Theme.controlHeight
    hoverEnabled: true
    font.family: Theme.uiFontFamily
    font.pixelSize: Theme.fontSizeBody

    // Custom placeholder field
    Text
    {
        id: placeholder_text
        text: sustainml_custom_combobox.placeholder_text
        textFormat: Text.PlainText
        anchors
        {
            left: sustainml_custom_combobox.left
            leftMargin: Theme.space3
            right: sustainml_custom_combobox.right
            rightMargin: Theme.space3 + Theme.iconSizeDefault + Theme.space2
            verticalCenter: sustainml_custom_combobox.verticalCenter
        }
        font: sustainml_custom_combobox.font
        color: sustainml_custom_combobox.disabled ? Theme.textDisabled : Theme.textMuted
        elide: Text.ElideRight
        visible: sustainml_custom_combobox.currentIndex === -1
    }
    onCurrentIndexChanged:
    {
        sustainml_custom_combobox.__index_changed = true
        sustainml_custom_combobox.text_changed(sustainml_custom_combobox.model[sustainml_custom_combobox.currentIndex])
        sustainml_custom_combobox.__edited = false
    }
    // A pick from the list must always reach the screen. When the screen changed the shown
    // value itself (e.g. restoring inputs), currentIndex can still point at the user's old
    // pick, so choosing that same item does not change the index and the handler above
    // never runs. Qt emits activated() after currentIndexChanged for every pick.
    onActivated:
    {
        if (!sustainml_custom_combobox.__index_changed)
            sustainml_custom_combobox.text_changed(sustainml_custom_combobox.model[index])
        sustainml_custom_combobox.__index_changed = false
    }

    // Combobox background
    background: Rectangle
    {
        id: background
        anchors.fill: parent
        radius: Theme.radiusSm
        color: sustainml_custom_combobox.disabled ? Theme.sunken : Theme.raised
        border.width: sustainml_custom_combobox.__edited || sustainml_custom_combobox.visualFocus ? 2 : 1
        border.color: sustainml_custom_combobox.disabled ? Theme.border
                    : sustainml_custom_combobox.__edited || sustainml_custom_combobox.visualFocus ? Theme.focusRing
                    : sustainml_custom_combobox.hovered ? Theme.brandGreen
                    : Theme.borderInput
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
    }

    // Combobox displayed text
    contentItem: Text
    {
        text: sustainml_custom_combobox.displayText
        textFormat: Text.PlainText
        font: sustainml_custom_combobox.font
        color: sustainml_custom_combobox.disabled ? Theme.textDisabled : Theme.textPrimary
        width: parent.width
        leftPadding: Theme.space3
        rightPadding: sustainml_custom_combobox.indicator.width + Theme.space3 + Theme.space2

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    // Combobox text shown in the popup
    delegate: ItemDelegate {
        id: item_delegate
        width: sustainml_custom_combobox.width - 2 * Theme.space1
        // The item, read from modelData here only: Qt 5.15 does not reliably resolve
        // modelData from custom properties or nested items of a delegate
        text: typeof modelData === "string" ? modelData : ""
        visible: !sustainml_custom_combobox.searchable ||
                 sustainml_custom_combobox.__search_text === "" ||
                 item_delegate.text.toLowerCase().indexOf(sustainml_custom_combobox.__search_text.toLowerCase()) !== -1
        height: visible ? Theme.controlHeightSm + 2 : 0
        leftPadding: Theme.space3
        rightPadding: Theme.space2
        topPadding: 0
        bottomPadding: 0
        hoverEnabled: true

        readonly property bool current_: item_delegate.text !== ""
                                         && item_delegate.text === sustainml_custom_combobox.displayText

        contentItem: Item {
            Text {
                anchors.left: parent.left
                anchors.right: check_icon.left
                anchors.rightMargin: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                text: item_delegate.text
                textFormat: Text.PlainText
                font.family: Theme.uiFontFamily
                font.pixelSize: Theme.fontSizeBody
                font.weight: item_delegate.current_ ? Font.DemiBold : Font.Normal
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            // A plain Image, not SmlIcon: an object with required properties inside a delegate
            // makes Qt 5.15 withhold the model context (modelData, index) from the whole delegate
            Image {
                id: check_icon
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSizeDense
                height: Theme.iconSizeDense
                sourceSize.width: Theme.iconSizeDense * 2
                sourceSize.height: Theme.iconSizeDense * 2
                source: "qrc:/images/icons/check/check_" + Theme.iconAccent + ".svg"
                visible: item_delegate.current_
            }
        }
        background: Rectangle {
            radius: Theme.radiusSm
            color: item_delegate.pressed ? Theme.accentSubtleStrong
                 : item_delegate.hovered || item_delegate.highlighted ? Theme.accentSubtle
                 : Theme.transparent
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
        y: sustainml_custom_combobox.height + Theme.space1
        width: sustainml_custom_combobox.width
        height: contentItem.implicitHeight + topPadding + bottomPadding
        padding: Theme.space1

        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFast } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFast } }

        onOpened: {
            sustainml_custom_combobox.__index_changed = false
            sustainml_custom_combobox.__search_text = ""
            if (sustainml_custom_combobox.searchable)
                popupSearchInput.forceActiveFocus()
        }
        onClosed: {
            sustainml_custom_combobox.__edited = false
            sustainml_custom_combobox.__search_text = ""
        }

        contentItem: Column {
            width: comboPopup.width - 2 * comboPopup.padding

            // Search field — only shown when searchable
            Rectangle {
                visible: sustainml_custom_combobox.searchable
                width: parent.width
                height: sustainml_custom_combobox.searchable ? Theme.controlHeightSm + 2 : 0
                radius: Theme.radiusSm
                color: Theme.sunken
                border.color: popupSearchInput.activeFocus ? Theme.focusRing : Theme.border
                border.width: 1

                SmlIcon {
                    id: search_icon
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space2
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: Theme.iconSizeDense
                    variant: Theme.iconMuted
                }

                TextInput {
                    id: popupSearchInput
                    anchors {
                        left: search_icon.right
                        right: parent.right
                        leftMargin: Theme.space2
                        rightMargin: Theme.space2
                        verticalCenter: parent.verticalCenter
                    }
                    height: font.pixelSize + 4
                    font.family: Theme.uiFontFamily
                    font.pixelSize: Theme.fontSizeBody
                    color: Theme.textPrimary
                    selectionColor: Theme.accentSubtleStrong
                    selectedTextColor: Theme.textPrimary
                    clip: true
                    onTextChanged: sustainml_custom_combobox.__search_text = text
                    KeyNavigation.down: listView

                    Text {
                        anchors.fill: parent
                        text: "Filter..."
                        textFormat: Text.PlainText
                        color: Theme.textMuted
                        font: popupSearchInput.font
                        visible: popupSearchInput.text === ""
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            ListView {
                id:listView
                width: parent.width
                interactive: true
                clip: true
                // Cap to ~8 rows before scrolling - a long result list (e.g. HF model
                // search) would otherwise size the popup to fit every item at once.
                implicitHeight: Math.min(contentHeight, (Theme.controlHeightSm + 2) * 8)
                model: sustainml_custom_combobox.popup.visible ? sustainml_custom_combobox.delegateModel : null

                // Not only spacing: the list's height follows its contentHeight, so without this
                // margin an empty list starts 0 px tall and never creates its first row
                bottomMargin: Theme.space1

                ScrollBar.vertical: SmlScrollBar {
                    policy: listView.contentHeight > listView.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }
        }

        background: Rectangle {
            radius: Theme.radiusMd
            color: Theme.overlay
            border.color: Theme.borderStrong
            border.width: 1

            // Soft drop shadow
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: -3
                radius: parent.radius
                color: Theme.shadow
            }
        }
    }

    // Combobox indicator
    indicator: SmlIcon {
        id: icon
        name: "down"
        size: Theme.iconSizeDefault
        variant: sustainml_custom_combobox.disabled ? Theme.iconMuted : Theme.iconDefault
        rotation: sustainml_custom_combobox.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: Theme.durFast } }

        anchors
        {
            right: parent.right
            rightMargin: Theme.space3
            verticalCenter: parent.verticalCenter
        }
    }
    Keys.onPressed: (event)=> {
        if (event.key == Qt.Key_Tab) {
            sustainml_custom_combobox.close();
            event.accepted = true;

        } else if (event.key == Qt.Key_Up) {
            if (currentIndex > 0)
            {
                currentIndex--;
            }
            else
            {
                currentIndex = count - 1;
            }
            event.accepted = true;

        } else if (event.key == Qt.Key_Down) {
            if (currentIndex < count - 1)
            {
                currentIndex++;
            }
            else
            {
                currentIndex = 0;
            }
            event.accepted = true;

        } else if (popup.visible && event.text.length > 0) {
            var letter = event.text;
            for (var i = 0; i < count; i++) {
                var itemText = model[i];
                if (typeof(itemText) === "string" && itemText.indexOf(letter) === 0) {
                    // currentIndex = i;
                    popup.contentItem.positionViewAtIndex(i, ListView.Beginning);
                    break;
                }
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
