#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Resilio v6.2.1 Release - Quick Command Reference
# =============================================================================
# This script ASSUMES:
# - You are on main
# - CI is green
# - Methodology + contract tests are locked
# =============================================================================

VERSION="6.2.1"
TAG="v${VERSION}"
REPO="cakmoel/resilio"

echo "=== Resilio Release ${TAG} ==="

# =============================================================================
# STEP 0: Safety Checks
# =============================================================================

echo "=== Step 0: Safety Checks ==="

CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "❌ You must be on main to release (current: $CURRENT_BRANCH)"
  exit 1
fi

git diff --quiet || {
  echo "❌ Working tree not clean"
  exit 1
}

# =============================================================================
# STEP 1: Pre-Release Verification
# =============================================================================

echo ""
echo "=== Step 1: Verify Versions & Files ==="

# Version references
grep -R "v6.2" README.md docs || true
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

read -p "Proceed with tagging ${TAG}? (y/N): " CONFIRM
[[ "$CONFIRM" == "y" ]] || exit 1

# =============================================================================
# STEP 4: Create Annotated Tag
# =============================================================================

echo ""
echo "=== Step 4: Create Git Tag ==="

git tag -a "${TAG}" -m "Resilio ${TAG}: Reproducible Performance Auditing Toolkit

Key Highlights:
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
# STEP 6: GitHub Release (CLI)
# =============================================================================

echo ""
echo "=== Step 6: GitHub Release ==="

if command -v gh >/dev/null; then
  gh release create "${TAG}" \
    --repo "${REPO}" \
    --title "Resilio ${TAG} – Reproducible Performance Auditing" \
    --notes-file docs/methods.md \
    "${ARCHIVE_BASE}.tar.gz" \
    "${ARCHIVE_BASE}.zip"
  echo "✓ GitHub release created"
else
  echo "⚠ gh not installed. Create release manually:"
  echo "  https://github.com/${REPO}/releases/new"
fi

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
