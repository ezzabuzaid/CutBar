# Testing

## Test Types

Current suite (`Tests/CutBarTests`) covers:

- Domain/logic behavior (`CutBarLogicTests`)
- Persistence and storage robustness (`CutBarPersistenceTests`)

## Run Tests

Standard:

```bash
swift test --disable-sandbox
```

Sandbox-friendly cache setup:

```bash
mkdir -p .tmp-swift-cache/home .tmp-swift-cache/clang-module-cache .tmp-swift-cache/swiftpm-cache
HOME="$PWD/.tmp-swift-cache/home" \
CLANG_MODULE_CACHE_PATH="$PWD/.tmp-swift-cache/clang-module-cache" \
SWIFTPM_CACHE_DIR="$PWD/.tmp-swift-cache/swiftpm-cache" \
swift test --disable-sandbox
```

## What to Test for Changes

- Meal phase calculations and target logic
- Draft/preset entry save behavior
- Delete/update flows
- SQLite schema constraints and backward compatibility
- Storage error handling surfaced to UI state

## Manual Smoke Checklist

1. Launch app and confirm menu bar icon/title appears.
2. Add preset entry and verify totals update.
3. Add custom entry and verify persisted after relaunch.
4. Delete an entry and verify totals/history update.
5. Open dashboard and meal history windows from commands.
6. Tail logs for unexpected storage/action errors.
