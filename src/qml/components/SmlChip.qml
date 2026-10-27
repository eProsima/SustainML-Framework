import QtQuick 2.15

// Project imports
import eProsima.SustainML.Theme 1.0

/*
    A short status or label in a tinted pill: a dot (or icon) and the text, both in the
    tone colour, so the status never relies on colour alone.

    Usage:
        SmlChip { text: "RUNNING"; tone: "info" }
 */
Rectangle {
    id: chip

    // External properties
    property string text: ""
    // "success", "warning", "danger", "info", "accent" or "neutral"
    property string tone: "neutral"
    property string icon_name: ""
    property bool show_dot: icon_name === ""
    // Live / busy state: a growing sprout instead of the dot
    property bool pulse: false

    readonly property color tone_color_: Theme.toneColor(tone)
    readonly property string icon_variant_: tone === "danger" ? Theme.iconDanger
                                          : tone === "warning" ? Theme.iconWarning
                                          : tone === "success" ? Theme.iconSuccess
                                          : tone === "accent" ? Theme.iconAccent
                                          : Theme.iconMuted

    implicitWidth: row.implicitWidth + 2 * Theme.space2 + 2
    implicitHeight: 22
    radius: height / 2
    color: Theme.alpha(tone_color_, Theme.darkMode ? 0.16 : 0.10)
    border.width: 1
    border.color: Theme.alpha(tone_color_, Theme.darkMode ? 0.35 : 0.28)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space1 + 2

        // Busy: a growing sprout instead of the dot
        SmlGrowingLoader {
            visible: chip.pulse
            anchors.verticalCenter: parent.verticalCenter
            size: Theme.iconSizeDense
            variant: chip.icon_variant_
            running: chip.pulse
        }

        Rectangle {
            id: dot
            visible: chip.show_dot && !chip.pulse
            anchors.verticalCenter: parent.verticalCenter
            width: 7
            height: 7
            radius: 3.5
            color: chip.tone_color_
        }

        SmlIcon {
            visible: chip.icon_name !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: chip.icon_name
            size: Theme.iconSizeDense - 2
            variant: chip.icon_variant_
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.text
            textFormat: Text.PlainText
            font.family: Theme.uiFontFamily
            font.pixelSize: Theme.fontSizeMicro
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
            color: chip.tone_color_
        }
    }
}
