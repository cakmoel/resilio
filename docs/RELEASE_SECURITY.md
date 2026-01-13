# Security-Hardened Release Process

## Overview

Resilio now uses a two-tier release system for enhanced security:
1. **GitHub Actions Workflow** - Production releases (recommended)
2. **Local Release Helper** - Development testing only

## Production Releases (GitHub Actions)

### Prerequisites
- Must be on `main` branch
- Clean working tree
- Write permissions to repository
- All tests passing

### Steps
1. Go to **Actions** → **Release** workflow
2. Click **Run workflow**
3. Enter version (e.g., `6.3.0`)
4. Type `release` to confirm
5. Workflow automatically:
   - Runs full test suite
   - Creates Git tag
   - Builds release archives
   - Creates GitHub release

### Security Features
- **Permission-based**: Only users with write permissions can trigger
- **Manual confirmation**: Requires explicit approval code
- **Branch protection**: Only works from `main` branch
- **Clean workspace**: Requires clean working tree
- **Automated testing**: Full validation before release

## Local Development Only

### When to Use
- Testing release process locally
- Validating archives before production
- Development environment setup

### Usage
```bash
export RELEASE_VERSION=6.3.0
export GITHUB_REPOSITORY=cakmoel/resilio
../resilio-private-tools/release.sh
```

### Security Limitations
- No automated GitHub releases
- Requires manual upload of archives
- Explicit confirmation for local use only
- Environment variable validation

## Security Improvements Made

### Before (Security Risks)
- ❌ Hardcoded repository path
- ❌ No authentication validation
- ❌ Anyone could trigger releases
- ❌ Automated releases without approval

### After (Secure)
- ✅ Environment variable validation
- ✅ GitHub Actions permission control
- ✅ Manual confirmation requirements
- ✅ Branch protection enforcement
- ✅ Clean workspace validation
- ✅ Separate development/production workflows

## Migration Guide

### For Production Releases
1. **Stop using**: `../resilio-private-tools/release.sh` for production
2. **Start using**: GitHub Actions Release workflow
3. **Benefits**: 
   - Automated testing validation
   - Secure permission control
   - Audit trail and logging
   - No local CLI dependencies

### For Local Testing
1. **Set environment variables**:
   ```bash
   export RELEASE_VERSION=6.3.0
   export GITHUB_REPOSITORY=yourusername/resilio
   ```
2. **Run local helper**:
   ```bash
   ../resilio-private-tools/release.sh
   ```
3. **Manual upload**: Upload created archives to GitHub

## File Structure

```
.github/workflows/
├── ci.yml          # CI/CD pipeline
└── release.yml     # Secure production releases

../resilio-private-tools/
├── release.sh              # Private local development helper
├── cleanup-workflows.sh     # GitHub Actions maintenance tool
├── AGENTS.md               # Internal development documentation  
└── README.md               # Security documentation
```

## Internal Development

For internal development commands, AI agent guidance, and detailed setup:
See `../resilio-private-tools/AGENTS.md` (private documentation)

## Best Practices

1. **Always use GitHub Actions** for production releases
2. **Keep working tree clean** before any release
3. **Validate version format** (X.Y.Z)
4. **Use semantic versioning** consistently
5. **Test locally first** with the helper script
6. **Review release notes** before publishing

## Security Checklist

Before any release:
- [ ] On `main` branch
- [ ] Working tree is clean
- [ ] All tests passing (`make test`)
- [ ] Version format validated (X.Y.Z)
- [ ] Release notes updated
- [ ] Documentation current

For production releases:
- [ ] Using GitHub Actions workflow
- [ ] Have repository write permissions
- [ ] Manual confirmation code provided
- [ ] Archives validated locally first

This security-hardened approach maintains the project's research-grade standards while protecting against unauthorized releases and ensuring proper validation.