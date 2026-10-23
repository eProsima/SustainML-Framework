# Icons

## The set

All interface icons are **Lucide** outline icons (ISC licence, version in
`thirdparty/lucide/VERSION`), drawn on a 24 px grid with a 2 px stroke and round caps and
joins. The masters are vendored in `thirdparty/lucide/icons` with Lucide's licence. Never
use emoji or Unicode characters as icons.

## How icons are made

`SmlIcon` loads one SVG per colour, `src/images/icons/<name>/<name>_<variant>.svg`. Those
files are **generated**, do not edit them by hand:

1. `tools/icons/icons.json` maps each SustainML icon name to its Lucide master and lists the
   colour of each variant.
2. `python3 -I tools/icons/generate_icons.py` writes every variant of every icon and
   rewrites the icon section of `src/images.qrc`.
3. `python3 -I tools/icons/generate_icons.py --check` fails if any icon is out of date.

To **add an icon**: pick it on lucide.dev, add `"<name>": {"lucide": "<lucide-name>"}` to
`icons.json`, import its master (`generate_icons.py --import-lucide <lucide-static package>`),
then generate. To **change** one, change its Lucide name and regenerate; no QML changes.

## Using icons

- `SmlIcon { name: "leaf"; variant: Theme.iconAccent; size: Theme.iconSizeDefault }`, or the
  `icon_name` of `SmlButton`, `SmlIconButton`, `SmlCard`, `SmlModal`, `SmlChip`, `SmlMenuItem`.
- `variant` is a variant name, not a colour; use the `Theme` names, which follow the theme:
  `iconDefault`, `iconMuted`, `iconAccent`, `iconOnAccent` (on bright green fills),
  `iconDanger`, `iconWarning`, `iconSuccess`.
- Sizes: `iconSizeDense` 14, `iconSizeDefault` 16, `iconSizeLarge` 20, `iconSizeXLarge` 24.

## Variants

| Variant | Colour |
|---|---|
| `dark` | `#15201A` |
| `light` | `#E4EAE5` |
| `muted` | `#6F7B72` |
| `accent` | `#2D7D1B` |
| `accent_dark` | `#9BE070` |
| `white` | `#FFFFFF` |
| `ink` | `#0F2408` |
| `lime` | `#CBEE19` |
| `danger` | `#B91C1C` |
| `danger_dark` | `#F87171` |
| `warning` | `#A44B07` |
| `warning_dark` | `#FBBF24` |
| `success` | `#15803D` |
| `success_dark` | `#4ADE80` |

## Icon names

| Name | Lucide |
|---|---|
| `back` | `arrow-left` |
| `box` | `box` |
| `chart` | `chart-column` |
| `check` | `check` |
| `checklist` | `list-checks` |
| `chevron_left` | `chevron-left` |
| `chevron_right` | `chevron-right` |
| `circle_dot` | `circle-dot` |
| `cpu` | `cpu` |
| `cross` | `x` |
| `database` | `database` |
| `down` | `chevron-down` |
| `earth` | `earth` |
| `error` | `circle-x` |
| `external` | `external-link` |
| `file` | `file-text` |
| `folder` | `folder-open` |
| `gauge` | `gauge` |
| `gear` | `settings` |
| `history` | `history` |
| `home` | `house` |
| `info` | `info` |
| `layers` | `layers` |
| `leaf` | `leaf` |
| `load` | `folder-down` |
| `loader` | `loader-circle` |
| `mop` | `brush-cleaning` |
| `moon` | `moon` |
| `network` | `network` |
| `pencil` | `pencil` |
| `plus` | `plus` |
| `refresh` | `refresh-cw` |
| `save` | `save` |
| `scale` | `scale` |
| `search` | `search` |
| `sparkles` | `sparkles` |
| `sprout` | `sprout` |
| `square` | `square (filled)` |
| `success` | `circle-check` |
| `sun` | `sun` |
| `table` | `table-2` |
| `trash` | `trash-2` |
| `up` | `chevron-up` |
| `upload` | `upload` |
| `warning` | `triangle-alert` |
| `workflow` | `workflow` |
| `zap` | `zap` |
