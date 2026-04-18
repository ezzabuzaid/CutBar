# Branding

Source-of-truth SVGs for the CutBar visual identity. Palette is kept in sync with `Sources/CutBar/Support/Theme.swift` — **edit the theme first, then recolor these**.

## Files

| File | Purpose |
| --- | --- |
| `cutbar-app-icon.svg` | 1024×1024 macOS app icon (forest gradient + lime fork) |
| `cutbar-menubar-template.svg` | 16×16 monochrome template (`currentColor`) for the menu bar |
| `cutbar-lockup-horizontal.svg` | Horizontal wordmark used in the About panel and DMG |
| `cutbar-icon.svg` | Flat mark, no background |
| `cutbar-avatar.svg` | Social avatar (not bundled into the app) |
| `cutbar-dmg-background.svg` | 660×400 DMG installer background |

## Palette

Sourced from `Theme.swift`:

- `#3d755d` forest accent (light)
- `#e4f222` lime accent (dark)
- `#f5f3ed` cream surface
- `#02120c` dark surface
- `#2f312d` ink

## Regenerate

```bash
./scripts/generate_assets.sh
```

Requires `librsvg` (`brew install librsvg`). Writes to `branding/generated/` and `Sources/CutBar/Resources/Assets.xcassets/`. Commit both sources and outputs.
