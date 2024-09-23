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
            get_name_from_node_id(id) + ":\n" + get_raw_output(id, data));
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
        case static_cast<Status>(0): // Status::NODE_INACTIVE:
            return QString("INACTIVE");
        case static_cast<Status>(1): // Status::NODE_ERROR:
            return QString("ERROR");
        case static_cast<Status>(2): // Status::NODE_IDLE:
            return QString("IDLE");
        case static_cast<Status>(3): // Status::NODE_INITIALIZING:
            return QString("INITIALIZING");
        case static_cast<Status>(4): // Status::NODE_RUNNING:
            return QString("RUNNING");
        case static_cast<Status>(5): // Status::NODE_TERMINATING:
            return QString("TERMINATING");
        default:
            return QString("UNKNOWN");
    }
}

QString Engine::get_task_QString(
        const types::TaskId& task_id)
{
    return QString("Task {") + QString::number(task_id.problem_id()) + QString(",") +
            QString::number(task_id.iteration_id()) + QString("}");
}

QString Engine::get_raw_output(
        const sustainml::NodeID& id,
        void* data)
{
    QString output = "";
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
            output += "App requirements: ";
            for (std::string req : requirements->app_requirements())
            {
                output += QString::fromStdString(req) + QString(", ");
            }
            output += "\n";
            return output;
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
            carbon = static_cast<types::CO2Footprint*>(data);
            output += QString("Carbon footprint: ") + QString::number(carbon->carbon_footprint()) + QString("\n");
            output += QString("Energy consumption: ") + QString::number(carbon->energy_consumption()) + QString("\n");
            output += QString("Carbon intensity: ") + QString::number(carbon->carbon_intensity()) + QString("\n");
            return output;
        case sustainml::NodeID::ID_HW_CONSTRAINTS:
            hw_constraints = static_cast<types::HWConstraints*>(data);
            output += QString("Max memory footprint: ") + QString::number(hw_constraints->max_memory_footprint()) +
                    QString("\n");
            return output;
        case sustainml::NodeID::ID_HW_RESOURCES:
            hw_resources = static_cast<types::HWResource*>(data);
            output += QString("Hardware description: ") +
                    QString::fromStdString(hw_resources->hw_description()) + QString("\n");
            output += QString("Power consumption: ") +
                    QString::number(hw_resources->power_consumption()) + QString("\n");
            output += QString("Latency: ") + QString::number(hw_resources->latency()) + QString("\n");
            output += QString("Model memory footprint: ") +
                    QString::number(hw_resources->memory_footprint_of_ml_model()) + QString("\n");
            output += QString("Max hardware memory footprint: ") +
                    QString::number(hw_resources->max_hw_memory_footprint()) + QString("\n");
            return output;
        case sustainml::NodeID::ID_ML_MODEL:
            model = static_cast<types::MLModel*>(data);
            output += QString("Model path: ") + QString::fromStdString(model->model_path()) + QString("\n");
            output += QString("Model: ") + QString::fromStdString(model->model()) + QString("\n");
            output += QString("Model properties path: ") +
                    QString::fromStdString(model->model_properties_path()) + QString("\n");
            output += QString("Model properties: ") + QString::fromStdString(model->model_properties()) + QString("\n");
            output += "Input batch: ";
            for (std::string input : model->input_batch())
            {
                output += QString::fromStdString(input) + QString(", ");
            }
            output += QString("\nTarget latency: ") + QString::number(model->target_latency()) + QString("\n");
            return output;
        case sustainml::NodeID::ID_ML_MODEL_METADATA:
            metadata = static_cast<types::MLModelMetadata*>(data);
            output += "Key words: ";
            for (std::string keyword : metadata->keywords())
            {
                output += QString::fromStdString(keyword) + QString(", ");
            }
            output += "\nMetadata: ";
            for (std::string meta : metadata->ml_model_metadata())
            {
                output += QString::fromStdString(meta) + QString(", ");
            }
            output += "\n";
            return output;
        case sustainml::NodeID::ID_ORCHESTRATOR:
            input = static_cast<types::UserInput*>(data);
            output += QString("Problem short description: ") +
                    QString::fromStdString(input->problem_short_description()) + QString("\n");
            output += QString("Problem definition: ") +
                    QString::fromStdString(input->problem_definition()) + QString("\n");
            output += QString("Modality: ") + QString::fromStdString(input->modality()) + QString("\n");
            output += QString("Inputs: ");
            for (std::string in : input->inputs())
            {
                output += QString::fromStdString(in) + QString(", ");
            }
            output += "\nOutputs: ";
            for (std::string out : input->outputs())
            {
                output += QString::fromStdString(out) + QString(", ");
            }
            output += QString("\nMin samples: ") + QString::number(input->minimum_samples()) + QString("\n");
            output += QString("Max samples: ") + QString::number(input->maximum_samples()) + QString("\n");
            output += QString("Optimize automatically: ") +
                    (input->optimize_carbon_footprint_auto() ? QString("true\n") : QString("false\n"));
            output += QString("Optimize manually: ") +
                    (input->optimize_carbon_footprint_manual() ? QString("true\n") : QString("false\n"));
            output += QString("Previous iteration: ") + QString::number(input->previous_iteration()) + QString("\n");
            output += QString("Desired carbon footprint: ") +
                    QString::number(input->desired_carbon_footprint()) + QString("\n");
            output += QString("Geo location continent: ") +
                    QString::fromStdString(input->geo_location_continent()) + QString("\n");
            output += QString("Geo location region: ") +
                    QString::fromStdString(input->geo_location_region()) + QString("\n");
            return output;
        default:
            return QString("Unknown node output\n");
    }
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
