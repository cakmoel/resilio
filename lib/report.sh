# shellcheck shell=bash

generate_research_report_with_hypothesis_testing() {
    echo ""
    echo "GENERATING ENHANCED RESEARCH REPORT..."
    generate_standard_report
    generate_hypothesis_testing_report
}

generate_standard_report() {
    cat > "$REPORT_FILE" << EOF_INNER
# Research-Based Load Testing Report

## Research Methodology

This report follows established research methodologies from computer performance analysis literature:

### Statistical Foundation
1. **Jain, R. (1991). "The Art of Computer Systems Performance Analysis"**
2. **Lilja, D. J. (2005). "Measuring Computer Performance: A Practitioner's Guide"**

### Executive Summary

**Research Methodology**: Multi-phase load testing with statistical validity  
**Statistical Confidence**: 95% confidence intervals (Jain, 1991)  
**Sample Size**: ${TOTAL_ITERATIONS} iterations (>30 minimum for CLT)  
**User Simulation**: ${THINK_TIME_MS}ms think time  
**Warm-up Period**: ${WARMUP_ITERATIONS} iterations  

### Test Phases (Research-Based):
1. **Warm-up**: ${WARMUP_ITERATIONS} iterations at 25% concurrency
2. **Ramp-up**: ${RAMPUP_ITERATIONS} iterations linear increase
3. **Sustained**: ${SUSTAINED_ITERATIONS} iterations at full concurrency
EOF_INNER

    for scenario in "${!SCENARIOS[@]}"; do
            cat >> "$REPORT_FILE" << EOF_INNER

### $scenario
**URL**: <!-- shellcheck disable=SC2006 -->
```
${SCENARIOS[$scenario]}
```

#### Performance Metrics with 95% Confidence Intervals (Jain, 1991)

| Metric | Mean | Median | Std Dev | Min | Max | P95 | P99 | CI Lower | CI Upper |
|--------|------|--------|---------|-----|-----|-----|-----|----------|----------|
EOF_INNER

        append_metric_row() {
            local label="$1" data="$2"
            IFS='|' read -r m med sd min max _ p95 p99 cil ciu <<< "$(calculate_statistics "$data")" # p90 removed as unused
            echo "| **$label** | $m | $med | $sd | $min | $max | $p95 | $p99 | $cil | $ciu |" >> "$REPORT_FILE"
        }

        append_metric_row "RPS (req/s)" "${RPS_VALUES[$scenario]}"
        append_metric_row "Response Time (ms)" "${RESPONSE_TIME_VALUES[$scenario]}"
        append_metric_row "P95 Latency (ms)" "${P95_VALUES[$scenario]}"
        append_metric_row "P99 Latency (ms)" "${P99_VALUES[$scenario]}"
        append_metric_row "Connection Time (ms)" "${CONNECT_VALUES[$scenario]}"
        append_metric_row "Processing Time (ms)" "${PROCESSING_VALUES[$scenario]}"

        local total_iters=$((RAMPUP_ITERATIONS + SUSTAINED_ITERATIONS))
        local failed=${ERROR_COUNTS[$scenario]}
        local error_rate
        error_rate=$(echo "scale=4; ($failed / $total_iters) * 100" | bc -l)
        local success_rate
        success_rate=$(echo "scale=4; 100 - $error_rate" | bc -l)
        local total_reqs=$((total_iters * AB_REQUESTS))
        local sample_size
        sample_size=$(echo "${RPS_VALUES[$scenario]}" | wc -w)

        cat >> "$REPORT_FILE" << EOF_INNER

#### Reliability Analysis (ISO/IEC 25010:2011)
- **Total Test Iterations**: $total_iters
- **Failed Iterations**: $failed
- **Error Rate**: ${error_rate}%
- **Success Rate**: ${success_rate}%
- **Total Simulated Requests**: $total_reqs

#### Statistical Significance (Jain, 1991)
- **Sample Size**: $sample_size valid measurements
- **Confidence Level**: 95% (Z=1.96)
EOF_INNER
    done
}

generate_hypothesis_testing_report() {
    cat > "$COMPARISON_REPORT" << EOF_INNER
# Statistical Hypothesis Testing Report v6.2

## Methodology: Automatic Test Selection
This report details the statistical hypothesis tests performed to compare the performance of the current system against a defined baseline. The appropriate statistical test (Welch's t-test or Mann-Whitney U test) is automatically selected based on the characteristics of the data (sample size, skewness, kurtosis) following recommendations from computer performance analysis literature (Jain, 1991; Lilja, 2005).

- **Welch's t-test**: Used for approximately normally distributed data with sufficient sample size (n >= 30). It is robust to unequal variances.
- **Mann-Whitney U test**: A non-parametric alternative used when data is not normally distributed or sample sizes are small (n < 30).

### Key Metrics and Interpretation
- **p-value**: The probability of observing a test statistic as extreme as, or more extreme than, the one observed, assuming the null hypothesis (no difference between current and baseline performance) is true.
    - **p < 0.05**: Statistically significant difference.
- **Effect Size**: Quantifies the magnitude of the difference between the two groups (current and baseline).
    - **Cohen's d (for Welch's t-test)**:
        - negligible: < 0.2
        - small: < 0.5
        - medium: < 0.8
        - large: >= 0.8
    - **Rank Biserial Correlation (for Mann-Whitney U test)**:
        - negligible: < 0.1
        - small: < 0.3
        - medium: < 0.5
        - large: >= 0.5

## Comparison Results
EOF_INNER

    for scenario in "${!SCENARIOS[@]}"; do
        local baseline_file
        baseline_file=$(load_latest_baseline "$scenario")
        if [[ -z "$baseline_file" ]]; then
            echo "### $scenario (No baseline found)" >> "$COMPARISON_REPORT"
            continue
        fi
        
        local baseline_rps
        baseline_rps=$(load_baseline_data "$baseline_file" 2)
        read -ra baseline_array <<< "$baseline_rps"
        read -ra candidate_array <<< "${RPS_VALUES[$scenario]}"
        
        # Calling Python hypothesis_test once and getting all metrics
        local output
        output=$( { printf "%s\n" "${baseline_array[@]}"; echo "---"; printf "%s\n" "${candidate_array[@]}"; } | "$STATS_PY" hypothesis_test )
        
        IFS='|' read -r test_used _ _ p_value _ effect b_norm c_norm <<< "$output" # stat, score, status removed as unused
        
        local interpretation
        interpretation=$(interpret_effect_size "$effect")
        
        local baseline_mean
        baseline_mean=$(calculate_mean baseline_array)
        local candidate_mean
        candidate_mean=$(calculate_mean candidate_array)
        local pct_change
        pct_change=$(echo "scale=2; (($candidate_mean - $baseline_mean) / $baseline_mean) * 100" | bc -l)
        
        local verdict="✓ No significant change"
        if (( $(echo "$p_value < 0.05" | bc -l) )); then
            if (( $(echo "$candidate_mean > $baseline_mean" | bc -l) )); then verdict="SIGNIFICANT IMPROVEMENT"
            else verdict="SIGNIFICANT REGRESSION"; fi
        fi
        
        cat >> "$COMPARISON_REPORT" << EOF_INNER
### $scenario
**Change**: ${pct_change}%
**Test Used**: ${test_used} (base: $b_norm, cand: $c_norm)
**p-value**: $p_value
**Effect Size**: $effect ($interpretation)
**Verdict**: $verdict

EOF_INNER
    done
}