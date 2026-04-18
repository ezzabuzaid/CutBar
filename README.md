# CutBar

Standalone macOS menu bar app (Swift Package).

## Requirements

- macOS 14+
- Xcode with Swift 6 toolchain

## Local Test

Use local cache paths when running in restricted/sandboxed environments:

```bash
mkdir -p .tmp-swift-cache/home .tmp-swift-cache/clang-module-cache .tmp-swift-cache/swiftpm-cache
HOME="$PWD/.tmp-swift-cache/home" \
CLANG_MODULE_CACHE_PATH="$PWD/.tmp-swift-cache/clang-module-cache" \
SWIFTPM_CACHE_DIR="$PWD/.tmp-swift-cache/swiftpm-cache" \
swift test --disable-sandbox
```

## Run App

```bash
./scripts/build_and_run.sh
```

Other modes:

```bash
./scripts/build_and_run.sh --verify
./scripts/build_and_run.sh --logs
./scripts/build_and_run.sh --telemetry
./scripts/build_and_run.sh --debug
```

## Release

```bash
./scripts/release.sh <version>
```

Release prerequisites:

- Valid Developer ID cert matching `SIGNING_IDENTITY` in `scripts/release.sh`
- Configured notarytool profile matching `NOTARY_PROFILE` in `scripts/release.sh`
- Codesign + notarization access on the machine running the release script
