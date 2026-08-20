#!/bin/bash

# Build script for MacAuraLive Universal 2 (Apple Silicon & Intel)
# ── Single source of truth: bump VERSION & BUILD_NUMBER here each release ─────
VERSION="1.8.1"
BUILD_NUMBER="121"
# ─────────────────────────────────────────────────────────────────────────────
set -e

# 1. Run Pre-Build Verification Test Suite
bash Scripts/verify_environment.sh

echo "🚀 Building MacAuraLive ${VERSION} Universal 2 (Apple Silicon & Intel x86_64)..."

swift build -c release --triple arm64-apple-macosx13.0
swift build -c release --triple x86_64-apple-macosx13.0

mkdir -p "build/universal"
lipo -create -output "build/universal/MacAuraLive" \
    ".build/arm64-apple-macosx/release/MacAuraLive" \
    ".build/x86_64-apple-macosx/release/MacAuraLive"

# Minify executable by stripping unneeded debug symbol tables
echo "🗜️ Minifying binary with dead symbol stripping..."
strip -u -r "build/universal/MacAuraLive"

BUILD_DIR="build/MacAuraLive.app/Contents"
rm -rf "build/MacAuraLive.app"
mkdir -p "$BUILD_DIR/MacOS"
mkdir -p "$BUILD_DIR/Resources"

# Copy compiled universal stripped executable
cp "build/universal/MacAuraLive" "$BUILD_DIR/MacOS/MacAuraLive"
chmod +x "$BUILD_DIR/MacOS/MacAuraLive"

# Copy Resources (including PrivacyInfo.xcprivacy, Assets, Runtime, Wallpapers)
if [ -d "Sources/MacAuraLive/Resources" ]; then
    cp -R "Sources/MacAuraLive/Resources/" "$BUILD_DIR/Resources/"
fi

# Copy AppIcon.icns
if [ -f "Sources/MacAuraLive/Resources/Assets/AppIcon.icns" ]; then
    cp "Sources/MacAuraLive/Resources/Assets/AppIcon.icns" "$BUILD_DIR/Resources/AppIcon.icns"
    echo "📦 AppIcon.icns copied to bundle Resources/"
fi

# Copy StatusBarIcon.png
if [ -f "Sources/MacAuraLive/Resources/Assets/StatusBarIcon.png" ]; then
    cp "Sources/MacAuraLive/Resources/Assets/StatusBarIcon.png" "$BUILD_DIR/Resources/StatusBarIcon.png"
    echo "📦 StatusBarIcon.png copied to bundle Resources/"
fi

# Generate Info.plist — version injected automatically from $VERSION / $BUILD_NUMBER
cat <<EOF > "$BUILD_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacAuraLive</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.macauralive.app</string>
    <key>CFBundleName</key>
    <string>MacAuraLive</string>
    <key>CFBundleDisplayName</key>
    <string>MacAuraLive</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSScreenCaptureUsageDescription</key>
    <string>MacAuraLive checks real-time window occlusion to automatically pause live wallpapers during full-screen apps and games, preserving GPU energy.</string>
</dict>
</plist>
EOF

# Code sign ad-hoc
echo "🔒 Code signing Universal MacAuraLive.app..."
codesign --force --deep --sign - "build/MacAuraLive.app"

echo "✅ Universal 2 App bundle created and signed at: build/MacAuraLive.app"

# ── DMG Packaging ─────────────────────────────────────────────────────────────
DMG_NAME="MacAuraLive-${VERSION}.dmg"
DMG_STAGING="build/dmg_staging"
DMG_OUTPUT="build/${DMG_NAME}"

echo "📦 Creating DMG installer: ${DMG_NAME}..."

rm -rf "${DMG_STAGING}" "${DMG_OUTPUT}"
mkdir -p "${DMG_STAGING}"

cp -R "build/MacAuraLive.app" "${DMG_STAGING}/MacAuraLive.app"
ln -s /Applications "${DMG_STAGING}/Applications"

for doc in EULA.md LICENSE PRIVACY_POLICY.md THIRD_PARTY_LICENSES.md; do
    [ -f "${doc}" ] && cp "${doc}" "${DMG_STAGING}/${doc}"
done

hdiutil create \
    -volname "MacAuraLive ${VERSION}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_OUTPUT}"

rm -rf "${DMG_STAGING}"
echo "✅ DMG created at: ${DMG_OUTPUT}"

# ── Cryptographic Checksums ───────────────────────────────────────────────────
echo ""
echo "🔐 Generating checksums..."

SHA256=$(shasum -a 256 "${DMG_OUTPUT}" | awk '{print $1}')
MD5=$(md5 -q "${DMG_OUTPUT}")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# .sha256 and .md5 sidecar files next to the DMG
echo "${SHA256}  ${DMG_NAME}" > "${DMG_OUTPUT}.sha256"
echo "${MD5}  ${DMG_NAME}"    > "${DMG_OUTPUT}.md5"

# Human-readable CHECKSUMS.txt
cat > "build/CHECKSUMS.txt" << CSEOF
===================================================================
 MacAuraLive v${VERSION} Official Universal Release Checksums
===================================================================
File: ${DMG_NAME}
Architecture: Universal 2 (Apple Silicon ARM64 + Intel x86_64)
Date: ${BUILD_DATE}

SHA-256:
${SHA256}  ${DMG_NAME}

MD5:
${MD5}  ${DMG_NAME}

Verify with:
  shasum -a 256 ${DMG_NAME}
  md5 -q ${DMG_NAME}
===================================================================
CSEOF

# ── docs/checksums.json — website reads this automatically on load ────────────
cat > "docs/checksums.json" << JSONEOF
{
  "version": "${VERSION}",
  "buildNumber": "${BUILD_NUMBER}",
  "date": "${BUILD_DATE}",
  "filename": "${DMG_NAME}",
  "downloadUrl": "https://github.com/ASKHOPE/MacAuraLive/releases/latest/download/${DMG_NAME}",
  "sha256": "${SHA256}",
  "md5": "${MD5}"
}
JSONEOF

echo ""
echo "🔐 Cryptographic Checksums"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SHA-256: ${SHA256}"
echo "MD5:     ${MD5}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 DMG:              ${DMG_OUTPUT}"
echo "📁 SHA-256 sidecar:  ${DMG_OUTPUT}.sha256"
echo "📁 MD5 sidecar:      ${DMG_OUTPUT}.md5"
echo "📁 CHECKSUMS.txt:    build/CHECKSUMS.txt"
echo "📁 Website JSON:     docs/checksums.json"
