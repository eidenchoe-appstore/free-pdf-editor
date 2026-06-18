#!/usr/bin/env bash
set -euo pipefail

APP_DISPLAY_NAME="Free PDF Editor"
VERSION="0.0.1"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DMG_ROOT="$DIST_DIR/dmg-root"
APP_BUNDLE="$DIST_DIR/$APP_DISPLAY_NAME.app"
DMG_PATH="$DIST_DIR/FreePDFEditor-v$VERSION.dmg"

CONFIGURATION=release "$ROOT_DIR/script/build_and_run.sh" --package >/dev/null

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

/usr/bin/hdiutil create \
  -volname "$APP_DISPLAY_NAME $VERSION" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

/usr/bin/hdiutil verify "$DMG_PATH" >/dev/null
rm -rf "$DMG_ROOT"

echo "$DMG_PATH"
