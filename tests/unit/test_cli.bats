#!/usr/bin/env bats

@test "CLI dry-run exits cleanly" {
  run bash -c "BASE_DIR=$(pwd) bash bin/dlt.sh --dry-run"
  [ "$status" -eq 0 ]
}
