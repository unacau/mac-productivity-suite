#!/bin/bash
set -euo pipefail

# Forward to the universal native build pipeline
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/build_native_app.sh" "$@"
