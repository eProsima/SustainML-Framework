# SustainML front-end - UI style guide

This directory records the look and interaction style of the SustainML interface.
Read it before building new UI, and extend what is here rather than inventing a new
look: every new screen should feel like part of the same application.

| File | What it covers |
|---|---|
| [tokens.md](tokens.md) | Colours, type, spacing, radii, sizes and motion: the `Theme` values to use |
| [components.md](components.md) | The shared `Sml*` components and when to use each |
| [patterns.md](patterns.md) | How each screen is laid out: header, cards, forms, tables, tabs, lists, dialogs |
| [icons.md](icons.md) | The icon set (Lucide), how icons are generated, names, sizes and colours |

## The rules

1. **Use tokens, never literals.** Colours, radii, spacing, sizes and durations come from
   `Theme` (`src/qml/utils/Theme.qml`, `import eProsima.SustainML.Theme 1.0`). No hex
   colours or ad-hoc pixel values for things a token covers. If a value is missing, add a
   token to `Theme.qml` and to [tokens.md](tokens.md), then use it.
2. **Use the shared components.** Buttons, icon buttons, inputs, combo boxes, cards,
   dialogs, menus, chips, tooltips and tabs exist in `src/qml/components`. Do not hand-build
   a button from a `Rectangle` and a `MouseArea`, and do not use a stock Qt control where
   an `Sml*` one exists.
3. **One icon language.** Only icons of the generated Lucide set, through `SmlIcon` or a
   component that takes `icon_name`. No emoji and no Unicode glyphs standing in for icons.
4. **Green is SustainML.** The brand greens carry the identity: the primary action,
   selection, focus, live state and the green line under every header. There is no blue
   in the interface (no blue "info" or "running" states).
5. **Layered surfaces.** Areas are told apart by background steps
   (`appBackground` -> `surface` -> `raised` -> `overlay`) and outlines, not by thick bars.
6. **Accessible by default.** Text at 4.5:1 or more on its surface, outlines and focus at
   3:1, real controls (reachable with Tab, with an accessible name or tooltip), status never
   shown by colour alone (a chip always has its text).
7. **Both themes.** Check every change in light and dark mode (`ScreenManager.night_mode`).

## Checklist for a new screen or feature

- [ ] Colours, sizes, radii and durations all come from `Theme`
- [ ] It has an `SmlScreenHeader` (title, subtitle, navigation, actions)
- [ ] Content sits in `SmlCard`s on the page background, at most `Theme.contentMaxWidth` wide
- [ ] Every button, input, menu, dialog and tab is an `Sml*` component
- [ ] Icons come from the generated set; new ones were added to `tools/icons/icons.json`
- [ ] Icon-only controls have a `tooltip_text`
- [ ] Checked in light and dark mode
- [ ] `python3 -I tools/icons/generate_icons.py --check` passes

## Qt 5.15 traps met while building this UI

- **No `required` properties on components used inside delegates.** An object with a
  required property anywhere inside a `Repeater` or `ComboBox` delegate (even nested, e.g.
  an icon inside a button) makes Qt 5.15 withhold `modelData` and `index` from the whole
  delegate: rows come out blank. `SmlIcon.name` is a plain property for this reason.
- **`Repeater` delegates that reassign their own model** must do it as the last statement
  of a handler (the delegate is destroyed by it); see the comments in `main.qml`.
