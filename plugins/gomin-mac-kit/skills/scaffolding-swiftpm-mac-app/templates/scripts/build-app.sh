#!/bin/bash
# Assembles build/MyApp.app from `swift build` (no .xcodeproj).
# Usage: bash scripts/build-app.sh [debug|release]
#   SIGN_ID="Developer ID Application: ..." to sign for distribution (default: ad-hoc "-").
set -euo pipefail

APP_NAME="MyApp"
CONFIG="${1:-release}"
SIGN_ID="${SIGN_ID:--}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/$APP_NAME.app"

cd "$ROOT"
# SwiftPM stamps the binary "sdk 14.0" (the deployment target) whatever SDK compiled it, and macOS 26 then draws it
# the pre-26 way — no Liquid Glass. Stamp the real SDK; the minimum stays macOS 14.
SDK_VERSION="$(xcrun --show-sdk-version)"
LINK_SDK=(-Xlinker -platform_version -Xlinker macos -Xlinker 14.0 -Xlinker "$SDK_VERSION")
swift build -c "$CONFIG" "${LINK_SDK[@]}"
BIN="$(swift build -c "$CONFIG" "${LINK_SDK[@]}" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "Sources/$APP_NAME/Info.plist" "$APP/Contents/Info.plist"
cp "$BIN/$APP_NAME" "$APP/Contents/MacOS/"
# .lproj at the bundle root, where Bundle.main looks (SwiftPM's resource bundle alone isn't found by a .app)
cp -R "Sources/$APP_NAME/Resources/"*.lproj "$APP/Contents/Resources/"

codesign --force --options runtime --sign "$SIGN_ID" "$APP"
codesign --verify --strict "$APP"

echo "Built $APP"
