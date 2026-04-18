#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CutBar"
BUNDLE_ID="com.ezz.study.CutBar"
MIN_SYSTEM_VERSION="14.0"
TEAM_ID="${TEAM_ID:-WM5KTF36L4}"
NOTARY_PROFILE="${NOTARY_PROFILE:-CutBar}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: IZZIDDEN ABU-ZAID (${TEAM_ID})}"
VERSION="${1:-1.0.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ENTITLEMENTS="$DIST_DIR/CutBar.entitlements"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
BRAND_GEN_DIR="$ROOT_DIR/branding/generated"
APP_ICON_SRC="$BRAND_GEN_DIR/AppIcon.icns"
VOLUME_ICON_SRC="$BRAND_GEN_DIR/VolumeIcon.icns"
DMG_BG_SRC="$BRAND_GEN_DIR/dmg/background.png"
DMG_BG_SRC_2X="$BRAND_GEN_DIR/dmg/background@2x.png"

say() { printf "\n==> %s\n" "$*"; }

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

legacy_secrets=()
while IFS= read -r -d '' legacy_secret; do
  legacy_secrets+=("$legacy_secret")
done < <(
  find "$ROOT_DIR" -type f \
    \( -name "DeveloperID.key" -o -name "DeveloperID.p12" \) \
    -print0
)

