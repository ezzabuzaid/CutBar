# Developers Guide

This file is for maintainers and contributors working on CutBar internals.

## Repo Layout

- `Sources/CutBar/App`: app entrypoint and app-level commands/scenes.
- `Sources/CutBar/Views`: SwiftUI screens and menu bar content.
- `Sources/CutBar/Models`: domain models for food entries, plans, and summaries.
- `Sources/CutBar/Stores`: persistence and app state orchestration.
- `Sources/CutBar/Support`: logging, formatting, fonts, and theme helpers.
- `Tests/CutBarTests`: unit/integration-style tests.
- `scripts`: build/run and release automation.
- `.github/workflows`: CI/CD workflows.

## Runtime Architecture

`CutBarApp` composes three surfaces:

- Menu bar panel (`MenuBarExtra`)
- Dashboard window
- Meal history window

`CutBarModel` is the state coordinator:

- Loads persisted document on launch
- Exposes computed totals/phase/progress for UI
- Handles create/delete flows for entries
- Refreshes time-driven state every minute

`FoodLogStore` is the storage boundary:

- SQLite-backed persistence
- Schema enforcement via SQL constraints/checks
- Atomic updates via explicit transactions
- Human-readable error mapping for UI display

## Persistence Details

- Database file: `~/Library/Application Support/CutBar/food-log.sqlite`
- Table: `entries`
- Views: `cutbar_day_totals`, `cutbar_slot_totals`
- Key invariants enforced in SQLite:
  - UUID-like `id`
  - `day_key` date format (`YYYY-MM-DD`)
  - valid `meal_slot` (`meal1`, `shake`, `meal2`)
  - positive macro/calorie values
  - `calories` matches `base_calories` plus buffer math

## Logging

Uses `os.Logger` with subsystem `com.ezz.study.CutBar`:

- `lifecycle`
- `storage`
- `actions`

Inspect logs with:

```bash
./scripts/build_and_run.sh --logs
./scripts/build_and_run.sh --telemetry
```

## Command Reference

- Build + run app: `./scripts/build_and_run.sh`
- Debug with LLDB: `./scripts/build_and_run.sh --debug`
- Verify launch: `./scripts/build_and_run.sh --verify`
- Run tests: `swift test --disable-sandbox`
- Local release: `./scripts/release.sh <version>`

## Release and Signing

The release process is automated in `.github/workflows/release-on-tag.yml`.

- Trigger: push a `v<semver>` tag (example `v1.2.3`)
- Artifacts:
  - `dist/CutBar-<version>.dmg`
  - `dist/CutBar-<version>.app.zip`
- Script enforces that no exported signing secrets exist in the repo tree.

See [`docs/RELEASE.md`](docs/RELEASE.md) for full details.
