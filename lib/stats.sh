# shellcheck shell=bash

# BASE_DIR is expected to be defined by the sourcing script (bin/dlt.sh)
STATS_PY="${BASE_DIR}/lib/stats.py"

if [[ ! -x "$STATS_PY" ]]; then
    chmod +x "$STATS_PY" 2>/dev/null || true
fi

calculate_mean() {
    local -n array="$1"
    printf "%s\n" "${array[@]}" | "$STATS_PY" calculate_statistics | cut -d'|' -f1
}

calculate_variance() {
    local -n array="$1"
    printf "%s\n" "${array[@]}" | "$STATS_PY" calculate_statistics | cut -d'|' -f11
}

# Pipe-compatible wrappers for unit tests (TDD parity)
mean() {
    "$STATS_PY" calculate_statistics | cut -d'|' -f1 | sed 's/\.0+$//' | sed 's/\.0*$//' # Strip trailing zeros for test parity
}

stddev() {
    "$STATS_PY" calculate_statistics | cut -d'|' -f3
}

percentile() {
    local p="$1"
    local field=6 # Default p90
    [[ "$p" == "95" ]] && field=7
    [[ "$p" == "99" ]] && field=8
    "$STATS_PY" calculate_statistics | cut -d"|" -f$field | sed 's/\.0+$//' | sed 's/\.0*$//'
}

ci_bounds() {
    "$STATS_PY" calculate_statistics | cut -d'|' -f9,10 | tr '|' ' '
}

# Redefining the wrapper more robustly
calculate_statistics() {
    local values_str="$1"
    # shellcheck disable=SC2086
    echo "$values_str" | "$STATS_PY" calculate_statistics
}

welchs_t_test() {
    local -n baseline_array="$1"
    local -n candidate_array="$2"
    
    { printf "%s\n" "${baseline_array[@]}"; echo "---"; printf "%s\n" "${candidate_array[@]}"; } | \
        "$STATS_PY" hypothesis_test | grep "^welch" | cut -d'|' -f2,3,4,5
    # The output format should match what report.sh expects
}

mann_whitney_u_test() {
    local -n baseline_array="$1"
    local -n candidate_array="$2"
    
    { printf "%s\n" "${baseline_array[@]}"; echo "---"; printf "%s\n" "${candidate_array[@]}"; } | \
        "$STATS_PY" hypothesis_test | grep "^mann_whitney" | cut -d'|' -f2,3,4,5
}

select_and_run_test() {
    local -n baseline_ref="$1"
    local -n candidate_ref="$2"
    
    { printf "%s\n" "${baseline_ref[@]}"; echo "---"; printf "%s\n" "${candidate_ref[@]}"; } | \
        "$STATS_PY" hypothesis_test
}

# Legacy support/helpers
calculate_cohens_d() {
    # Call Python for this too if needed, but keeping it simple for now
    # Actually, it's better to let Python handle the whole comparison
    :
}
