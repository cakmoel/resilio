#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Resilio Local Release Helper - DEVELOPMENT USE ONLY
# =============================================================================
# SECURITY NOTES:
# - This script is for LOCAL TESTING only
# - For production releases, use .github/workflows/release.yml
# - Requires explicit environment variables for security
# =============================================================================

# Security: Require explicit environment variables
if [[ -z "${RELEASE_VERSION:-}" ]]; then
  echo "❌ RELEASE_VERSION environment variable required"
  echo "   Usage: RELEASE_VERSION=6.3.0 ./release.sh"
  exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "❌ GITHUB_REPOSITORY environment variable required"
  echo "   Example: export GITHUB_REPOSITORY=cakmoel/resilio"
  exit 1
fi

VERSION="$RELEASE_VERSION"
TAG="v${VERSION}"
REPO="$GITHUB_REPOSITORY"

echo "=== Resilio LOCAL Release Helper ${TAG} ==="
echo "⚠️  For production releases, use GitHub Actions workflow"
echo ""

# =============================================================================
# STEP 0: Enhanced Security Checks
# =============================================================================

echo "=== Step 0: Security & Safety Checks ==="

# Verify format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid version format. Use X.Y.Z"
  exit 1
fi

# Branch check
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "❌ You must be on main to release (current: $CURRENT_BRANCH)"
  exit 1
fi

# Working tree check
git diff --quiet || {
  echo "❌ Working tree not clean"
  exit 1
}

# Tag existence check
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "❌ Tag $TAG already exists"
  exit 1
fi

# Confirm local development use
read -r -p "This is for LOCAL TESTING only. Continue? (y/N): " LOCAL_CONFIRM
[[ "$LOCAL_CONFIRM" == "y" ]] || exit 1

# =============================================================================
# STEP 1: Pre-Release Verification
# =============================================================================

echo ""
echo "=== Step 1: Verify Versions & Files ==="

# Version references
grep -R "v${VERSION}" README.md docs || true
grep -R "${VERSION}" docs || true

# Required files
ls -lh \
  bin/dlt.sh \
  bin/slt.sh \
  config/dlt.conf \
  docs/methodology.md \
  docs/methods.md \
  docs/USAGE_GUIDE.md\
  docs/REFERENCES.md \
  lib/*.sh \
  lib/*.py \
  LICENSE.md \
  SECURITY.md \
  CODE_OF_CONDUCT.md \
  CHANGELOG.md \
  CONTRIBUTING.md \
  Makefile \
  .github/workflows/ci.yml

# Syntax check
echo ""
echo "Checking bash syntax..."
bash -n bin/dlt.sh && echo "✓ bin/dlt.sh syntax OK"
bash -n bin/slt.sh && echo "✓ bin/slt.sh syntax OK"
bash -n lib/*.sh && echo "✓ lib scripts syntax OK"

# =============================================================================
# STEP 2: Run Final Tests
# =============================================================================

echo ""
echo "=== Step 2: Final Test Run ==="

make lint
make test

echo "✓ All tests passed"

# =============================================================================
# STEP 3: Create Release Commit (if needed)
# =============================================================================

echo ""
echo "=== Step 3: Release Commit Check ==="

echo "Latest commit:"
git log --oneline -1

read -r -p "Proceed with tagging ${TAG}? (y/N): " CONFIRM
[[ "$CONFIRM" == "y" ]] || exit 1

# =============================================================================
# STEP 4: Create Annotated Tag
# =============================================================================

echo ""
echo "=== Step 4: Create Git Tag ==="

git tag -a "${TAG}" -m "Resilio ${TAG}: Reproducible Performance Auditing Toolkit

Summary of v6.2.2 fixes:
- Resolved dlt.sh --dry-run hanging issue.
- Fixed unit test failures due to incorrect library sourcing in Bats subshells.
- Implemented missing choose_test and extract_samples functions.
- Standardized BASE_DIR and PROJECT_ROOT in Bats test setup.
- Addressed multiple shellcheck warnings (SC2155, SC2188, SC2046, SC2206).

Key Highlights of the Toolkit:
- Modular CLI + reusable statistical core
- Welch vs Mann–Whitney selection (Ruxton-aligned)
- Contract-locked statistical methodology
- Unit + system test separation (Bats)
- CI-enforced reproducibility
- Paper-ready Methods documentation

Statistical foundations:
- Welch (1947)
- Mann & Whitney (1947)
- Ruxton (2006)
- Robust to non-normal performance data"

git push origin "${TAG}"

echo "✓ Tag ${TAG} pushed"

# =============================================================================
# STEP 5: Create Release Archives
# =============================================================================

echo ""
echo "=== Step 5: Create Release Archives ==="

ARCHIVE_BASE="resilio-${TAG}"

tar -czf "${ARCHIVE_BASE}.tar.gz" \
  bin \
  lib \
  config \
  docs \
  Makefile \
  README.md \
  LICENSE.md \
  SECURITY.md \
  CODE_OF_CONDUCT.md \
  CHANGELOG.md \
  CONTRIBUTING.md \
  .github

zip -r "${ARCHIVE_BASE}.zip" \
  bin \
  lib \
  config \
  docs \
  Makefile \
  README.md \
  LICENSE.md \
  SECURITY.md \
  CODE_OF_CONDUCT.md \
  CHANGELOG.md \
  CONTRIBUTING.md \
  .github

ls -lh "${ARCHIVE_BASE}".*

# =============================================================================
# STEP 6: SECURITY WARNING - No Automated GitHub Release
# =============================================================================

echo ""
echo "=== Step 6: Security Notice ==="

echo "⚠️  Automated GitHub release DISABLED for security"
echo "   Use GitHub Actions workflow for production releases:"
echo "   https://github.com/${REPO}/actions/workflows/release.yml"
echo ""
echo "📋 To create release manually:"
echo "   1. Push tag: git push origin ${TAG}"
echo "   2. Visit: https://github.com/${REPO}/releases/new"
echo "   3. Upload archives: ${ARCHIVE_BASE}.*"
echo ""
echo "🔐 Security recommendation: Use GitHub Actions for automated releases"

# =============================================================================
# STEP 7: Verification
# =============================================================================

echo ""
echo "=== Step 7: Verify Release ==="

sleep 3
curl -s "https://api.github.com/repos/${REPO}/releases/latest" \
  | jq -r '.tag_name'

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "=== Release Summary ==="
echo "Version: ${TAG}"
echo "Commit: $(git rev-parse --short HEAD)"
echo "Date: $(date '+%Y-%m-%d')"
echo "✓ Release complete"
