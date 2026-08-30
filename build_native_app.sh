#!/bin/bash
set -e

APP_NAME="Mac Productivity Suite Native"
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
echo " Building 100% Pure Native Standalone Edition     "
echo " Target: Universal (arm64 & x86_64) macOS 14.0+   "
echo " Compatible with macOS 14 (Sonoma), 15 (Sequoia)..."
echo "=================================================="

rm -rf "${APP_BUNDLE}" "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}" "${CONTENTS_DIR}" "${ROOT_DIR}/Applications" "${SCRIPTS_DIR}" "${BUILD_DIR}/temp"

SOURCES=(
    "src/NativeStandaloneApp/Engine/HotkeyManager.swift"
    "src/NativeStandaloneApp/Engine/AppSwitcherEngine.swift"
    "src/NativeStandaloneApp/Engine/CopyOnSelectEngine.swift"
    "src/NativeStandaloneApp/Engine/ChromeProfileHelper.swift"
    "src/NativeStandaloneApp/Engine/ProductivityActionsHelper.swift"
    "src/NativeStandaloneApp/Views/HUDOverlayWindow.swift"
    "src/NativeStandaloneApp/Views/MenuBarPopupView.swift"
    "src/NativeStandaloneApp/main.swift"
)

echo "[1/5] Compiling arm64 slice (Apple Silicon - macOS 14+)..."
swiftc \
    -parse-as-library \
    -target arm64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${BUILD_DIR}/temp/binary_arm64" \
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
    -framework Cocoa \
    -framework SwiftUI \
    -framework Carbon \
    -O

echo "[3/5] Creating Universal Mach-O Binary with lipo..."
lipo -create -output "${MACOS_DIR}/MacProductivitySuiteNative" "${BUILD_DIR}/temp/binary_arm64" "${BUILD_DIR}/temp/binary_x86_64"

echo "[4/5] Injecting Info.plist and Code-Signing..."
cp src/NativeStandaloneApp/Info.plist "${CONTENTS_DIR}/Info.plist"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "[5/5] Generating Standalone .pkg Installer..."
cp -R "${APP_BUNDLE}" "${ROOT_DIR}/Applications/Mac Productivity Suite.app"

cat << 'POSTINSTALL' > "${SCRIPTS_DIR}/postinstall"
#!/bin/bash
set -e

# Target user
TARGET_USER=$(stat -f "%Su" /dev/console 2>/dev/null || echo "$SUDO_USER")
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER=$(who | grep console | awk '{print $1}' | head -n 1)
fi

echo "[*] Installed standalone app to /Applications/Mac Productivity Suite.app"

# Auto-launch app for user
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
    sudo -u "$TARGET_USER" open "/Applications/Mac Productivity Suite.app" 2>/dev/null || true
fi

exit 0
POSTINSTALL

chmod +x "${SCRIPTS_DIR}/postinstall"

pkgbuild \
    --root "${ROOT_DIR}" \
    --scripts "${SCRIPTS_DIR}" \
    --identifier "com.igorekishev.macproductivitysuite.native" \
    --version "1.0.0" \
    "${PKG_PATH}"

echo "=================================================="
echo " Native Standalone Build Succeeded!"
echo " App: ${APP_BUNDLE}"
echo " PKG: ${PKG_PATH}"
echo "=================================================="
