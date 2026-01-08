#!/usr/bin/env bats

setup() {
  export CONF_Z=1.96
}

@test "mean calculation is correct" {
  run bash -c '
    source lib/stats.sh
    printf "1\n2\n3\n4\n5\n" | mean
  '
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "stddev is non-zero for varied data" {
  run bash -c '
    source lib/stats.sh
    printf "1\n2\n3\n4\n5\n" | stddev
  '
  [ "$status" -eq 0 ]
  [[ "$output" != "0" ]]
}

@test "percentile 95 returns expected value" {
  run bash -c '
    source lib/stats.sh
    printf "1\n2\n3\n4\n5\n" | percentile 95
  '
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]
}

@test "confidence interval produces two numbers" {
  run bash -c '
    source lib/stats.sh
    printf "1\n2\n3\n4\n5\n" | ci_bounds
  '
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^-?[0-9.]+\ -?[0-9.]+$ ]]
}
