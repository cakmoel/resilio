# Contribution Guidelines

We are excited that you want to contribute to Resilio! To maintain the integrity of our performance metrics and the reliability of our scripts, please follow these guidelines.

## Code Quality Standards

### General Principles
- **Performance is paramount** - This is a performance tool, code efficiency is critical
- **Research-grade engineering** - Follow academic standards for statistical accuracy
- **Backward compatibility** - Maintain CLI interface compatibility
- **Statistical integrity** - All mathematical changes must reference academic standards

### Shell Script Code (bin/, lib/, config/)

**Shell Compatibility and Headers:**
```bash
#!/bin/bash
set -euo pipefail

# shellcheck shell=bash
# shellcheck disable=SC2034  # for unused variables in sourced files
```

**Naming Conventions:**
- Functions: `snake_case` with descriptive names
- Variables: `UPPER_SNAKE_CASE` for constants, `snake_case` for locals
- Global variables: `SCENARIOS`, `BASE_DIR`, `APP_ENV`
- Associative arrays: `declare -A SCENARIOS`

**Import Structure:**
```bash
# Correct source order
source "$BASE_DIR/config/dlt.conf"
source "$BASE_DIR/lib/parser.sh"
source "$BASE_DIR/lib/stats.sh"
source "$BASE_DIR/lib/runner.sh"
source "$BASE_DIR/lib/report.sh"
```

**Error Handling:**
- Use `set -euo pipefail` globally
- Implement proper error logging with timestamps
- Capture command output and check return codes
- Use `timeout` for external commands

```bash
# Good error handling
if timeout "$AB_TIMEOUT" ab -n "$AB_REQUESTS" -c "$AB_CONCURRENCY" "$url" > "$temp_file" 2>&1; then
    # Success case
else
    log_error "ApacheBench failed for $url"
    return 1
fi
```

### Python Code (lib/stats.py, tests/, visualize_results.py)

**Imports and Structure:**
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

**Naming Conventions:**
- Functions: `snake_case` with descriptive names
- Variables: `snake_case`, single-letter variables only for math contexts
- Constants: `UPPER_SNAKE_CASE`
- Classes: `PascalCase` for test classes

**Error Handling:**
```python
# Good error handling
try:
    result = statistics.mean(data)
except statistics.StatisticsError:
    return 0, 0, "insufficient_data"
except Exception as e:
    log_error(f"Unexpected error in calculation: {e}")
    return 0, 0, "error"
```

## Statistical Integrity

### Requirements for Mathematical Changes
If modifying mathematical logic in `lib/stats.py` or statistical functions:
- **Provide academic reference** - Cite the paper or industry standard
- **Include test cases** - Verify accuracy with known datasets
- **Document assumptions** - Explain data requirements and limitations
- **Maintain precision** - Use appropriate numerical methods

### Core Statistical Standards
- **Minimum n=2** for variance calculations
- **Minimum n=20** for normality testing
- **Welch's t-test** for unequal variances (Jain, 1991; Welch, 1947)
- **Mann-Whitney U** for non-parametric comparisons (Mann & Whitney, 1947)
- **95% confidence intervals** using standard methods
- **D'Agostino's method** for skewness/kurtosis analysis

## Testing Standards

### Running Tests
```bash
# Python unit tests
python3 tests/unit/test_stats.py
python3 -m unittest tests.unit.test_stats -v

# Shell script tests (Bats)
bats tests/unit
bats tests/unit/test_stats.bats

# Lint shell scripts
make lint
shellcheck -x -e SC2006 bin/dlt.sh lib/*.sh config/dlt.conf
```

### Python Tests
- Use `unittest` framework for consistency
- Test edge cases: empty data, single values, zero variance
- Verify statistical accuracy with known datasets
- Include performance regression tests for critical paths

### Shell Tests
- Use Bats (Bash Automated Testing System)
- Test both success and failure paths
- Mock external dependencies (`ab`, system calls)
- Verify proper error propagation

## File Organization

```
├── bin/           # Executable entry points (dlt.sh, slt.sh)
├── lib/           # Core library modules (stats.py, parser.sh, etc.)
├── config/        # Configuration files (dlt.conf)
├── tests/         # Test suites (unit/, system/)
└── docs/          # Documentation
```

**Key Principles:**
- Separate business logic from configuration
- Use consistent directory structure across components
- Maintain backward compatibility for CLI interfaces
- Document all statistical methods with academic references

## Common Patterns

### Logging
```bash
log_error() { echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ERROR_LOG" >&2; }
log_info() { echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${REPORT_DIR}/execution.log"; }
```

### Directory Management
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
mkdir -p "$REPORT_DIR/raw_data"
```

## Performance Considerations

- Python math engine optimized for large datasets
- O(n log n) algorithms for statistical rankings
- Stream processing for ApacheBench output
- Minimal memory footprint for sustained load testing

## Environment Variables

### SLT Engine
- `ITERATIONS` (default: 1000)
- `AB_REQUESTS` (default: 100)
- `AB_CONCURRENCY` (default: 10)
- `AB_TIMEOUT` (default: 30)

### DLT Engine
- `APP_ENV` (production/local) - determines baseline storage
- Test scenarios defined in `config/dlt.conf`
- No runtime overrides - uses research-based fixed parameters

## Security and Safety

- Never expose secrets in configuration files
- Validate all URLs before testing
- Use timeouts for external network calls
- Proper resource cleanup (background processes, temp files)

## Process

1. **Fork the repository**
2. **Create a feature branch** with descriptive name
3. **Write tests** for new functionality
4. **Run the test suite** to ensure no regressions:
   ```bash
   make lint
   make test
   ```
5. **Update documentation** including:
   - README.md for new flags or environment variables
   - REFERENCES.md for new statistical methods
6. **Submit a Pull Request** with:
   - Clear description of changes
   - How it affects test accuracy or speed
   - Academic references for statistical changes
   - Test results showing no regressions

## Areas for Contribution

- Multiple comparison correction (Bonferroni/Holm)
- Sequential Probability Ratio Test (SPRT) for early stopping
- Bayesian A/B testing as an alternative approach
- Visualization dashboards for trends
- Integration with monitoring tools (Prometheus, Grafana)
- Additional statistical tests and distributions
- Performance optimizations for large-scale testing

This codebase follows research-grade engineering standards with emphasis on statistical accuracy, performance reliability, and maintainability.