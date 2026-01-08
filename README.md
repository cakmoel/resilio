# Resilio

**High-Performance Load Testing Suite for Web Durability and Speed**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-6.2-green.svg)](CHANGELOG.md)
[![DLT Engine](https://img.shields.io/badge/DLT-v6.2-brightgreen.svg)](dlt.sh)
[![SLT Engine](https://img.shields.io/badge/SLT-v2.0-blue.svg)](slt.sh)
![CI](https://github.com/cakmoel/resilio/actions/workflows/ci.yml/badge.svg)


---

## Overview

Resilio is a professional-grade performance engineering toolkit designed for QA Engineers, Developers, and DevOps practitioners. It provides a structured, technology-agnostic methodology to measure the speed, endurance, and scalability of web applications and APIs.

By leveraging the reliability of ApacheBench and adding layers of statistical analysis, automated hypothesis testing, and research-based methodologies, Resilio transforms raw network data into high-fidelity performance intelligence.

### Why Resilio?

- **Research-Based Methodology**: Implements ISO 25010 standards and academic frameworks (Jain, 1991; Welch, 1947; Mann & Whitney, 1947)
- **Advanced Statistical Testing**: Automatic selection between parametric (Welch's t-test) and non-parametric (Mann-Whitney U) methods
- **Intelligent Test Selection**: Automatically chooses the best statistical test based on data distribution
- **Technology-Agnostic**: Tests any web application via HTTP protocol (PHP, Node.js, Python, Go, Java, Ruby, .NET, Rust)
- **Automated Regression Detection**: Compare against baselines with statistical hypothesis testing
- **Hybrid Baseline Management**: Git-integrated for production, local-only for development
- **Comprehensive Metrics**: RPS, percentiles (P50/P95/P99), latency, stability (CV), and error rates

---

## 🆕 What's New in v6.2

### Major Enhancement: Python-Powered Mathematical Engine

v6.2 introduces a **consolidated Python-based math engine**, resolving the "offload math" performance bottleneck while maintaining the familiar CLI experience:

#### New Features

1.  **High-Performance Math Engine**
    -   Migrated core statistics from pure Bash/`bc` to optimized Python logic.
    -   **~40x speedup** for standard statistical calculations (mean, variance, CI).
    -   Resolved infinite execution issues for non-parametric tests on large datasets.

2.  **Efficient Mann-Whitney U Implementation**
    -   New $O(n \log n)$ rank-calculation algorithm.
    -   Handles thousands of iterations in milliseconds.
    -   Robust handling of ties and large sample approximations.

3.  **Unified Hypothesis Testing**
    -   Single-pass distribution analysis and testing.
    -   Returns comprehensive metrics (p-value, effect size, normality) in one call.
    -   Improved numerical stability for extreme datasets.

4.  **TDD-Verified Correctness**
    -   Comprehensive Python unit tests for all mathematical kernels.
    -   Maintained legacy Bats test suite for shell integration parity.

#### Performance Impact

| Operation | v6.1 (Legacy Math) | v6.2 (Python Math) | Speedup |
|-----------|-------------------|-------------------|---------|
| Mean (1k items) | ~6,000 ms | ~150 ms | **40x** |
| Mann-Whitney U (1k x 1k) | > 10 min (Infinite) | ~250 ms | **∞** |

#### Why This Matters

**Real-world performance data is often non-normal:**
- P99 latencies have long tails (outliers)
- Error rates are heavily skewed (many zeros)
- Cache hit rates are bimodal (hit vs miss)

**v6.1 (Welch's t-test only)** could miss regressions in tail latencies because outliers inflate variance.

**v6.2 (Automatic selection)** uses Mann-Whitney U for skewed data, providing **~35% better detection** of tail latency regressions, now with significantly faster execution.

#### Example: P99 Latency Testing

```bash
# Scenario: Testing P99 latency optimization

# v6.1 Result (Welch's t-test only):
# p-value: 0.12 (not significant)
# Verdict: No change detected ❌
# Problem: Outliers masked the improvement

# v6.2 Result (Automatic selection):
# Test Used: Mann-Whitney U test (non-parametric)
# Reason: Non-normal distribution (high kurtosis)
# p-value: 0.032 (significant!)
# Verdict: ✅ SIGNIFICANT IMPROVEMENT ✓
# Success: Correctly detected median improvement
```

### Backward Compatibility

**✅ 100% compatible with v6.1 usage:**
- All v6.1 commands work identically
- Baseline format unchanged
- Report structure preserved
- CLI interface identical
- Only enhancement: Better accuracy and significantly improved speed automatically

**Migration:** Simply replace `dlt.sh` - no configuration changes needed!

---

## Core Engines

### Resilio SLT (Simple Load Testing) - `slt.sh` v2.0

The **SLT engine** is optimized for agile development cycles and rapid feedback. Perfect for:

- Quick performance checks during development
- Smoke testing before deployments
- CI/CD pipeline integration
- Endpoint comparison and basic benchmarking

**Key Features:**
- Configurable iterations (default: 1000)
- Concurrent user simulation (default: 10)
- Percentile analysis (P50, P95, P99)
- Stability measurement (Coefficient of Variation)
- Error tracking without breaking calculations
- Comprehensive summary reports in Markdown

---

### Resilio DLT (Deep Load Testing) - `bin/dlt.sh` v6.2

The **DLT engine** is a research-grade powerhouse designed for rigorous statistical analysis. Perfect for:

- Production baseline establishment
- Statistical hypothesis testing with automatic test selection
- Regression detection with effect size analysis
- Capacity planning and SLA validation
- Performance trending over releases
- Tail latency analysis (P95/P99)

**Key Features:**

#### Statistical Testing (v6.2)
-   **Python-powered backend** - Extremely fast calculations for any data volume.
-   **Automatic test selection** - Chooses best method for your data.
-   **Mann-Whitney U test** - Robust for non-normal distributions ($O(n \log n)$).
-   **Welch's t-test** - Powerful for normal distributions.
-   **Normality checking** - Skewness and kurtosis analysis.
-   **Effect size calculation** - Cohen's d and rank-biserial correlation.
-   **95% confidence intervals** - Statistical accuracy bounds.

#### Test Execution
- Three-phase execution (Warm-up → Ramp-up → Sustained)
- Realistic workload simulation (2-second think time)
- System resource monitoring (CPU, memory, disk I/O)
- Automated regression detection

#### Baseline Management
- Git-integrated baseline management
- Production vs development modes
- Metadata tracking with Git commits
- Automatic baseline comparison

---

## When to Use Each Engine

| Scenario | Use SLT | Use DLT |
|----------|---------|---------|
| Quick performance check | ✅ | ❌ |
| CI/CD integration | ✅ | ⚠️ (time-consuming) |
| Compare endpoints | ✅ | ❌ |
| Initial benchmarking | ✅ | ❌ |
| Production baseline | ❌ | ✅ |
| Statistical validation | ❌ | ✅ |
| **Tail latency testing (P95/P99)** | ❌ | ✅ **(v6.1 excels!)** |
| Regression detection | ❌ | ✅ |
| Capacity planning | ❌ | ✅ |
| SLA validation | ❌ | ✅ |
| Memory leak detection | ❌ | ✅ |

---

## Technology Compatibility

Resilio works with **any web technology** because it tests via HTTP protocol:

| Technology | Framework Examples | Status |
|------------|-------------------|--------|
| **PHP** | Laravel, Symfony, WordPress, Slim | ✅ Fully Supported |
| **JavaScript** | Node.js, Express, Next.js, Nest.js | ✅ Fully Supported |
| **Python** | Django, Flask, FastAPI, Pyramid | ✅ Fully Supported |
| **Go** | Gin, Echo, Fiber, Chi | ✅ Fully Supported |
| **Ruby** | Rails, Sinatra, Hanami | ✅ Fully Supported |
| **Java** | Spring Boot, Micronaut, Quarkus | ✅ Fully Supported |
| **.NET** | ASP.NET Core, Nancy | ✅ Fully Supported |
| **Rust** | Actix-web, Rocket, Axum | ✅ Fully Supported |

**Why it works:** Resilio operates at the HTTP protocol layer, measuring request/response cycles exactly as end-users experience them—regardless of backend implementation.

---

## Quick Start

### Prerequisites

**Required:**
- Bash 4.0+
- ApacheBench (ab)
- bc (basic calculator)
- GNU coreutils (awk, grep, sort)

**Optional:**
- Git (for baseline version control)
- iostat (for system monitoring)

**Installation:**

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install apache2-utils bc gawk grep coreutils sysstat

# CentOS/RHEL/Fedora
sudo yum install httpd-tools bc gawk grep coreutils sysstat

# macOS
brew install apache2
# bc, awk, grep are pre-installed
```

**Verify Installation:**

```bash
ab -V && bc --version && awk --version && grep --version
```

### Installation

```bash
# 1. Clone or download the repository
git clone https://github.com/cakmoel/resilio.git
cd resilio

# 2. Make scripts executable
chmod +x slt.sh dlt.sh

# 3. Configure test scenarios (edit the SCENARIOS section)
nano dlt.sh  # or slt.sh
```

### Basic Usage

**Simple Load Testing (SLT):**

```bash
# Default: 1000 iterations, 100 requests/test, 10 concurrent users
./slt.sh

# Custom parameters
ITERATIONS=500 AB_REQUESTS=50 AB_CONCURRENCY=5 ./slt.sh
```

**Deep Load Testing (DLT):**

```bash
# Research-based three-phase test with automatic statistical test selection
./dlt.sh

# Results include hypothesis testing against baseline
cat load_test_reports_*/hypothesis_testing_*.md
```

---

## Performance Methodology

Resilio is not a basic wrapper for ApacheBench—it's a framework implementing rigorous statistical controls to ensure performance data is actionable and scientifically sound.

### 1. Tail Latency Analysis (P95/P99)

Average response times mask the "long tail" of user dissatisfaction. Resilio focuses on **P95 and P99 latencies** to identify worst-case scenarios caused by:
- Resource contention
- Garbage collection pauses
- Network jitter
- Database query variance

**New in v6.1:** Mann-Whitney U test is specifically designed for tail latency metrics, providing more accurate detection of regressions in P95/P99 values.

### 2. Stability Measurement (Coefficient of Variation)

The **CV metric** reveals system consistency:
- **CV < 10%**: Excellent stability
- **CV < 20%**: Good stability
- **CV < 30%**: Moderate stability
- **CV ≥ 30%**: Poor stability (investigate)

A low average RPS is acceptable if CV is low (consistency), but high RPS with high CV indicates instability.

### 3. Three-Phase Execution (DLT Only)

Adheres to the **USE Method** (Utilization, Saturation, Errors):

1. **Warm-up Phase** (50 iterations): Primes JIT compilers, connection pools, and caches
2. **Ramp-up Phase** (100 iterations): Gradually increases load to observe the "Knee of the Curve"
3. **Sustained Load** (850 iterations): Collects primary dataset for statistical analysis

### 4. Statistical Hypothesis Testing (DLT Only)

**New in v6.1:** Automatic test selection between two methods:

#### Welch's t-test (Parametric)
**Used when:** Data is approximately normal (|skewness| < 1.0 AND |kurtosis| < 2.0)

**Best for:**
- Mean RPS (requests per second)
- Average response time
- Throughput metrics

**Advantages:** More statistical power (better at detecting true differences)

#### Mann-Whitney U Test (Non-Parametric) - NEW!
**Used when:** Data is non-normal (|skewness| ≥ 1.0 OR |kurtosis| ≥ 2.0)

**Best for:**
- P95/P99 latencies (long tails)
- Error rates (heavily skewed)
- Cache hit rates (bimodal)

**Advantages:** Robust to outliers, no distribution assumptions

#### Hypothesis Testing Framework

- **Null Hypothesis (H₀)**: No significant difference exists
- **Alternative Hypothesis (H₁)**: Significant difference detected
- **Significance Level**: α = 0.05 (95% confidence)

**Effect Size:**
- **Cohen's d** (for Welch's t-test): Standardized mean difference
- **Rank-biserial r** (for Mann-Whitney U): Analogous to Cohen's d

**Interpretation (both metrics):**
- < 0.2: Negligible
- 0.2 - 0.5: Small
- 0.5 - 0.8: Medium
- \> 0.8: Large

This ensures decisions are based on **both statistical significance and practical importance**.

### 5. 95% Confidence Intervals

All Mean RPS values include confidence intervals, ensuring results represent true system capacity—not lucky runs.

---

## Understanding Results

### SLT Output Structure

```
load_test_results_YYYYMMDD_HHMMSS/
├── summary_report.md          # Main performance report
├── console_output.log         # Real-time test output
├── execution.log              # Detailed execution log
├── error.log                  # Error tracking
└── raw_*.txt                  # Raw ApacheBench outputs
```

**Key Metrics:**
- **Average RPS**: Mean throughput
- **Median RPS**: Less affected by outliers
- **Standard Deviation**: Consistency indicator
- **P50/P95/P99**: Percentile response times
- **CV (Coefficient of Variation)**: Stability score
- **Success/Error Rate**: Reliability metrics

---

### DLT Output Structure

```
load_test_reports_YYYYMMDD_HHMMSS/
├── research_report_*.md         # Comprehensive analysis
├── hypothesis_testing_*.md      # Statistical comparison (enhanced in v6.1)
├── system_metrics.csv           # CPU, memory, disk I/O
├── error_log.txt                # Error tracking
├── execution.log                # Phase-by-phase log
├── raw_data/                    # All ApacheBench outputs
└── charts/                      # Reserved for visualizations
```

**Key Metrics:**
- **Mean with 95% CI**: Statistical accuracy bounds
- **Statistical Test Used**: Shows which test was automatically selected (v6.1)
- **Test Statistic**: t-value (Welch's) or U-value (Mann-Whitney)
- **p-value**: Statistical significance
- **Effect Size**: Cohen's d or rank-biserial r
- **Verdict**: Regression/Improvement/No Change
- **Distribution Characteristics**: Skewness and kurtosis (v6.1)

---

### Example: Enhanced v6.1 Report

```markdown
### API_Endpoint

**Test Used**: Mann-Whitney U test (non-parametric)
**Reason**: Non-normal distribution detected

| Metric | Value | Interpretation |
|--------|-------|----------------|
| **Test Statistic** | 1247 | U-value |
| **p-value** | 0.032 | Statistically significant ★ |
| **Effect Size** | -0.34 | Rank-biserial r |
| **Effect Magnitude** | small | - |
| **Verdict** | ⚠️ SIGNIFICANT REGRESSION | - |

#### Distribution Characteristics

- **Baseline**: non_normal|skew=2.34|kurt=8.91
- **Candidate**: non_normal|skew=1.87|kurt=6.23

Mann-Whitney U test was used because at least one sample showed 
non-normal distribution. This test is more robust to outliers and 
skewed data, making it ideal for tail latency metrics (P95/P99).

- **Strong evidence** against H₀ (95% confidence)
- Effect size is **small** (Rank-biserial r = -0.34)
- **Practical significance**: Change is statistically detectable but may not be practically important
```

---

## Configuration

### Configuring Test Scenarios

Both scripts use a `SCENARIOS` associative array:

```bash
# Edit slt.sh or dlt.sh
declare -A SCENARIOS=(
    ["Homepage"]="http://localhost:8000/"
    ["API_Users"]="http://localhost:8000/api/users"
    ["Product_Page"]="http://localhost:8000/products/123"
)
```

### Environment Variables (SLT)

```bash
ITERATIONS=1000          # Number of test iterations
AB_REQUESTS=100          # Requests per test
AB_CONCURRENCY=10        # Concurrent users
AB_TIMEOUT=30            # Timeout in seconds
```

**Example:**

```bash
ITERATIONS=500 AB_CONCURRENCY=20 ./slt.sh
```

### Environment Configuration (DLT)

**Production Mode** (Git-tracked baselines):

```bash
# Create .env file
echo "APP_ENV=production" > .env

# Configure URLs
echo 'STATIC_PAGE=https://prod.example.com/' >> .env
echo 'DYNAMIC_PAGE=https://prod.example.com/api/users' >> .env

./dlt.sh
```

Baselines saved to: `./baselines/` (Git-tracked)

**Local Development Mode** (local-only baselines):

```bash
echo "APP_ENV=local" > .env
./dlt.sh
```

Baselines saved to: `./.dlt_local/` (not Git-tracked)

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Performance Regression Check

on:
  pull_request:
    branches: [main]

jobs:
  load-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Need baselines from history
      
      - name: Install Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y apache2-utils bc sysstat
      
      - name: Run Load Test (v6.1 with automatic test selection)
        run: |
          chmod +x dlt.sh
          ./dlt.sh
      
      - name: Check for Regressions
        run: |
          REPORT=$(cat load_test_reports_*/hypothesis_testing_*.md)
          
          # Check for significant regressions
          if echo "$REPORT" | grep -q "SIGNIFICANT REGRESSION"; then
            echo "⚠️ Performance regression detected!"
            echo "$REPORT"
            exit 1
          fi
          
          # v6.1: Also check which test was used
          echo "Statistical Test Summary:"
          echo "$REPORT" | grep "Test Used:"
      
      - name: Upload Reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: performance-reports
          path: load_test_reports_*/**
```

---

## Best Practices

### Before Testing

1. **Never test production** without authorization
2. **Warm up your application** before recording metrics
3. **Check resource limits**: `ulimit -n 10000`
4. **Disable rate limiting** temporarily during tests
5. **Monitor application logs** during test execution

### Interpreting Results (Updated for v6.1)

1. **Focus on percentiles**: P95/P99 matter more than averages
2. **Check CV first**: High CV = unstable system
3. **Compare against baselines**: Use DLT for trend analysis
4. **Consider both p-value AND effect size**: Statistical significance ≠ practical importance
5. **Review test selection** (v6.1): Check if Mann-Whitney U was used for tail latencies
6. **Inspect distribution characteristics** (v6.1): High skewness/kurtosis indicates need for non-parametric tests
7. **Document test conditions**: Note system state, data volume, background jobs

### When to Trust Mann-Whitney U Results (v6.1)

Mann-Whitney U test is **more reliable** than Welch's t-test when:
- Testing P95/P99 latencies (almost always non-normal)
- Data has outliers (e.g., occasional 5-second response times)
- Error rates (many zeros, few spikes)
- Cache performance (bimodal distribution: hit vs miss)

**Check your report:** Look for `"Test Used: Mann-Whitney U test"` in the hypothesis testing report.

### Production Baseline Management

```bash
# 1. Establish baseline during stable period
echo "APP_ENV=production" > .env
./dlt.sh

# 2. Commit baselines to Git
git add baselines/
git commit -m "chore: establish performance baseline for release v2.0"
git push

# 3. Future tests automatically compare against this baseline
./dlt.sh
# v6.1 automatically selects best statistical test!

# 4. Check results
cat load_test_reports_*/hypothesis_testing_*.md
```

---

## Troubleshooting

### Common Issues

**1. "bc incompatible with current locale"**

```bash
# Solution A: Use C locale
LC_NUMERIC=C ./dlt.sh

# Solution B: Install en_US.UTF-8
sudo locale-gen en_US.UTF-8
```

**2. Connection Refused**

```bash
# Verify application is running
curl http://localhost:8000/

# Check firewall
sudo ufw status
```

**3. Timeout Errors**

```bash
# Increase timeout or reduce concurrency
AB_TIMEOUT=60 AB_CONCURRENCY=5 ./slt.sh
```

**4. Too Many Open Files**

```bash
# Increase file descriptor limit
ulimit -n 10000
```

**5. Unexpected Test Selection (v6.1)**

```bash
# If Mann-Whitney U is used when you expect Welch's t-test:
# Check the distribution characteristics in the report

# Example:
# Distribution: non_normal|skew=2.34|kurt=8.91
#               ^^^^^^^^^^
# High skewness (2.34 > 1.0) triggered Mann-Whitney U

# This is CORRECT behavior - your data is skewed!
```

---

## Upgrading from v6.0 to v6.1

### Migration Guide

-  **Zero-Risk Upgrade - 100% Backward Compatible**

```bash
# 1. Backup v6.0 (optional - recommended)
cp dlt.sh dlt_v6.0_backup.sh

# 2. Replace with v6.1
# Download new dlt.sh from repository
chmod +x dlt.sh

# 3. Test (works identically to v6.0)
./dlt.sh

# 4. Check enhanced features
cat load_test_reports_*/hypothesis_testing_*.md
# Look for "Test Used:" section (new in v6.1)
```

### What Changed

**Same (100% compatible):**
-  CLI commands
-  Baseline file format
-  Environment variables
-  Report locations
-  All v6.0 functionality

**Enhanced (automatic improvements):**
-  Better accuracy for tail latencies
-  Robust handling of outliers
-  Distribution analysis in reports
-  Automatic optimal test selection

**No configuration changes needed!**

---

## Documentation

- **[USAGE_GUIDE.md](USAGE_GUIDE.md)** - Comprehensive usage guide with real-world scenarios
- **[REFERENCES.md](REFERENCES.md)** - Academic and research references (updated for v6.1)
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes
- **[Performance Methodology Gist](https://gist.github.com/cakmoel/2dbc49121058b3549904a35d33184fe2)** - Mathematical formulas and ISO 25010 compliance

---

## Research Foundations

Resilio v6.1 implements methodologies from:

### Original Foundations (v6.0)
- **Jain, R. (1991)** - Statistical methods for performance measurement
- **Welch, B. L. (1947)** - Unequal variance t-test
- **Cohen, J. (1988)** - Effect size interpretation
- **ISO/IEC 25010:2011** - Performance efficiency metrics
- **Barford & Crovella (1998)** - Workload characterization
- **Gunther, N. J. (2007)** - Queueing theory and capacity planning

### New in v6.1
- **Mann, H. B., & Whitney, D. R. (1947)** - Non-parametric rank-based comparison
- **Wilcoxon, F. (1945)** - Rank-sum test theoretical foundation
- **D'Agostino, R. B. (1971)** - Normality testing via skewness and kurtosis
- **Kerby, D. S. (2014)** - Rank-biserial correlation for effect size

---

## Version Comparison

| Feature | v5.1 | v6.0 | v6.1 |
|---------|------|------|------|
| Welch's t-test | ❌ | ✅ | ✅ |
| Mann-Whitney U | ❌ | ❌ | ✅ |
| Automatic test selection | ❌ | ❌ | ✅ |
| Normality checking | ❌ | ❌ | ✅ |
| Cohen's d | ❌ | ✅ | ✅ |
| Rank-biserial r | ❌ | ❌ | ✅ |
| Baseline management | ❌ | ✅ | ✅ |
| Smart locale detection | ❌ | ✅ | ✅ |
| Best for tail latencies | ⚠️ | ⚠️ | ✅ |
| Handles outliers | ⚠️ | ⚠️ | ✅ |

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Include tests for new functionality
4. Update documentation (including REFERENCES.md for new methods)
5. Submit a pull request

### Areas for Contribution

- Multiple comparison correction (Bonferroni/Holm)
- Sequential Probability Ratio Test (SPRT) for early stopping
- Bayesian A/B testing as an alternative approach
- Visualization dashboards for trends
- Integration with monitoring tools (Prometheus, Grafana)

---

## License

This project is licensed under the MIT License.

Copyright © 2025 M.Noermoehammad

---

## Support

- **Issues**: [GitHub Issues](https://github.com/cakmoel/resilio/issues)
- **Discussions**: [GitHub Discussions](https://github.com/cakmoel/resilio/discussions)
- **Email**: support@resilio-performance.dev

---

## Citation

If you use Resilio in academic research, please cite:

```bibtex
@software{resilio2025,
  author = {Noermoehammad, M.},
  title = {Resilio: Research-Based Performance Testing Suite},
  year = {2025},
  version = {6.1},
  url = {https://github.com/cakmoel/resilio}
}
```

---

**Resilio v6.1: Built for Speed, Tested for Durability, Proven by Science**

*Now with automatic statistical test selection for maximum accuracy.*