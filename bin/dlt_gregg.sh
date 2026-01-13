#!/bin/bash
# shellcheck disable=SC1091
set -euo pipefail

# =============================================================================
# ENHANCED RESEARCH-BASED LOAD TESTING v6.3 + Brendan Gregg Integration
# =============================================================================

# LOCALE CONFIGURATION - Smart Auto-Detection
detect_and_configure_locale() {
    export LC_NUMERIC="C"
    export LANG="C"
    return 0
}

detect_and_configure_locale

# SCRIPT DIRECTORY
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load enhanced configuration
# shellcheck source=config/dlt.conf
source "$BASE_DIR/config/dlt.conf"
# shellcheck source=config/dlt_gregg.conf
source "$BASE_DIR/config/dlt_gregg.conf"

# SOURCES - Enhanced with Gregg's modules
# shellcheck source=lib/parser.sh
source "$BASE_DIR/lib/parser.sh"
# shellcheck source=lib/stats.sh
source "$BASE_DIR/lib/stats.sh"
# shellcheck source=lib/normality.sh
source "$BASE_DIR/lib/normality.sh"
# shellcheck source=lib/runner.sh
source "$BASE_DIR/lib/runner.sh"
# shellcheck source=lib/report.sh
source "$BASE_DIR/lib/report.sh"
# shellcheck source=lib/gregg_profiling.sh
source "$BASE_DIR/lib/gregg_profiling.sh"
# shellcheck source=lib/kernel_metrics.sh
source "$BASE_DIR/lib/kernel_metrics.sh"

