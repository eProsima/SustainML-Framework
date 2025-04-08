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
    id: sustainml_fragment_comparison
    anchors.fill: parent

    // Public properties
    required property int problem_id
    required property int stack_id

    color: ScreenManager.night_mode ? selected_tab_nightmode_color : selected_tab_color

    // Private properties
    // property var iteration_list: []

    Connections {
        target: sustainml_fragment_problem

        function onUpdate_iteration(comparison_interation_ids_list) {
            var newList = [];
            for (var i = 0; i < comparison_interation_ids_list.length; i++) {
                var iterationId = comparison_interation_ids_list[i];
                var json = engine.request_specific_results(problem_id, iterationId);
                newList.push(json);
            }
            var iteration_list = newList;
            // console.log("Iteration list: " + iteration_list.length);    //debug
            chartView.addDynamicBars(newList);
        }
    }

    ChartView {
        id: chartView
        title: "Bar series"
        anchors.fill: parent
        legend.alignment: Qt.AlignBottom
        antialiasing: true

        BarSeries {
            id: mySeries
            axisX: BarCategoryAxis { categories: ["Power Consumption"] }
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
            for (var i = 0; i < iteration_list.length; i++) {
                var data = iteration_list[i];
                var barSet = dynamicBarSet.createObject(mySeries, {
                    "label": "Iteration " + data.task_id.iteration_id,
                    "values": [data.CARBON_FOOTPRINT.carbon_intensity]
                });
                // console.log("Plotea: Label = " + barSet.label + ", Value = " + barSet.values);   //debug
                if (barSet !== null) {
                    mySeries.append(barSet.label, barSet.values);
                    // console.log("BarSet created for element: " + i);
                } else {
                    console.log("Unable to create BarSet for element: " + i);
                }
            }
            updateYAxisMax(iteration_list);
        }

        function updateYAxisMax(iteration_list) {
            var highest = 0;
            for (var i = 0; i < iteration_list.length; i++) {
                var data = iteration_list[i];
                highest = Math.max(highest, data.CARBON_FOOTPRINT.carbon_intensity);
            }
            mySeries.axisY.max = highest * 1.1;
        }
    }
}
