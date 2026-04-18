# CutBar

[![Release](https://img.shields.io/github/v/release/ezzabuzaid/CutBar?include_prereleases&sort=semver)](https://github.com/ezzabuzaid/CutBar/releases)
[![Release On Tag](https://github.com/ezzabuzaid/CutBar/actions/workflows/release-on-tag.yml/badge.svg)](https://github.com/ezzabuzaid/CutBar/actions/workflows/release-on-tag.yml)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-2f312d)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/swift-6-3d755d)](https://swift.org)

CutBar is a standalone macOS menu bar app (Swift Package) for logging meals and tracking daily protein/calorie progress.

## What It Does

- Runs as a menu bar extra with quick status.
- Tracks entries across fixed meal slots (`meal1`, `shake`, `meal2`).
- Shows dashboard and meal history windows.
- Persists data in a local SQLite store.

## Requirements

- macOS 14+
- Xcode with Swift 6 toolchain

## Install

### Option 1: Install from GitHub Release (Recommended)

1. Open the project releases page on GitHub.
2. Download the latest `CutBar-<version>.dmg`.
3. Open the DMG and drag `CutBar.app` to `Applications`.
4. Launch `CutBar.app`.

### Option 2: Run from Source

```bash
git clone <repo-url>
cd CutBar
./scripts/build_and_run.sh
```

## Quick Start

Run the app:

```bash
./scripts/build_and_run.sh
```

Useful modes:

```bash
./scripts/build_and_run.sh --verify
./scripts/build_and_run.sh --logs
./scripts/build_and_run.sh --telemetry
./scripts/build_and_run.sh --debug
```

## Testing

Run tests:

```bash
swift test --disable-sandbox
```

For restricted/sandboxed environments, use local cache paths:

```bash
mkdir -p .tmp-swift-cache/home .tmp-swift-cache/clang-module-cache .tmp-swift-cache/swiftpm-cache
HOME="$PWD/.tmp-swift-cache/home" \
CLANG_MODULE_CACHE_PATH="$PWD/.tmp-swift-cache/clang-module-cache" \
SWIFTPM_CACHE_DIR="$PWD/.tmp-swift-cache/swiftpm-cache" \
swift test --disable-sandbox
```

## Development Docs

- [Contributing Guide](CONTRIBUTING.md)
- [Developers Guide](DEVELOPERS.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Local Development](docs/LOCAL_DEVELOPMENT.md)
- [Testing Guide](docs/TESTING.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Changelog](CHANGELOG.md)

## Release

Local manual release:

```bash
./scripts/release.sh <version>
```

Automated release is tag-driven via `.github/workflows/release-on-tag.yml`:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

On tag push, the workflow validates tag format and `main` ancestry, builds/signs/notarizes, and publishes:

- `CutBar-<version>.dmg`
- `CutBar-<version>.app.zip`

Full release details and required secrets are documented in [docs/RELEASE.md](docs/RELEASE.md).

## Security

Report vulnerabilities using the process in [SECURITY.md](SECURITY.md).
