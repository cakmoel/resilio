# White Paper: Resilio v6.2.0 — Scientific Load Testing at Scale

**The High-Performance Python-Powered Statistical Engine**

**Author**: M.Noermoehammad  
**Publication Date**: January 6, 2026 (Updated: Jan 9, 2026)  
**Research Domain**: Performance Engineering, Statistical Analysis, System Reliability.  
**Tool Version**: Resilio (SLT v2.1 & DLT v6.2 Engines)

---

## Executive Summary

This white paper introduces **Resilio v6.2.0**, a professional-grade performance engineering toolkit that transforms ApacheBench into a scientifically rigorous load testing framework. Version 6.2.0 represents a major architectural milestone, introducing a **Python-powered mathematical kernel** that delivers an unprecedented **40x speedup** in statistical analysis while enhancing numerical precision.

By integrating established research (Jain, 1991; Barford & Crovella, 1998; Ruxton, 2006) with modern computational tools, Resilio provides actionable performance intelligence. Our latest benchmarks demonstrate how the new engine handles tens of thousands of test iterations with sub-second analysis latency, making it the most robust open-source "research-first" testing suite available.

### Key Achievements in v6.2.0:
*   **Python Math Kernel**: Replaced legacy Bash-based calculations with a high-performance Python engine.
*   **Automated Test Selection**: Intelligent detection of data normality to switch between **Welch’s t-test** and **Mann-Whitney U**.
*   **Effect Size Quantification**: Implementation of **Cohen’s d** and **Rank-Biserial Correlation** for deep statistical insight.
*   **40x Faster Analysis**: Analysis of 10,000 iterations reduced from ~10 minutes to <15 seconds.

---

## 1. Introduction: The Performance Engineering Challenge

### 1.1 The Problem with Traditional Load Testing
Most development teams approach load testing with ad-hoc scripts or manual ApacheBench commands. These lack methodological rigor, leading to:
*   **Statistical Invalidity**: Small samples (n<30) violate the Central Limit Theorem.
*   **Transient Effects**: Cold-start measurements contaminate steady-state analysis.
*   **Average Blindness**: Mean response times mask the "long tail" of user dissatisfaction.

### 1.2 The Resilio Solution (v6.2.0)
Resilio addresses these through two specialized engines, now unified by the **Python Statistical Engine (lib/stats.py)**:

*   **Resilio SLT (v2.1)**: Rapid, statistically valid feedback (Mean, Median, CV, P95) for Agile/CI cycles.
*   **Resilio DLT (v6.2)**: Deep analysis using a three-phase methodology (Warm-up, Ramp-up, Sustained) with full hypothesis testing and 95% Confidence Intervals.

---

## 2. Research Foundation & Methodology

### 2.1 The Kernel: Python-Powered Statistics
In version 6.2.0, Resilio moved its mathematical heavy lifting from `bc` (Bash Calculator) to a dedicated Python backend. This shift allows for more complex statistical models:
*   **Welch’s t-test**: Used for comparing normally distributed data with unequal variances (Welch, 1947). This replaces the older, less precise Z-test methodology.
*   **Mann-Whitney U**: Leveraged when data is non-normal or skewed, ensuring resilience to outliers without assuming a normal distribution.
*   **P-Value Approximations**: Automatic calculation of statistical significance (p < 0.05), removing the need for manual Z-score table lookups.
*   **Effect Size Quantification**: Implementation of **Cohen’s d** and **Rank-Biserial Correlation** to quantify the magnitude of difference, providing context beyond just "significant" or "not significant."
*   **Normality Detection**: Automatic skewness and kurtosis analysis to select the appropriate test (Parametric vs. Non-Parametric).

### 2.2 Three-Phase DLT Methodology
1.  **Warm-up (discarded)**: Primes JIT compilers and caches (Lilja, 2005).
2.  **Ramp-up**: Identifies the "knee of the curve" where system saturation begins.
3.  **Sustained Load**: Captures high-n data for 95% Confidence Interval (CI) calculations.

---

## 3. Case Study: Architectural Performance Analysis

Using Resilio v6.2.0, we compared a **Custom PHP MVC** against **ExpressionEngine CMS**. The DLT engine quantified the architectural overhead with research-grade precision:

### 3.1 Throughput and Stability
| Metric | Custom MVC | ExpressionEngine | Delta |
|--------|------------|-----------------|-------|
| Median RPS | 52.43 | 11.41 | **+359%** |
| Stability (CV) | 8.8% (Exc) | 14.7% (Good) | **+40%** |

### 3.2 Tail Latency Percentiles
*   **P95 Latency**: Custom MVC (303ms) vs ExpressionEngine (1,196ms).
*   **P99 Latency**: Custom MVC (752ms) vs ExpressionEngine (1,855ms).
Resilio Insight: ExpressionEngine’s tail latency exceeds the Google Core Web Vitals 1s threshold, whereas the Custom MVC remains sub-second even at the 99th percentile.

---

## 4. Business Impact and Infrastructure ROI

Resilio's performance data translates directly to infrastructure requirements:

*   **Infrastructure Cost**: Supporting 1,000 users requires 2 servers for Custom MVC vs 9 servers for ExpressionEngine.
*   **Annual Savings**: Based on AWS t3.medium pricing, the optimized architecture identifies **$2,520 USD in annual savings** per cluster.
*   **SEO & UX**: Converting technical latency to business outcomes, Resilio confirms the Custom MVC handles 4.3x more traffic within the "Excellent" PageSpeed boundaries.

---

## 5. Technology-Agnostic Design

Resilio operates at the **HTTP Protocol Layer (L7 Audit)**, making it independent of the server-side language:
*   **PHP**: Laravel, Symfony, WordPress, Drupal.
*   **Node.js**: Express, Fastify, Next.js.
*   **Python**: Django, Flask, FastAPI.
*   **Go/Rust/Java/.NET**: High-concurrency compiled backends.

---

## 6. Conclusions

Performance engineering transforms from an "art" to a science when measurements are rigorous, methodology is research-based, and results are actionable. **Resilio v6.2.0** democratizes this science by providing enterprise-grade statistical analysis in a lightweight, transparent toolkit.

Whether you are planning infrastructure for 10x traffic growth or benchmarking a microservices migration, Resilio provides the objective data required for confident architectural decisions.

---

## 7. References

*   **Jain, R. (1991)**. *The Art of Computer Systems Performance Analysis*. Wiley.
*   **Barford, P., & Crovella, M. (1998)**. *Generating Representative Web Workloads*. SIGMETRICS.
*   **Ruxton, G. D. (2006)**. *The unequal variance t-test is an underused alternative to Student's t-test and the Mann–Whitney U test*. Behavioral Ecology.
*   **Gregg, B. (2013)**. *Systems Performance: Enterprise and the Cloud*. Prentice Hall.

---

**Contact & Resources**:
*   **GitHub**: [Resilio Repository](https://github.com/cakmoel/resilio)
*   **Documentation**: [Resilio USAGE_GUIDE.md](file:///var/www/html/load-tester/docs/USAGE_GUIDE.md)
*   **Technical Blog**: [scriptlog.my.id](https://scriptlog.my.id)

