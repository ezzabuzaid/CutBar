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
- `SPARKLE_ED_PUBLIC_KEY` — base64 ed25519 public key; required for stable releases.
- `SPARKLE_ED_PRIVATE_KEY` — base64 ed25519 private key; required for stable releases.

Optional GitHub secrets:

- `NOTARY_PROFILE`
- `SIGNING_IDENTITY`

## Auto-Updates (Sparkle)

Stable releases publish a signed `appcast.xml` as a GitHub Release asset. Shipped
apps fetch the feed at:

```
https://github.com/ezzabuzaid/CutBar/releases/latest/download/appcast.xml
```

Each entry in the feed references the release's `CutBar-<version>.dmg` and
carries an EdDSA signature; the Sparkle runtime in the installed app verifies
the signature with the `SUPublicEDKey` baked into Info.plist at build time.

### One-Time Key Generation

Sparkle's tools ship alongside the framework. From a fresh checkout:

```bash
curl -fsSLo /tmp/sparkle.tar.xz \
  https://github.com/sparkle-project/Sparkle/releases/download/2.6.4/Sparkle-2.6.4.tar.xz
mkdir -p /tmp/sparkle && tar -xf /tmp/sparkle.tar.xz -C /tmp/sparkle
/tmp/sparkle/bin/generate_keys
```

`generate_keys` stores the private key in your login keychain and prints the
base64 public key. Export the private key for CI:

```bash
/tmp/sparkle/bin/generate_keys -x sparkle-ed-private.key
```

Store the two halves:

- Paste the base64 public key into `SPARKLE_ED_PUBLIC_KEY`.
- Paste the file contents of `sparkle-ed-private.key` into `SPARKLE_ED_PRIVATE_KEY`.
- Delete `sparkle-ed-private.key` from disk — the keychain copy is authoritative.

**Rotation is destructive.** Shipped clients trust exactly one public key. If
the key is rotated, older installs will refuse every subsequent update until
they reinstall manually.

### Local Smoke Test

Sparkle 2 rejects `file://` feeds and DMG enclosures — they must be `http(s)://`.
Run a one-off HTTP server on loopback for local testing.

1. Export the private key: `/tmp/sparkle/bin/generate_keys -x ~/sparkle-priv.key`
2. Build a release with a bumped version, pointing the feed at a loopback URL:
   ```bash
   SPARKLE_ED_PUBLIC_KEY='<base64-pubkey>' \
   SPARKLE_ED_KEY_FILE="$HOME/sparkle-priv.key" \
   APPCAST_FEED_URL="http://127.0.0.1:8765/appcast.xml" \
     ./scripts/release.sh 99.0.0
   ```
3. Hand-author `/tmp/appcast.xml` from the CI template, pointing the enclosure
   `url` at `http://127.0.0.1:8765/CutBar-99.0.0.dmg` and copying the
   `sparkle:edSignature="..." length="..."` pair from `dist/CutBar-99.0.0.dmg.ed`
   verbatim into the `<enclosure>` element.
4. Serve both files:
   ```bash
   cp dist/CutBar-99.0.0.dmg /tmp/
   cd /tmp && python3 -m http.server 8765
   ```
5. Launch an older build of the app (with the same public key baked in). On a
   menu-bar app the update alert may take a moment to appear — check **About
   → Check for Updates…** to trigger the prompt immediately.

### Pre-Releases

Tags that include a `-` (e.g. `v1.2.0-rc.1`) skip the appcast + sidecar upload.
Users on the stable channel will not see pre-release versions.

## Safety Checks

- `scripts/release.sh` refuses to run if exported key/cert files exist in the repo tree.
- Notary profile is validated before build/signing.

## Post-Release Validation

1. Download released DMG from GitHub Release.
2. Confirm app launches on a clean machine profile.
3. Verify notarization/stapling status via macOS Gatekeeper checks.
