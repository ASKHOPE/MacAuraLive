#!/bin/bash

set -e

echo "🚀 Building MacAura Live Wallpaper for macOS..."

# Compile in release mode
swift build -c release

BUILD_DIR="build/MacAura.app/Contents"

mkdir -p "$BUILD_DIR/MacOS"
mkdir -p "$BUILD_DIR/Resources"

# Copy binary
cp ".build/release/MacAura" "$BUILD_DIR/MacOS/MacAura"
chmod +x "$BUILD_DIR/MacOS/MacAura"

# Copy resources
if [ -d "Sources/MacAura/Resources" ]; then
    cp -R "Sources/MacAura/Resources/" "$BUILD_DIR/Resources/"
fi

# Copy app icon directly into Resources/ root (macOS requires AppIcon.icns at this level)
if [ -f "Sources/MacAura/Resources/Assets/AppIcon.icns" ]; then
    cp "Sources/MacAura/Resources/Assets/AppIcon.icns" "$BUILD_DIR/Resources/AppIcon.icns"
    echo "📦 AppIcon.icns copied to bundle Resources/"
fi

# Copy status bar icon directly into Resources/ root
if [ -f "Sources/MacAura/Resources/Assets/StatusBarIcon.png" ]; then
    cp "Sources/MacAura/Resources/Assets/StatusBarIcon.png" "$BUILD_DIR/Resources/StatusBarIcon.png"
    echo "📦 StatusBarIcon.png copied to bundle Resources/"
fi

# Create Info.plist with explicit ScreenCapture & SystemAudio TCC keys
cat <<EOF > "$BUILD_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacAura</string>
    <key>CFBundleIdentifier</key>
    <string>com.macaura.livewallpaper</string>
    <key>CFBundleName</key>
    <string>MacAura</string>
    <key>CFBundleDisplayName</key>
    <string>MacAura Live Wallpaper</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Ad-hoc code sign bundle for Apple Silicon (ARM64)
echo "🔒 Code signing MacAura.app for macOS ARM64..."
codesign --force --deep --sign - "build/MacAura.app"

echo "✅ App bundle created and signed successfully at: build/MacAura.app"
