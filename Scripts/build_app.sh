#!/bin/bash

# Build script for MacAuraLive on macOS ARM64 / Apple Silicon
set -e

echo "🚀 Building MacAuraLive Wallpaper Engine for macOS..."

swift build -c release

BUILD_DIR="build/MacAuraLive.app/Contents"
rm -rf "build/MacAuraLive.app"
mkdir -p "$BUILD_DIR/MacOS"
mkdir -p "$BUILD_DIR/Resources"

# Copy compiled executable
cp ".build/release/MacAuraLive" "$BUILD_DIR/MacOS/MacAuraLive"
chmod +x "$BUILD_DIR/MacOS/MacAuraLive"

# Copy Resources
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
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>100</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Code sign ad-hoc
echo "🔒 Code signing MacAuraLive.app for macOS ARM64..."
codesign --force --deep --sign - "build/MacAuraLive.app"

echo "✅ App bundle created and signed successfully at: build/MacAuraLive.app"
