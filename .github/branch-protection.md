# Branch Protection Rules for Resilio Load Testing Suite

This document outlines the branch protection rules configured for the `main` branch to ensure code quality, security, and stability.

## Current Protection Rules

### Main Branch Protection
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI"
    ]
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
}
```

## Rule Details

### 1. Required Status Checks
- **Strict mode**: Enabled - Branches must be up to date before merging
- **Required checks**: 
  - `CI` - All CI workflow must pass (tests + linting)

### 2. Pull Request Reviews
- **Required approvals**: 1 reviewer
- **Dismiss stale reviews**: Automatically dismiss reviews when new commits are pushed
- **Code owner reviews**: Not required (small team)
- **Last push approval**: Not required

### 3. Branch Restrictions
- **Admin enforcement**: Admins must also follow rules (no bypass)
- **Force pushes**: Disabled for security
- **Deletions**: Disabled for safety
- **Linear history**: Required (no merge commits, use rebase)

## Setting Up Branch Protection

### Via GitHub UI (Recommended)
1. Go to repository Settings > Branches
2. Click "Add rule" for `main` branch
3. Configure as above
4. Save changes

### Via GitHub CLI
```bash
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["CI"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field required_linear_history=true
```

### Via API
```bash
curl -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/branches/main/protection \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["CI"]
    },
    "enforce_admins": true,
    "required_pull_request_reviews": {
      "required_approving_review_count": 1,
      "dismiss_stale_reviews": true
    },
    "allow_force_pushes": false,
    "allow_deletions": false,
    "required_linear_history": true
  }'
```

## Security Rationale

### Why Strict Mode?
- Prevents merging when CI is outdated
- Ensures all recent changes are tested
- Reduces risk of merging broken code

### Why Admin Enforcement?
- Ensures consistent code quality across all contributors
- Prevents accidental bypass of quality checks
- Maintains security standards

### Why Linear History?
- Cleaner, more readable project history
- Easier debugging and bisecting
- Prevents merge commit noise

### Why No Force Pushes?
- Prevents accidental history rewriting
- Maintains audit trail
- Protects against malicious changes

## CI Status Checks

The current CI workflow provides:
- ✅ **18 unit tests** - Comprehensive test coverage
- ✅ **Python tests** - Statistical engine validation  
- ✅ **ShellCheck** - Code quality and security
- ✅ **Multi-environment** - Ubuntu GitHub Actions

## Emergency Procedures

### Temporary Disable (Emergency Only)
1. Go to Settings > Branches > main branch
2. Temporarily disable protection
3. Make critical fix
4. Re-enable protection immediately
5. Document the emergency in changelog

### Emergency Bypass (Admin Only)
1. Use GitHub CLI with force flag:
   ```bash
   gh pr merge --merge --bypass-reviews PR_NUMBER
   ```
2. Document reason in commit message
3. Follow up with proper review

## Monitoring and Compliance

### Regular Audits
- Monthly review of protection rules
- Check for bypass attempts
- Verify CI health and reliability

### Alerts
- GitHub email notifications for protection rule changes
- Monitor for failed deployments
- Track CI failure rates

## Related Files

- `.github/workflows/ci.yml` - CI workflow configuration
- `Makefile` - Local development commands
- `CONTRIBUTING.md` - Development guidelines
- `SECURITY.md` - Security procedures

## References

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [GitHub Security Best Practices](https://docs.github.com/en/enterprise-cloud@latest/admin/overview/security-best-practices)
- [OWASP Git Security Guidelines](https://owasp.org/www-project-git-security/)

---

**Note**: These rules are designed for the Resilio Load Testing Suite's specific needs as a performance testing toolkit requiring high code quality and reliability. Adjust according to your team's workflow and requirements.