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

#include <iostream>
#include <memory>

#include <QQmlApplicationEngine>
#include <qqmlcontext.h>
#include <QString>

#include <sustainml/Engine.h>

#include <sustainml_cpp/orchestrator/OrchestratorNode.hpp>
#include <sustainml_cpp/types/types.h>

#define PRINT_STATUS_LOG false

Engine::Engine()
    : enabled_(false)
{
}

QObject* Engine::enable()
{
    // Share engine public methods with QML
    rootContext()->setContextProperty("engine", this);

    // Load main GUI
    load(QUrl(QLatin1String("qrc:/qml/main.qml")));

    // Initialize orchestrator node
    orchestrator = new sustainml::orchestrator::OrchestratorNode(shared_from_this());

    // Set enable as True
    enabled_ = true;

    return rootObjects().value(0);
}

Engine::~Engine()
{
    if  (enabled_)
    {
        delete orchestrator;
    }
}

void Engine::on_new_node_output(
        const sustainml::NodeID& id,
        void* data)
{
    emit update_log(QString("Output received. Task ") + get_task_from_data(id, data) + (",\tnode ") +
            get_name_from_node_id(id));
}

void Engine::on_node_status_change(
        const sustainml::NodeID& id,
        const types::NodeStatus& status)
{
    if (PRINT_STATUS_LOG)
    {
        emit update_log(get_name_from_node_id(id) + QString(" node status changed to ") +
                update_node_status(id, status));
    }
    else
    {
        update_node_status(id, status);
    }
}

void Engine::launch_task(
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
        QString extra_data)
{
    std::vector<std::string> input_set;
    std::vector<std::string> output_set;
    split_string(inputs.toStdString(), input_set, ' ');
    split_string(outputs.toStdString(), output_set, ' ');
    uint32_t min = 1;
    uint32_t max = sizeof(uint32_t)-1;
    if (minimum_samples > 0)
    {
        try
        {
            min = static_cast<uint32_t>(minimum_samples);
        }
        catch (const std::exception& e)
        {
            emit update_log(QString("Error converting minimum samples to uint32_t: ") + e.what());
        }
    }
    else
    {
        emit update_log(QString("Error: minimum samples (") + QString::number(minimum_samples) +
                QString(") must be greater than 0. Using default value " + QString::number(min)));
    }
    if (maximum_samples > 0)
    {
        try
        {
            max = static_cast<uint32_t>(maximum_samples);
        }
        catch (const std::exception& e)
        {
            emit update_log(QString("Error converting maximum samples to uint32_t: ") + e.what());
        }
    }
    else
    {
        emit update_log(QString("Error: maximum samples (") + QString::number(maximum_samples) +
                QString(") must be greater than 0. Using default value " + QString::number(max)));
    }
    std::vector<uint8_t> raw_data(extra_data.toStdString().begin(), extra_data.toStdString().end());

    auto task = orchestrator->prepare_new_task();
    task.second->task_id(task.first);
    task.second->modality(modality.toStdString());
    task.second->problem_short_description(problem_short_description.toStdString());
    task.second->problem_definition(problem_definition.toStdString());
    task.second->inputs(input_set);
    task.second->outputs(output_set);
    task.second->minimum_samples(min);
    task.second->maximum_samples(max);
    task.second->optimize_carbon_footprint_auto(optimize_carbon_footprint_auto);
    task.second->optimize_carbon_footprint_manual(optimize_carbon_footprint_manual);
    task.second->previous_iteration(previous_iteration);
    task.second->desired_carbon_footprint(desired_carbon_footprint);
    task.second->geo_location_continent(geo_location_continent.toStdString());
    task.second->geo_location_region(geo_location_region.toStdString());
    task.second->extra_data(raw_data);
    orchestrator->start_task(task.first, task.second);
}

QString Engine::get_name_from_node_id(
        const sustainml::NodeID& id)
{
    switch (id)
    {
        case sustainml::NodeID::ID_APP_REQUIREMENTS:
            return QString("APP_REQUIREMENTS");
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
            return QString("CARBON_FOOTPRINT");
        case sustainml::NodeID::ID_HW_CONSTRAINTS:
            return QString("HW_CONSTRAINTS");
        case sustainml::NodeID::ID_HW_RESOURCES:
            return QString("HW_RESOURCES");
        case sustainml::NodeID::ID_ML_MODEL:
            return QString("ML_MODEL");
        case sustainml::NodeID::ID_ML_MODEL_METADATA:
            return QString("ML_MODEL_METADATA");
        case sustainml::NodeID::ID_ORCHESTRATOR:
            return QString("ORCHESTRATOR");
        default:
            return QString("UNKNOWN");
    }
}

