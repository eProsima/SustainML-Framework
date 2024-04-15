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

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>
#include <QtQml>
#include <QtQuick/QQuickView>

#include <sustainml/Engine.h>

int main(
        int argc,
        char* argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif // if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QGuiApplication app(argc, argv);

    // Register main project settings
    qmlRegisterSingletonType( QUrl("qrc:/Settings"), "eProsima.SustainML.Settings", 1, 0, "Settings" );

    // Register project fonts
    qmlRegisterSingletonType( QUrl("qrc:/SustainMLFont"), "eProsima.SustainML.Font", 1, 0, "SustainMLFont" );

    // Register project screen manager
    qmlRegisterSingletonType( QUrl("qrc:/ScreenManager"), "eProsima.SustainML.ScreenMan", 1, 0, "ScreenManager" );

    // Register fonts
    QFontDatabase::addApplicationFont("qrc:/font/ArimaMadurai-ExtraBold.ttf");

    // Register engine
    std::shared_ptr<Engine> engine = std::make_shared<Engine>();
    QObject* topLevel = engine->enable();

    QQuickWindow* window = qobject_cast<QQuickWindow*>(topLevel); \
    if ( !window )
    {
        qWarning("Error: Your root item has to be a Window."); \
        return -1;
    }
    window->show();

    // Start APP
    return app.exec();
}
