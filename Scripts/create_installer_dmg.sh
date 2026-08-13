#!/bin/bash

# MacAura DMG Installer Builder Script (Apple Silicon Native)
set -e

echo "🚀 Packaging MacAura DMG Installer for Apple Silicon..."

# Ensure release build exists
bash Scripts/build_app.sh

DMG_TEMP_DIR="build/dmg_temp"
DMG_OUTPUT="build/MacAura_v1.2.0_Installer_AppleSilicon.dmg"

rm -rf "$DMG_TEMP_DIR" "$DMG_OUTPUT"
mkdir -p "$DMG_TEMP_DIR"

# Copy MacAura.app to DMG temp folder
cp -R "build/MacAura.app" "$DMG_TEMP_DIR/"

# Create symlink to /Applications for drag-to-install
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Create disk image via hdiutil
echo "📦 Creating disk image: $DMG_OUTPUT"
hdiutil create -volname "MacAura Installer" \
               -srcfolder "$DMG_TEMP_DIR" \
               -ov -format UDZO \
               "$DMG_OUTPUT"

rm -rf "$DMG_TEMP_DIR"

echo "✅ DMG Installer created successfully at: $DMG_OUTPUT"
