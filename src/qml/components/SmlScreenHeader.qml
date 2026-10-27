import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    Top bar of every screen: the navigation buttons (Home as a labelled button, Back as
    an outlined icon button), the screen title and subtitle, and the screen's actions on the right. The far right
    is left free for the Node status (gear) button that main.qml keeps on top of every
    screen.

    Usage:
        SmlScreenHeader {
            id: header
            title: "Results"
            subtitle: "Problems and iterations evaluated"
            navigation: [ SmlButton { icon_name: "home"; text_value: "Home"; ... },
                          SmlIconButton { icon_name: "back"; outlined: true; ... } ]
            actions: [ SmlButton { ... }, SmlButton { ... } ]
        }
 */
Rectangle {
    id: header

    // External properties
    property string title: ""
    property string subtitle: ""
    property alias navigation: navigation_row.data
    property alias actions: actions_row.data
    // Room kept free on the right for the global Node status button
    property int reserved_right: Theme.controlHeight + Theme.space4 + Theme.space3

    anchors { top: parent.top; left: parent.left; right: parent.right }
    height: Theme.headerHeight
    color: Theme.headerTint

    Row {
        id: navigation_row
        anchors { left: parent.left; leftMargin: navigation_row.children.length > 0 ? Theme.pagePadding : 0; verticalCenter: parent.verticalCenter }
        spacing: Theme.space2
    }

    Column {
        id: title_column
        anchors {
            left: navigation_row.right
            leftMargin: navigation_row.children.length > 0 ? Theme.space4 : Theme.pagePadding
            right: actions_row.left
            rightMargin: Theme.space4
            verticalCenter: parent.verticalCenter
        }
        spacing: 1

        Text {
            width: parent.width
            text: header.title
            textFormat: Text.PlainText
            font.family: Theme.uiFontFamily
            font.pixelSize: 17
            font.weight: Font.DemiBold
            font.letterSpacing: -0.2
            color: Theme.textPrimary
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: header.subtitle !== ""
            text: header.subtitle
            textFormat: Text.PlainText
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeMeta
            color: Theme.textMuted
            elide: Text.ElideRight
        }
    }

    Row {
        id: actions_row
        anchors { right: parent.right; rightMargin: header.reserved_right; verticalCenter: parent.verticalCenter }
        spacing: Theme.space2
    }

    // Bottom edge: a SustainML green line across the whole bar
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 3
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.brandGreen }
            GradientStop { position: 0.5; color: Theme.brandGreenBright }
            GradientStop { position: 1.0; color: Theme.brandGreen }
        }
    }
}
