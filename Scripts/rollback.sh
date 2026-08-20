#!/bin/bash
set -e

# rollback.sh - Safe release rollback utility for MacAuraLive
# Usage:
#   ./Scripts/rollback.sh --list             # List available previous builds
#   ./Scripts/rollback.sh <version>          # Rollback version.json to specified version
#   ./Scripts/rollback.sh --last             # Rollback to the previous recorded build

HISTORY_FILE="build/build_history.json"

if [ "$1" == "--list" ] || [ -z "$1" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📜 MacAuraLive Build & Release History"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ -f "$HISTORY_FILE" ]; then
        python3 -c "
import json
try:
    history = json.load(open('$HISTORY_FILE'))
    for idx, item in enumerate(reversed(history)):
        print(f\"[{idx+1}] v{item.get('version')} (Build {item.get('build')}) - Commit: {item.get('commit', 'N/A')} - Date: {item.get('date', 'N/A')}\")
        if 'dmg' in item:
            print(f\"    Artifact: {item['dmg']}\")
except Exception as e:
    print('Error parsing history:', e)
"
    else
        echo "No local build_history.json found. Available git release tags:"
        git tag --sort=-version:refname | head -10
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
fi

TARGET="$1"

if [ "$TARGET" == "--last" ]; then
    if [ ! -f "$HISTORY_FILE" ]; then
        echo "❌ Cannot determine last build without $HISTORY_FILE"
        exit 1
    fi
    TARGET=$(python3 -c "
import json
history = json.load(open('$HISTORY_FILE'))
if len(history) >= 2:
    print(history[-2]['version'])
elif len(history) == 1:
    print(history[0]['version'])
else:
    print('')
")
    if [ -z "$TARGET" ]; then
        echo "❌ No previous build entry found in history."
        exit 1
    fi
    echo "🔄 Rolling back to last known build: v${TARGET}"
fi

# Clean leading 'v'
CLEAN_VERSION="${TARGET#v}"

# Search for matching entry in build history
PREV_BUILD=""
if [ -f "$HISTORY_FILE" ]; then
    PREV_BUILD=$(python3 -c "
import json
history = json.load(open('$HISTORY_FILE'))
match = next((item for item in history if item.get('version') == '$CLEAN_VERSION'), None)
if match:
    print(match.get('build', ''))
")
fi

if [ -z "$PREV_BUILD" ]; then
    PREV_BUILD="100"
fi

# Update version.json
python3 -c "
import json
data = json.load(open('version.json'))
data['version'] = '$CLEAN_VERSION'
data['build'] = '$PREV_BUILD'
json.dump(data, open('version.json', 'w'), indent=2)
"

# Also sync docs/checksums.json if present
if [ -f "docs/checksums.json" ]; then
    python3 -c "
import json
data = json.load(open('docs/checksums.json'))
data['version'] = '$CLEAN_VERSION'
data['buildNumber'] = '$PREV_BUILD'
data['filename'] = f'MacAuraLive-{data[\"version\"]}.dmg'
data['downloadUrl'] = f'https://github.com/ASKHOPE/MacAuraLive/releases/latest/download/{data[\"filename\"]}'
json.dump(data, open('docs/checksums.json', 'w'), indent=2)
"
fi

echo "✅ Successfully rolled back version.json to v${CLEAN_VERSION} (Build ${PREV_BUILD})"
echo "💡 You can now run 'bash Scripts/build_app.sh' to recompile the release bundle."
