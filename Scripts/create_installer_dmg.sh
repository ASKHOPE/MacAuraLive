#!/bin/bash

# MacAuraLive DMG Installer Builder Script (Universal 2: Apple Silicon & Intel)
set -e

echo "🚀 Packaging MacAuraLive Universal 2 DMG Installer (Apple Silicon & Intel)..."

# Ensure universal release build exists
bash Scripts/build_app.sh

DMG_OUTPUT="build/MacAuraLive_v1.8.0_Universal_Installer.dmg"
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
cp -f "LICENSE" "$DMG_STAGING/LICENSE" 2>/dev/null || true
cp -f "TERMS_OF_SERVICE.md" "$DMG_STAGING/TERMS_OF_SERVICE.md" 2>/dev/null || true
cp -f "PRIVACY_POLICY.md" "$DMG_STAGING/PRIVACY_POLICY.md" 2>/dev/null || true
cp -f "EULA.md" "$DMG_STAGING/EULA.md" 2>/dev/null || true
cp -f "DMCA.md" "$DMG_STAGING/DMCA.md" 2>/dev/null || true
cp -f "THIRD_PARTY_LICENSES.md" "$DMG_STAGING/THIRD_PARTY_LICENSES.md" 2>/dev/null || true
cp -f "SECURITY.md" "$DMG_STAGING/SECURITY.md" 2>/dev/null || true
cp -f "USER_GUIDE.md" "$DMG_STAGING/USER_GUIDE.md" 2>/dev/null || true

echo "📦 Creating disk image: $DMG_OUTPUT"
hdiutil create -srcfolder "$DMG_STAGING" -volname "$DMG_VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -ov -format UDZO "$DMG_OUTPUT"

rm -rf "$DMG_STAGING"

# Generate cryptographic checksums
echo "🔑 Generating SHA-256 and MD5 checksum files..."
DMG_FILENAME="MacAuraLive_v1.8.0_Universal_Installer.dmg"
cd build
shasum -a 256 "$DMG_FILENAME" > "${DMG_FILENAME}.sha256"
md5 -r "$DMG_FILENAME" > "${DMG_FILENAME}.md5"

cat << EOF > CHECKSUMS.txt
===================================================================
 MacAuraLive v1.8.0 Official Universal Release Checksums
===================================================================
File: $DMG_FILENAME
Architecture: Universal 2 (Apple Silicon ARM64 + Intel x86_64)

SHA-256:
$(cat "${DMG_FILENAME}.sha256")

MD5:
$(cat "${DMG_FILENAME}.md5")
===================================================================
EOF

cd ..

echo "✅ Universal DMG Installer created successfully at: $DMG_OUTPUT"
echo "✅ Checksum files generated: ${DMG_OUTPUT}.sha256, ${DMG_OUTPUT}.md5, build/CHECKSUMS.txt"
