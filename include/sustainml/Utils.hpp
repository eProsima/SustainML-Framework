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
     * @brief Get the name from node json object
     *
     * @param json JSON object
     * @return QString Node name
     */
    static QString node_name(
            const QJsonObject& json)
    {
        return node_name(node_id(json));
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
        // TODO define which task representation is the correct one
        //if (types::TaskId() == task_id)
        //{
        //    return QString("Problem ID: invalid, Iteration ID: invalid");
        //}
        //return QString("Problem ID: ") + QString::number(task_id.problem_id()) + QString(", Iteration ID: ") +
        //        QString::number(task_id.iteration_id());
    }

    /**
     * @brief Get the task from json object
     *
     * @param json JSON object
     * @return QString Task ID
     */
    static QString task_string(
            const QJsonObject& json)
    {
        if (json.contains("task_id"))
        {
            QJsonObject task_id = json["task_id"].toObject();
            return task_string(types::TaskId(task_id.value("problem_id").toInt(),
                           task_id.value("iteration_id").toInt()));
        }
        else
        {
            return QString("UNKNOWN");
        }
    }

    /**
     * @brief  Get the status from json object
     *
     * @param json JSON object
     * @return int Node status. If not found, return -1
     */
    static int status(
            const QJsonObject& json)
    {
        if (json.contains("status"))
        {
            return json["status"].toInt();
        }
        else
        {
            return -1;
        }
    }

    /**
     * @brief Get the status as a string from value
     *
     * @param status NodeStatus object
     * @return QString Node status
     */
    static QString status_string(
            const QJsonObject& json)
    {
        switch (status(json))
        {
            case static_cast<int>(0): // Status::NODE_INACTIVE:
                return QString("INACTIVE");
            case static_cast<int>(1): // Status::NODE_ERROR:
                return QString("ERROR");
            case static_cast<int>(2): // Status::NODE_IDLE:
                return QString("IDLE");
            case static_cast<int>(3): // Status::NODE_INITIALIZING:
                return QString("INITIALIZING");
            case static_cast<int>(4): // Status::NODE_RUNNING:
                return QString("RUNNING");
            case static_cast<int>(5): // Status::NODE_TERMINATING:
                return QString("TERMINATING");
            default:
                return QString("UNKNOWN");
        }
    }

    /**
     * @brief Get the raw output from json object
     *
     * @param json JSON object
     * @return QString Raw output
     */
    static QString raw_output(
            const QJsonObject& json)
    {
        QString output = "";

        if (json.contains(Utils::node_name(sustainml::NodeID::ID_APP_REQUIREMENTS)))
        {
            QJsonObject node_json = json[Utils::node_name(sustainml::NodeID::ID_APP_REQUIREMENTS)].toObject();
            output += "App requirements: ";
            output += node_json["app_requirements"].toString() + QString("\n");
        }
        if (json.contains(Utils::node_name(sustainml::NodeID::ID_CARBON_FOOTPRINT)))
        {
            QJsonObject node_json = json[Utils::node_name(sustainml::NodeID::ID_CARBON_FOOTPRINT)].toObject();
            output += QString("Carbon footprint: ") + QString::number(node_json["carbon_footprint"].toDouble()) +
                    QString(
                "\n");
            output += QString("Energy consumption: ") + QString::number(node_json["energy_consumption"].toDouble()) +
                    QString("\n");
            output += QString("Carbon intensity: ") + QString::number(node_json["carbon_intensity"].toDouble()) +
                    QString(
                "\n");
        }
        if (json.contains(Utils::node_name(sustainml::NodeID::ID_HW_CONSTRAINTS)))
        {
            QJsonObject node_json = json[Utils::node_name(sustainml::NodeID::ID_HW_CONSTRAINTS)].toObject();
            output += QString("Max memory footprint: ") + QString::number(node_json["max_memory_footprint"].toInt()) +
                    QString("\n");
            output += "Hardware required: ";
            output += node_json["hardware_required"].toString() + QString("\n");
        }
        if (json.contains(Utils::node_name(sustainml::NodeID::ID_HW_RESOURCES)))
        {
            QJsonObject node_json = json[Utils::node_name(sustainml::NodeID::ID_HW_RESOURCES)].toObject();
            output += QString("Hardware description: ") + node_json["hw_description"].toString() + QString("\n");
            output += QString("Power consumption: ") + QString::number(node_json["power_consumption"].toDouble()) +
                    QString(
                "\n");
            output += QString("Latency: ") + QString::number(node_json["latency"].toDouble()) + QString("\n");
            output += QString("Model memory footprint: ") + QString::number(
                node_json["memory_footprint_of_ml_model"].toDouble()) + QString("\n");
            output += QString("Max hardware memory footprint: ") + QString::number(
                node_json["max_hw_memory_footprint"].toDouble()) + QString("\n");
        }
        if (json.contains(Utils::node_name(sustainml::NodeID::ID_ML_MODEL)))
        {
            QJsonObject node_json = json[Utils::node_name(sustainml::NodeID::ID_ML_MODEL)].toObject();
            output += QString("Model path: ") + node_json["model_path"].toString() + QString("\n");
            output += QString("Model: ") + node_json["model"].toString() + QString("\n");
            output += QString("Model properties path: ") + node_json["model_properties_path"].toString() +
                    QString("\n");
            output += QString("Model properties: ") + node_json["model_properties"].toString() + QString("\n");
            output += "Input batch: ";
            QJsonArray input_batch = node_json["input_batch"].toArray();
            for (QJsonValue input : input_batch)
            {
                output += input.toString() + QString(", ");
            }
            output += QString("\nTarget latency: ") + QString::number(node_json["target_latency"].toDouble()) +
                    QString("\n");
        }
        if (json.contains(Utils::node_name(sustainml::NodeID::ID_ML_MODEL_METADATA)))
        {
            QJsonObject node_json = json[Utils::node_name(sustainml::NodeID::ID_ML_MODEL_METADATA)].toObject();
            output += "Key words: ";
            QJsonArray keywords = node_json["keywords"].toArray();
            for (QJsonValue keyword : keywords)
            {
                output += keyword.toString() + QString(", ");
            }
            output += "\nMetadata: ";
            output += node_json["metadata"].toString() + QString("\n");
        }
        return output;
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

