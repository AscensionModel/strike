#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${CONFIGURATION:-release}"
UNIVERSAL="${UNIVERSAL:-1}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/Strike.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$ROOT_DIR/build/AppIcon.iconset"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
ARM_BUILD_DIR="$ROOT_DIR/.build/arm64"
X86_BUILD_DIR="$ROOT_DIR/.build/x86_64"

cd "$ROOT_DIR"
if [ "$CONFIGURATION" = "release" ] && [ "$UNIVERSAL" = "1" ]; then
  swift build -c "$CONFIGURATION" --triple arm64-apple-macosx13.0 --scratch-path "$ARM_BUILD_DIR"
  swift build -c "$CONFIGURATION" --triple x86_64-apple-macosx13.0 --scratch-path "$X86_BUILD_DIR"
else
  swift build -c "$CONFIGURATION"
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
if [ "$CONFIGURATION" = "release" ] && [ "$UNIVERSAL" = "1" ]; then
  lipo -create \
    "$ARM_BUILD_DIR/arm64-apple-macosx/release/Strike" \
    "$X86_BUILD_DIR/x86_64-apple-macosx/release/Strike" \
    -output "$MACOS_DIR/Strike"
else
  cp ".build/$CONFIGURATION/Strike" "$MACOS_DIR/Strike"
fi
cp "$ROOT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ "$CONFIGURATION" = "release" ] && [ "$UNIVERSAL" = "1" ] && [ -d "$ARM_BUILD_DIR/arm64-apple-macosx/release/Strike_Strike.bundle" ]; then
  cp -R "$ARM_BUILD_DIR/arm64-apple-macosx/release/Strike_Strike.bundle" "$RESOURCES_DIR/"
elif [ -d ".build/$CONFIGURATION/Strike_Strike.bundle" ]; then
  cp -R ".build/$CONFIGURATION/Strike_Strike.bundle" "$RESOURCES_DIR/"
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
sips -z 16 16 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$ROOT_DIR/Assets/gong.png" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"

if [ -n "$SIGN_IDENTITY" ]; then
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
else
  codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "$APP_DIR"
