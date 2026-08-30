#!/bin/bash
set -e

PKG_NAME="MacProductivitySuite.pkg"
DIST_DIR="dist"
BUILD_DIR="$DIST_DIR/build_pkg"
ROOT_DIR="$BUILD_DIR/root"
SCRIPTS_DIR="$BUILD_DIR/scripts"

echo "=================================================="
echo " Building Mac Productivity Suite Installer (.pkg) "
echo " Includes Swift Menu Bar App & Embedded Binaries  "
echo "=================================================="

# Ensure Swift Menu Bar App is compiled
echo "[*] Compiling Swift Menu Bar App..."
./build_app.sh

echo "[1/4] Preparing build directories..."
rm -rf "$BUILD_DIR"
mkdir -p "$ROOT_DIR/Applications" "$SCRIPTS_DIR/binaries"

# 1. Payload: Place the Swift Menu Bar App into /Applications
echo "[2/4] Assembling Application and Config payloads..."
cp -R "dist/Mac Productivity Suite.app" "$ROOT_DIR/Applications/"

# 2. Scripts Payload: Put configuration directories and offline cached binaries
cp -R hammerspoon "$SCRIPTS_DIR/"
cp -R karabiner "$SCRIPTS_DIR/"

# Ensure cached binaries are embedded for 100% offline installation
if [ -f payload_cache/Hammerspoon.zip ]; then
    cp payload_cache/Hammerspoon.zip "$SCRIPTS_DIR/binaries/"
fi
if [ -f payload_cache/Karabiner.dmg ]; then
    cp payload_cache/Karabiner.dmg "$SCRIPTS_DIR/binaries/"
fi

echo "[3/4] Creating self-contained offline postinstall script..."
cat << 'POSTINSTALL' > "$SCRIPTS_DIR/postinstall"
#!/bin/bash
set -e

# Secure Checksums
HAMMERSPOON_SHA256="11bb1c90faf5427f37c7bd4fe7eab9774ae43e1d5cb020c5b3088dac32849efa"
HAMMERSPOON_FALLBACK_URL="https://github.com/Hammerspoon/hammerspoon/releases/download/1.1.1/Hammerspoon-1.1.1.zip"

# Determine target console user
if [ -n "$USER" ] && [ "$USER" != "root" ]; then
    TARGET_USER="$USER"
else
    TARGET_USER=$(stat -f "%Su" /dev/console 2>/dev/null || echo "$SUDO_USER")
    if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
        TARGET_USER=$(who | grep console | awk '{print $1}' | head -n 1)
    fi
fi

USER_HOME=$(dscl . -read /Users/$TARGET_USER NFSHomeDirectory 2>/dev/null | awk '{print $2}')
if [ -z "$USER_HOME" ]; then
    USER_HOME="/Users/$TARGET_USER"
fi

echo "[*] Target user: $TARGET_USER ($USER_HOME)"

HAMMERSPOON_DIR="$USER_HOME/.hammerspoon"
KARABINER_DIR="$USER_HOME/.config/karabiner/assets/complex_modifications"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 1. ALWAYS INSTALL HAMMERSPOON (Core engine for both Classic and Hyper modes)
if [ ! -d "/Applications/Hammerspoon.app" ]; then
    echo "[*] Installing Hammerspoon.app..."
    if [ -f "$REPO_DIR/binaries/Hammerspoon.zip" ]; then
        cp "$REPO_DIR/binaries/Hammerspoon.zip" /tmp/Hammerspoon.zip
    else
        echo "[*] Downloading Hammerspoon v1.1.1..."
        curl -L -s -o /tmp/Hammerspoon.zip "$HAMMERSPOON_FALLBACK_URL"
    fi
    
    # Checksum verification
    ACTUAL_SHA=$(shasum -a 256 /tmp/Hammerspoon.zip | cut -d ' ' -f 1)
    if [ "$ACTUAL_SHA" != "$HAMMERSPOON_SHA256" ]; then
        echo "Error: Hammerspoon checksum mismatch!"
        exit 1
    fi
    unzip -q /tmp/Hammerspoon.zip -d /Applications/
    rm -f /tmp/Hammerspoon.zip
fi

# 2. DO NOT AUTO-INSTALL KARABINER AT PKG TIME
# Karabiner is kept in the app's bundle/payload cache and only installed/launched
# when the user chooses "Hyper Key Mode" from the Menu Bar App.
# However, we make sure the Karabiner complex modifications rule directory exists and rule is installed ready for use.

# 3. INSTALL CONFIGURATIONS
echo "[*] Setting up user configuration directories..."
sudo -u "$TARGET_USER" mkdir -p "$HAMMERSPOON_DIR"
sudo -u "$TARGET_USER" mkdir -p "$KARABINER_DIR"

# Backup existing Hammerspoon config if it exists
if [ -f "$HAMMERSPOON_DIR/init.lua" ]; then
    echo "[*] Backing up existing Hammerspoon configuration..."
    sudo -u "$TARGET_USER" mv "$HAMMERSPOON_DIR" "${HAMMERSPOON_DIR}.backup_${TIMESTAMP}"
    sudo -u "$TARGET_USER" mkdir -p "$HAMMERSPOON_DIR"
fi

# Backup existing Karabiner rule if it exists
if [ -f "$KARABINER_DIR/hyper-key-mapping.json" ]; then
    echo "[*] Backing up existing Karabiner hyper key rule..."
    sudo -u "$TARGET_USER" mv "$KARABINER_DIR/hyper-key-mapping.json" "$KARABINER_DIR/hyper-key-mapping.backup_${TIMESTAMP}.json"
fi

echo "[*] Copying Hammerspoon configuration..."
cp -R "$REPO_DIR/hammerspoon/"* "$HAMMERSPOON_DIR/"

echo "[*] Copying Karabiner configuration..."
cp "$REPO_DIR/karabiner/hyper-key-mapping.json" "$KARABINER_DIR/"

# Default to classic mode unless specified
if [ ! -f "$HAMMERSPOON_DIR/config.json" ]; then
    echo '{"mode":"classic","autoReloadHammerspoon":true}' > "$HAMMERSPOON_DIR/config.json"
fi

# Fix ownership
chown -R "$TARGET_USER" "$HAMMERSPOON_DIR"
chown -R "$TARGET_USER" "$USER_HOME/.config/karabiner" 2>/dev/null || true

# 4. AUTO-LAUNCH HAMMERSPOON AND MAC PRODUCTIVITY SUITE MENU BAR APP FOR THE USER
echo "[*] Launching installed apps for user $TARGET_USER..."
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
    sudo -u "$TARGET_USER" open "/Applications/Mac Productivity Suite.app" 2>/dev/null || true
    sudo -u "$TARGET_USER" open "/Applications/Hammerspoon.app" 2>/dev/null || true
fi

echo "[*] Installation Complete."
exit 0
POSTINSTALL

chmod +x "$SCRIPTS_DIR/postinstall"

echo "[4/4] Generating .pkg installer bundle..."
pkgbuild \
    --root "$ROOT_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.unacau.macproductivitysuite" \
    --version "2.0.0" \
    "$DIST_DIR/$PKG_NAME"

echo "=================================================="
echo " PKG Build Succeeded: $DIST_DIR/$PKG_NAME"
echo "=================================================="
