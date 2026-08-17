#!/bin/bash

# Build script for MacAuraLive Universal 2 (Apple Silicon & Intel)
set -e

# 1. Run Pre-Build Verification Test Suite
bash Scripts/verify_environment.sh

echo "🚀 Building MacAuraLive Universal 2 (Apple Silicon & Intel x86_64)..."

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

# Generate Info.plist
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
    <string>1.8.0</string>
    <key>CFBundleVersion</key>
    <string>120</string>
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

echo "✅ Universal 2 App bundle created and signed successfully at: build/MacAuraLive.app"
