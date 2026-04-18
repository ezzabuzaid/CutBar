# Tasks — add-meal-heatmap

## Model

- [x] Add `HeatmapDay` struct (dayKey, date, totals?, proteinProgress, hasEntries) in `Models/`.
- [x] Extend `CutBarModel` with `heatmapDays: [HeatmapDay]` (rolling 30, Monday-aligned order).
- [x] Extend `CutBarModel` with `currentStreak: Int` (consecutive goal days ending today).
- [x] Add `selectedDayKey: String?` + `selectedDayLog: DayLog?` to `CutBarModel`.
- [x] Selection setter: same key → nil; today key → nil.

## View

- [x] New `HeatmapCardView` (grid + legend + streak chip).
- [x] Bucket→color helper (local to `HeatmapCardView`).
- [x] Today cell stroke + selected cell stroke.
- [x] Cell tooltip (`.help(...)`).
- [x] New `SelectedDayDetailCardView` (read-only; no delete/context menu).
- [x] Wire into `DashboardView`: heatmap after summary; detail card conditional between heatmap and protocol.

## Tests

- [x] `HeatmapDayTests`: window size/order, empty-day handling, progress cap.
- [x] `HeatmapDayTests`: streak — zero, N consecutive, gap stop, today-not-yet-at-goal.
- [x] `CutBarModelTests`: `selectedDayKey` setter behavior (today → nil, toggle, clearSelection).

## Verification

- [x] `swift build` clean.
- [x] `swift test` green (46 tests, including 8 new heatmap + 3 selection).
- [ ] Manual dashboard check: seed 30 days, verify grid, streak, tooltip, selection, Today button, Esc deselect, today-only sections unchanged, `MealHistoryView` unchanged.
