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
 * @file utils.hpp
 *
 */

#ifndef EPROSIMA_SUSTAINML_UTILS_HPP
#define EPROSIMA_SUSTAINML_UTILS_HPP

#include <QString>
#include <QJsonObject>

#include <sustainml_cpp/core/Constants.hpp>
#include <sustainml_cpp/types/types.hpp>

class Utils
{

public:

    Utils() = delete;

    /**
     * @brief Get the node id from node name
     *
     * @param name QString node name
     * @return sustainml::NodeID Node ID
     */
    static sustainml::NodeID node_id(
            const QString& name)
    {
        if (name == QString("APP_REQUIREMENTS"))
        {
            return sustainml::NodeID::ID_APP_REQUIREMENTS;
        }
        else if (name == QString("CARBON_FOOTPRINT"))
        {
            return sustainml::NodeID::ID_CARBON_FOOTPRINT;
        }
        else if (name == QString("HW_CONSTRAINTS"))
        {
            return sustainml::NodeID::ID_HW_CONSTRAINTS;
        }
        else if (name == QString("HW_RESOURCES"))
        {
            return sustainml::NodeID::ID_HW_RESOURCES;
        }
        else if (name == QString("ML_MODEL"))
        {
            return sustainml::NodeID::ID_ML_MODEL;
        }
        else if (name == QString("ML_MODEL_METADATA"))
        {
            return sustainml::NodeID::ID_ML_MODEL_METADATA;
        }
        else if (name == QString("ORCHESTRATOR"))
        {
            return sustainml::NodeID::ID_ORCHESTRATOR;
        }
        else
        {
            return sustainml::NodeID::UNKNOWN;
        }
    }

    /**
     * @brief Get the node from json object
     *
     * @param json JSON object
     * @return sustainml::NodeID Node ID
     */
    static sustainml::NodeID node_id(
            const QJsonObject& json)
    {
        if (json.keys().size() == 1)
        {
            return node_id(json.keys()[0]);
        }
        else
        {
            return sustainml::NodeID::UNKNOWN;
        }
    }

    /**
     * @brief Get the name from node id object
     *
     * @param id NodeID object
     * @return QString Node name
     */
    static QString node_name(
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

    /**
     * @brief Get the task id from json object
     *
     * @param json JSON object
     * @return types::TaskId Task ID
     */
    static types::TaskId task_id(
            const QJsonObject& json)
    {
        if (json.contains("task_id"))
        {
            QJsonObject task_id = json.value("task_id").toObject();
            return types::TaskId(task_id.value("problem_id").toInt(), task_id.value("iteration_id").toInt());
        }
        else
        {
            // Invalid Task ID
            return types::TaskId();
        }
    }

    /**
     * @brief Get the task QString
     *
     * @param task_id types::TaskId task_id object
     * @return QString Task QString
     */
    static QString task_string(
            const types::TaskId task_id)
    {
        // Check if invalid task id
        if (types::TaskId() == task_id)
        {
            return QString("Invalid Task");
        }
        return QString("Task {") + QString::number(task_id.problem_id()) + QString(",") +
               QString::number(task_id.iteration_id()) + QString("}");
    }

    /**
     * @brief Split a string into a QJsonArray
     *
     * @param string String to split
     * @param string_array QJsonArray to store the split strings
     * @param delimeter Delimeter to split the string
     * @return size_t Number of strings in the QJsonArray
     */
    static size_t split_string(
            const std::string& string,
            QJsonArray& string_array,
            char delimeter)
    {
        size_t position = string.find(delimeter);
        size_t initial_position = 0;

        // Split loop
        while (position != std::string::npos)
        {
            string_array.push_back(string.substr(initial_position, position - initial_position).c_str());
            initial_position = position + 1;
            position = string.find(delimeter, initial_position);
        }
        string_array.push_back(string.substr(initial_position, std::min(position,
                string.size()) - initial_position + 1).c_str());

        return string_array.size();
    }
};

#endif //EPROSIMA_SUSTAINML_UTILS_HPP

