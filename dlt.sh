#!/bin/bash

# =============================================================================
# Deep Load Testing Script with Research-Based Methodology
# -----------------------------------------------------------------------------
# This script performs deep load testing with a focus on research-based methodology,
# including warm-up phases, ramp-up simulations, sustained periods, statistical analysis,
# and automated regression detection. It supports both Git-integrated baselines and local-only storage.
#
# Requirements:
# - Apache Bench (ab) installed
# - GNU coreutils (bc, sort, uniq)
# - Optional: Git for version control of baselines
#
# 
# File: dlt.sh
# Author: M.Noermoehammad
# License: MIT License
# Version: 6.0 - Priority 1 Implementation
#
# CHANGELOG v6.0:
# - Smart locale auto-detection (respects system configuration)
# - Hybrid baseline management (Git-integrated + local development)
# - Welch's t-test implementation for hypothesis testing
# - Effect size calculation (Cohen's d)
# - Automated regression detection
#
# RESEARCH METHODOLOGY:
# - Warm-up phase to stabilize metrics
# - Ramp-up phase to simulate real-world traffic patterns
# - Sustained phase to capture steady-state performance
# - Statistical analysis and visualization for insights
#
# NOTE: This script is designed for research purposes and may not suit all environments.
#       Always ensure you have the necessary permissions before running tests on live systems.
#       Use at your own risk!
#
# DISCLAIMER: The author does not guarantee the accuracy or reliability of results obtained through this script.
#             It is recommended to conduct thorough validation 
#             and verification of findings before making any decisions based on them.
#
# You can see the research references in REFERENCES.md
# =============================================================================



set -euo pipefail

# =============================================================================
# LOCALE CONFIGURATION - Smart Auto-Detection
# =============================================================================

detect_and_configure_locale() {
    local current_locale="${LC_NUMERIC:-${LC_ALL:-${LANG:-C}}}"
    
    # Test decimal separator compatibility for bc calculations
    local test_decimal=$(printf "%.2f" 3.14 2>/dev/null | cut -d'.' -f2)
    
    if [[ "$test_decimal" == "14" ]]; then
        # Current locale uses period - validate with bc
        if echo "scale=2; 3.14 * 2" | bc -l &>/dev/null; then
            echo "[INFO] Locale validated: $current_locale (decimal: period)" >&2
            export LC_NUMERIC="$current_locale"
            return 0
        fi
    fi
    
    # Need compatible locale - try alternatives
    for try_locale in "C" "en_US.UTF-8" "en_GB.UTF-8" "POSIX"; do
        if locale -a 2>/dev/null | grep -qiE "^${try_locale}"; then
            export LC_NUMERIC="$try_locale"
            export LANG="${LANG:-$try_locale}"
            echo "[INFO] Using compatible locale: $try_locale" >&2
            return 0
        fi
    done
    
    # Fallback to C (always available)
    export LC_NUMERIC="C"
    export LANG="C"
    echo "[WARN] Fallback to C locale" >&2
    return 0
}

# Initialize locale
detect_and_configure_locale

# Validate bc with current locale
if ! echo "scale=2; 3.14 * 2" | bc -l &>/dev/null; then
    echo "[FATAL] bc incompatible with current locale. Install en_US.UTF-8 or run with LC_NUMERIC=C" >&2
    exit 1
fi

# =============================================================================
# CONFIGURATION - Environment Detection
# =============================================================================

