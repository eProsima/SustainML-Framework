// Copyright 2024 Proyectos y Sistemas de Mantenimiento SL (eProsima).
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
 * @file Engine.hpp
 */

#ifndef EPROSIMA_SUSTAINML_ENGINE_HPP
#define EPROSIMA_SUSTAINML_ENGINE_HPP

#include <memory>

#include <QNetworkAccessManager>
#include <QQmlApplicationEngine>
#include <QQueue>
#include <QtCharts/QVXYModelMapper>
#include <QThread>
#include <QTimer>
#include <QWaitCondition>

#include <sustainml_cpp/core/Constants.hpp>
#include <sustainml_cpp/types/types.hpp>


#include <sustainml/REST_requester.hpp>

class Engine : public QQmlApplicationEngine
{
    Q_OBJECT

public:

    //! Standard void constructor
    Engine();

    //! Release listener and all models
    ~Engine();

    /**
     * @brief Start the Engine execution
     *
     * @return Engine pointer
     */
    QObject* enable();

public slots:

    /**
     * @brief  launch task with user input data
     *
     * @param problem_short_description short description of the problem
     * @param modality modality of the problem
     * @param metric metric of the problem
     * @param problem_definition definition of the problem
     * @param inputs inputs of the problem
     * @param outputs outputs of the problem
     * @param dataset_metadata_description description of the given dataset
     * @param dataset_metadata_topic topic of the given dataset
     * @param dataset_metadata_profile profile of the given dataset
     * @param dataset_metadata_keywords keywords of the given dataset
     * @param dataset_metadata_applications applications of the given dataset
     * @param minimum_samples minimum samples
     * @param maximum_samples maximum samples
     * @param optimize_carbon_footprint_auto optimize carbon footprint automatically
     * @param optimize_carbon_footprint_manual optimize carbon footprint manually
     * @param previous_iteration previous iteration
     * @param desired_carbon_footprint desired carbon footprint
     * @param max_memory_footprint maximum memory footprint
     * @param hardware_required hardware required
     * @param geo_location_continent continent of the location
     * @param geo_location_region region of the location
     * @param extra_data extra data
     * @param previous_problem_id id of the previous problem in case of reiteration
     * @param num_outputs number of outputs requested by the user
     * @param model_selected model selected by the user
     * @param type type of the problem
     *
     */
    void launch_task(
        QString problem_short_description,
        QString modality,
        QString metric,
        QString problem_definition,
        QString inputs,
        QString outputs,
        QString dataset_metadata_description,
        QString dataset_metadata_topic,
        QString dataset_metadata_profile,
        QString dataset_metadata_keywords,
        QString dataset_metadata_applications,
        int minimum_samples,
        int maximum_samples,
        bool optimize_carbon_footprint_auto,
        QString goal,
        bool optimize_carbon_footprint_manual,
        int previous_iteration,
        double desired_carbon_footprint,
        int max_memory_footprint,
        QString hardware_required,
        QString geo_location_continent,
        QString geo_location_region,
        QString /*extra_data_*/,
        int previous_problem_id,
        int num_outputs,
        QString model_selected,
        QString type);

    /**
     * @brief public method to launch a task with dataset path
     * @param dataset_path path to the dataset for extracting metadata
     */
    void launch_dataset_path_task(
        QString dataset_path);
    /**
     * @brief public method to request all nodes data
     * @param retrieve_all retrieve all data or only last problem received
     */
    void request_current_data (
            const bool& retrieve_all);
    /**
     * @brief public method to request specific task results from all  nodes.
     * @param task_id task identifier pointer
     */
    QJsonObject request_specific_results(
        const int problem_id, const int iteration_id);

    /**
     * @brief public method to request status periodically
     *
     */
    void request_status();

    /**
     * @brief public method to request modalities of ML
     */
    void request_modalities();

    /**
     * @brief public method to request inputs and outputs modalities of ML
     */
    void request_inout_modalities();

    /**
     * @brief public method to request goals of ML
     */
    void request_goals();

    /**
     * @brief public method to request hardwares
     */
    void request_hardwares();

    /**
     * @brief public method to request metrics from modalities or problem
     *
     * @param metric_req_type indicate if metrics are retrieved from modalities or problem. Also provide ins, out modalities or problem type
     * @param req_type_values provide ins, out modalities or problem type. Each separated by comma
     */
    void request_metrics(
        QString metric_req_type,
        QString req_type_values);

    /**
     * @brief public method to request model details
     *
     * @param mode_name indicate model name that details are requested
     */
    void request_model_info(
        QString mode_name);

    /**
     * @brief public method to request problem types from modality
     *
     * @param modality indicate modality to request problem types
     */
    void request_problem_from_modality(
            QString modality);

    /**
     * @brief public method to request models types from goal
     *
     * @param modality indicate goal to request models types
     */
    void request_model_from_goal(
        QString modality);

