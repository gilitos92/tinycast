#!/bin/bash
# Fork only: build a Release Tinycast.app and replace /Applications/Tinycast.app with it.
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="${IDENTITY:-Tinycast Self-Signed}"
# Outside the clone, which lives in iCloud Drive and must not sync half a gigabyte of build output.
DERIVED="${DERIVED:-$HOME/Library/Developer/Xcode/DerivedData/Tinycast-fork}"
# The newest upstream tag, so a cached upstream update check never looks newer than this build.
BASE="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo v0.0.0)"
VERSION="${VERSION:-$(echo "${BASE#v}" | sed -E 's/-beta\.[0-9]+$//')}"
BUILD="$(git rev-list --count HEAD)"

echo "▸ Building Tinycast ${VERSION} (${BUILD})"
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath "$DERIVED" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" \
    build -quiet

APP="$DERIVED/Build/Products/Release/Tinycast.app"
echo "▸ Installing to /Applications"
osascript -e 'tell application id "com.tinycast.app" to quit' 2>/dev/null || true
while pgrep -x Tinycast > /dev/null; do sleep 0.2; done
rm -rf /Applications/Tinycast.app
ditto "$APP" /Applications/Tinycast.app
open /Applications/Tinycast.app
echo "✓ Tinycast ${VERSION} (${BUILD}) installed"
