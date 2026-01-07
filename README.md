# Resilio

**High-Performance Load Testing Suite for Web Durability and Speed**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-6.0-green.svg)](CHANGELOG.md)

---

## Overview

Resilio is a professional-grade performance engineering toolkit designed for QA Engineers, Developers, and DevOps practitioners. It provides a structured, technology-agnostic methodology to measure the speed, endurance, and scalability of web applications and APIs.

By leveraging the reliability of ApacheBench and adding layers of statistical analysis, automated hypothesis testing, and research-based methodologies, Resilio transforms raw network data into high-fidelity performance intelligence.

### Why Resilio?

- **Research-Based Methodology**: Implements ISO 25010 standards and academic frameworks (Jain, 1991; Welch, 1947)
- **Statistical Rigor**: Welch's t-test, Cohen's d effect size, and 95% confidence intervals
- **Technology-Agnostic**: Tests any web application via HTTP protocol (PHP, Node.js, Python, Go, Java, Ruby, .NET, Rust)
- **Automated Regression Detection**: Compare against baselines with statistical hypothesis testing
- **Hybrid Baseline Management**: Git-integrated for production, local-only for development
- **Comprehensive Metrics**: RPS, percentiles (P50/P95/P99), latency, stability (CV), and error rates

---

## Core Engines

### Resilio SLT (Simple Load Testing) - `slt.sh`

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

### Resilio DLT (Deep Load Testing) - `dlt.sh`

The **DLT engine** is a research-grade powerhouse designed for rigorous statistical analysis. Perfect for:

- Production baseline establishment
- Statistical hypothesis testing (Welch's t-test)
- Regression detection with effect size analysis
- Capacity planning and SLA validation
- Performance trending over releases

**Key Features:**
- Three-phase execution (Warm-up → Ramp-up → Sustained)
- Welch's t-test for comparing performance
- Cohen's d effect size calculation
- 95% confidence intervals
- Automated regression detection
- Git-integrated baseline management
- System resource monitoring (CPU, memory, disk I/O)

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
git clone https://github.com/yourusername/resilio.git
cd resilio

# 2. Make scripts executable
chmod +x slt.sh dlt.sh

# 3. Configure test scenarios (edit the SCENARIOS section)
nano slt.sh  # or dlt.sh
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
# Research-based three-phase test
./dlt.sh

# Results include hypothesis testing against baseline
cat load_test_reports_*/hypothesis_testing_*.md
```

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

## Performance Methodology

Resilio is not a basic wrapper for ApacheBench—it's a framework implementing rigorous statistical controls to ensure performance data is actionable and scientifically sound.

### 1. Tail Latency Analysis (P95/P99)

Average response times mask the "long tail" of user dissatisfaction. Resilio focuses on **P95 and P99 latencies** to identify worst-case scenarios caused by:
- Resource contention
- Garbage collection pauses
- Network jitter
- Database query variance

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

DLT implements **Welch's t-test** to compare current performance against baselines:

- **Null Hypothesis (H₀)**: No significant difference exists
- **Alternative Hypothesis (H₁)**: Significant difference detected
- **Significance Level**: α = 0.05 (95% confidence)

**Effect Size (Cohen's d):**
- d < 0.2: Negligible
- d ≈ 0.5: Medium
- d > 0.8: Large

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

### DLT Output Structure

```
load_test_reports_YYYYMMDD_HHMMSS/
├── research_report_*.md         # Comprehensive analysis
├── hypothesis_testing_*.md      # Statistical comparison
├── system_metrics.csv           # CPU, memory, disk I/O
├── error_log.txt                # Error tracking
├── execution.log                # Phase-by-phase log
├── raw_data/                    # All ApacheBench outputs
└── charts/                      # Reserved for visualizations
```

**Key Metrics:**
- **Mean with 95% CI**: Statistical accuracy bounds
- **Welch's t-test**: p-value for significance
- **Cohen's d**: Practical effect size
- **Verdict**: Regression/Improvement/No Change
- **Connection vs Processing Time**: Bottleneck identification

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
      
      - name: Run Load Test
        run: |
          chmod +x dlt.sh
          ./dlt.sh
      
      - name: Check for Regressions
        run: |
          if grep -q "REGRESSION" load_test_reports_*/hypothesis_testing_*.md; then
            echo "Performance regression detected!"
            exit 1
          fi
      
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

### Interpreting Results

1. **Focus on percentiles**: P95/P99 matter more than averages
2. **Check CV first**: High CV = unstable system
3. **Compare against baselines**: Use DLT for trend analysis
4. **Consider both p-value and effect size**: Statistical significance ≠ practical importance
5. **Document test conditions**: Note system state, data volume, background jobs

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
# Check: load_test_reports_*/hypothesis_testing_*.md
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

---

## Documentation

- **[USAGE_GUIDE.md](USAGE_GUIDE.md)** - Comprehensive usage guide with real-world scenarios
- **[REFERENCES.md](REFERENCES.md)** - Academic and research references
- **[Performance Methodology Gist](https://gist.github.com/cakmoel/2dbc49121058b3549904a35d33184fe2)** - Mathematical formulas and ISO 25010 compliance

---

## Research Foundations

Resilio implements methodologies from:

- **Jain, R. (1991)** - Statistical methods for performance measurement
- **Welch, B. L. (1947)** - Unequal variance t-test
- **Cohen, J. (1988)** - Effect size interpretation
- **ISO/IEC 25010:2011** - Performance efficiency metrics
- **Barford & Crovella (1998)** - Workload characterization
- **Gunther, N. J. (2007)** - Queueing theory and capacity planning

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Include tests for new functionality
4. Update documentation
5. Submit a pull request

---

## License

This project is licensed under the MIT License.

Copyright © 2025 M.Noermoehammad

---

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/resilio/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/resilio/discussions)
- **Email**: your.email@example.com

---

**Resilio: Built for Speed, Tested for Durability**