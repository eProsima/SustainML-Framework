import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    What an empty list or view shows instead of blank space: a sprout in a soft green
    circle, a short title and a hint at how to fill it.

    Usage:
        SmlEmptyState { anchors.centerIn: parent; title: "No saved searches yet"; hint: "..." }
 */
Column {
    id: empty_state

    property string title: ""
    property string hint: ""
    property string icon_name: "sprout"
    // Waiting for something: the sprout grows instead of standing still
    property bool busy: false

    width: Math.min(420, parent ? parent.width - 2 * Theme.space5 : 420)
    spacing: Theme.space2

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 56
        height: 56
        radius: 28
        color: Theme.accentSubtle

        SmlIcon {
            anchors.centerIn: parent
            visible: !empty_state.busy
            name: empty_state.icon_name
            size: Theme.iconSizeXLarge + 4
            variant: Theme.iconAccent
        }

        SmlGrowingLoader {
            anchors.centerIn: parent
            visible: empty_state.busy
            running: empty_state.busy
            size: Theme.iconSizeXLarge + 4
        }
    }

    Item { width: 1; height: Theme.space1 }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: empty_state.title
        textFormat: Text.PlainText
        font.family: Theme.uiFontFamily
        font.pixelSize: Theme.fontSizeCardTitle
        font.weight: Font.DemiBold
        color: Theme.textPrimary
        wrapMode: Text.WordWrap
    }

    Text {
        width: parent.width
        visible: empty_state.hint !== ""
        horizontalAlignment: Text.AlignHCenter
        text: empty_state.hint
        textFormat: Text.PlainText
        font.family: Theme.uiFontFamily
        font.pixelSize: Theme.fontSizeBody
        lineHeight: 1.3
        color: Theme.textMuted
        wrapMode: Text.WordWrap
    }
}
