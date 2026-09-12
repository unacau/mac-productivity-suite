#!/bin/bash
set -euo pipefail

echo "=================================================="
echo " Installing Chrome Quick Access (v1.0.0)          "
echo "=================================================="

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Chrome Quick Access"
APP_BUNDLE="${REPO_DIR}/dist/${APP_NAME}.app"
TARGET_APP="/Applications/${APP_NAME}.app"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "[*] Building application bundle first..."
    "${REPO_DIR}/build_native_app.sh"
fi

echo "[*] Installing to /Applications..."
rm -rf "${TARGET_APP}"
cp -R "${APP_BUNDLE}" "/Applications/"

echo "=================================================="
echo " ✅ Installation Complete!                        "
echo " App installed to: ${TARGET_APP}"
echo "=================================================="
echo "Next Steps:"
echo " 1. Launch '${APP_NAME}.app' from Applications."
echo " 2. Ensure Accessibility permission is enabled in System Settings."
echo " 3. Use Caps-Lock + C to switch Chrome profiles."
echo " 4. Use Caps-Lock + A to switch Antigravity apps."
echo " 5. Select text to automatically copy to clipboard."
