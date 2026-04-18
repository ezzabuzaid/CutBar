# Security Policy

## Supported Versions

Security fixes are applied to the latest `main` branch.

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Older tags/releases | No |

## Reporting a Vulnerability

Do not open public issues for security vulnerabilities.

Use GitHub private vulnerability reporting (Security Advisories) for this repository.
If private reporting is unavailable, open a minimal issue requesting a private contact channel and do not include exploit details.

## What to Include

- Affected component/file
- Reproduction steps
- Expected vs actual behavior
- Potential impact
- Suggested mitigation (if available)

## Response Targets

- Initial acknowledgement: within 3 business days
- Triage decision: within 7 business days
- Fix timeline: shared after triage based on severity and release risk

## Secret Handling

- Never commit signing/exported cert files (`.p12`, `.key`).
- Use local keychain and CI secrets for notarization/signing.
- Rotate credentials immediately if accidental exposure is suspected.
