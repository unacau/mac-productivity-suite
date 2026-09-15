#!/bin/bash
set -euo pipefail

# ==============================================================================
# Chrome Quick Access - Release Management Utility
# Supports both Cloud-Native Tag Releases (GHA) and Local Distribution
# ==============================================================================

VERSION=$(cat VERSION.txt | tr -d '[:space:]')
BUILD=$(cat BUILD.txt | tr -d '[:space:]')
APP_NAME="Chomyyak"
DMG_FILE="dist/Chomyyak.dmg"
CHECKSUM_FILE="dist/checksums.txt"
REPO="unacau/mac-productivity-suite"
TAG="v$VERSION"

MODE="cloud"
DRY_RUN=0

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  --push           Create git tag '$TAG' and push to origin (triggers GitHub Actions release).
  --tag-only       Create git tag '$TAG' locally without pushing.
  --local          Build locally, generate checksums, and publish via local 'gh' CLI.
  --dry-run        Perform pre-flight verification without creating tags or publishing.
  -h, --help       Show this help message.

Default behavior:
  Runs pre-flight verification and guides you through triggering the automated
  GitHub Actions cloud release pipeline.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --push)
            MODE="push"
            ;;
        --tag-only)
            MODE="tag"
            ;;
        --local)
            MODE="local"
            ;;
        --dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            print_usage
            exit 1
            ;;
    esac
done

echo "=================================================="
echo " Preparing Release $TAG (Build $BUILD)"
echo " App: $APP_NAME"
echo " Mode: $MODE (Dry Run: $DRY_RUN)"
echo "=================================================="

# 1. Pre-Flight Quality Gate & Health Check
echo "[1/3] Running Pre-Flight Quality Gate & Diagnostics..."
./scripts/health_check.sh

if [ $DRY_RUN -eq 1 ]; then
    echo "=================================================="
    echo " 🔎 Dry run complete. Pre-flight health passed!"
    echo " Would target Tag: $TAG (v$VERSION, Build $BUILD)"
    echo "=================================================="
    exit 0
fi

# 2. Execution based on selected mode
case "$MODE" in
    push)
        echo "[2/3] Tagging release $TAG..."
        if git rev-parse "$TAG" >/dev/null 2>&1; then
            echo "ℹ️ Tag $TAG already exists locally."
        else
            git tag -a "$TAG" -m "Release $TAG (Build $BUILD)"
            echo "✅ Created git tag $TAG."
        fi

        echo "[3/3] Pushing tag to origin to trigger GitHub Actions release..."
        git push origin "$TAG"
        echo "=================================================="
        echo " 🚀 Release Pipeline Triggered via GitHub Actions!"
        echo " Track progress at: https://github.com/$REPO/actions"
        echo "=================================================="
        ;;

    tag)
        echo "[2/3] Creating git tag $TAG locally..."
        if git rev-parse "$TAG" >/dev/null 2>&1; then
            echo "ℹ️ Tag $TAG already exists locally."
        else
            git tag -a "$TAG" -m "Release $TAG (Build $BUILD)"
            echo "✅ Tag $TAG created."
        fi
        echo "[3/3] Done. Push whenever ready with:"
        echo "      git push origin $TAG"
        ;;

    local)
        echo "[2/3] Building Universal Application, DMG & Checksums locally..."
        ./build_native_app.sh
        mkdir -p dist
        cd dist
        shasum -a 256 ChromeQuickAccess.dmg > checksums.txt
        echo "✅ Checksum computed: $(cat checksums.txt)"
        cd ..

        echo "[3/3] Publishing via local GitHub CLI (gh)..."
        if command -v gh >/dev/null 2>&1; then
            gh release create "$TAG" "$DMG_FILE" "$CHECKSUM_FILE" \
                --title "$TAG - $APP_NAME & Productivity Suite" \
                --notes "Release $TAG (Build $BUILD) of Chrome Quick Access featuring driverless Caps-Lock remapping, multi-profile Chrome cycling, Antigravity switcher, and universal Copy-on-Select." \
                --repo "$REPO" || echo "ℹ️ gh release command skipped or already exists."
        else
            echo "ℹ️ GitHub CLI (gh) not installed. Artifacts available at $DMG_FILE and $CHECKSUM_FILE."
        fi
        echo "=================================================="
        echo " ✅ Local Release $TAG Completed!"
        echo " Artifacts: $DMG_FILE, $CHECKSUM_FILE"
        echo "=================================================="
        ;;

    cloud)
        echo "[2/3] Verifying git state..."
        if git rev-parse "$TAG" >/dev/null 2>&1; then
            echo "ℹ️ Tag $TAG already exists."
        else
            echo "Tag $TAG is ready to be created."
        fi

        echo "[3/3] Ready to trigger Cloud Release Workflow!"
        echo ""
        echo "To trigger the automated GitHub Actions release workflow, run:"
        echo "  ./release.sh --push"
        echo ""
        echo "Or run manually:"
        echo "  git tag -a $TAG -m \"Release $TAG (Build $BUILD)\""
        echo "  git push origin $TAG"
        echo ""
        echo "For an offline/local build & publish directly from this machine:"
        echo "  ./release.sh --local"
        echo "=================================================="
        ;;
esac
