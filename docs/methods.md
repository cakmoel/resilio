Below is a **paper-ready “Methods” section**, written in a **neutral IEEE / ACM style**, suitable for submission or as a technical appendix.
No marketing language, no assumptions, no over-claims.

---

# Methods

## Experimental Design

Performance measurements were conducted using **Resilio**, a load-testing and statistical auditing toolkit designed to ensure reproducibility and statistical validity. Each experiment consisted of repeated load test iterations against the system under test under controlled conditions. All tests were executed on identical hardware and software configurations to eliminate environmental confounders.

Each scenario consisted of a fixed workload definition (request type, concurrency level, and think time). For each scenario, a large number of requests (≥100,000 total) were issued to ensure sufficient statistical power.

A warm-up phase was applied to remove transient startup effects. Samples collected during the warm-up phase were discarded prior to analysis.

---

## Data Collection

Raw response time and throughput samples were collected per iteration. Each iteration produced a single aggregate throughput measurement (requests per second) and a distribution of response times. All reported metrics were derived exclusively from these raw samples, ensuring full traceability.

---

## Central Tendency Metrics

Two measures of central tendency were reported:

* **Arithmetic Mean (Mean RPS):** Used to estimate average throughput across iterations.
* **Median (P50):** Used to represent the typical user experience and reduce sensitivity to outliers.

The median was preferred for comparative interpretation, while the mean was used for inferential statistics.

---

## Variability and Stability Analysis

Performance stability was quantified using the **Coefficient of Variation (CV)**:

[
CV = \frac{\sigma}{\bar{x}}
]

where (\sigma) is the sample standard deviation and (\bar{x}) is the sample mean. Lower CV values indicate more deterministic system behavior and reduced performance jitter.

---

## Tail Latency Analysis

To capture worst-case user experience, tail latency percentiles were computed:

* **P95**: 95th percentile response time
* **P99**: 99th percentile response time

Percentiles were computed using a **discrete index method**:

[
\text{index} = \lfloor p \times (n - 1) \rfloor + 1
]

where (p) is the percentile expressed as a fraction and (n) is the sample size. This method is commonly used in performance engineering and avoids optimistic tail inflation in small samples.

---

## Confidence Intervals

To quantify measurement uncertainty, a **95% confidence interval (CI)** for the mean throughput was computed as:

[
CI = \bar{x} \pm 1.96 \times \frac{\sigma}{\sqrt{n}}
]

where:

* (\bar{x}) is the sample mean,
* (\sigma) is the sample standard deviation,
* (n) is the number of iterations,
* 1.96 is the Z-score corresponding to a 95% confidence level.

This interval estimates the range within which the true mean throughput is expected to lie with 95% confidence.

---

## Statistical Test Selection

To compare performance metrics between systems, Resilio automatically selected statistical tests based on sample size and distribution characteristics:

* **Welch’s t-test** was used when:

  * sample size (n \geq 30), and
  * skewness and kurtosis indicated only mild deviations from normality.

* **Mann–Whitney U test** was used when:

  * sample size (n < 30), or
  * severe non-normality was detected.

This approach follows the recommendations of Ruxton (2006), which demonstrate that Welch’s t-test is robust to moderate deviations from normality and avoids unnecessary loss of statistical power.

---

## Reproducibility and Validation

All statistical computations were implemented as deterministic functions and validated using automated unit tests. The statistical behavior of the toolkit is contractually bound to its documented methodology, preventing silent methodological drift across versions.

All results reported in this study are reproducible from the recorded raw samples and configuration parameters.

---