    /**
     * @brief private method to request user_inputs from the given previous task.
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     */
    void request_orchestrator(
        int problem_id,
        int iteration_id);

signals:

    /**
     * @brief Task sent signal to display in the GUI
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     */
    void task_sent(
            const int& problem_id,
            const int& iteration_id);

    /**
     * @brief Update log signal with raw string, appending new records in the displayed log
     *
     * @param log log string to display
     */
    void update_log(
            const QString& log);

    /**
     * @brief Update app requirements node status signal to display in the GUI
     *
     * @param status status string to display
     */
    void update_app_requirements_node_status(
            const QString& status);

    /**
     * @brief Update carbon footprint node status signal to display in the GUI
     *
     * @param status status string to display
     */
    void update_carbon_footprint_node_status(
            const QString& status);

    /**
     * @brief Update hardware constraints node status signal to display in the GUI
     *
     * @param status status string to display
     */
    void update_hw_constraints_node_status(
            const QString& status);

    /**
     * @brief Update hardware resources node status signal to display in the GUI
     *
     * @param status status string to display
     */
    void update_hw_resources_node_status(
            const QString& status);

    /**
     * @brief Update ML model metadata node status signal to display in the GUI
     *
     * @param status status string to display
     */
    void update_ml_model_metadata_node_status(
            const QString& status);

    /**
     * @brief Update ML model node status signal to display in the GUI
     *
     * @param status status string to display
     */
    void update_ml_model_node_status(
            const QString& status);

    /**
     * @brief New app requirements node output signal to display in the GUI
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     * @param app_requirements app requirements string to display
     */
    void new_app_requirements_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& app_requirements);

    /**
     * @brief New carbon footprint node output signal to display in the GUI
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     * @param hardware_required hardware required string to display
     * @param max_memory_footprint maximum memory footprint string to display
     */
    void new_hw_constraints_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& hardware_required,
            const QString& max_memory_footprint);

    /**
     * @brief New carbon footprint node output signal to display in the GUI
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     * @param metadata metadata string to display
     * @param keywords keywords string to display
     */
    void new_ml_model_metadata_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& metadata,
            const QString& keywords);

    /**
     * @brief New ML model node output signal to display in the GUI
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     * @param model model string to display
     * @param model_path model path string to display
     * @param properties properties string to display
     * @param properties_path properties path string to display
     * @param input_batch input batch string to display
     * @param target_latency target latency string to display
     */
    void new_ml_model_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& model,
            const QString& model_path,
            const QString& properties,
            const QString& properties_path,
            const QString& input_batch,
            const QString& target_latency);

    /**
     * @brief New HW resources node output signal to display in the GUI
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     * @param hw_description hardware description string to display
     * @param power_consumption power consumption string to display
     * @param latency latency string to display
     * @param memory_footprint_of_ml_model memory footprint of ML model string to display
     * @param max_hw_memory_footprint maximum hardware memory footprint string to display
     */
    void new_hw_resources_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& hw_description,
            const QString& power_consumption,
            const QString& latency,
            const QString& memory_footprint_of_ml_model,
            const QString& max_hw_memory_footprint);

    /**
     * @brief New carbon footprint node output signal to display in the GUI
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     * @param carbon_footprint carbon footprint string to display
     * @param energy_consumption energy consumption string to display
     * @param carbon_intensity carbon intensity string to display
     */
    void new_carbon_footprint_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& carbon_footprint,
            const QString& energy_consumption,
            const QString& carbon_intensity);

    /**
     * @brief Signal to reiterate user inputs for task reiteration
     *
     * @param problem_id problem identifier
     * @param iteration_id iteration identifier
     * @param modality modality of the problem
     * @param metric metric of the problem
     * @param problem_short_description short description of the problem
     * @param problem_definition definition of the problem
     * @param inputs_str inputs of the problem
     * @param outputs_str outputs of the problem
     * @param dataset_metadata_description description of the given dataset
     * @param dataset_metadata_topic topic of the given dataset
     * @param dataset_metadata_profile profile of the given dataset
     * @param dataset_metadata_keywords keywords of the given dataset
     * @param dataset_metadata_applications applications of the given dataset
     * @param minimum_samples minimum number of samples
     * @param maximum_samples maximum number of samples
     * @param optimize_carbon_footprint_manual optimize carbon footprint manually
     * @param previous_iteration previous iteration number
     * @param optimize_carbon_footprint_auto optimize carbon footprint automatically
     * @param desired_carbon_footprint desired carbon footprint value
     * @param geo_location_continent continent of the location
     * @param geo_location_region region of the location
     * @param extra_data extra data as JSON object
     */
    void reiterate_user_inputs(
        const int& problem_id,
        const int& iteration_id,
        const QString& modality,
        const QString& metric,
        const QString& problem_short_description,
        const QString& problem_definition,
        const QString& inputs_str,
        const QString& outputs_str,
        const QString& dataset_metadata_description,
        const QString& dataset_metadata_topic,
        const QString& dataset_metadata_profile,
        const QString& dataset_metadata_keywords,
        const QString& dataset_metadata_applications,
        int minimum_samples,
        int maximum_samples,
        bool optimize_carbon_footprint_manual,
        int previous_iteration,
        bool optimize_carbon_footprint_auto,
        double desired_carbon_footprint,
        const QString& geo_location_continent,
        const QString& geo_location_region,
        const QString& goal,
        const QString& hardware_required,
        const int& max_memory_footprint,
        const int& num_outputs,
        const QString& type);

    /**
     * @brief Update qml tasking bool signal as task end
     */
    void task_end();

    /**
     * @brief Update qml refreshing bool signal to display in the GUI
     */
    void refreshing_on();

    /**
     * @brief Update qml initializing bool signal to display in the GUI
     */
    void initializing_off();

    /**
     * @brief Modalities received signal to display in the GUI
     *
     * @param modalities list of possible modalities
     * @param goals list of possible goals
     */
    void modalities_available(
            const QStringList& modalities,
            const QStringList& goals);

    /**
     * @brief Dataset metadata received signal to display in the GUI
     * @param dataset_metadata map with dataset metadata
     */
    void dataset_metadata_available(
        const QVariantMap& dataset_metadata);
    /**
     * @brief Goals received signal to display in the GUI
     *
     * @param goals list of possible goals
     */
    void goals_available(
        const QStringList& goals);

    /**
     * @brief Hardwares received signal to display in the GUI
     *
     * @param hardwares list of possible hardwares
     */
    void hardwares_available(
            const QStringList& hardwares);

    /**
     * @brief Metrics received signal to display in the GUI
     *
     * @param metrics list of possible metrics
     */
    void metrics_available(
        const QStringList& metrics);

    /**
     * @brief Models received signal to display in the GUI
     *
     * @param metrics list of possible models
     */
    void models_available(
        const QStringList& metrics);

    /**
     * @brief Signal to display the error message
     *
     * @param message error message to display
     */
    void notSupportProblem(
        const QString& message);

