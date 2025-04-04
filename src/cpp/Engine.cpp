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
#include <sustainml/REST_requester.hpp>
#include <sustainml/Utils.hpp>

#include <sustainml_cpp/types/types.hpp>

#define PRINT_STATUS_LOG false

Engine::Engine()
    : enabled_(false)
{
    node_status_timer_ = new QTimer(this);
    node_status_timer_->setInterval(500);
    connect(node_status_timer_, SIGNAL(timeout()), this, SLOT(request_status()));
}

QObject* Engine::enable()
{
    // Share engine public methods with QML
    rootContext()->setContextProperty("engine", this);

    // Load main GUI
    load(QUrl(QLatin1String("qrc:/qml/main.qml")));

    // Set enable as True
    enabled_ = true;

    // Start timer
    node_status_timer_->start();

    // Request modalities
    request_modalities();

    return rootObjects().value(0);
}

Engine::~Engine()
{
    node_status_timer_->stop();
    node_status_timer_->disconnect();
    node_status_timer_->deleteLater();
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
        int max_memory_footprint,
        QString hardware_required,
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

    QJsonObject extra_data;
    extra_data["hardware_required"] = hardware_required;
    extra_data["max_memory_footprint"] = max_memory_footprint;
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

    // Launch user input request
    user_input_request(json_data);
}

void Engine::request_current_data(
        const bool& retrieve_all)
{
    void* data = nullptr;
    int iterator_start = received_task_ids.size() == 0 ? 0 : received_task_ids.size() - 1;
    if (retrieve_all)
    {
        iterator_start = 0;
    }

    for (int i = iterator_start; i < received_task_ids.size(); i++)
    {
        // Request results for all nodes, for the given task ids
        request_results(received_task_ids.at(i), sustainml::NodeID::MAX);
    }
}

void Engine::request_status()
{
    node_status_request(QJsonObject());
}

void Engine::request_modalities()
{
    QJsonObject json_config;
    json_config["node_id"] = 4;
    json_config["transaction_id"] = 0;
    json_config["configuration"] = "modality";

    config_request(json_config, [this](const QJsonObject& json_obj) {
        QJsonObject response_obj = json_obj["response"].toObject();
        if (response_obj.contains("configuration") && response_obj["configuration"].isString())
        {
            QJsonDocument config_doc = QJsonDocument::fromJson(response_obj["configuration"].toString().toUtf8());
            if (config_doc.isObject())
            {
                QJsonObject config_obj = config_doc.object();
                if (config_obj.contains("modalities") && config_obj["modalities"].isString())
                {
                    QStringList modalities = config_obj["modalities"].toString().split(", ");
                    emit modalities_available(modalities);
                }
            }
        }
    });
}

