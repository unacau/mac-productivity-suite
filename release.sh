#!/bin/bash
set -euo pipefail

VERSION=$(cat VERSION.txt)
BUILD=$(cat BUILD.txt)
APP_NAME="Chrome Quick Access"
DMG_FILE="dist/ChromeQuickAccess.dmg"
REPO="unacau/mac-productivity-suite"

echo "=================================================="
echo " Preparing Release v$VERSION (Build $BUILD)       "
echo " App: $APP_NAME                                   "
echo "=================================================="

# 1. Build Native Application & DMG
echo "[1/3] Building Universal Application & DMG..."
./build_native_app.sh

# 2. Verify Health
echo "[2/3] Running Health & Quality Check..."
./scripts/health_check.sh

# 3. Publish / Tag Release
echo "[3/3] Creating Release Assets..."
if command -v gh >/dev/null 2>&1; then
    echo "Creating GitHub Release v$VERSION..."
    gh release create "v$VERSION" "$DMG_FILE" \
        --title "v$VERSION - Chrome Quick Access & Productivity Suite" \
        --notes "Release v$VERSION (Build $BUILD) of Chrome Quick Access featuring driverless Caps-Lock remapping, multi-profile Chrome cycling, Antigravity switcher, and universal Copy-on-Select." \
        --repo "$REPO" || echo "ℹ️ gh release command skipped or already exists."
else
    echo "ℹ️ GitHub CLI (gh) not installed. DMG is available at $DMG_FILE."
fi

echo "=================================================="
echo " ✅ Release v$VERSION Built Successfully!"
echo " Artifact: $DMG_FILE"
echo "=================================================="
