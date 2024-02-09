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
    QString log = QString("Received output from node ") + get_name_from_node_id(id);
    emit update_log(log + QString(",\tTask ") + get_task_from_data(id, data));
}

void Engine::on_node_status_change(
        const sustainml::NodeID& id,
        const types::NodeStatus& status)
{
    emit update_log(get_name_from_node_id(id) + QString(" node status changed to ") + update_node_status(id, status));
}

void Engine::launch_task()
{
    auto task = orchestrator->prepare_new_task();

    task.second->task_id(task.first);
    task.second->problem_description("Testing task " + std::to_string(task.first));
    orchestrator->start_task(task.first, task.second);
}

QString Engine::get_name_from_node_id(
        const sustainml::NodeID& id)
{
    switch (id)
    {
        case sustainml::NodeID::ID_TASK_ENCODER:
            return QString("TASK_ENCODER_NODE");
        case sustainml::NodeID::ID_MACHINE_LEARNING:
            return QString("ML_MODEL_NODE");
        case sustainml::NodeID::ID_HARDWARE_RESOURCES:
            return QString("HW_RESOURCES_NODE");
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
            return QString("CO2_TRACKER_NODE");
        case sustainml::NodeID::ID_ORCHESTRATOR:
            return QString("ORCHESTRATOR_NODE");
        default:
            return QString("UNKNOWN");
    }
}

QString Engine::get_task_from_data(
        const sustainml::NodeID& id,
        void* data)
{
    types::UserInput* ui = nullptr;
    types::EncodedTask* encoded = nullptr;
    types::MLModel* ml = nullptr;
    types::HWResource* hw = nullptr;
    types::CO2Footprint* co2 = nullptr;
    switch (id)
    {
        case sustainml::NodeID::ID_TASK_ENCODER:
            encoded = static_cast<types::EncodedTask*>(data);
            return QString::number(encoded->task_id());
        case sustainml::NodeID::ID_MACHINE_LEARNING:
            ml = static_cast<types::MLModel*>(data);
            return QString::number(ml->task_id());
        case sustainml::NodeID::ID_HARDWARE_RESOURCES:
            hw = static_cast<types::HWResource*>(data);
            return QString::number(hw->task_id());
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
            co2 = static_cast<types::CO2Footprint*>(data);
            return QString::number(co2->task_id());
        case sustainml::NodeID::ID_ORCHESTRATOR:
            ui = static_cast<types::UserInput*>(data);
            return QString::number(ui->task_id());
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
            return QString("NODE_INACTIVE");
        case 1u: //Status::NODE_INITIALIZING
            return QString("NODE_INITIALIZING");
        case 2u: //Status::NODE_IDLE
            return QString("NODE_IDLE");
        case 3u: //Status::NODE_RUNNING
            return QString("NODE_RUNNING");
        case 4u: //Status::NODE_ERROR
            return QString("NODE_ERROR");
        case 5u: //Status::NODE_TERMINATING
            return QString("NODE_TERMINATING");
        default:
            return QString("UNKNOWN");
    }
}

QString Engine::update_node_status(
        const sustainml::NodeID& id,
        const types::NodeStatus& status)
{
    QString status_value = get_status_from_node(status);
    switch (id)
    {
        case sustainml::NodeID::ID_TASK_ENCODER:
            emit update_task_encoder_node_status(status_value);
            break;
        case sustainml::NodeID::ID_MACHINE_LEARNING:
            emit update_ml_model_node_status(status_value);
            break;
        case sustainml::NodeID::ID_HARDWARE_RESOURCES:
            emit update_hw_resources_node_status(status_value);
            break;
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
            emit update_co2_footprint_node_status(status_value);
            break;
        default:
            break;
    }
    return status_value;
}
