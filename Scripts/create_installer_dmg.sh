#!/bin/bash

# MacAuraLive DMG Installer Builder Script (Apple Silicon Native)
set -e

echo "🚀 Packaging MacAuraLive DMG Installer for Apple Silicon..."

# Ensure release build exists
bash Scripts/build_app.sh

DMG_TEMP_DIR="build/dmg_temp"
DMG_OUTPUT="build/MacAuraLive_v1.6.0_Installer_AppleSilicon.dmg"
DMG_STAGING="build/dmg_staging"
DMG_VOLUME_NAME="MacAuraLive Installer"
SOURCE_APP="build/MacAuraLive.app"

# Clean prior build artifacts
rm -rf "$DMG_OUTPUT" "$DMG_STAGING"

mkdir -p "$DMG_STAGING"
cp -R "$SOURCE_APP" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Copy verified Legal Compliance & Documentation Suite to DMG
cp -f "CHANGELOG.md" "$DMG_STAGING/CHANGELOG.md" 2>/dev/null || true
cp -f "Legal/LICENSE" "$DMG_STAGING/LICENSE" 2>/dev/null || true
cp -f "Legal/TERMS_OF_SERVICE.md" "$DMG_STAGING/TERMS_OF_SERVICE.md" 2>/dev/null || true
cp -f "Legal/PRIVACY_POLICY.md" "$DMG_STAGING/PRIVACY_POLICY.md" 2>/dev/null || true
cp -f "Legal/DISCLAIMER.md" "$DMG_STAGING/DISCLAIMER.md" 2>/dev/null || true
cp -f "Legal/THIRD_PARTY_LICENSES.md" "$DMG_STAGING/THIRD_PARTY_LICENSES.md" 2>/dev/null || true
cp -f "Legal/EULA.md" "$DMG_STAGING/EULA.md" 2>/dev/null || true

echo "📦 Creating disk image: $DMG_OUTPUT"
hdiutil create -srcfolder "$DMG_STAGING" -volname "$DMG_VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -ov -format UDZO "$DMG_OUTPUT"

rm -rf "$DMG_STAGING"

# Generate cryptographic checksums
echo "🔑 Generating SHA-256 and MD5 checksum files..."
DMG_FILENAME="MacAuraLive_v1.6.0_Installer_AppleSilicon.dmg"
cd build
shasum -a 256 "$DMG_FILENAME" > "${DMG_FILENAME}.sha256"
md5 -r "$DMG_FILENAME" > "${DMG_FILENAME}.md5"

cat << EOF > CHECKSUMS.txt
===================================================================
 MacAuraLive v1.6.0 Official Release Checksums
===================================================================
File: $DMG_FILENAME

SHA-256:
$(cat "${DMG_FILENAME}.sha256")

MD5:
$(cat "${DMG_FILENAME}.md5")
===================================================================
EOF

cd ..

echo "✅ DMG Installer created successfully at: $DMG_OUTPUT"
echo "✅ Checksum files generated: ${DMG_OUTPUT}.sha256, ${DMG_OUTPUT}.md5, build/CHECKSUMS.txt"
