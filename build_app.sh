#!/bin/bash
set -e

APP_NAME="Mac Productivity Suite"
DIST_DIR="dist"
BUILD_DIR="${DIST_DIR}/build_app"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "=================================================="
echo " Compiling Swift Menu Bar App (${APP_NAME})        "
echo " Target: Universal (arm64 & x86_64) macOS 14.0+   "
echo " Supports macOS 14 (Sonoma), 15 (Sequoia), 26+    "
echo "=================================================="

rm -rf "$BUILD_DIR" "$APP_BUNDLE"
mkdir -p "$BUILD_DIR" "$MACOS_DIR" "$RESOURCES_DIR"

SOURCES=(
    "src/MenuBarApp/ModeManager.swift"
    "src/MenuBarApp/MenuBarView.swift"
    "src/MenuBarApp/main.swift"
)

echo "[1/4] Compiling arm64 slice (Apple Silicon - macOS 14+)..."
swiftc \
    -parse-as-library \
    -target arm64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${BUILD_DIR}/binary_arm64" \
    -framework Cocoa \
    -framework SwiftUI \
    -O

echo "[2/4] Compiling x86_64 slice (Intel - macOS 14+)..."
swiftc \
    -parse-as-library \
    -target x86_64-apple-macos14.0 \
    "${SOURCES[@]}" \
    -o "${BUILD_DIR}/binary_x86_64" \
    -framework Cocoa \
    -framework SwiftUI \
    -O

echo "[3/4] Creating Universal Mach-O Binary with lipo..."
lipo -create -output "${MACOS_DIR}/MacProductivitySuiteBar" "${BUILD_DIR}/binary_arm64" "${BUILD_DIR}/binary_x86_64"

echo "[4/4] Copying Info.plist and Code-Signing..."
cp src/MenuBarApp/Info.plist "${CONTENTS_DIR}/Info.plist"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "=================================================="
echo " Build Complete: ${APP_BUNDLE}"
echo "=================================================="
