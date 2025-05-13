// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtCharts 2.15


// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Rectangle
{
    id: root
    anchors.fill: parent

    // Public properties
    required property int problem_id
    required property int stack_id

    color: ScreenManager.night_mode ? selected_tab_nightmode_color : selected_tab_color

    // Private properties
    property var values_list: []
    property var _barSets: []
    property var jsonList : []

    Connections {
        target: sustainml_fragment_problem

        function onUpdate_iteration(comparison_interation_ids_list) {
            var newList = [];
            for (var i = 0; i < comparison_interation_ids_list.length; i++) {
                var iterationId = comparison_interation_ids_list[i];
                var json = engine.request_specific_results(problem_id, iterationId);
                newList.push(json);
            }
            jsonList = newList;
            chartView.addDynamicBars(newList);
        }

        function onUpdate_comparison(comparison_values_list) {
            if (comparison_values_list.length > 0) {
                values_list = [comparison_values_list[comparison_values_list.length - 1]];  // TODO: Now only show last value, implement multiple barSeries
            } else {
                values_list = [];
            }
        }
    }

    ChartView {
        id: chartView
        title: "Comparisons between iterations"
        anchors.fill: parent
        legend.alignment: Qt.AlignBottom
        antialiasing: true

        BarSeries {
            id: mySeries
            labelsVisible: true
            labelsFormat: "@value"
            axisX: BarCategoryAxis { categories: root.values_list }
            axisY: ValueAxis {
                min: 0
                max: 100
            }
        }

        Component {
            id: dynamicBarSet
            BarSet {
                label: ""
                values: []
            }
        }

        // Function to add dynamic bars to the chart
        function addDynamicBars(iteration_list) {
            mySeries.clear();
            _barSets = [];
            for (var j = 0; j < iteration_list.length; j++) {
                var data = iteration_list[j];
                var valuesArray = [];

                for (var i = 0; i < root.values_list.length; i++) {
                    var value = values_list[i];
                    switch (value.toString()) {
                        case "Latency [ms]":
                            valuesArray.push(data.HW_RESOURCES.latency);
                            break;
                        case "Memory Footprint [MB]":
                            valuesArray.push(data.HW_RESOURCES.memory_footprint_of_ml_model);
                            break;
                        case "Power Consumption [W]":
                            valuesArray.push(data.HW_RESOURCES.power_consumption);
                            break;
                        case "Carbon Footprint [kgCO2e]":
                            valuesArray.push(data.CARBON_FOOTPRINT.carbon_footprint);
                            break;
                        case "Carbon Intensity [gCO2/kW]":
                            valuesArray.push(data.CARBON_FOOTPRINT.carbon_intensity);
                            break;
                        case "Energy Consumption [kWh]":
                            valuesArray.push(data.CARBON_FOOTPRINT.energy_consumption);
                            break;
                        default:
                            console.log("Unknown value: " + value);
                    }
                }

                var barSet = dynamicBarSet.createObject(mySeries, {
                        "label": "Iteration " + data.task_id.iteration_id,
                        "values": valuesArray
                    });
                if (barSet !== null) {
                    mySeries.append(barSet.label, barSet.values);
                    _barSets.push(barSet);
                    // console.log("BarSet created for element: " + j);
                } else {
                    console.log("Unable to create BarSet for element: " + j);
                }
            }
            updateYAxisMax();
        }

        function updateYAxisMax() {
            var highest = 0;
            for (var i = 0; i < _barSets.length; i++) {
                var barSet = _barSets[i];
                for (var j = 0; j < barSet.values.length; j++) {
                    console.log("barSet.values[" + j + "]: " + barSet.values[j]);
                    highest = Math.max(highest, barSet.values[j]);
                }
            }
            mySeries.axisY.max = highest * 1.1;
            console.log("Highest value: " + highest);
        }
    }

    MouseArea {
        id: chartMouseArea
        anchors.fill: chartView
        hoverEnabled: true
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.ArrowCursor
        property var actualBarSet: 0

        onPositionChanged: {

            var pos = chartView.mapToValue(Qt.point(mouse.x, mouse.y), mySeries);
            var hovered = false;

            for (var i = 0; i < _barSets.length; i++) {
                var barSet = _barSets[i];
                for (var j = 0; j <  barSet.values.length; j++) {
                    var barValue = barSet.values[j];
                    var barWidth = 0.5 / _barSets.length;
                    var centerX = barWidth / 2 + barWidth * i - 0.25;
                    if (Math.abs(pos.x - centerX) < barWidth / 2 && (pos.y < barValue && pos.y > 0)) {
                        hovered = true;
                        actualBarSet = parseInt(barSet.label.split(" ").pop());
                        break;
                    }
                }
            }

            cursorShape = hovered ? Qt.PointingHandCursor : Qt.ArrowCursor;
        }

        onClicked: {
            if (cursorShape === Qt.PointingHandCursor) {
                contextMenuData.popup(mouse.x, mouse.y);
            }
        }
    }

    Menu {
        id: contextMenuData
        MenuItem {
            text: "More info"
            onTriggered: {
                infoPopup.iteration = chartMouseArea.actualBarSet;
                infoPopup.open();
            }
        }
    }

    Popup {
        id: infoPopup
        modal: true
        focus: true
        x: -width
        y: 0
        width: 500
        height: parent.height
        background: Rectangle { color: "transparent" }
        property var iteration: ""

        Behavior on x {
            NumberAnimation { duration: 350; easing.type: Easing.OutQuad }
        }

        property var jsonData: (function() {
            for (var i = 0; i < root.jsonList.length; i++) {
                if (parseInt(root.jsonList[i].task_id.iteration_id) === parseInt(infoPopup.iteration)) {
                    return root.jsonList[i];
                }
            }
            return {};
        })()

        Rectangle {
            anchors.fill: parent
            color: "white"
            border.color: "#cccccc"

            Button {
                text: "X"
                anchors.top: parent.top
                anchors.right: parent.right
                width: 20
                height: 20
                onClicked: infoPopup.close()
            }

            SmlText {
                id: iterationTextHeader
                anchors {
                    top: parent.top
                    topMargin: Settings.spacing_small
                    horizontalCenter: parent.horizontalCenter
                }
                text_value: "Iteration " + infoPopup.iteration
                text_kind: SmlText.TextKind.Header_3
                font.bold: true
                font.pointSize: 13

            }

            SmlScrollView {
                // anchors.fill: parent
                anchors.top: iterationTextHeader.bottom
                anchors.topMargin: Settings.spacing_small
                anchors.left: parent.left
                anchors.right: parent.right
                width: parent.width
                height: parent.height - iterationTextHeader.height - Settings.spacing_small * 2
                content_height: columnContent.implicitHeight
                layout: SmlScrollBar.ScrollBarLayout.Vertical
                scrollbar_backgound_color: Settings.app_color_light
                scrollbar_backgound_nightmodel_color: Settings.app_color_dark

                Rectangle {
                    id: tableContent
                    width: parent.width
                    color: "transparent"
                    border.color: "transparent"

                    visible: Object.keys(infoPopup.jsonData).length > 0
                    anchors {
                        top: iterationTextHeader.bottom
                        topMargin: Settings.spacing_small
                        left: parent.left
                        leftMargin: Settings.spacing_normal
                    }

                    Column {
                        id: columnContent
                        spacing: Settings.spacing_small
                        width: parent.width

                        SmlText {
                            text_value: "Node ML_MODEL"
                            font.bold: true
                            font.pointSize: 13
                        }
                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.ML_MODEL, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node CARBON_FOOTPRINT"
                            font.bold: true
                            font.pointSize: 13
                        }
                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.CARBON_FOOTPRINT, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node APP_REQUIREMENTS"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.APP_REQUIREMENTS, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node HW_CONSTRAINTS"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.HW_CONSTRAINTS, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node HW_RESOURCES"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.HW_RESOURCES, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        SmlText {
                            text_value: "Node ML_MODEL_METADATA"
                            font.bold: true
                            font.pointSize: 13
                        }

                        SmlText {
                            text_value: JSON.stringify(infoPopup.jsonData.ML_MODEL_METADATA, null, 2)
                            font.family: "monospace"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                x = 0;
            } else {
                x = -width;
            }
        }
    }
}
