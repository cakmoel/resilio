#!/bin/bash
# Apply branch protection rules for Resilio Load Testing Suite
# Usage: ./apply-branch-protection.sh [owner] [repo]

set -euo pipefail

# Default values (can be overridden)
OWNER="${1:-$(git config --get remote.origin.url | sed 's/.*:\([^/]*\)\/.*/\1/')}"
REPO="${2:-$(basename "$(git remote get-url origin)" .git)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is required but not installed"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI not authenticated. Run 'gh auth login'"
    exit 1
fi

log_info "Applying branch protection rules for ${OWNER}/${REPO}"

# Branch protection configuration
PROTECTION_CONFIG='{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true,
  "allow_fork_syncing": false
}'

# Apply branch protection
log_info "Applying branch protection to main branch..."

if gh api \
  --method PUT \
  "repos/${OWNER}/${REPO}/branches/main/protection" \
  --header "Accept: application/vnd.github.v3+json" \
  --field "required_status_checks=$(echo "$PROTECTION_CONFIG" | jq '.required_status_checks')" \
  --field "enforce_admins=$(echo "$PROTECTION_CONFIG" | jq '.enforce_admins')" \
  --field "required_pull_request_reviews=$(echo "$PROTECTION_CONFIG" | jq '.required_pull_request_reviews')" \
  --field "restrictions=$(echo "$PROTECTION_CONFIG" | jq '.restrictions')" \
  --field "allow_force_pushes=$(echo "$PROTECTION_CONFIG" | jq '.allow_force_pushes')" \
  --field "allow_deletions=$(echo "$PROTECTION_CONFIG" | jq '.allow_deletions')" \
  --field "required_linear_history=$(echo "$PROTECTION_CONFIG" | jq '.required_linear_history')" \
  --field "allow_fork_syncing=$(echo "$PROTECTION_CONFIG" | jq '.allow_fork_syncing')" \
  --silent; then
  
    log_info "✅ Branch protection rules applied successfully!"
else
    log_error "❌ Failed to apply branch protection rules"
    exit 1
fi

# Verify the rules were applied
log_info "Verifying branch protection rules..."

if PROTECTION_STATUS=$(gh api "repos/${OWNER}/${REPO}/branches/main/protection" 2>/dev/null); then
    log_info "Current protection rules:"
    echo "$PROTECTION_STATUS" | jq '{
      required_status_checks: .required_status_checks,
      enforce_admins: .enforce_admins,
      required_pull_request_reviews: .required_pull_request_reviews,
      allow_force_pushes: .allow_force_pushes,
      allow_deletions: .allow_deletions,
      required_linear_history: .required_linear_history
    }'
else
    log_warn "Could not verify branch protection status (this might be expected if you don't have admin rights)"
fi

# Show key security settings
log_info "🔒 Key security settings applied:"
echo "  • Admin enforcement: Enabled (no bypass for admins)"
echo "  • CI required: Strict mode (up-to-date before merge)"
echo "  • Pull request reviews: 1 required approval"
echo "  • Force pushes: Disabled"
echo "  • Branch deletion: Disabled"
echo "  • Linear history: Required"

log_info "📋 Next steps:"
echo "  1. Test the protection by creating a test PR"
echo "  2. Verify CI runs and passes"
echo "  3. Check that merge requires approval"
echo "  4. Document any team-specific procedures"

log_info "🔗 Useful commands:"
echo "  • View protection: gh api repos/${OWNER}/${REPO}/branches/main/protection"
echo "  • Remove protection: gh api --method DELETE repos/${OWNER}/${REPO}/branches/main/protection"
echo "  • List PRs: gh pr list"

log_warn "⚠️  Important notes:"
echo "  • Only repository admins can apply branch protection"
echo "  • These rules apply to ALL contributors including admins"
echo "  • Emergency bypass requires admin rights and proper documentation"
echo "  • Consider CODEOWNERS file for code owner review requirements"