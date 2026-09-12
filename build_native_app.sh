#!/bin/bash
set -euo pipefail

APP_NAME="Chrome Quick Access"
DIST_DIR="dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
BUILD_DIR="${DIST_DIR}/build_native"
DMG_PATH="${DIST_DIR}/ChromeQuickAccess.dmg"

echo "=================================================="
echo " Building Native ${APP_NAME} (.app)               "
echo " Target: Universal (arm64 & x86_64) macOS 14.0+   "
echo "=================================================="

rm -rf "${APP_BUNDLE}" "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}" "${CONTENTS_DIR}" "${BUILD_DIR}/temp"

SOURCES=(
    "src/ChromeQuickAccess/Engine/KeyCodes.swift"
    "src/ChromeQuickAccess/Engine/CapsLockEngine.swift"
    "src/ChromeQuickAccess/Engine/ChromeProfileEngine.swift"
    "src/ChromeQuickAccess/Engine/AntigravityEngine.swift"
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
lipo -create -output "${MACOS_DIR}/ChromeQuickAccess" \
    "${BUILD_DIR}/temp/binary_arm64" \
    "${BUILD_DIR}/temp/binary_x86_64"

echo "[4/5] Packaging Info.plist & Code-Signing..."
if [ -f "src/ChromeQuickAccess/Info.plist" ]; then
    cp "src/ChromeQuickAccess/Info.plist" "${CONTENTS_DIR}/Info.plist"
else
    cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ChromeQuickAccess</string>
    <key>CFBundleIdentifier</key>
    <string>com.unacau.chromequickaccess</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Chrome Quick Access</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(cat VERSION.txt 2>/dev/null || echo "1.0.0")</string>
    <key>CFBundleVersion</key>
    <string>$(cat BUILD.txt 2>/dev/null || echo "1")</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
fi

codesign --force --sign - --identifier "com.unacau.chromequickaccess" -r="designated => identifier \"com.unacau.chromequickaccess\"" "${APP_BUNDLE}"
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
echo " Archs: $(lipo -archs "${MACOS_DIR}/ChromeQuickAccess")"
echo "=================================================="
