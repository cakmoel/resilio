# AGENTS.md - Resilio Load Testing Suite

This file contains essential information for agentic coding agents working on the Resilio load testing codebase.

## Build/Test/Lint Commands

### Python Components
```bash
# Run Python unit tests
python3 tests/unit/test_stats.py
python3 -m unittest tests.unit.test_stats -v

# Run all Python tests (if pytest available)
python3 -m pytest tests/ -v

# Single test execution
python3 -m unittest tests.unit.test_stats.TestStats.test_calculate_stats
```

### Shell Script Components
```bash
# Run Bats unit tests
bats tests/unit

# Run specific test file
bats tests/unit/test_stats.bats

# Lint shell scripts
make lint
shellcheck -x -e SC2006 bin/dlt.sh lib/*.sh config/dlt.conf
shellcheck -x bin/slt.sh bin/dlt.sh lib/*.sh config/dlt.conf

# Full test suite
make test  # Runs unit tests only
```

### Load Testing Tools
```bash
# Simple Load Testing (SLT)
./bin/slt.sh                    # Default settings
ITERATIONS=500 ./bin/slt.sh     # Custom iterations

# Deep Load Testing (DLT) 
./bin/dlt.sh                    # Research-grade testing
APP_ENV=production ./bin/dlt.sh # Production mode with Git baselines
```

## Code Style Guidelines

### Python Code (lib/stats.py, tests/, visualize_results.py)

**Imports and Structure:**
- Use standard library imports first, then third-party
- Group imports by type with blank lines between groups
- Use absolute imports: `import stats` not `from . import stats`

```python
# Correct import order
import sys
import math
import statistics
import json  # standard library

import pandas as pd  # third-party
import matplotlib.pyplot as plt
```

**Naming Conventions:**
- Functions: `snake_case` with descriptive names
- Variables: `snake_case`, single-letter variables only for math contexts
- Constants: `UPPER_SNAKE_CASE`
- Classes: `PascalCase` for test classes

```python
# Good
def calculate_mean_confidence_interval(values):
    mean_value = statistics.mean(values)
    
# Bad
def calcCI(vals):
    m = stats.mean(vals)
```

**Error Handling:**
- Use specific exceptions, never bare `except:`
- Return early with error indicators for CLI functions
- Log errors to stderr with timestamps
- Use `try/except` blocks around external calls

```python
# Good
try:
    result = statistics.mean(data)
except statistics.StatisticsError:
    return 0, 0, "insufficient_data"
except Exception as e:
    log_error(f"Unexpected error in calculation: {e}")
    return 0, 0, "error"
```

**Type and Value Checking:**
- Validate input parameters at function entry
- Check for minimum data requirements (n >= 2 for variance, n >= 20 for normality)
- Handle edge cases: empty lists, single values, zero variance

**Performance:**
- Use `statistics` module for built-in, optimized calculations
- Implement O(n log n) algorithms for ranking operations
- Avoid unnecessary list copies in large datasets

### Shell Script Code (bin/, lib/, config/)

**Shell Compatibility and Headers:**
- Use `#!/bin/bash` shebang with Bash 4.4+ features
- Include `set -euo pipefail` for strict error handling
- Add ShellCheck directives when needed

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
- Source dependencies in consistent order
- Use relative paths from `BASE_DIR`

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

**Locale and Number Formatting:**
- Force consistent locale for number parsing
- Implement smart locale detection for `bc` compatibility
- Use `LC_NUMERIC=C` for predictable decimal handling

**Configuration:**
- Store test scenarios in associative arrays
- Use environment variables for overrideable settings
- Separate configuration (`config/`) from logic (`lib/`)

### Testing Standards

**Python Tests:**
- Use `unittest` framework for consistency
- Test edge cases: empty data, single values, zero variance
- Verify statistical accuracy with known datasets
- Include performance regression tests for critical paths

```python
class TestStats(unittest.TestCase):
    def setUp(self):
        self.data1 = [1, 2, 3, 4, 5]
        self.data2 = [10, 20, 30, 40, 50]
        self.skewed_data = [1, 1, 1, 1, 100]
    
    def test_calculate_stats(self):
        res = stats.calculate_stats(self.data1)
        self.assertEqual(res[0], 3.0)  # Mean
```

**Shell Tests:**
- Use Bats (Bash Automated Testing System)
- Test both success and failure paths
- Mock external dependencies (`ab`, system calls)
- Verify proper error propagation

### Statistical Mathematics

**Core Functions:**
- All statistical calculations must reference academic standards
- Use Welch's t-test for unequal variances
- Implement Mann-Whitney U for non-parametric comparisons
- Calculate 95% confidence intervals using standard methods

**Data Requirements:**
- Minimum n=2 for variance calculations
- Minimum n=20 for normality testing
- Use D'Agostino's method for skewness/kurtosis analysis
- Automatic test selection based on distribution characteristics

### File Organization

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

### Environment Variables

**SLT Engine:**
- `ITERATIONS` (default: 1000)
- `AB_REQUESTS` (default: 100)
- `AB_CONCURRENCY` (default: 10)
- `AB_TIMEOUT` (default: 30)

**DLT Engine:**
- `APP_ENV` (production/local) - determines baseline storage
- Test scenarios defined in `config/dlt.conf`
- No runtime overrides - uses research-based fixed parameters

### Common Patterns

**Logging:**
```bash
log_error() { echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ERROR_LOG" >&2; }
log_info() { echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${REPORT_DIR}/execution.log"; }
```

**Directory Management:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
mkdir -p "$REPORT_DIR/raw_data"
```

**Data Processing Pipeline:**
1. Collection (ApacheBench execution)
2. Parsing (extract metrics from raw output)
3. Statistical Analysis (Python math engine)
4. Reporting (Markdown with visualizations)
5. Baseline Comparison (Git-tracked when production)

### Performance Considerations

- Python math engine optimized for large datasets
- O(n log n) algorithms for statistical rankings
- Stream processing for ApacheBench output
- Minimal memory footprint for sustained load testing

### Security and Safety

- Never expose secrets in configuration files
- Validate all URLs before testing
- Use timeouts for external network calls
- Proper resource cleanup (background processes, temp files)

This codebase follows research-grade engineering standards with emphasis on statistical accuracy, performance reliability, and maintainability.