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
  # Mock ab
  cat > tests/mock_ab.sh <<'EOF'
#!/bin/bash
echo "Requests per second:    123.45 [#/sec] (mean)"
echo "Time per request:       405.021 [ms] (mean)"
echo "Failed requests:        0"
echo "Transfer rate:          123.45 [Kbytes/sec] received"
echo "Connect:                1 2 3 4"
echo "Processing:             1 2 3 4"
echo "Total:                  1 2 3 4"
echo "Percentage of the requests served within a certain time (ms)"
echo " 50%      1"
echo " 90%      2"
echo " 95%      3"
echo " 99%      4"
EOF
  chmod +x tests/mock_ab.sh

  # Create a temp config file that uses the mock
  cp config/dlt.conf /tmp/test_dlt.conf
  echo 'AB_BIN="'"$PWD"'/tests/mock_ab.sh"' >> /tmp/test_dlt.conf

  # Modify dlt.sh to use the temp config
  local dlt_content
  dlt_content=$(cat bin/dlt.sh)
  dlt_content=${dlt_content/source \"\$BASE_DIR\/config\/dlt.conf\"/source \/tmp\/test_dlt.conf}

  run bash -c "BASE_DIR=$(pwd) $dlt_content" -- --dry-run
  [ "$status" -eq 0 ]

  # Cleanup
  rm /tmp/test_dlt.conf
  rm tests/mock_ab.sh
}
