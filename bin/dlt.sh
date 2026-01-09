#!/bin/bash
set -euo pipefail

# =============================================================================
# LOCALE CONFIGURATION - Smart Auto-Detection
# =============================================================================
detect_and_configure_locale() {
    local current_locale="${LC_NUMERIC:-${LC_ALL:-${LANG:-C}}}"
    local test_decimal
    test_decimal=$(printf "%.2f" 3.14 2>/dev/null | cut -d'.' -f2)
    if [[ "$test_decimal" == "14" ]]; then
        if echo "scale=2; 3.14 * 2" | bc -l &>/dev/null; then
            export LC_NUMERIC="$current_locale"
            return 0
        fi
    fi
    for try_locale in "C" "en_US.UTF-8" "en_GB.UTF-8" "POSIX"; do
        if locale -a 2>/dev/null | grep -qiE "^${try_locale}"; then
            export LC_NUMERIC="$try_locale"
            export LANG="${LANG:-$try_locale}"
            return 0
        fi
    done
    export LC_NUMERIC="C"
    export LANG="C"
    return 0
}

detect_and_configure_locale

# SCRIPT DIRECTORY
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# =============================================================================
# SOURCES
# =============================================================================
source "$BASE_DIR/config/dlt.conf"
source "$BASE_DIR/lib/parser.sh"
source "$BASE_DIR/lib/stats.sh"
source "$BASE_DIR/lib/normality.sh"
source "$BASE_DIR/lib/runner.sh"
source "$BASE_DIR/lib/report.sh"

APP_ENV=$(detect_environment)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Environment-specific baseline directories
if [[ "$APP_ENV" == "production" ]]; then
    BASELINE_DIR="${BASE_DIR}/baselines"
    BASELINE_PREFIX="production"
    USE_GIT_TRACKING=true
else
    BASELINE_DIR="${BASE_DIR}/.dlt_local"
    BASELINE_PREFIX="${APP_ENV}"
    USE_GIT_TRACKING=false
fi

mkdir -p "$BASELINE_DIR"
REPORT_DIR="${BASE_DIR}/load_test_reports_${TIMESTAMP}"
mkdir -p "${REPORT_DIR}/raw_data"
mkdir -p "${REPORT_DIR}/charts"

REPORT_FILE="${REPORT_DIR}/research_report_${TIMESTAMP}.md"
SYSTEM_METRICS_FILE="${REPORT_DIR}/system_metrics.csv"
ERROR_LOG="${REPORT_DIR}/error_log.txt"
COMPARISON_REPORT="${REPORT_DIR}/hypothesis_testing_${TIMESTAMP}.md"

# Initialize logs
echo "timestamp,cpu_user,cpu_system,memory_used,memory_free,load_1,load_5,load_15,disk_read_kb,disk_write_kb" > "$SYSTEM_METRICS_FILE"
true > "$ERROR_LOG"

log_error() { echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ERROR_LOG" >&2; }
log_info() { echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${REPORT_DIR}/execution.log"; }

main() {
    if [[ "${1:-}" == "--dry-run" ]]; then
        echo "Dry run: Configuration loaded. Exiting."
        exit 0
    fi

    echo "========================================="
    echo "RESEARCH-BASED LOAD TESTING v6.2"
    echo "Environment: ${APP_ENV^^}"
    echo "Baseline Mode: $([ "$USE_GIT_TRACKING" = true ] && echo 'Git-Tracked (Production)' || echo 'Local Development')"
    echo "========================================="
    
    (while true; do capture_system_metrics; sleep 5; done) &
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
    
    # Phase 1: Warm-up
    echo ""
    echo "PHASE 1: WARM-UP"
    echo "--------------------------------------------------"
    for (( i=1; i<=WARMUP_ITERATIONS; i++ )); do
        for scenario in "${!SCENARIOS[@]}"; do
            result=$(run_research_test "${SCENARIOS[$scenario]}" "$scenario" "warmup_$i" $((AB_CONCURRENCY / 4)))
            IFS='|' read -r status rps _ _ _ _ _ _ _ _ p95 p99 _ _ <<< "$result"
            if [[ "$status" == "SUCCESS" ]]; then printf "  ✓ %-20s: %6.1f req/s\n" "$scenario" "$rps"
            else ERROR_COUNTS[$scenario]=$((ERROR_COUNTS[$scenario] + 1)); fi
        done
    done
    
    # Phase 2: Ramp-up
    echo "PHASE 2: RAMP-UP"
    for (( i=1; i<=RAMPUP_ITERATIONS; i++ )); do
        current_concurrency=$(( (AB_CONCURRENCY / 4) + ((AB_CONCURRENCY * 3 / 4) * i / RAMPUP_ITERATIONS) ))
        for scenario in "${!SCENARIOS[@]}"; do
            result=$(run_research_test "${SCENARIOS[$scenario]}" "$scenario" "rampup_$i" "$current_concurrency")
            IFS='|' read -r status rps _ _ _ connect_avg processing_avg total _ _ p95 p99 _ _ <<< "$result"
            if [[ "$status" == "SUCCESS" ]]; then
                RPS_VALUES[$scenario]+="$rps "
                P95_VALUES[$scenario]+="$p95 "
                P99_VALUES[$scenario]+="$p99 "
                RESPONSE_TIME_VALUES[$scenario]+="$total "
                CONNECT_VALUES[$scenario]+="$connect_avg "
                PROCESSING_VALUES[$scenario]+="$processing_avg "
            fi
        done
    done
    
    # Phase 3: Sustained
    echo "PHASE 3: SUSTAINED LOAD"
    for (( i=1; i<=SUSTAINED_ITERATIONS; i++ )); do
        for scenario in "${!SCENARIOS[@]}"; do
            result=$(run_research_test "${SCENARIOS[$scenario]}" "$scenario" "sustained_$i" "$AB_CONCURRENCY")
            IFS='|' read -r status rps _ _ _ connect_avg processing_avg total _ _ p95 p99 _ _ <<< "$result"
            if [[ "$status" == "SUCCESS" ]]; then
                RPS_VALUES[$scenario]+="$rps "
                P95_VALUES[$scenario]+="$p95 "
                P99_VALUES[$scenario]+="$p99 "
                RESPONSE_TIME_VALUES[$scenario]+="$total "
                CONNECT_VALUES[$scenario]+="$connect_avg "
                PROCESSING_VALUES[$scenario]+="$processing_avg "
            fi
        done
        if (( i % 100 == 0 )); then echo "Progress: $((i * 100 / SUSTAINED_ITERATIONS))%"; fi
    done
    
    kill "$MONITOR_PID" 2>/dev/null || true
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    generate_research_report_with_hypothesis_testing
    
    echo ""
    echo "SAVING BASELINES..."
    for scenario in "${!SCENARIOS[@]}"; do
        baseline_file=$(save_baseline "$scenario" RPS_VALUES["$scenario"])
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

trap 'echo "Test interrupted"; kill $MONITOR_PID 2>/dev/null || true; exit 1' INT TERM
main "$@"