# Detect environment
detect_environment() {
    local env_file="${BASE_DIR}/.env"
    if [[ -f "$env_file" ]]; then
        local app_env
        app_env=$(grep -E '^APP_ENV=' "$env_file" | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
        if [[ -n "$app_env" ]]; then echo "$app_env"; return 0; fi
    fi
    echo "local"
}

# Auto-detect target application PID
detect_target_pid() {
    # Try to find the web server process
    local web_server_pids=""
    
    # Common web server processes
    for process in "apache2" "httpd" "nginx" "node" "php-fpm" "gunicorn" "uwsgi"; do
        local pids
        pids=$(pgrep "$process" 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            web_server_pids="$pids"
            break
        fi
    done
    
    # If multiple PIDs found, pick the first one
    if [[ -n "$web_server_pids" ]]; then
        echo "$web_server_pids" | head -1
    else
        echo ""
    fi
}

APP_ENV=$(detect_environment)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Environment-specific baseline directories
if [[ "$APP_ENV" == "production" ]]; then
    BASELINE_DIR="${BASE_DIR}/baselines"
    USE_GIT_TRACKING=true
else
    BASELINE_DIR="${BASE_DIR}/.dlt_local"
    # shellcheck disable=SC2034
    BASELINE_PREFIX="${APP_ENV}"
    USE_GIT_TRACKING=false
fi

mkdir -p "$BASELINE_DIR"
REPORT_DIR="${BASE_DIR}/load_test_reports_${TIMESTAMP}"
mkdir -p "${REPORT_DIR}/raw_data"
mkdir -p "${REPORT_DIR}/charts"
mkdir -p "${REPORT_DIR}/${GREGG_OUTPUT_DIR}"
mkdir -p "${REPORT_DIR}/${KERNEL_OUTPUT_DIR}"
mkdir -p "${REPORT_DIR}/${FLAMEGRAPH_DIR}"

REPORT_FILE="${REPORT_DIR}/research_report_${TIMESTAMP}.md"
SYSTEM_METRICS_FILE="${REPORT_DIR}/system_metrics.csv"
ERROR_LOG="${REPORT_DIR}/error_log.txt"
COMPARISON_REPORT="${REPORT_DIR}/hypothesis_testing_${TIMESTAMP}.md"

# Initialize logs
echo "timestamp,cpu_user,cpu_system,memory_used,memory_free,load_1,load_5,load_15,disk_read_kb,disk_write_kb" > "$SYSTEM_METRICS_FILE"
true > "$ERROR_LOG"

log_error() { echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ERROR_LOG" >&2; }
log_info() { echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${REPORT_DIR}/execution.log"; }

# Enhanced system monitoring with Gregg's metrics
enhanced_capture_system_metrics() {
    local output_file="$1"
    
    # Original metrics (for backward compatibility)
    capture_system_metrics "$output_file"
    
    # Enhanced Gregg metrics
    if [[ "$ENABLE_KERNEL_METRICS" == "true" ]]; then
        capture_gregg_system_metrics "${REPORT_DIR}/${GREGG_OUTPUT_DIR}/enhanced_system_metrics.csv"
    fi
}

main() {
    echo "========================================="
    echo "ENHANCED RESEARCH-BASED LOAD TESTING v6.3"
    echo "Brendan Gregg's System Performance Integration"
    echo "Environment: ${APP_ENV^^}"
    echo "Baseline Mode: $([ "$USE_GIT_TRACKING" = true ] && echo 'Git-Tracked (Production)' || echo 'Local Development')"
    echo "Gregg Profiling: $([ "$ENABLE_GREGG_PROFILING" = true ] && echo 'ENABLED' || echo 'DISABLED')"
    echo "========================================="
    
    # Auto-detect target PID if not specified
    if [[ -z "$TARGET_APP_PID" ]] || [[ "$TARGET_APP_PID" == "auto" ]]; then
        TARGET_APP_PID=$(detect_target_pid)
        if [[ -n "$TARGET_APP_PID" ]]; then
            log_info "Auto-detected target application PID: $TARGET_APP_PID"
        else
            log_info "No target PID detected - will use system-wide profiling only"
        fi
    fi
    
    # Start Brendan Gregg's comprehensive profiling
    if [[ "$ENABLE_GREGG_PROFILING" == "true" ]]; then
        log_info "Starting Brendan Gregg's comprehensive system profiling..."
        start_comprehensive_profiling "${REPORT_DIR}/${GREGG_OUTPUT_DIR}" "$TARGET_APP_PID" "$TARGET_INTERFACE"
    fi
    
    # Start kernel-level metrics collection
    if [[ "$ENABLE_KERNEL_METRICS" == "true" ]]; then
        log_info "Starting kernel-level metrics collection..."
        start_kernel_metrics_collection "$REPORT_DIR" "$TARGET_APP_PID"
    fi
    
    # Start enhanced system metrics monitoring
    (while true; do enhanced_capture_system_metrics "$SYSTEM_METRICS_FILE"; sleep "$SYSTEM_METRICS_INTERVAL"; done) &
    MONITOR_PID=$!
    
    declare -A RPS_VALUES P95_VALUES P99_VALUES RESPONSE_TIME_VALUES CONNECT_VALUES PROCESSING_VALUES ERROR_COUNTS
    for scenario in "${!SCENARIOS[@]}"; do
        RPS_VALUES[$scenario]=""
        P95_VALUES[$scenario]=""
        P99_VALUES[$scenario]=""
        RESPONSE_TIME_VALUES[$scenario]=""
        CONNECT_VALUES[$scenario]=""
        PROCESSING_VALUES[$scenario]=""
        ERROR_COUNTS[$scenario]=0
    done
    
    START_TIME=$(date +%s)
    
    # Phase 1: Warm-up with Gregg's profiling
    echo ""
    echo "PHASE 1: WARM-UP (with system profiling)"
    echo "--------------------------------------------------"
    for (( i=1; i<=WARMUP_ITERATIONS; i++ )); do
        for scenario in "${!SCENARIOS[@]}"; do
            url="${SCENARIOS[$scenario]}"
            concurrency="${CONCURRENCY[$scenario]:-$AB_CONCURRENCY}"
            
            result=$(run_research_test "$url" "$scenario" "$i" "$concurrency")
            IFS='|' read -r rps response_time p95 p99 connect_time processing_time failed_requests <<< "$result"
            
            # Store results (only successful ones for statistics)
            if [[ "$failed_requests" -eq 0 ]]; then
                RPS_VALUES[$scenario]+="$rps "
                P95_VALUES[$scenario]+="$p95 "
                P99_VALUES[$scenario]+="$p99 "
                RESPONSE_TIME_VALUES[$scenario]+="$response_time "
                CONNECT_VALUES[$scenario]+="$connect_time "
                PROCESSING_VALUES[$scenario]+="$processing_time "
            else
                ERROR_COUNTS[$scenario]=$((ERROR_COUNTS[$scenario] + 1))
            fi
            
            printf " Warmup %3d/%3d - %-15s: %7.2f req/s (P95: %6.1fms)\n" \
                "$i" "$WARMUP_ITERATIONS" "$scenario" "$rps" "$p95"
        done
        
        # Enhanced think time with system monitoring during warmup
        local think_time=$(( (RANDOM % THINK_TIME_MS) + 500 ))
        sleep "$(echo "scale=3; $think_time / 1000" | bc)"
    done
    
    # Phase 2: Ramp-up
    echo ""
    echo "PHASE 2: RAMP-UP (increasing load)"
    echo "--------------------------------------------------"
    for (( i=1; i<=RAMPUP_ITERATIONS; i++ )); do
        # Gradually increase concurrency
        local ramp_factor=$((i * 20 / RAMPUP_ITERATIONS))
        local base_concurrency=${CONCURRENCY[$DYNAMIC]:-$AB_CONCURRENCY}
        local dynamic_concurrency=$((base_concurrency + ramp_factor))
        
        for scenario in "${!SCENARIOS[@]}"; do
            url="${SCENARIOS[$scenario]}"
            local concurrency="${CONCURRENCY[$scenario]:-$AB_CONCURRENCY}"
            
            # Apply ramp-up to dynamic scenarios only
            if [[ "$scenario" == "DYNAMIC" ]]; then
                concurrency=$dynamic_concurrency
            fi
            
            result=$(run_research_test "$url" "$scenario" "$i" "$concurrency")
            IFS='|' read -r rps response_time p95 p99 connect_time processing_time failed_requests <<< "$result"
            
            if [[ "$failed_requests" -eq 0 ]]; then
                RPS_VALUES[$scenario]+="$rps "
                P95_VALUES[$scenario]+="$p95 "
                P99_VALUES[$scenario]+="$p99 "
                RESPONSE_TIME_VALUES[$scenario]+="$response_time "
                CONNECT_VALUES[$scenario]+="$connect_time "
                PROCESSING_VALUES[$scenario]+="$processing_time "
            else
                ERROR_COUNTS[$scenario]=$((ERROR_COUNTS[$scenario] + 1))
            fi
            
            printf " Ramp-up %3d/%3d - %-15s: %7.2f req/s (P95: %6.1fms, Concurrency: %2d)\n" \
                "$i" "$RAMPUP_ITERATIONS" "$scenario" "$rps" "$p95" "$concurrency"
        done
        
        sleep "$(echo "scale=3; $THINK_TIME_MS / 1000" | bc)"
    done
    
    # Phase 3: Sustained Load with Enhanced Monitoring
    echo ""
    echo "PHASE 3: SUSTAINED LOAD (comprehensive monitoring)"
    echo "--------------------------------------------------"
    for (( i=1; i<=SUSTAINED_ITERATIONS; i++ )); do
        for scenario in "${!SCENARIOS[@]}"; do
            url="${SCENARIOS[$scenario]}"
            concurrency="${CONCURRENCY[$scenario]:-$AB_CONCURRENCY}"
            
            result=$(run_research_test "$url" "$scenario" "$i" "$concurrency")
            IFS='|' read -r rps response_time p95 p99 connect_time processing_time failed_requests <<< "$result"
            
            if [[ "$failed_requests" -eq 0 ]]; then
                RPS_VALUES[$scenario]+="$rps "
                P95_VALUES[$scenario]+="$p95 "
                P99_VALUES[$scenario]+="$p99 "
                RESPONSE_TIME_VALUES[$scenario]+="$response_time "
                CONNECT_VALUES[$scenario]+="$connect_time "
                PROCESSING_VALUES[$scenario]+="$processing_time "
            else
                ERROR_COUNTS[$scenario]=$((ERROR_COUNTS[$scenario] + 1))
            fi
            
            # Progress indicator every 100 iterations
            if (( i % 100 == 0 )); then
                echo "Progress: $((i * 100 / SUSTAINED_ITERATIONS))% complete"
            fi
        done
        
        sleep "$(echo "scale=3; $THINK_TIME_MS / 1000" | bc)"
    done
    
    END_TIME=$(date +%s)
    TOTAL_DURATION=$((END_TIME - START_TIME))
    
    # Stop all profiling sessions
    echo ""
    echo "Stopping profiling sessions..."
    kill $MONITOR_PID 2>/dev/null || true
    
    if [[ "$ENABLE_GREGG_PROFILING" == "true" ]]; then
        stop_system_profiling "${REPORT_DIR}/${GREGG_OUTPUT_DIR}"
    fi
    
    if [[ "$ENABLE_KERNEL_METRICS" == "true" ]]; then
        stop_kernel_metrics_collection "$REPORT_DIR"
    fi
    
    # Generate comprehensive reports
    echo ""
    echo "Generating comprehensive analysis reports..."
    
    # Original research report
    generate_research_report "$REPORT_FILE"
    
    # Enhanced Gregg analysis reports
    if [[ "$ENABLE_GREGG_PROFILING" == "true" ]]; then
        for scenario in "${!SCENARIOS[@]}"; do
            generate_gregg_analysis_report "${REPORT_DIR}/${GREGG_OUTPUT_DIR}" "$scenario"
        done
        
        # Generate flame graphs if enabled
        if [[ "$ENABLE_FLAME_GRAPHS" == "true" ]]; then
            for scenario in "${!SCENARIOS[@]}"; do
                generate_flame_graph "${REPORT_DIR}/${GREGG_OUTPUT_DIR}" "$scenario"
            done
        fi
    fi
    
    # Kernel-level analysis
    if [[ "$ENABLE_KERNEL_METRICS" == "true" ]]; then
        for scenario in "${!SCENARIOS[@]}"; do
            generate_kernel_analysis_report "$REPORT_DIR" "$scenario"
        done
    fi
    
    # Baseline comparison
    local baseline_file
    baseline_file=$(load_latest_baseline "DYNAMIC")
    if [[ -n "$baseline_file" ]]; then
        baseline_rps=$(load_baseline_data "$baseline_file" 2)
        echo "Comparing against baseline: $baseline_file"
        
        # Convert to arrays
        local -a baseline_rps_array candidate_rps_array
        read -ra baseline_rps_array <<< "$baseline_rps"
        read -ra candidate_rps_array <<< "${RPS_VALUES[DYNAMIC]}"
        
        if [[ ${#baseline_rps_array[@]} -gt 0 ]] && [[ ${#candidate_rps_array[@]} -gt 0 ]]; then
            echo "Performing statistical hypothesis testing..."
            local test_result
            test_result=$(select_and_run_test baseline_rps_array candidate_rps_array)
            
            # Generate hypothesis testing report
            generate_hypothesis_testing_report "$COMPARISON_REPORT" "DYNAMIC" "$test_result" "$baseline_file"
            
            # Optionally save as new baseline
            save_baseline "DYNAMIC" RPS_VALUES[DYNAMIC]
        fi
    else
        echo "No baseline found. Creating new baseline..."
        save_baseline "DYNAMIC" RPS_VALUES[DYNAMIC]
    fi
    
    # Final summary
    echo ""
    echo "========================================="
    echo "Enhanced Load Testing Complete!"
    echo "========================================="
    echo "Total Duration: ${TOTAL_DURATION}s"
    echo "Reports Directory: $REPORT_DIR"
    
    if [[ "$ENABLE_GREGG_PROFILING" == "true" ]]; then
        echo "Gregg Analysis: ${REPORT_DIR}/${GREGG_OUTPUT_DIR}/"
    fi
    
    if [[ "$ENABLE_KERNEL_METRICS" == "true" ]]; then
        echo "Kernel Metrics: ${REPORT_DIR}/${KERNEL_OUTPUT_DIR}/"
    fi
    
    if [[ "$ENABLE_FLAME_GRAPHS" == "true" ]]; then
        echo "Flame Graphs: ${REPORT_DIR}/${FLAMEGRAPH_DIR}/"
    fi
    
    echo "Main Report: $REPORT_FILE"
    echo "Statistical Analysis: $COMPARISON_REPORT"
    echo "========================================="
}

# Trap for cleanup
trap 'echo "Test interrupted - stopping profiling..."; 
       [[ "$ENABLE_GREGG_PROFILING" == "true" ]] && stop_system_profiling "${REPORT_DIR}/${GREGG_OUTPUT_DIR}" 2>/dev/null || true;
       [[ "$ENABLE_KERNEL_METRICS" == "true" ]] && stop_kernel_metrics_collection "$REPORT_DIR" 2>/dev/null || true;
       exit 1' INT TERM

# Check for required tools
echo "Checking required tools..."
for cmd in "$AB_BIN" bc awk grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Required command '$cmd' not found"
        exit 1
    fi
done

# Check Gregg's tools if enabled
if [[ "$ENABLE_GREGG_PROFILING" == "true" ]]; then
    check_gregg_tools || echo "Warning: Some Gregg tools not available - analysis will be limited"
fi

# Check privileges for profiling
if [[ "$REQUIRE_ROOT_FOR_PROFILING" == "true" ]] && [[ "$EUID" -ne 0 ]] && [[ "$ENABLE_GREGG_PROFILING" == "true" ]]; then
    echo "WARNING: Running without root privileges. Some Gregg profiling features may be limited."
    echo "Consider running with sudo for full system visibility."
fi

main "$@"