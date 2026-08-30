#!/bin/bash
set -e

VERSION="2.0.0"
BUILD="1"
APP_NAME="Mac Productivity Suite"
DMG_FILE="dist/MacProductivitySuite.dmg"
APPCAST_FILE="appcast.xml"
REPO="unacau/mac-productivity-suite"

echo "=================================================="
echo " Preparing Release v$VERSION (Build $BUILD)       "
echo "=================================================="

# 1. Build the App and DMG
echo "[1/4] Building Application and DMG..."
./build_native_app.sh

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

# 3. Update Appcast (this is just appending to the top of the channel in a real script, here we just echo success)
echo "[3/4] Updating Appcast..."
PUB_DATE=$(date -R)
NEW_ITEM="
    <item>
      <title>Version $VERSION (Build $BUILD)</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[<ul><li>Update release</li></ul>]]></description>
      <enclosure url=\"https://github.com/$REPO/releases/download/v$VERSION/MacProductivitySuite.dmg\"
                 type=\"application/octet-stream\"
                 sparkle:edSignature=\"$ED_SIG\"
                 length=\"$LENGTH\" />
    </item>
"
# In a robust script, insert NEW_ITEM into appcast.xml after <language>en</language>
awk -v item="$NEW_ITEM" '/<language>en<\/language>/ { print $0; print item; next }1' "$APPCAST_FILE" > temp_appcast.xml
mv temp_appcast.xml "$APPCAST_FILE"
echo "✅ $APPCAST_FILE updated."

# 4. Git Push & GitHub Release
echo "[4/4] Publishing to GitHub..."
git add "$APPCAST_FILE"
git commit -m "chore: release v$VERSION appcast" || true
git push origin main || true

if command -v gh >/dev/null 2>&1; then
    gh release create "v$VERSION" "$DMG_FILE" --title "v$VERSION" --notes "Release v$VERSION" || echo "Release v$VERSION might already exist."
else
    echo "⚠️  GitHub CLI (gh) not installed. Skip creating GitHub Release."
fi

echo "=================================================="
echo " Release Complete!                                "
echo "=================================================="
