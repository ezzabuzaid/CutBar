# Release Guide

## Release Paths

- Local manual release: `./scripts/release.sh <version>`
- Automated tag release: `.github/workflows/release-on-tag.yml`

## Local Manual Release

```bash
./scripts/release.sh 1.2.3
```

Prerequisites:

- Developer ID certificate available in login keychain.
- Notary profile configured (default profile name: `CutBar`).
- Access to signing/notarization credentials on the release machine.

The script builds universal binaries (`arm64` + `x86_64`), signs, notarizes, staples, and creates:

- `dist/CutBar-<version>.app.zip`
- `dist/CutBar-<version>.dmg`

## Automated GitHub Tag Release

1. Push a semver tag prefixed with `v`:

```bash
git tag v1.2.3
git push origin v1.2.3
```

2. Workflow validates:
   - Tag format
   - Commit ancestry from `main`
3. Workflow runs release script and publishes GitHub Release artifacts.

Required GitHub secrets:

- `MACOS_CERT_P12_BASE64`
- `MACOS_CERT_PASSWORD`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`

Optional GitHub secrets:

- `NOTARY_PROFILE`
- `SIGNING_IDENTITY`

## Safety Checks

- `scripts/release.sh` refuses to run if exported key/cert files exist in the repo tree.
- Notary profile is validated before build/signing.

## Post-Release Validation

1. Download released DMG from GitHub Release.
2. Confirm app launches on a clean machine profile.
3. Verify notarization/stapling status via macOS Gatekeeper checks.
