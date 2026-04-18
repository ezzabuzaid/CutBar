# Design — add-meal-heatmap

## Data

- Derive a `heatmapDays: [HeatmapDay]` from `document.logs` on `CutBarModel`.
  - Window: `today - 29 ... today` (30 cells, today inclusive).
  - Each cell: `{ dayKey, date, totals: NutritionSummary?, proteinProgress: Double, hasEntries: Bool }`.
  - Missing days → `totals = nil`, `proteinProgress = 0`, `hasEntries = false`.
- `currentStreak: Int` — consecutive days ending at today with `proteinProgress >= 1.0`. Today counts only if already at goal (doesn't punish mid-day).
- `selectedDayKey: String?` — new `@Observable` property on `CutBarModel`. `nil` = no drill-in (today implicit).
- `selectedDayLog: DayLog?` — computed from `selectedDayKey`.

## Intensity buckets

| Bucket | Range of `proteinProgress` | Fill |
|--------|----------------------------|------|
| empty  | `hasEntries == false`      | stroke only, no fill |
| low    | `0 < p < 0.5`              | accent @ 20% |
| mid    | `0.5 <= p < 0.8`           | accent @ 45% |
| high   | `0.8 <= p < 1.0`           | accent @ 70% |
| goal   | `p >= 1.0`                 | accent @ 100% |

Four filled buckets + empty. Matches the "░ ▒ ▓ █" legend.

## Layout

- Card lives in `DashboardView` between `summaryCard` and `protocolCard`.
- Grid: 7 columns × up to 5 rows, week starts Monday (follows `Calendar.current.firstWeekday`? → use Monday explicitly for consistency).
- Cells are square, ~`(cardWidth - padding - 6*gap) / 7`. Gap 4pt. Corner radius 4pt.
- Today cell: 1pt accent stroke ring.
- Selected cell: 2pt stroke using `Color.primary`.
- Legend row + streak chip share the footer row.

## Interaction

- Click cell → `selectedDayKey = cell.dayKey` (or `nil` if same cell re-clicked, or if cell is today).
- Hover → tooltip via `.help("138g · 1,820 kcal")` (or `"No entries"` when empty).
- Inline detail card appears between heatmap card and Protocol card when `selectedDayKey != nil`.
  - Header: display date + `[Today]` text button that clears selection.
  - Body: meal-slot sections like `DayHistoryCard`, read-only (no context menu / delete).
- `Esc` key → clear selection (via `.keyboardShortcut(.escape)` on Today button? → simpler: make the button a default `.cancelAction` shortcut).

## Why not a separate window / sheet

- Dashboard is already the user's home surface; pushing a new window for drill-in adds friction.
- Inline reveal keeps "today logging" one scroll away — user already scrolls the dashboard.
- `MealHistoryView` remains the place for deep history + mutations.

## Testing

- `CutBarModelTests` — add cases for:
  - heatmap window size = 30, in chronological order ending today.
  - missing days → `hasEntries == false`.
  - streak: 0 with no data; N with N consecutive goal days; resets on gap.
  - `selectedDayKey` setter: same key twice → nil; today key → nil.
- `ThemeTests` — add bucket→color mapping assertions if we codify the ramp as a helper.
- Manual: type-check via `nx run CutBar:typecheck` (if wired) or the Swift test target.
