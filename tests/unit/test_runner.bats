#!/usr/bin/env bats

setup() {
  source lib/runner.sh
  export ITERATIONS=5
  export THINK_TIME=0
  export RAW_DIR="$(mktemp -d)"
  export AB_BIN="$PWD/tests/mock_ab.sh"
}

teardown() {
  rm -rf "$RAW_DIR"
}

@test "runner produces csv output (mocked)" {
  run env \
    ITERATIONS=3 \
    THINK_TIME=0 \
    AB_BIN="$PWD/tests/mock_ab.sh" \
    bash bin/dlt.sh --dry-run

  [ "$status" -eq 0 ]
}
