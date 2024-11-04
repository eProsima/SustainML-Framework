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

#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkReply>
#include <QQmlApplicationEngine>
#include <qqmlcontext.h>
#include <QString>
#include <QUrl>

#include <sustainml/Engine.h>

#include <sustainml_cpp/orchestrator/OrchestratorNode.hpp>
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

    // Initialize orchestrator node
    orchestrator = new sustainml::orchestrator::OrchestratorNode(*this);

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
    if  (enabled_)
    {
        delete orchestrator;
    }
}

void Engine::on_new_node_output(
        const sustainml::NodeID& id,
        void* data)
{
    //emit update_log(QString("Output received. Task ") + get_task_from_data(id, data) + (",\tnode ") +
    //        get_name_from_node_id(id) + ":\n" + get_raw_output(id, data));
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
        QString /*extra_data_*/)
{
    QJsonArray ins;
    QJsonArray outs;
    split_string(inputs.toStdString(), ins, ' ');
    split_string(outputs.toStdString(), outs, ' ');

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

    // Prepare node results requests
    QString node_query_url_ = server_url_ + "/results";
    QUrl node_url(node_query_url_.toStdString().c_str());
    std::array<QNetworkRequest, static_cast<size_t>(sustainml::NodeID::MAX)> requests;
    std::array<QByteArray, static_cast<size_t>(sustainml::NodeID::MAX)> node_raw_data;
    for (size_t i = 0; i < static_cast<size_t>(sustainml::NodeID::MAX); ++i)
    {
        QJsonObject node_json_data;
        node_json_data["node_id"] = static_cast<int>(i);
        QJsonDocument node_doc(node_json_data);
        node_raw_data[i] = node_doc.toJson();
        requests[i].setUrl(node_url);
        requests[i].setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

        // Launch node results requests
        node_responses_[i]->post(requests[i], node_raw_data[i]);
    }
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

QString Engine::get_task_from_json(
        const QJsonObject& json)
{
    if (json.contains("task_id"))
    {
        QJsonObject task_id = json["task_id"].toObject();
        return get_task_QString(types::TaskId(task_id["problem_id"].toInt(), task_id["iteration_id"].toInt()));
    }
    else
    {
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
            output += "Hardware required: ";
            for (std::string hw_req : hw_constraints->hardware_required())
            {
                output += QString::fromStdString(hw_req) + QString(", ");
            }
            output += QString("\n");
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

QString Engine::get_raw_output_json(
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

void Engine::user_input_response(
        QNetworkReply* reply_)
{
    QJsonDocument json_doc = QJsonDocument::fromJson(reply_->readAll());
    QJsonObject json_obj = json_doc.object();
    if (!json_obj.empty())
    {
        emit update_log(QString("User input send for ") + get_task_from_json(json_obj));
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
        QString name = get_name_from_node_id(get_node_from_json(json_obj));
        emit update_log(QString("Output received. Task ") + get_task_from_json(json_obj[name].toObject()) +
                (",\tnode ") +
                name + ":\n" + get_raw_output_json(json_obj));
    }
    reply_->deleteLater();
}
