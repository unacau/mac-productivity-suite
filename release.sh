#!/bin/bash
set -e

VERSION="2.0.0"
BUILD="1"
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
if [ -f "sparkle_private.key" ]; then
    SIGNATURE_OUTPUT=$(Frameworks/bin/sign_update -f sparkle_private.key "$DMG_FILE")
else
    # Assume keychain
    SIGNATURE_OUTPUT=$(Frameworks/bin/sign_update "$DMG_FILE")
fi

ED_SIG=$(echo "$SIGNATURE_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
LENGTH=$(echo "$SIGNATURE_OUTPUT" | grep -o 'length="[^"]*"' | cut -d'"' -f2)

if [ -z "$ED_SIG" ] || [ -z "$LENGTH" ]; then
    echo "❌ Failed to sign DMG or parse output."
    exit 1
fi
echo "✅ Signature generated."

# 3. Update Appcast
echo "[3/4] Updating Appcast..."
PUB_DATE=$(date -R)

python3 -c "
import os

appcast_file = '$APPCAST_FILE'
version = '$VERSION'
build = '$BUILD'
pub_date = '$PUB_DATE'
repo = '$REPO'
ed_sig = '$ED_SIG'
length = '$LENGTH'

xml_template = f'''<?xml version=\"1.0\" encoding=\"utf-8\"?>
<rss version=\"2.0\" xmlns:sparkle=\"http://www.andymatuschak.org/xml-namespaces/sparkle\"  xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
  <channel>
    <title>Mac Productivity Suite Changelog</title>
    <link>https://raw.githubusercontent.com/{repo}/main/appcast.xml</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
    <item>
      <title>Version {version} (Build {build})</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{build}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[<ul>
        <li>Universal Multi-User Engine</li>
        <li>Dynamic App Discovery</li>
        <li>Automatic Chrome Profiles (Brave, Edge, Chromium)</li>
        <li>New Preferences UI</li>
      </ul>]]></description>
      <enclosure url=\"https://github.com/{repo}/releases/download/v{version}/MacProductivitySuite.dmg\"
                 type=\"application/octet-stream\"
                 sparkle:edSignature=\"{ed_sig}\"
                 length=\"{length}\" />
    </item>
  </channel>
</rss>
'''

with open(appcast_file, 'w', encoding='utf-8') as f:
    f.write(xml_template)
"

echo "✅ $APPCAST_FILE updated successfully."

# 4. Git Push & GitHub Release
echo "[4/4] Publishing to GitHub..."
git add "$APPCAST_FILE"
git commit -m "chore: release v$VERSION appcast and installers" || true
git push -u origin main || echo "⚠️  Git push failed. Ensure you have push access to the repository."

if command -v gh >/dev/null 2>&1; then
    gh release create "v$VERSION" "$DMG_FILE" "$PKG_FILE" --title "v$VERSION" --notes "Release v$VERSION (Includes Standalone DMG and Full PKG)" || echo "Release v$VERSION might already exist."
else
    echo "⚠️  GitHub CLI (gh) not installed. Skip creating GitHub Release."
fi

echo "=================================================="
echo " Release Complete!                                "
echo "=================================================="
