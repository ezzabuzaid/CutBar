# add-meal-heatmap

## Why

Dashboard shows only today. User has no at-a-glance read on consistency and no way to peek at a past day without leaving the dashboard.

## What

Add a rolling 30-day protein-goal heatmap card to `DashboardView`, between the summary card and the Protocol card. Cells are clickable; selecting a past day reveals an inline read-only day-detail card below the heatmap. The existing Protocol + meal-slot logging cards stay today-only and untouched.

## Scope

- Heatmap card: 30-day grid, protein-goal intensity, streak counter, legend.
- Inline past-day detail card (read-only; reuses history row styling).
- Selection state + "Today" deselect affordance.

## Non-goals

- Calendar-month view, month navigation beyond the rolling 30-day window.
- Planning / forward-looking days.
- Editing or deleting entries from the heatmap drill-in (delete still lives in `MealHistoryView`).
- EventKit / Calendar.app sync.
- Changes to `MealHistoryView`.
