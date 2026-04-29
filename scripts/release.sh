#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-0.0.2}"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
DOCS_DIR="$ROOT_DIR/docs"
UPDATES_DIR="$DOCS_DIR/releases"
STAGE_DIR="$BUILD_DIR/Strike-$VERSION"
APP_DIR="$BUILD_DIR/Strike.app"
ZIP_PATH="$DIST_DIR/Strike-$VERSION.zip"
DMG_PATH="$DIST_DIR/Strike-$VERSION.dmg"
SPARKLE_GENERATE_APPCAST="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"
# Base URL for enclosure links in appcast.xml (must be public HTTPS; Sparkle cannot use a private GitHub repo).
# Example: public "releases-only" repo → https://raw.githubusercontent.com/ORG/strike-updates/main/docs/releases/
# Must match the directory where you upload docs/releases/*.zip (trailing slash required).
APPCAST_URL_PREFIX="${STRIKE_UPDATE_DOWNLOAD_URL_PREFIX:-https://raw.githubusercontent.com/AscensionModel/strike/main/docs/releases/}"

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

mkdir -p "$UPDATES_DIR"
cp "$ZIP_PATH" "$UPDATES_DIR/"

if [ -x "$SPARKLE_GENERATE_APPCAST" ]; then
  if [ -n "${SPARKLE_PRIVATE_KEY:-}" ]; then
    printf "%s" "$SPARKLE_PRIVATE_KEY" | "$SPARKLE_GENERATE_APPCAST" \
      --ed-key-file - \
      --download-url-prefix "$APPCAST_URL_PREFIX" \
      -o "$DOCS_DIR/appcast.xml" \
      "$UPDATES_DIR"
  else
    "$SPARKLE_GENERATE_APPCAST" \
      --download-url-prefix "$APPCAST_URL_PREFIX" \
      -o "$DOCS_DIR/appcast.xml" \
      "$UPDATES_DIR"
  fi
else
  echo "warning: Sparkle generate_appcast not found; run swift build first"
fi

echo "$ZIP_PATH"
echo "$DMG_PATH"
echo "$DOCS_DIR/appcast.xml"
echo "Upload docs/appcast.xml and docs/releases/ to your public update host. SUFeedURL in Info.plist must point at the hosted appcast.xml (prefix used: $APPCAST_URL_PREFIX)."
