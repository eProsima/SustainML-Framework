# Components

Shared components live in `src/qml/components` (registered in `src/qml.qrc`). Use them
instead of stock Qt controls or hand-built `Rectangle` + `MouseArea` buttons.

## Buttons

| Component | Use it for | Key properties |
|---|---|---|
| `SmlButton` | Any text button | `text_value`, `icon_name`, `variant`: `"secondary"` (default), `"primary"` (the one main action, bright green with dark text), `"ghost"` (menu rows, light actions), `"subtle"`, `"danger"` (delete, clear, stop); `size`: `"sm"` / `"md"` / `"lg"`; `disabled`; `tooltip_text`; `align_left` |
| `SmlIconButton` | Icon-only buttons: Back, row actions, toolbars | `icon_name`, `tooltip_text` (also its accessible name), `outlined` (next to text buttons), `button_size`, `icon_rotation` |

Rules: one `primary` per screen or dialog (Submit, Compare, Browse, Start now, Analyze rows);
destructive actions use `danger`; icon-only buttons always have a `tooltip_text`.

## Inputs

| Component | Use it for |
|---|---|
| `SmlInput` | Single-line text field (a `TextInput`): raised fill, `borderInput` outline, 2 px `focusRing` while editing. `placeholder_text`, `disabled`, `read_only`, `monospace` |
| `SmlTextArea` | Multi-line text field in the same style (a `TextEdit`): Enter starts a new line, scrolls inside once full, Tab moves to the next field. `placeholder_text`, `disabled`, `read_only`, `content_height` |
| `SmlCombobox` | Drop-down choice: chevron, overlay popup with green hover rows and a check on the current value; `searchable` adds a filter field, `read_only` only shows the value |
| `SmlCheckBox` | Check box: bright green with a dark check when checked |
| `SmlFieldLabel` | Label above a field; `active` turns it green while its field is edited |

## Structure

| Component | Use it for |
|---|---|
| `SmlScreenHeader` | Top bar of every screen: `title`, `subtitle`, `navigation` (Home as a labelled `SmlButton`, Back as an `outlined` `SmlIconButton`), `actions` on the right; green line along its bottom; leaves room on the right for the global Node status (gear) button |
| `SmlCard` | Section of a screen, straight on the page (no box): heading with `title`, `subtitle`, `icon_name` (green tile) and `actions` over a thin divider; children go into the content area below (`content_padding` is the gap) |
| `SmlTabView` | Tabs over pages. `tab_style: "card"` for problem tabs (framed, the selected one joined to the page with a green top bar); `"underline"` for tabs inside a page (outlined segments, the selected one filled green) |
| `SmlScrollView` / `SmlScrollBar` | Scrolling areas; the bar is slim, neutral, and hidden when there is nothing to scroll |

## Dialogs and menus

| Component | Use it for |
|---|---|
| `SmlModal` | Every dialog: centred, dims the window, overlay card with icon tile (`icon_name`, `tone`), `title`, `subtitle`, close button; `standardButtons` are drawn as `SmlButton`s (the accepting one primary). Declare a `footer: SmlDialogButtonBox { ... }` for custom buttons |
| `SmlDialog` | Message dialog (title, text, OK) on top of `SmlModal` |
| `SmlSaveLoadDialogs` | The named save / load file pickers |
| `SmlMenu` / `SmlMenuItem` | Context menus; rows take an `icon_name` |
| `SmlToolTip` | Tooltip for an area that is not a button |

## Status and display

| Component | Use it for |
|---|---|
| `SmlChip` | A short status in a tinted pill with a dot or icon (`tone`, `pulse` for live states) |
| `SmlIcon` | An icon (`name`, `variant` from `Theme.icon*`, `size`) |
| `SmlText` | Text in the type roles of the theme |
| `SmlFocusRing` | Keyboard focus outline inside a custom control |
