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
        <li>Fixed a CI deadlock caused by parallel tests concurrently modifying the C-level environment variables (<code>setenv</code>).</li>
        <li>Optimized CI compile times by caching the SPM <code>.build</code> directory for SwiftSyntax.</li>
        <li>Serialized test execution to prevent <code>AppConfigManager</code> and <code>ChromeProfileHelper</code> singleton data races.</li>
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
    git commit -m "release: v$VERSION with CI/CD optimizations" || true
    git tag -a "v$VERSION" -m "Release v$VERSION" || true
    git push -u origin main || echo "⚠️  Git push failed. Ensure you have push access to the repository."
    git push origin "v$VERSION" || echo "⚠️  Git push tag failed."

    if command -v gh >/dev/null 2>&1; then
        gh release create "v$VERSION" "$DMG_FILE" "$PKG_FILE" --title "v$VERSION" --notes "### Release v$VERSION
- **CI Test Suite Hang Resolved**: Completely eliminated the deadlock in CI integration tests by removing parallel \`setenv\` mutations and fully serializing the test suites, preventing all cross-suite \`AppConfigManager\` singleton state corruption.
- **Lightning Fast CI Compilations**: Configured SPM \`.build\` caching in GitHub Actions, massively accelerating \`SwiftSyntax\` and \`swift-testing\` compilation times across pipeline runs.
- **Prevented Test Event Loop Hijacking**: Patched \`AppRunner.main()\` to dynamically intercept \`XCTest\` execution contexts, preventing \`NSApplication.shared.run()\` from indefinitely blocking headless CI runners." || echo "Release v$VERSION might already exist."
    else
        echo "⚠️  GitHub CLI (gh) not installed. Skip creating GitHub Release."
    fi
else
    echo "Running inside CI environment, skipping local git commit and push."
fi

echo "=================================================="
echo " Release Complete!                                "
echo "=================================================="
