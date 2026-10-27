pragma Singleton
import QtQuick 2.15

/*
    Font families of the interface. Inter (titles and body) and JetBrains Mono (values,
    ids) are also registered by main.cpp; the SustainML word mark keeps Arima Madurai.
 */
Item {
    property alias sustainml_font: sustainml_font_loader.name
    property alias title_font: title_font_loader.name
    property alias body_font: body_font_loader.name
    property alias mono_font: mono_font_loader.name

    FontLoader {
        id: sustainml_font_loader
        source: "qrc:/font/ArimaMadurai-ExtraBold.ttf"
    }

    FontLoader {
        id: title_font_loader
        source: "qrc:/font/Inter-600.ttf"
    }

    FontLoader {
        id: body_font_loader
        source: "qrc:/font/Inter-400.ttf"
    }

    FontLoader {
        id: mono_font_loader
        source: "qrc:/font/JetBrainsMono-400.ttf"
    }
}