# Detect environment from .env file
detect_environment() {
    local env_file="${SCRIPT_DIR}/.env"
    
    if [[ -f "$env_file" ]]; then
        # Parse APP_ENV from .env (handles various formats)
        local app_env=$(grep -E '^APP_ENV=' "$env_file" | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
        
        if [[ -n "$app_env" ]]; then
            echo "$app_env"
            return 0
        fi
    fi
    
    # Default to local if no .env or no APP_ENV
    echo "local"
}

# Research-Based Configuration
WARMUP_ITERATIONS=50
RAMPUP_ITERATIONS=100
SUSTAINED_ITERATIONS=850
TOTAL_ITERATIONS=1000

AB_REQUESTS=1000
AB_CONCURRENCY=50
THINK_TIME_MS=2000
TEST_TIMEOUT=30

# Test scenarios
declare -A SCENARIOS=(
    ["Static"]="http://example.com/static.html" 
    ["Dynamic"]="http://example.com/dynamic.php" 
    ["API_Endpoint"]="http://example.com/api/v1/data" 
    ["404_Error"]="http://example.com/notfound" 
)

# =============================================================================
# BASELINE MANAGEMENT - Hybrid Strategy
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
APP_ENV=$(detect_environment)

# Environment-specific baseline directories
if [[ "$APP_ENV" == "production" ]]; then
    BASELINE_DIR="${SCRIPT_DIR}/baselines"
    BASELINE_PREFIX="production"
    USE_GIT_TRACKING=true
    echo "[INFO] Environment: PRODUCTION (baselines will be Git-tracked)"
else
    BASELINE_DIR="${SCRIPT_DIR}/.dlt_local"
    BASELINE_PREFIX="${APP_ENV}"
    USE_GIT_TRACKING=false
    echo "[INFO] Environment: ${APP_ENV^^} (baselines local only)"
fi

# Create baseline directory
mkdir -p "$BASELINE_DIR"

# Report directory (always local)
REPORT_DIR="${SCRIPT_DIR}/load_test_reports_${TIMESTAMP}"
mkdir -p "${REPORT_DIR}/raw_data"
mkdir -p "${REPORT_DIR}/charts"

REPORT_FILE="${REPORT_DIR}/research_report_${TIMESTAMP}.md"
SYSTEM_METRICS_FILE="${REPORT_DIR}/system_metrics.csv"
ERROR_LOG="${REPORT_DIR}/error_log.txt"
COMPARISON_REPORT="${REPORT_DIR}/hypothesis_testing_${TIMESTAMP}.md"

# Initialize logs
echo "timestamp,cpu_user,cpu_system,memory_used,memory_free,load_1,load_5,load_15,disk_read_kb,disk_write_kb" > "$SYSTEM_METRICS_FILE"
> "$ERROR_LOG"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ERROR_LOG" >&2
}

log_info() {
    echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${REPORT_DIR}/execution.log"
}

capture_system_metrics() {
    local timestamp=$(date +%s)
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_stats=$(free -m | awk 'NR==2{print $3","$4}')
    local load=$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ' | tr ',' ' ')
    local disk_io=$(iostat -d -k 1 2 2>/dev/null | tail -1 | awk '{print $3","$4}' || echo "0,0")
    
    echo "$timestamp,${cpu_usage:-0},0,$mem_stats,$load,$disk_io" >> "$SYSTEM_METRICS_FILE"
}

# =============================================================================
# BASELINE STORAGE & RETRIEVAL
# =============================================================================

save_baseline() {
    local scenario="$1"
    local -n data_ref="$2"
    
    local baseline_file="${BASELINE_DIR}/${BASELINE_PREFIX}_baseline_${scenario}_$(date +%Y%m%d).csv"
    
    # CSV Header
    echo "iteration,rps,response_time_ms,p95_ms,p99_ms,connect_ms,processing_ms" > "$baseline_file"
    
    # Write data
    local iteration=1
    local -a rps_array=($data_ref)
    for val in "${rps_array[@]}"; do
        echo "$iteration,$val,0,0,0,0,0" >> "$baseline_file"
        ((iteration++))
    done
    
    log_info "Baseline saved: $baseline_file"
    
    # Git tracking for production
    if [[ "$USE_GIT_TRACKING" == true ]] && command -v git &>/dev/null; then
        if git -C "$SCRIPT_DIR" rev-parse --git-dir &>/dev/null; then
            git -C "$SCRIPT_DIR" add "$baseline_file" 2>/dev/null || true
            log_info "Baseline staged for Git commit"
        fi
    fi
    
    # Update metadata
    update_baseline_metadata "$scenario" "$baseline_file"
    
    echo "$baseline_file"
}

