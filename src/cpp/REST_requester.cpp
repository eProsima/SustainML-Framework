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
 * @file REST_requester.cpp
 *
 */

#include <sustainml/REST_requester.hpp>

#include <condition_variable>
#include <functional>
#include <iostream>

#include <QJsonDocument>

REST_requester::REST_requester(
        std::function<void(const REST_requester* requester, const QJsonObject& json_obj)> callback,
        const RequestType& type,
        const QJsonObject& json_obj)
    : data_received_callback(callback)
{
    manager_ = new QNetworkAccessManager(this);
    connect(manager_, SIGNAL(finished(QNetworkReply*)), this, SLOT(manage_response(QNetworkReply*)));
    QNetworkRequest network_request_(QUrl(request_type_to_url(type).toStdString().c_str()));
    network_request_.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    manager_->post(network_request_, QJsonDocument(json_obj).toJson());
}

REST_requester::~REST_requester()
{
    manager_->disconnect();
    manager_->deleteLater();
}

void REST_requester::manage_response(
        QNetworkReply* reply_)
{
    // Parse the JSON response
    QJsonDocument json_doc = QJsonDocument::fromJson(reply_->readAll());
    QJsonObject json_obj = json_doc.object();

    // Delete the reply
    reply_->deleteLater();

    // Run the callback function
    data_received_callback(this, json_obj);
}

QString REST_requester::request_type_to_url(
        RequestType type)
{
    QString url = server_url_;
    switch (type)
    {
        case RequestType::SEND_USER_INPUT:
            url += "/user_input";
            break;
        case RequestType::REQUEST_RESULTS:
            url += "/results";
            break;
        case RequestType::REQUEST_NODE_STATUS:
            url += "/status";
            break;
    }
    return url;
}
