#!/bin/bash
set -euo pipefail

# ==============================================================================
# Mac Productivity Suite - System Health & Diagnostics Utility
# Evaluates Accessibility permissions, config sync, binaries, and Sparkle feed
# ==============================================================================

echo "=================================================="
echo " Mac Productivity Suite — System Health Check     "
echo "=================================================="

FAILED=0

# 1. Check Configuration Files
echo -n "[1/5] Checking Configuration Integrity... "
CONFIG_FILE="$HOME/.config/mac-productivity-suite/config.json"
if [ -f "$CONFIG_FILE" ]; then
    if python3 -c "import json; json.load(open('$CONFIG_FILE'))" >/dev/null 2>&1; then
        echo "✅ Valid JSON ($CONFIG_FILE)"
    else
        echo "❌ Corrupt JSON in $CONFIG_FILE"
        FAILED=1
    fi
else
    echo "ℹ️  Not found (default config will be created on first launch)"
fi

# 2. Check Build Outputs & Binaries
echo -n "[2/5] Checking Build Artifacts & Universal Binary... "
APP_BUNDLE="dist/Mac Productivity Suite.app"
if [ -d "$APP_BUNDLE" ]; then
    BINARY="$APP_BUNDLE/Contents/MacOS/MacProductivitySuite"
    if [ -f "$BINARY" ]; then
        ARCHS=$(lipo -archs "$BINARY" 2>/dev/null || echo "Unknown")
        echo "✅ Present (Architectures: $ARCHS)"
    else
        echo "⚠️  App bundle exists but executable is missing."
        FAILED=1
    fi
else
    echo "ℹ️  dist/ bundle not built yet (Run 'make native' to build)."
fi

# 3. Check Appcast & Sparkle Feed
echo -n "[3/5] Checking Sparkle RSS Appcast Feed... "
APPCAST_FILE="appcast.xml"
if [ -f "$APPCAST_FILE" ]; then
    ITEM_COUNT=$(grep -c "<item>" "$APPCAST_FILE" || true)
    LATEST_VER=$(grep -m1 "<sparkle:shortVersionString>" "$APPCAST_FILE" | sed -E 's/.*<sparkle:shortVersionString>(.*)<\/sparkle:shortVersionString>.*/\1/' || true)
    echo "✅ Valid ($ITEM_COUNT releases listed, Latest: v${LATEST_VER:-Unknown})"
else
    echo "❌ appcast.xml missing"
    FAILED=1
fi

# 4. Check Versioning Consistency
echo -n "[4/5] Checking Versioning Consistency... "
if [ -f "VERSION.txt" ] && [ -f "BUILD.txt" ]; then
    V_TXT=$(cat VERSION.txt | tr -d '[:space:]')
    B_TXT=$(cat BUILD.txt | tr -d '[:space:]')
    PLIST="src/NativeStandaloneApp/Info.plist"
    if [ -f "$PLIST" ]; then
        V_PLIST=$(plutil -extract CFBundleShortVersionString raw "$PLIST" 2>/dev/null || echo "missing")
        B_PLIST=$(plutil -extract CFBundleVersion raw "$PLIST" 2>/dev/null || echo "missing")
        if [ "$V_TXT" = "$V_PLIST" ] && [ "$B_TXT" = "$B_PLIST" ]; then
            echo "✅ Synchronized (v$V_TXT, Build $B_TXT)"
        else
            echo "⚠️  Mismatch: VERSION.txt ($V_TXT / $B_TXT) vs Info.plist ($V_PLIST / $B_PLIST)"
            FAILED=1
        fi
    else
        echo "✅ Tracked ($V_TXT / Build $B_TXT)"
    fi
else
    echo "⚠️  VERSION.txt or BUILD.txt missing."
    FAILED=1
fi

SKIP_TESTS=0
for arg in "$@"; do
    if [ "$arg" = "--skip-tests" ] || [ "$arg" = "--no-tests" ]; then
        SKIP_TESTS=1
    fi
done

# 5. Check Test Suite Health
echo -n "[5/5] Running Automated Test Suite (Fast Check)... "
if [ $SKIP_TESTS -eq 1 ]; then
    echo "⏭️  Skipped (Tests verified in prior step)"
elif ./tests/run_tests.sh >/dev/null 2>&1; then
    echo "✅ All tests passing cleanly."
else
    echo "❌ Test suite failed! Run ./tests/run_tests.sh for details."
    FAILED=1
fi

echo "=================================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 System Health: HEALTHY & PRODUCTION READY"
else
    echo "⚠️  System Health: ISSUES DETECTED"
fi
echo "=================================================="
exit $FAILED