QString Engine::get_task_from_data(
        const sustainml::NodeID& id,
        void* data)
{
    types::AppRequirements* requirements = nullptr;
    types::CO2Footprint* carbon = nullptr;
    types::HWConstraints* hw_constraints = nullptr;
    types::HWResource* hw_resources = nullptr;
    types::MLModel* model = nullptr;
    types::MLModelMetadata* metadata = nullptr;
    types::UserInput* input = nullptr;

    switch (id)
    {
        case sustainml::NodeID::ID_APP_REQUIREMENTS:
            requirements = static_cast<types::AppRequirements*>(data);
            return get_task_QString(requirements->task_id());
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
            carbon = static_cast<types::CO2Footprint*>(data);
            return get_task_QString(carbon->task_id());
        case sustainml::NodeID::ID_HW_CONSTRAINTS:
            hw_constraints = static_cast<types::HWConstraints*>(data);
            return get_task_QString(hw_constraints->task_id());
        case sustainml::NodeID::ID_HW_RESOURCES:
            hw_resources = static_cast<types::HWResource*>(data);
            return get_task_QString(hw_resources->task_id());
        case sustainml::NodeID::ID_ML_MODEL:
            model = static_cast<types::MLModel*>(data);
            return get_task_QString(model->task_id());
        case sustainml::NodeID::ID_ML_MODEL_METADATA:
            metadata = static_cast<types::MLModelMetadata*>(data);
            return get_task_QString(metadata->task_id());
        case sustainml::NodeID::ID_ORCHESTRATOR:
            input = static_cast<types::UserInput*>(data);
            return get_task_QString(input->task_id());
        default:
            return QString("UNKNOWN");
    }
}

QString Engine::get_status_from_node(
        const types::NodeStatus& status)
{
    switch (status.node_status())
    {
        case 0u: //Status::NODE_INACTIVE
            return QString("INACTIVE");
        case 1u: //Status::NODE_INITIALIZING
            return QString("INITIALIZING");
        case 2u: //Status::NODE_IDLE
            return QString("IDLE");
        case 3u: //Status::NODE_RUNNING
            return QString("RUNNING");
        case 4u: //Status::NODE_ERROR
            return QString("ERROR");
        case 5u: //Status::NODE_TERMINATING
            return QString("TERMINATING");
        default:
            return QString("UNKNOWN");
    }
}

QString Engine::get_task_QString(
        const types::TaskId& task_id)
{
    return QString("Task {") + QString::number(task_id.problem_id()) + QString(",") +
            QString::number(task_id.data_id()) + QString("}");
}

QString Engine::update_node_status(
        const sustainml::NodeID& id,
        const types::NodeStatus& status)
{
    QString status_value = get_status_from_node(status);
    switch (id)
    {
        case sustainml::NodeID::ID_APP_REQUIREMENTS:
            emit update_app_requirements_node_status(status_value);
            break;
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
            emit update_carbon_footprint_node_status(status_value);
            break;
        case sustainml::NodeID::ID_HW_CONSTRAINTS:
            emit update_hw_constraints_node_status(status_value);
            break;
        case sustainml::NodeID::ID_HW_RESOURCES:
            emit update_hw_resources_node_status(status_value);
            break;
        case sustainml::NodeID::ID_ML_MODEL:
            emit update_ml_model_node_status(status_value);
            break;
        case sustainml::NodeID::ID_ML_MODEL_METADATA:
            emit update_ml_model_metadata_node_status(status_value);
            break;
        default:
            break;
    }
    return status_value;
}

size_t Engine::split_string(
        const std::string& string,
        std::vector<std::string>& string_set,
        char delimeter)
{
    size_t position = string.find(delimeter);
    size_t initial_position = 0;
    string_set.clear();

    // Split loop
    while (position != std::string::npos)
    {
        string_set.push_back(string.substr(initial_position, position - initial_position));
        initial_position = position + 1;
        position = string.find(delimeter, initial_position);
    }
    string_set.push_back(string.substr(initial_position, std::min(position, string.size()) - initial_position + 1));

    return string_set.size();
}
