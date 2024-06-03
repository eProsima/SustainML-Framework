// Library imports
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.Font 1.0
import eProsima.SustainML.ScreenMan 1.0

// Component imports
import "../components"

Item
{
    id: sustainml_fragment_problem

    // Public properties
    required property int problem_id
    required property int stack_id

    // Private properties
    readonly property var __signal_kind: ["inspect", "add_to_compare", "compare"]
    property var __comparison_interation_ids_list: []

    onProblem_idChanged:
    {
        problem_fragment_view.update_problem_id(problem_id, -1)
    }


    Rectangle
    {
        anchors.top: parent.top
        anchors.left: parent.left
        width: 50
        height: 20
        color: ScreenManager.night_mode ? "grey" : "white" //"transparent"
    }

    SmlTabView
    {
        id: problem_fragment_view

        property var problem_components: {"general_view": "qrc:/qml/fragments/SmlGeneralFragment.qml",
                                        "iteration_view": "qrc:/qml/fragments/SmlIterationFragment.qml",
                                       "comparison_view": "qrc:/qml/fragments/SmlComparisonFragment.qml"}

        property var components_title_map: { "general_view": "Overview",
                                           "iteration_view": "Iteration",
                                          "comparison_view": "Comparison"}
        property var components_stack_id_map: { "general_view": 0,
                                              "iteration_view": 1,
                                             "comparison_view": 2}

        anchors.fill: parent
        clip: true

        allowed_stack_components: problem_components
        default_stack_component: "general_view"
        selected_tab_color: "#fafafa"

        onTab_view_loaded:
        {
            problem_fragment_view.update_stack_id(components_stack_id_map["general_view"], -1)
            problem_fragment_view.update_problem_id(problem_id, -1)
            problem_fragment_view.update_tab_name(components_title_map["general_view"], components_stack_id_map["general_view"])
            problem_fragment_view.create_new_tab(components_title_map["iteration_view"], components_stack_id_map["iteration_view"], problem_id, "iteration_view")
            problem_fragment_view.create_new_tab(components_title_map["comparison_view"], components_stack_id_map["comparison_view"], problem_id, "comparison_view")
            problem_fragment_view.focus(components_stack_id_map["general_view"], problem_id)
        }
        onRetrieve_default_data:
        {
            problem_fragment_view.create_new_tab(components_title_map["general_view"], components_stack_id_map["general_view"], problem_id, "general_view")
            engine.request_current_data(true)
        }
        onLoaded_item_signal:
        {
            if (component === "general_view")
            {
                if (signal_kind === "inspect")
                {
                    problem_fragment_view.create_new_tab(components_title_map["iteration_view"], components_stack_id_map["iteration_view"], problem_id, "iteration_view")
                    // set iteration view with given id
                }
                else if (signal_kind === "add_to_compare")
                {
                    sustainml_fragment_problem.__comparison_interation_ids_list.push(id)
                    console.log("Added iteration id " + id + " to comparison list: " + sustainml_fragment_problem.__comparison_interation_ids_list)
                }
                else if (signal_kind === "compare")
                {
                    problem_fragment_view.create_new_tab(components_title_map["comparison_view"], components_stack_id_map["comparison_view"], problem_id, "comparison_view")
                    // set comparison view with given ids (sustainml_fragment_problem.__comparison_interation_ids_list)
                }
            }
            else if (component === "iteration_view")
            {
                if (signal_kind === "")
                {
                    //id
                }
            }
            else if (component === "comparison_view")
            {
                if (signal_kind === "")
                {
                    //id
                }
            }
        }
    }
}
