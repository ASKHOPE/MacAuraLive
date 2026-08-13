#!/bin/bash

# MacAuraLive DMG Installer Builder Script (Apple Silicon Native)
set -e

echo "🚀 Packaging MacAuraLive DMG Installer for Apple Silicon..."

# Ensure release build exists
bash Scripts/build_app.sh

DMG_TEMP_DIR="build/dmg_temp"
DMG_OUTPUT="build/MacAuraLive_v1.2.0_Installer_AppleSilicon.dmg"

rm -rf "$DMG_TEMP_DIR" "$DMG_OUTPUT"
mkdir -p "$DMG_TEMP_DIR"

# Copy MacAuraLive.app to DMG temp folder
cp -R "build/MacAuraLive.app" "$DMG_TEMP_DIR/"

# Create symlink to /Applications for drag-to-install
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Create disk image via hdiutil
echo "📦 Creating disk image: $DMG_OUTPUT"
hdiutil create -volname "MacAuraLive Installer" \
               -srcfolder "$DMG_TEMP_DIR" \
               -ov -format UDZO \
               "$DMG_OUTPUT"

rm -rf "$DMG_TEMP_DIR"

echo "🔑 Generating SHA-256 and MD5 checksum files..."
cd build
DMG_FILENAME="MacAuraLive_v1.2.0_Installer_AppleSilicon.dmg"
shasum -a 256 "$DMG_FILENAME" > "${DMG_FILENAME}.sha256"
md5 -r "$DMG_FILENAME" > "${DMG_FILENAME}.md5"

cat <<EOF > CHECKSUMS.txt
===================================================================
 MacAuraLive v1.2.0 Official Release Checksums
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
