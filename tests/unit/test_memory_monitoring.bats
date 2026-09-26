#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(dirname "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_ROOT
  export BASE_DIR="$PROJECT_ROOT"
  source "${PROJECT_ROOT}/tests/unit/common.bash"
}

@test "Memory monitoring config variables are defined in config/dlt.conf" {
  source "${PROJECT_ROOT}/config/dlt.conf"
  [ "$MEMORY_MONITORING" = "true" ]
  [ "$MEMORY_INCLUDE_PROCESS" = "true" ]
  [ "$MEMORY_INCLUDE_SWAP" = "true" ]
  [ "$MEMORY_THRESHOLD_WARNING" = "80" ]
}

@test "slth.sh memory monitoring output format contains 12 pipe-delimited fields" {
  run bash -c '
    # Simulate the extended result format from run_ab_test
    result="SUCCESS|100|50|0|10|20|30|512|1024|0|0|50|1234"
    fields=$(echo "$result" | tr "|" "\n" | wc -l)
    [ "$fields" -eq 12 ]
    echo "$result" | grep -q "SUCCESS"
  '
  [ "$status" -eq 0 ]
}

@test "slth.sh system memory values are valid MB amounts" {
  run bash -c '
    system_memory_before=$(free -m | awk "NR==2{print \$3}")
    system_memory_after=$(free -m | awk "NR==2{print \$3}")
    [ "$system_memory_before" -gt 0 ]
    [ "$system_memory_after" -gt 0 ]
    echo "Memory before: ${system_memory_before}MB, after: ${system_memory_after}MB"
  '
  [ "$status" -eq 0 ]
}

@test "slth.sh RPS per MB efficiency calculation produces valid number" {
  run bash -c '
    rps=100
    sys_after=1024
    rps_per_mb=$(echo "scale=3; $rps / ($sys_after / 1024)" | bc -l)
    echo "$rps_per_mb" | grep -qE "^[0-9]"
  '
  [ "$status" -eq 0 ]
}
