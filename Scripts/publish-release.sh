#!/bin/bash
# Fork only: build a tagged release and publish it on GitHub. Usage: publish-release.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="gilitos92/tinycast"
IDENTITY="${IDENTITY:-Tinycast Self-Signed}"
# Outside the clone, which lives in iCloud Drive and must not sync half a gigabyte of build output.
DERIVED="${DERIVED:-$HOME/Library/Developer/Xcode/DerivedData/Tinycast-fork-release}"
VERSION="${1:-$(sed -nE 's/^ *MARKETING_VERSION: *"?([0-9.]+)"?.*/\1/p' project.yml | head -1)}"
SOURCE_TAG="fork-v${VERSION}"
# The updater parses only `vX.Y.Z`; local tags stay `fork-v*` so upstream's `v*` never collide.
TAG="v${VERSION}"

fail() {
    echo "✗ $1" >&2
    exit 1
}

COMMIT="$(git rev-parse -q --verify "${SOURCE_TAG}^{commit}")" || fail "No tag ${SOURCE_TAG}."
git ls-remote --exit-code --tags origin "refs/tags/${SOURCE_TAG}" > /dev/null ||
    fail "Push ${SOURCE_TAG} first."
! gh release view "$TAG" --repo "$REPO" > /dev/null 2>&1 || fail "$TAG is already published."
BUILD="$(git rev-list --count "$COMMIT")"

OUT="$(mktemp -d)"
SRC="$OUT/src"
cleanup() {
    git worktree remove --force "$SRC" 2> /dev/null || true
    rm -rf "$OUT"
}
trap cleanup EXIT
git worktree add -q --detach "$SRC" "$COMMIT"

echo "▸ Building Tinycast ${VERSION} (${BUILD}) from ${SOURCE_TAG}"
xcodebuild -project "$SRC/Tinycast.xcodeproj" -scheme Tinycast -configuration Release \
    -derivedDataPath "$DERIVED" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" \
    build -quiet
APP="$DERIVED/Build/Products/Release/Tinycast.app"
"$SRC/Scripts/verify-signature.sh" "$APP"

ZIP="$OUT/Tinycast-${VERSION}.zip"
DMG="$OUT/Tinycast-${VERSION}.dmg"
echo "▸ Packaging"
# The only zip that leaves the signature verifiable, which the updater checks before installing.
ditto -c -k --keepParent --sequesterRsrc "$APP" "$ZIP"
mkdir "$OUT/stage"
cp -R "$APP" "$OUT/stage/"
ln -s /Applications "$OUT/stage/Applications"
diskutil image create from "$OUT/stage" --format UDZO --volumeName "Tinycast" "$DMG" > /dev/null 2>&1

NOTES="$OUT/notes.md"
awk -v head="## [${VERSION}]" '
    index($0, head) == 1 { found = 1; next }
    found && /^## \[/ { exit }
    found { print }
' "$SRC/CHANGELOG.md" > "$NOTES"
grep -q '[^[:space:]]' "$NOTES" || fail "CHANGELOG.md has no [${VERSION}] section."
cat >> "$NOTES" << EOF

<!-- tinycast:install -->

## Install

Download \`Tinycast-${VERSION}.dmg\` and drag Tinycast into Applications. It needs macOS 26 or later
on Apple silicon. macOS blocks the first launch because the app isn't notarized by Apple; the
[README](https://github.com/${REPO}#install-this-fork) shows how to open it. After that, Tinycast
updates itself.
EOF

echo "▸ Publishing ${TAG}"
gh release create "$TAG" --repo "$REPO" --target "$COMMIT" \
    --title "Tinycast ${VERSION}" --notes-file "$NOTES" "$ZIP" "$DMG"
echo "✓ https://github.com/${REPO}/releases/tag/${TAG}"