update_baseline_metadata() {
    local scenario="$1"
    local baseline_file="$2"
    local metadata_file="${BASELINE_DIR}/metadata.json"
    
    # Create or update metadata
    if [[ ! -f "$metadata_file" ]]; then
        echo "{}" > "$metadata_file"
    fi
    
    # Simple JSON update (no jq dependency)
    local timestamp=$(date -Iseconds)
    local git_commit=$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || echo "no-git")
    
    cat >> "$metadata_file" << EOF

# Baseline: $scenario
# File: $baseline_file
# Timestamp: $timestamp
# Git Commit: $git_commit
# Environment: $APP_ENV

EOF
}

load_latest_baseline() {
    local scenario="$1"
    
    # Find most recent baseline for this scenario
    local baseline_file=$(ls -t "${BASELINE_DIR}/${BASELINE_PREFIX}_baseline_${scenario}_"*.csv 2>/dev/null | head -1)
    
    if [[ -z "$baseline_file" ]] || [[ ! -f "$baseline_file" ]]; then
        echo ""
        return 1
    fi
    
    echo "$baseline_file"
    return 0
}

load_baseline_data() {
    local baseline_file="$1"
    local metric_column="$2"  # 2=rps, 3=response_time, 4=p95, etc.
    
    if [[ ! -f "$baseline_file" ]]; then
        echo ""
        return 1
    fi
    
    # Extract metric column (skip header)
    local values=$(tail -n +2 "$baseline_file" | cut -d',' -f"$metric_column" | tr '\n' ' ')
    echo "$values"
}

# =============================================================================
# STATISTICAL HYPOTHESIS TESTING - Welch's t-test
# =============================================================================

