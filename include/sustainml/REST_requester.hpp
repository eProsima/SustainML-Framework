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
 * @file REST_requester.hpp
 */

#ifndef EPROSIMA_SUSTAINML_REST_REQUESTER_HPP
#define EPROSIMA_SUSTAINML_REST_REQUESTER_HPP

#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QObject>

#include <condition_variable>
#include <functional>

class REST_requester : public QObject
{
    Q_OBJECT

private:

    //! Callback to be executed when data is received
    std::function<void(const REST_requester* requester, const QJsonObject& json_obj)> data_received_callback;

public:

    //! Request types
    enum class RequestType
    {
        SEND_USER_INPUT,
        REQUEST_RESULTS,
        REQUEST_NODE_STATUS,
        REQUEST_CONFIG
    };

    //! Object performs a REST request and registers the functor for the response management
    REST_requester(
            std::function<void(const REST_requester* requester, const QJsonObject& json_obj)> callback,
            const RequestType& type,
            const QJsonObject& json_obj);

    //! Release listener and all models
    ~REST_requester();

private slots:

    void manage_response(
            QNetworkReply* reply);

private:
    //! Convert request type to url route using server url
    QString request_type_to_url(
            RequestType type);

    //! Back-end orchestrator node server URL
    const QString server_url_ = "http://127.0.0.1:5001";

    QNetworkAccessManager* manager_;
};

#endif //EPROSIMA_SUSTAINML_REST_REQUESTER_HPP
