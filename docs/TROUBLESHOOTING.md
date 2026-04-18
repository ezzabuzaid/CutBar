# Troubleshooting

## Build Fails with Toolchain Errors

Symptoms:

- `swift build` fails quickly
- Unknown Swift language version or SDK errors

Checks:

1. Confirm Xcode and Swift toolchain are installed.
2. Ensure command line tools are selected:

```bash
xcode-select -p
```

## App Does Not Launch from Script

Try verification mode first:

```bash
./scripts/build_and_run.sh --verify
```

If it fails:

- Check whether another `CutBar` process is stuck.
- Run in debug mode:

```bash
./scripts/build_and_run.sh --debug
```

## No Logs or Missing Telemetry

Use the script log modes:

```bash
./scripts/build_and_run.sh --logs
./scripts/build_and_run.sh --telemetry
```

If empty, verify the app actually launched and produced events.

## Storage Errors in UI

The app surfaces database read/write failures through `storageIssue`.

Likely causes:

- Corrupted SQLite file
- Permission issues writing in Application Support

Next steps:

1. Back up the existing DB file.
2. Inspect path in the error message.
3. Relaunch and reproduce with logs enabled.

## Local Release Fails at Notary Validation

If `notarytool` profile validation fails, create/update credentials:

```bash
xcrun notarytool store-credentials "CutBar" --apple-id <apple-id> --team-id <team-id> --password <app-specific-password>
```

## Signing Errors (codesign identity not found)

Check available signing identities:

```bash
security find-identity -v -p codesigning
```

Ensure `SIGNING_IDENTITY` matches an installed Developer ID Application certificate.

## CI Release Fails on Missing Secrets

Validate repository secrets are configured exactly as documented in [`docs/RELEASE.md`](RELEASE.md).
