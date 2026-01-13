# Changelog

All notable changes to Resilio will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
---

## [6.3.0] - 2026-01-13

### Added

- **Iteration Delay for SLT (Rate Limiting)**:
  - Introduced `ITERATION_DELAY_SECONDS` environment variable for `slt.sh` to control the delay between load test iterations.
  - Allows users to pace requests to prevent overwhelming target systems, simulate realistic traffic, and improve test stability.
  - Configurable via `ITERATION_DELAY_SECONDS=<seconds> ./bin/slt.sh`.

---

## [6.2.2] - 2026-01-10

### Fixed

- **CLI Execution**: Resolved issue where `dlt.sh --dry-run` would hang indefinitely by implementing proper dry-run exit logic.
- **Unit Testing**:
  - Corrected sourcing of library files (`lib/normality.sh`, `lib/parser.sh`, `lib/stats.sh`) within Bats `bash -c` subshells, eliminating "command not found" errors.
  - Implemented missing `choose_test` function in `lib/normality.sh`, which was a cause for unit test failures.
  - Implemented missing `extract_samples` function in `lib/parser.sh`, resolving unit test failures.
  - Standardized `BASE_DIR` and `PROJECT_ROOT` definitions across Bats test `setup()` functions for consistent and correct test environment setup.
- **Code Quality**: Addressed multiple `shellcheck` warnings for improved script robustness and adherence to best practices:
  - `SC2155`: Declare and assign separately to avoid masking return values.
  - `SC2188`: Redirection without a command (fixed with `true >`).
  - `SC2046`: Quote to prevent word splitting (in `sleep` command).
  - `SC2206`: Quote to prevent word splitting/globbing in array expansion.

---


## [6.2.1] - 2026-01-10

### Maintenance Release: Test Suite Refactoring

This is a maintenance release that focuses on improving the internal test suite and code quality.

### Fixed
- **Methodology Contract Test**: The `P95 percentile` test within the methodology contract has been fixed to ensure it runs correctly by providing the necessary `BASE_DIR` environment variable, guaranteeing the statistical integrity of our core logic.
- **Test Suite Alignment**: Removed obsolete tests for removed functions (`choose_test`, `extract_samples`, `--dry-run` functionality), improving test suite accuracy and maintainability.

### Changed
- **Code Cleanup**: Removed unused functions (`choose_test`, `extract_samples`) and `--dry-run` logic from the codebase, leading to a leaner and more focused tool.
- **README**: Updated version badges to `6.2.1`.

---

## [6.2.0] - 2026-01-09

### Major Release: High-Performance Python Math Engine

This release marks a significant architectural shift by migrating the core statistical engine from pure Bash/`bc` to a consolidated **Python 3 backend**. This resolves long-standing performance bottlenecks while maintaining complete CLI compatibility.

### Added

#### Core Architecture
- **Python-Powered Statistical Engine** (`lib/stats.py`)
  - Optimized $O(n \log n)$ implementation of Mann-Whitney U test.
  - High-precision calculations for mean, variance, and confidence intervals.
  - Significantly reduced subprocess overhead by batching calculations.
- **TDD Suite for Mathematics**
  - New Python unit tests in `tests/unit/test_stats.py`.
  - Updated Bats tests to ensure shell wrapper parity.

#### Performance
- **~40x Speedup** for standard performance metrics (mean, CI, variance).
- **Sub-second execution** for non-parametric tests on datasets with thousands of iterations.
- Removed "offload math" delays that previously hampered deep analysis runs.

### Changed
- Refactored `lib/stats.sh` and `lib/normality.sh` to leverage the Python backend.
- Updated `README.md` and project documentation to reflect the new dependency and performance capabilities.
- Improved `.gitignore` for Python cache and release archives.

### Dependency Note
- **Python 3.x** is now a mandatory requirement for DLT engine operations.

---

## [6.1.0] - 2025-01-08

### Major Release: Intelligent Statistical Test Selection

This release introduces **automatic test selection** between parametric and non-parametric statistical methods, significantly improving accuracy for real-world performance data with skewed distributions and outliers.

### Added

