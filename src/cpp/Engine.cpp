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

#include <iostream>
#include <memory>

#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkReply>
#include <QQmlApplicationEngine>
#include <qqmlcontext.h>
#include <QString>
#include <QUrl>

#include <sustainml/Engine.hpp>
#include <sustainml/Utils.hpp>

#include <sustainml_cpp/types/types.hpp>

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

    // Initialize user input request manager
    user_input_request_ = new QNetworkAccessManager(this);
    connect(user_input_request_, SIGNAL(finished(QNetworkReply*)), this, SLOT(user_input_response(QNetworkReply*)));

    // Initialize node responses
    for (size_t i = 0; i < static_cast<size_t>(sustainml::NodeID::MAX); ++i)
    {
        node_responses_[i] = new QNetworkAccessManager(this);
        connect(node_responses_[i], SIGNAL(finished(QNetworkReply*)), this, SLOT(node_response(QNetworkReply*)));
    }

    // Set enable as True
    enabled_ = true;

    return rootObjects().value(0);
}

Engine::~Engine()
{
    delete user_input_request_;
    for (size_t i = 0; i < static_cast<size_t>(sustainml::NodeID::MAX); ++i)
    {
        delete node_responses_[i];
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
        QString /*extra_data_*/)
{
    QJsonArray ins;
    QJsonArray outs;
    Utils::split_string(inputs.toStdString(), ins, ' ');
    Utils::split_string(outputs.toStdString(), outs, ' ');

    uint32_t min = 1;
    uint32_t max = sizeof(uint32_t) - 1;
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
    //std::vector<uint8_t> raw_data(extra_data_.toStdString().begin(), extra_data_.toStdString().end());

    // Prepare user input request
    QString query_url_ = server_url_ + "/user_input";
    QUrl url(query_url_.toStdString().c_str());
    QNetworkRequest ui_request(url);
    ui_request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject extra_data;
    extra_data["hardware_required"] = "PIM_AI_1chip";
    extra_data["max_memory_footprint"] = 100;
    QJsonObject json_data;
    json_data["problem_short_description"] = problem_short_description;
    json_data["modality"] = modality;
    json_data["problem_definition"] = problem_definition;
    json_data["inputs"] = ins;
    json_data["outputs"] = outs;
    json_data["minimum_samples"] = int(min);
    json_data["maximum_samples"] = int(max);
    json_data["optimize_carbon_footprint_auto"] = optimize_carbon_footprint_auto;
    json_data["optimize_carbon_footprint_manual"] = optimize_carbon_footprint_manual;
    json_data["previous_iteration"] = previous_iteration;
    json_data["desired_carbon_footprint"] = desired_carbon_footprint;
    json_data["geo_location_continent"] = geo_location_continent;
    json_data["geo_location_region"] = geo_location_region;
    json_data["extra_data"] = extra_data;
    QJsonDocument doc(json_data);
    QByteArray json_data_bytes = doc.toJson();

    // Launch user input request
    user_input_request_->post(ui_request, json_data_bytes);
}

void Engine::user_input_response(
        QNetworkReply* reply_)
{
    QJsonDocument json_doc = QJsonDocument::fromJson(reply_->readAll());
    QJsonObject json_obj = json_doc.object();
    if (!json_obj.empty())
    {
        types::TaskId* task_id = get_task_from_json(json_obj);
        if (nullptr == task_id)
        {
            emit update_log(QString("Error: task id is nullptr"));
        }
        else
        {
            received_task_ids.push_back(task_id);
            emit task_sent(static_cast<int>(task_id->problem_id()), static_cast<int>(task_id->iteration_id()));
        }
        // Request results for all nodes, last task id
        request_results(*task_id, sustainml::NodeID::MAX);
        emit update_log(QString("User input send for ") + get_task_QString(task_id));
    }
    reply_->deleteLater();
}

void Engine::node_response(
        QNetworkReply* reply_)
{
    QJsonDocument json_doc = QJsonDocument::fromJson(reply_->readAll());
    QJsonObject json_obj = json_doc.object();
    if (!json_obj.empty())
    {
        // specialized method to print results
        print_results(get_node_from_json(json_obj), json_obj);
    }
    reply_->deleteLater();
}

void Engine::request_current_data(
        const bool& retrieve_all)
{
    void * data = nullptr;
    int iterator_start = received_task_ids.size() == 0 ? 0 : received_task_ids.size() - 1;
    if (retrieve_all)
    {
        iterator_start = 0;
    }

    for (int i = iterator_start; i < received_task_ids.size(); i++)
    {
        // Request results for all nodes, for the given task ids
        request_results(*(received_task_ids.at(i)), sustainml::NodeID::MAX);
    }
}

void Engine::request_results(
        const types::TaskId& task_id,
        const sustainml::NodeID& node_id)
{
    // Node results requests
    QString node_query_url_ = server_url_ + "/results";
    QUrl node_url(node_query_url_.toStdString().c_str());
    std::array<QNetworkRequest, static_cast<size_t>(sustainml::NodeID::MAX)> requests;
    std::array<QByteArray, static_cast<size_t>(sustainml::NodeID::MAX)> node_raw_data;
    QJsonObject task_json;
    task_json["problem_id"] = static_cast<int>(task_id.problem_id());
    task_json["iteration_id"] = static_cast<int>(task_id.iteration_id());

    // Determine the iteration to request
    size_t initial = 0;
    size_t final = static_cast<size_t>(sustainml::NodeID::MAX);
    // Request all node data
    if (sustainml::NodeID::MAX != node_id)
    {
        initial = static_cast<size_t>(node_id);
        final = initial + 1;
    }
    // Launch node result requests
    if (sustainml::NodeID::UNKNOWN != node_id)
    {
        for (size_t i = initial; i < final; ++i)
        {
            QJsonObject node_json_data;
            node_json_data["node_id"] = static_cast<int>(i);
            node_json_data["task_id"] = task_json;
            QJsonDocument node_doc(node_json_data);
            node_raw_data[i] = node_doc.toJson();
            requests[i].setUrl(node_url);
            requests[i].setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

            // Launch node results requests
            node_responses_[i]->post(requests[i], node_raw_data[i]);
        }
    }
}

void Engine::print_results(
        const sustainml::NodeID& id,
        const QJsonObject& json_obj)
{
    QJsonObject node_json = json_obj[Utils::node_name(id)].toObject();
    types::TaskId task_id = Utils::task_id(node_json);
    switch (id)
    {
        case sustainml::NodeID::ID_APP_REQUIREMENTS:
        {
            emit new_app_requirements_node_output(
                task_id.problem_id(),
                task_id.iteration_id(),
                node_json["app_requirements"].toString());
            break;
        }
        case sustainml::NodeID::ID_CARBON_FOOTPRINT:
        {
            emit new_carbon_footprint_node_output(
                task_id.problem_id(),
                task_id.iteration_id(),
                QString::number(node_json["carbon_footprint"].toDouble()),
                QString::number(node_json["energy_consumption"].toDouble()),
                QString::number(node_json["carbon_intensity"].toDouble()));
            break;
        }
        case sustainml::NodeID::ID_HW_CONSTRAINTS:
        {
            emit new_hw_constraints_node_output(
                task_id.problem_id(),
                task_id.iteration_id(),
                node_json["hardware_required"].toString(),
                QString::number(node_json["max_memory_footprint"].toInt()));
            break;
        }
        case sustainml::NodeID::ID_HW_RESOURCES:
        {
            emit new_hw_resources_node_output(
                task_id.problem_id(),
                task_id.iteration_id(),
                node_json["hw_description"].toString(),
                QString::number(node_json["power_consumption"].toDouble()),
                QString::number(node_json["latency"].toDouble()),
                QString::number(node_json["memory_footprint_of_ml_model"].toDouble()),
                QString::number(node_json["max_hw_memory_footprint"].toDouble()));
            break;
        }
        case sustainml::NodeID::ID_ML_MODEL:
        {
            QJsonArray input_batch = node_json["input_batch"].toArray();
            QString list_of_inputs = "";
            for (QJsonValue input : input_batch)
            {
                if (!list_of_inputs.isEmpty())
                {
                    list_of_inputs += QString(", ");
                }
                list_of_inputs += input.toString();
            }
            emit new_ml_model_node_output(
                task_id.problem_id(),
                task_id.iteration_id(),
                node_json["model"].toString(),
                node_json["model_path"].toString(),
                node_json["model_properties"].toString(),
                node_json["model_properties_path"].toString(),
                list_of_inputs,
                QString::number(node_json["target_latency"].toDouble()));
            break;
        }
        case sustainml::NodeID::ID_ML_MODEL_METADATA:
        {
            QJsonArray keywords = node_json["keywords"].toArray();
            QString list_of_keywords = "";
            for (QJsonValue keyword : keywords)
            {
                if (!list_of_keywords.isEmpty())
                {
                    list_of_keywords += QString(", ");
                }
                list_of_keywords += keyword.toString();
            }
            emit new_ml_model_metadata_node_output(
                task_id.problem_id(),
                task_id.iteration_id(),
                list_of_keywords,
                node_json["metadata"].toString());
            break;
        }
        default:
            break;
    }
    emit update_log(QString("Output received. ") + Utils::task_string(task_id) + QString(",node ") +
            Utils::node_name(id) + QString(":\n") + Utils::raw_output(json_obj));
}

QString Engine::get_raw_output(
        const QJsonObject& json_obj)
{
    QString output = "";

    if (json_obj.contains(get_name_from_node_id(sustainml::NodeID::ID_APP_REQUIREMENTS)))
    {
        QJsonObject node_json = json_obj[get_name_from_node_id(sustainml::NodeID::ID_APP_REQUIREMENTS)].toObject();
        output += "App requirements: ";
        output += node_json["app_requirements"].toString() + QString("\n");
    }
    if (json_obj.contains(get_name_from_node_id(sustainml::NodeID::ID_CARBON_FOOTPRINT)))
    {
        QJsonObject node_json = json_obj[get_name_from_node_id(sustainml::NodeID::ID_CARBON_FOOTPRINT)].toObject();
        output += QString("Carbon footprint: ") + QString::number(node_json["carbon_footprint"].toDouble()) + QString(
            "\n");
        output += QString("Energy consumption: ") + QString::number(node_json["energy_consumption"].toDouble()) +
                QString("\n");
        output += QString("Carbon intensity: ") + QString::number(node_json["carbon_intensity"].toDouble()) + QString(
            "\n");
    }
    if (json_obj.contains(get_name_from_node_id(sustainml::NodeID::ID_HW_CONSTRAINTS)))
    {
        QJsonObject node_json = json_obj[get_name_from_node_id(sustainml::NodeID::ID_HW_CONSTRAINTS)].toObject();
        output += QString("Max memory footprint: ") + QString::number(node_json["max_memory_footprint"].toInt()) +
                QString("\n");
        output += "Hardware required: ";
        output += node_json["hardware_required"].toString() + QString("\n");
    }
    if (json_obj.contains(get_name_from_node_id(sustainml::NodeID::ID_HW_RESOURCES)))
    {
        QJsonObject node_json = json_obj[get_name_from_node_id(sustainml::NodeID::ID_HW_RESOURCES)].toObject();
        output += QString("Hardware description: ") + node_json["hw_description"].toString() + QString("\n");
        output += QString("Power consumption: ") + QString::number(node_json["power_consumption"].toDouble()) + QString(
            "\n");
        output += QString("Latency: ") + QString::number(node_json["latency"].toDouble()) + QString("\n");
        output += QString("Model memory footprint: ") + QString::number(
            node_json["memory_footprint_of_ml_model"].toDouble()) + QString("\n");
        output += QString("Max hardware memory footprint: ") + QString::number(
            node_json["max_hw_memory_footprint"].toDouble()) + QString("\n");
    }
    if (json_obj.contains(get_name_from_node_id(sustainml::NodeID::ID_ML_MODEL)))
    {
        QJsonObject node_json = json_obj[get_name_from_node_id(sustainml::NodeID::ID_ML_MODEL)].toObject();
        output += QString("Model path: ") + node_json["model_path"].toString() + QString("\n");
        output += QString("Model: ") + node_json["model"].toString() + QString("\n");
        output += QString("Model properties path: ") + node_json["model_properties_path"].toString() + QString("\n");
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
    if (json_obj.contains(get_name_from_node_id(sustainml::NodeID::ID_ML_MODEL_METADATA)))
    {
        QJsonObject node_json = json_obj[get_name_from_node_id(sustainml::NodeID::ID_ML_MODEL_METADATA)].toObject();
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

// ---------------------- Helper methods ----------------------
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

sustainml::NodeID Engine::get_node_id_from_name(
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

sustainml::NodeID Engine::get_node_from_json(
        const QJsonObject& json)
{

    if (json.keys().size() == 1)
    {
        return get_node_id_from_name(json.keys()[0]);
    }
    else
    {
        return sustainml::NodeID::UNKNOWN;
    }
}

types::TaskId* Engine::get_task_from_json(
        const QJsonObject& json)
{
    if (json.contains("task_id"))
    {
        QJsonObject task_id = json["task_id"].toObject();
        return new types::TaskId(task_id["problem_id"].toInt(), task_id["iteration_id"].toInt());
    }
    else
    {
        return nullptr;
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
        const types::TaskId* task_id)
{
    if (nullptr == task_id)
    {
        return QString("Task {nullptr}");
    }
    return QString("Task {") + QString::number(task_id->problem_id()) + QString(",") +
           QString::number(task_id->iteration_id()) + QString("}");
    // TODO define which task representation is the correct one
    //if (nullptr == task_id)
    //{
    //    return QString("Problem ID: nullptr, Iteration ID: nullptr");
    //}
    //return QString("Problem ID: ") + QString::number(task_id->problem_id()) + QString(", Iteration ID: ") +
    //        QString::number(task_id->iteration_id());
}

size_t Engine::split_string(
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
