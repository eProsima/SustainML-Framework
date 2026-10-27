import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Section of a screen, straight on the page background (no box: framed panels are kept
    for the tabbed views, Results and U-Net graphs). With a title it gets a heading row
    (optional green icon tile, title, muted subtitle, actions on the right) over a 1 px
    divider; the children go into the content area below it, aligned with the heading.

    Usage:
        SmlCard {
            title: "Hugging Face suggestions"
            subtitle: "Query: ..."
            icon_name: "sparkles"
            actions: [ SmlButton { ... } ]
            Flickable { anchors.fill: parent; ... }
        }
 */
Item {
    id: card

    // External properties
    property string title: ""
    property string subtitle: ""
    property string icon_name: ""
    // Space between the heading and the content
    property int content_padding: Theme.space4
    property alias actions: actions_row.data
    default property alias content: content_item.data
    readonly property alias content_area: content_item

    implicitHeight: title_bar.height + content_item.childrenRect.height + content_padding

    // Heading
    Item {
        id: title_bar
        visible: card.title !== ""
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: visible ? Math.max(52, title_column.implicitHeight + 2 * Theme.space3) : 0

        Rectangle {
            id: icon_tile
            visible: card.icon_name !== ""
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 32
            height: 32
            radius: Theme.radiusMd
            color: Theme.accentFill

            SmlIcon {
                anchors.centerIn: parent
                name: card.icon_name
                size: Theme.iconSizeDefault + 2
                variant: Theme.iconOnAccent
            }
        }

        Column {
            id: title_column
            anchors {
                left: icon_tile.visible ? icon_tile.right : parent.left
                leftMargin: icon_tile.visible ? Theme.space3 : 0
                right: actions_row.left
                rightMargin: Theme.space3
                verticalCenter: parent.verticalCenter
            }
            spacing: 2

            Text {
                width: parent.width
                text: card.title
                textFormat: Text.PlainText
                font.family: Theme.uiFontFamily
                font.pixelSize: Theme.fontSizeCardTitle
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: card.subtitle !== ""
                text: card.subtitle
                textFormat: Text.PlainText
                font.family: Theme.uiFontFamily
                font.pixelSize: Theme.fontSizeMeta
                color: Theme.textMuted
                elide: Text.ElideRight
            }
        }

        Row {
            id: actions_row
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.space2
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.border
        }
    }

    Item {
        id: content_item
        anchors {
            top: title_bar.bottom
            topMargin: card.content_padding
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }
}
