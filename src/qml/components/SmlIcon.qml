import QtQuick 2.15
import QtQuick.Controls 2.15

// Project imports
import eProsima.SustainML.Settings 1.0
import eProsima.SustainML.ScreenMan 1.0

Image {
    id: sustainml_custom_icon
    antialiasing: true
    smooth: true
    visible: true

    // External properties
    required property string name
    property string color: Settings.app_color_dark
    property string nightmode_color: Settings.app_color_light
    property string color_pressed: color
    property string nightmode_color_pressed: nightmode_color
    property int size: Settings.button_icon_size
    property real scalingFactor: 1
    property int anim_angle: Settings.button_movement_anim_angle
    property int anim_duration: Settings.button_movement_anim_duration
    property bool pressed: false    // if icon has hover effect, change this to true
    property string clickable_text: ""
    property int tooltip_delay: 1000
    property int tooltip_timeout: 0

    signal clicked()

    // Internal properties, based on the input selection
    readonly property string __final_color: pressed
        ? ScreenManager.night_mode ? nightmode_color_pressed : color_pressed
        : ScreenManager.night_mode ? nightmode_color : color
    sourceSize.width: size * scalingFactor
    sourceSize.height: size * scalingFactor

    source: name ?
                __final_color == Settings.app_color_green_1 ?
                    "qrc:/images/icons/" + name + "/" + name + "_1.svg" :
                __final_color == Settings.app_color_green_2 ?
                    "qrc:/images/icons/" + name + "/" + name + "_2.svg" :
                __final_color == Settings.app_color_green_3 ?
                    "qrc:/images/icons/" + name + "/" + name + "_3.svg" :
                __final_color == Settings.app_color_green_4 ?
                    "qrc:/images/icons/" + name + "/" + name + "_4.svg" :
                __final_color == Settings.app_color_light ?
                    "qrc:/images/icons/" + name + "/" + name + "_w.svg" :
                "qrc:/images/icons/" + name + "/" + name + ".svg" :
            ""
    SequentialAnimation {
        id: rotate
        running: false
        NumberAnimation { target: sustainml_custom_icon; property: "rotation"; to: anim_angle; duration: anim_duration }
        NumberAnimation { target: sustainml_custom_icon; property: "rotation"; to: anim_angle-5; duration: anim_duration / 5 }
        NumberAnimation { target: sustainml_custom_icon; property: "rotation"; to: 0; duration: anim_duration / 3 }
    }

    function start_animation() {
        rotate.running = true
    }

   SmlMouseArea{
        id: mouse_area
        anchors.centerIn: parent
        hoverEnabled: true
        width: parent.width * 1.5
        height: parent.height * 1.5

        enabled: clickable_text !== "" && !main_window.tasking
        acceptedButtons : !main_window.tasking ? Qt.AllButtons : Qt.NoButton
        default_cursor_shape: Qt.ArrowCursor
        custom_cursor_shape : main_window.tasking ? Qt.ArrowCursor : Qt.PointingHandCursor

        onEntered:  if (!main_window.tasking) parent.start_animation();
        onPressed:  if (!main_window.tasking) parent.pressed = true;
        onReleased: if (!main_window.tasking) parent.pressed = false;
        onClicked:  if (!main_window.tasking) parent.clicked();
    }

    ToolTip
    {
        id: internalTooltip
        visible: clickable_text !== "" && mouse_area.containsMouse
        text: clickable_text
        delay: tooltip_delay
        timeout: tooltip_timeout

        // Dynamic positioning: prefer right, fallback left, never covering cursor horizontally
        function updatePos() {
            var root = sustainml_custom_icon
            while (root.parent) root = root.parent
            var margin = 12
            var global = sustainml_custom_icon.mapToItem(root, mouse_area.mouseX, mouse_area.mouseY)

            x = (root.width - (global.x + margin) >= implicitWidth)
                    ? mouse_area.mouseX + margin
                    : mouse_area.mouseX - implicitWidth - margin

            var top = Math.max(margin, Math.min(global.y - implicitHeight/2, root.height - implicitHeight - margin))
            y = sustainml_custom_icon.mapFromItem(root, 0, top).y
        }

        onVisibleChanged: if (visible) updatePos()
        onImplicitWidthChanged: if (visible) updatePos()
        onImplicitHeightChanged: if (visible) updatePos()
        Connections {
            target: mouse_area
            function onPositionChanged() {
                if (internalTooltip.visible) internalTooltip.updatePos()
            }
        }

        background: Rectangle {
            color: Qt.rgba(0.18, 0.18, 0.18, 0.75)
            radius: 6
        }
        contentItem: Text {
            text: internalTooltip.text
            color: "white"
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            padding: 8
            width: Math.min(280, implicitWidth)
        }
    }
}
