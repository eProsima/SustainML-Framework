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

void Engine::launch_task()
{
    auto task = orchestrator->prepare_new_task();
    task.second->task_id(task.first);
    task.second->problem_definition("Testing task " + get_task_QString(task.first).toStdString());
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
