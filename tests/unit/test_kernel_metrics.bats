#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(dirname "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_ROOT
  export BASE_DIR="$PROJECT_ROOT"
  source "${PROJECT_ROOT}/lib/kernel_metrics.sh"
  TEST_TMP="/tmp/kernel_test_$$"
  mkdir -p "$TEST_TMP"
}

teardown() {
  rm -rf "$TEST_TMP" 2>/dev/null || true
}

@test "Kernel metrics captures required system fields" {
  capture_kernel_metrics "$TEST_TMP/kernel.csv"
  
  [ -f "$TEST_TMP/kernel.csv" ]
  
  # Check for expected number of fields (actual: 21 fields from implementation)
  local fields
  fields=$(head -1 "$TEST_TMP/kernel.csv" | tr ',' '\n' | wc -l)
  [ "$fields" -eq 21 ]
}

@test "Kernel metrics includes context switches" {
  capture_kernel_metrics "$TEST_TMP/kernel.csv"
  
  local ctxt
  ctxt=$(head -1 "$TEST_TMP/kernel.csv" | cut -d',' -f5)
  
  # Should be a numeric value (context switches since boot)
  [[ "$ctxt" =~ ^[0-9]+$ ]]
  [ "$ctxt" -gt 0 ]
}

@test "Kernel metrics includes memory vmstat data" {
  capture_kernel_metrics "$TEST_TMP/kernel.csv"
  
  local free_pages
  free_pages=$(head -1 "$TEST_TMP/kernel.csv" | cut -d',' -f8)
  
  # Should be a numeric value
  [[ "$free_pages" =~ ^[0-9]+$ ]]
}

@test "Process metrics capture works with valid PID" {
  # Use init process (always exists)
  local init_pid=1
  
  capture_process_metrics "$TEST_TMP/process.csv" "$init_pid"
  
  [ -f "$TEST_TMP/process.csv" ]
  
  # Should capture process-specific data
  local fields
  fields=$(head -1 "$TEST_TMP/process.csv" | tr ',' '\n' | wc -l)
  [ "$fields" -eq 19 ]
}

@test "Process metrics handles invalid PID gracefully" {
  run capture_process_metrics "$TEST_TMP/process.csv" "999999"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid PID"* ]]
}

@test "Network stack metrics captures TCP data" {
  capture_network_stack_metrics "$TEST_TMP/network.csv"
  
  [ -f "$TEST_TMP/network.csv" ]
  
  local fields
  fields=$(head -1 "$TEST_TMP/network.csv" | tr ',' '\n' | wc -l)
  [ "$fields" -eq 16 ]
}

@test "Block I/O metrics captures disk activity" {
  capture_block_io_metrics "$TEST_TMP/blockio.csv"
  
  [ -f "$TEST_TMP/blockio.csv" ]
  
  local fields
  fields=$(head -1 "$TEST_TMP/blockio.csv" | tr ',' '\n' | wc -l)
  [ "$fields" -eq 9 ]
}