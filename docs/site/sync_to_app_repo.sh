#!/usr/bin/env bash
set -euo pipefail

# sync_to_app_repo.sh
# Synchronizes the Chomyak official website into the main mac-productivity-suite repo (docs/site)

WEBSITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/Users/igorekishev/Igor/igorekishev/mac-productivity-suite/docs/site"

echo "🐹 Synchronizing Chomyak website to: ${TARGET_DIR}..."
mkdir -p "${TARGET_DIR}"

rsync -av --delete \
  --exclude="assets/videos/*.mp4" \
  --exclude="assets/downloads/*.dmg" \
  "${WEBSITE_DIR}/" "${TARGET_DIR}/"

# Re-link or copy specific lightweight assets for GitHub Pages
mkdir -p "${TARGET_DIR}/assets/downloads"
mkdir -p "${TARGET_DIR}/assets/videos"

echo "✅ Website core assets synced."
echo "💡 To view locally in target repo: cd ${TARGET_DIR} && python3 serve.py 8081"
