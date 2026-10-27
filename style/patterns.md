# Patterns

How each part of the application is built. A new screen should follow the closest one.

## Screen

- `SmlScreenHeader` at the top: navigation (Home, Back) on the left, then the title and a
  one-line subtitle, the screen's actions on the right. The global Node status (gear)
  button sits at the right end of every header, except on the iteration info view.
- Below it, the content straight on the uniform `Theme.appBackground`, `Theme.pagePadding`
  from the edges and at most `Theme.contentMaxWidth` wide, in `SmlCard` sections (heading +
  divider, no box). Framed panels are used only where tabs switch between pages (Results,
  U-Net graphs). The organic background shapes appear only behind the Start screen
  (`Theme.decorationOpacity`).
- Long forms keep their main action in a fixed footer bar (Problem definition: Clear all,
  Submit).

## Forms

- Fields grouped in sections (Problem, Model and data, Sustainability targets), each
  field a `SmlFieldLabel` above an `SmlInput` / `SmlCombobox`, in rows of 1, 2 or 3 columns
  `Theme.space4` apart.
- Disabled fields are sunken with dimmed text; placeholders say what to enter.

## Tables (Results)

- Header row on `Theme.cardHeader`, 12 px DemiBold `textSecondary`, units on a second line;
  48 px rows with 1 px dividers; numbers in the mono font.
- The spare width of the view is shared equally among the data columns (on resize); a
  column the user drags keeps its width until then.

## Tabs

- Problem tabs: `SmlTabView` with `tab_style: "card"` on an outlined content card whose top
  corners are square, so the selected tab joins it at any position.
- Tabs inside a page (Overview, Iteration, Comparison): `tab_style: "underline"`, outlined
  segments with the selected one filled green.

## Lists

- Rows are framed (`raised`, `border`, `radiusMd`) with a green hover; the selected or open
  row gets `accentSubtleStrong` and a `brandGreen` outline. Row actions are muted icons
  (rename, delete) that turn coloured on hover.

## Status

- Node and task states are `SmlChip`s: IDLE success, RUNNING accent (pulsing),
  INITIALIZING warning, anything else danger. Progress ("Refreshing...", "Working on
  task...", "Searching Hugging Face...") is a pulsing green chip.

## Dialogs

- `SmlModal`: icon tile in the tone colour, title and subtitle, text in `textSecondary`,
  footer buttons on the right with the primary (or danger) action rightmost.
