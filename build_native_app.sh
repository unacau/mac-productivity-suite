#!/bin/bash
set -euo pipefail

APP_NAME="Mac Productivity Suite"
DIST_DIR="dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
PKG_NAME="MacProductivitySuite-Native.pkg"
PKG_PATH="${DIST_DIR}/${PKG_NAME}"
BUILD_DIR="${DIST_DIR}/build_native_pkg"
ROOT_DIR="${BUILD_DIR}/root"
SCRIPTS_DIR="${BUILD_DIR}/scripts"

echo "=================================================="
echo " Building 100% Pure Standalone Edition            "
echo " Target: Universal (arm64 & x86_64) macOS 14.0+   "
echo " Compatible with macOS 14 (Sonoma), 15 (Sequoia)..."
echo "=================================================="

rm -rf "${APP_BUNDLE}" "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}" "${CONTENTS_DIR}" "${ROOT_DIR}/Applications" "${SCRIPTS_DIR}" "${BUILD_DIR}/temp"

SOURCES=(
    "src/NativeStandaloneApp/Engine/OSProviders.swift"
    "src/NativeStandaloneApp/Engine/HotkeyManager.swift"
    "src/NativeStandaloneApp/Engine/AppConfig.swift"
    "src/NativeStandaloneApp/Engine/AppDiscoveryService.swift"
    "src/NativeStandaloneApp/Engine/ChromeProfileHelper.swift"
    "src/NativeStandaloneApp/Engine/AppSwitcherEngine.swift"
    "src/NativeStandaloneApp/Engine/AppLogger.swift"
    "src/NativeStandaloneApp/Views/HUDOverlayWindow.swift"
    "src/NativeStandaloneApp/Views/AppPickerSheet.swift"
    "src/NativeStandaloneApp/Views/SettingsWindow.swift"
    "src/NativeStandaloneApp/Views/MenuBarPopupView.swift"
    "src/NativeStandaloneApp/main.swift"
)

echo "[1/5] Compiling arm64 slice (Apple Silicon - macOS 14+)..."
swiftc \
    -parse-as-library \
    -target arm64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${BUILD_DIR}/temp/binary_arm64" \
    -F Frameworks -framework Sparkle \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Carbon \
    -O

echo "[2/5] Compiling x86_64 slice (Intel - macOS 14+)..."
swiftc \
    -parse-as-library \
    -target x86_64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${BUILD_DIR}/temp/binary_x86_64" \
    -F Frameworks -framework Sparkle \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Carbon \
    -O

echo "[3/5] Creating Universal Mach-O Binary with lipo..."
lipo -create -output "${MACOS_DIR}/MacProductivitySuite" "${BUILD_DIR}/temp/binary_arm64" "${BUILD_DIR}/temp/binary_x86_64"

echo "[4/5] Embedding Frameworks and Code-Signing..."
mkdir -p "${CONTENTS_DIR}/Frameworks"
cp -R "Frameworks/Sparkle.framework" "${CONTENTS_DIR}/Frameworks/"
cp src/NativeStandaloneApp/Info.plist "${CONTENTS_DIR}/Info.plist"

install_name_tool -add_rpath @executable_path/../Frameworks "${MACOS_DIR}/MacProductivitySuite" || true

codesign --force --deep --sign - "${APP_BUNDLE}"

echo "[5/5] Generating DMG Installer..."
DMG_PATH="${DIST_DIR}/MacProductivitySuite.dmg"
rm -f "${DMG_PATH}"

if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
      --volname "Mac Productivity Suite" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 128 \
      --app-drop-link 400 150 \
      "${DMG_PATH}" \
      "${APP_BUNDLE}"
else
    echo "create-dmg not found, creating standard DMG..."
    hdiutil create -volname "Mac Productivity Suite" -srcfolder "${APP_BUNDLE}" -ov -format UDZO "${DMG_PATH}"
fi

echo "=================================================="
echo " Standalone Build Succeeded!"
echo " App: ${APP_BUNDLE}"
echo " DMG: ${DMG_PATH}"
echo "=================================================="
