# shellcheck shell=bash

extract_samples() {
    local samples_file="$1"
    local total_samples
    total_samples=$(wc -l < "$samples_file")

    # Ensure ITERATIONS and WARMUP_RATIO are set
    : "${ITERATIONS:=1}"
    : "${WARMUP_RATIO:=0}"

    local warmup_count
    warmup_count=$(echo "scale=0; ($total_samples * $WARMUP_RATIO) / 1" | bc -l)

    # Print samples after warm-up
    tail -n +$((warmup_count + 1)) "$samples_file"
}

parse_ab_output() {
    local file="$1"
    local scenario="$2"
    
    if ! grep -q "Requests per second:" "$file"; then
        log_error "Test failed for $scenario - no RPS data"
        echo "ERROR|0|0|0|0|0|0|0|0|0|0|0|0|0"
        return 1
    fi
    
    local rps
    rps=$(grep "Requests per second:" "$file" | awk '{print $4}')
    local time_per_req
    time_per_req=$(grep "Time per request:" "$file" | head -1 | awk '{print $4}')
    local failed
    failed=$(grep "Failed requests:" "$file" | awk '{print $3}')
    local transfer_rate
    transfer_rate=$(grep "Transfer rate:" "$file" | awk '{print $3}')
    
    local connect_line
    connect_line=$(grep "Connect:" "$file")
    local processing_line
    processing_line=$(grep "Processing:" "$file")
    local total_line
    total_line=$(grep "Total:" "$file")
    
    local connect_avg
    connect_avg=$(echo "$connect_line" | awk '{print $4}')
    local processing_avg
    processing_avg=$(echo "$processing_line" | awk '{print $4}')
    local total_avg
    total_avg=$(echo "$total_line" | awk '{print $4}')
    
    local p50
    p50=$(grep -A 20 "Percentage" "$file" | grep "50%" | awk '{print $2}')
    local p90
    p90=$(grep -A 20 "Percentage" "$file" | grep "90%" | awk '{print $2}')
    local p95
    p95=$(grep -A 20 "Percentage" "$file" | grep "95%" | awk '{print $2}')
    local p99
    p99=$(grep -A 20 "Percentage" "$file" | grep "99%" | awk '{print $2}')
    
    [[ -z "$rps" ]] && rps="0"
    [[ -z "$p95" ]] && p95="0"
    [[ -z "$p99" ]] && p99="0"
    [[ -z "$total_avg" ]] && total_avg="0"
    [[ -z "$connect_avg" ]] && connect_avg="0"
    [[ -z "$processing_avg" ]] && processing_avg="0"
    
    : "$p90" # Satisfy ShellCheck unused variable check
    echo "SUCCESS|$rps|$time_per_req|$failed|$transfer_rate|$connect_avg|$processing_avg|$total_avg|$p50|$p90|$p95|$p99|0|0"
}
