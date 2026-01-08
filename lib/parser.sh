# shellcheck shell=bash

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
