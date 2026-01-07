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