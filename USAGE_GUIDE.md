# Resilio Usage Guide

**Complete Guide to Simple and Deep Load Testing**

---

## Table of Contents

1. [Understanding Resilio Architecture](#understanding-resilio-architecture)
2. [SLT (Simple Load Testing) Deep Dive](#slt-simple-load-testing-deep-dive)
3. [DLT (Deep Load Testing) Deep Dive](#dlt-deep-load-testing-deep-dive)
4. [Real-World Workflows](#real-world-workflows)
5. [Statistical Analysis Guide](#statistical-analysis-guide)
6. [Baseline Management](#baseline-management)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [Appendix: Quick Reference](#appendix-quick-reference)

---

## Understanding Resilio Architecture

### Philosophy

Resilio is built on the principle that **performance testing should be both pragmatic and scientifically rigorous**. It provides two complementary tools:

- **SLT (slt.sh)**: Fast, iterative testing for development cycles
- **DLT (dlt.sh)**: Research-grade analysis for production validation

### Technology Stack

Both engines leverage:

- **ApacheBench (ab)**: Industry-standard HTTP benchmarking tool
- **bc**: Floating-point mathematical calculations
- **Bash**: Orchestration and data processing
- **GNU coreutils**: Text processing (awk, grep, sort)

### What Gets Measured

Both scripts measure:

✅ **Throughput**: Requests per second (RPS)  
✅ **Latency**: Response time distribution (P50, P95, P99)  
✅ **Reliability**: Success rate and error tracking  
✅ **Stability**: Coefficient of Variation (CV)  
✅ **Bottlenecks**: Connection time vs processing time

### What Does NOT Get Measured

❌ Application-level code profiling  
❌ Database query optimization  
❌ Memory leaks (use language-specific profilers)  
❌ Internal function call traces

For internal profiling, use:
- **PHP**: Xdebug, Blackfire
- **Node.js**: `node --inspect`, clinic.js
- **Python**: cProfile, py-spy
- **Go**: pprof
- **Java**: JProfiler, VisualVM

---

## SLT (Simple Load Testing) Deep Dive

### Overview

**File**: `slt.sh`  
**Version**: 2.0  
**Purpose**: Rapid performance feedback for agile development

### Architecture

```
┌─────────────────────────────────────┐
│     Configuration Loading           │
│  (SCENARIOS, environment variables) │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Test Execution Loop                │
│   (1000 iterations by default)       │
│                                      │
│   For each iteration:                │
│     For each scenario:               │
│       → Run ApacheBench              │
│       → Parse output                 │
│       → Track success/error          │
│       → Store metrics                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Statistical Analysis               │
│   → Calculate mean, median, std dev  │
│   → Compute percentiles (P50-P99)    │
│   → Calculate CV (stability)         │
│   → Separate errors from dataset     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Report Generation                  │
│   → Console summary                  │
│   → Markdown report                  │
│   → Raw data preservation            │
└─────────────────────────────────────┘
```

### Configuration

**Default Parameters:**

```bash
ITERATIONS=1000           # Total test iterations
AB_REQUESTS=100           # Requests per iteration
AB_CONCURRENCY=10         # Concurrent users
AB_TIMEOUT=30             # Timeout in seconds
```

**Customization:**

```bash
# Light testing (development)
ITERATIONS=100 AB_REQUESTS=50 AB_CONCURRENCY=5 ./slt.sh

# Heavy testing (pre-production)
ITERATIONS=2000 AB_REQUESTS=500 AB_CONCURRENCY=50 ./slt.sh

# API stress test
ITERATIONS=1500 AB_REQUESTS=1000 AB_CONCURRENCY=100 ./slt.sh
```

### Test Scenarios Configuration

Edit the `SCENARIOS` array in `slt.sh` (around line 40):

```bash
declare -A SCENARIOS=(
    ["Homepage"]="http://localhost:8000/"
    ["API_Users"]="http://localhost:8000/api/users"
    ["Checkout"]="http://localhost:8000/checkout"
)
```

**Best Practices:**
- Use descriptive scenario names (no spaces)
- Test diverse endpoint types (static, dynamic, API)
- Include critical user journeys
- Test expected error cases (404, 500)

### Execution Flow

**Phase 1: Initialization** (< 1 second)
- Load configuration
- Create output directory
- Initialize tracking arrays
- Validate required tools

**Phase 2: Test Loop** (duration depends on ITERATIONS)
- Sequential iteration through all scenarios
- Each test: `timeout $AB_TIMEOUT ab -n $AB_REQUESTS -c $AB_CONCURRENCY $url`
- Real-time console output every iteration
- Progress indicators every 100 iterations

**Phase 3: Analysis** (1-2 seconds)
- Sort values for percentile calculations
- Calculate statistics (mean, median, std dev)
- Compute CV for stability assessment
- Generate success/error rates

**Phase 4: Reporting** (< 1 second)
- Console summary with formatted tables
- Markdown report with full metrics
- Preserve all raw ApacheBench outputs

### Output Structure

```
load_test_results_20250108_143022/
├── summary_report.md              # Main report
│
├── console_output.log             # Real-time execution log
├── execution.log                  # Detailed iteration log
├── error.log                      # Error tracking
│
└── raw_Homepage_1.txt             # Raw ApacheBench outputs
    raw_Homepage_2.txt
    raw_API_Users_1.txt
    ...
```

### Understanding SLT Reports

**Sample Output:**

```markdown
##  Homepage

**URL:** `http://localhost:8000/`

### Performance Metrics

| Metric | Value |
|--------|-------|
| **Average RPS** | **1,247.32 req/s** |
| Median RPS | 1,251.18 req/s |
| Standard Deviation | 89.45 req/s (CV: 7.18%) |
| Min/Max RPS | 1,012.34 / 1,398.76 req/s |
| P50 / P95 / P99 | 1,251 / 1,356 / 1,378 req/s |

### Latency Analysis

| Metric | Value |
|--------|-------|
| Avg Response Time | 8.02 ms |
| Median Response Time | 7.98 ms |
| P95 Latency | 11.23 ms |
| P99 Latency | 14.56 ms |

### Reliability

| Metric | Value |
|--------|-------|
| Success Rate | 99.80% (998/1000) |
| Error Rate | 0.20% (2 failures) |

**Stability Assessment:** ==== Excellent (CV < 10%)
```

**Interpretation:**

1. **Average RPS (1,247.32)**: Your application handles ~1,250 requests/second
2. **CV (7.18%)**: Excellent stability—performance is highly consistent
3. **P95 Latency (11.23ms)**: 95% of requests complete within 11.23ms
4. **P99 Latency (14.56ms)**: Even worst-case (99th percentile) is fast
5. **Success Rate (99.80%)**: Nearly perfect reliability

**Verdict:** ✅ Production-ready performance

### When to Use SLT

✅ **Development Phase:**
- Quick smoke tests after code changes
- Comparing optimization attempts
- Validating bug fixes don't regress performance

✅ **CI/CD Pipeline:**
- Fast feedback (completes in minutes)
- Fail builds on severe regressions
- Track performance trends over commits

✅ **Endpoint Comparison:**
- Which implementation is faster? (A/B testing)
- REST API vs GraphQL performance
- CDN vs direct server response

❌ **When NOT to Use SLT:**
- Production baseline establishment (use DLT)
- Statistical hypothesis testing (use DLT)
- Memory leak detection (use DLT sustained phase)
- Capacity planning (use DLT with ramp-up)

### SLT Limitations

1. **No baseline comparison**: Cannot detect gradual performance degradation
2. **No statistical validation**: Results lack confidence intervals
3. **No warm-up phase**: May include JIT compilation overhead
4. **No system monitoring**: Doesn't track CPU/memory during tests

For these capabilities, use **DLT**.

---

## DLT (Deep Load Testing) Deep Dive

### Overview

**File**: `dlt.sh`  
**Version**: 6.0  
**Purpose**: Research-grade performance analysis with statistical rigor

### Key Enhancements in v6.0

✨ **Smart Locale Auto-Detection**: Automatically configures decimal separator for bc calculations  
✨ **Hybrid Baseline Management**: Git-tracked for production, local-only for development  
✨ **Welch's t-test**: Statistical hypothesis testing for performance comparison  
✨ **Cohen's d**: Effect size calculation for practical significance  
✨ **Automated Regression Detection**: Pass/fail verdicts based on statistics

### Architecture

```
┌─────────────────────────────────────┐
│   Environment Detection              │
│   → Read APP_ENV from .env           │
│   → Configure baseline strategy      │
│   → Initialize directories           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Phase 1: WARM-UP (50 iterations)   │
│   → Low concurrency (AB_CONCURRENCY/4)│
│   → Prime JIT compilers               │
│   → Initialize connection pools       │
│   → Warm caches                       │
│   → Results DISCARDED                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Phase 2: RAMP-UP (100 iterations)  │
│   → Gradually increase concurrency    │
│   → Observe "Knee of the Curve"       │
│   → Detect saturation point           │
│   → Results INCLUDED in analysis      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Phase 3: SUSTAINED (850 iterations)│
│   → Full concurrency (AB_CONCURRENCY)│
│   → Primary dataset collection        │
│   → System resource monitoring        │
│   → Results INCLUDED in analysis      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Statistical Analysis               │
│   → Calculate mean, median, std dev  │
│   → Compute 95% confidence intervals │
│   → Percentile analysis (P90-P99)    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Hypothesis Testing                 │
│   → Load latest baseline             │
│   → Welch's t-test (p-value)         │
│   → Cohen's d (effect size)          │
│   → Verdict: Improvement/Regression  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Baseline Management                │
│   → Save current test as baseline    │
│   → Update metadata                  │
│   → Git staging (production mode)    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Report Generation                  │
│   → Research report (full analysis)  │
│   → Hypothesis testing report        │
│   → System metrics CSV               │
└─────────────────────────────────────┘
```

### Configuration

**Research-Based Parameters** (DO NOT change without understanding methodology):

```bash
WARMUP_ITERATIONS=50       # Prime application environment
RAMPUP_ITERATIONS=100      # Observe saturation behavior
SUSTAINED_ITERATIONS=850   # Primary dataset
TOTAL_ITERATIONS=1000      # Total test duration

AB_REQUESTS=1000           # Requests per iteration
AB_CONCURRENCY=50          # Concurrent users
THINK_TIME_MS=2000         # Delay between requests (realistic simulation)
TEST_TIMEOUT=30            # Timeout per test
```

**Why these values?**

- **1000 total iterations**: Statistical significance requires n > 30 per phase (Central Limit Theorem)
- **50 warm-up**: Sufficient for JIT optimization and cache priming
- **100 ramp-up**: Captures transition from cold → hot state
- **850 sustained**: Large dataset for narrow confidence intervals
- **Concurrency 50**: Simulates moderate production load
- **Think time 2000ms**: Models realistic user behavior (Barford & Crovella, 1998)

### Environment Configuration

**Production Mode** (Git-tracked baselines):

```bash
# .env file
APP_ENV=production
STATIC_PAGE=https://prod.example.com/
DYNAMIC_PAGE=https://prod.example.com/api/users
API_ENDPOINT=https://prod.example.com/api/v2/posts
```

- Baselines saved to: `./baselines/`
- Git-tracked: Yes
- Use for: Release validation, SLA monitoring, regression detection

**Local Development Mode** (local-only baselines):

```bash
# .env file
APP_ENV=local
STATIC_PAGE=http://localhost:8000/
DYNAMIC_PAGE=http://localhost:8000/api/users
```

- Baselines saved to: `./.dlt_local/`
- Git-tracked: No
- Use for: Feature development, quick experiments

**Staging Mode**:

```bash
APP_ENV=staging
```

- Baselines saved to: `./.dlt_local/`
- Git-tracked: No

### Execution Flow

**Initialization** (5-10 seconds)
1. Detect environment from `.env`
2. Configure baseline directories
3. Start background system monitoring (CPU, memory, disk I/O)
4. Create report directory structure

**Phase 1: Warm-Up** (~5-10 minutes)
- 50 iterations at 25% concurrency (12-13 concurrent users)
- Purpose: Stabilize application state
- Results: **Discarded** (not included in final analysis)
- Output: Real-time progress indicators

**Phase 2: Ramp-Up** (~10-15 minutes)
- 100 iterations with gradual concurrency increase (13 → 50 users)
- Purpose: Observe system behavior under increasing load
- Results: **Included** in statistical analysis
- Identifies "Knee of the Curve" (saturation point)

**Phase 3: Sustained Load** (~85-120 minutes)
- 850 iterations at full concurrency (50 users)
- Purpose: Collect primary performance dataset
- Results: **Included** in statistical analysis
- Simulates steady-state production load

**Analysis & Reporting** (10-30 seconds)
- Statistical calculations (mean, median, std dev, CI)
- Load baseline from `./baselines/` or `./.dlt_local/`
- Welch's t-test hypothesis testing
- Cohen's d effect size calculation
- Generate two reports: research + hypothesis testing

**Total Duration**: ~100-150 minutes (1.5-2.5 hours)

### Output Structure

```
load_test_reports_20250108_143022/
├── research_report_20250108_143022.md       # Full statistical analysis
├── hypothesis_testing_20250108_143022.md    # Baseline comparison
│
├── system_metrics.csv                       # CPU, memory, disk I/O
├── error_log.txt                            # Error tracking
├── execution.log                            # Phase-by-phase log
│
├── raw_data/                                # All ApacheBench outputs
│   ├── Static_iter_warmup_1.txt
│   ├── Static_iter_rampup_1.txt
│   ├── Static_iter_sustained_1.txt
│   └── ...
│
└── charts/                                  # Reserved for future visualizations
```

### Understanding DLT Reports

#### Research Report Structure

**1. Executive Summary**

```markdown
### Static

**URL**: `https://prod.example.com/`

| Metric | Mean | Median | Std Dev | P95 | P99 | 95% CI |
|--------|------|--------|---------|-----|-----|--------|
| RPS | 1847.32 | 1851.45 | 124.56 | - | - | [1839.12, 1855.52] |
```

**Interpretation:**
- **Mean RPS**: Average throughput
- **95% CI [1839.12, 1855.52]**: True mean lies in this range with 95% confidence
- **Std Dev (124.56)**: Relatively stable if SD < 10% of mean

**2. Latency Breakdown**

```markdown
| Phase | Connect (ms) | Processing (ms) | Total (ms) |
|-------|--------------|-----------------|------------|
| Mean | 2.34 | 24.12 | 26.46 |
| P95 | 3.45 | 31.89 | 35.12 |
| P99 | 4.12 | 38.23 | 42.18 |
```

**Interpretation:**
- **Connect time**: Network + TLS handshake
- **Processing time**: Application logic + database
- **If Connect > Processing**: Network bottleneck
- **If Processing >> Connect**: Application/database bottleneck

#### Hypothesis Testing Report Structure

```markdown
### Dynamic

**Baseline**: ./baselines/production_baseline_Dynamic_20250105.csv  
**Baseline Mean RPS**: 1,247.32  
**Current Mean RPS**: 1,356.78  
**Change**: +8.78%

#### Statistical Test Results

| Metric | Value | Interpretation |
|--------|-------|----------------|
| **t-statistic** | 3.42 | - |
| **p-value** | 0.001 | Statistically significant (p < 0.05) |
| **Degrees of Freedom** | 148 | Welch-Satterthwaite |
| **Cohen's d** | 0.62 | Effect size: medium |
| **Verdict** | ✅ SIGNIFICANT IMPROVEMENT | - |

#### Interpretation

- **Very strong evidence** against H₀ (99.9% confidence)
- Effect size is **medium** (Cohen's d = 0.62)
- **Practical significance**: Change is both statistically and practically significant
```

**Decision Matrix:**

| p-value | Cohen's d | Interpretation | Action |
|---------|-----------|----------------|--------|
| < 0.05 | > 0.8 | Large improvement | ✅ Merge immediately |
| < 0.05 | 0.5-0.8 | Medium improvement | ✅ Merge with confidence |
| < 0.05 | 0.2-0.5 | Small improvement | ⚠️ Document, consider merge |
| < 0.05 | < 0.2 | Negligible change | ⚠️ Not practically important |
| ≥ 0.05 | Any | Not significant | ❌ No evidence of change |

### Baseline Management

**Baseline File Structure:**

```csv
iteration,rps,response_time_ms,p95_ms,p99_ms,connect_ms,processing_ms
1,1247.32,8.02,11.23,14.56,2.34,5.68
2,1251.18,7.98,11.18,14.12,2.31,5.67
3,1245.67,8.05,11.45,14.89,2.36,5.69
...
```

**Baseline Lifecycle:**

1. **First Run** (no baseline exists):
   ```
   Status: No baseline found - this test will be saved as baseline
   ```
   - Current test becomes the baseline
   - Future tests compare against this

2. **Subsequent Runs** (baseline exists):
   ```
   Baseline: ./baselines/production_baseline_Dynamic_20250105.csv
   Verdict: ✅ SIGNIFICANT IMPROVEMENT (+8.78%)
   ```
   - Welch's t-test compares current vs baseline
   - Effect size quantifies practical importance

3. **Updating Baselines**:
   ```bash
   # Method 1: Delete old baseline (forces new baseline creation)
   rm baselines/production_baseline_Dynamic_*.csv
   ./dlt.sh
   
   # Method 2: Rename current test as baseline
   cp load_test_reports_*/raw_data/* baselines/
   ```

**Best Practice:** Establish new baselines after major releases:

```bash
# After release v2.0
git tag v2.0.0
./dlt.sh
git add baselines/
git commit -m "chore: baseline for v2.0.0"
git push --tags
```

### Statistical Methodology

#### Welch's t-test (Welch, 1947)

**Purpose**: Compare two groups with potentially unequal variances

**Formula**:
```
t = (mean₁ - mean₂) / √(s₁²/n₁ + s₂²/n₂)

Where:
- mean₁, mean₂: Sample means
- s₁², s₂²: Sample variances
- n₁, n₂: Sample sizes
```

**Degrees of Freedom (Welch-Satterthwaite)**:
```
df = (s₁²/n₁ + s₂²/n₂)² / ((s₁²/n₁)²/(n₁-1) + (s₂²/n₂)²/(n₂-1))
```

**p-value Interpretation**:
- p < 0.01: Very strong evidence against H₀ (99% confidence)
- p < 0.05: Strong evidence against H₀ (95% confidence)
- p ≥ 0.05: Insufficient evidence to reject H₀

#### Cohen's d (Cohen, 1988)

**Purpose**: Quantify practical significance (effect size)

**Formula**:
```
d = (mean₁ - mean₂) / pooled_SD

pooled_SD = √(((n₁-1)s₁² + (n₂-1)s₂²) / (n₁ + n₂ - 2))
```

**Interpretation**:
- |d| < 0.2: Negligible
- |d| ≈ 0.5: Medium
- |d| > 0.8: Large

**Why Both Metrics Matter**:

| Scenario | p-value | Cohen's d | Interpretation |
|----------|---------|-----------|----------------|
| A | 0.001 | 0.05 | Statistically significant but meaningless change |
| B | 0.08 | 0.75 | Not statistically significant but likely important |
| C | 0.001 | 0.85 | Both statistically and practically significant ✅ |

**Best Practice**: Always consider **both** p-value and effect size before making decisions.

---

## Real-World Workflows

### Workflow 1: Feature Development Cycle

**Scenario**: Optimizing a database query

```bash
# Step 1: Establish baseline (before optimization)
echo "APP_ENV=local" > .env
./dlt.sh

# Output shows:
# ✓ Dynamic: ./.dlt_local/local_baseline_Dynamic_20250108.csv

# Step 2: Make your changes
vim app/Models/User.php
# ... add database indexes ...
php artisan migrate

# Step 3: Run comparison test
./dlt.sh

# Step 4: Check results
cat load_test_reports_*/hypothesis_testing_*.md
```

**Sample Result**:

```markdown
### Dynamic

Baseline Mean RPS: 856.3
Current Mean RPS: 1,124.7
Change: +31.34%

Statistical Test Results:
- p-value: < 0.001
- Cohen's d: 1.42
- Verdict: ✅ SIGNIFICANT IMPROVEMENT

Interpretation:
- Very strong evidence (99.9% confidence)
- Effect size is large (d = 1.42)
- Practical significance: Major performance gain
```

**Decision**: ✅ Merge the optimization! Clear win with statistical backing.

---

### Workflow 2: Production Baseline Management

**Scenario**: Setting up performance monitoring for production

```bash
# Step 1: Initial setup
git clone https://github.com/yourteam/app.git
cd app
cp .env.example .env

# Step 2: Configure for production
cat > .env << EOF
APP_ENV=production
STATIC_PAGE=https://prod.example.com/
DYNAMIC_PAGE=https://prod.example.com/api/users
API_ENDPOINT=https://prod.example.com/api/v2/posts
EOF

# Step 3: Establish production baseline
./dlt.sh

# Step 4: Commit baselines to Git
git add baselines/
git add .gitignore
git commit -m "chore: establish production performance baselines for v1.0"
git push origin main
```

**Git History**:

```
baselines/
├── production_baseline_Static_20250108.csv      (Git-tracked)
├── production_baseline_Dynamic_20250108.csv     (Git-tracked)
├── production_baseline_API_Endpoint_20250108.csv
└── metadata.json
```

**Future Releases**:

```bash
# After release v2.0 (3 months later)
./dlt.sh

# Check for regressions
cat load_test_reports_*/hypothesis_testing_*.md

# If all tests show "No significant change" or "IMPROVEMENT":
git add baselines/
git commit -m "chore: update baselines for v2.0"
git tag v2.0.0
git push --tags
```

---

### Workflow 3: CI/CD Integration

**Scenario**: Automated performance regression detection on every PR

**.github/workflows/performance-test.yml**:

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
          fetch-depth: 0  # Need full history for baselines
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y apache2-utils bc sysstat
      
      - name: Setup environment
        run: |
          cp .env.example .env
          echo "APP_ENV=production" >> .env
          # Use staging URLs for PR testing
          echo "STATIC_PAGE=https://staging.example.com/" >> .env
          echo "DYNAMIC_PAGE=https://staging.example.com/api/users" >> .env
      
      - name: Run load test
        id: loadtest
        run: |
          chmod +x dlt.sh
          ./dlt.sh
          
          # Parse hypothesis testing results
          REPORT=$(find load_test_reports_* -name "hypothesis_testing_*.md" | head -1)
          
          # Check for regressions
          if grep -q "REGRESSION" "$REPORT"; then
            echo "regression=true" >> $GITHUB_OUTPUT
            cat "$REPORT"
            exit 1
          else
            echo "regression=false" >> $GITHUB_OUTPUT
          fi
      
      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: performance-reports
          path: load_test_reports_*/**
      
      - name: Comment PR with results
        if: always()
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const reportPath = require('child_process')
              .execSync('find load_test_reports_* -name "hypothesis_testing_*.md" | head -1')
              .toString()
              .trim();
            const report = fs.readFileSync(reportPath, 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 📊 Performance Test Results\n\n${report}`
            });
```

**Result**: Every PR automatically gets a performance report:

```markdown
## 📊 Performance Test Results

### Static
✅ No significant change (p=0.24, d=0.08)

### Dynamic
⚠️ SIGNIFICANT REGRESSION
- Baseline: 856.3 req/s
- Current: 798.1 req/s
- Change: -6.79%
- p-value: 0.001
- Cohen's d: -0.72 (medium effect)

**Action Required:** Investigate performance regression before merging.
```

**Team Response**:
1. Developer investigates the regression
2. Finds N+1 query issue
3. Fixes the issue
4. Re-runs CI/CD
5. New test shows ✅ "No significant change"
6. PR is approved and merged

---

### Workflow 4: A/B Testing (Redis vs Memcached)

**Scenario**: Which caching backend performs better?

```bash
# Test A: Redis
echo "CACHE_DRIVER=redis" > .env
echo "APP_ENV=local" >> .env
./dlt.sh
# API_Endpoint: 1,247.3 req/s

# Test B: Memcached
echo "CACHE_DRIVER=memcached" > .env
./dlt.sh
# API_Endpoint: 1,189.6 req/s

# Compare baselines
# Result: p=0.023, d=0.45 (small-medium effect)
# Redis is 4.86% faster with statistical significance
```

**Decision**: ✅ Choose Redis (statistically faster, though effect is moderate)

---

## Statistical Analysis Guide

### Understanding p-values

**p-value**: Probability of observing results this extreme if H₀ is true

**Interpretation**:

| p-value Range | Interpretation | Confidence |
|---------------|----------------|------------|
| p < 0.001 | Very strong evidence against H₀ | 99.9% |
| 0.001 ≤ p < 0.01 | Strong evidence against H₀ | 99% |
| 0.01 ≤ p < 0.05 | Moderate evidence against H₀ | 95% |
| 0.05 ≤ p < 0.10 | Weak evidence against H₀ | 90% |
| p ≥ 0.10 | Insufficient evidence | - |

**Common Misconceptions**:

❌ **"p < 0.05 means there's a 95% chance the change is real"**  
✅ **Correct**: "If there were no real change, we'd see results this extreme < 5% of the time"

❌ **"p = 0.051 means no effect exists"**  
✅ **Correct**: "Evidence is slightly below conventional threshold, but an effect may still exist"

❌ **"p < 0.001 means the change is important"**  
✅ **Correct**: "Very strong statistical evidence, but check Cohen's d for practical importance"

❌ **"Statistical significance = practical significance"**  
✅ **Correct**: "A statistically significant 0.5% improvement may not be worth deploying"

### Understanding Confidence Intervals

**95% Confidence Interval [1839.12, 1855.52]**

**Interpretation**:
- If we repeated this test 100 times, approximately 95 of those intervals would contain the true population mean
- We're 95% confident the true mean RPS lies between 1839.12 and 1855.52
- **NOT**: "There's a 95% probability the true mean is in this range"

**Practical Use**:

```markdown
Baseline CI: [850.0, 862.6]
Current CI:  [1115.3, 1134.1]

→ Intervals don't overlap → Strong evidence of difference
→ Can report: "Performance improved by at least 29.3% with 95% confidence"
```

### Understanding Standard Deviation

**Standard Deviation = 124.56 req/s**

**What it means**:
- ~68% of observations fall within mean ± 1 SD
- ~95% of observations fall within mean ± 2 SD
- ~99.7% of observations fall within mean ± 3 SD

**Example**:

```
Mean: 1,247.32 req/s
SD:   124.56 req/s

68% of tests: 1,122.76 - 1,371.88 req/s
95% of tests: 998.20 - 1,496.44 req/s
99.7% of tests: 873.64 - 1,620.00 req/s
```

**Low SD = Stable System**  
**High SD = Unpredictable Performance**

---

## Advanced Configuration

### Testing Authenticated Endpoints

**Method 1: Bearer Token Authentication**

Edit `dlt.sh` or `slt.sh` and locate the `ab` command (around line 200 in `slt.sh` or line 350 in `dlt.sh`):

```bash
# Find this line:
timeout $TEST_TIMEOUT ab -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1

# Replace with:
timeout $TEST_TIMEOUT ab -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

**Method 2: Cookie-Based Authentication**

```bash
# Step 1: Get session cookie first
curl -c cookies.txt -X POST http://localhost:8000/login \
  -d "username=test&password=test123"

# Step 2: Extract cookie value
SESSION_ID=$(cat cookies.txt | grep session | awk '{print $7}')

# Step 3: Edit script to use cookie
timeout $TEST_TIMEOUT ab -C "session=$SESSION_ID" \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

**Method 3: Environment Variable Token**

```bash
# .env file
AUTH_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# In script, load from .env:
source .env
timeout $TEST_TIMEOUT ab -H "Authorization: Bearer $AUTH_TOKEN" \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

**Method 4: Basic Authentication**

```bash
# For HTTP Basic Auth
timeout $TEST_TIMEOUT ab -A username:password \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

### Testing POST Requests

**Step 1: Create POST data file**

```bash
# postdata.json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "securepass123",
  "action": "create"
}
```

**Step 2: Modify ab command in script**

```bash
timeout $TEST_TIMEOUT ab -p postdata.json -T "application/json" \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

**For form-encoded POST:**

```bash
# postdata.txt
username=testuser&email=test@example.com&action=create

# In script:
timeout $TEST_TIMEOUT ab -p postdata.txt -T "application/x-www-form-urlencoded" \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

### Custom Headers

**Add multiple custom headers:**

```bash
timeout $TEST_TIMEOUT ab \
  -H "X-API-Version: v2" \
  -H "X-Client-ID: load-test" \
  -H "Accept: application/json" \
  -H "User-Agent: Resilio-LoadTest/6.0" \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

**Common use cases:**

```bash
# API versioning
-H "X-API-Version: v2"

# Client identification
-H "X-Client-ID: load-test-suite"

# Accept specific content types
-H "Accept: application/json"

# Custom tracking headers
-H "X-Request-ID: $(uuidgen)"

# Bypass CDN for origin testing
-H "Cache-Control: no-cache"
```

### Keep-Alive Configuration

**Enable HTTP keep-alive** (recommended for realistic testing):

```bash
# Already enabled by default in dlt.sh with -k flag
ab -k -n $AB_REQUESTS -c $concurrency "$url"
```

**Disable keep-alive** (test cold connections):

```bash
# Remove -k flag to test connection overhead
ab -n $AB_REQUESTS -c $concurrency "$url"
```

**Why it matters:**
- **With keep-alive (-k)**: Reuses TCP connections (realistic modern web traffic)
- **Without keep-alive**: Creates new connection for each request (higher overhead)

### Custom Think Time

**Adjust think time** in `dlt.sh` to simulate different user behaviors:

```bash
# Edit dlt.sh around line 72
THINK_TIME_MS=2000  # Default

# Fast users (e-commerce checkout)
THINK_TIME_MS=1000

# Normal users (browsing)
THINK_TIME_MS=2000

# Slow users (reading content)
THINK_TIME_MS=5000

# Batch API calls (no delay)
THINK_TIME_MS=0
```

**Implementation in script:**

```bash
# Random think time between 500ms and THINK_TIME_MS
local think_time=$(( (RANDOM % THINK_TIME_MS) + 500 ))
sleep $(echo "scale=3; $think_time / 1000" | bc)
```

### Testing Multiple HTTP Methods

**GET requests** (default):

```bash
ab -n 100 -c 10 "http://localhost:8000/api/users"
```

**POST requests:**

```bash
ab -n 100 -c 10 -p postdata.json -T "application/json" \
  "http://localhost:8000/api/users"
```

**PUT requests:**

```bash
ab -n 100 -c 10 -u putdata.json -T "application/json" \
  "http://localhost:8000/api/users/123"
```

**DELETE requests:**

```bash
# ApacheBench doesn't support DELETE natively
# Use curl in a loop instead:
for i in {1..100}; do
  curl -X DELETE "http://localhost:8000/api/users/$i"
done
```

### Running Tests in Background

**Background execution with logging:**

```bash
# Start test in background
nohup ./dlt.sh > dlt_$(date +%Y%m%d_%H%M%S).log 2>&1 &

# Save process ID
echo $! > dlt.pid

# Monitor progress in real-time
tail -f dlt_*.log

# Check if still running
if ps -p $(cat dlt.pid) > /dev/null; then
  echo "Test is running"
else
  echo "Test completed"
fi

# Stop test if needed
kill $(cat dlt.pid)

# Force stop
kill -9 $(cat dlt.pid)
```

**Using screen or tmux:**

```bash
# Using screen
screen -S loadtest
./dlt.sh
# Press Ctrl+A then D to detach

# Reattach later
screen -r loadtest

# Using tmux
tmux new -s loadtest
./dlt.sh
# Press Ctrl+B then D to detach

# Reattach later
tmux attach -t loadtest
```

### Testing Through Proxies

**HTTP Proxy:**

```bash
# Set proxy environment variables
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080

./dlt.sh
```

**SOCKS Proxy:**

```bash
# ApacheBench doesn't support SOCKS directly
# Use proxychains
sudo apt-get install proxychains

# Configure /etc/proxychains.conf
# socks5 127.0.0.1 9050

proxychains ./dlt.sh
```

### SSL/TLS Configuration

**Test with specific TLS version:**

```bash
# ApacheBench uses system OpenSSL
# Force TLS 1.2
export OPENSSL_CONF=/path/to/custom/openssl.cnf

# Or use curl for TLS testing
curl --tlsv1.2 https://example.com/
```

**Ignore SSL certificate errors** (testing only):

```bash
# ApacheBench doesn't have -k option like curl
# Use stunnel or modify ab command with custom verification
```

---

## Troubleshooting

### Issue 1: Locale Errors

**Error Message:**

```
[FATAL] bc incompatible with current locale. Install en_US.UTF-8 or run with LC_NUMERIC=C
```

**Root Cause**: System locale uses comma as decimal separator (e.g., `3,14` instead of `3.14`), which is incompatible with `bc` calculations.

**Solutions:**

**Option A: Install en_US.UTF-8 locale**

```bash
# Ubuntu/Debian
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

# CentOS/RHEL
sudo localedef -i en_US -f UTF-8 en_US.UTF-8

# Verify
locale -a | grep en_US
```

**Option B: Run with C locale (quickest)**

```bash
LC_NUMERIC=C ./dlt.sh
```

**Option C: Set in .env file**

```bash
echo "LC_NUMERIC=C" >> .env
./dlt.sh
```

**Option D: Set permanently in shell**

```bash
echo 'export LC_NUMERIC=C' >> ~/.bashrc
source ~/.bashrc
```

**Verify Fix:**

```bash
echo "scale=2; 3.14 * 2" | bc -l
# Should output: 6.28 (not 6,28)
```

---

### Issue 2: No Baseline Found

**Message:**

```
### Dynamic
Status: No baseline found - this test will be saved as baseline
```

**Explanation**: This is **normal behavior** on the first run. DLT needs a baseline to compare against.

**Expected Workflow:**

```bash
# Run 1: Establishes baseline
./dlt.sh
# Output: "No baseline found - this test will be saved as baseline"

# Run 2: Compares against baseline
./dlt.sh
# Output: "Baseline: ./baselines/production_baseline_Dynamic_20250108.csv"
#         "Verdict: ✅ No significant change"
```

**Force New Baseline Creation:**

```bash
# Delete existing baselines
rm -rf baselines/production_baseline_Dynamic_*.csv

# Or delete all baselines
rm -rf baselines/*.csv

# Next run creates fresh baseline
./dlt.sh
```

**When to Update Baselines:**

✅ After major release (v1.0 → v2.0)  
✅ After infrastructure changes (new servers)  
✅ After significant optimizations  
❌ After every test (defeats purpose of regression detection)  
❌ When results are bad (cherry-picking)

---

### Issue 3: Git Not Tracking Baselines

**Problem**: Baselines not appearing in `git status`

**Root Cause**: `APP_ENV` is not set to `production`, so baselines go to `.dlt_local/` which is git-ignored.

**Check Environment:**

```bash
# Check .env file
cat .env | grep APP_ENV

# If it shows:
APP_ENV=local    # Baselines → .dlt_local/ (not tracked)

# Should show:
APP_ENV=production    # Baselines → ./baselines/ (tracked)
```

**Fix:**

```bash
# Method 1: Edit .env file
sed -i 's/APP_ENV=local/APP_ENV=production/' .env

# Method 2: Manually edit
nano .env
# Change: APP_ENV=production

# Method 3: Recreate .env
echo "APP_ENV=production" > .env
echo "STATIC_PAGE=https://prod.example.com/" >> .env

# Re-run test
./dlt.sh

# Verify baselines are now in correct location
ls -la baselines/
# Should show production_baseline_*.csv files

# Add to Git
git add baselines/
git commit -m "chore: add production performance baselines"
git push
```

**Verify Git Tracking:**

```bash
# Check if baselines directory is tracked
git ls-files baselines/
# Should list all baseline CSV files

# Check .gitignore doesn't exclude baselines
cat .gitignore | grep baselines
# Should NOT find "baselines/" entry
```

---

### Issue 4: Inconsistent Results Between Runs

**Symptom**: Running the same test twice gives significantly different results.

**Possible Causes & Solutions:**

**1. System Load Varied**

```bash
# Check system metrics during test
cat load_test_reports_*/system_metrics.csv

# Look for anomalies:
# - CPU usage > 90%
# - Memory < 10% free
# - High load average (> number of CPU cores)

# Solution: Run tests during off-peak hours
# Use 'cron' to schedule tests:
crontab -e
# Add: 0 2 * * * cd /path/to/resilio && ./dlt.sh
```

**2. Sample Size Too Small**

```bash
# Increase iterations in dlt.sh
# Edit around line 65:
TOTAL_ITERATIONS=2000
SUSTAINED_ITERATIONS=1700

# More iterations = narrower confidence intervals = more reliable
```

**3. Application State Changed**

Common issues:
- Database grew between tests (more records = slower queries)
- Cache warmed up (first test cold, second test warm)
- Background jobs running (cron, queue workers)
- Disk space filled up

```bash
# Solution: Ensure consistent state

# 1. Reset database to known state
php artisan migrate:fresh --seed

# 2. Clear all caches
php artisan cache:clear
redis-cli FLUSHALL

# 3. Stop background jobs during test
sudo systemctl stop cron
sudo supervisorctl stop all

# 4. Restart application
sudo systemctl restart php-fpm
```

**4. Network Conditions**

```bash
# Check network latency
ping -c 100 localhost
# Look for packet loss or high variance

# Check DNS resolution
time nslookup example.com
# Should be < 50ms

# Disable rate limiting temporarily
# (Application-specific configuration)
```

**Best Practice: Run Multiple Tests**

```bash
# Run 3 times, take median
./dlt.sh  # Run 1
sleep 300  # 5 minute cooldown

./dlt.sh  # Run 2
sleep 300

./dlt.sh  # Run 3

# Compare all three reports
ls -lt load_test_reports_*/hypothesis_testing_*.md | head -3

# Use median result for decision-making
```

---

### Issue 5: Tests Timing Out

**Error:**

```
[ERROR] Test timeout or execution failed for Dynamic iteration 1
Failed requests:    100
   (Connect: 0, Receive: 0, Length: 0, Exceptions: 100)
```

**Solutions:**

**1. Increase Timeout**

```bash
# Edit dlt.sh (line ~72) or slt.sh
TEST_TIMEOUT=60  # Increased from 30 seconds

# Or set via environment variable (slt.sh only)
AB_TIMEOUT=60 ./slt.sh
```

**2. Reduce Concurrency**

```bash
# Edit dlt.sh (line ~71)
AB_CONCURRENCY=25  # Reduced from 50

# Or for slt.sh:
AB_CONCURRENCY=5 ./slt.sh
```

**3. Check Application Health**

```bash
# Test single request latency
curl -w "Time: %{time_total}s\n" -o /dev/null -s http://localhost:8000/

# Should be < 1 second
# If > 5 seconds, application has issues

# Check application logs
tail -f /var/log/nginx/error.log
tail -f /var/log/php-fpm/error.log

# Common issues:
# - Database connection pool exhausted
# - Memory limit reached
# - Slow query (missing indexes)
```

**4. Check System Resources**

```bash
# CPU usage
top
# If at 100%, reduce concurrency

# Memory
free -h
# If swap is being used, reduce load

# Disk I/O
iostat -x 1
# If %util > 80%, disk is bottleneck

# Network connections
ss -s
# Check for connection limits
```

---

### Issue 6: High Error Rates

**Symptom**: Success rate < 95%, many failed requests

**Investigation Steps:**

**1. Check Error Log**

```bash
cat load_test_reports_*/error_log.txt

# Look for patterns:
# - Connection refused
# - Timeout
# - 500 Internal Server Error
# - 502 Bad Gateway
# - 503 Service Unavailable
```

**2. Examine Raw ApacheBench Outputs**

```bash
grep -A 10 "Failed requests" load_test_reports_*/raw_data/*.txt | less

# Look for:
# - Connect errors (app not running)
# - Receive errors (app crashed mid-request)
# - Length errors (response size mismatch)
# - Exceptions (network issues)
```

**3. Common Causes & Solutions**

| Error Type | Cause | Solution |
|------------|-------|----------|
| **Connection Refused** | App not running | `sudo systemctl start php-fpm` |
| **Timeout** | App too slow | Optimize code or increase timeout |
| **503 Errors** | Resource exhaustion | Increase PHP workers, memory limits |
| **502 Bad Gateway** | PHP-FPM crashed | Check PHP-FPM logs, increase workers |
| **SSL Errors** | Certificate issues | Fix SSL configuration |
| **Length Errors** | Response varies | Check for dynamic content issues |

**4. Debug Individual Request**

```bash
# Test single request with verbose output
curl -v http://localhost:8000/api/users

# Check response headers
curl -I http://localhost:8000/api/users

# Time each phase
curl -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n" \
  -o /dev/null -s http://localhost:8000/api/users
```

**5. Application-Specific Debugging**

```bash
# PHP: Check FPM status
sudo systemctl status php-fpm
# Look for worker limits, memory exhaustion

# Check PHP error log
tail -f /var/log/php-fpm/error.log

# Node.js: Check process
pm2 status
pm2 logs

# Python: Check uWSGI/Gunicorn
sudo systemctl status gunicorn
journalctl -u gunicorn -f
```

---

### Issue 7: "Too Many Open Files"

**Error:**

```
ab: apr_socket_recv: Connection reset by peer (104)
socket: Too many open files
```

**Root Cause**: System file descriptor limit too low for high concurrency testing.

**Check Current Limit:**

```bash
ulimit -n
# Typically shows: 1024 (too low for load testing)
```

**Solutions:**

**1. Temporary Fix (current session only)**

```bash
ulimit -n 10000
./dlt.sh
```

**2. Permanent Fix (user-level)**

```bash
# Edit limits.conf
sudo nano /etc/security/limits.conf

# Add these lines:
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536

# Save and exit

# Apply changes (requires logout/login)
sudo reboot

# Or re-login
exit
# Log back in

# Verify
ulimit -n
# Should show: 65536
```

**3. Permanent Fix (system-wide)**

```bash
# Edit sysctl.conf
sudo nano /etc/sysctl.conf

# Add:
fs.file-max = 2097152

# Apply immediately
sudo sysctl -p

# Verify
cat /proc/sys/fs/file-max
# Should show: 2097152
```

**4. For systemd services**

```bash
# Edit service file
sudo systemctl edit php-fpm

# Add:
[Service]
LimitNOFILE=65536

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart php-fpm
```

---

### Issue 8: Script Hangs / No Progress

**Symptom**: Script runs but shows no output for extended period (> 5 minutes with no updates).

**Possible Causes:**

**1. Network Timeout / Unreachable URL**

```bash
# Check if target URL is reachable
curl -v --max-time 10 http://localhost:8000/

# Check DNS resolution
nslookup example.com

# Check network connectivity
ping -c 5 localhost

# Check firewall rules
sudo iptables -L -n
sudo ufw status
```

**2. Application Deadlock**

```bash
# Check if application is responding
ps aux | grep php-fpm  # or node, python, etc.

# Check for zombie processes
ps aux | grep 'Z'

# Check application logs
tail -f /var/log/application.log

# Test if endpoint responds
curl --max-time 5 http://localhost:8000/api/users
```

**3. System Resource Exhaustion**

```bash
# Check memory
free -h
# If swap is at max, system is thrashing

# Check disk space
df -h
# If at 100%, logs can't be written

# Check CPU
top
# If load average >> CPU count, system overloaded

# Check disk I/O wait
iostat -x 1
# If %iowait > 50%, disk is bottleneck
```

**4. ApacheBench Stuck**

```bash
# Find ab processes
ps aux | grep ab

# Kill stuck ab processes
pkill -9 ab

# Find test script
ps aux | grep dlt.sh

# Stop gracefully
kill $(pgrep -f dlt.sh)

# Force stop
kill -9 $(pgrep -f dlt.sh)
```

**Emergency Stop Procedure:**

```bash
# 1. Press Ctrl+C (graceful stop)
# Test script catches SIGINT and cleans up

# 2. If Ctrl+C doesn't work, force kill:
ps aux | grep dlt.sh
kill -9 <PID>

# 3. Kill all related processes
pkill -9 -f "dlt.sh"
pkill -9 ab

# 4. Check for orphaned processes
ps aux | grep -E "(dlt|slt|ab)"

# 5. Clean up any locks or temp files
rm -f /tmp/ab_* 2>/dev/null
```

**Prevention:**

```bash
# Always use timeout in scripts (already implemented)
timeout $TEST_TIMEOUT ab -n ...

# Monitor in separate terminal
watch -n 5 'ps aux | grep -E "(dlt|ab)" | grep -v grep'

# Set up automated timeout
# Run test with overall timeout:
timeout 2h ./dlt.sh
```

---

## Best Practices

### Pre-Test Checklist

✅ **Environment Verification**

```bash
# 1. Required tools installed
command -v ab >/dev/null 2>&1 || { echo "ab not installed"; exit 1; }
command -v bc >/dev/null 2>&1 || { echo "bc not installed"; exit 1; }
command -v awk >/dev/null 2>&1 || { echo "awk not installed"; exit 1; }

# 2. Target application is running
curl -f -s -o /dev/null http://localhost:8000/ || { echo "App not responding"; exit 1; }

# 3. Resource limits adequate
if [ $(ulimit -n) -lt 10000 ]; then
  echo "File descriptor limit too low: $(ulimit -n)"
  echo "Run: ulimit -n 10000"
  exit 1
fi

# 4. Disk space available (need at least 5GB)
available=$(df -BG . | tail -1 | awk '{print $4}' | tr -d 'G')
if [ $available -lt 5 ]; then
  echo "Insufficient disk space: ${available}GB"
  exit 1
fi

# 5. No rate limiting active
# (Application-specific - check your config)
```

✅ **Application State**

```bash
# 1. Warm up application (prime caches, JIT)
for i in {1..10}; do
  curl -s http://localhost:8000/ > /dev/null
  sleep 1
done

# 2. Clear old logs
sudo truncate -s 0 /var/log/nginx/access.log
sudo truncate -s 0 /var/log/nginx/error.log
sudo truncate -s 0 /var/log/php-fpm/error.log

# 3. Restart application for clean state
sudo systemctl restart php-fpm
sleep 5

# 4. Verify database connection
mysql -e "SELECT 1" >/dev/null 2>&1 || { echo "DB connection failed"; exit 1; }

# 5. Seed database with consistent test data
php artisan migrate:fresh --seed --class=LoadTestSeeder
```

✅ **System Optimization**

```bash
# 1. Stop unnecessary services
sudo systemctl stop cron
sudo systemctl stop snapd
sudo systemctl stop unattended-upgrades

# 2. Drop caches (if testing cold performance)
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'

# 3. Set CPU governor to performance
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
  echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
fi

# 4. Disable swap (if sufficient RAM)
sudo swapoff -a

# 5. Set I/O scheduler to deadline (for SSDs)
echo deadline | sudo tee /sys/block/sda/queue/scheduler
```

### During Test Execution

✅ **Multi-Terminal Monitoring**

**Terminal 1: Run Test**

```bash
./dlt.sh
```

**Terminal 2: Monitor Application Logs**

```bash
tail -f /var/log/nginx/access.log | grep -E "(200|500|502|503)"
```

**Terminal 3: Monitor System Resources**

```bash
# Real-time monitoring
htop

# Or use dstat
dstat -tcmdn 5

# Or use vmstat
vmstat 5
```

**Terminal 4: Monitor Database**

```bash
# MySQL
watch -n 5 'mysql -e "SHOW PROCESSLIST"'

# PostgreSQL
watch -n 5 'psql -c "SELECT * FROM pg_stat_activity"'

# Redis
redis-cli --latency
```

✅ **Do NOT During Testing**

❌ Deploy code changes  
❌ Run database migrations  
❌ Restart any services  
❌ Run multiple tests simultaneously  
❌ Browse the application manually  
❌ Run backups or maintenance tasks  
❌ Modify system configuration  

### Post-Test Analysis

✅ **Immediate Actions**

```bash
# 1. Review hypothesis testing report first
cat load_test_reports_*/hypothesis_testing_*.md | less

# 2. Check for regressions
if grep -q "REGRESSION" load_test_reports_*/hypothesis_testing_*.md; then
  echo "⚠️  REGRESSION DETECTED - INVESTIGATE BEFORE DEPLOYING"
else
  echo "✅ No regressions found"
fi

# 3. Review system metrics for anomalies
# Look for CPU spikes, memory exhaustion
awk -F',' 'NR>1 && $2>90 {print "High CPU at", $1, ":", $2"%"}' \
  load_test_reports_*/system_metrics.csv

# 4. Check error rate
error_count=$(grep "ERROR" load_test_reports_*/error_log.txt | wc -l)
if [ $error_count -gt 10 ]; then
  echo "⚠️  High error count: $error_count"
fi

# 5. Archive important reports
if [ -d "load_test_reports_"* ]; then
  tar -czf "load_test_$(date +%Y%m%d_%H%M%S).tar.gz" load_test_reports_*
  echo "✅ Report archived"
fi
```

✅ **Clean Up Old Reports**

```bash
# Keep only last 10 reports
ls -dt load_test_reports_* | tail -n +11 | xargs rm -rf

# Or keep reports from last 30 days
find . -maxdepth 1 -name "load_test_reports_*" -type d -mtime +30 -exec rm -rf {} \;
```

✅ **Document Results**

Create a test report document:

```markdown
# Performance Test Report

**Date:** 2025-01-08 14:30:00  
**Tester:** Senior QA Engineer  
**Feature:** Database Index Optimization  
**Environment:** Staging  
**Git Commit:** a3f9d8c1234567890abcdef  
**Branch:** feature/optimize-user-queries

## Objective
Validate that adding database indexes improves API response time without introducing regressions.

## Test Configuration
- **Tool:** Resilio DLT v6.0
- **Iterations:** 1000 (50 warmup + 100 rampup + 850 sustained)
- **Concurrency:** 50 concurrent users
- **Duration:** ~120 minutes

## Baseline
- **Established:** 2025-01-05 (main branch, commit: xyz789)
- **Baseline RPS:** 856.3 req/s
- **Baseline P95:** 145.2ms

## Current Results
- **Current RPS:** 1,124.7 req/s (+31.34%)
- **Current P95:** 98.6ms (-32.1%)
- **Success Rate:** 99.98%
- **CV (Stability):** 7.2% (Excellent)

## Statistical Analysis
- **p-value:** < 0.001 (very significant)
- **Cohen's d:** 1.42 (large effect size)
- **95% CI:** [1,115.3, 1,134.1]
- **Verdict:** ✅ SIGNIFICANT IMPROVEMENT

## Interpretation
- Very strong statistical evidence (99.9% confidence)
- Effect size is large (d > 0.8) - major practical improvement
- Both throughput and latency improved significantly
- System stability excellent (CV < 10%)

## System Metrics
- **Peak CPU:** 78% (acceptable)
- **Peak Memory:** 4.2GB / 8GB (52%, healthy)
- **Disk I/O:** Minimal impact
- **No errors or warnings** in application logs

## Conclusion
✅ **APPROVED FOR PRODUCTION DEPLOYMENT**

Database index optimization delivers substantial, statistically-validated performance improvement with no regressions or stability issues.

## Recommendations
1. Deploy to production during next release window
2. Update performance baseline after production deployment
3. Monitor production metrics for 48 hours post-deployment
4. Document index strategy in technical documentation

## Artifacts
- Full Report: `load_test_reports_20250108_143022/research_report_20250108_143022.md`
- Hypothesis Testing: `load_test_reports_20250108_143022/hypothesis_testing_20250108_143022.md`
- System Metrics: `load_test_reports_20250108_143022/system_metrics.csv`
- Archive: `load_test_20250108_143022.tar.gz`

---
**Approved by:** Senior QA Engineer  
**Reviewed by:** Tech Lead, DevOps Engineer  
**Next Action:** Schedule production deployment
```

### Comparative Testing Best Practices

When comparing performance across different scenarios:

✅ **Ensure Consistency**

```bash
# Same hardware
lscpu  # Document CPU specs
free -h  # Document RAM
df -h   # Document disk

# Same network conditions
ping -c 100 localhost | tail -5  # Document latency

# Same database state
mysql -e "SELECT COUNT(*) FROM users"  # Document record count

# Same test parameters
echo "ITERATIONS=$ITERATIONS" > test_config.txt
echo "AB_REQUESTS=$AB_REQUESTS" >> test_config.txt
echo "AB_CONCURRENCY=$AB_CONCURRENCY" >> test_config.txt

# Same time of day (avoid peak hours)
echo "Test time: $(date)" >> test_config.txt
```

✅ **Technology Comparison Matrix**

| Factor | PHP (Laravel) | Node.js (Express) | Python (FastAPI) | Go (Gin) |
|--------|---------------|-------------------|------------------|----------|
| Same Hardware | ✅ AWS t3.medium | ✅ AWS t3.medium | ✅ AWS t3.medium | ✅ AWS t3.medium |
| Same Database | ✅ MySQL 8.0, 10K records | ✅ MySQL 8.0, 10K records | ✅ MySQL 8.0, 10K records | ✅ MySQL 8.0, 10K records |
| Same Endpoint | ✅ GET /api/users | ✅ GET /api/users | ✅ GET /api/users | ✅ GET /api/users |
| Same Concurrency | ✅ 50 users | ✅ 50 users | ✅ 50 users | ✅ 50 users |
| Same Time | ✅ 2 AM UTC | ✅ 2 AM UTC | ✅ 2 AM UTC | ✅ 2 AM UTC |

### Statistical Rigor Practices

✅ **Always Consider Both Metrics**

```markdown
## Decision Matrix

| Scenario | p-value | Cohen's d | Statistical | Practical | Decision |
|----------|---------|-----------|-------------|-----------|----------|
| A | 0.001 | 0.08 | Significant | Negligible | Document only |
| B | 0.06 | 0.75 | Not significant | Large | Retest (may be Type II error) |
| C | 0.001 | 0.92 | Significant | Large | ✅ Deploy immediately |
| D | 0.24 | 0.15 | Not significant | Negligible | No change detected |
```

✅ **Avoid Common Pitfalls**

**P-Hacking (DON'T DO THIS):**

```bash
# ❌ WRONG: Running tests until p < 0.05
./dlt.sh  # p = 0.08 (not significant)
./dlt.sh  # p = 0.06 (still not significant)
./dlt.sh  # p = 0.04 (significant!) ← cherry-picked result
```

**Correct Approach:**

```bash
# ✅ CORRECT: Pre-register test plan
echo "Running 3 tests, will use median result" > test_plan.txt
./dlt.sh  # Test 1
./dlt.sh  # Test 2
./dlt.sh  # Test 3
# Report all three results, use median
```

✅ **Document Transparently**

```markdown
## Test History

| Date | Commit | RPS | p-value | Cohen's d | Notes |
|------|--------|-----|---------|-----------|-------|
| 2025-01-05 | baseline | 856.3 | - | - | Baseline established |
| 2025-01-06 | a1b2c3d | 798.1 | 0.06 | 0.45 | Borderline, retest scheduled |
| 2025-01-06 | a1b2c3d | 812.4 | 0.08 | 0.38 | Retest confirms no sig. improvement |
| 2025-01-08 | x9y8z7w | 1124.7 | <0.001 | 1.42 | ✅ Clear improvement |
```

✅ **Preregistration for Critical Tests**

```bash
# Before running test, document your hypothesis
cat > test_hypothesis.md << 'EOF'
# Hypothesis: Database Index Will Improve Performance

## Prediction
Adding index on users.email will improve /api/users endpoint by 20-30%.

## Test Plan
- Tool: Resilio DLT v6.0
- Baseline: commit xyz789 (established 2025-01-05)
- Test: commit a3f9d8c (with index added)
- Expected p-value: < 0.05
- Expected Cohen's d: > 0.5 (medium-large effect)

## Success Criteria
- p < 0.05 AND Cohen's d > 0.5 → Deploy
- p ≥ 0.05 OR Cohen's d < 0.5 → Investigate further

## Commit timestamp: 2025-01-08 10:00:00
EOF

git add test_hypothesis.md
git commit -m "docs: preregister performance test hypothesis"
```

### Production Testing Safety

⚠️ **NEVER Run Load Tests Against Production Without:**

**1. Written Authorization**

```markdown
# Performance Test Authorization Request

**To:** CTO, VP Engineering, SRE Lead
**From:** Senior QA Engineer
**Date:** 2025-01-08

**Request:** Authorization to run load test against production

**Details:**
- Endpoint: https://api.prod.example.com/health (read-only)
- Duration: 30 minutes
- Concurrency: 10 users (low impact)
- Scheduled: 2025-01-09 02:00 AM UTC (lowest traffic period)
- Monitoring: DataDog alerts enabled, on-call engineer ready

**Risk Assessment:**
- Risk Level: Low (health endpoint, off-peak hours, low concurrency)
- Rollback Plan: Kill test immediately if CPU > 80% or error rate > 1%

**Approval Required From:**
- [ ] CTO
- [ ] VP Engineering
- [ ] SRE Lead

**Status:** PENDING
```

**2. Off-Peak Hours**

```bash
# Check production traffic patterns first
# Use analytics to find lowest traffic time

# Typical safe windows:
# - 2-4 AM in target timezone
# - Weekends (if B2B application)
# - Avoid: Monday mornings, end of month, holiday shopping seasons
```

**3. Progressive Load Testing**

```bash
# DON'T start with full load
# Start small and increase gradually

# Phase 1: Smoke test (1 user)
AB_CONCURRENCY=1 AB_REQUESTS=10 ./slt.sh

# Phase 2: Light load (5 users)
AB_CONCURRENCY=5 AB_REQUESTS=50 ./slt.sh

# Phase 3: Moderate load (10 users)
AB_CONCURRENCY=10 AB_REQUESTS=100 ./slt.sh

# Monitor between each phase
# Only proceed if:
# - Error rate < 0.1%
# - CPU < 70%
# - Response time < 2x normal
```

**4. Active Monitoring**

```bash
# Terminal 1: Run test
./slt.sh

# Terminal 2: Monitor application metrics
watch -n 5 'curl -s https://api.example.com/metrics'

# Terminal 3: Monitor infrastructure
# DataDog, New Relic, CloudWatch, etc.

# Terminal 4: Ready to kill test
ps aux | grep slt
# Be ready to: kill -9 <PID>
```

**5. Communication Plan**

```markdown
# Test Communication Plan

**Before Test (T-30 minutes):**
- [ ] Notify #engineering Slack channel
- [ ] Notify on-call engineer
- [ ] Set status page: "Scheduled maintenance testing"

**During Test:**
- [ ] Monitor #alerts channel
- [ ] Update team every 10 minutes

**After Test:**
- [ ] Share results in #engineering
- [ ] Clear status page
- [ ] Document any issues encountered

**Emergency Stop Conditions:**
- CPU > 80%
- Error rate > 1%
- Customer complaints
- Any production incident
```

✅ **Safer Alternatives to Production Testing:**

**1. Production Replica**

```bash
# Test against production replica/clone
# Identical infrastructure, isolated from real traffic

echo "DYNAMIC_PAGE=https://prod-replica.example.com/api/users" > .env
./dlt.sh
```

**2. Staging with Production Data**

```bash
# Use staging environment with production database snapshot
pg_dump production_db | psql staging_db
./dlt.sh
```

**3. Synthetic Monitoring**

```bash
# Use tools that continuously test production
# - Datadog Synthetic Monitoring
# - New Relic Synthetics
# - Pingdom
# These are designed for production use
```

**4. Real User Monitoring (RUM)**

```bash
# Instead of load testing, analyze real user performance
# - Google Analytics
# - Sentry Performance Monitoring
# - Application Performance Monitoring (APM) tools
```

---

## Appendix: Quick Reference

### SLT Command Cheatsheet

```bash
# ========================================
# Basic Usage
# ========================================

# Default test (1000 iterations)
./slt.sh

# Quick test (100 iterations)
ITERATIONS=100 ./slt.sh

# Heavy load test
ITERATIONS=2000 AB_REQUESTS=500 AB_CONCURRENCY=50 ./slt.sh

# ========================================
# Performance Scenarios
# ========================================

# Light testing (development)
ITERATIONS=100 AB_REQUESTS=50 AB_CONCURRENCY=5 ./slt.sh

# Medium testing (staging)
ITERATIONS=500 AB_REQUESTS=200 AB_CONCURRENCY=20 ./slt.sh

# Heavy testing (pre-production)
ITERATIONS=1000 AB_REQUESTS=500 AB_CONCURRENCY=50 ./slt.sh

# Stress testing
ITERATIONS=2000 AB_REQUESTS=1000 AB_CONCURRENCY=100 ./slt.sh

# ========================================
# Timeout Adjustments
# ========================================

# Long timeout (slow endpoints)
AB_TIMEOUT=60 ./slt.sh

# Short timeout (fast endpoints)
AB_TIMEOUT=10 ./slt.sh

# ========================================
# Combined Parameters
# ========================================

# API stress test
ITERATIONS=1500 AB_REQUESTS=1000 AB_CONCURRENCY=100 AB_TIMEOUT=30 ./slt.sh

# Quick smoke test
ITERATIONS=50 AB_REQUESTS=20 AB_CONCURRENCY=5 AB_TIMEOUT=10 ./slt.sh

# ========================================
# Output Management
# ========================================

# View latest summary
cat load_test_results_*/summary_report.md | less

# Check for errors
cat load_test_results_*/error.log

# Archive results
tar -czf slt_$(date +%Y%m%d).tar.gz load_test_results_*/

# Clean old results (keep last 5)
ls -dt load_test_results_* | tail -n +6 | xargs rm -rf
```

### DLT Command Cheatsheet

```bash
# ========================================
# Basic Usage
# ========================================

# Production test (Git-tracked baselines)
echo "APP_ENV=production" > .env
./dlt.sh

# Local development test (local baselines)
echo "APP_ENV=local" > .env
./dlt.sh

# Staging test
echo "APP_ENV=staging" > .env
./dlt.sh

# ========================================
# Result Analysis
# ========================================

# View hypothesis testing report
cat load_test_reports_*/hypothesis_testing_*.md | less

# View full research report
cat load_test_reports_*/research_report_*.md | less

# Check for regressions (exit code 1 if found)
grep -q "REGRESSION" load_test_reports_*/hypothesis_testing_*.md && echo "REGRESSION DETECTED" || echo "NO REGRESSION"

# View system metrics
cat load_test_reports_*/system_metrics.csv | column -t -s,

# ========================================
# Baseline Management
# ========================================

# List all baselines
ls -lh baselines/

# View baseline metadata
cat baselines/metadata.json

# Delete specific baseline (force new baseline creation)
rm baselines/production_baseline_Dynamic_*.csv

# Delete all baselines
rm -rf baselines/*.csv

# ========================================
# Output Management
# ========================================

# Archive report with timestamp
tar -czf load_test_$(date +%Y%m%d_%H%M%S).tar.gz load_test_reports_*/

# Archive specific test
tar -czf commit_a3f9d8c_test.tar.gz load_test_reports_20250108_143022/

# Clean old reports (keep last 10)
ls -dt load_test_reports_* | tail -n +11 | xargs rm -rf

# ========================================
# Git Integration
# ========================================

# After test, commit baselines (production mode only)
git add baselines/
git commit -m "chore: update performance baseline for v2.0"
git push

# Tag baseline for release
git tag -a v2.0-baseline -m "Performance baseline for v2.0"
git push --tags

# ========================================
# Background Execution
# ========================================

# Run in background with log
nohup ./dlt.sh > dlt_$(date +%Y%m%d_%H%M%S).log 2>&1 &
echo $! > dlt.pid

# Monitor progress
tail -f dlt_*.log

# Check if running
ps -p $(cat dlt.pid) && echo "Running" || echo "Completed"

# Stop background test
kill $(cat dlt.pid)
```

### Interpreting Results Cheatsheet

**Performance Metrics:**

| Metric | Excellent | Good | Acceptable | Poor |
|--------|-----------|------|------------|------|
| **CV (Coefficient of Variation)** | < 10% | 10-15% | 15-25% | > 25% |
| **Success Rate** | > 99.5% | 99-99.5% | 95-99% | < 95% |
| **P95 Latency** | < 100ms | 100-200ms | 200-500ms | > 500ms |
| **P99 Latency** | < 200ms | 200-400ms | 400-1000ms | > 1000ms |

**Statistical Metrics:**

| Metric | Interpretation | Decision |
|--------|----------------|----------|
| **p < 0.001** | Very strong evidence | 99.9% confidence |
| **p < 0.01** | Strong evidence | 99% confidence |
| **p < 0.05** | Moderate evidence | 95% confidence (standard threshold) |
| **p < 0.10** | Weak evidence | 90% confidence |
| **p ≥ 0.10** | Insufficient evidence | Accept null hypothesis |


**Effect Size (Cohen's d):**

| |d| Range | Effect Size | Practical Meaning | Recommendation |
|-----------|-------------|-------------------|----------------|
| < 0.2 | Negligible | Not worth effort | Document but don't act |
| 0.2 - 0.5 | Small | Minor improvement | Consider other factors |
| 0.5 - 0.8 | Medium | Meaningful change | Likely worth deploying |
| > 0.8 | Large | Major improvement | Deploy with confidence |


**Decision Matrix:**

| p-value | Cohen's d | Verdict | Action |
|---------|-----------|---------|--------|
| < 0.05 | > 0.8 | ✅ **Strong improvement** | Deploy immediately |
| < 0.05 | 0.5-0.8 | ✅ **Moderate improvement** | Deploy with confidence |
| < 0.05 | 0.2-0.5 | ⚠️ **Small improvement** | Consider context, document |
| < 0.05 | < 0.2 | ⚠️ **Negligible change** | Statistically real but not important |
| ≥ 0.05 | > 0.5 | ⚠️ **Possible Type II error** | Retest with more iterations |
| ≥ 0.05 | < 0.5 | ❌ **No meaningful change** | Accept null hypothesis |


### Common Issues Quick Fix

| Issue | Quick Fix |
|-------|-----------|
| **Locale error** | `LC_NUMERIC=C ./dlt.sh` |
| **No baseline found** | Normal on first run, creates baseline automatically |
| **Git not tracking** | Set `APP_ENV=production` in .env |
| **Test timeout** | Increase `AB_TIMEOUT=60` or reduce `AB_CONCURRENCY=25` |
| **Too many files** | `ulimit -n 10000` |
| **High error rate** | Check app is running: `curl http://localhost:8000/` |
| **Inconsistent results** | Run 3 times, use median result |


### Environment Variables Reference

**SLT (slt.sh):**

```bash
ITERATIONS=1000           # Number of test iterations (default: 1000)
AB_REQUESTS=100           # Requests per iteration (default: 100)
AB_CONCURRENCY=10         # Concurrent users (default: 10)
AB_TIMEOUT=30             # Timeout in seconds (default: 30)
```

**DLT (dlt.sh):**

```bash
APP_ENV=production        # Environment: production|staging|local
LC_NUMERIC=C              # Locale for bc calculations (if needed)

# In .env file:
STATIC_PAGE=https://example.com/
DYNAMIC_PAGE=https://example.com/api/users
API_ENDPOINT=https://example.com/api/v2/posts
```

### File Locations Reference

**SLT Output:**

```
load_test_results_YYYYMMDD_HHMMSS/
├── summary_report.md          # Main report (start here)
├── console_output.log         # Real-time execution log
├── execution.log              # Detailed iteration log
├── error.log                  # Errors only
└── raw_*.txt                  # Raw ApacheBench outputs
```

**DLT Output:**

```
load_test_reports_YYYYMMDD_HHMMSS/
├── research_report_*.md           # Full statistical analysis
├── hypothesis_testing_*.md        # Baseline comparison (start here)
├── system_metrics.csv             # CPU, memory, disk I/O
├── error_log.txt                  # Errors only
├── execution.log                  # Phase-by-phase log
└── raw_data/                      # All ApacheBench outputs
    ├── Static_iter_warmup_*.txt
    ├── Static_iter_rampup_*.txt
    └── Static_iter_sustained_*.txt
```

**DLT Baselines:**

```
# Production mode (APP_ENV=production):
./baselines/
├── production_baseline_Static_20250108.csv
├── production_baseline_Dynamic_20250108.csv
└── metadata.json

# Local/Staging mode (APP_ENV=local):
./.dlt_local/
├── local_baseline_Static_20250108.csv
├── local_baseline_Dynamic_20250108.csv
└── metadata.json
```

### Script Modification Guide

**Edit Test Scenarios:**

```bash
# Both slt.sh and dlt.sh use same format

# slt.sh: Line ~40
# dlt.sh: Line ~64

declare -A SCENARIOS=(
    ["Homepage"]="http://localhost:8000/"
    ["API_Users"]="http://localhost:8000/api/users"
    ["API_Products"]="http://localhost:8000/api/products"
    ["Checkout"]="http://localhost:8000/checkout"
)
```

**Add Authentication Header:**

```bash
# slt.sh: Line ~200
# dlt.sh: Line ~350

# Find:
timeout $TEST_TIMEOUT ab -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1

# Replace with:
timeout $TEST_TIMEOUT ab -H "Authorization: Bearer YOUR_TOKEN" \
  -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
```

**Change Timeout:**

```bash
# slt.sh: Use environment variable
AB_TIMEOUT=60 ./slt.sh

# dlt.sh: Edit script line ~72
TEST_TIMEOUT=60  # Change from 30
```

**Change Concurrency:**

```bash
# slt.sh: Use environment variable
AB_CONCURRENCY=100 ./slt.sh

# dlt.sh: Edit script line ~71
AB_CONCURRENCY=100  # Change from 50
```

---

## Glossary

**ApacheBench (ab)**: Industry-standard HTTP benchmarking tool used by both engines

**Baseline**: Reference performance data from previous test, used for comparison

**Cohen's d**: Standardized measure of effect size; quantifies practical significance

**Coefficient of Variation (CV)**: Ratio of standard deviation to mean; measures stability

**Confidence Interval (CI)**: Range where true population parameter likely lies (e.g., 95% CI)

**Concurrency**: Number of simultaneous users/requests during test

**DLT**: Deep Load Testing - Research-grade engine with statistical rigor

**Effect Size**: Magnitude of difference; practical importance beyond statistical significance

**H₀ (Null Hypothesis)**: Assumption that no real difference exists

**H₁ (Alternative Hypothesis)**: Assumption that a real difference exists

**Iteration**: Single execution of test across all scenarios

**P50/P95/P99**: Percentiles - 50th, 95th, 99th percentile response times

**p-value**: Probability of observing results this extreme if H₀ is true

**Ramp-up**: DLT phase where load gradually increases to observe saturation

**RPS**: Requests Per Second - primary throughput metric

**SLT**: Simple Load Testing - Fast, agile engine for development

**Standard Deviation (SD)**: Measure of variability in results

**Sustained Load**: DLT phase with full concurrency for primary data collection

**Think Time**: Delay between requests to simulate realistic user behavior

**Type I Error**: False positive - rejecting H₀ when it's true (p-value controls this)

**Type II Error**: False negative - failing to reject H₀ when it's false (power controls this)

**Warm-up**: DLT phase to prime application (JIT, caches, connection pools)

**Welch's t-test**: Statistical test for comparing two groups with unequal variances


