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

#include <QQmlApplicationEngine>
#include <qqmlcontext.h>

#include <sustainml_frontend/Engine.h>

Engine::Engine()
    : enabled_(false)
{
}

QObject* Engine::enable()
{
    // Initialize async backend
    //listener_ = new backend::Listener(this);
    //backend_connection_.set_listener(listener_);

    // Initialize models

    // Initialized qml
    //rootContext()->setContextProperty("controller", controller_);

    // Load main GUI
    load(QUrl(QLatin1String("qrc:/qml/main.qml")));

    // Connect Callback Listener to this object

    // Set enable as True
    enabled_ = true;

    return rootObjects().value(0);
}

Engine::~Engine()
{
    if  (enabled_)
    {
        // First free the listener to stop new entities from appear
        // if (listener_)
        // {
        //     backend_connection_.unset_listener();
        //     delete listener_;
        // }
    }
}