void Engine::request_results(
        const types::TaskId& task_id,
        const sustainml::NodeID& node_id)
{
    // Node results requests
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
            node_results_request(node_json_data);
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

void Engine::user_input_request(
        const QJsonObject& json_obj)
{
    REST_requester* requester = new REST_requester(
        std::bind(&Engine::user_input_response, this, std::placeholders::_1, std::placeholders::_2),
        REST_requester::RequestType::SEND_USER_INPUT,
        json_obj);

    {
        std::lock_guard<std::mutex> lock(requesters_mutex_);
        requesters_.push_back(requester);
    }
}

void Engine::user_input_response(
        const REST_requester* requester,
        const QJsonObject& json_obj)
{
    if (!json_obj.empty())
    {
        types::TaskId task_id = Utils::task_id(json_obj);
        if (types::TaskId() == task_id)
        {
            emit update_log(QString("Error: task id is invalid"));
        }
        else
        {
            received_task_ids.push_back(task_id);
            emit task_sent(static_cast<int>(task_id.problem_id()), static_cast<int>(task_id.iteration_id()));
        }
        // Request results for all nodes, last task id
        request_results(task_id, sustainml::NodeID::MAX);
        emit update_log(QString("User input send for ") + Utils::task_string(task_id));
    }
    // Remove REST requester from queue
    std::lock_guard<std::mutex> lock(requesters_mutex_);
    for (auto it = requesters_.begin(); it != requesters_.end(); ++it)
    {
        if (*it == requester)
        {
            auto ptr = *it;
            requesters_.erase(it);
            (ptr)->disconnect();
            (ptr)->deleteLater();
            break;
        }
    }
}

void Engine::node_results_request(
        const QJsonObject& json_obj)
{
    REST_requester* requester = new REST_requester(
        std::bind(&Engine::node_results_response, this, std::placeholders::_1, std::placeholders::_2),
        REST_requester::RequestType::REQUEST_RESULTS,
        json_obj);

    {
        std::lock_guard<std::mutex> lock(requesters_mutex_);
        requesters_.push_back(requester);
    }
}

void Engine::node_results_response(
        const REST_requester* requester,
        const QJsonObject& json_obj)
{
    if (!json_obj.empty())
    {
        // specialized method to print results
        print_results(Utils::node_id(json_obj), json_obj);
    }
    // Remove REST requester from queue
    std::lock_guard<std::mutex> lock(requesters_mutex_);
    for (auto it = requesters_.begin(); it != requesters_.end(); ++it)
    {
        if (*it == requester)
        {
            auto ptr = *it;
            requesters_.erase(it);
            (ptr)->disconnect();
            (ptr)->deleteLater();
            break;
        }
    }
}

void Engine::node_status_request(
        const QJsonObject& json_obj)
{
    REST_requester* requester = new REST_requester(
        std::bind(&Engine::node_status_response, this, std::placeholders::_1, std::placeholders::_2),
        REST_requester::RequestType::REQUEST_NODE_STATUS,
        json_obj);

    {
        std::lock_guard<std::mutex> lock(requesters_mutex_);
        requesters_.push_back(requester);
    }
}

void Engine::node_status_response(
        const REST_requester* requester,
        const QJsonObject& json_obj)
{
    if (!json_obj.empty())
    {
        QJsonObject nodes_json = json_obj["status"].toObject();

        // Update status for each node
        if (nodes_json.contains(Utils::node_name(sustainml::NodeID::ID_APP_REQUIREMENTS)))
        {
            QString status_value = nodes_json.value(
                Utils::node_name(sustainml::NodeID::ID_APP_REQUIREMENTS)).toString();
            emit update_app_requirements_node_status(status_value);
        }
        if (nodes_json.contains(Utils::node_name(sustainml::NodeID::ID_CARBON_FOOTPRINT)))
        {
            QString status_value = nodes_json.value(
                Utils::node_name(sustainml::NodeID::ID_CARBON_FOOTPRINT)).toString();
            emit update_carbon_footprint_node_status(status_value);
        }
        if (nodes_json.contains(Utils::node_name(sustainml::NodeID::ID_HW_CONSTRAINTS)))
        {
            QString status_value = nodes_json.value(
                Utils::node_name(sustainml::NodeID::ID_HW_CONSTRAINTS)).toString();
            emit update_hw_constraints_node_status(status_value);
        }
        if (nodes_json.contains(Utils::node_name(sustainml::NodeID::ID_HW_RESOURCES)))
        {
            QString status_value = nodes_json.value(
                Utils::node_name(sustainml::NodeID::ID_HW_RESOURCES)).toString();
            emit update_hw_resources_node_status(status_value);
        }
        if (nodes_json.contains(Utils::node_name(sustainml::NodeID::ID_ML_MODEL)))
        {
            QString status_value = nodes_json.value(
                Utils::node_name(sustainml::NodeID::ID_ML_MODEL)).toString();
            emit update_ml_model_node_status(status_value);
        }
        if (nodes_json.contains(Utils::node_name(sustainml::NodeID::ID_ML_MODEL_METADATA)))
        {
            QString status_value = nodes_json.value(
                Utils::node_name(sustainml::NodeID::ID_ML_MODEL_METADATA)).toString();
            emit update_ml_model_metadata_node_status(status_value);
        }
    }
    // Remove REST requester from queue
    std::lock_guard<std::mutex> lock(requesters_mutex_);
    for (auto it = requesters_.begin(); it != requesters_.end(); ++it)
    {
        if (*it == requester)
        {
            auto ptr = *it;
            requesters_.erase(it);
            (ptr)->disconnect();
            (ptr)->deleteLater();
            break;
        }
    }
}

void Engine::config_request(
        const QJsonObject& json_obj,
        std::function<void(const QJsonObject&)> callback)
{
    config_callback_ = callback;

    REST_requester* requester = new REST_requester(
        std::bind(&Engine::config_response, this, std::placeholders::_1, std::placeholders::_2),
        REST_requester::RequestType::REQUEST_CONFIG,
        json_obj);

    {
        std::lock_guard<std::mutex> lock(requesters_mutex_);
        requesters_.push_back(requester);
    }
}

void Engine::config_response(
        const REST_requester* requester,
        const QJsonObject& json_obj)
{
    if (!json_obj.empty())
    {
        std::cout << "Config response: " << QJsonDocument(json_obj).toJson(QJsonDocument::Indented).toStdString() << std::endl;

        if (config_callback_)
        {
            config_callback_(json_obj);
            config_callback_ = nullptr; // Empty the callback
        }
    }
    // Remove REST requester from queue
    std::lock_guard<std::mutex> lock(requesters_mutex_);
    for (auto it = requesters_.begin(); it != requesters_.end(); ++it)
    {
        if (*it == requester)
        {
            auto ptr = *it;
            requesters_.erase(it);
            (ptr)->disconnect();
            (ptr)->deleteLater();
            break;
        }
    }
}
