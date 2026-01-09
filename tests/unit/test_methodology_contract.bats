#!/usr/bin/env bats

@test "P95 percentile follows discrete index definition" {
  run bash -c '
    BASE_DIR=$(pwd)
    source lib/stats.sh
    printf "1\n2\n3\n4\n5\n" | percentile 95
  '
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]
}

@test "Welch is preferred for n >= 30 with mild skew/kurtosis" {
  run bash -c '
    source lib/normality.sh
    choose_test 30 0.9 1.8
  '
  [ "$status" -eq 0 ]
  [ "$output" = "welch" ]
}

@test "Mann-Whitney used for small sample size" {
  run bash -c '
    source lib/normality.sh
    choose_test 20 0.2 0.5
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mann-whitney" ]
}
