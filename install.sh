#!/bin/bash
set -euo pipefail

echo "=================================================="
echo " Installing Mac Productivity Suite (v2.0 Universal)"
echo "=================================================="

# Define directories
HAMMERSPOON_DIR="$HOME/.hammerspoon"
CONFIG_DIR="$HOME/.config/mac-productivity-suite"
KARABINER_DIR="$HOME/.config/karabiner/assets/complex_modifications"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Creating target directories..."
mkdir -p "$HAMMERSPOON_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$KARABINER_DIR"

echo "[*] Installing Hammerspoon scripts..."
cp -R "$REPO_DIR/hammerspoon/"* "$HAMMERSPOON_DIR/"

echo "[*] Installing Karabiner-Elements configuration..."
cp "$REPO_DIR/karabiner/hyper-key-mapping.json" "$KARABINER_DIR/"

echo "[*] Universal dynamic configuration initialized."
echo "=================================================="
echo " Installation Complete!                           "
echo "=================================================="
echo "Next Steps:"
echo " 1. Launch 'Mac Productivity Suite Native.app' or 'Mac Productivity Suite.app' from Applications."
echo " 2. Click the ⌘ icon in your Menu Bar to customize shortcuts or auto-detect your installed apps."
echo " 3. If using Hammerspoon mode, open Hammerspoon and click 'Reload Config'."
