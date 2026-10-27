// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtCharts 2.15


// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"

Rectangle
{
    id: root
    anchors.fill: parent

    // Public properties
    required property int problem_id
    required property int stack_id

    color: Theme.surface

    // Bar colours: SustainML greens, then teals and limes, distinct in both themes
    readonly property var __bar_colors: ["#2D7D1B", "#64C537", "#1F8A70", "#A7D84A", "#145A32", "#4FB3A0", "#7A9E1F", "#2E5E4E"]

    // Private properties
    property var values_list: []
    property var _barSets: []
    property var jsonList : []

    function getYAxisUnits() {
        if (values_list.length === 1) {
            var txt = values_list[0].toString()
            var m = txt.match(/\[(.+?)\]/)
            if (m && m.length > 1)
                return m[1]
        }
        return ""
    }

    Connections {
        target: sustainml_fragment_problem

        function onUpdate_iteration(comparison_interation_ids_list) {
            // problem_id -1 is the "New Tab" placeholder (no real problem behind it) -
            // requesting results for it crashes the backend (uint32_t can't hold -1).
            if (problem_id < 0) return;

            var newList = [];
            for (var i = 0; i < comparison_interation_ids_list.length; i++) {
                var iterationId = comparison_interation_ids_list[i];
                var json = engine.request_specific_results(problem_id, iterationId);
                newList.push(json);
            }
            jsonList = newList;
            chartView.addDynamicBars(newList);
            chartView.update()
        }

        function onUpdate_comparison(comparison_value) {
            if (comparison_value != "" && values_list.length === 0) {
                values_list = [comparison_value];
                yAxis.titleText = getYAxisUnits();
                chartView.update()
            }
        }
    }

    ChartView {
        id: chartView
        title: ""
        anchors.fill: parent
        legend.alignment: Qt.AlignBottom
        legend.labelColor: Theme.textSecondary
        legend.font.family: Theme.uiFontFamily
        legend.font.pixelSize: Theme.fontSizeMeta
        antialiasing: true
        backgroundColor: Theme.surface
        plotAreaColor: Theme.surface
        backgroundRoundness: 0
        margins { left: Theme.space4; right: Theme.space4; top: Theme.space4; bottom: Theme.space2 }

        BarSeries {
            id: mySeries
            labelsVisible: true
            labelsFormat: "@value"
            axisX: BarCategoryAxis {
                categories: root.values_list
                labelsColor: Theme.textSecondary
                labelsFont.family: Theme.uiFontFamily
                labelsFont.pixelSize: Theme.fontSizeBody
                color: Theme.borderStrong
                gridVisible: false
            }
            axisY: ValueAxis {
                id: yAxis
                titleText: root.getYAxisUnits()
                titleBrush: Theme.textMuted
                titleFont.family: Theme.uiFontFamily
                titleFont.pixelSize: Theme.fontSizeMeta
                labelsColor: Theme.textMuted
                labelsFont.family: Theme.monoFontFamily
                labelsFont.pixelSize: Theme.fontSizeMeta
                gridLineColor: Theme.border
                color: Theme.borderStrong
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
                        // the nodes exchange the latency in hours: shown in seconds, as in the iteration table
                        case "Latency [s]":
                            valuesArray.push(data.HW_RESOURCES.latency * 3600);
                            break;
                        case "Memory Footprint [MB]":
                            valuesArray.push(data.HW_RESOURCES.memory_footprint_of_ml_model);
                            break;
                        case "Power Consumption [W]":
                            valuesArray.push(data.HW_RESOURCES.power_consumption);
                            break;
                        case "Carbon Footprint [gCO2e]":
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
                    var shown = mySeries.append(barSet.label, barSet.values);
                    if (shown) {
                        shown.color = root.__bar_colors[j % root.__bar_colors.length];
                        shown.borderColor = shown.color;
                        shown.labelColor = Theme.textPrimary;
                    }
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
                    highest = Math.max(highest, barSet.values[j]);
                }
            }
            mySeries.axisY.max = highest * 1.1;
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

    SmlMenu {
        id: contextMenuData
        SmlMenuItem {
            icon_name: "info"
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

        // Node results as text; empty until an iteration is chosen
        function nodeText(node) { return node ? JSON.stringify(node, null, 2) : "" }

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
            color: Theme.overlay
            border.color: Theme.borderStrong

            SmlIconButton {
                anchors.top: parent.top
                anchors.topMargin: Theme.space2
                anchors.right: parent.right
                anchors.rightMargin: Theme.space2
                button_size: Theme.controlHeightSm
                icon_name: "cross"
                tooltip_text: "Close"
                onClicked: infoPopup.close()
            }

            SmlText {
                id: iterationTextHeader
                anchors {
                    top: parent.top
                    topMargin: Theme.space4
                    left: parent.left
                    leftMargin: Theme.space5
                }
                text_value: "Iteration " + infoPopup.iteration
                text_kind: SmlText.TextKind.Header_2

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

                Rectangle {
                    id: tableContent
                    width: parent.width
                    color: "transparent"
                    border.color: "transparent"

                    visible: Object.keys(infoPopup.jsonData).length > 0
                    anchors {
                        top: parent.top
                        left: parent.left
                        leftMargin: Theme.space5
                    }

                    Column {
                        id: columnContent
                        spacing: Settings.spacing_small
                        width: parent.width

                        SmlText {
                            text_value: "Node ML_MODEL"
                            font.weight: Font.DemiBold
                            force_color: true
                            forced_color: Theme.accentText
                        }
                        SmlText {
                            text_value: infoPopup.nodeText(infoPopup.jsonData.ML_MODEL)
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeMeta
                            wrapMode: Text.WordWrap
                        }

                        SmlText {
                            text_value: "Node CARBON_FOOTPRINT"
                            font.weight: Font.DemiBold
                            force_color: true
                            forced_color: Theme.accentText
                        }
                        SmlText {
                            text_value: infoPopup.nodeText(infoPopup.jsonData.CARBON_FOOTPRINT)
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeMeta
                            wrapMode: Text.WordWrap
                        }

                        SmlText {
                            text_value: "Node APP_REQUIREMENTS"
                            font.weight: Font.DemiBold
                            force_color: true
                            forced_color: Theme.accentText
                        }

                        SmlText {
                            text_value: infoPopup.nodeText(infoPopup.jsonData.APP_REQUIREMENTS)
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeMeta
                            wrapMode: Text.WordWrap
                        }

                        SmlText {
                            text_value: "Node HW_CONSTRAINTS"
                            font.weight: Font.DemiBold
                            force_color: true
                            forced_color: Theme.accentText
                        }

                        SmlText {
                            text_value: infoPopup.nodeText(infoPopup.jsonData.HW_CONSTRAINTS)
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeMeta
                            wrapMode: Text.WordWrap
                        }

                        SmlText {
                            text_value: "Node HW_RESOURCES"
                            font.weight: Font.DemiBold
                            force_color: true
                            forced_color: Theme.accentText
                        }

                        SmlText {
                            text_value: infoPopup.nodeText(infoPopup.jsonData.HW_RESOURCES)
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeMeta
                            wrapMode: Text.WordWrap
                        }

                        SmlText {
                            text_value: "Node ML_MODEL_METADATA"
                            font.weight: Font.DemiBold
                            force_color: true
                            forced_color: Theme.accentText
                        }

                        SmlText {
                            text_value: infoPopup.nodeText(infoPopup.jsonData.ML_MODEL_METADATA)
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeMeta
                            wrapMode: Text.WordWrap
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
