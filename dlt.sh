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
# File: dlt.sh
# Author: M.Noermoehammad
# License: MIT License
# Version: 6.1
#
# CHANGELOG v6.1:
# - Added Mann-Whitney U test (non-parametric alternative)
# - Automatic statistical test selection (parametric vs non-parametric)
# - Normality checking using skewness and kurtosis
# - Rank-biserial correlation for Mann-Whitney effect size
# - Enhanced reporting with test rationale
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
# STATISTICAL FOUNDATIONS - Shared Functions
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

# =============================================================================
# NORMALITY TESTING - New in v6.1
# =============================================================================

check_normality() {
    local -n data_array="$1"
    local n=${#data_array[@]}
    
    if [[ $n -lt 20 ]]; then
        # Too small for reliable normality test
        echo "insufficient_data"
        return 1
    fi
    
    # Calculate mean and standard deviation
    local mean=$(calculate_mean data_array)
    local variance=$(calculate_variance data_array "$mean")
    local sd=$(echo "scale=6; sqrt($variance)" | bc -l)
    
    if (( $(echo "$sd == 0" | bc -l) )); then
        echo "zero_variance"
        return 1
    fi
    
    # Calculate skewness: E[(X-μ)³]/σ³
    local m3=0
    for val in "${data_array[@]}"; do
        local z=$(echo "scale=6; ($val - $mean) / $sd" | bc -l)
        local z3=$(echo "scale=6; $z * $z * $z" | bc -l)
        m3=$(echo "scale=6; $m3 + $z3" | bc -l)
    done
    local skewness=$(echo "scale=4; $m3 / $n" | bc -l)
    local skew_abs=$(echo "scale=4; sqrt($skewness * $skewness)" | bc -l)
    
    # Calculate kurtosis: E[(X-μ)⁴]/σ⁴ - 3
    local m4=0
    for val in "${data_array[@]}"; do
        local z=$(echo "scale=6; ($val - $mean) / $sd" | bc -l)
        local z4=$(echo "scale=6; $z * $z * $z * $z" | bc -l)
        m4=$(echo "scale=6; $m4 + $z4" | bc -l)
    done
    local kurtosis=$(echo "scale=4; ($m4 / $n) - 3" | bc -l)
    local kurt_abs=$(echo "scale=4; sqrt($kurtosis * $kurtosis)" | bc -l)
    
    # Decision criteria (D'Agostino, 1971)
    if (( $(echo "$skew_abs > 1.0" | bc -l) )) || (( $(echo "$kurt_abs > 2.0" | bc -l) )); then
        echo "non_normal|skew=$skewness|kurt=$kurtosis"
        return 1
    else
        echo "approximately_normal|skew=$skewness|kurt=$kurtosis"
        return 0
    fi
}

# =============================================================================
# PARAMETRIC TEST - Welch's t-test (from v6.0)
# =============================================================================

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
    local se=$(echo "scale=6; sqrt(($var1 / $n1) + ($var2 / $n2))" | bc -l)
    
    if (( $(echo "$se == 0" | bc -l) )); then
        echo "0|0|999|zero_variance"
        return 1
    fi
    
    local t_stat=$(echo "scale=6; ($mean1 - $mean2) / $se" | bc -l)
    
    # Welch-Satterthwaite degrees of freedom
    local s1=$(echo "scale=6; $var1 / $n1" | bc -l)
    local s2=$(echo "scale=6; $var2 / $n2" | bc -l)
    local numerator=$(echo "scale=6; ($s1 + $s2) * ($s1 + $s2)" | bc -l)
    local denom=$(echo "scale=6; (($s1 * $s1) / ($n1 - 1)) + (($s2 * $s2) / ($n2 - 1))" | bc -l)
    
    local df=30
    if (( $(echo "$denom > 0" | bc -l) )); then
        df=$(echo "scale=0; $numerator / $denom" | bc -l)
    fi
    
    local p_value=$(t_to_pvalue "$t_stat" "$df")
    
    echo "$t_stat|$p_value|$df|success"
}

