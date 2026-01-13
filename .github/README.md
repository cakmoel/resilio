# GitHub Configuration

This directory contains GitHub-specific configuration files for the Resilio Load Testing Suite.

## Files Overview

### Workflows (`.github/workflows/`)
- **`ci.yml`** - Continuous Integration (tests + linting)
- **`release.yml`** - Automated release process  
- **`branch-protection.yml`** - Manual branch protection setup

### Scripts (`.github/`)
- **`apply-branch-protection.sh`** - Apply branch protection rules
- **`check-protection.sh`** - Verify current protection status

### Configuration
- **`CODEOWNERS`** - Defines code ownership for PR reviews
- **`branch-protection.md`** - Detailed branch protection documentation

## Quick Start

### 1. Apply Branch Protection
```bash
# Apply to current repository
./.github/apply-branch-protection.sh

# Apply to specific repository  
./.github/apply-branch-protection.sh owner repo-name
```

### 2. Check Protection Status
```bash
# Check current repository
./.github/check-protection.sh

# Check specific repository
./.github/check-protection.sh owner/repo-name
```

### 3. Manual Setup (GitHub UI)
1. Go to repository Settings → Branches
2. Click "Add rule" for `main` branch
3. Configure as documented in `branch-protection.md`

## Security Features

- ✅ **Admin enforcement** - No bypass for administrators
- ✅ **Required CI** - All tests and linting must pass
- ✅ **PR reviews** - Code review required for all changes
- ✅ **Linear history** - Clean, readable commit history
- ✅ **Protected main** - Prevents accidental overwrites

## Emergency Procedures

See `branch-protection.md` for:
- Temporary disable procedures (emergency only)
- Admin bypass guidelines
- Recovery procedures

## Maintenance

- Monthly audit of protection rules
- Monitor CI health and reliability
- Update rules as team evolves
- Review CODEOWNERS file quarterly