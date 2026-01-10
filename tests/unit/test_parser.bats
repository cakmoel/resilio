#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(dirname "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_ROOT
  export BASE_DIR="$PROJECT_ROOT" # Ensure BASE_DIR is set for lib/parser.sh (indirectly via dlt.conf)
  source "${PROJECT_ROOT}/tests/unit/common.bash"
}

@test "warm-up samples are discarded" {
  run bash -c '
    source "${PROJECT_ROOT}/config/dlt.conf"
    source "${PROJECT_ROOT}/lib/parser.sh"
    printf "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n" > /tmp/samples.txt
    ITERATIONS=10
    WARMUP_RATIO=0.2
    extract_samples /tmp/samples.txt
  '
  [ "$status" -eq 0 ]
  [ "$output" = $'3\n4\n5\n6\n7\n8\n9\n10' ]
}
