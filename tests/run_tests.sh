#!/bin/bash
set -e

echo "=================================================="
echo " Running Automated Test Suite                     "
echo "=================================================="

# 1. Compile and run Swift unit tests
echo "[1/3] Compiling Swift unit test harness..."
mkdir -p dist/tests

swiftc \
    -parse-as-library \
    src/NativeStandaloneApp/Engine/HotkeyManager.swift \
    src/NativeStandaloneApp/Engine/AppConfig.swift \
    src/NativeStandaloneApp/Engine/AppDiscoveryService.swift \
    src/NativeStandaloneApp/Engine/ChromeProfileHelper.swift \
    src/NativeStandaloneApp/Engine/AppSwitcherEngine.swift \
    src/NativeStandaloneApp/Engine/CopyOnSelectEngine.swift \
    src/NativeStandaloneApp/Engine/ProductivityActionsHelper.swift \
    src/NativeStandaloneApp/Views/HUDOverlayWindow.swift \
    src/NativeStandaloneApp/Views/AppPickerSheet.swift \
    src/NativeStandaloneApp/Views/SettingsWindow.swift \
    src/NativeStandaloneApp/Views/MenuBarPopupView.swift \
    tests/SwiftUnitTests.swift \
    -o dist/tests/test_runner \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Carbon

echo "[2/3] Executing Swift Unit Tests..."
./dist/tests/test_runner

# 2. Check Lua syntax for all Hammerspoon scripts
echo "[3/3] Checking Lua scripts syntax..."
for f in hammerspoon/*.lua; do
    if command -v luac >/dev/null 2>&1; then
        luac -p "$f"
        echo "  ✅ Syntax OK: $f"
    else
        echo "  ℹ️ luac not found, checking file readability: $f"
        test -r "$f"
    fi
done

echo "=================================================="
echo " ALL AUTOMATED TESTS COMPLETED SUCCESSFULLY!      "
echo "=================================================="
