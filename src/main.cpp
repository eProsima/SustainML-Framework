#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Register main project settings
    qmlRegisterSingletonType( QUrl("qrc:/Settings"), "eProsima.SustainML.Settings", 1, 0, "Settings" );

    // Register project fonts
    qmlRegisterSingletonType( QUrl("qrc:/SustainMLFont"), "eProsima.SustainML.Font", 1, 0, "SustainMLFont" );

    // Register project screen manager
    qmlRegisterSingletonType( QUrl("qrc:/ScreenManager"), "eProsima.SustainML.ScreenMan", 1, 0, "ScreenManager" );

    // Register fonts
    //QFontDatabase::addApplicationFont("qrc:/font/ArimaMadurai-ExtraBold.ttf");

    // Load main GUI
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    // Start APP
    return app.exec();
}
