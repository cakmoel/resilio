#!/bin/bash

# =============================================================================
# File: slt.sh
# Author: M.Noermoehammad
# Improved Simple Load Testing(slt) Script
# License: MIT License
# Version: 2.0
# 
# Improvements over v1.0:
# - Maintains original simple logic and workflow
# - Adds error tracking without breaking existing calculations
# - Preserves output to file for audit trail
# - Adds percentile calculations (P50, P95, P99)
# - Includes standard deviation for stability measurement
# - Better error handling without silent failures
# - Configurable parameters via environment variables
# - Backward compatible with v1.0 usage
# =============================================================================

set -euo pipefail

# Force English locale for consistent number formatting
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"

# --- Configuration (can be overridden via environment variables) ---
ITERATIONS=${ITERATIONS:-1000}
AB_REQUESTS=${AB_REQUESTS:-100}
AB_CONCURRENCY=${AB_CONCURRENCY:-10}
AB_TIMEOUT=${AB_TIMEOUT:-30}

# Output directory for results
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="./load_test_results_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"

# Define the test scenarios: [Scenario Name]="URL"
declare -A SCENARIOS=(
    ["Static"]="http://myblog.local/login"
    ["Dynamic"]="http://myblog.local/your-post-detail-here"
    ["404_Not_Found"]="http://myblog.local/this-page-is-not-real"
)

# Initialize error tracking arrays
declare -A ERROR_COUNTS
declare -A SUCCESS_COUNTS

# --- Logging Functions ---
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${OUTPUT_DIR}/execution.log"
}

log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${OUTPUT_DIR}/error.log"
    echo "  $1" >&2
}

# --- Function to Run a Single Test ---
run_ab_test() {
    local url=$1
    local scenario=$2
    local iteration=$3
    local temp_file="${OUTPUT_DIR}/raw_${scenario}_${iteration}.txt"
    
    # Run 'ab' with timeout and capture full output
    if timeout $AB_TIMEOUT ab -n $AB_REQUESTS -c $AB_CONCURRENCY "$url" > "$temp_file" 2>&1; then
        # Check if 'ab' returned a valid requests per second value
        if grep -q "Requests per second:" "$temp_file"; then
            local rps=$(grep "Requests per second:" "$temp_file" | awk '{print $4}')
            
            # Extract additional metrics (non-breaking addition)
            local time_per_req=$(grep "Time per request:" "$temp_file" | head -1 | awk '{print $4}' || echo "0")
            local failed=$(grep "Failed requests:" "$temp_file" | awk '{print $3}' || echo "0")
            
            # Extract percentiles if available
            local p50=$(grep -A 10 "Percentage" "$temp_file" | grep "50%" | awk '{print $2}' || echo "0")
            local p95=$(grep -A 10 "Percentage" "$temp_file" | grep "95%" | awk '{print $2}' || echo "0")
            local p99=$(grep -A 10 "Percentage" "$temp_file" | grep "99%" | awk '{print $2}' || echo "0")
            
            log_to_file "SUCCESS: $scenario iteration $iteration - RPS: $rps, P95: ${p95}ms"
            
            # Return metrics in parseable format
            echo "SUCCESS|$rps|$time_per_req|$failed|$p50|$p95|$p99"
            return 0
        else
            log_error "No RPS data found for $scenario iteration $iteration"
            echo "FAILED|0|0|0|0|0|0"
            return 1
        fi
    else
        log_error "Test timeout or execution failed for $scenario iteration $iteration"
        echo "FAILED|0|0|0|0|0|0"
        return 1
    fi
}

