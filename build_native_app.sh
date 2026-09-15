#!/bin/bash
set -euo pipefail

APP_NAME="Khomyak"
DIST_DIR="dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
BUILD_DIR="${DIST_DIR}/build_native"
DMG_PATH="${DIST_DIR}/Khomyak.dmg"

echo "=================================================="
echo " Building Native ${APP_NAME} (.app)               "
echo " Target: Universal (arm64 & x86_64) macOS 14.0+   "
echo "=================================================="

rm -rf "${APP_BUNDLE}" "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}" "${CONTENTS_DIR}" "${RESOURCES_DIR}" "${BUILD_DIR}/temp"

SOURCES=(
    "src/ChromeQuickAccess/Engine/KeyCodes.swift"
    "src/ChromeQuickAccess/Engine/CapsLockEngine.swift"
    "src/ChromeQuickAccess/Engine/ChromeProfileEngine.swift"
    "src/ChromeQuickAccess/Engine/AntigravityEngine.swift"
    "src/ChromeQuickAccess/Engine/AppGroupEngine.swift"
    "src/ChromeQuickAccess/Engine/CopyOnSelectEngine.swift"
    "src/ChromeQuickAccess/Views/MinimalHUDWindow.swift"
    "src/ChromeQuickAccess/AppDelegate.swift"
    "src/ChromeQuickAccess/main.swift"
)

FRAMEWORKS=(
    "-framework" "Cocoa"
    "-framework" "AppKit"
    "-framework" "SwiftUI"
    "-framework" "ApplicationServices"
    "-framework" "CoreGraphics"
)

echo "[1/5] Compiling arm64 slice (Apple Silicon)..."
swiftc \
    -parse-as-library \
    -target arm64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${BUILD_DIR}/temp/binary_arm64" \
    "${FRAMEWORKS[@]}" \
    -O

echo "[2/5] Compiling x86_64 slice (Intel)..."
swiftc \
    -parse-as-library \
    -target x86_64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${BUILD_DIR}/temp/binary_x86_64" \
    "${FRAMEWORKS[@]}" \
    -O

echo "[3/5] Creating Universal Mach-O Binary with lipo..."
lipo -create -output "${MACOS_DIR}/Khomyak" \
    "${BUILD_DIR}/temp/binary_arm64" \
    "${BUILD_DIR}/temp/binary_x86_64"

echo "[4/5] Packaging Info.plist, AppIcon & Code-Signing..."
cp "src/ChromeQuickAccess/Info.plist" "${CONTENTS_DIR}/Info.plist"
if [ -f "src/ChromeQuickAccess/Resources/AppIcon.icns" ]; then
    cp "src/ChromeQuickAccess/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

codesign --force --sign - --identifier "com.almosteleven.khomyak" -r="designated => identifier \"com.almosteleven.khomyak\"" "${APP_BUNDLE}"
codesign -vvv "${APP_BUNDLE}"

echo "[5/5] Generating DMG Installer..."
rm -f "${DMG_PATH}"
DMG_STAGE="${BUILD_DIR}/dmg_stage"
rm -rf "${DMG_STAGE}"
mkdir -p "${DMG_STAGE}"
cp -R "${APP_BUNDLE}" "${DMG_STAGE}/"
ln -s /Applications "${DMG_STAGE}/Applications"
hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_STAGE}" -ov -format UDZO "${DMG_PATH}"

rm -rf "${BUILD_DIR}"

echo "=================================================="
echo " ✅ Standalone Build Succeeded!"
echo " App: ${APP_BUNDLE}"
echo " DMG: ${DMG_PATH}"
echo " Archs: $(lipo -archs "${MACOS_DIR}/Khomyak")"
echo "=================================================="
