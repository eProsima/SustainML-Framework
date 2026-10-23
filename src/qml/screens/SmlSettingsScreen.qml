// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"

Item
{
    id: root

    // External properties
    property string log: ""
    property string app: ""
    property string carbon: ""
    property string hw_constraints: ""
    property string hw_resources: ""
    property string model: ""
    property string metadata: ""
    // HF search/comparison history, bound in from main_window - needed here only to
    // hand to engine.save_all() below, this screen never reads/displays it itself.
    property var hf_saved_searches: []
    property var hf_compare_history: []
    // false when opened from the start screen, where there is nothing to save yet
    property bool save_enabled: true

    // Status tone of a node state: never told by colour alone, the chip shows the state too
    function __status_tone(status)
    {
        return status == "IDLE" ? "success"
             : status == "RUNNING" ? "accent"
             : status == "INITIALIZING" ? "warning"
             : "danger"
    }

    // External signals
    signal go_home();
    signal go_back();

    SmlScreenHeader
    {
        id: header
        title: "Node status"
        subtitle: "State of the SustainML framework nodes, and saved data"

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
                tooltip_text: "Go back to previous screen"
                onClicked: root.go_back()
            }
        ]

        actions: [
            // Save everything (current results + HF searches + comparisons) into a named file
            SmlButton
            {
                id: save_all_button
                icon_name: Settings.save_icon_name
                text_value: "Save"
                disabled: !root.save_enabled
                tooltip_text: "Save current results, HF searches, and comparisons into a named file"
                onClicked: save_load_all_dialogs.open_save()
            },

            // Load everything (results + HF searches + comparisons) from a named file
            SmlButton
            {
                id: load_all_button
                icon_name: Settings.load_icon_name
                text_value: "Load"
                tooltip_text: "Load results, HF searches, and comparisons from a named file"
                onClicked: save_load_all_dialogs.open_load()
            },

            // Clear saved data button
            SmlButton
            {
                id: clear_saved_data_button
                variant: "danger"
                icon_name: Settings.delete_icon_name
                text_value: "Clear saved data"
                tooltip_text: "Delete all saved result files from the backend"
                onClicked: clear_saved_data_dialog.open()
            }
        ]
    }

    SmlCard
    {
        id: nodes_card
        anchors
        {
            top: header.bottom
            topMargin: Theme.space5
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(parent.width - 2 * Theme.pagePadding, 560)
        title: "Framework nodes"
        icon_name: "workflow"
        content_padding: Theme.space2

        Column
        {
            width: nodes_card.content_area.width

            Repeater
            {
                model: ["App Requirements", "Carbon Footprint", "HW Constraints", "HW Resources", "ML Model", "Model Metadata"]

                delegate: Item
                {
                    id: node_row
                    required property string modelData
                    required property int index
                    readonly property string status: node_row.index === 0 ? root.app
                                                   : node_row.index === 1 ? root.carbon
                                                   : node_row.index === 2 ? root.hw_constraints
                                                   : node_row.index === 3 ? root.hw_resources
                                                   : node_row.index === 4 ? root.model
                                                   : root.metadata

                    width: parent.width
                    height: 44

                    Text
                    {
                        anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                        text: node_row.modelData
                        textFormat: Text.PlainText
                        font.family: Theme.uiFontFamily
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.Medium
                        color: Theme.textPrimary
                    }

                    SmlChip
                    {
                        anchors { right: parent.right; rightMargin: Theme.space4; verticalCenter: parent.verticalCenter }
                        text: node_row.status
                        tone: root.__status_tone(node_row.status)
                        pulse: node_row.status == "RUNNING" || node_row.status == "INITIALIZING"
                    }

                    Rectangle
                    {
                        visible: node_row.index > 0
                        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: Theme.space4; rightMargin: Theme.space4 }
                        height: 1
                        color: Theme.border
                    }
                }
            }
        }
    }

    SmlModal
    {
        id: clear_saved_data_dialog
        title: "Clear saved data"
        icon_name: Settings.delete_icon_name
        tone: "danger"
        standardButtons: Dialog.Yes | Dialog.No

        Text
        {
            width: clear_saved_data_dialog.availableWidth
            text: "This will permanently delete all saved result files from the backend. Tasks currently in progress are not affected. Continue?"
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            lineHeight: 1.3
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeBody
            color: Theme.textSecondary
        }

        onAccepted: engine.clear_saved_data()
    }

    SmlSaveLoadDialogs
    {
        id: save_load_all_dialogs
        anchors.fill: parent
        save_title: "Save Everything"
        load_title: "Load Everything"
        save_prompt: "Name this save, or pick an existing one below to overwrite it. Saves current results, HF searches, and comparisons together."
        no_files_text: "No saved files yet."
        onSave_requested: engine.save_all(name, root.hf_saved_searches, root.hf_compare_history)
        onLoad_requested: engine.load_all(name)
    }
}
