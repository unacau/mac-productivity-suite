#!/bin/bash
set -euo pipefail

PKG_NAME="MacProductivitySuite-Full.pkg"
DIST_DIR="dist"
BUILD_DIR="$DIST_DIR/build_full_pkg"
ROOT_DIR="$BUILD_DIR/root"
SCRIPTS_DIR="$BUILD_DIR/scripts"
VERSION=$(cat VERSION.txt)

echo "=================================================="
echo " Building Mac Productivity Suite Installer PKG    "
echo " (Pure Native Swift Engine — Driverless)          "
echo "=================================================="

echo "[1/4] Ensuring latest Swift app binary..."
./build_native_app.sh

echo "[2/4] Preparing build directories & payload..."
rm -rf "$BUILD_DIR" "$DIST_DIR/$PKG_NAME"
mkdir -p "$ROOT_DIR/Applications" "$SCRIPTS_DIR"
cp -R "$DIST_DIR/Mac Productivity Suite.app" "$ROOT_DIR/Applications/"

echo "[3/4] Configuring non-relocatable component plist..."
pkgbuild --analyze --root "$ROOT_DIR" "$BUILD_DIR/components.plist"
plutil -replace "0.BundleIsRelocatable" -bool false "$BUILD_DIR/components.plist"

cat << 'PREINSTALL' > "$SCRIPTS_DIR/preinstall"
#!/bin/bash
set -e
# Terminate existing instance and clean old app to guarantee a clean overwrite
pkill -f "Mac Productivity Suite" 2>/dev/null || true
rm -rf "/Applications/Mac Productivity Suite.app" 2>/dev/null || true
exit 0
PREINSTALL
chmod +x "$SCRIPTS_DIR/preinstall"

cat << 'POSTINSTALL' > "$SCRIPTS_DIR/postinstall"
#!/bin/bash
set -e

TARGET_USER=$(stat -f "%Su" /dev/console 2>/dev/null || echo "$SUDO_USER")
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER=$(who | grep console | awk '{print $1}' | head -n 1)
fi

# Auto-launch app if running in user session
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
    sudo -u "$TARGET_USER" open "/Applications/Mac Productivity Suite.app" 2>/dev/null || true
fi

exit 0
POSTINSTALL
chmod +x "$SCRIPTS_DIR/postinstall"

echo "[4/4] Generating .pkg installer bundle..."
pkgbuild \
    --root "$ROOT_DIR" \
    --component-plist "$BUILD_DIR/components.plist" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.unacau.macproductivitysuite.full" \
    --version "$VERSION" \
    "$DIST_DIR/$PKG_NAME"

echo "=================================================="
echo " PKG Build Succeeded: $DIST_DIR/$PKG_NAME"
echo " Size: $(du -sh "$DIST_DIR/$PKG_NAME" | awk '{print $1}')"
echo "=================================================="
