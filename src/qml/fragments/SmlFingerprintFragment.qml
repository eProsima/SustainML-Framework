// Library imports
import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

// Component imports
import "../components"

/*
    Fingerprint tab of a problem: the radars of the iterations selected in the Overview, next to
    the Iteration tab and opened and closed with it.
 */
Rectangle {
    id: root
    anchors.fill: parent
    color: Theme.surface

    // Public properties
    required property int problem_id
    required property int stack_id

    // Public signals
    signal component_signal(string viewType, string signal_kind, string id)

    // Private properties
    property var __iterations: []
    property var __entries: []
    property var __left_out: []

    Component.onCompleted: __update(sustainml_fragment_problem.__comparison_interation_ids_list)

    Connections {
        target: sustainml_fragment_problem
        function onUpdate_iteration(comparison_interation_ids_list) {
            root.__update(comparison_interation_ids_list)
        }
    }

    // A selected iteration may get its result after it was selected
    Connections {
        target: engine
        function onNew_carbon_footprint_node_output(problem_id, iteration_id, carbon_footprint, energy_consumption, carbon_intensity) {
            if (problem_id === root.problem_id && root.__iterations.indexOf(iteration_id) !== -1)
                Qt.callLater(root.__update, root.__iterations)
        }
    }

    // Results of the selected iterations. Left out: no model, an error in a node, or a result
    // still incomplete.
    function __update(iterations)
    {
        root.__iterations = iterations.slice().sort(function(a, b) { return a - b })
        var entries = [], left_out = []
        // problem_id -1 is the "New Tab" placeholder: it has no results to ask for
        if (root.problem_id >= 0)
        {
            root.__iterations.forEach(function(iteration) {
                var json = engine.request_specific_results(root.problem_id, iteration)
                var model = json.ML_MODEL || {}, hw = json.HW_RESOURCES || {}, carbon = json.CARBON_FOOTPRINT || {}
                var name = model.model ? String(model.model) : ""
                var hardware = hw.hw_description ? String(hw.hw_description) : ""
                var e = {
                    "iteration": iteration,
                    "model": name,
                    "hardware": hardware,
                    "co2": Number(carbon.carbon_footprint),
                    "energy": Number(carbon.energy_consumption) * 1000,   // kWh
                    "latency": Number(hw.latency) * 3600,                 // the nodes exchange hours
                    "memory": Number(hw.memory_footprint_of_ml_model) || 0,
                    "power": Number(hw.power_consumption)
                }
                var ok = name !== "" && name !== "Error" && name !== "NO_MODEL" &&
                         hardware.toLowerCase().indexOf("error") === -1 &&
                         Number(carbon.carbon_intensity) > 0 && e.co2 > 0 && e.energy > 0 && e.latency > 0 && e.power > 0
                if (ok)
                    entries.push(e)
                else
                    left_out.push(iteration)
            })
        }
        root.__entries = entries
        root.__left_out = left_out
        // The accuracy of the YOLO models comes from the catalog of the Axelera board
        if (main_window.yolo_models.length === 0 && entries.some(function(e) { return /^yolo/i.test(e.model) }))
            engine.request_yolo_models()
    }

    Flickable {
        id: flick
        visible: root.__entries.length > 0
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: fingerprint.height + 2 * Theme.space4
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        SmlModelFingerprint {
            id: fingerprint
            x: Theme.space5
            y: Theme.space4
            width: flick.width - 2 * Theme.space5
            height: implicitHeight
            entries: root.__entries
            left_out: root.__left_out
            catalog: main_window.yolo_models
            // A radar fills the height of the tab (heading, margins and the note below it aside)
            radar_height: Math.max(390, flick.height - 2 * Theme.space4 - 52 - Theme.space4 - 40)
        }
    }

    SmlEmptyState {
        anchors.centerIn: parent
        visible: root.__entries.length === 0
        title: "Nothing to draw yet"
        hint: root.__left_out.length > 0
              ? "The selected iterations have no result: an error, or still running."
              : "Select iterations in the Overview to compare their fingerprints."
    }
}
