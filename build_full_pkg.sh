#!/bin/bash
set -e

PKG_NAME="MacProductivitySuite-Full.pkg"
DIST_DIR="dist"
BUILD_DIR="$DIST_DIR/build_full_pkg"
ROOT_DIR="$BUILD_DIR/root"
SCRIPTS_DIR="$BUILD_DIR/scripts"

echo "=================================================="
echo " Building Mac Productivity Suite Full Edition     "
echo " (With Hammerspoon & Karabiner-Elements Bundled)  "
echo "=================================================="

# Ensure Swift Menu Bar App is compiled
if [ ! -f "$DIST_DIR/Mac Productivity Suite.app/Contents/MacOS/MacProductivitySuiteBar" ]; then
    echo "[*] Compiling Swift Menu Bar App..."
    ./build_app.sh
fi

echo "[1/4] Preparing build directories..."
rm -rf "$BUILD_DIR" "$DIST_DIR/$PKG_NAME"
mkdir -p "$ROOT_DIR/Applications" "$SCRIPTS_DIR"

echo "[2/4] Assembling Application and Config payloads..."
cp -R "$DIST_DIR/Mac Productivity Suite.app" "$ROOT_DIR/Applications/"

# Copy embedded assets into the scripts directory
cp payload_cache/Hammerspoon.zip "$SCRIPTS_DIR/"
cp payload_cache/Karabiner.dmg "$SCRIPTS_DIR/"
cp -R hammerspoon "$SCRIPTS_DIR/"
cp -R karabiner "$SCRIPTS_DIR/"

echo "[3/4] Creating self-contained offline postinstall script..."
cat << 'POSTINSTALL' > "$SCRIPTS_DIR/postinstall"
#!/bin/bash
set -e

# Target user
TARGET_USER=$(stat -f "%Su" /dev/console 2>/dev/null || echo "$SUDO_USER")
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER=$(who | grep console | awk '{print $1}' | head -n 1)
fi

USER_HOME=$(dscl . -read /Users/$TARGET_USER NFSHomeDirectory | awk '{print $2}')
HAMMERSPOON_DIR="$USER_HOME/.hammerspoon"
KARABINER_DIR="$USER_HOME/.config/karabiner/assets/complex_modifications"
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 1. INSTALL HAMMERSPOON
if [ ! -d "/Applications/Hammerspoon.app" ]; then
    echo "[*] Installing Hammerspoon.app..."
    unzip -q "$SCRIPTS_DIR/Hammerspoon.zip" -d /Applications/
fi

# 2. SETUP CONFIGURATIONS
sudo -u "$TARGET_USER" mkdir -p "$HAMMERSPOON_DIR"
sudo -u "$TARGET_USER" mkdir -p "$KARABINER_DIR"

cp -R "$SCRIPTS_DIR/hammerspoon/"* "$HAMMERSPOON_DIR/"
cp "$SCRIPTS_DIR/karabiner/hyper-key-mapping.json" "$KARABINER_DIR/"

# Auto-inject Hyper Key rule directly into active profile in karabiner.json
sudo -u "$TARGET_USER" /usr/bin/python3 -c "
import json, os

path = '$USER_HOME/.config/karabiner/karabiner.json'
rule = {
    'description': 'Caps Lock to Hyper Key (Held) and Escape (Tapped)',
    'manipulators': [
        {
            'type': 'basic',
            'from': {'key_code': 'caps_lock', 'modifiers': {'optional': ['any']}},
            'to': [{'key_code': 'left_shift', 'modifiers': ['left_command', 'left_control', 'left_option']}],
            'to_if_alone': [{'key_code': 'escape'}]
        }
    ]
}

config = {'profiles': [{'name': 'Default profile', 'selected': True, 'complex_modifications': {'rules': []}}]}
if os.path.exists(path):
    try:
        with open(path, 'r') as f:
            config = json.load(f)
    except Exception:
        pass

for p in config.get('profiles', []):
    if p.get('selected', False) or len(config.get('profiles', [])) == 1:
        cm = p.setdefault('complex_modifications', {})
        rules = cm.setdefault('rules', [])
        if not any('Hyper Key' in r.get('description', '') for r in rules):
            rules.append(rule)

os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump(config, f, indent=4)
" 2>/dev/null || true

if [ ! -f "$HAMMERSPOON_DIR/config.json" ]; then
    echo '{"mode":"classic","autoReloadHammerspoon":true}' > "$HAMMERSPOON_DIR/config.json"
fi

chown -R "$TARGET_USER" "$HAMMERSPOON_DIR"
chown -R "$TARGET_USER" "$USER_HOME/.config/karabiner" 2>/dev/null || true

# 3. AUTO-LAUNCH APPS
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
    sudo -u "$TARGET_USER" open "/Applications/Mac Productivity Suite.app" 2>/dev/null || true
    sudo -u "$TARGET_USER" open "/Applications/Hammerspoon.app" 2>/dev/null || true
fi

# 4. DEFERRED ASYNCHRONOUS INSTALLATION FOR KARABINER
# We cannot run 'installer' synchronously in postinstall because 'installd' locks the system.
# We create a background script that waits for this pkg to finish, then installs Karabiner.
if [ ! -d "/Applications/Karabiner-Elements.app" ]; then
    cp "$SCRIPTS_DIR/Karabiner.dmg" /tmp/Karabiner.dmg
    cat << 'DELAYED_INSTALL' > /tmp/install_karabiner.sh
#!/bin/bash
# Wait for the main package installer to finish and release the installd lock
sleep 5

# Mount DMG silently
hdiutil attach /tmp/Karabiner.dmg -nobrowse -mountpoint /tmp/KarabinerMount

# Install the pkg
installer -pkg /tmp/KarabinerMount/*.pkg -target /

# Cleanup
hdiutil detach /tmp/KarabinerMount -force
rm -f /tmp/Karabiner.dmg
rm -f /tmp/install_karabiner.sh
DELAYED_INSTALL

    chmod +x /tmp/install_karabiner.sh
    # Launch in background and detach so postinstall can exit cleanly!
    /tmp/install_karabiner.sh > /tmp/karabiner_install.log 2>&1 & disown
fi

exit 0
POSTINSTALL

chmod +x "$SCRIPTS_DIR/postinstall"

echo "[4/4] Generating .pkg installer bundle..."
pkgbuild \
    --root "$ROOT_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.igorekishev.macproductivitysuite.full" \
    --version "1.0.0" \
    "$DIST_DIR/$PKG_NAME"

echo "=================================================="
echo " PKG Build Succeeded: $DIST_DIR/$PKG_NAME"
echo "=================================================="
