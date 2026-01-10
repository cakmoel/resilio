# shellcheck shell=bash

check_normality() {
    local -n data_array="$1"
    local n=${#data_array[@]}
    
    if [[ $n -lt 20 ]]; then
        echo "insufficient_data"
        return 1
    fi
    
    local mean
    mean=$(calculate_mean data_array)
    local variance
    variance=$(calculate_variance data_array "$mean")
    local sd
    sd=$(echo "scale=6; sqrt($variance)" | bc -l)
    
    if (( $(echo "$sd == 0" | bc -l) )); then
        echo "zero_variance"
        return 1
    fi
    
    local m3=0
    for val in "${data_array[@]}"; do
        local z
        z=$(echo "scale=6; ($val - $mean) / $sd" | bc -l)
        local z3
        z3=$(echo "scale=6; $z * $z * $z" | bc -l)
        m3=$(echo "scale=6; $m3 + $z3" | bc -l)
    done
    local skewness
    skewness=$(echo "scale=4; $m3 / $n" | bc -l)
    local skew_abs
    skew_abs=$(echo "scale=4; sqrt($skewness * $skewness)" | bc -l)
    
    local m4=0
    for val in "${data_array[@]}"; do
        local z
        z=$(echo "scale=6; ($val - $mean) / $sd" | bc -l)
        local z4
        z4=$(echo "scale=6; $z * $z * $z * $z" | bc -l)
        m4=$(echo "scale=6; $m4 + $z4" | bc -l)
    done
    local kurtosis
    kurtosis=$(echo "scale=4; ($m4 / $n) - 3" | bc -l)
    local kurt_abs
    kurt_abs=$(echo "scale=4; sqrt($kurtosis * $kurtosis)" | bc -l)
    
    if (( $(echo "$skew_abs > 1.0" | bc -l) )) || (( $(echo "$kurt_abs > 2.0" | bc -l) )); then
        echo "non_normal|skew=$skewness|kurt=$kurtosis"
        return 1
    else
        echo "approximately_normal|skew=$skewness|kurt=$kurtosis"
        return 0
    fi
}

choose_test() {
    local n="$1"
    local skew_abs="$2"
    local kurt_abs="$3"

    # Simplified logic for test selection based on parameters
    if (( $(echo "$n >= 30" | bc -l) )) && (( $(echo "$skew_abs <= 1.0" | bc -l) )) && (( $(echo "$kurt_abs <= 2.0" | bc -l) )); then
        echo "welch"
    else
        echo "mann-whitney"
    fi
}

select_and_run_test() {
    local -n baseline_ref="$1"
    local -n candidate_ref="$2"
    
    local baseline_normality
    baseline_normality=$(check_normality baseline_ref)
    local candidate_normality
    candidate_normality=$(check_normality candidate_ref)
    
    local baseline_is_normal=false
    local candidate_is_normal=false
    
    if [[ "$baseline_normality" == approximately_normal* ]]; then
        baseline_is_normal=true
    fi
    
    if [[ "$candidate_normality" == approximately_normal* ]]; then
        candidate_is_normal=true
    fi
    
    if [[ "$baseline_is_normal" == true ]] && [[ "$candidate_is_normal" == true ]]; then
        local result
        result=$(welchs_t_test baseline_ref candidate_ref)
        echo "welch|$result|$baseline_normality|$candidate_normality"
    else
        local result
        result=$(mann_whitney_u_test baseline_ref candidate_ref)
        echo "mann_whitney|$result|$baseline_normality|$candidate_normality"
    fi
}
