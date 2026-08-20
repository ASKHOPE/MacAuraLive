#!/bin/bash
set -e

# Package an official macOS GUI installer wizard (.pkg & DMG)
# Reads dynamic version from version.json

ROOT_DIR="$(pwd)"
VERSION=$(python3 -c "import json; print(json.load(open('version.json'))['version'])")
BUILD_NUMBER=$(python3 -c "import json; print(json.load(open('version.json')).get('build', '1'))")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛠️ Creating macOS Installation Wizard Package (.pkg)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Version: v${VERSION} (Build ${BUILD_NUMBER})"

PKG_ROOT="${ROOT_DIR}/build/pkg_root"
PKG_STAGING="${ROOT_DIR}/build/pkg_staging"
RESOURCES_DIR="${ROOT_DIR}/build/pkg_resources"
OUTPUT_DIR="${ROOT_DIR}/build/MacAuraLive_${VERSION}"
PKG_NAME="MacAuraLive_Installer_${VERSION}.pkg"
DMG_WIZARD_NAME="MacAuraLive-Setup-${VERSION}.dmg"

mkdir -p "$PKG_ROOT/Applications"
mkdir -p "$PKG_STAGING"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$OUTPUT_DIR"

# Ensure MacAuraLive.app exists in build
if [ ! -d "${ROOT_DIR}/build/MacAuraLive.app" ]; then
    echo "⚠️ MacAuraLive.app not found. Building now..."
    bash "${ROOT_DIR}/Scripts/build_app.sh"
fi

# Copy App to staging root
rm -rf "$PKG_ROOT/Applications/MacAuraLive.app"
cp -R "${ROOT_DIR}/build/MacAuraLive.app" "$PKG_ROOT/Applications/MacAuraLive.app"

# 1. Create Rich Text Welcome & Overview for the Wizard
cat << HTML > "$RESOURCES_DIR/welcome.html"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 18px; line-height: 1.5; color: #1f2937; }
h1 { color: #1e3a8a; margin-bottom: 4px; }
h3 { color: #6366f1; margin-top: 0px; }
.badge { display: inline-block; background: #e0e7ff; color: #4338ca; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
ul { padding-left: 20px; }
li { margin-bottom: 6px; }
</style>
</head>
<body>
<h1>Welcome to MacAuraLive</h1>
<h3>Next-Generation Live Wallpaper Engine for macOS</h3>
<span class="badge">Universal 2 • v${VERSION}</span>

<p>MacAuraLive transforms your Mac desktop and lock screen into an interactive, visually stunning canvas with low-power GPU rendering.</p>

<h4>What's Included:</h4>
<ul>
  <li><b>Dynamic Live Wallpapers:</b> Smooth 60fps MP4 loops, interactive WebGL, and animated GIFs.</li>
  <li><b>Moods & macOS Sync:</b> Automatic wallpaper and profile switching synced with macOS Focus & Sleep modes.</li>
  <li><b>Universal Multi-Monitor Spanning:</b> Independent or synchronized wallpapers across displays.</li>
  <li><b>Zero Telemetry & 100% Privacy:</b> Operates completely on-device.</li>
</ul>

<p>Click <b>Continue</b> to review the Terms of Service and proceed with the installation.</p>
</body>
</html>
HTML

# 2. Extract and format Terms of Service & License for the Wizard
if [ -f "TERMS_OF_SERVICE.md" ]; then
    cp "TERMS_OF_SERVICE.md" "$RESOURCES_DIR/license.txt"
elif [ -f "LICENSE" ]; then
    cp "LICENSE" "$RESOURCES_DIR/license.txt"
else
    echo "MacAuraLive Software License Agreement & Terms of Service." > "$RESOURCES_DIR/license.txt"
fi

# 3. Create Conclusion screen
cat << HTML > "$RESOURCES_DIR/conclusion.html"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 18px; line-height: 1.5; color: #1f2937; }
h1 { color: #15803d; }
.box { background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 12px; margin-top: 12px; }
</style>
</head>
<body>
<h1>Installation Complete! 🎉</h1>
<p>MacAuraLive has been successfully installed into your <b>/Applications</b> folder.</p>

<div class="box">
  <b>Quick Tip:</b> Launch MacAuraLive from Launchpad or Applications to access your dashboard, menu bar quick-controls, and mood presets.
</div>

<p>Thank you for using MacAuraLive!</p>
</body>
</html>
HTML

# 4. Build Component Package
pkgbuild \
    --root "$PKG_ROOT" \
    --identifier "com.macauralive.pkg" \
    --version "${VERSION}" \
    --install-location "/" \
    "$PKG_STAGING/MacAuraLive_Component.pkg"

# 5. Generate Distribution XML for Apple Installer Wizard with Next buttons & License Step
cat << XML > "$PKG_STAGING/Distribution.xml"
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>MacAuraLive v${VERSION} Setup</title>
    <welcome file="welcome.html" mime-type="text/html"/>
    <license file="license.txt" mime-type="text/plain"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
    <choices-outline>
        <line choice="default">
            <line choice="com.macauralive.pkg"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="com.macauralive.pkg" visible="false">
        <pkg-ref id="com.macauralive.pkg"/>
    </choice>
    <pkg-ref id="com.macauralive.pkg" version="${VERSION}" onConclusion="none">MacAuraLive_Component.pkg</pkg-ref>
</installer-gui-script>
XML

# 6. Build Final macOS Installer Wizard (.pkg)
productbuild \
    --distribution "$PKG_STAGING/Distribution.xml" \
    --resources "$RESOURCES_DIR" \
    --package-path "$PKG_STAGING" \
    "${OUTPUT_DIR}/${PKG_NAME}"

echo "✅ Official macOS Installer Wizard (.pkg) built at: ${OUTPUT_DIR}/${PKG_NAME}"

# 7. Package into a DMG with .pkg installer wizard inside
DMG_TEMP="${ROOT_DIR}/build/dmg_wizard_staging"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

cp "${OUTPUT_DIR}/${PKG_NAME}" "$DMG_TEMP/MacAuraLive Setup Wizard.pkg"
cp -R "${ROOT_DIR}/build/MacAuraLive.app" "$DMG_TEMP/MacAuraLive.app"
ln -s /Applications "$DMG_TEMP/Applications"
[ -f "README.md" ] && cp "README.md" "$DMG_TEMP/README.txt"

rm -f "${OUTPUT_DIR}/${DMG_WIZARD_NAME}"
hdiutil create \
    -volname "MacAuraLive ${VERSION} Setup" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${OUTPUT_DIR}/${DMG_WIZARD_NAME}"

rm -rf "$DMG_TEMP" "$PKG_ROOT" "$PKG_STAGING" "$RESOURCES_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Installer Wizard & DMG Generation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Wizard Package (.pkg): ${OUTPUT_DIR}/${PKG_NAME}"
echo "💿 Disk Image (.dmg):     ${OUTPUT_DIR}/${DMG_WIZARD_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
