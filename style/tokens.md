# Design tokens

All values live in `src/qml/utils/Theme.qml` (singleton `Theme`). Use the token name,
never the value. The theme follows `ScreenManager.night_mode`.

## Colour

Light / dark values. Every text colour reaches **4.5:1** on every surface of its theme;
`borderInput` and `focusRing` reach **3:1**.

| Token | Light | Dark | Use |
|---|---|---|---|
| `appBackground` | `#F1F8EB` | `#0A170C` | page background (uniform) |
| `surface` | `#FFFFFF` | `#131B15` | cards, pages, tab content |
| `raised` | `#FFFFFF` | `#19231B` | inputs, secondary buttons, list rows |
| `overlay` | `#FFFFFF` | `#212C23` | popups, menus, dialogs, tooltips |
| `sunken` | `#E8F3DF` | `#101812` | disabled inputs, subtle fills |
| `cardHeader` | `#E1F3D3` | `#1B3520` | table header rows |
| `headerTint` | `#EAF7DF` | `#12261A` | the screen header bar |
| `border` | `#BFDCA8` | `#28392B` | dividers, card outlines |
| `borderStrong` | `#9CC77F` | `#37503B` | tab frames, content card outlines, secondary button outlines |
| `borderInput` | `#7A8B76` | `#6B7D6E` | input, combo box and checkbox outlines (3:1) |
| `textPrimary` | `#15201A` | `#E4EAE5` | body text, titles |
| `textSecondary` | `#46534A` | `#A7B2AA` | labels, secondary lines, table headers |
| `textMuted` | `#56635A` | `#8F9B92` | hints, placeholders, meta |
| `textDisabled` | `#A2ACA4` | `#5A655D` | disabled text |
| `accentText` | `#21780A` | `#9BE070` | text in green (model names, values that differ, labels in focus) |
| `accentSubtle` / `accentSubtleStrong` | bright green 30 % / 50 % | 30 % / 45 % | hover and selection tints |
| `focusRing` | `#38961E` | `#8BD65F` | keyboard focus, input being edited |
| `success` / `warning` / `danger` | `#11652F` / `#A44B07` / `#B91C1C` | `#4ADE80` / `#FBBF24` / `#F87171` | status, always with text |
| `scrim` | black 35 % | black 60 % | behind modal dialogs |

Same in both themes:

| Token | Value | Use |
|---|---|---|
| `brandGreen` | `#62A343` | the SustainML green: header line, selected tab bars, hover outlines |
| `brandGreenBright` | `#64C537` | the bright green of the logo |
| `brandLime` | `#CBEE19` | the word mark in dark mode, U-Net output maps |
| `accentFill` / `accentFillHover` / `accentFillPressed` | `#64C537` / `#58B82D` / `#4DA626` | **fill of primary buttons, checked boxes, selected segments, icon tiles** |
| `onAccent` | `#FFFFFF` | text and icons on `accentFill` (white; bold weight for legibility on the bright green) |
| `accentBorder` | `#4DA626` | outline of `accentFill` shapes against white (3:1) |

`Theme.toneColor(tone)` gives the colour of `"success"`, `"warning"`, `"danger"`,
`"info"` (green, there is no blue) or `"accent"`; `Theme.alpha(color, a)` the same colour
with another opacity.

## Typography

- **Inter** for the interface and **JetBrains Mono** for values, ids, paths and numbers in
  tables (`Theme.uiFontFamily`, `Theme.monoFontFamily`). Both are bundled in `src/font` and
  registered by `main.cpp`, which makes Inter the application font. The SustainML word mark
  keeps Arima Madurai (`SustainMLFont.sustainml_font`).

| Role | Token | Size / weight |
|---|---|---|
| Overlines (`PROJECT PARTNERS`, `U-NET MODEL`) | `fontSizeMicro` | 11 px DemiBold, spaced capitals |
| Meta, tooltips, chips, table headers | `fontSizeMeta` | 12 px |
| Body, controls | `fontSizeBody` | 13 px |
| Field labels | `fontSizeLabel` | 13 px DemiBold, `textSecondary` (`accentText` while editing) |
| Card titles | `fontSizeCardTitle` | 15 px DemiBold |
| Dialog titles | `fontSizeDialogTitle` | 16 px DemiBold |
| Screen titles (header) | - | 17 px DemiBold |
| Page titles | `fontSizePageTitle` | 20 px DemiBold |

`SmlText` maps its `TextKind` onto these: `Header_1` page title,
`Header_2` card title, `Header_3` field label, `Body` body.

## Shape and spacing

| Token | Value | Use |
|---|---|---|
| `radiusXs` | 4 | checkboxes |
| `radiusSm` | 6 | buttons, inputs, menu rows, content cards under tabs |
| `radiusMd` | 8 | tabs, list rows, popups, icon tiles |
| `radiusLg` | 12 | cards, dialogs |
| `space1` ... `space7` | 4, 8, 12, 16, 24, 32, 48 | all padding and gaps (4 px grid) |
| `pagePadding` | 24 | side padding of screen content |
| `contentMaxWidth` | 1180 | forms and lists stop growing past this |

## Sizes

| Token | Value | Use |
|---|---|---|
| `controlHeightSm` / `controlHeight` / `controlHeightLg` | 28 / 34 / 44 | small, default and large buttons |
| `headerHeight` | 60 | the screen header bar |
| `iconSizeDense` / `iconSizeDefault` / `iconSizeLarge` / `iconSizeXLarge` | 14 / 16 / 20 / 24 | icons |

Form fields are 38 px tall, multi-line fields 80 or 104 px; table rows and headers 48 px.

## Motion

| Token | Value | Use |
|---|---|---|
| `durFast` | 100 ms | hover and press colour changes |
| `durEnter` | 180 ms | opening dialogs |
| `durExit` | 120 ms | closing (shorter than opening) |

`Theme.reduceMotion` sets them all to 0. Pressing changes colour only, never size or position.
