#!/usr/bin/env bats

@test "P95 percentile follows discrete index definition" {
  run bash -c '
    BASE_DIR=$(pwd) source lib/stats.sh
    printf "1\n2\n3\n4\n5\n" | percentile 95
  '
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]
}
