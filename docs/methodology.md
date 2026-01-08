# Resilio: Statistical Methodology (Normative)

This document defines the binding statistical methodology used by the
Resilio / DLT performance auditing toolkit. Any deviation between
implementation and this document is considered a defect.

---

## 1. Central Tendency

- Arithmetic Mean is reported for throughput averages.
- Median (P50) is reported as the typical user experience.
- Mean is never interpreted without dispersion metrics.

---

## 2. Stability & Variability

Performance stability is measured using the Coefficient of Variation (CV):

CV = σ / x̄

Lower CV indicates a more deterministic system with reduced jitter.

---

## 3. Tail Latency Percentiles

Percentiles (P95, P99) are computed using a discrete index method:

index = ⌊p × (n − 1)⌋ + 1

Where:
- p is the percentile expressed as a fraction
- n is the sample size

This definition is consistent with Jain (1991) and is preferred in
performance engineering to avoid optimistic tail inflation in small samples.

---

## 4. Confidence Interval (95%)

The 95% confidence interval for the mean throughput is computed as:

CI = x̄ ± (1.96 × (σ / √n))

Where:
- x̄ = sample mean
- σ = sample standard deviation
- n = sample size
- 1.96 = Z-score for 95% confidence

---

## 5. Statistical Test Selection

Resilio selects statistical tests as follows:

- Welch’s t-test is used when:
  - n ≥ 30
  - skewness and kurtosis are within moderate bounds

- Mann–Whitney U test is used when:
  - n < 30
  - skewness or kurtosis indicate severe non-normality

This strategy follows Ruxton (2006) and avoids unnecessary loss of
statistical power.

---

## 6. Reproducibility Contract

- All metrics must be derivable from raw samples.
- Percentile, CI, and test-selection behavior must not change without
  an explicit methodology revision.
