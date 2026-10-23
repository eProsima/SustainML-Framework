pragma Singleton
import QtQuick 2.15

// Project imports
import eProsima.SustainML.ScreenMan 1.0

/*
   Design tokens of the SustainML interface: colours, type, shape, spacing, sizes and motion.

   Use the token names, never their values: no hex colours, ad-hoc radii or pixel sizes in
   screens or components. The values follow from one rule set (see style/tokens.md):

     - neutral, slightly green-tinted surfaces, stepped from back to front
       (appBackground -> surface -> raised -> overlay), told apart by tone, not thick lines
     - the SustainML greens as the accent, used for meaning only: the primary action,
       selection, focus and live state
     - every text colour reaches 4.5:1 on every surface of its theme; input outlines,
       the focus ring and meaningful icons reach 3:1

   The theme follows ScreenManager.night_mode, the existing switch of the application.
 */
QtObject {
    readonly property bool darkMode: ScreenManager.night_mode

    readonly property var lightPalette_: ({
        appBackground: "#F1F8EB",
        surface: "#FFFFFF",
        raised: "#FFFFFF",
        overlay: "#FFFFFF",
        sunken: "#E8F3DF",
        border: "#BFDCA8",
        borderStrong: "#9CC77F",
        borderInput: "#7A8B76",
        textPrimary: "#15201A",
        textSecondary: "#46534A",
        textMuted: "#56635A",
        textDisabled: "#A2ACA4",
        hoverBackground: "#0D000000",
        pressedBackground: "#17000000",
        accentSubtle: "#4D64C537",
        accentSubtleStrong: "#8064C537",
        accentText: "#21780A",
        focusRing: "#38961E",
        success: "#11652F",
        warning: "#A44B07",
        danger: "#B91C1C",
        info: "#21780A",
        cardHeader: "#E1F3D3",
        headerTint: "#EAF7DF",
        scrim: "#59000000",
        shadow: "#14000000",
        decoration: "#64C537",
        decorationOpacity: 0.5
    })

    readonly property var darkPalette_: ({
        appBackground: "#0A170C",
        surface: "#131B15",
        raised: "#19231B",
        overlay: "#212C23",
        sunken: "#101812",
        border: "#28392B",
        borderStrong: "#37503B",
        borderInput: "#6B7D6E",
        textPrimary: "#E4EAE5",
        textSecondary: "#A7B2AA",
        textMuted: "#8F9B92",
        textDisabled: "#5A655D",
        hoverBackground: "#0FFFFFFF",
        pressedBackground: "#1AFFFFFF",
        accentSubtle: "#4D64C537",
        accentSubtleStrong: "#7364C537",
        accentText: "#9BE070",
        focusRing: "#8BD65F",
        success: "#4ADE80",
        warning: "#FBBF24",
        danger: "#F87171",
        info: "#9BE070",
        cardHeader: "#1B3520",
        headerTint: "#12261A",
        scrim: "#99000000",
        shadow: "#40000000",
        decoration: "#64C537",
        decorationOpacity: 0.13
    })

    readonly property var palette_: darkMode ? darkPalette_ : lightPalette_

    // -- Neutral surfaces, back to front -------------------------------------------------
    readonly property color appBackground:      palette_.appBackground
    readonly property color surface:            palette_.surface
    readonly property color raised:             palette_.raised
    readonly property color overlay:            palette_.overlay
    readonly property color sunken:             palette_.sunken
    readonly property color cardHeader:         palette_.cardHeader   // title bars of cards
    readonly property color headerTint:         palette_.headerTint   // screen header bar
    // -- Borders / dividers ----------------------------------------------------------------
    readonly property color border:             palette_.border
    readonly property color borderStrong:       palette_.borderStrong
    readonly property color borderInput:        palette_.borderInput
    // -- Text --------------------------------------------------------------------------------
    readonly property color textPrimary:        palette_.textPrimary
    readonly property color textSecondary:      palette_.textSecondary
    readonly property color textMuted:          palette_.textMuted
    readonly property color textDisabled:       palette_.textDisabled
    // -- Interaction veils (translucent, so they work on any surface) --------------------
    readonly property color hoverBackground:    palette_.hoverBackground
    readonly property color pressedBackground:  palette_.pressedBackground
    readonly property color scrim:              palette_.scrim
    readonly property color shadow:             palette_.shadow

    // -- SustainML greens ------------------------------------------------------------------
    // The brand colours of the logo. Filled primary buttons, checked boxes and selected
    // segments use the bright brand green itself with dark ink on it (7.5:1), darkening on
    // hover and press; accentBorder outlines those fills against white (3:1).
    readonly property color brandGreen:         "#62A343"
    readonly property color brandGreenBright:   "#64C537"
    readonly property color brandGreenDeep:     "#3F6A2B"
    readonly property color brandLime:          "#CBEE19"
    readonly property color accentFill:         "#64C537"
    readonly property color accentFillHover:    "#58B82D"
    readonly property color accentFillPressed:  "#4DA626"
    readonly property color onAccent:           "#FFFFFF"
    readonly property color accentBorder:       "#4DA626"
    readonly property color accentSubtle:       palette_.accentSubtle
    readonly property color accentSubtleStrong: palette_.accentSubtleStrong
    readonly property color accentText:         palette_.accentText
    readonly property color focusRing:          palette_.focusRing
    // Decorative organic shapes behind the start screen (the other screens keep a uniform background)
    readonly property color decoration:         palette_.decoration
    readonly property real  decorationOpacity:  palette_.decorationOpacity

    // -- Status: always shown with an icon or text too, never by colour alone --------------
    readonly property color success:            palette_.success
    readonly property color warning:            palette_.warning
    readonly property color danger:             palette_.danger
    readonly property color info:               palette_.info

    //! Colour of a status tone ("success", "warning", "danger", "info", "accent"); any other is neutral
    function toneColor(tone) {
        return tone === "success" ? success
             : tone === "warning" ? warning
             : tone === "danger" ? danger
             : tone === "info" ? info
             : tone === "accent" ? accentText
             : textSecondary
    }

    //! A colour with another alpha (Qt 5 has no Qt.alpha)
    function alpha(c, a) {
        var k = Qt.lighter(c, 1.0)
        return Qt.rgba(k.r, k.g, k.b, a)
    }

    readonly property color transparent: "transparent"

    // -- Icons -------------------------------------------------------------------------------
    // Icons are generated SVGs, one file per colour variant (see style/icons.md). These are
    // the variant names to pass to SmlIcon.variant.
    readonly property string iconDefault:  darkMode ? "light" : "dark"
    readonly property string iconMuted:    "muted"
    readonly property string iconAccent:   darkMode ? "accent_dark" : "accent"
    readonly property string iconOnAccent: "white"
    readonly property string iconDanger:   darkMode ? "danger_dark" : "danger"
    readonly property string iconWarning:  darkMode ? "warning_dark" : "warning"
    readonly property string iconSuccess:  darkMode ? "success_dark" : "success"

    readonly property int iconSizeDense:   14
    readonly property int iconSizeDefault: 16
    readonly property int iconSizeLarge:   20
    readonly property int iconSizeXLarge:  24

    // -- Typography --------------------------------------------------------------------------
    // Inter for the interface and JetBrains Mono for values, ids and code, both bundled
    // and registered by main.cpp. The SustainML word mark keeps its own typeface.
    readonly property var installedFontFamilies_: Qt.fontFamilies()
    readonly property string uiFontFamily:
        installedFontFamilies_.indexOf("Inter") >= 0 ? "Inter" : Qt.application.font.family
    readonly property string monoFontFamily:
        installedFontFamilies_.indexOf("JetBrains Mono") >= 0 ? "JetBrains Mono" : "monospace"

    readonly property int fontSizeMicro:    11  // overlines, badges
    readonly property int fontSizeMeta:     12  // meta, tooltips, chips, table headers
    readonly property int fontSizeBody:     13  // body, controls, menu rows
    readonly property int fontSizeLabel:    13  // field labels (DemiBold)
    readonly property int fontSizeCardTitle: 15 // card and section titles (DemiBold)
    readonly property int fontSizeDialogTitle: 16
    readonly property int fontSizePageTitle: 20 // screen titles (DemiBold)
    readonly property int fontSizeDisplay:  40  // start screen

    // -- Shape -------------------------------------------------------------------------------
    readonly property int radiusXs: 4   // checkboxes, small chips
    readonly property int radiusSm: 6   // buttons, inputs, menu rows
    readonly property int radiusMd: 8   // tabs, list rows, popups
    readonly property int radiusLg: 12  // cards, dialogs

    // -- Spacing, on a 4 px grid -------------------------------------------------------------
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 24
    readonly property int space6: 32
    readonly property int space7: 48

    // -- Sizes -------------------------------------------------------------------------------
    readonly property int controlHeightSm: 28
    readonly property int controlHeight:   34
    readonly property int controlHeightLg: 44
    readonly property int headerHeight:    60   // screen header bar
    readonly property int pagePadding:     24   // side padding of the screen content
    readonly property int contentMaxWidth: 1180 // forms and lists stop growing past this

    // -- Motion ------------------------------------------------------------------------------
    // Closing is shorter than opening; reduceMotion sets them all to 0
    property bool reduceMotion: false
    readonly property int durFast:  reduceMotion ? 0 : 100
    readonly property int durEnter: reduceMotion ? 0 : 180
    readonly property int durExit:  reduceMotion ? 0 : 120
}
