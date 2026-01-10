#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(dirname "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_ROOT
  export BASE_DIR="$PROJECT_ROOT" # Ensure BASE_DIR is set for lib/stats.sh
  source "${PROJECT_ROOT}/tests/unit/common.bash"
}

@test "P95 percentile follows discrete index definition" {
  run bash -c '
    source "${PROJECT_ROOT}/lib/stats.sh"
    printf "1\n2\n3\n4\n5\n" | percentile 95
  '
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]
}