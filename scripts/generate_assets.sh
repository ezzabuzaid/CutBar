#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRAND_DIR="$ROOT_DIR/branding"
GEN_DIR="$BRAND_DIR/generated"
BUNDLE_IMAGES_DIR="$ROOT_DIR/Sources/CutBar/Resources/Assets.xcassets"

APP_ICON_SRC="$BRAND_DIR/cutbar-app-icon.svg"
MENUBAR_SRC="$BRAND_DIR/cutbar-menubar-template.svg"
LOCKUP_SRC="$BRAND_DIR/cutbar-lockup-horizontal.svg"
DMG_BG_SRC="$BRAND_DIR/cutbar-dmg-background.svg"

say() { printf "\n==> %s\n" "$*"; }

if ! command -v rsvg-convert >/dev/null 2>&1; then
  printf "rsvg-convert not found. Install with: brew install librsvg\n" >&2
  exit 1
fi
if ! command -v iconutil >/dev/null 2>&1; then
  printf "iconutil not found (expected on macOS).\n" >&2
  exit 1
fi

for f in "$APP_ICON_SRC" "$MENUBAR_SRC" "$LOCKUP_SRC" "$DMG_BG_SRC"; do
  if [[ ! -f "$f" ]]; then
    printf "Missing source: %s\n" "$f" >&2
    exit 1
  fi
done

mkdir -p "$GEN_DIR" "$BUNDLE_IMAGES_DIR"

render_png() {
  local src="$1" dst="$2" w="$3" h="$4"
  rsvg-convert --width="$w" --height="$h" --keep-aspect-ratio \
    --output="$dst" "$src" >/dev/null
}

say "App icon → .iconset + .icns"
ICONSET_DIR="$GEN_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

declare -a ICON_SIZES=(
  "16:icon_16x16.png"
  "32:icon_16x16@2x.png"
  "32:icon_32x32.png"
  "64:icon_32x32@2x.png"
  "128:icon_128x128.png"
  "256:icon_128x128@2x.png"
  "256:icon_256x256.png"
  "512:icon_256x256@2x.png"
  "512:icon_512x512.png"
  "1024:icon_512x512@2x.png"
)
for entry in "${ICON_SIZES[@]}"; do
  size="${entry%%:*}"
  name="${entry##*:}"
  render_png "$APP_ICON_SRC" "$ICONSET_DIR/$name" "$size" "$size"
done
iconutil -c icns "$ICONSET_DIR" -o "$GEN_DIR/AppIcon.icns"

say "Volume icon (reuse app icon)"
cp "$GEN_DIR/AppIcon.icns" "$GEN_DIR/VolumeIcon.icns"

say "Menu bar template (currentColor → solid ink)"
MENUBAR_IMAGESET="$BUNDLE_IMAGES_DIR/MenuBarIcon.imageset"
rm -rf "$MENUBAR_IMAGESET"
mkdir -p "$MENUBAR_IMAGESET"

MENUBAR_INK_TMP="$(mktemp -t cutbar-menubar.XXXXXX).svg"
trap 'rm -f "$MENUBAR_INK_TMP"' EXIT
# Substitute currentColor with solid black so template rendering is applied by AppKit.
sed 's/currentColor/#000000/g' "$MENUBAR_SRC" >"$MENUBAR_INK_TMP"

render_png "$MENUBAR_INK_TMP" "$MENUBAR_IMAGESET/MenuBarIcon.png"     18 18
render_png "$MENUBAR_INK_TMP" "$MENUBAR_IMAGESET/MenuBarIcon@2x.png"  36 36
render_png "$MENUBAR_INK_TMP" "$MENUBAR_IMAGESET/MenuBarIcon@3x.png"  54 54

cat >"$MENUBAR_IMAGESET/Contents.json" <<'JSON'
{
  "images" : [
    { "idiom" : "universal", "filename" : "MenuBarIcon.png",    "scale" : "1x" },
    { "idiom" : "universal", "filename" : "MenuBarIcon@2x.png", "scale" : "2x" },
    { "idiom" : "universal", "filename" : "MenuBarIcon@3x.png", "scale" : "3x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" },
  "properties" : { "template-rendering-intent" : "template" }
}
JSON

say "Wordmark lockup (for About panel)"
WORDMARK_IMAGESET="$BUNDLE_IMAGES_DIR/Wordmark.imageset"
rm -rf "$WORDMARK_IMAGESET"
mkdir -p "$WORDMARK_IMAGESET"

# Natural size 320×80; About panel renders at 220pt wide so 3x is sufficient without oversizing.
render_png "$LOCKUP_SRC" "$WORDMARK_IMAGESET/Wordmark.png"    320  80
render_png "$LOCKUP_SRC" "$WORDMARK_IMAGESET/Wordmark@2x.png" 640 160
render_png "$LOCKUP_SRC" "$WORDMARK_IMAGESET/Wordmark@3x.png" 720 180

cat >"$WORDMARK_IMAGESET/Contents.json" <<'JSON'
{
  "images" : [
    { "idiom" : "universal", "filename" : "Wordmark.png",    "scale" : "1x" },
    { "idiom" : "universal", "filename" : "Wordmark@2x.png", "scale" : "2x" },
    { "idiom" : "universal", "filename" : "Wordmark@3x.png", "scale" : "3x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON

say "DMG background"
DMG_OUT_DIR="$GEN_DIR/dmg"
mkdir -p "$DMG_OUT_DIR"
render_png "$DMG_BG_SRC" "$DMG_OUT_DIR/background.png"    660  400
render_png "$DMG_BG_SRC" "$DMG_OUT_DIR/background@2x.png" 1320 800

say "Done. Generated assets:"
ls -1 "$GEN_DIR"
ls -1 "$DMG_OUT_DIR"
ls -1 "$BUNDLE_IMAGES_DIR"
