pragma Singleton
import QtQuick 2.15

Item {
    property alias sustainml_font: sustainml_font_loader.name
    property alias title_font: title_font_loader.name
    property alias body_font: body_font_loader.name


    FontLoader {
        id: sustainml_font_loader
        source: "qrc:/font/ArimaMadurai-ExtraBold.ttf"
    }

    FontLoader {
        id: title_font_loader
        source: "qrc:/font/ArimaMadurai-Medium.ttf"
    }

    FontLoader {
        id: body_font_loader
        source: "qrc:/font/Lato-Regular.ttf"
    }
}
