#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(dirname "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_ROOT
  export BASE_DIR="$PROJECT_ROOT"
  source "${PROJECT_ROOT}/lib/gregg_profiling.sh"
  TEST_TMP="/tmp/gregg_test_$$"
  mkdir -p "$TEST_TMP"
}

teardown() {
  rm -rf "$TEST_TMP" 2>/dev/null || true
}

@test "Gregg system metrics captures required fields" {
  capture_gregg_system_metrics "$TEST_TMP/metrics.csv"
  
  [ -f "$TEST_TMP/metrics.csv" ]
  
  # Check for expected number of fields (allowing for system variations in CI)
  local fields
  fields=$(head -1 "$TEST_TMP/metrics.csv" | tr ',' '\n' | wc -l)
  
  # Allow 15-25 fields to account for system variations and fallback values in CI
  [ "$fields" -ge 15 ] && [ "$fields" -le 25 ]
}

@test "Gregg system metrics produces valid timestamp" {
  capture_gregg_system_metrics "$TEST_TMP/metrics.csv"
  
  local timestamp
  timestamp=$(head -1 "$TEST_TMP/metrics.csv" | cut -d',' -f1)
  
  # Should be a reasonable Unix timestamp (within last 10 seconds)
  local current_time
  current_time=$(date +%s)
  [ "$timestamp" -ge $((current_time - 10)) ]
  [ "$timestamp" -le $current_time ]
}

@test "Gregg tools availability check passes when tools exist" {
  run check_gregg_tools
  [ "$status" -eq 0 ]
}

@test "Gregg metrics include load average" {
  capture_gregg_system_metrics "$TEST_TMP/metrics.csv"
  
  local load_avg
  load_avg=$(head -1 "$TEST_TMP/metrics.csv" | cut -d',' -f3)
  
  # Should be numeric (load average values)
  [[ "$load_avg" =~ ^[0-9.,[:space:]]+$ ]]
  [ -n "$load_avg" ]
}

@test "Gregg metrics include TCP statistics" {
  capture_gregg_system_metrics "$TEST_TMP/metrics.csv"
  
  local tcp_stats
  tcp_stats=$(head -1 "$TEST_TMP/metrics.csv" | cut -d',' -f19)
  
  # Should be numeric or empty if system has no TCP traffic
  [[ "$tcp_stats" =~ ^[0-9]*$ ]]
}