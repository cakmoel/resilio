#!/usr/bin/env bats

@test "Welch chosen for n >= 30 with mild skew/kurtosis" {
  run bash -c '
    source lib/normality.sh
    choose_test 100 0.8 1.2
  '
  [ "$status" -eq 0 ]
  [ "$output" = "welch" ]
}

@test "Mann-Whitney chosen for small sample size" {
  run bash -c '
    source lib/normality.sh
    choose_test 10 0.1 0.1
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mann-whitney" ]
}

@test "Mann-Whitney chosen for extreme skew" {
  run bash -c '
    source lib/normality.sh
    choose_test 100 4.5 0.2
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mann-whitney" ]
}

@test "Mann-Whitney chosen for extreme kurtosis" {
  run bash -c '
    source lib/normality.sh
    choose_test 100 0.1 9.0
  '
  [ "$status" -eq 0 ]
  [ "$output" = "mann-whitney" ]
}
