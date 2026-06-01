#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <QQmlContext>
#include "core/droidstar.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", "Dark");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_ACCENT", "Teal");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_PRIMARY", "BlueGrey");
    QQuickStyle::setStyle("Material");
    app.setWindowIcon(QIcon(":/images/droidstar.png"));
    qmlRegisterType<DroidStar>("org.dudetronics.droidstar", 1, 0, "DroidStar");
    QQmlApplicationEngine engine;
#ifdef USE_FLITE
    engine.rootContext()->setContextProperty("USE_FLITE", QVariant(true));
#else
    engine.rootContext()->setContextProperty("USE_FLITE", QVariant(false));
#endif

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    engine.loadFromModule("DroidStarApp", "ui/mobile/Main");
#else
    engine.loadFromModule("DroidStarApp", "ui/desktop/MainDesktop");
#endif
    return app.exec();

}
