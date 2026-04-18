# Local Development

## Requirements

- macOS 14+
- Xcode with Swift 6

## Build and Run

```bash
./scripts/build_and_run.sh
```

Other modes:

```bash
./scripts/build_and_run.sh --verify
./scripts/build_and_run.sh --debug
./scripts/build_and_run.sh --logs
./scripts/build_and_run.sh --telemetry
```

## Test Execution

For restricted/sandboxed environments, use local cache paths:

```bash
mkdir -p .tmp-swift-cache/home .tmp-swift-cache/clang-module-cache .tmp-swift-cache/swiftpm-cache
HOME="$PWD/.tmp-swift-cache/home" \
CLANG_MODULE_CACHE_PATH="$PWD/.tmp-swift-cache/clang-module-cache" \
SWIFTPM_CACHE_DIR="$PWD/.tmp-swift-cache/swiftpm-cache" \
swift test --disable-sandbox
```

## Build Artifacts

- App bundle output: `dist/CutBar.app`
- Release output: `dist/CutBar-<version>.dmg` and `dist/CutBar-<version>.app.zip`

## Typical Edit Loop

1. Implement small focused change.
2. Run tests.
3. Run app (`./scripts/build_and_run.sh --verify`).
4. Manually validate affected UI/state flows.
