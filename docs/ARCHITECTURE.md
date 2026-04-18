# Architecture

## Overview

CutBar is a standalone macOS menu bar app built as a Swift Package.
It tracks food entries, protein, and calories across fixed meal slots.

## Main Layers

1. Presentation (`Views`, `App`)
2. State/Domain (`CutBarModel`, models)
3. Persistence (`FoodLogStore`, SQLite)

## App Surfaces

- Menu bar extra panel for quick logging and status.
- Dashboard window for deeper interaction.
- Meal history window for reviewing past days.

## Data Flow

1. User action in SwiftUI view.
2. View calls `CutBarModel` method (`logPreset`, `saveDraft`, `delete`).
3. `CutBarModel` calls `FoodLogStore.update(...)`.
4. `FoodLogStore` runs SQLite transaction and persists.
5. `CutBarModel` updates published state; UI re-renders.

## Storage

- SQLite database at `Application Support/CutBar/food-log.sqlite`.
- Strong DB-level constraints enforce domain invariants.
- Writes are transaction-protected.
- Read/write failures are surfaced as user-facing storage issues.

## Time Model

- `CutBarModel` refreshes the clock every minute.
- Current day phase is computed from `CutPlan`.
- Menu bar title reflects either phase label or current totals.

## Logging/Observability

Uses `os.Logger` categories:

- `lifecycle`
- `storage`
- `actions`

Telemetry can be tailed with:

```bash
./scripts/build_and_run.sh --telemetry
```
