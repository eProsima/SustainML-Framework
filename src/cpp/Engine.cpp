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

#include <sustainml_frontend/Engine.h>

#include <sustainml_cpp/orchestrator/OrchestratorNode.hpp>
#include <sustainml_cpp/types/types.h>

Engine::Engine()
    : enabled_(false)
{
}

QObject* Engine::enable()
{
    // Initialize orchestrator node
    orchestrator = new sustainml::orchestrator::OrchestratorNode(shared_from_this());

    // Share engine public methods with QML
    rootContext()->setContextProperty("engine", this);

    // Load main GUI
    load(QUrl(QLatin1String("qrc:/qml/main.qml")));

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
        const sustainml::NodeID& /*id*/,
        void* /*data*/)
{
    //std::lock_guard<std::mutex> lock(mtx_);
    //node_data_received_[id].second++;
    //cv_.notify_one();
}

void Engine::on_node_status_change(
        const sustainml::NodeID& /*id*/,
        const types::NodeStatus& /*status*/)
{
    //std::lock_guard<std::mutex> lock(mtx_);
    //node_data_received_[id].first = status.node_status();
    //cv_.notify_one();
}

void Engine::launch_task()
{
    auto task = orchestrator->prepare_new_task();

    task.second->task_id(task.first);
    task.second->problem_description("Testing task " + std::to_string(task.first));
    orchestrator->start_task(task.first, task.second);
}
