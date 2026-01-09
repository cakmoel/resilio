# shellcheck shell=bash
# BASE_DIR and STATS_PY are provided by lib/stats.sh (sourced earlier)

check_normality() {
    local -n data_array="$1"
    printf "%s\n" "${data_array[@]}" | "$STATS_PY" check_normality
}

select_and_run_test() {
    local -n baseline_ref="$1"
    local -n candidate_ref="$2"
    
    local output
    output=$( { printf "%s\n" "${baseline_ref[@]}"; echo "---"; printf "%s\n" "${candidate_ref[@]}"; } | "$STATS_PY" hypothesis_test )
    
    local test_used p_val effect b_norm c_norm
    IFS='|' read -r test_used _ _ p_val _ effect b_norm c_norm <<< "$output"
    
    echo "$test_used|$p_val|$effect|$b_norm|$c_norm"
}

choose_test() {
    local n="$1"
    local skew="$2"
    local kurtosis="$3"

    # Use bc for floating point comparisons
    if (( $(echo "$n < 30" | bc -l) )); then
        echo "mann-whitney"
        return
    fi

    # Check for absolute value of skew
    if (( $(echo "($skew > 1.0) || ($skew < -1.0)" | bc -l) )); then
        echo "mann-whitney"
        return
    fi

    # Check for absolute value of kurtosis
    if (( $(echo "($kurtosis > 2.0) || ($kurtosis < -2.0)" | bc -l) )); then
        echo "mann-whitney"
        return
    fi

    echo "welch"
}

