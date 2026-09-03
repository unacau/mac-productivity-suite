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

# Ensure Swift Standalone App is compiled
if [ ! -d "$DIST_DIR/Mac Productivity Suite.app" ]; then
    echo "[*] Compiling Swift App..."
    ./build_native_app.sh
fi

echo "[1/3] Preparing build directories..."
rm -rf "$BUILD_DIR" "$DIST_DIR/$PKG_NAME"
mkdir -p "$ROOT_DIR/Applications" "$SCRIPTS_DIR"

echo "[2/3] Assembling Application payload..."
cp -R "$DIST_DIR/Mac Productivity Suite.app" "$ROOT_DIR/Applications/"

cat << 'POSTINSTALL' > "$SCRIPTS_DIR/postinstall"
#!/bin/bash
set -e

TARGET_USER=$(stat -f "%Su" /dev/console 2>/dev/null || echo "$SUDO_USER")
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER=$(who | grep console | awk '{print $1}' | head -n 1)
fi

# Terminate any existing running instance so the freshly installed binary starts
pkill -f "Mac Productivity Suite" 2>/dev/null || true
sleep 1

# Auto-launch app if running in user session
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
    sudo -u "$TARGET_USER" open "/Applications/Mac Productivity Suite.app" 2>/dev/null || true
fi

exit 0
POSTINSTALL

chmod +x "$SCRIPTS_DIR/postinstall"

echo "[3/3] Generating .pkg installer bundle..."
pkgbuild \
    --root "$ROOT_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.unacau.macproductivitysuite.full" \
    --version "$VERSION" \
    "$DIST_DIR/$PKG_NAME"

echo "=================================================="
echo " PKG Build Succeeded: $DIST_DIR/$PKG_NAME"
echo " Size: $(du -sh "$DIST_DIR/$PKG_NAME" | awk '{print $1}')"
echo "=================================================="
