#!/bin/bash
set -euo pipefail

echo "=================================================="
echo " Running Automated Test Suite                     "
echo "=================================================="

# 1. Compile and run Swift unit and integration tests
echo "[1/2] Running Swift tests (Unit & Integration) via SPM..."
swift test

# 2. Check Lua syntax for all Hammerspoon scripts
echo "[2/2] Checking Lua scripts syntax..."
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
