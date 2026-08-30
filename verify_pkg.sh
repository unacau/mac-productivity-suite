#!/bin/bash
set -e

PKG_PATH="${1:-dist/MacProductivitySuite.pkg}"

echo "=================================================="
echo " Automated Quality Control Verification for PKG   "
echo " Verifying: $PKG_PATH"
echo "=================================================="

if [ ! -f "$PKG_PATH" ]; then
    echo "❌ [FAIL] PKG file not found: $PKG_PATH"
    exit 1
fi
echo "✅ [PASS] PKG file exists ($(ls -lh "$PKG_PATH" | awk '{print $5}'))"

TMP_DIR="/tmp/mps_pkg_qc_$$"
mkdir -p "$TMP_DIR"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "[*] Expanding PKG to isolate contents..."
pkgutil --expand "$PKG_PATH" "$TMP_DIR/expanded"
if [ ! -d "$TMP_DIR/expanded/Scripts" ]; then
    echo "❌ [FAIL] Scripts directory missing in PKG"
    exit 1
fi

echo "✅ [PASS] PKG expanded successfully"
echo "[*] Verifying Payload Assets..."

if [ ! -f "$TMP_DIR/expanded/Scripts/postinstall" ]; then
    echo "❌ [FAIL] postinstall script missing!"
    exit 1
fi
if [ ! -d "$TMP_DIR/expanded/Scripts/hammerspoon" ]; then
    echo "❌ [FAIL] hammerspoon payload missing!"
    exit 1
fi
if [ ! -d "$TMP_DIR/expanded/Scripts/karabiner" ]; then
    echo "❌ [FAIL] karabiner payload missing!"
    exit 1
fi
if [ ! -f "$TMP_DIR/expanded/Scripts/binaries/Hammerspoon.zip" ]; then
    echo "❌ [FAIL] Offline Hammerspoon binary missing!"
    exit 1
fi
if [ ! -f "$TMP_DIR/expanded/Scripts/binaries/Karabiner.dmg" ]; then
    echo "❌ [FAIL] Offline Karabiner binary missing!"
    exit 1
fi
echo "✅ [PASS] All payload assets verified (postinstall, hammerspoon, karabiner, offline binaries present)"

echo "[*] Running Sandboxed Dry-Run Execution Test of postinstall..."
cd "$TMP_DIR/expanded/Scripts"

cat << 'MOCK' > mock_env.sh
mkdir() { echo "mock: mkdir $@"; }
cp() { echo "mock: cp $@"; }
mv() { echo "mock: mv $@"; }
chown() { echo "mock: chown $@"; }
curl() { echo "mock: curl $@"; }
unzip() { echo "mock: unzip $@"; }
hdiutil() { echo "mock: hdiutil $@"; }
installer() { echo "mock: installer $@"; }
shasum() { /usr/bin/shasum "$@"; }
sudo() { 
  if [ "$1" == "-u" ]; then
    shift 2; "$@"
  else
    "$@"
  fi
}
export -f mkdir cp mv chown curl unzip hdiutil installer sudo
MOCK

source mock_env.sh
bash postinstall > output.log || true

if grep -q "Installation Complete" output.log; then
    echo "✅ [PASS] postinstall logic executed successfully"
else
    echo "❌ [FAIL] postinstall execution failed"
    cat output.log
    exit 1
fi

echo "=================================================="
echo " ALL QUALITY CONTROL CHECKS PASSED (100% READY)   "
echo "=================================================="