calculate_mean() {
    local -n array="$1"
    local count=${#array[@]}
    
    if [[ $count -eq 0 ]]; then
        echo "0"
        return
    fi
    
    local sum=0
    for val in "${array[@]}"; do
        sum=$(echo "$sum + $val" | bc -l)
    done
    
    echo "scale=6; $sum / $count" | bc -l
}

calculate_variance() {
    local -n array="$1"
    local mean="$2"
    local count=${#array[@]}
    
    if [[ $count -le 1 ]]; then
        echo "0"
        return
    fi
    
    local sum_sq=0
    for val in "${array[@]}"; do
        local diff=$(echo "$val - $mean" | bc -l)
        sum_sq=$(echo "$sum_sq + ($diff * $diff)" | bc -l)
    done
    
    # Sample variance (n-1)
    echo "scale=6; $sum_sq / ($count - 1)" | bc -l
}

welchs_t_test() {
    local -n baseline_array="$1"
    local -n candidate_array="$2"
    
    local n1=${#baseline_array[@]}
    local n2=${#candidate_array[@]}
    
    if [[ $n1 -lt 2 ]] || [[ $n2 -lt 2 ]]; then
        echo "0|0|0|insufficient_data"
        return 1
    fi
    
    # Calculate means
    local mean1=$(calculate_mean baseline_array)
    local mean2=$(calculate_mean candidate_array)
    
    # Calculate variances
    local var1=$(calculate_variance baseline_array "$mean1")
    local var2=$(calculate_variance candidate_array "$mean2")
    
    # Welch's t-statistic
    # t = (mean1 - mean2) / sqrt(var1/n1 + var2/n2)
    local se=$(echo "scale=6; sqrt(($var1 / $n1) + ($var2 / $n2))" | bc -l)
    
    if (( $(echo "$se == 0" | bc -l) )); then
        echo "0|0|999|zero_variance"
        return 1
    fi
    
    local t_stat=$(echo "scale=6; ($mean1 - $mean2) / $se" | bc -l)
    
    # Welch-Satterthwaite degrees of freedom
    # df = (var1/n1 + var2/n2)^2 / ((var1/n1)^2/(n1-1) + (var2/n2)^2/(n2-1))
    local s1=$(echo "scale=6; $var1 / $n1" | bc -l)
    local s2=$(echo "scale=6; $var2 / $n2" | bc -l)
    local numerator=$(echo "scale=6; ($s1 + $s2) * ($s1 + $s2)" | bc -l)
    local denom=$(echo "scale=6; (($s1 * $s1) / ($n1 - 1)) + (($s2 * $s2) / ($n2 - 1))" | bc -l)
    
    local df=30  # Conservative approximation for large samples
    if (( $(echo "$denom > 0" | bc -l) )); then
        df=$(echo "scale=0; $numerator / $denom" | bc -l)
    fi
    
    # Approximate p-value using t-distribution
    local p_value=$(t_to_pvalue "$t_stat" "$df")
    
    echo "$t_stat|$p_value|$df|success"
}

t_to_pvalue() {
    local t="$1"
    local df="$2"
    
    # Absolute value of t
    local t_abs=$(echo "scale=6; sqrt($t * $t)" | bc -l)
    
    # For large df (>30), use normal approximation
    if (( $(echo "$df > 30" | bc -l) )); then
        # Two-tailed p-value approximation
        # P(|Z| > |t|) ≈ 2 * Φ(-|t|)
        # Using rough normal CDF approximation
        
        if (( $(echo "$t_abs > 3.5" | bc -l) )); then
            echo "0.001"  # Very significant
        elif (( $(echo "$t_abs > 2.576" | bc -l) )); then
            echo "0.01"   # p < 0.01
        elif (( $(echo "$t_abs > 1.96" | bc -l) )); then
            echo "0.05"   # p < 0.05
        elif (( $(echo "$t_abs > 1.645" | bc -l) )); then
            echo "0.10"   # p < 0.10
        else
            echo "0.20"   # Not significant
        fi
    else
        # Small sample - use t-table approximation
        if (( $(echo "$t_abs > 3.0" | bc -l) )); then
            echo "0.01"
        elif (( $(echo "$t_abs > 2.0" | bc -l) )); then
            echo "0.05"
        else
            echo "0.20"
        fi
    fi
}

# =============================================================================
# EFFECT SIZE - Cohen's d
# =============================================================================

calculate_cohens_d() {
    local mean1="$1"
    local mean2="$2"
    local sd1="$3"
    local sd2="$4"
    local n1="$5"
    local n2="$6"
    
    # Pooled standard deviation
    local var1=$(echo "$sd1 * $sd1" | bc -l)
    local var2=$(echo "$sd2 * $sd2" | bc -l)
    
    local pooled_var=$(echo "scale=6; ((($n1 - 1) * $var1) + (($n2 - 1) * $var2)) / ($n1 + $n2 - 2)" | bc -l)
    local pooled_sd=$(echo "scale=6; sqrt($pooled_var)" | bc -l)
    
    if (( $(echo "$pooled_sd == 0" | bc -l) )); then
        echo "0"
        return
    fi
    
    # Cohen's d
    local d=$(echo "scale=4; ($mean1 - $mean2) / $pooled_sd" | bc -l)
    echo "$d"
}

interpret_cohens_d() {
    local d="$1"
    local d_abs=$(echo "scale=4; sqrt($d * $d)" | bc -l)
    
    if (( $(echo "$d_abs < 0.2" | bc -l) )); then
        echo "negligible"
    elif (( $(echo "$d_abs < 0.5" | bc -l) )); then
        echo "small"
    elif (( $(echo "$d_abs < 0.8" | bc -l) )); then
        echo "medium"
    else
        echo "large"
    fi
}

# =============================================================================
# APACHEBENCH PARSER (Keep original implementation)
# =============================================================================

parse_ab_output() {
    local file="$1"
    local scenario="$2"
    
    if ! grep -q "Requests per second:" "$file"; then
        log_error "Test failed for $scenario - no RPS data"
        echo "ERROR|0|0|0|0|0|0|0|0|0|0|0|0|0"
        return 1
    fi
    
    local rps=$(grep "Requests per second:" "$file" | awk '{print $4}')
    local time_per_req=$(grep "Time per request:" "$file" | head -1 | awk '{print $4}')
    local failed=$(grep "Failed requests:" "$file" | awk '{print $3}')
    local transfer_rate=$(grep "Transfer rate:" "$file" | awk '{print $3}')
    
    local connect_line=$(grep "Connect:" "$file")
    local processing_line=$(grep "Processing:" "$file")
    local total_line=$(grep "Total:" "$file")
    
    local connect_avg=$(echo "$connect_line" | awk '{if ($3 ~ /\[.+/) {print $4} else {print $3}}')
    local processing_avg=$(echo "$processing_line" | awk '{if ($3 ~ /\[.+/) {print $4} else {print $3}}')
    local total_avg=$(echo "$total_line" | awk '{if ($3 ~ /\[.+/) {print $4} else {print $3}}')
    
    local p50=$(grep -A 20 "Percentage" "$file" | grep "50%" | awk '{print $2}')
    local p90=$(grep -A 20 "Percentage" "$file" | grep "90%" | awk '{print $2}')
    local p95=$(grep -A 20 "Percentage" "$file" | grep "95%" | awk '{print $2}')
    local p99=$(grep -A 20 "Percentage" "$file" | grep "99%" | awk '{print $2}')
    
    [[ -z "$rps" ]] && rps="0"
    [[ -z "$p95" ]] && p95="0"
    [[ -z "$p99" ]] && p99="0"
    [[ -z "$total_avg" ]] && total_avg="0"
    [[ -z "$connect_avg" ]] && connect_avg="0"
    [[ -z "$processing_avg" ]] && processing_avg="0"
    
    echo "SUCCESS|$rps|$time_per_req|$failed|$transfer_rate|$connect_avg|$processing_avg|$total_avg|$p50|$p90|$p95|$p99|0|0"
}

# =============================================================================
# TEST EXECUTION (Keep original implementation)
# =============================================================================

run_research_test() {
    local url="$1"
    local scenario="$2"
    local iteration="$3"
    local concurrency="$4"
    
    local temp_file="${REPORT_DIR}/raw_data/${scenario}_iter${iteration}_$(date +%s).txt"
    
    timeout $TEST_TIMEOUT ab -k -n $AB_REQUESTS -c $concurrency "$url" > "$temp_file" 2>&1
    
    local result=$(parse_ab_output "$temp_file" "$scenario")
    echo "$result" > "${temp_file}.parsed"
    
    local think_time=$(( (RANDOM % THINK_TIME_MS) + 500 ))
    sleep $(echo "scale=3; $think_time / 1000" | bc)
    
    echo "$result"
}

# =============================================================================
# STATISTICAL CALCULATIONS (Keep original calculate_statistics)
# =============================================================================

calculate_statistics() {
    local values_str="$1"
    read -ra values <<< "$values_str"
    
    read -ra sorted < <(printf '%s\n' "${values[@]}" | sort -n)
    local count=${#sorted[@]}
    
    if [[ $count -eq 0 ]]; then
        echo "0|0|0|0|0|0|0|0|0|0"
        return
    fi
    
    local sum=0
    for val in "${sorted[@]}"; do
        sum=$(echo "$sum + $val" | bc -l)
    done
    
    local mean=$(echo "scale=3; $sum / $count" | bc -l)
    
    local middle=$((count / 2))
    if (( count % 2 == 1 )); then
        local median=${sorted[$middle]}
    else
        local median=$(echo "scale=3; (${sorted[$((middle-1))]} + ${sorted[$middle]}) / 2" | bc -l)
    fi
    
    local variance=0
    for val in "${sorted[@]}"; do
        local diff=$(echo "$val - $mean" | bc -l)
        variance=$(echo "$variance + ($diff * $diff)" | bc -l)
    done
    variance=$(echo "scale=3; $variance / $count" | bc -l)
    local std_dev=$(echo "scale=3; sqrt($variance)" | bc -l)
    
    local min=${sorted[0]}
    local max=${sorted[-1]}
    
    local p90_idx=$((count * 90 / 100))
    local p95_idx=$((count * 95 / 100))
    local p99_idx=$((count * 99 / 100))
    
    local p90=${sorted[$p90_idx]:-0}
    local p95=${sorted[$p95_idx]:-0}
    local p99=${sorted[$p99_idx]:-0}
    
    local confidence=$(echo "scale=3; 1.96 * $std_dev / sqrt($count)" | bc -l)
    local ci_lower=$(echo "scale=3; $mean - $confidence" | bc -l)
    local ci_upper=$(echo "scale=3; $mean + $confidence" | bc -l)
    
    echo "$mean|$median|$std_dev|$min|$max|$p90|$p95|$p99|$ci_lower|$ci_upper"
}

# =============================================================================
# MAIN TEST EXECUTION
# =============================================================================

main() {
    echo "========================================="
    echo "RESEARCH-BASED LOAD TESTING v6.0"
    echo "Environment: ${APP_ENV^^}"
    echo "Baseline Mode: $([ "$USE_GIT_TRACKING" = true ] && echo 'Git-Tracked (Production)' || echo 'Local Development')"
    echo "========================================="
    
    # Start system monitoring
    (while true; do capture_system_metrics; sleep 5; done) &
    MONITOR_PID=$!
    
    # Initialize result storage
    declare -A RPS_VALUES
    declare -A P95_VALUES
    declare -A P99_VALUES
    declare -A RESPONSE_TIME_VALUES
    declare -A ERROR_COUNTS
    
    for scenario in "${!SCENARIOS[@]}"; do
        RPS_VALUES[$scenario]=""
        P95_VALUES[$scenario]=""
        P99_VALUES[$scenario]=""
        RESPONSE_TIME_VALUES[$scenario]=""
        ERROR_COUNTS[$scenario]=0
    done
    
    START_TIME=$(date +%s)
    
    # Phase 1: Warm-up
    echo ""
    echo "PHASE 1: WARM-UP"
    echo "--------------------------------------------------"
    for (( i=1; i<=WARMUP_ITERATIONS; i++ )); do
        for scenario in "${!SCENARIOS[@]}"; do
            url=${SCENARIOS[$scenario]}
            result=$(run_research_test "$url" "$scenario" "warmup_$i" $((AB_CONCURRENCY / 4)))
            
            IFS='|' read -r status rps _ _ _ _ _ _ _ _ p95 p99 _ _ <<< "$result"
            
            if [[ "$status" == "SUCCESS" ]]; then
                printf "  ✓ %-20s: %6.1f req/s\n" "$scenario" "$rps"
            else
                ERROR_COUNTS[$scenario]=$((ERROR_COUNTS[$scenario] + 1))
            fi
        done
    done
    
    # Phase 2: Ramp-up
    for (( i=1; i<=RAMPUP_ITERATIONS; i++ )); do
        current_concurrency=$(( (AB_CONCURRENCY / 4) + ((AB_CONCURRENCY * 3 / 4) * i / RAMPUP_ITERATIONS) ))
        
        for scenario in "${!SCENARIOS[@]}"; do
            url=${SCENARIOS[$scenario]}
            result=$(run_research_test "$url" "$scenario" "rampup_$i" "$current_concurrency")
            
            IFS='|' read -r status rps _ _ _ _ _ total _ _ p95 p99 _ _ <<< "$result"
            
            if [[ "$status" == "SUCCESS" ]]; then
                RPS_VALUES[$scenario]+="$rps "
                P95_VALUES[$scenario]+="$p95 "
                P99_VALUES[$scenario]+="$p99 "
                RESPONSE_TIME_VALUES[$scenario]+="$total "
            fi
        done
    done
    
    # Phase 3: Sustained
    echo "PHASE 3: SUSTAINED LOAD"
    for (( i=1; i<=SUSTAINED_ITERATIONS; i++ )); do
        for scenario in "${!SCENARIOS[@]}"; do
            url=${SCENARIOS[$scenario]}
            result=$(run_research_test "$url" "$scenario" "sustained_$i" "$AB_CONCURRENCY")
            
            IFS='|' read -r status rps _ _ _ _ _ total _ _ p95 p99 _ _ <<< "$result"
            
            if [[ "$status" == "SUCCESS" ]]; then
                RPS_VALUES[$scenario]+="$rps "
                P95_VALUES[$scenario]+="$p95 "
                P99_VALUES[$scenario]+="$p99 "
                RESPONSE_TIME_VALUES[$scenario]+="$total "
            fi
        done
        
        if (( i % 100 == 0 )); then
            echo "Progress: $((i * 100 / SUSTAINED_ITERATIONS))%"
        fi
    done
    
    kill $MONITOR_PID 2>/dev/null || true
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # Generate reports with hypothesis testing
    generate_research_report_with_hypothesis_testing
    
    # Save baselines
    echo ""
    echo "SAVING BASELINES..."
    for scenario in "${!SCENARIOS[@]}"; do
        baseline_file=$(save_baseline "$scenario" RPS_VALUES[$scenario])
        echo "  ✓ $scenario: $baseline_file"
    done
    
    echo ""
    echo "========================================="
    echo "TEST COMPLETE"
    echo "Duration: ${DURATION}s"
    echo "Report: $REPORT_FILE"
    echo "Hypothesis Testing: $COMPARISON_REPORT"
    echo "========================================="
}

# =============================================================================
# ENHANCED REPORT GENERATION WITH HYPOTHESIS TESTING
# =============================================================================

generate_research_report_with_hypothesis_testing() {
    echo ""
    echo "GENERATING ENHANCED RESEARCH REPORT..."
    
    # Standard report (keep original)
    generate_standard_report
    
    # NEW: Hypothesis testing report
    generate_hypothesis_testing_report
}

generate_standard_report() {
    cat > "$REPORT_FILE" << 'EOF'
# Research-Based Load Testing Report v6.0

## Enhancements in v6.0
- Smart locale auto-detection
- Hybrid baseline management (Git-integrated)
- Welch's t-test for statistical hypothesis testing
- Cohen's d effect size calculation
- Automated regression detection

## Executive Summary
EOF

    for scenario in "${!SCENARIOS[@]}"; do
        IFS='|' read -r mean median sd min max p90 p95 p99 ci_low ci_up <<< \
            "$(calculate_statistics "${RPS_VALUES[$scenario]}")"
        
        cat >> "$REPORT_FILE" << EOF

### $scenario
**URL**: \`${SCENARIOS[$scenario]}\`

| Metric | Mean | Median | Std Dev | P95 | P99 | 95% CI |
|--------|------|--------|---------|-----|-----|--------|
| RPS | $mean | $median | $sd | - | - | [$ci_low, $ci_up] |
EOF
    done
    
    cat >> "$REPORT_FILE" << EOF

---
**Test Duration**: ${DURATION}s  
**Environment**: $APP_ENV  
**Baseline Tracking**: $([ "$USE_GIT_TRACKING" = true ] && echo 'Git-enabled (Production)' || echo 'Local development')

EOF
}

generate_hypothesis_testing_report() {
    cat > "$COMPARISON_REPORT" << 'EOF'
# Statistical Hypothesis Testing Report

## Methodology: Welch's t-test (Welch, 1947)

**Null Hypothesis (H₀)**: No significant difference between baseline and current test  
**Alternative Hypothesis (H₁)**: Significant difference exists  
**Significance Level (α)**: 0.05 (5%)

## Results

EOF

    for scenario in "${!SCENARIOS[@]}"; do
        # Try to load baseline
        baseline_file=$(load_latest_baseline "$scenario")
        
        if [[ -z "$baseline_file" ]]; then
            cat >> "$COMPARISON_REPORT" << EOF
### $scenario
**Status**: No baseline found - this test will be saved as baseline

EOF
            continue
        fi
        
        # Load baseline RPS data
        baseline_rps=$(load_baseline_data "$baseline_file" 2)
        
        if [[ -z "$baseline_rps" ]]; then
            cat >> "$COMPARISON_REPORT" << EOF
### $scenario
**Status**: Baseline data corrupted - skipping comparison

EOF
            continue
        fi
        
        # Convert to arrays
        read -ra baseline_array <<< "$baseline_rps"
        read -ra candidate_array <<< "${RPS_VALUES[$scenario]}"
        
        # Perform Welch's t-test
        IFS='|' read -r t_stat p_value df status <<< "$(welchs_t_test baseline_array candidate_array)"
        
        if [[ "$status" != "success" ]]; then
            cat >> "$COMPARISON_REPORT" << EOF
### $scenario
**Status**: Statistical test failed - $status

EOF
            continue
        fi
        
        # Calculate statistics
        baseline_mean=$(calculate_mean baseline_array)
        candidate_mean=$(calculate_mean candidate_array)
        
        baseline_var=$(calculate_variance baseline_array "$baseline_mean")
        candidate_var=$(calculate_variance candidate_array "$candidate_mean")
        
        baseline_sd=$(echo "scale=3; sqrt($baseline_var)" | bc -l)
        candidate_sd=$(echo "scale=3; sqrt($candidate_var)" | bc -l)
        
        # Cohen's d
        cohens_d=$(calculate_cohens_d "$baseline_mean" "$candidate_mean" "$baseline_sd" "$candidate_sd" "${#baseline_array[@]}" "${#candidate_array[@]}")
        effect_interpretation=$(interpret_cohens_d "$cohens_d")
        
        # Percent change
        pct_change=$(echo "scale=2; (($candidate_mean - $baseline_mean) / $baseline_mean) * 100" | bc -l)
        
        # Determine significance
        if (( $(echo "$p_value < 0.05" | bc -l) )); then
            if (( $(echo "$candidate_mean > $baseline_mean" | bc -l) )); then
                verdict="SIGNIFICANT IMPROVEMENT"
            else
                verdict="SIGNIFICANT REGRESSION"
            fi
        else
            verdict="✓ No significant change"
        fi
        
        cat >> "$COMPARISON_REPORT" << EOF
### $scenario

**Baseline**: $baseline_file  
**Baseline Mean RPS**: $baseline_mean  
**Current Mean RPS**: $candidate_mean  
**Change**: ${pct_change}%

#### Statistical Test Results

| Metric | Value | Interpretation |
|--------|-------|----------------|
| **t-statistic** | $t_stat | - |
| **p-value** | $p_value | $([ $(echo "$p_value < 0.05" | bc -l) -eq 1 ] && echo "Statistically significant (p < 0.05)" || echo "Not significant (p ≥ 0.05)") |
| **Degrees of Freedom** | $df | Welch-Satterthwaite |
| **Cohen's d** | $cohens_d | Effect size: $effect_interpretation |
| **Verdict** | $verdict | - |

#### Interpretation (Jain, 1991 & Cohen, 1988)

EOF

        if (( $(echo "$p_value < 0.01" | bc -l) )); then
            echo "- **Very strong evidence** against H₀ (99% confidence)" >> "$COMPARISON_REPORT"
        elif (( $(echo "$p_value < 0.05" | bc -l) )); then
            echo "- **Strong evidence** against H₀ (95% confidence)" >> "$COMPARISON_REPORT"
        else
            echo "- **Insufficient evidence** to reject H₀" >> "$COMPARISON_REPORT"
        fi
        
        echo "- Effect size is **$effect_interpretation** (Cohen's d = $cohens_d)" >> "$COMPARISON_REPORT"
        
        if [[ "$effect_interpretation" == "negligible" ]] || [[ "$effect_interpretation" == "small" ]]; then
            echo "- **Practical significance**: Change is statistically detectable but may not be practically important" >> "$COMPARISON_REPORT"
        else
            echo "- **Practical significance**: Change is both statistically and practically significant" >> "$COMPARISON_REPORT"
        fi
        
        echo "" >> "$COMPARISON_REPORT"
    done
    
    cat >> "$COMPARISON_REPORT" << 'EOF'

---

## Research References

1. **Welch, B. L. (1947)**. "The generalization of Student's problem when several different population variances are involved." *Biometrika*, 34(1-2), 28-35.

2. **Cohen, J. (1988)**. *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

3. **Jain, R. (1991)**. *The Art of Computer Systems Performance Analysis*. Wiley.

---

**Report Generated**: $(date)  
**Environment**: $APP_ENV  
**Baseline Strategy**: $([ "$USE_GIT_TRACKING" = true ] && echo 'Git-tracked production baselines' || echo 'Local development baselines')

EOF

    log_info "Hypothesis testing report generated: $COMPARISON_REPORT"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

trap 'echo "Test interrupted"; kill $MONITOR_PID 2>/dev/null || true; exit 1' INT TERM

main "$@"

