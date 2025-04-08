import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Rectangle {
    id: sustainml_fragment_iteration
    // Public properties
    required property int problem_id
    required property int stack_id

    anchors.fill: parent

    color: ScreenManager.night_mode ? selected_tab_nightmode_color : selected_tab_color

    // Private properties
    property var iteration_list: []

    Connections {
        target: sustainml_fragment_problem

        function onUpdate_iteration(comparison_interation_ids_list) {
            var newList = [];
            for (var i = 0; i < comparison_interation_ids_list.length; i++) {
                var iterationId = comparison_interation_ids_list[i];
                var json = engine.request_specific_results(problem_id, iterationId);
                newList.push(json);
            }
            iteration_list = newList;
        }
    }

    SmlScrollView {
        id: iterationScrollView
        anchors.fill: parent
        width: sustainml_fragment_iteration.width - Settings.spacing_small * 2
        height: sustainml_fragment_iteration.height - Settings.spacing_small
        content_width: iterationListView.contentWidth > width ? iterationListView.contentWidth : width
        content_height: iterationListView.contentHeight > height ? iterationListView.contentHeight : height
        layout: SmlScrollBar.ScrollBarLayout.Both
        scrollbar_backgound_color: Settings.app_color_light
        scrollbar_backgound_nightmodel_color: Settings.app_color_dark

        ListView {
            id: iterationListView
            anchors.fill: parent
            contentWidth: contentItem.childrenRect.width + 20
            clip: true
            model: iteration_list

            delegate: Rectangle {
                id: iterationDelegate
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: 8
                }

                border.color: "#cccccc"
                border.width: 1
                color: "transparent"
                implicitHeight: columnContent.implicitHeight + 20
                implicitWidth: rowContent.childrenRect.width + 20

                Column {
                    id: columnContent
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "Iteration ID: " + modelData.task_id.iteration_id
                        font.bold: true
                        font.pointSize: 16
                    }

                    Row {
                        id: rowContent
                        spacing: 10
                        anchors.left: parent.left
                        anchors.right: parent.right
                        Column {
                            spacing: 5
                            width: mlModelText.contentWidth
                            Text {
                                text: "Node ML_MODEL"
                                font.bold: true
                                font.pointSize: 13
                            }
                            Text {
                                id: mlModelText
                                text: "Content: " + JSON.stringify(modelData.ML_MODEL, null, 2)
                                font.family: "monospace"
                                wrapMode: Text.WordWrap
                            }
                        }

                        Column {
                            spacing: 5
                            width: carbonFootprintText.contentWidth
                            Text {
                                text: "Node CARBON_FOOTPRINT"
                                font.bold: true
                                font.pointSize: 13
                            }
                            Text {
                                id: carbonFootprintText
                                text: "Content: " + JSON.stringify(modelData.CARBON_FOOTPRINT, null, 2)
                                font.family: "monospace"
                                wrapMode: Text.WordWrap
                            }
                        }

                        Column {
                            spacing: 5
                            width: appRequirementText.contentWidth
                            Text {
                                text: "Node APP_REQUIREMENTS"
                                font.bold: true
                                font.pointSize: 13
                            }
                            Text {
                                id: appRequirementText
                                text: "Content: " + JSON.stringify(modelData.APP_REQUIREMENTS, null, 2)
                                font.family: "monospace"
                                wrapMode: Text.WordWrap
                            }
                        }

                        Column {
                            spacing: 5
                            width: hwConstraintsText.contentWidth
                            Text {
                                text: "Node HW_CONSTRAINTS"
                                font.bold: true
                                font.pointSize: 13
                            }
                            Text {
                                id: hwConstraintsText
                                text: "Content: " + JSON.stringify(modelData.HW_CONSTRAINTS, null, 2)
                                font.family: "monospace"
                                wrapMode: Text.WordWrap
                            }
                        }

                        Column {
                            spacing: 5
                            width: hwResourcesText.contentWidth
                            Text {
                                text: "Node HW_RESOURCES"
                                font.bold: true
                                font.pointSize: 13
                            }
                            Text {
                                id: hwResourcesText
                                text: "Content: " + JSON.stringify(modelData.HW_RESOURCES, null, 2)
                                font.family: "monospace"
                                wrapMode: Text.WordWrap
                            }
                        }

                        Column {
                            spacing: 5
                            width: mlModelMetadataText.contentWidth
                            Text {
                                text: "Node ML_MODEL_METADATA"
                                font.bold: true
                                font.pointSize: 13
                            }
                            Text {
                                id: mlModelMetadataText
                                text: "Content: " + JSON.stringify(modelData.ML_MODEL_METADATA, null, 2)
                                font.family: "monospace"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
