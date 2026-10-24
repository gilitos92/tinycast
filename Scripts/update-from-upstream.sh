#!/bin/bash
# Fork only: merge abue-ammar/tinycast into `development`, test, install and push the result.
# After resolving merge conflicts by hand and committing, re-run with --finish.
set -euo pipefail
cd "$(dirname "$0")/.."

# Files the fork deleted on purpose; upstream edits to them are dropped, never restored.
REMOVED=(.github .coderabbit.yaml)

merge_upstream() {
    local behind
    behind="$(git rev-list --count HEAD..upstream/main)"
    if [ "$behind" -eq 0 ]; then
        echo "✓ Already up to date with upstream"
        exit 0
    fi
    echo "▸ Merging ${behind} upstream commit(s)"
    git log --oneline HEAD..upstream/main
    git merge --no-ff --no-edit upstream/main && return
    for path in "${REMOVED[@]}"; do
        if git ls-files --unmerged -- "$path" | grep -q .; then
            git rm -rqf --ignore-unmatch -- "$path"
        fi
    done
    if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
        echo "✗ Resolve these conflicts, then: git commit --no-edit && $0 --finish"
        git diff --name-only --diff-filter=U
        exit 1
    fi
    git commit --no-edit
}

[ "$(git branch --show-current)" = "development" ] || { echo "✗ Switch to development first"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "✗ Commit or stash local changes first"; exit 1; }
git remote get-url upstream > /dev/null 2>&1 \
    || git remote add upstream https://github.com/abue-ammar/tinycast.git
git fetch upstream --tags

[ "${1:-}" = "--finish" ] || merge_upstream

# A merge that added or removed files must regenerate the project, or the build misses them.
xcodegen generate > /dev/null
if [ -n "$(git status --porcelain Tinycast.xcodeproj)" ]; then
    git commit -qm "Regenerate the Xcode project after the upstream merge" -- Tinycast.xcodeproj
fi

./Scripts/run-tests.sh
./Scripts/install-local.sh
git push origin development
echo "✓ Updated to upstream $(git describe --tags --abbrev=0 --match 'v*' upstream/main)"
