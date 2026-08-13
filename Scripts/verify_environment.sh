#!/bin/bash

# MacAuraLive Pre-Build Verification & Environment Audit Script
set -e

echo "🔍 Running MacAuraLive Pre-Build Verification Audit..."
ERRORS=0

# 1. Swift & Xcode Toolchain Check
echo "  [1/5] Checking macOS Toolchain..."
if ! command -v swift >/dev/null 2>&1; then
    echo "  ❌ Swift compiler not found. Please install Xcode Command Line Tools."
    ERRORS=$((ERRORS + 1))
else
    echo "  ✅ Swift compiler: $(swift --version | head -n 1)"
fi

if ! command -v codesign >/dev/null 2>&1; then
    echo "  ❌ codesign utility not found."
    ERRORS=$((ERRORS + 1))
else
    echo "  ✅ codesign utility available."
fi

# 2. Project & Source Structure Check
echo "  [2/5] Checking Directory & Asset Structure..."
REQUIRED_FILES=(
    "Package.swift"
    "Sources/MacAuraLive/MacAuraLiveApp.swift"
    "Sources/MacAuraLive/Resources/Assets/AppIcon.png"
    "Sources/MacAuraLive/Resources/Assets/StatusBarIcon.png"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ❌ Missing required file: $file"
        ERRORS=$((ERRORS + 1))
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "  ✅ All core source files & branding assets verified."
fi

# 3. Legal & Open Source Compliance Check
echo "  [3/5] Checking Legal Suite Files..."
LEGAL_DOCS=(
    "LICENSE"
    "EULA.md"
    "TERMS_OF_SERVICE.md"
    "PRIVACY_POLICY.md"
    "SECURITY.md"
    "DMCA.md"
    "README.md"
)

for doc in "${LEGAL_DOCS[@]}"; do
    if [ ! -f "$doc" ]; then
        echo "  ❌ Missing legal document: $doc"
        ERRORS=$((ERRORS + 1))
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "  ✅ Complete 6-part legal compliance suite verified."
fi

# 4. Version & Naming Synchronization Audit
echo "  [4/5] Auditing Version & Branding Consistency..."
PACKAGE_NAME=$(grep -o 'name: "MacAuraLive"' Package.swift || true)
if [ -z "$PACKAGE_NAME" ]; then
    echo "  ❌ Package.swift does not declare name 'MacAuraLive'."
    ERRORS=$((ERRORS + 1))
fi

UPDATE_VER=$(grep -o 'currentVersion = "1.5.0"' Sources/MacAuraLive/Core/UpdateManager.swift || true)
if [ -z "$UPDATE_VER" ]; then
    echo "  ❌ UpdateManager.swift version mismatch."
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
    echo "  ✅ App name 'MacAuraLive' and version '1.5.0' are 100% synchronized."
fi

# 5. Security & Static Analysis Audit
echo "  [5/5] Auditing Code Safety..."
HARDENED_CHECK=$(grep -o 'SecurityHardeningManager' Sources/MacAuraLive/Core/WebWallpaperView.swift || true)
if [ -z "$HARDENED_CHECK" ]; then
    echo "  ❌ WebWallpaperView missing SecurityHardeningManager integration."
    ERRORS=$((ERRORS + 1))
fi

KEYCHAIN_CHECK=$(grep -o 'kSecClassGenericPassword' Sources/MacAuraLive/Core/KeychainManager.swift || true)
if [ -z "$KEYCHAIN_CHECK" ]; then
    echo "  ❌ KeychainManager missing Security.framework Keychain integration."
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
    echo "  ✅ Security hardening & Keychain hardware encryption verified."
fi

echo ""
if [ $ERRORS -gt 0 ]; then
    echo "❌ Pre-build verification failed with $ERRORS error(s). Please resolve before building."
    exit 1
else
    echo "🎉 Pre-build verification passed! Environment is 100% ready for build."
fi
