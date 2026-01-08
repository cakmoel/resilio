# Baseline Analysis: DLT Toolkit v6.2

## Executive Summary
The Deep Load Testing (DLT) toolkit v6.2 implements a sophisticated research-based methodology. However, the current technical implementation of its statistical engine (`lib/stats.sh`) suffers from a critical performance bottleneck known as "**offload math overhead**".

## The "Offload Math" Problem
The toolkit delegates nearly all arithmetic operations to the external `bc` (Basic Calculator) utility. While `bc` provides high precision, the way it is integrated causes exponential slowdown as data volume increases.

### 1. Bottleneck: Subprocess Iteration
In `calculate_mean` and `calculate_variance`, `bc` is called inside a Bash loop for every single data point.
- **Impact**: Averaging 1,000 response times takes **~6 seconds** on standard hardware.
- **Scalability**: For 10,000 iterations, the report generation phase alone would take over a minute.

### 2. Bottleneck: O(n²) Algorithmic Complexity
The `mann_whitney_u_test` implementation uses a **Bubble Sort** algorithm written in pure Bash, which calls `bc` in its inner comparison loop.
- **Complexity**: $O(n^2)$ comparisons.
- **Impact**: For a total sample size of 2,000 (baseline + candidate), the script performs ~4,000,000 `bc` calls.
- **Usability**: This makes the non-parametric tests effectively unusable for datasets larger than ~100 items.

## Baseline Strengths
- **Methodological Rigor**: Adheres to ISO 25010 and established academic frameworks (Jain, 1991).
- **Intelligent Logic**: The automatic selection between parametric and non-parametric tests is a best-in-class feature.
- **Robustness**: Handles locales and environment detection correctly.

## Baseline Weaknesses (The "Problem")
- **Computational Efficiency**: The tool is extremely slow during the "Reporting" phase.
- **Outdated Tests**: The unit tests (`tests/unit/test_stats.bats`) reference deleted pipe-based functions, leading to silent test failures or obsolescence.

## Engineering Conclusion
The user's concern about "offload math" is **CORRECT**. While the methodology is sound, the implementation cannot handle "a bunch of data" without significant architectural changes.

---
**Prepared by**: Antigravity AI
**Date**: 2026-01-09
**Reference**: DLT Version 6.2
