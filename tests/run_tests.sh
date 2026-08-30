#!/bin/bash
set -euo pipefail

echo "=================================================="
echo " Running Automated Test Suite                     "
echo "=================================================="

# 1. Compile and run Swift unit tests
echo "[1/3] Running Swift tests via SPM..."
swift test

# We skip the legacy execution since SPM handles it

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