if ((${#legacy_secrets[@]} > 0)); then
  printf "Refusing to run while sensitive export exists in repo tree:\n" >&2
  for legacy_secret in "${legacy_secrets[@]}"; do
    printf "  - %s\n" "$legacy_secret" >&2
  done
  printf "Import certs into login keychain and delete exported key/p12 files first.\n" >&2
  exit 1
fi

say "Validating notary profile '$NOTARY_PROFILE'"
if ! notary_history_output="$(
  xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" 2>&1
)"; then
  printf "Unable to validate notarytool profile '%s'.\n" "$NOTARY_PROFILE" >&2
  printf "notarytool output:\n%s\n" "$notary_history_output" >&2
  printf "If the profile is missing, run:\n" >&2
  printf "  xcrun notarytool store-credentials '%s' --apple-id <apple-id> --team-id '%s' --password <app-specific-password>\n" "$NOTARY_PROFILE" "$TEAM_ID" >&2
  exit 1
fi

say "Generating brand assets from branding/*.svg"
"$ROOT_DIR/scripts/generate_assets.sh"

if [[ ! -f "$APP_ICON_SRC" ]]; then
  printf "Missing %s after generation.\n" "$APP_ICON_SRC" >&2
  exit 1
fi

say "Building Release (universal arm64 + x86_64)"
swift build -c release --disable-sandbox --package-path "$PACKAGE_DIR" \
  --arch arm64 --arch x86_64
BUILD_BIN_PATH="$(swift build -c release --disable-sandbox --package-path "$PACKAGE_DIR" --arch arm64 --arch x86_64 --show-bin-path)"
BUILD_BINARY="$BUILD_BIN_PATH/$APP_NAME"

say "Assembling app bundle at $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$APP_ICON_SRC" "$APP_RESOURCES/AppIcon.icns"

for bundle in "$BUILD_BIN_PATH"/*.bundle; do
  [ -d "$bundle" ] || continue
  bundle_name="$(basename "$bundle")"
  dest="$APP_RESOURCES/$bundle_name"
  rm -rf "$dest"
  mkdir -p "$dest/Contents/Resources"
  cat >"$dest/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}.resources</string>
  <key>CFBundleName</key>
  <string>${bundle_name%.bundle}</string>
  <key>CFBundlePackageType</key>
  <string>BNDL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
</dict>
</plist>
PLIST
  # Copy every item from the flat SPM bundle into the proper Resources/
  for item in "$bundle"/*; do
    [ -e "$item" ] || continue
    cp -R "$item" "$dest/Contents/Resources/"
  done
done

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.healthcare-fitness</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSHumanReadableCopyright</key>
  <string>© $(date +%Y) Ezz Abu-Zaid</string>
</dict>
</plist>
PLIST

cat >"$ENTITLEMENTS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.app-sandbox</key>
  <false/>
  <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
  <false/>
</dict>
</plist>
EOF

say "Signing nested bundles"
for bundle in "$APP_RESOURCES"/*.bundle; do
  [ -d "$bundle" ] || continue
  codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime "$bundle"
done

say "Signing app bundle (hardened runtime, timestamp)"
codesign --force --sign "$SIGNING_IDENTITY" \
  --entitlements "$ENTITLEMENTS" \
  --options runtime --timestamp \
  "$APP_BUNDLE"

say "Verifying signature"
codesign --verify --strict --deep --verbose=2 "$APP_BUNDLE"
spctl -a -vvv --type execute "$APP_BUNDLE" || true

say "Zipping app for notarization"
APP_ZIP="$DIST_DIR/${APP_NAME}-${VERSION}.app.zip"
rm -f "$APP_ZIP"
ditto -c -k --keepParent "$APP_BUNDLE" "$APP_ZIP"

say "Submitting app.zip to Apple for notarization"
xcrun notarytool submit "$APP_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

say "Stapling notarization ticket to .app"
xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"

say "Creating branded DMG from stapled app"
VOL_NAME="$APP_NAME $VERSION"
STAGING_DIR="$(mktemp -d -t cutbar-dmg)"
MOUNT_POINT="$(mktemp -d -t cutbar-mount)"
RW_DMG="$DIST_DIR/${APP_NAME}-${VERSION}.rw.dmg"

cleanup_dmg() {
  if mount | grep -q " on $MOUNT_POINT "; then
    hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1 || true
  fi
  rm -rf "$STAGING_DIR" "$MOUNT_POINT"
  rm -f "$RW_DMG"
}
trap cleanup_dmg EXIT

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

if [[ -f "$DMG_BG_SRC" ]]; then
  mkdir -p "$STAGING_DIR/.background"
  cp "$DMG_BG_SRC" "$STAGING_DIR/.background/background.png"
  if [[ -f "$DMG_BG_SRC_2X" ]]; then
    cp "$DMG_BG_SRC_2X" "$STAGING_DIR/.background/background@2x.png"
  fi
fi

if [[ -f "$VOLUME_ICON_SRC" ]]; then
  cp "$VOLUME_ICON_SRC" "$STAGING_DIR/.VolumeIcon.icns"
fi

rm -f "$DMG_PATH" "$RW_DMG"
hdiutil create -volname "$VOL_NAME" \
  -srcfolder "$STAGING_DIR" \
  -fs HFS+ -format UDRW \
  "$RW_DMG"

say "Styling DMG window via Finder"
hdiutil attach "$RW_DMG" -noautoopen -mountpoint "$MOUNT_POINT" >/dev/null

if [[ -f "$VOLUME_ICON_SRC" ]]; then
  SetFile -a C "$MOUNT_POINT"
fi

if [[ -f "$DMG_BG_SRC" ]]; then
  osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set sidebar width of container window to 0
    set bounds of container window to {200, 200, 860, 600}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 128
    set text size of theViewOptions to 13
    set background picture of theViewOptions to file ".background:background.png" of disk "$VOL_NAME"
    set position of item "$APP_NAME.app" of container window to {160, 245}
    set position of item "Applications" of container window to {500, 245}
    close
    open
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT
fi

sync
hdiutil detach "$MOUNT_POINT" -force >/dev/null || hdiutil detach "$MOUNT_POINT" >/dev/null

say "Compressing DMG to UDZO"
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"

say "Signing DMG"
codesign --force --sign "$SIGNING_IDENTITY" --timestamp "$DMG_PATH"

say "Submitting DMG for notarization (so it's stapled too)"
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

say "Stapling ticket to DMG"
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

say "Final verification"
spctl -a -vvv --type execute "$APP_BUNDLE"

say "Done: $DMG_PATH"
ls -lh "$DMG_PATH"