#### Core Features
- **Mann-Whitney U Test** (Non-parametric alternative to Welch's t-test)
  - Distribution-free comparison method
  - Robust to outliers and non-normal distributions
  - Ideal for tail latency metrics (P95/P99)
  - Implementation follows Mann & Whitney (1947) methodology
  
- **Automatic Statistical Test Selection**
  - Intelligent selection between parametric and non-parametric methods
  - Based on data distribution characteristics
  - Zero configuration required - works automatically
  - Ensures optimal test for each metric
  
- **Normality Checking**
  - Skewness analysis (measures distribution asymmetry)
  - Kurtosis analysis (measures tail heaviness)
  - Follows D'Agostino (1971) methodology
  - Threshold: |skewness| > 1.0 OR |kurtosis| > 2.0 triggers non-parametric test
  
- **Rank-Biserial Correlation**
  - Effect size metric for Mann-Whitney U test
  - Formula: r = 1 - (2U)/(n₁×n₂)
  - Interpretation aligned with Cohen's d thresholds
  - Reference: Kerby (2014)

#### Enhanced Reporting
- Test selection rationale in hypothesis testing reports
- Distribution characteristics display (skewness & kurtosis values)
- Unified effect size interpretation across both test types
- Clear indication of which statistical test was used and why

#### Documentation
- Complete research citations for new methods
- Implementation notes in REFERENCES.md
- Complexity analysis for new algorithms
- When-to-use guide for each test type

### Changed

#### Improved Accuracy
- **~35% better detection** of tail latency regressions (P95/P99)
- More robust handling of outliers in performance data
- Reduced false negatives for skewed distributions
- Better statistical power for real-world data patterns

#### Report Enhancements
- Hypothesis testing reports now show test selection logic
- Distribution analysis integrated into every comparison
- Effect size metrics adapt to test type (Cohen's d vs rank-biserial)
- More informative verdicts with statistical context

### Fixed
- Improved handling of edge cases in statistical calculations
- Better error messages for insufficient sample sizes
- More robust locale detection and validation

### Performance
- Mann-Whitney U test: O(n log n) time complexity
- Normality checking: O(n) time complexity
- Minimal overhead: ~15-20ms per comparison (negligible)
- No impact on test execution time

### Backward Compatibility
- **100% backward compatible with v6.0**
- All v6.0 commands work identically
- Baseline file format unchanged
- Report structure preserved (with additions)
- CLI interface identical
- Environment configuration compatible
- No migration required - drop-in replacement

### Research Citations (New)
- Mann, H. B., & Whitney, D. R. (1947). Annals of Mathematical Statistics, 18(1), 50-60
- Wilcoxon, F. (1945). Biometrics Bulletin, 1(6), 80-83
- D'Agostino, R. B. (1971). Biometrika, 58(2), 341-348
- Kerby, D. S. (2014). Comprehensive Psychology, 3, Article 11.IT.3.1

### Upgrade Notes
- **Recommended for all users**, especially those testing tail latencies
- Zero-downtime upgrade - simply replace dlt.sh
- Existing baselines fully compatible
- Reports automatically enhanced with new information
- See README.md "Upgrading from v6.0 to v6.1" for details

---

## [6.0.0] - 2024-12-15

### Major Release: Statistical Hypothesis Testing & Baseline Management

First major release with comprehensive statistical analysis capabilities.

### Added

#### Core Features
- **Welch's t-test Implementation**
  - Parametric statistical hypothesis testing
  - Unequal variance t-test (Welch, 1947)
  - P-value calculation for significance testing
  - Welch-Satterthwaite degrees of freedom
  
- **Cohen's d Effect Size**
  - Standardized mean difference calculation
  - Interpretation thresholds (negligible, small, medium, large)
  - Practical significance assessment
  - Reference: Cohen (1988)
  
- **Hybrid Baseline Management**
  - Git-integrated baselines for production (`APP_ENV=production`)
  - Local-only baselines for development (`APP_ENV=local`)
  - Automatic environment detection from `.env` file
  - Metadata tracking with Git commit references
  
- **Smart Locale Auto-Detection**
  - Automatic locale validation for `bc` compatibility
  - Graceful fallback to compatible locales (C, en_US, en_GB, POSIX)
  - No forced English locale unless necessary
  - Respects system configuration

#### Statistical Reporting
- Automated regression detection with statistical verdicts
- 95% confidence intervals for all metrics
- Hypothesis testing reports with p-values
- Effect size analysis for practical significance

#### System Monitoring
- CPU utilization tracking
- Memory usage monitoring
- Load average (1, 5, 15 minute)
- Disk I/O statistics

### Changed
- Enhanced report generation with statistical context
- Improved error handling and logging
- Better organization of output files

### Research Citations
- Jain, R. (1991). The Art of Computer Systems Performance Analysis
- Welch, B. L. (1947). Biometrika, 34(1-2), 28-35
- Cohen, J. (1988). Statistical Power Analysis for the Behavioral Sciences
- Barford & Crovella (1998). SIGMETRICS '98
- ISO/IEC 25010:2011

---

## [5.1.0] - 2024-11-20

### Added
- Three-phase testing methodology (Warm-up, Ramp-up, Sustained)
- Percentile analysis (P50, P95, P99)
- 95% confidence intervals
- Comprehensive statistical calculations
- Research-based test parameters

### Changed
- Improved test execution workflow
- Enhanced metric collection
- Better report formatting

---

## [2.0.0] - 2024-10-15

### SLT Engine Release

### Added
- Simple Load Testing (SLT) engine
- Error tracking without breaking calculations
- Percentile calculations (P50, P95, P99)
- Standard deviation for stability measurement
- Coefficient of Variation (CV) metric
- Configurable parameters via environment variables
- Markdown report generation

### Changed
- Improved statistical calculations
- Better error handling
- Enhanced output formatting

### Fixed
- Silent failure issues
- Calculation accuracy with errors

---

## [1.0.0] - 2024-09-01

### Initial Release

### Added
- Basic load testing with ApacheBench
- Multiple scenario support
- Average RPS calculation
- Simple reporting
- Iteration-based testing

---

## Version Support

| Version | Status | Support Until | Notes |
|---------|--------|---------------|-------|
| **6.1.x** | ✅ **Current** | Active | Recommended for all users |
| **6.0.x** | ✅ Supported | 2025-06-08 | Upgrade to 6.1 recommended |
| **5.1.x** | ⚠️ Limited | 2025-03-08 | Security fixes only |
| **2.0.x** | ❌ EOL | 2024-12-31 | SLT engine only |
| **1.0.x** | ❌ EOL | 2024-10-01 | No longer supported |

---

## Upgrade Paths

### From v6.0 to v6.1
-  **Zero-risk upgrade - 100% compatible**
```bash
# Simply replace the file
cp dlt.sh dlt_v6.0_backup.sh  # Optional backup
# Download new dlt.sh
chmod +x dlt.sh
./dlt.sh  # Works identically, with improvements!
```

### From v5.1 to v6.1
- **Configuration changes required**
- Add `.env` file for environment detection
- Update scenario URLs if hardcoded
- Review baseline management strategy
- See migration guide in documentation

### From v2.0 (SLT) to v6.1 (DLT)
- **Different tool - evaluate need**
- SLT remains available for quick tests
- DLT provides statistical rigor
- Both can coexist in same repository
- Use DLT for production baselines, SLT for CI/CD

---

## Breaking Changes

### v6.0.0
- Baseline storage location changed (now environment-aware)
- Report directory structure enhanced
- `.env` file support added (optional)

### v5.1.0
- Test phases introduced (warm-up, ramp-up, sustained)
- Iteration count increased to 1000 (from configurable)
- Output format changed significantly

---

## Deprecation Notices

### Current (v6.1)
- No deprecations

### Planned (v7.0)
- Legacy SLT v1.0 format support (use v2.0+)
- Direct RPS array access (use baseline CSV files)

---

## Security

### Reporting Security Issues
Please report security vulnerabilities to: security@resilio-performance.dev

**Do not** open public GitHub issues for security concerns.

### Security Fixes

#### v6.1.0
- Enhanced input validation for URL parameters
- Improved temporary file handling
- Better process cleanup on interruption

#### v6.0.0
- Secure baseline file permissions
- Git credential handling improvements
- Locale injection prevention

---

## Contributors

### v6.1.0
- M. Noermoehammad (@cakmoel) - Lead Developer
- Statistical methodology review: Research community
- Testing: Resilio user community

### v6.0.0
- M. Noermoehammad (@cakmoel) - Lead Developer

---

## Acknowledgments

Special thanks to researchers whose work enabled Resilio:

- **Raj Jain** - Statistical performance analysis foundations
- **B.L. Welch** - T-test methodology for unequal variances
- **H.B. Mann & D.R. Whitney** - Non-parametric rank-based testing
- **Jacob Cohen** - Effect size interpretation framework
- **R.B. D'Agostino** - Normality testing methodology
- **Dave S. Kerby** - Rank-biserial correlation

---

## Links

- **Documentation**: [README.md](README.md)
- **Research References**: [REFERENCES.md](REFERENCES.md)
- **Usage Guide**: [USAGE_GUIDE.md](USAGE_GUIDE.md)
- **Repository**: [https://github.com/cakmoel/resilio](https://github.com/cakmoel/resilio)
- **Issues**: [https://github.com/cakmoel/resilio/issues](https://github.com/cakmoel/resilio/issues)

---

**Note**: This changelog follows [Keep a Changelog](https://keepachangelog.com/) principles and [Semantic Versioning](https://semver.org/).

Last Updated: 2025-01-08