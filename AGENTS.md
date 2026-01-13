# AGENTS.md - AI Agent Guide for Resilio Load Testing Suite

This guide provides AI agents with essential information for contributing to the Resilio performance testing toolkit.

## Quick Start Commands

### Essential Development Commands
```bash
# Run full test suite (preferred)
make test

# Run specific test categories
make test-unit              # Bats tests for shell scripts
bats tests/unit            # Alternative to above
bats tests/unit/test_stats.bats  # Run single test file

# Python statistical engine tests
python3 tests/unit/test_stats.py
python3 -m unittest tests.unit.test_stats -v

# Linting (required before PR)
make lint
shellcheck -x -e SC2006 bin/dlt.sh lib/*.sh config/dlt.conf

# Manual system tests (destructive, run with care)
bats tests/system
```

### Running the Application
```bash
# Simple Load Testing (fast, CI/CD focused)
./bin/slt.sh

# Deep Load Testing (research-grade statistics)  
./bin/dlt.sh

# With custom parameters
ITERATIONS=500 AB_CONCURRENCY=20 ./bin/slt.sh
```

## Project Architecture

### Hybrid Language Stack
- **Bash 4.4+** (primary): Core orchestration, parsing, reporting
- **Python 3.10+** (statistical engine): High-performance mathematical calculations
- **External dependencies**: ApacheBench (`ab`), `bc`, GNU coreutils

### Core Components
```
bin/dlt.sh         # Deep Load Testing - research-grade with hypothesis testing
bin/slt.sh         # Simple Load Testing - fast CI/CD integration
lib/               # Core library modules
├── stats.py       # Python statistical engine (O(n log n) algorithms)
├── *.sh           # Bash libraries (parser, runner, report, normality)
config/dlt.conf    # Test scenarios and configuration
tests/             # Dual testing framework (Bats + Python unittest)
```

## Code Style Guidelines

### Bash Script Standards

#### Required Headers
```bash
#!/bin/bash
set -euo pipefail

# shellcheck shell=bash
# shellcheck disable=SC2034  # for unused variables in sourced files
```

#### Import Structure (strict order)
```bash
source "$BASE_DIR/config/dlt.conf"
source "$BASE_DIR/lib/parser.sh"
source "$BASE_DIR/lib/stats.sh"
source "$BASE_DIR/lib/runner.sh"
source "$BASE_DIR/lib/report.sh"
```

#### Naming Conventions
- Functions: `snake_case` with descriptive names
- Variables: `UPPER_SNAKE_CASE` for constants, `snake_case` for locals
- Global variables: `SCENARIOS`, `BASE_DIR`, `APP_ENV`
- Associative arrays: `declare -A SCENARIOS`

#### Error Handling Pattern
```bash
# Network operations must use timeout
if timeout "$AB_TIMEOUT" ab -n "$AB_REQUESTS" -c "$AB_CONCURRENCY" "$url" > "$temp_file" 2>&1; then
    # Success case
else
    log_error "ApacheBench failed for $url"
    return 1
fi

# Logging with timestamps
log_error() { echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ERROR_LOG" >&2; }
log_info() { echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${REPORT_DIR}/execution.log"; }
```

#### Directory Management Pattern
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
mkdir -p "$REPORT_DIR/raw_data"
```

### Python Standards

#### Import Structure
```python
# Standard library imports first
import sys
import math
import statistics
import json

# Third-party imports second
import pandas as pd
import matplotlib.pyplot as plt
```

#### Naming Conventions
- Functions: `snake_case` with descriptive names
- Variables: `snake_case`, single-letter only for mathematical contexts
- Constants: `UPPER_SNAKE_CASE`
- Classes: `PascalCase` (test classes only)

#### Error Handling
```python
try:
    result = statistics.mean(data)
except statistics.StatisticsError:
    return 0, 0, "insufficient_data"
except Exception as e:
    log_error(f"Unexpected error in calculation: {e}")
    return 0, 0, "error"
