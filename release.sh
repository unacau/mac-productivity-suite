#!/bin/bash
set -euo pipefail

VERSION=$(cat VERSION.txt)
BUILD=$(cat BUILD.txt)
APP_NAME="Mac Productivity Suite"
DMG_FILE="dist/MacProductivitySuite.dmg"
PKG_FILE="dist/MacProductivitySuite-Full.pkg"
APPCAST_FILE="appcast.xml"
REPO="unacau/mac-productivity-suite"

echo "=================================================="
echo " Preparing Release v$VERSION (Build $BUILD)       "
echo "=================================================="

# 1. Build the Apps
echo "[1/4] Building Applications and Installers..."
./build_native_app.sh
./build_full_pkg.sh

# 2. Sign DMG with Sparkle
echo "[2/4] Signing DMG with Sparkle EdDSA..."
if [ -s "sparkle_private.key" ]; then
    SIGNATURE_OUTPUT=$(Frameworks/bin/sign_update -f sparkle_private.key "$DMG_FILE")
    ED_SIG=$(echo "$SIGNATURE_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
    LENGTH=$(echo "$SIGNATURE_OUTPUT" | grep -o 'length="[^"]*"' | cut -d'"' -f2)
elif [ -z "${CI:-}" ]; then
    SIGNATURE_OUTPUT=$(Frameworks/bin/sign_update "$DMG_FILE" 2>/dev/null || true)
    ED_SIG=$(echo "$SIGNATURE_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
    LENGTH=$(echo "$SIGNATURE_OUTPUT" | grep -o 'length="[^"]*"' | cut -d'"' -f2)
    if [ -z "$LENGTH" ]; then
        LENGTH=$(wc -c < "$DMG_FILE" | tr -d ' ')
    fi
else
    echo "ℹ️  Running in CI without key; calculating payload length."
    ED_SIG=""
    LENGTH=$(wc -c < "$DMG_FILE" | tr -d ' ')
fi
echo "✅ Packaging info generated (Length: $LENGTH)."

# 3. Update Appcast
echo "[3/4] Updating Appcast..."
export APPCAST_FILE="$APPCAST_FILE"
export VERSION="$VERSION"
export BUILD="$BUILD"
export PUB_DATE="$(date -R)"
export REPO="$REPO"
export ED_SIG="$ED_SIG"
export LENGTH="$LENGTH"

python3 - << 'PYEOF'
import os

appcast_file = os.environ['APPCAST_FILE']
version = os.environ['VERSION']
build = os.environ['BUILD']
pub_date = os.environ['PUB_DATE']
repo = os.environ['REPO']
ed_sig = os.environ['ED_SIG']
length = os.environ['LENGTH']

new_item = f'''    <item>
      <title>Version {version} (Build {build})</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{build}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[<ul>
        <li><strong>Accurate Chromium Profile Selection & Focus</strong>: Resolved an issue where selecting a browser profile in the HUD opened/focused the wrong profile window due to menu ordering differences. Implemented GAIA title disambiguation and precise native menu title matching.</li>
        <li><strong>Synchronized Active Profile Tracking</strong>: Checkmark (✓) active profile tracking now accurately identifies the focused window across all profiles, eliminating HUD desynchronization.</li>
        <li><strong>Pure Native Driverless Engine</strong>: 100% native Swift 6 engine with driverless Caps Lock Hyper Key mapping via hidutil and Carbon/CGEvent taps.</li>
        <li><strong>Instant HUD Overlay Dismissal</strong>: Re-engineered dismissal lifecycle so the floating HUD vanishes the exact millisecond keys are released.</li>
        <li><strong>Sparkle Auto-Updates</strong>: Integrated Sparkle 2.x with EdDSA signature verification.</li>
      </ul>]]></description>
      <enclosure url="https://github.com/{repo}/releases/download/v{version}/MacProductivitySuite.dmg"
                 type="application/octet-stream"
                 sparkle:edSignature="{ed_sig}"
                 length="{length}" />
    </item>'''

if os.path.exists(appcast_file):
    with open(appcast_file, 'r', encoding='utf-8') as f:
        content = f.read()
    if '<item>' in content:
        updated_content = content.replace('<item>', new_item + '\n    <item>', 1)
    else:
        updated_content = content.replace('</channel>', new_item + '\n  </channel>', 1)
else:
    updated_content = f'''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Mac Productivity Suite Changelog</title>
    <link>https://raw.githubusercontent.com/{repo}/main/appcast.xml</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
{new_item}
  </channel>
</rss>
'''

with open(appcast_file, 'w', encoding='utf-8') as f:
    f.write(updated_content)
PYEOF

echo "✅ $APPCAST_FILE updated successfully."

# 4. Git Push & GitHub Release
echo "[4/4] Publishing to GitHub..."
if [ -z "${CI:-}" ]; then
    git add -A
    git commit -m "release: v$VERSION with accurate Chromium profile selection and focus synchronization" || true
    git tag -a "v$VERSION" -m "Release v$VERSION" || true
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    git push -u origin "$CURRENT_BRANCH" || echo "⚠️  Git push failed. Ensure you have push access to the repository."
    if [ "$CURRENT_BRANCH" != "main" ]; then
        git push origin "$CURRENT_BRANCH:main" || echo "⚠️  Git push to main failed."
    fi
    git push origin "v$VERSION" || echo "⚠️  Git push tag failed."

    if command -v gh >/dev/null 2>&1; then
        gh release create "v$VERSION" "$DMG_FILE" "$PKG_FILE" --title "v$VERSION" --notes "### Release v$VERSION
- **Accurate Chromium Profile Selection & Focus**: Resolved an issue where selecting a browser profile in the HUD opened/focused the wrong profile window due to menu ordering differences. Implemented GAIA title disambiguation and precise native menu title matching.
- **Synchronized Active Profile Tracking**: Checkmark (\`✓\`) active profile tracking now accurately identifies the focused window across all profiles, eliminating HUD desynchronization.
- **Pure Native Driverless Engine**: 100% native Swift 6 engine with driverless Caps Lock Hyper Key mapping via macOS \`hidutil\` and Carbon/CGEvent taps.
- **Instant HUD Overlay Dismissal**: Re-engineered dismissal lifecycle so the floating HUD vanishes the exact millisecond keys are released.
- **Non-Blocking App Cold Starts**: Delegated browser launches to \`/usr/bin/open\` to eliminate main-thread hangs on cold start.
- **Sparkle Auto-Updates**: Integrated Sparkle 2.x with EdDSA signature verification and offline PKG bundle packaging." || echo "Release v$VERSION might already exist."
    else
        echo "⚠️  GitHub CLI (gh) not installed. Skip creating GitHub Release."
    fi
else
    echo "Running inside CI environment, skipping local git commit and push."
fi

echo "=================================================="
echo " Release Complete!                                "
echo "=================================================="
