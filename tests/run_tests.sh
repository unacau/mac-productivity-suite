#!/bin/bash
set -euo pipefail

echo "=================================================="
echo " Running Automated Test Suite                     "
echo "=================================================="

# Compile and run Swift unit tests
echo "[1/1] Running Swift Unit Tests via SPM..."
swift test

echo "=================================================="
echo " ALL AUTOMATED TESTS COMPLETED SUCCESSFULLY!      "
echo "=================================================="