```

## Statistical Integrity Requirements

### Academic Standards (Non-Negotiable)
All mathematical changes MUST cite academic references:
- **Minimum n=2** for variance calculations
- **Minimum n=20** for normality testing  
- **Welch's t-test** for unequal variances (Jain, 1991; Welch, 1947)
- **Mann-Whitney U** for non-parametric comparisons (Mann & Whitney, 1947)
- **95% confidence intervals** using standard methods
- **D'Agostino's method** for skewness/kurtosis analysis

### Performance Requirements
- Python math engine: O(n log n) algorithms for rankings
- Shell processing: Stream-based parsing for large datasets
- Memory efficiency: Minimal footprint for sustained testing

## Testing Patterns

### Dual Testing Framework

#### Bats Tests (Shell Scripts)
- Location: `tests/unit/*.bats`
- Mock external dependencies in `tests/mock_ab.sh`
- Test helper: `tests/unit/common.bash`
- Standard setup pattern:
```bash
setup() {
  PROJECT_ROOT="$(dirname "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_ROOT
  export BASE_DIR="$PROJECT_ROOT"
  source "${PROJECT_ROOT}/tests/unit/common.bash"
}
```

#### Python Tests (Statistical Engine)
- Location: `tests/unit/test_stats.py`
- Use `unittest` framework
- Test edge cases: empty data, single values, zero variance
- Verify statistical accuracy with known datasets

### Test Data Standards
- Use reproducible datasets for statistical verification
- Include performance regression tests for critical paths
- Mock ApacheBench output for isolated unit testing

## Configuration Management

### Environment Variables
```bash
# SLT Engine (configurable)
ITERATIONS=1000          # Number of test iterations
AB_REQUESTS=100          # Requests per test
AB_CONCURRENCY=10        # Concurrent users
AB_TIMEOUT=30            # Timeout in seconds

# DLT Engine (research-grade, fixed parameters)
APP_ENV=production       # or "local" - determines baseline storage
```

### Test Scenarios
Defined in `config/dlt.conf` using associative arrays:
```bash
declare -A SCENARIOS=(
    ["Homepage"]="http://localhost:8000/"
    ["API_Users"]="http://localhost:8000/api/users"
)
```

## Critical Constraints

### Performance is Paramount
This is a performance testing tool - code efficiency directly affects measurement accuracy. Maintain the 40x speedup achieved in v6.2.

### Backward Compatibility
CLI interfaces must remain 100% compatible. Internal refactoring is allowed, but user-facing behavior cannot change.

### Research-Grade Engineering
Statistical accuracy is more important than code simplicity. Follow academic standards and maintain mathematical integrity.

### Safety Requirements
- Never test production without authorization
- Validate all URLs before testing
- Use timeouts for external network calls
- Proper resource cleanup (background processes, temp files)

## Development Workflow

### Before Submitting Changes
1. `make lint` - All shell scripts must pass ShellCheck
2. `make test` - Full test suite must pass
3. Verify statistical accuracy with known datasets
4. Update documentation for any interface changes
5. Cite academic references for statistical method changes

### Release Process
**Production Releases**: Use GitHub Actions workflow (Actions → Release)
- Requires repository write permissions
- Automated testing and validation
- Secure, permission-based releases
- See `docs/RELEASE_SECURITY.md` for details

**Local Testing Only**: `RELEASE_VERSION=X.Y.Z GITHUB_REPOSITORY=user/repo ./release.sh`
- For development and validation only
- No automated GitHub releases
- Requires environment variables

### Areas Needing Special Care
- Statistical calculations in `lib/stats.py`
- ApacheBench output parsing in `lib/parser.sh`
- Baseline comparison logic
- Timeout and error handling
- Resource cleanup

### Contribution Priorities
1. Statistical accuracy improvements
2. Performance optimizations
3. Additional statistical tests (with academic references)
4. Monitoring tool integrations
5. Visualization enhancements

## File Organization Rules

```
├── bin/           # Executable entry points only
├── lib/           # Core library modules (mixed bash/python)
├── config/        # Configuration files
├── tests/         # Test suites (unit/, system/)
├── docs/          # Documentation
└── experiments/   # Experimental features (not for production)
```

Maintain strict separation between business logic and configuration. Use consistent directory structure across all components.

## Common Pitfalls to Avoid

1. **Breaking statistical accuracy** for performance gains
2. **Changing CLI interfaces** without migration path
3. **Ignoring academic references** for statistical methods
4. **Testing without proper timeouts** - can hang indefinitely
5. **Hardcoding paths** - use `BASE_DIR` pattern consistently
6. **Mixing import order** - follow specified structure
7. **Skipping error handling** - all external calls need try/catch

This codebase maintains research-grade engineering standards. Prioritize statistical accuracy, performance reliability, and backward compatibility in all contributions.