protected:

    //! Set to true if the engine is being enabled
    bool enabled_;

private:

    /**
     * @brief private method to request results from the given node(s).
     *
     * @param task_id task identifier pointer
     * @param node_id node identifier. If set as MAX, request all node results.
     */
    void request_results(
            const types::TaskId& task_id,
            const sustainml::NodeID& node_id);

    /**
     * @brief private method to display status from the given node(s).
     *
     * @param id node identifier
     * @param json_obj JSON object with the node status
     */
    void print_results(
            const sustainml::NodeID& id,
            const QJsonObject& json_obj);

    /**
     * @brief private method to send the user_inputs to the reiteration.
     *
     * @param json_obj JSON object with the node status
     */
    void send_reiteration_inputs(
        const QJsonObject& json_obj);

    std::vector<types::TaskId> received_task_ids;
    std::vector<REST_requester*> requesters_;
    std::mutex requesters_mutex_;
    bool has_active_problem_ = false;

    // --------------- REST requester --------------- //
    //! Send user input to the Framework pipeline
    void user_input_request(
            const QJsonObject& json_obj);

    //! Manage sent user input request response
    void user_input_response(
            const REST_requester* requester,
            const QJsonObject& json_obj);

    //! Request results to the Framework
    void node_results_request(
            const QJsonObject& json_obj);

    //! Receive and propagate results to the GUI
    void node_results_response(
            const REST_requester* requester,
            const QJsonObject& json_obj);

    //! Request all results to the Framework from specific task
    QJsonObject specific_node_results_request(
        const QJsonObject& json_obj);

    //! Previous user_inputs request to the Framework
    void orchestrator_request(
        const QJsonObject& json_obj);

    //! Previous user_inputs results to the GUI
    void orchestrator_response(
        const REST_requester* requester,
        const QJsonObject& json_obj);

    //! Request node status to the Framework
    void node_status_request(
            const QJsonObject& json_obj);

    //! Receive and propagate node status to the GUI
    void node_status_response(
            const REST_requester* requester,
            const QJsonObject& json_obj);

    //! Request configuration of a Node
    void config_request(
            const QJsonObject& json_obj,
            std::function<void(const QJsonObject&)> callback);

    //! Receive and propagate the node configuration
    void config_response(
            const REST_requester* requester,
            const QJsonObject& json_obj);

    QTimer* node_status_timer_;

    std::map<int, std::function<void(const QJsonObject&)>> config_callbacks_;

    bool ml_model_idle = true;
    bool ml_model_meta_idle = true;
    bool hw_idle = true;
};

#endif //EPROSIMA_SUSTAINML_ENGINE_HPP
