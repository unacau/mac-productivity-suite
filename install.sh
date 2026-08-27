#!/bin/bash
set -e

echo "=================================================="
echo " Installing Mac Productivity Suite                "
echo "=================================================="

# Define directories
HAMMERSPOON_DIR="$HOME/.hammerspoon"
KARABINER_DIR="$HOME/.config/karabiner/assets/complex_modifications"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Creating target directories..."
mkdir -p "$HAMMERSPOON_DIR"
mkdir -p "$KARABINER_DIR"

echo "[*] Installing Hammerspoon configuration..."
# Copy Hammerspoon scripts (we use cp so it's a hardcoded snapshot, but symlinking is an option)
cp -R "$REPO_DIR/hammerspoon/"* "$HAMMERSPOON_DIR/"

echo "[*] Installing Karabiner-Elements configuration..."
cp "$REPO_DIR/karabiner/hyper-key-mapping.json" "$KARABINER_DIR/"

echo "[*] Hardcoded default settings applied successfully."
echo "=================================================="
echo " Installation Complete!                           "
echo "=================================================="
echo "Next Steps:"
echo " 1. Open Hammerspoon and click 'Reload Config'."
echo " 2. Open Karabiner-Elements -> Complex Modifications -> Add rule, and enable the 'Caps Lock to Hyper Key' rule."
