# shellcheck shell=bash

capture_system_metrics() {
    local timestamp
    timestamp=$(date +%s)
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_stats
    mem_stats=$(free -m | awk 'NR==2{print $3","$4}')
    local load
    load=$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ' | tr ',' ' ')
    local disk_io
    disk_io=$(iostat -d -k 1 2 2>/dev/null | tail -1 | awk '{print $3","$4}' || echo "0,0")
    
    echo "$timestamp,${cpu_usage:-0},0,$mem_stats,$load,$disk_io" >> "$SYSTEM_METRICS_FILE"
}

run_research_test() {
    local url="$1"
    local scenario="$2"
    local iteration="$3"
    local concurrency="$4"
    
    local temp_file
    temp_file="${REPORT_DIR}/raw_data/${scenario}_iter${iteration}_$(date +%s).txt"
    
    timeout "$TEST_TIMEOUT" "$AB_BIN" -k -n "$AB_REQUESTS" -c "$concurrency" "$url" > "$temp_file" 2>&1
    echo "--- RAW AB OUTPUT FOR $scenario ($iteration) ---" >&2
    cat "$temp_file" >&2
    echo "------------------------------------------------" >&2
    
    local result
    result=$(parse_ab_output "$temp_file" "$scenario")
    echo "$result" > "${temp_file}.parsed"
    
    local think_time
    think_time=$(( (RANDOM % THINK_TIME_MS) + 500 ))
    sleep $(echo "scale=3; $think_time / 1000" | bc)
    
    echo "$result"
}

save_baseline() {
    local scenario="$1"
    local -n data_ref="$2"
    
    local baseline_file
    baseline_file="${BASELINE_DIR}/${BASELINE_PREFIX}_baseline_${scenario}_$(date +%Y%m%d).csv"
    
    echo "iteration,rps,response_time_ms,p95_ms,p99_ms,connect_ms,processing_ms" > "$baseline_file"
    
    local iteration=1
    local -a rps_array
    read -ra rps_array <<< "$data_ref"
    for val in "${rps_array[@]}"; do
        echo "$iteration,$val,0,0,0,0,0" >> "$baseline_file"
        ((iteration++))
    done
    
    if [[ "$USE_GIT_TRACKING" == true ]] && command -v git &>/dev/null;
    then
        if git -C "$BASE_DIR" rev-parse --git-dir &>/dev/null;
        then
            git -C "$BASE_DIR" add "$baseline_file" 2>/dev/null || true
        fi
    fi
    
    echo "$baseline_file"
}

load_latest_baseline() {
    local scenario="$1"
    local baseline_file
    # shellcheck disable=SC2012
    baseline_file=$(ls -t "${BASELINE_DIR}/${BASELINE_PREFIX}_baseline_${scenario}_"*.csv 2>/dev/null | head -1)
    if [[ -z "$baseline_file" ]] || [[ ! -f "$baseline_file" ]]; then echo ""; return 0; fi
    echo "$baseline_file"
    return 0
}

load_baseline_data() {
    local baseline_file="$1"
    local metric_column="$2"
    if [[ ! -f "$baseline_file" ]]; then echo ""; return 1; fi
    local values
    values=$(tail -n +2 "$baseline_file" | cut -d',' -f"$metric_column" | tr '\n' ' ')
    echo "$values"
}