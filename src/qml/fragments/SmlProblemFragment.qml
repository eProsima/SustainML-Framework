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

    // Public signals
    signal update_iteration(var comparison_interation_ids_list)
    signal update_comparison(var comparison_interation_ids_list)

    // Private properties
    readonly property var __signal_kind: ["add_to_compare", "out_of_compare"]
    property var __comparison_interation_ids_list: []
    property var __comparison_values_list: []

    onProblem_idChanged:
    {
        problem_fragment_view.update_problem_id(problem_id, -1)
    }


    // Rectangle
    // {
    //     anchors.top: parent.top
    //     anchors.left: parent.left
    //     width: 50
    //     height: 20
    //     color: ScreenManager.night_mode ? "#303030" : "white" //"transparent"
    // }

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
        tab_background_color: "transparent"
        tab_background_nightmode_color: "transparent"
        selected_tab_color: "#e0e0e0"
        selected_tab_nightmode_color: "#505050"
        not_selected_tab_color: "#d0d0d0"
        not_selected_tab_nightmode_color: "#404040"
        not_selected_shadow_tab_color: "#909090"
        not_selected_shadow_tab_nightmode_color: "#303030"

        onTab_view_loaded:
        {
            problem_fragment_view.update_stack_id(components_stack_id_map["general_view"], -1)
            problem_fragment_view.update_problem_id(problem_id, -1)
            problem_fragment_view.update_tab_name(components_title_map["general_view"], components_stack_id_map["general_view"])
            // problem_fragment_view.create_new_tab(components_title_map["iteration_view"], components_stack_id_map["iteration_view"], problem_id, "iteration_view")
            // problem_fragment_view.create_new_tab(components_title_map["comparison_view"], components_stack_id_map["comparison_view"], problem_id, "comparison_view")
            problem_fragment_view.focus(components_stack_id_map["general_view"], problem_id)
        }
        onRetrieve_default_data:
        {
            problem_fragment_view.create_new_tab(components_title_map["general_view"], components_stack_id_map["general_view"], problem_id, "general_view")
            engine.request_current_data(true)
        }
        onLoaded_item_signal:
        {
            console.log("Signal received: " + component + " " + signal_kind + " " + iteration_id)
            if (component === "general_view")
            {
                if (signal_kind === "add_to_compare")
                {
                    sustainml_fragment_problem.__comparison_interation_ids_list.push(iteration_id)
                    console.log("Added iteration id " + iteration_id + " to comparison list: " + sustainml_fragment_problem.__comparison_interation_ids_list)
                    problem_fragment_view.create_new_tab(components_title_map["iteration_view"], components_stack_id_map["iteration_view"], problem_id, "iteration_view")
                    if (sustainml_fragment_problem.__comparison_interation_ids_list.length >= 2)
                    {
                        // problem_fragment_view.create_new_tab(components_title_map["comparison_view"], components_stack_id_map["comparison_view"], problem_id, "comparison_view")
                    }
                    sustainml_fragment_problem.update_iteration(sustainml_fragment_problem.__comparison_interation_ids_list)
                    // problem_fragment_view.focus(components_stack_id_map["general_view"], problem_id)
                }

                //TODO: create signal for delation of iteration from __comparison_interation_ids_list abd update in SmlIteration and SmlComparison
                else if (signal_kind === "out_of_compare")
                {
                    var index = sustainml_fragment_problem.__comparison_interation_ids_list.indexOf(iteration_id);
                    if (index !== -1) {
                        sustainml_fragment_problem.__comparison_interation_ids_list.splice(index, 1);
                    }
                    console.log("Get rid of iteration id " + iteration_id + " from comparison list: " + sustainml_fragment_problem.__comparison_interation_ids_list)

                    if (sustainml_fragment_problem.__comparison_interation_ids_list.length < 2)
                    {
                        problem_fragment_view.close_tab(components_stack_id_map["comparison_view"], problem_id)

                        if (sustainml_fragment_problem.__comparison_interation_ids_list.length == 0)
                            problem_fragment_view.close_tab(components_stack_id_map["iteration_view"], problem_id)
                    }

                    sustainml_fragment_problem.update_iteration(sustainml_fragment_problem.__comparison_interation_ids_list)
                }
            }
            else if (component === "iteration_view")
            {
                if (signal_kind === "add_to_compare")
                {
                    sustainml_fragment_problem.__comparison_values_list.push(iteration_id)  // Here iteration_id is the name of value to compare
                    console.log("Added " + iteration_id + " to comparison list: " + sustainml_fragment_problem.__comparison_values_list)
                    problem_fragment_view.create_new_tab(components_title_map["comparison_view"], components_stack_id_map["comparison_view"], problem_id, "comparison_view")
                    sustainml_fragment_problem.update_comparison(sustainml_fragment_problem.__comparison_values_list)
                    sustainml_fragment_problem.update_iteration(sustainml_fragment_problem.__comparison_interation_ids_list)
                    problem_fragment_view.focus(components_stack_id_map["comparison_view"], problem_id)

                }
                else if (signal_kind === "out_of_compare")
                {
                    // TODO: signal to delate comparison value from __comparison_values_list
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
