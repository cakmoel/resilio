#!/usr/bin/env bats

@test "warm-up samples are discarded" {
  run bash -c '
    source config/dlt.conf
    source lib/parser.sh
    printf "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n" > /tmp/samples.txt
    ITERATIONS=10
    WARMUP_RATIO=0.2
    extract_samples /tmp/samples.txt
  '
  [ "$status" -eq 0 ]
  [ "$output" = $'3\n4\n5\n6\n7\n8\n9\n10' ]
}
