#!/usr/bin/env bats

@test "FULL load test (manual execution)" {
  skip "System test — run manually, long execution"

  run bash bin/dlt.sh
  [ "$status" -eq 0 ]
}
