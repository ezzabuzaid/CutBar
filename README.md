# CutBar

[![Release](https://img.shields.io/github/v/release/ezzabuzaid/CutBar?include_prereleases&sort=semver)](https://github.com/ezzabuzaid/CutBar/releases)
[![Release On Tag](https://github.com/ezzabuzaid/CutBar/actions/workflows/release-on-tag.yml/badge.svg)](https://github.com/ezzabuzaid/CutBar/actions/workflows/release-on-tag.yml)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-2f312d)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/swift-6-3d755d)](https://swift.org)

A menu bar meal tracker for your cut protocol. Protein and calories at a glance — and your data never leaves your Mac.

![CutBar](branding/generated/hero.png)

## Install

1. Grab the latest `CutBar-<version>.dmg` from [Releases](https://github.com/ezzabuzaid/CutBar/releases).
2. Open the DMG and drag **CutBar.app** to **Applications**.
3. Launch it. Look up — it lives in your menu bar.

Requires macOS 14 Sonoma or later. The app is signed and notarized. CutBar checks for updates in the background and installs new versions in-place via Sparkle; you can also trigger a check from **About CutBar → Check for Updates…**.

## What you see

**In the menu bar:** today's protein (g) and calories, live.

**Click it** to drop a compact panel with:

- The phase you're currently in — Fasting, Meal 1, Gym, Shake, or Meal 2 — with its time window.
- Progress bars toward your daily protein and calorie targets.
- All three meal slots with the protein logged in each.
- **Quick Log** — up to three pinned presets from your profile, or `+ New Entry` for anything else.
- Your last three entries (right-click to delete).

## The protocol

CutBar keeps three fixed slots (`Meal 1`, `Post-Gym Shake`, `Meal 2`) and lets you personalize:

- Daily targets (protein, calories, fat, carbs)
- Slot windows and per-slot targets
- Default entry source and restaurant calorie buffer
- Presets, including enabled/pinned state and pinned order for menu-bar Quick Log

## Windows

- **Dashboard** — full-day view with a card per slot, targets, and what you've logged.
- **Meal History** — scrollable list of past days, grouped by date.
- **Profile Settings** — personalize targets, windows, defaults, and presets.

Open either from the menu bar panel footer.

## Shortcuts

| Key | Action           |
| --- | ---------------- |
| ⌘N  | New entry        |
| ⌘,  | Profile settings |
| ⌘R  | Refresh totals   |
| ⌘Y  | Meal History     |
| ⌘S  | Save entry       |
| ⌘Q  | Quit             |

## Your data is yours

Everything is stored locally in a SQLite database at `~/Library/Application Support/CutBar/food-log.sqlite`. No network calls. No telemetry. No accounts.

## Security

Report vulnerabilities using the process in [SECURITY.md](SECURITY.md).

## For developers

Building from source, running tests, and cutting releases are covered in [DEVELOPERS.md](DEVELOPERS.md) and the [`docs/`](docs/) folder:

- [Architecture](docs/ARCHITECTURE.md)
- [Local Development](docs/LOCAL_DEVELOPMENT.md)
- [Testing Guide](docs/TESTING.md)
- [Release Process](docs/RELEASE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
