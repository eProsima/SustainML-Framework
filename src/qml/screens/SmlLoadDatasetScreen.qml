// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15


// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"

Item
{
    id:root

    property alias dataset_path_text: dataset_path_input.text

    // Public signals
    signal go_home();
    signal go_back();

    // Internal properties
    readonly property int __input_height: 38

    property bool tasking: false

    signal send_dataset_path_task();

    // Background mouse area
    MouseArea
    {
        anchors.fill: parent
        onClicked: focus = true
    }

    SmlScreenHeader
    {
        id: header
        title: "Dataset selector"
        subtitle: "Upload a dataset to fill in its metadata automatically"
        navigation: [
            // Go home button
            SmlButton
            {
                id: go_home_button
                icon_name: Settings.home_icon_name
                text_value: "Home"
                tooltip_text: "Go to Home screen"
                onClicked: root.go_home()
            },
            // Go back button
            SmlIconButton
            {
                id: go_back_button
                outlined: true
                icon_name: Settings.back_icon_name
                tooltip_text: "Go to Problem Definition screen"
                onClicked: root.go_back()
            }
        ]
    }

    SmlCard
    {
        id: dataset_card
        anchors
        {
            top: header.bottom
            topMargin: Theme.space6
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(parent.width - 2 * Theme.pagePadding, 760)
        title: "Dataset file"
        subtitle: "CSV or JSON file with the data the model will work with"
        icon_name: "database"

        Column
        {
            width: dataset_card.content_area.width
            spacing: Theme.space5

            // What happens with the dataset: plain help text, not a control
            Row
            {
                width: parent.width
                spacing: Theme.space3

                SmlIcon
                {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "info"
                    size: Theme.iconSizeLarge
                    variant: Theme.iconMuted
                }

                Text
                {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.iconSizeLarge - parent.spacing
                    text: "Choose a dataset file with Browse. Its description, topic, keywords, applications and profile are extracted and filled in on the problem definition."
                    textFormat: Text.PlainText
                    font.family: Theme.uiFontFamily
                    font.pixelSize: Theme.fontSizeBody
                    lineHeight: 1.3
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            Column
            {
                width: parent.width

                SmlFieldLabel { text: "Dataset path"; width: parent.width }

                Row
                {
                    width: parent.width
                    spacing: Theme.space2

                    SmlInput {
                        id: dataset_path_input
                        height: root.__input_height
                        width: parent.width - browse_button.width - parent.spacing
                        placeholder_text: "Select a dataset file..."
                        monospace: text !== ""
                        disabled: true
                    }

                    SmlButton {
                        id: browse_button
                        variant: "primary"
                        icon_name: Settings.browse_icon_name
                        text_value: "Browse"
                        tooltip_text: "Browse for a dataset file"
                        onClicked: dataset_file_dialog_loader.active = true
                        height: root.__input_height
                    }
                }
            }

            // Tasking status
            Rectangle
            {
                id: tasking_status
                visible: root.tasking
                width: parent.width
                height: 48
                radius: Theme.radiusMd
                color: Theme.accentSubtle

                Row
                {
                    anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                    spacing: Theme.space3

                    // Tasking status icon
                    SmlGrowingLoader
                    {
                        id: tasking_status_icon
                        anchors.verticalCenter: parent.verticalCenter
                        size: Theme.iconSizeLarge
                        running: root.tasking
                    }

                    // Tasking status text
                    Text
                    {
                        id: tasking_status_text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Extracting metadata, please wait"
                        textFormat: Text.PlainText
                        font.family: Theme.uiFontFamily
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.DemiBold
                        color: Theme.accentText
                    }
                }
            }
        }
    }

    // Loaded on demand (only once Browse is clicked) rather than declared
    // directly: QtQuick.Dialogs 1.x's fallback (non-native) FileDialog has a
    // known, harmless internal binding-loop warning in its own bundled QML
    // (DefaultFileDialog.qml's toolbar buttons) that fires as soon as it's
    // constructed - a permanent child here would trigger it the instant this
    // screen loads, before the user ever opens the dialog.
    Loader {
        id: dataset_file_dialog_loader
        active: false

        sourceComponent: FileDialog {
            title: "Select Dataset"
            selectFolder: false
            nameFilters: ["CSV Files (*.csv)", "JSON Files (*.json)", "All Files (*)"]
            Component.onCompleted: open()
            onAccepted: {
                const file = fileUrl.toString();
                dataset_path_input.text = file
                engine.launch_dataset_path_task(file)
                root.send_dataset_path_task();
                dataset_file_dialog_loader.active = false
            }
            onRejected: dataset_file_dialog_loader.active = false
        }
    }
}
