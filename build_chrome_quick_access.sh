#!/bin/bash
set -euo pipefail

APP_NAME="Chrome Quick Access"
DIST_DIR="dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
BUILD_DIR="${DIST_DIR}/build_chrome_quick_access"

echo "=================================================="
echo " Building Native Chrome Quick Access (.app)       "
echo " Target: macOS 14.0+ (Sonoma, Sequoia, Tahoe)     "
echo "=================================================="

rm -rf "${APP_BUNDLE}" "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}" "${CONTENTS_DIR}" "${BUILD_DIR}/temp"

SOURCES=(
    "src/ChromeQuickAccess/Engine/KeyCodes.swift"
    "src/ChromeQuickAccess/Engine/CapsLockEngine.swift"
    "src/ChromeQuickAccess/Engine/ChromeProfileEngine.swift"
    "src/ChromeQuickAccess/Engine/AntigravityEngine.swift"
    "src/ChromeQuickAccess/Views/MinimalHUDWindow.swift"
    "src/ChromeQuickAccess/AppDelegate.swift"
    "src/ChromeQuickAccess/main.swift"
)

echo "[1/4] Compiling binary with swiftc..."
swiftc \
    -parse-as-library \
    -target arm64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${MACOS_DIR}/ChromeQuickAccess" \
    -framework Cocoa \
    -framework AppKit \
    -framework SwiftUI \
    -framework ApplicationServices \
    -framework CoreGraphics \
    -O

echo "[2/4] Generating Info.plist (LSUIElement = 1 for background agent)..."
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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
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

echo "[3/4] Codesigning application bundle..."
codesign --force --sign - --identifier "com.unacau.chromequickaccess" -r="designated => identifier \"com.unacau.chromequickaccess\"" "${APP_BUNDLE}"

echo "[4/4] Verifying code signature..."
codesign -vvv "${APP_BUNDLE}"

rm -rf "${BUILD_DIR}"

echo "=================================================="
echo " ✅ Build Successful!"
echo " App Bundle: ${APP_BUNDLE}"
echo " To run now: open \"${APP_BUNDLE}\""
echo "=================================================="
