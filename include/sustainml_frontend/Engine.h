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
     *
     * @param id node identifier
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
     * @brief  launch dummy task
     *
     */
    void launch_task();

signals:

    void update_log(
            const QString& log);

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

    sustainml::orchestrator::OrchestratorNode* orchestrator;
};

#endif //_EPROSIMA_SUSTAINML_ENGINE_H