# --- Statistical Calculation Functions ---
calculate_statistics() {
    local -n values_ref=$1
    local count=${#values_ref[@]}
    
    if [ $count -eq 0 ]; then
        echo "0|0|0|0|0|0|0|0"
        return
    fi
    
    # Sort values for percentile calculations
    local sorted=($(printf '%s\n' "${values_ref[@]}" | sort -n))
    
    # Calculate sum
    local sum=0
    for val in "${sorted[@]}"; do
        sum=$(echo "$sum + $val" | bc -l)
    done
    
    # Calculate mean (preserves original logic)
    local mean=$(echo "scale=3; $sum / $count" | bc -l)
    
    # Calculate median
    local middle=$((count / 2))
    if (( count % 2 == 1 )); then
        local median=${sorted[$middle]}
    else
        local median=$(echo "scale=3; (${sorted[$((middle-1))]} + ${sorted[$middle]}) / 2" | bc -l)
    fi
    
    # Calculate standard deviation (NEW: stability metric)
    local variance=0
    for val in "${sorted[@]}"; do
        local diff=$(echo "$val - $mean" | bc -l)
        variance=$(echo "$variance + ($diff * $diff)" | bc -l)
    done
    variance=$(echo "scale=3; $variance / $count" | bc -l)
    local std_dev=$(echo "scale=3; sqrt($variance)" | bc -l)
    
    # Calculate percentiles (NEW: tail latency metrics)
    local p50_idx=$((count * 50 / 100))
    local p95_idx=$((count * 95 / 100))
    local p99_idx=$((count * 99 / 100))
    
    local p50=${sorted[$p50_idx]:-0}
    local p95=${sorted[$p95_idx]:-0}
    local p99=${sorted[$p99_idx]:-0}
    
    # Calculate min and max
    local min=${sorted[0]}
    local max=${sorted[-1]}
    
    echo "$mean|$median|$std_dev|$min|$max|$p50|$p95|$p99"
}

# --- Main Testing Logic ---
main() {
    echo "======================================================================"
    echo "Starting Improved Performance Testing"
    echo "======================================================================"
    echo "Configuration:"
    echo "  - Iterations per scenario: $ITERATIONS"
    echo "  - Requests per test: $AB_REQUESTS"
    echo "  - Concurrency level: $AB_CONCURRENCY"
    echo "  - Test timeout: ${AB_TIMEOUT}s"
    echo "  - Output directory: $OUTPUT_DIR"
    echo "======================================================================"
    echo ""
    
    # Redirect all output to both console and file
    exec > >(tee "${OUTPUT_DIR}/console_output.log")
    exec 2>&1
    
    # Initialize result storage
    declare -A RPS_VALUES
    declare -A RESPONSE_TIME_VALUES
    declare -A P95_VALUES
    declare -A P99_VALUES
    
    for name in "${!SCENARIOS[@]}"; do
        RPS_VALUES[$name]=""
        RESPONSE_TIME_VALUES[$name]=""
        P95_VALUES[$name]=""
        P99_VALUES[$name]=""
        ERROR_COUNTS[$name]=0
        SUCCESS_COUNTS[$name]=0
    done
    
    local start_time=$(date +%s)
    
    # Loop through the defined number of iterations
    for (( i=1; i<=$ITERATIONS; i++ )); do
        echo "--- Iteration $i of $ITERATIONS ---"
        
        # Loop through each scenario
        for name in "${!SCENARIOS[@]}"; do
            url=${SCENARIOS[$name]}
            
            # Run the test and parse results
            result=$(run_ab_test "$url" "$name" "$i")
            
            IFS='|' read -r status rps time_req failed p50 p95 p99 <<< "$result"
            
            if [ "$status" = "SUCCESS" ]; then
                # Store successful results (preserves original logic)
                RPS_VALUES[$name]+="$rps "
                RESPONSE_TIME_VALUES[$name]+="$time_req "
                P95_VALUES[$name]+="$p95 "
                P99_VALUES[$name]+="$p99 "
                SUCCESS_COUNTS[$name]=$((SUCCESS_COUNTS[$name] + 1))
                
                printf " %-20s: %7.2f req/s (Response: %6.1fms, P95: %6.1fms)\n" \
                    "$name" "$rps" "$time_req" "$p95"
            else
                # Track errors separately (NEW: no longer adds 0 to averages)
                ERROR_COUNTS[$name]=$((ERROR_COUNTS[$name] + 1))
                printf " %-20s: FAILED\n" "$name"
            fi
        done
        
        # Progress indicator every 100 iterations
        if (( i % 100 == 0 )); then
            echo "Progress: $((i * 100 / ITERATIONS))% complete"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Generate summary report
    generate_summary_report "$duration"
}

# --- Generate Summary Report ---
generate_summary_report() {
    local duration=$1
    
    echo ""
    echo "======================================================================"
    echo " Test Summary - Performance Analysis Over $ITERATIONS Iterations"
    echo "======================================================================"
    echo ""
    
    # Create markdown report file
    local report_file="${OUTPUT_DIR}/summary_report.md"
    
    cat > "$report_file" << EOF
# Load Testing Summary Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Test Duration:** ${duration}s  
**Total Iterations:** $ITERATIONS  
**Requests per Test:** $AB_REQUESTS  
**Concurrency Level:** $AB_CONCURRENCY  

---

EOF
    
    for name in "${!SCENARIOS[@]}"; do
        url=${SCENARIOS[$name]}
        
        # Convert space-separated string to array
        read -r -a rps_array <<< "${RPS_VALUES[$name]}"
        read -r -a time_array <<< "${RESPONSE_TIME_VALUES[$name]}"
        read -r -a p95_array <<< "${P95_VALUES[$name]}"
        read -r -a p99_array <<< "${P99_VALUES[$name]}"
        
        local success_count=${SUCCESS_COUNTS[$name]}
        local error_count=${ERROR_COUNTS[$name]}
        local total_tests=$((success_count + error_count))
        local success_rate=0
        
        if [ $total_tests -gt 0 ]; then
            success_rate=$(echo "scale=2; $success_count * 100 / $total_tests" | bc -l)
        fi
        
        # Calculate statistics (only on successful tests)
        if [ ${#rps_array[@]} -gt 0 ]; then
            IFS='|' read -r rps_mean rps_median rps_std rps_min rps_max rps_p50 rps_p95 rps_p99 <<< \
                "$(calculate_statistics rps_array)"
            
            IFS='|' read -r time_mean time_median time_std time_min time_max time_p50 time_p95 time_p99 <<< \
                "$(calculate_statistics time_array)"
            
            IFS='|' read -r p95_mean p95_median p95_std p95_min p95_max p95_p50 p95_p95 p95_p99 <<< \
                "$(calculate_statistics p95_array)"
            
            # Calculate coefficient of variation (stability indicator)
            local cv=$(echo "scale=2; $rps_std * 100 / $rps_mean" | bc -l)
            
            # Console output (preserves original format but enhanced)
            echo "   $name"
            echo "   URL: $url"
            echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            printf " ==== Average RPS:          %8.2f req/s (original metric)\n" "$rps_mean"
            printf " ==== Median RPS:           %8.2f req/s\n" "$rps_median"
            printf " ==== Std Deviation:        %8.2f req/s (CV: %.1f%%)\n" "$rps_std" "$cv"
            printf " ==== Range:                %8.2f - %.2f req/s\n" "$rps_min" "$rps_max"
            printf " ==== Percentiles:          P50: %.2f | P95: %.2f | P99: %.2f req/s\n" \
                "$rps_p50" "$rps_p95" "$rps_p99"
            echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            printf " ==== Avg Response Time:    %8.2f ms\n" "$time_mean"
            printf " ==== P95 Latency:          %8.2f ms\n" "$p95_mean"
            printf " ==== P99 Latency:          %8.2f ms\n" "$p95_p99"
            echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            printf " ==== Success Rate:         %8.2f%% (%d/%d tests)\n" \
                "$success_rate" "$success_count" "$total_tests"
            printf " ==== Error Rate:           %8.2f%% (%d failures)\n" \
                "$(echo "100 - $success_rate" | bc -l)" "$error_count"
            echo ""
            
            # Markdown report
            cat >> "$report_file" << EOF
##  $name

**URL:** \`$url\`

### Performance Metrics

| Metric | Value |
|--------|-------|
| **Average RPS** | **${rps_mean} req/s** |
| Median RPS | ${rps_median} req/s |
| Standard Deviation | ${rps_std} req/s (CV: ${cv}%) |
| Min/Max RPS | ${rps_min} / ${rps_max} req/s |
| P50 / P95 / P99 | ${rps_p50} / ${rps_p95} / ${rps_p99} req/s |

### Latency Analysis

| Metric | Value |
|--------|-------|
| Avg Response Time | ${time_mean} ms |
| Median Response Time | ${time_median} ms |
| P95 Latency | ${p95_mean} ms |
| P99 Latency | ${p95_p99} ms |

### Reliability

| Metric | Value |
|--------|-------|
| Success Rate | ${success_rate}% (${success_count}/${total_tests}) |
| Error Rate | $(echo "100 - $success_rate" | bc -l)% (${error_count} failures) |

**Stability Assessment:** $(
    if (( $(echo "$cv < 10" | bc -l) )); then
        echo "==== Excellent (CV < 10%)"
    elif (( $(echo "$cv < 20" | bc -l) )); then
        echo "==== Good (CV < 20%)"
    elif (( $(echo "$cv < 30" | bc -l) )); then
        echo "==== Moderate (CV < 30%)"
    else
        echo "==== Poor (CV ≥ 30%)"
    fi
)

---

EOF
        else
            echo " $name: All $total_tests tests FAILED"
            echo ""
            
            cat >> "$report_file" << EOF
##  $name

**URL:** \`$url\`

**Status:** All ${total_tests} tests FAILED

---

EOF
        fi
    done
    
    # Add summary footer
    cat >> "$report_file" << EOF

## Test Artifacts

- **Console Output:** \`console_output.log\`
- **Execution Log:** \`execution.log\`
- **Error Log:** \`error.log\`
- **Raw Test Data:** \`raw_*.txt\` files

## Interpretation Guide

- **Average RPS:** Mean throughput (original metric preserved)
- **Median RPS:** Middle value, less affected by outliers
- **Std Deviation:** Lower is more stable
- **CV (Coefficient of Variation):** <20% indicates stable performance
- **P95/P99:** Tail latency, important for SLA validation
- **Success Rate:** Percentage of successful test iterations

---

**Report Generated:** $(date '+%Y-%m-%d %H:%M:%S')

EOF
    
    echo "======================================================================"
    echo "===== Testing Complete!"
    echo "======================================================================"
    echo "===== Summary report saved: $report_file"
    echo "===== All test data saved in: $OUTPUT_DIR"
    echo "===== Total test duration: ${duration}s"
    echo "======================================================================"
}

# --- Entry Point ---
trap 'echo "Test interrupted by user"; exit 1' INT TERM

# Check for required tools
for cmd in ab bc awk grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' not found"
        exit 1
    fi
done

main "$@"