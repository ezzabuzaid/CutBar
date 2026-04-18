# Contributing to CutBar

Thanks for contributing.

## Prerequisites

- macOS 14 or newer
- Xcode with Swift 6 toolchain

## Local Setup

1. Clone the repository.
2. Build and run the app:

```bash
./scripts/build_and_run.sh
```

3. Run tests (uses local cache paths for sandbox-friendly execution):

```bash
mkdir -p .tmp-swift-cache/home .tmp-swift-cache/clang-module-cache .tmp-swift-cache/swiftpm-cache
HOME="$PWD/.tmp-swift-cache/home" \
CLANG_MODULE_CACHE_PATH="$PWD/.tmp-swift-cache/clang-module-cache" \
SWIFTPM_CACHE_DIR="$PWD/.tmp-swift-cache/swiftpm-cache" \
swift test --disable-sandbox
```

## Development Workflow

1. Create a feature branch from `main`.
2. Make focused changes.
3. Add or update tests when behavior changes.
4. Update docs when commands, architecture, or release steps change.
5. Open a pull request.

## Pull Request Expectations

- Clear summary of the change and reason.
- Testing evidence (commands run + result).
- Screenshots or recordings for visible UI changes.
- No unrelated refactors in the same PR.

## Code Guidelines

- Keep state management in `CutBarModel`.
- Keep storage concerns in `FoodLogStore`.
- Keep UI logic inside SwiftUI views and avoid pushing persistence into views.
- Prefer small, composable functions and explicit names.

## Security and Secrets

- Never commit exported signing material (`.p12`, `.key`).
- Release signing/notarization credentials must come from keychain/CI secrets.
- If you find a security issue, follow [`SECURITY.md`](SECURITY.md).

## Release Changes

For user-visible behavior changes, add an entry to [`CHANGELOG.md`](CHANGELOG.md) under `Unreleased`.
