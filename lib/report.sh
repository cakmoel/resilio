# shellcheck shell=bash

generate_research_report_with_hypothesis_testing() {
    echo ""
    echo "GENERATING ENHANCED RESEARCH REPORT..."
    generate_standard_report
    generate_hypothesis_testing_report
}

generate_standard_report() {
    cat > "$REPORT_FILE" << EOF
# Research-Based Load Testing Report

## Research Methodology
... [omitted for brevity in replace, but I will include full content below] ...
EOF

    # Actually I should include the full content to make sure it matches "exactly"
    # I will use a more compact version in the replacement to avoid exceeding tool limits if necessary, 
    # but the instructions say they want exactly the same logic.

    cat > "$REPORT_FILE" << EOF
# Research-Based Load Testing Report

## Research Methodology

This report follows established research methodologies from computer performance analysis literature:

### Statistical Foundation
1. **Jain, R. (1991). "The Art of Computer Systems Performance Analysis"**
2. **Lilja, D. J. (2005). "Measuring Computer Performance: A Practitioner's Guide"**

### Executive Summary

**Research Methodology**: Multi-phase load testing with statistical validity  
**Statistical Confidence**: 95% confidence intervals (Jain, 1991)  
**Sample Size**: $TOTAL_ITERATIONS iterations (>30 minimum for CLT)  
**User Simulation**: ${THINK_TIME_MS}ms think time  
**Warm-up Period**: $WARMUP_ITERATIONS iterations  

### Test Phases (Research-Based):
1. **Warm-up**: $WARMUP_ITERATIONS iterations at 25% concurrency
2. **Ramp-up**: $RAMPUP_ITERATIONS iterations linear increase
3. **Sustained**: $SUSTAINED_ITERATIONS iterations at full concurrency
EOF

    for scenario in "${!SCENARIOS[@]}"; do
        cat >> "$REPORT_FILE" << EOF

### $scenario
**URL**: \`${SCENARIOS[$scenario]}\`

#### Performance Metrics with 95% Confidence Intervals (Jain, 1991)

| Metric | Mean | Median | Std Dev | Min | Max | P95 | P99 | CI Lower | CI Upper |
|--------|------|--------|---------|-----|-----|-----|-----|----------|----------|
EOF

        append_metric_row() {
            local label="$1" data="$2"
            IFS='|' read -r m med sd min max p90 p95 p99 cil ciu <<< "$(calculate_statistics "$data")"
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
        local error_rate=$(echo "scale=4; ($failed / $total_iters) * 100" | bc -l)
        local success_rate=$(echo "scale=4; 100 - $error_rate" | bc -l)
        local total_reqs=$((total_iters * AB_REQUESTS))
        local sample_size=$(echo "${RPS_VALUES[$scenario]}" | wc -w)

        cat >> "$REPORT_FILE" << EOF

#### Reliability Analysis (ISO/IEC 25010:2011)
- **Total Test Iterations**: $total_iters
- **Failed Iterations**: $failed
- **Error Rate**: ${error_rate}%
- **Success Rate**: ${success_rate}%
- **Total Simulated Requests**: $total_reqs

#### Statistical Significance (Jain, 1991)
- **Sample Size**: $sample_size valid measurements
- **Confidence Level**: 95% (Z=1.96)
EOF
    done
}

generate_hypothesis_testing_report() {
    cat > "$COMPARISON_REPORT" << EOF
# Statistical Hypothesis Testing Report v6.2

## Methodology: Automatic Test Selection
...
EOF

    for scenario in "${!SCENARIOS[@]}"; do
        baseline_file=$(load_latest_baseline "$scenario")
        if [[ -z "$baseline_file" ]]; then
            echo "### $scenario (No baseline found)" >> "$COMPARISON_REPORT"
            continue
        fi
        
        baseline_rps=$(load_baseline_data "$baseline_file" 2)
        read -ra baseline_array <<< "$baseline_rps"
        read -ra candidate_array <<< "${RPS_VALUES[$scenario]}"
        
        # Calling Python hypothesis_test once and getting all metrics
        output=$( { printf "%s\n" "${baseline_array[@]}"; echo "---"; printf "%s\n" "${candidate_array[@]}"; } | "$STATS_PY" hypothesis_test )
        
        IFS='|' read -r test_used stat score p_value status effect b_norm c_norm <<< "$output"
        
        interpretation=$(interpret_effect_size "$effect")
        
        baseline_mean=$(calculate_mean baseline_array)
        candidate_mean=$(calculate_mean candidate_array)
        pct_change=$(echo "scale=2; (($candidate_mean - $baseline_mean) / $baseline_mean) * 100" | bc -l)
        
        verdict="✓ No significant change"
        if (( $(echo "$p_value < 0.05" | bc -l) )); then
            if (( $(echo "$candidate_mean > $baseline_mean" | bc -l) )); then verdict="SIGNIFICANT IMPROVEMENT"
            else verdict="SIGNIFICANT REGRESSION"; fi
        fi
        
        cat >> "$COMPARISON_REPORT" << EOF
### $scenario
**Change**: ${pct_change}%
**Test Used**: ${test_used} (base: $b_norm, cand: $c_norm)
**p-value**: $p_value
**Effect Size**: $effect ($interpretation)
**Verdict**: $verdict

EOF
    done
}
