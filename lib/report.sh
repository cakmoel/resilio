# shellcheck shell=bash

init_report() {
  REPORT="$OUT_DIR/report.md"
  echo "# DLT Research Report" > "$REPORT"
}

append_result() {
  local name="$1" n="$2" mean="$3" sd="$4" p95="$5" p99="$6" test="$7"
  cat >> "$REPORT" <<EOF

## $name
Samples: $n  
Test: $test  

Mean: $mean  
StdDev: $sd  
P95: $p95  
P99: $p99  

EOF
}

run_all_scenarios() {
  init_report
  for s in "${!SCENARIOS[@]}"; do
    run_scenario "$s" "${SCENARIOS[$s]}"
    data="$(extract_samples "$s")"
    n=$(echo "$data" | wc -l)
    m=$(echo "$data" | mean)
    sd=$(echo "$data" | stddev)
    p95=$(echo "$data" | percentile 95)
    p99=$(echo "$data" | percentile 99)
    sk=$(echo "$data" | skewness)
    ku=$(echo "$data" | kurtosis)
    test=$(select_test "$n" "$sk" "$ku")
    append_result "$s" "$n" "$m" "$sd" "$p95" "$p99" "$test"
  done
}

finalize_report() {
  echo "Report written to $REPORT"
}
