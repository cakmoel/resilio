Resilio: Statistical Methodology for Performance Auditing

This document outlines the mathematical framework and metric definitions used by the Resilio toolkit to ensure load testing results are reproducible, scientifically valid, and statistically significant.
1. Throughput & Central Tendency

To understand the "Typical" vs. "Average" performance, Resilio calculates two primary throughput metrics:

    Average RPS (Arithmetic Mean): The sum of all successful requests divided by total time. While useful, it can be skewed by significant outliers.

    Median RPS (P50): The middle value of the data set. In the Resilio case study, the Custom PHP MVC achieved a Median RPS of 52.43 vs. ExpressionEngine's 11.41, proving a +359.5% gain in typical user throughput.

2. Stability & Jitter Analysis

Performance is not just about speed; it is about consistency. We use the Coefficient of Variation (CV) to measure "Performance Jitter":

    Custom PHP MVC: Achieved a CV of 8.8% (Classified as: Excellent).

    ExpressionEngine: Achieved a CV of 14.7% (Classified as: Good).

    Significance: A lower CV indicates a more deterministic system with fewer background resource contentions.

3. Tail Latency Percentiles (P95/P99)

Average response times hide the "long tail" of user dissatisfaction. Resilio measures the thresholds for the slowest users:

    P95 Latency: The threshold where 5% of users experience slower responses. For the Custom MVC, this was 303.04 ms , compared to 1195.57 ms for the CMS.

    P99 Latency: Captured to identify severe infrastructure bottlenecks like Garbage Collection pauses. The CMS spiked to 1855 ms under load , while the Custom MVC stayed at 752 ms.

4. 95% Confidence Interval (CI)

To ensure that a test run is not just a "lucky" anomaly, Resilio calculates the Confidence Interval for the mean RPS:

CI = x̄ ± (1.96 × (σ ÷ √n))
Where:

    x̄ = sample mean (Mean RPS in our case study)
    σ = population standard deviation
    n = sample size (1,000 iterations in our case study)
    1.96 = Z-score for 95% confidence level

Case Study Specifics:

    x̄: Mean Requests Per Second (RPS)
    1.96: Z-score for 95% confidence level
    σ: Standard Deviation of RPS measurements
    n: Number of test iterations (1,000 iterations)

5. Summary of Empirical Evidence

Based on 100,000 requests per scenario, the delta between architectures is quantified as:
Architecture 	Median RPS 	P95 Latency 	Stability (CV)
Custom PHP MVC 	52.43 	303.04 ms 	8.8%
ExpressionEngine 	11.41 	1195.57 ms 	14.7%
Variance (Delta) 	+359.5% 	-74.6% 	-40.1%
