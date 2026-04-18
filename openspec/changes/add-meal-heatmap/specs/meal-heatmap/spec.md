# meal-heatmap

## Purpose

Give the user an at-a-glance, navigational read on recent protein-goal consistency directly in the dashboard, without leaving the logging surface.

## Requirements

### Heatmap window

- MUST show exactly 30 cells, one per day, covering `today - 29 ... today` inclusive.
- MUST order cells chronologically, rendered as a Monday-first 7-column grid.
- MUST render days with no logged entries as an empty cell (stroke only, no fill), visually distinct from a zero-progress logged day.

### Intensity encoding

- MUST color each logged day according to `proteinGrams / plan.dailyTargets.proteinGrams`, clamped at `>= 1.0 = goal`.
- MUST use four filled buckets: `<50%`, `50–80%`, `80–100%`, `>=100%`.
- MUST use `Color.themeAccent` with varied alpha; no new brand hues.

### Today cell

- MUST visually distinguish today with a subtle accent stroke, regardless of progress.
- Today MUST NOT be selectable for drill-in (tapping today clears selection).

### Streak

- MUST display a streak counter = number of consecutive days ending at today with `proteinProgress >= 1.0`.
- MUST count today only if today has already met goal; otherwise streak reflects prior consecutive goal days up to yesterday.
- MUST show `0` (not hide the chip) when there is no active streak.

### Legend

- MUST display a compact legend mapping the four filled buckets to their colors, plus the empty-cell affordance.

### Selection & drill-in

- Selecting a past cell MUST reveal an inline read-only day-detail card between the heatmap card and the Protocol card.
- The detail card MUST show date, totals (protein g, calories), entry count, and entries grouped by `MealSlot` using the existing history row styling.
- The detail card MUST NOT expose delete or edit affordances.
- A visible "Today" affordance MUST clear the selection.
- Re-selecting the currently selected cell MUST clear the selection.
- Clearing the selection MUST remove the detail card from the layout.

### Tooltip

- Hovering a cell MUST show a tooltip with `{protein}g · {calories} kcal` for logged days, or `"No entries"` for empty days.

### Non-interference

- The summary card, Protocol card, and `MealSlotCardView`s MUST continue to reflect *today* regardless of selection.
- Selection state MUST NOT persist across app launches.
