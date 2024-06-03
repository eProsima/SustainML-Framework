// Copyright 2024 Proyectos y Sistemas de Mantenimiento SL (eProsima).
//
// This file is part of eProsima SustainML front-end.
//
// eProsima Fast DDS Monitor is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// eProsima Fast DDS Monitor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with eProsima SustainML front-end. If not, see <https://www.gnu.org/licenses/>.

/**
 * @file Engine.h
 */

#ifndef _EPROSIMA_SUSTAINML_ENGINE_H
#define _EPROSIMA_SUSTAINML_ENGINE_H

#include <memory>

#include <QQmlApplicationEngine>
#include <QQueue>
#include <QtCharts/QVXYModelMapper>
#include <QThread>
#include <QWaitCondition>

#include <sustainml_cpp/orchestrator/OrchestratorNode.hpp>
#include <sustainml_cpp/types/types.h>

class Engine : public QQmlApplicationEngine,
    public sustainml::orchestrator::OrchestratorNodeHandle,
    public std::enable_shared_from_this<Engine>
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

    /**
     * @brief New node output callback
     * @param   id node identifier
     * @param data data received
     */
    void on_new_node_output(
            const sustainml::NodeID& id,
            void* data) override;

    /**
     * @brief Node status change callback
     *
     * @param id node identifier
     * @param status new status
     */
    void on_node_status_change(
            const sustainml::NodeID& id,
            const types::NodeStatus& status) override;

public slots:

    /**
     * @brief  launch task with user input data
     *
     * @param problem_short_description short description of the problem
     * @param modality modality of the problem
     * @param problem_definition definition of the problem
     * @param inputs inputs of the problem
     * @param outputs outputs of the problem
     * @param minimum_samples minimum samples
     * @param maximum_samples maximum samples
     * @param optimize_carbon_footprint_auto optimize carbon footprint automatically
     * @param optimize_carbon_footprint_manual optimize carbon footprint manually
     * @param previous_iteration previous iteration
     * @param desired_carbon_footprint desired carbon footprint
     * @param geo_location_continent continent of the location
     * @param geo_location_region region of the location
     * @param extra_data extra data
     */
    void launch_task(
            QString problem_short_description,
            QString modality,
            QString problem_definition,
            QString inputs,
            QString outputs,
            int minimum_samples,
            int maximum_samples,
            bool optimize_carbon_footprint_auto,
            bool optimize_carbon_footprint_manual,
            int previous_iteration,
            double desired_carbon_footprint,
            QString geo_location_continent,
            QString geo_location_region,
            QString extra_data);

    /**
     * @brief public method to request all nodes data
     * @param retrieve_all retrieve all data or only last problem received
     */
    void request_current_data (
            const bool& retrieve_all);

signals:

    void task_sent(
            const int& problem_id,
            const int& iteration_id);

    void update_log(
            const QString& log);

    void update_app_requirements_node_status(
            const QString& status);

    void update_carbon_footprint_node_status(
            const QString& status);

    void update_hw_constraints_node_status(
            const QString& status);

    void update_hw_resources_node_status(
            const QString& status);

    void update_ml_model_metadata_node_status(
            const QString& status);

    void update_ml_model_node_status(
            const QString& status);

    void new_app_requirements_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& app_requirements);

    void new_hw_constraints_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& max_memory_footprint);

    void new_ml_model_metadata_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& metadata,
            const QString& keywords);

    void new_ml_model_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& model,
            const QString& model_path,
            const QString& properties,
            const QString& properties_path,
            const QString& input_batch,
            const QString& target_latency);

    void new_hw_resources_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& hw_description,
            const QString& power_consumption,
            const QString& latency,
            const QString& memory_footprint_of_ml_model,
            const QString& max_hw_memory_footprint);

    void new_carbon_footprint_node_output(
            const int& problem_id,
            const int& iteration_id,
            const QString& carbon_footprint,
            const QString& energy_consumption,
            const QString& carbon_intensity);

protected:

    //! Set to true if the engine is being enabled
    bool enabled_;

private:

    QString get_name_from_node_id(
            const sustainml::NodeID& id);

    QString get_task_from_data(
            const sustainml::NodeID& id,
            void* data);

    QString get_status_from_node(
            const types::NodeStatus& status);

    QString get_task_QString(
            const types::TaskId& task_id);

    QString update_node_status(
            const sustainml::NodeID& id,
            const types::NodeStatus& status);

    size_t split_string(
            const std::string& string,
            std::vector<std::string>& string_set,
            char delimeter);

    void print_results(
            const sustainml::NodeID& id,
            void* data,
            const bool& update_logs);

    sustainml::orchestrator::OrchestratorNode* orchestrator;
    std::vector<types::TaskId> received_task_ids;
};

#endif //_EPROSIMA_SUSTAINML_ENGINE_H
