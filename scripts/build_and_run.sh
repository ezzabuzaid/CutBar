#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CutBar"
BUNDLE_ID="com.ezz.study.CutBar"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
CACHE_ROOT="$ROOT_DIR/tmp/cutbar-swift-cache"

mkdir -p \
  "$CACHE_ROOT/home" \
  "$CACHE_ROOT/clang-module-cache" \
  "$CACHE_ROOT/swiftpm-cache"

export HOME="$CACHE_ROOT/home"
export CLANG_MODULE_CACHE_PATH="$CACHE_ROOT/clang-module-cache"
export SWIFTPM_CACHE_DIR="$CACHE_ROOT/swiftpm-cache"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --disable-sandbox --package-path "$PACKAGE_DIR"
BUILD_BIN_DIR="$(swift build --disable-sandbox --package-path "$PACKAGE_DIR" --show-bin-path)"
BUILD_BINARY="$BUILD_BIN_DIR/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_FRAMEWORKS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

# Bundle any frameworks produced by SwiftPM (e.g. Sparkle) into Contents/Frameworks
# so @rpath lookups at runtime succeed.
shopt -s nullglob
BUNDLED_FRAMEWORK=0
for framework in "$BUILD_BIN_DIR"/*.framework; do
  cp -R "$framework" "$APP_FRAMEWORKS/"
  BUNDLED_FRAMEWORK=1
done
shopt -u nullglob

if [[ "$BUNDLED_FRAMEWORK" -eq 1 ]]; then
  # Ensure dyld resolves @rpath/*.framework from Contents/Frameworks.
  if ! /usr/bin/otool -l "$APP_BINARY" | grep -q "@executable_path/../Frameworks"; then
    /usr/bin/install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY"
  fi
fi

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
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.0.0-dev</string>
  <key>CFBundleVersion</key>
  <string>0.0.0-dev</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

sign_app_if_needed() {
  if /usr/bin/codesign --verify --deep --strict "$APP_BUNDLE" >/dev/null 2>&1; then
    return
  fi

  # Remove stale signatures first so re-signing works without --force.
  /usr/bin/codesign --remove-signature "$APP_BUNDLE" >/dev/null 2>&1 || true
  /usr/bin/codesign --deep --sign - "$APP_BUNDLE"
}

sign_app_if_needed

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
