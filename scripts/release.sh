#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-0.0.1}"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$BUILD_DIR/Strike-$VERSION"
APP_DIR="$BUILD_DIR/Strike.app"
ZIP_PATH="$DIST_DIR/Strike-$VERSION.zip"
DMG_PATH="$DIST_DIR/Strike-$VERSION.dmg"

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/package-app.sh"

rm -rf "$DIST_DIR" "$STAGE_DIR"
mkdir -p "$DIST_DIR" "$STAGE_DIR"
cp -R "$APP_DIR" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
hdiutil create \
  -volname "Strike $VERSION" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "$ZIP_PATH"
echo "$DMG_PATH"
