// Copyright 2026 Proyectos y Sistemas de Mantenimiento SL (eProsima).
//
// This file is part of eProsima SustainML front-end.
//
// eProsima SustainML Framework Front-end is free software: you can redistribute it
// and/or modify it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// eProsima SustainML Framework Front-end is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with eProsima SustainML front-end. If not, see <https://www.gnu.org/licenses/>.

/**
 * @file SmlSaveLoadDialogs.qml
 */

import QtQuick 2.15
import QtQuick.Controls 2.15

import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.ScreenMan 1.0

// Reusable "named save file" Save/Load dialog pair, backed by the backend's
// saved_files_available() signal. Any screen that wants its own save/load flow
// (results-only, or everything) embeds one instance and calls open_save()/
// open_load() from its own buttons, then handles save_requested(name)/
// load_requested(name) by calling whichever engine method actually performs
// that screen's save/load.
//
// Because saved_files_available() is a single global signal shared by every
// instance of this component (results screen, settings screen, ...), each
// instance only reacts to responses it itself asked for - otherwise one
// screen's Save/Load click would also pop open every other screen's dialog.
Item
{
    id: root

    property string save_title: "Save"
    property string load_title: "Load"
    property string save_prompt: "Name this save, or pick an existing one below to overwrite it:"
    property string no_files_text: "No saved files yet."

    signal save_requested(string name)
    signal load_requested(string name)

    property var __saved_file_names: []
    property bool __opening_save_dialog: false
    property bool __awaiting_files_list: false
    property string __selected_saved_file: ""

    function open_save()
    {
        save_name_field.text = ""
        root.__opening_save_dialog = true
        root.__awaiting_files_list = true
        engine.request_saved_files_list()
    }

    function open_load()
    {
        root.__opening_save_dialog = false
        root.__awaiting_files_list = true
        engine.request_saved_files_list()
    }

    Connections
    {
        target: engine

        function onSaved_files_available(names)
        {
            if (!root.__awaiting_files_list) return
            root.__awaiting_files_list = false
            root.__saved_file_names = names
            if (root.__opening_save_dialog)
            {
                save_name_dialog.open()
            }
            else
            {
                root.__selected_saved_file = ""
                load_picker_dialog.open()
            }
        }
    }

    Dialog
    {
        id: save_name_dialog
        anchors.centerIn: parent
        modal: true
        padding: 16
        standardButtons: Dialog.Save | Dialog.Cancel

        background: Rectangle
        {
            anchors.fill: parent
            radius: 10
            color: Settings.app_color_light
            border.color: Settings.app_color_green_4
            border.width: 1
        }

        header: Item { }

        contentItem: Column
        {
            id: save_dialog_column
            spacing: 16

            SmlText
            {
                text_value: root.save_title
                text_kind: SmlText.TextKind.Header_2
                width: 280
                horizontalAlignment: Text.AlignHCenter
            }

            SmlText
            {
                text_value: root.save_prompt
                text_kind: SmlText.TextKind.Body
                width: 280
            }

            TextField
            {
                id: save_name_field
                width: 280
                placeholderText: "e.g. experiment 1"
                // Matches persistence.py's own whitelist exactly, so what's typed
                // here is always exactly what ends up saved - nothing gets silently
                // dropped server-side. '/' is allowed as a literal character - the
                // backend encodes it so it never becomes a real subfolder.
                validator: RegExpValidator { regExp: /^[A-Za-z0-9 _/-]*$/ }
            }

            SmlText
            {
                visible: root.__saved_file_names.length > 0
                text_value: "Existing saves:"
                text_kind: SmlText.TextKind.Body
                width: 280
            }

            ScrollView
            {
                width: 280
                height: Math.min(save_existing_column.implicitHeight, 160)
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column
                {
                    id: save_existing_column
                    // Narrower than the ScrollView itself, leaving clearance on the right
                    // for its overlay scrollbar so it doesn't cover the row content.
                    width: 280 - 16
                    spacing: 8

                    Repeater
                    {
                        model: root.__saved_file_names

                        delegate: Rectangle
                        {
                            id: existing_save_row
                            required property var modelData

                            width: save_existing_column.width
                            height: 36
                            radius: height / 2.5
                            // "Selected" here just means it matches whatever's currently
                            // typed in the name field - the same thing clicking a row sets,
                            // so it also highlights correctly if someone types a match by hand.
                            color: existing_save_row.modelData === save_name_field.text
                                ? Settings.app_color_green_1
                                : (ScreenManager.night_mode ? Settings.app_color_green_2 : Settings.app_color_green_4)

                            SmlText
                            {
                                anchors
                                {
                                    left: parent.left
                                    leftMargin: Settings.spacing_normal
                                    right: parent.right
                                    rightMargin: Settings.spacing_normal
                                    verticalCenter: parent.verticalCenter
                                }
                                force_elide: true
                                text_value: existing_save_row.modelData
                                text_kind: SmlText.TextKind.Body
                                force_color: true
                                forced_color: ScreenManager.night_mode ? Settings.app_color_green_1 : Settings.app_color_green_3
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: save_name_field.text = existing_save_row.modelData
                            }
                        }
                    }
                }
            }
        }

        onAccepted:
        {
            var chosen_name = save_name_field.text.trim()
            if (chosen_name.length > 0)
            {
                root.save_requested(chosen_name)
            }
        }
    }

    Dialog
    {
        id: load_picker_dialog
        anchors.centerIn: parent
        modal: true
        padding: 16
        standardButtons: Dialog.Open | Dialog.Cancel

        width: 320

        Component.onCompleted:
        {
            var open_button = load_picker_dialog.standardButton(Dialog.Open)
            open_button.text = "Load"
            open_button.enabled = Qt.binding(function() { return root.__selected_saved_file !== "" })
        }

        onAccepted:
        {
            if (root.__selected_saved_file !== "")
            {
                root.load_requested(root.__selected_saved_file)
            }
        }

        background: Rectangle
        {
            anchors.fill: parent
            radius: 10
            color: Settings.app_color_light
            border.color: Settings.app_color_green_4
            border.width: 1
        }

        header: Item { }

        contentItem: Column
        {
            id: load_dialog_column
            spacing: 12
            width: load_picker_dialog.availableWidth

            SmlText
            {
                text_value: root.load_title
                text_kind: SmlText.TextKind.Header_2
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            SmlText
            {
                visible: root.__saved_file_names.length === 0
                text_value: root.no_files_text
                text_kind: SmlText.TextKind.Body
                width: parent.width
            }

            ScrollView
            {
                width: parent.width
                height: Math.min(load_files_column.implicitHeight, 260)
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column
                {
                    id: load_files_column
                    // Narrower than the ScrollView itself, leaving clearance on the right
                    // for its overlay scrollbar so it doesn't cover the row content
                    // (including the delete X, which sits at the row's right edge).
                    width: load_picker_dialog.contentItem.width - 16
                    spacing: 8

                    Repeater
                    {
                        model: root.__saved_file_names

                        delegate: Rectangle
                        {
                            id: saved_file_row
                            required property var modelData

                            width: load_files_column.width
                            height: 36
                            radius: height / 2.5
                            color: saved_file_row.modelData === root.__selected_saved_file
                                ? Settings.app_color_green_1
                                : (ScreenManager.night_mode ? Settings.app_color_green_2 : Settings.app_color_green_4)

                            SmlText
                            {
                                id: saved_file_label
                                anchors
                                {
                                    left: parent.left
                                    leftMargin: Settings.spacing_normal
                                    right: delete_icon.left
                                    rightMargin: Settings.spacing_small
                                    verticalCenter: parent.verticalCenter
                                }
                                force_elide: true
                                text_value: saved_file_row.modelData
                                text_kind: SmlText.TextKind.Body
                                force_color: true
                                forced_color: ScreenManager.night_mode ? Settings.app_color_green_1 : Settings.app_color_green_3
                            }

                            SmlIcon
                            {
                                id: delete_icon
                                anchors
                                {
                                    right: parent.right
                                    rightMargin: Settings.spacing_normal
                                    verticalCenter: parent.verticalCenter
                                }
                                name: Settings.close_tab_icon_name
                                size: Settings.spacing_normal
                                color: Settings.app_color_green_3
                                nightmode_color: Settings.app_color_green_1
                            }

                            // Click anywhere but the X to select this saved file - loading
                            // itself happens via the separate Load button below
                            MouseArea
                            {
                                anchors
                                {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    right: delete_icon.left
                                    rightMargin: -Settings.spacing_small
                                }
                                onClicked: root.__selected_saved_file = saved_file_row.modelData
                            }

                            // Click the X to delete just this one saved file
                            MouseArea
                            {
                                anchors
                                {
                                    left: delete_icon.left
                                    leftMargin: -Settings.spacing_small
                                    top: parent.top
                                    bottom: parent.bottom
                                    right: parent.right
                                }
                                onClicked:
                                {
                                    engine.delete_saved_file(saved_file_row.modelData)
                                    root.__saved_file_names = root.__saved_file_names.filter(function(n) { return n !== saved_file_row.modelData })
                                    if (root.__selected_saved_file === saved_file_row.modelData)
                                    {
                                        root.__selected_saved_file = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
