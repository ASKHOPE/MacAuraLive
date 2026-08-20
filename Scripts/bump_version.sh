#!/bin/bash
set -e

# bump_version.sh - Intelligent commit-driven version bumper
# Usage:
#   ./Scripts/bump_version.sh            # Auto-detect from git commits since last tag
#   ./Scripts/bump_version.sh patch      # Force patch bump
#   ./Scripts/bump_version.sh minor      # Force minor bump
#   ./Scripts/bump_version.sh major      # Force major bump
#   ./Scripts/bump_version.sh --dry-run  # Preview next version calculation

FORCE_TYPE="$1"
DRY_RUN=0
if [ "$1" == "--dry-run" ] || [ "$2" == "--dry-run" ]; then
    DRY_RUN=1
    [ "$FORCE_TYPE" == "--dry-run" ] && FORCE_TYPE=""
fi

VERSION_FILE="version.json"
if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ $VERSION_FILE not found in project root!"
    exit 1
fi

CURRENT_VERSION=$(python3 -c "import json; print(json.load(open('$VERSION_FILE'))['version'])")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Calculate automatic build number from total git commits
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")
BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Find latest git tag or beginning of history
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$FORCE_TYPE" ]; then
    BUMP_TYPE="$FORCE_TYPE"
else
    # Auto-detect bump type using conventional commit patterns
    if [ -n "$LATEST_TAG" ]; then
        COMMITS=$(git log "${LATEST_TAG}..HEAD" --oneline)
    else
        COMMITS=$(git log -n 25 --oneline)
    fi

    if echo "$COMMITS" | grep -E "(BREAKING CHANGE|feat!:)" >/dev/null; then
        BUMP_TYPE="major"
    elif echo "$COMMITS" | grep -E "^[a-f0-9]+ feat" >/dev/null; then
        BUMP_TYPE="minor"
    else
        BUMP_TYPE="patch"
    fi
fi

case "$BUMP_TYPE" in
    major)
        NEW_MAJOR=$((MAJOR + 1))
        NEW_MINOR=0
        NEW_PATCH=0
        ;;
    minor)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$((MINOR + 1))
        NEW_PATCH=0
        ;;
    patch|*)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$MINOR
        NEW_PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔖 Version Bumper Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Current Version: v${CURRENT_VERSION}"
echo "Detected Type:   ${BUMP_TYPE}"
echo "Target Version:  v${NEW_VERSION} (Build ${BUILD_NUMBER})"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "ℹ️ Dry-run mode enabled. No changes applied."
    exit 0
fi

# Write updated version.json
python3 -c "
import json
data = json.load(open('$VERSION_FILE'))
data['version'] = '$NEW_VERSION'
data['build'] = '$BUILD_NUMBER'
json.dump(data, open('$VERSION_FILE', 'w'), indent=2)
"

# Also sync docs/checksums.json if present
if [ -f "docs/checksums.json" ]; then
    python3 -c "
import json
data = json.load(open('docs/checksums.json'))
data['version'] = '$NEW_VERSION'
data['buildNumber'] = '$BUILD_NUMBER'
data['filename'] = f'MacAuraLive-{data[\"version\"]}.dmg'
data['downloadUrl'] = f'https://github.com/ASKHOPE/MacAuraLive/releases/latest/download/{data[\"filename\"]}'
json.dump(data, open('docs/checksums.json', 'w'), indent=2)
"
fi

echo "✅ version.json updated to v${NEW_VERSION} (Build ${BUILD_NUMBER})"