t_to_pvalue() {
    local t="$1"
    local df="$2"
    local t_abs=$(echo "scale=6; sqrt($t * $t)" | bc -l)
    
    if (( $(echo "$df > 30" | bc -l) )); then
        if (( $(echo "$t_abs > 3.5" | bc -l) )); then
            echo "0.001"
        elif (( $(echo "$t_abs > 2.576" | bc -l) )); then
            echo "0.01"
        elif (( $(echo "$t_abs > 1.96" | bc -l) )); then
            echo "0.05"
        elif (( $(echo "$t_abs > 1.645" | bc -l) )); then
            echo "0.10"
        else
            echo "0.20"
        fi
    else
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
# NON-PARAMETRIC TEST - Mann-Whitney U (New in v6.1)
# =============================================================================

mann_whitney_u_test() {
    local -n baseline_array="$1"
    local -n candidate_array="$2"
    
    local n1=${#baseline_array[@]}
    local n2=${#candidate_array[@]}
    
    if [[ $n1 -lt 3 ]] || [[ $n2 -lt 3 ]]; then
        echo "0|0|0|insufficient_data"
        return 1
    fi
    
    # Combine arrays with labels
    declare -a combined_values
    declare -a combined_labels
    
    for val in "${baseline_array[@]}"; do
        combined_values+=("$val")
        combined_labels+=("baseline")
    done
    
    for val in "${candidate_array[@]}"; do
        combined_values+=("$val")
        combined_labels+=("candidate")
    done
    
    # Sort with index tracking (bubble sort)
    local n_combined=${#combined_values[@]}
    declare -a sorted_indices
    
    for (( i=0; i<n_combined; i++ )); do
        sorted_indices[i]=$i
    done
    
    for (( i=0; i<n_combined-1; i++ )); do
        for (( j=0; j<n_combined-i-1; j++ )); do
            local idx1=${sorted_indices[j]}
            local idx2=${sorted_indices[j+1]}
            local val1=${combined_values[$idx1]}
            local val2=${combined_values[$idx2]}
            
            if (( $(echo "$val1 > $val2" | bc -l) )); then
                local temp=${sorted_indices[j]}
                sorted_indices[j]=${sorted_indices[j+1]}
                sorted_indices[j+1]=$temp
            fi
        done
    done
    
    # Assign ranks (handle ties)
    declare -a ranks
    for (( i=0; i<n_combined; i++ )); do
        ranks[i]=0
    done
    
    local current_rank=1
    for (( i=0; i<n_combined; i++ )); do
        local idx=${sorted_indices[i]}
        
        # Check for ties
        local tie_count=1
        local tie_sum=$current_rank
        
        while (( i + tie_count < n_combined )); do
            local next_idx=${sorted_indices[i+tie_count]}
            if (( $(echo "${combined_values[$idx]} == ${combined_values[$next_idx]}" | bc -l) )); then
                tie_sum=$(echo "$tie_sum + $current_rank + $tie_count" | bc -l)
                ((tie_count++))
            else
                break
            fi
        done
        
        # Assign average rank
        local avg_rank=$(echo "scale=2; $tie_sum / $tie_count" | bc -l)
        for (( t=0; t<tie_count; t++ )); do
            local tied_idx=${sorted_indices[i+t]}
            ranks[$tied_idx]=$avg_rank
        done
        
        current_rank=$(echo "$current_rank + $tie_count" | bc -l)
        i=$(echo "$i + $tie_count - 1" | bc -l)
    done
    
    # Calculate sum of ranks for baseline
    local R1=0
    for (( i=0; i<n1; i++ )); do
        R1=$(echo "$R1 + ${ranks[i]}" | bc -l)
    done
    
    # Calculate U statistics
    local U1=$(echo "scale=6; $R1 - ($n1 * ($n1 + 1) / 2)" | bc -l)
    local U2=$(echo "scale=6; ($n1 * $n2) - $U1" | bc -l)
    
    local U_stat=$U1
    if (( $(echo "$U2 < $U1" | bc -l) )); then
        U_stat=$U2
    fi
    
    # Calculate z-score (large sample approximation)
    local mu_U=$(echo "scale=6; ($n1 * $n2) / 2" | bc -l)
    local sigma_U=$(echo "scale=6; sqrt(($n1 * $n2 * ($n1 + $n2 + 1)) / 12)" | bc -l)
    
    if (( $(echo "$sigma_U == 0" | bc -l) )); then
        echo "0|0|0|zero_variance"
        return 1
    fi
    
    # Continuity correction
    local U_corrected=$U_stat
    if (( $(echo "$U_stat < $mu_U" | bc -l) )); then
        U_corrected=$(echo "$U_stat + 0.5" | bc -l)
    else
        U_corrected=$(echo "$U_stat - 0.5" | bc -l)
    fi
    
    local z_score=$(echo "scale=6; ($U_corrected - $mu_U) / $sigma_U" | bc -l)
    local p_value=$(z_to_pvalue "$z_score")
    
    echo "$U_stat|$z_score|$p_value|success"
}

z_to_pvalue() {
    local z="$1"
    local z_abs=$(echo "scale=6; sqrt($z * $z)" | bc -l)
    
    if (( $(echo "$z_abs > 3.291" | bc -l) )); then
        echo "0.001"
    elif (( $(echo "$z_abs > 2.576" | bc -l) )); then
        echo "0.01"
    elif (( $(echo "$z_abs > 1.96" | bc -l) )); then
        echo "0.05"
    elif (( $(echo "$z_abs > 1.645" | bc -l) )); then
        echo "0.10"
    elif (( $(echo "$z_abs > 1.28" | bc -l) )); then
        echo "0.20"
    else
        echo "0.50"
    fi
}

# =============================================================================
# AUTOMATIC TEST SELECTION - New in v6.1
# =============================================================================

select_and_run_test() {
    local -n baseline_ref="$1"
    local -n candidate_ref="$2"
    
    # Check normality
    local baseline_normality=$(check_normality baseline_ref)
    local candidate_normality=$(check_normality candidate_ref)
    
    local baseline_is_normal=false
    local candidate_is_normal=false
    
    if [[ "$baseline_normality" == approximately_normal* ]]; then
        baseline_is_normal=true
    fi
    
    if [[ "$candidate_normality" == approximately_normal* ]]; then
        candidate_is_normal=true
    fi
    
    # Decision: Both normal → Welch's t-test, otherwise → Mann-Whitney U
    if [[ "$baseline_is_normal" == true ]] && [[ "$candidate_is_normal" == true ]]; then
        local result=$(welchs_t_test baseline_ref candidate_ref)
        echo "welch|$result|$baseline_normality|$candidate_normality"
    else
        local result=$(mann_whitney_u_test baseline_ref candidate_ref)
        echo "mann_whitney|$result|$baseline_normality|$candidate_normality"
    fi
}

# =============================================================================
# EFFECT SIZE CALCULATIONS
# =============================================================================

# Cohen's d (parametric)
calculate_cohens_d() {
    local mean1="$1"
    local mean2="$2"
    local sd1="$3"
    local sd2="$4"
    local n1="$5"
    local n2="$6"
    
    local var1=$(echo "$sd1 * $sd1" | bc -l)
    local var2=$(echo "$sd2 * $sd2" | bc -l)
    
    local pooled_var=$(echo "scale=6; ((($n1 - 1) * $var1) + (($n2 - 1) * $var2)) / ($n1 + $n2 - 2)" | bc -l)
    local pooled_sd=$(echo "scale=6; sqrt($pooled_var)" | bc -l)
    
    if (( $(echo "$pooled_sd == 0" | bc -l) )); then
        echo "0"
        return
    fi
    
    local d=$(echo "scale=4; ($mean1 - $mean2) / $pooled_sd" | bc -l)
    echo "$d"
}

# Rank-biserial correlation (non-parametric)
calculate_rank_biserial() {
    local U="$1"
    local n1="$2"
    local n2="$3"
    
    local r=$(echo "scale=4; 1 - ((2 * $U) / ($n1 * $n2))" | bc -l)
    echo "$r"
}

# Unified interpretation
interpret_effect_size() {
    local effect="$1"
    local effect_abs=$(echo "scale=4; sqrt($effect * $effect)" | bc -l)
    
    if (( $(echo "$effect_abs < 0.2" | bc -l) )); then
        echo "negligible"
    elif (( $(echo "$effect_abs < 0.5" | bc -l) )); then
        echo "small"
    elif (( $(echo "$effect_abs < 0.8" | bc -l) )); then
        echo "medium"
    else
        echo "large"
    fi
}

# =============================================================================
# APACHEBENCH PARSER
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
# TEST EXECUTION
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
# STATISTICAL CALCULATIONS
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
    echo "RESEARCH-BASED LOAD TESTING v6.1"
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
    
    # Generate reports
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
# REPORT GENERATION
# =============================================================================

generate_research_report_with_hypothesis_testing() {
    echo ""
    echo "GENERATING ENHANCED RESEARCH REPORT..."
    
    generate_standard_report
    generate_hypothesis_testing_report
}

generate_standard_report() {
    cat > "$REPORT_FILE" << 'EOF'
# Research-Based Load Testing Report v6.1

## What's New in v6.1
-  **Mann-Whitney U test** - Non-parametric alternative for skewed data
-  **Automatic test selection** - Parametric vs non-parametric based on data
-  **Normality checking** - Skewness and kurtosis analysis
-  **Enhanced effect sizes** - Rank-biserial correlation for Mann-Whitney U

## Enhancements from v6.0
- Smart locale auto-detection
- Hybrid baseline management (Git-integrated)
- Welch's t-test for normally distributed data
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
# Statistical Hypothesis Testing Report v6.1

## Methodology: Automatic Test Selection

This version automatically selects the most appropriate statistical test:

- **Welch's t-test** (parametric) - When data is approximately normal
- **Mann-Whitney U test** (non-parametric) - When data is skewed or has outliers

**Null Hypothesis (H₀)**: No significant difference between baseline and current test  
**Alternative Hypothesis (H₁)**: Significant difference exists  
**Significance Level (α)**: 0.05 (5%)

## Results

EOF

    for scenario in "${!SCENARIOS[@]}"; do
        baseline_file=$(load_latest_baseline "$scenario")
        
        if [[ -z "$baseline_file" ]]; then
            cat >> "$COMPARISON_REPORT" << EOF
### $scenario
**Status**: No baseline found - this test will be saved as baseline

EOF
            continue
        fi
        
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
        
        # NEW: Automatic test selection
        IFS='|' read -r test_used statistic score p_value status base_norm cand_norm <<< \
            "$(select_and_run_test baseline_array candidate_array)"
        
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
        pct_change=$(echo "scale=2; (($candidate_mean - $baseline_mean) / $baseline_mean) * 100" | bc -l)
        
        # Calculate appropriate effect size
        local effect_size=""
        local effect_metric=""
        
        if [[ "$test_used" == "welch" ]]; then
            baseline_var=$(calculate_variance baseline_array "$baseline_mean")
            candidate_var=$(calculate_variance candidate_array "$candidate_mean")
            baseline_sd=$(echo "scale=3; sqrt($baseline_var)" | bc -l)
            candidate_sd=$(echo "scale=3; sqrt($candidate_var)" | bc -l)
            
            effect_size=$(calculate_cohens_d "$baseline_mean" "$candidate_mean" \
                         "$baseline_sd" "$candidate_sd" "${#baseline_array[@]}" "${#candidate_array[@]}")
            effect_metric="Cohen's d"
        else
            effect_size=$(calculate_rank_biserial "$statistic" "${#baseline_array[@]}" "${#candidate_array[@]}")
            effect_metric="Rank-biserial r"
        fi
        
        effect_interpretation=$(interpret_effect_size "$effect_size")
        
        # Determine verdict
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

**Test Used**: $([ "$test_used" = "welch" ] && echo "**Welch's t-test** (parametric)" || echo "**Mann-Whitney U test** (non-parametric)")  
**Reason**: $([ "$test_used" = "welch" ] && echo "Both samples approximately normal" || echo "Non-normal distribution detected")

| Metric | Value | Interpretation |
|--------|-------|----------------|
| **Test Statistic** | $statistic | $([ "$test_used" = "welch" ] && echo "t-value" || echo "U-value") |
| **p-value** | $p_value | $([ $(echo "$p_value < 0.05" | bc -l) -eq 1 ] && echo "Statistically significant ★" || echo "Not significant") |
| **Effect Size** | $effect_size | $effect_metric |
| **Effect Magnitude** | $effect_interpretation | - |
| **Verdict** | $verdict | - |

#### Distribution Characteristics

- **Baseline**: $base_norm
- **Candidate**: $cand_norm

#### Interpretation

EOF

        if [[ "$test_used" == "welch" ]]; then
            cat >> "$COMPARISON_REPORT" << EOF
**Welch's t-test** was used because both samples showed approximately normal distributions.
This parametric test is more powerful (better at detecting true differences) when normality 
assumptions are met.

EOF
        else
            cat >> "$COMPARISON_REPORT" << EOF
**Mann-Whitney U test** was used because at least one sample showed non-normal distribution 
(high skewness or kurtosis). This non-parametric test is more robust to outliers and skewed 
data, making it ideal for real-world performance metrics which often have long tails (P95/P99).

EOF
        fi
        
        if (( $(echo "$p_value < 0.01" | bc -l) )); then
            echo "- **Very strong evidence** against H₀ (99% confidence)" >> "$COMPARISON_REPORT"
        elif (( $(echo "$p_value < 0.05" | bc -l) )); then
            echo "- **Strong evidence** against H₀ (95% confidence)" >> "$COMPARISON_REPORT"
        else
            echo "- **Insufficient evidence** to reject H₀" >> "$COMPARISON_REPORT"
        fi
        
        echo "- Effect size is **$effect_interpretation** ($effect_metric = $effect_size)" >> "$COMPARISON_REPORT"
        
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

See REFERENCES.md for complete citations.

**Key Methods:**
1. Welch's t-test - Welch (1947)
2. Mann-Whitney U test - Mann & Whitney (1947)
3. Normality testing - D'Agostino (1971)
4. Cohen's d - Cohen (1988)
5. Rank-biserial correlation - Kerby (2014)

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


