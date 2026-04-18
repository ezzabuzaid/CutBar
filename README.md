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

### Local Manual Release

```bash
./scripts/release.sh <version>
```

Release prerequisites:

- Valid Developer ID cert matching `SIGNING_IDENTITY` in `scripts/release.sh`
- Configured notarytool profile matching `NOTARY_PROFILE` in `scripts/release.sh`
- Codesign + notarization access on the machine running the release script

### Automated GitHub Tag Release

Tag-based releases are fully automated through
`.github/workflows/release-on-tag.yml`.

Trigger a release by pushing a semver tag with `v` prefix:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

The workflow only runs on `v*` tags and:

- Validates tag format as `v<semver>`
- Derives app version by stripping leading `v`
- Fails if the tagged commit is not reachable from `main`
- Marks prerelease tags (for example `v1.2.3-rc.1`) as GitHub prereleases
- Builds/signs/notarizes with `./scripts/release.sh <version>`
- Publishes a GitHub Release with:
  - `CutBar-<version>.dmg`
  - `CutBar-<version>.app.zip`

Required repository secrets:

- `MACOS_CERT_P12_BASE64`
- `MACOS_CERT_PASSWORD`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`

Optional repository secrets:

- `NOTARY_PROFILE` (defaults to `CutBar`)
- `SIGNING_IDENTITY` (defaults to script-derived identity)
