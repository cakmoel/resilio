#!/bin/bash
# Check branch protection status for Resilio repositories
# Usage: ./check-protection.sh [owner/repo]

set -euo pipefail

REPO="${1:-$(git config --get remote.origin.url | sed 's/.*github.com[/:]\(.*\)\.git/\1/')}"
if [ -z "$REPO" ]; then
    echo "Usage: $0 [owner/repo]"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_protection() {
    echo -e "${BLUE}🔍 Checking branch protection for ${REPO}${NC}"
    echo "=================================================="
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI not authenticated${NC}"
        exit 1
    fi
    
    if PROTECTION=$(gh api "repos/${REPO}/branches/main/protection" 2>/dev/null); then
        echo -e "${GREEN}✅ Branch protection is enabled${NC}"
        echo ""
        
        # Parse and display key settings
        ENFORCE_ADMINS=$(echo "$PROTECTION" | jq -r '.enforce_admins')
        STRICT_CHECKS=$(echo "$PROTECTION" | jq -r '.required_status_checks.strict')
        REQUIRED_REVIEWS=$(echo "$PROTECTION" | jq -r '.required_pull_request_reviews.required_approving_review_count')
        DISMISS_STALE=$(echo "$PROTECTION" | jq -r '.required_pull_request_reviews.dismiss_stale_reviews')
        ALLOW_FORCE=$(echo "$PROTECTION" | jq -r '.allow_force_pushes')
        ALLOW_DELETION=$(echo "$PROTECTION" | jq -r '.allow_deletions')
        LINEAR_HISTORY=$(echo "$PROTECTION" | jq -r '.required_linear_history')
        
        echo -e "${BLUE}📋 Protection Rules:${NC}"
        echo -e "  Admin Enforcement: $([ "$ENFORCE_ADMINS" == "true" ] && echo "${GREEN}✅ Enabled${NC}" || echo "${RED}❌ Disabled${NC}")"
        echo -e "  Strict CI Checks: $([ "$STRICT_CHECKS" == "true" ] && echo "${GREEN}✅ Enabled${NC}" || echo "${YELLOW}⚠️  Disabled${NC}")"
        echo -e "  Required Reviews: ${GREEN}${REQUIRED_REVIEWS} approval(s)${NC}"
        echo -e "  Dismiss Stale Reviews: $([ "$DISMISS_STALE" == "true" ] && echo "${GREEN}✅ Enabled${NC}" || echo "${YELLOW}⚠️  Disabled${NC}")"
        echo -e "  Force Pushes: $([ "$ALLOW_FORCE" == "false" ] && echo "${GREEN}✅ Blocked${NC}" || echo "${RED}❌ Allowed${NC}")"
        echo -e "  Branch Deletion: $([ "$ALLOW_DELETION" == "false" ] && echo "${GREEN}✅ Blocked${NC}" || echo "${RED}❌ Allowed${NC}")"
        echo -e "  Linear History: $([ "$LINEAR_HISTORY" == "true" ] && echo "${GREEN}✅ Required${NC}" || echo "${YELLOW}⚠️  Not Required${NC}")"
        
        # Status checks
        echo ""
        echo -e "${BLUE}🔧 Required Status Checks:${NC}"
        CONTEXTS=$(echo "$PROTECTION" | jq -r '.required_status_checks.contexts[]?' 2>/dev/null || echo "None")
        if [ "$CONTEXTS" != "None" ] && [ -n "$CONTEXTS" ]; then
            echo "$CONTEXTS" | while read -r context; do
                echo "  • ${GREEN}$context${NC}"
            done
        else
            echo "  ${YELLOW}⚠️  No status checks required${NC}"
        fi
        
        # Security score
        echo ""
        echo -e "${BLUE}🛡️  Security Assessment:${NC}"
        SCORE=0
        MAX=7
        
        [ "$ENFORCE_ADMINS" == "true" ] && ((SCORE++))
        [ "$STRICT_CHECKS" == "true" ] && ((SCORE++))
        [ "$REQUIRED_REVIEWS" -ge 1 ] && ((SCORE++))
        [ "$DISMISS_STALE" == "true" ] && ((SCORE++))
        [ "$ALLOW_FORCE" == "false" ] && ((SCORE++))
        [ "$ALLOW_DELETION" == "false" ] && ((SCORE++))
        [ "$LINEAR_HISTORY" == "true" ] && ((SCORE++))
        
        if [ "$SCORE" -eq "$MAX" ]; then
            echo -e "  ${GREEN}✅ Excellent security posture (${SCORE}/${MAX})${NC}"
        elif [ "$SCORE" -ge 5 ]; then
            echo -e "  ${YELLOW}⚠️  Good security posture (${SCORE}/${MAX})${NC}"
        else
            echo -e "  ${RED}❌ Poor security posture (${SCORE}/${MAX})${NC}"
        fi
        
    else
        echo -e "${RED}❌ No branch protection found on main branch${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Security Risk:${NC}"
        echo "  • Anyone can push directly to main"
        echo "  • No code reviews required"
        echo "  • No CI validation required"
        echo "  • History can be rewritten"
        echo ""
        echo -e "${BLUE}🚀 Quick Fix:${NC}"
        echo "  Run: .github/apply-branch-protection.sh"
        echo "  Or: GitHub UI → Settings → Branches → Add rule"
    fi
    
    echo ""
    echo -e "${BLUE}📊 Repository Info:${NC}"
    if REPO_INFO=$(gh api "repos/${REPO}" 2>/dev/null); then
        PRIVATE=$(echo "$REPO_INFO" | jq -r '.private')
        FORKS=$(echo "$REPO_INFO" | jq -r '.forks_count')
        STARS=$(echo "$REPO_INFO" | jq -r '.stargazers_count')
        
        echo "  • Visibility: $([ "$PRIVATE" == "true" ] && echo "Private" || echo "Public")"
        echo "  • Forks: $FORKS"
        echo "  • Stars: $STARS"
    fi
}

# Check if CODEOWNERS exists
check_codeowners() {
    echo ""
    echo -e "${BLUE}👥 CODEOWNERS Check:${NC}"
    
    if gh api "repos/${REPO}/contents/.github/CODEOWNERS" 2>/dev/null > /dev/null; then
        echo -e "  ${GREEN}✅ CODEOWNERS file exists${NC}"
    else
        echo -e "  ${YELLOW}⚠️  No CODEOWNERS file found${NC}"
        echo "  Consider adding .github/CODEOWNERS for review requirements"
    fi
}

# Main execution
check_protection
check_codeowners

echo ""
echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo "  • Apply protection: .github/apply-branch-protection.sh"
echo "  • View details: gh api repos/${REPO}/branches/main/protection"
echo "  • Recent PRs: gh pr list --repo ${REPO}"