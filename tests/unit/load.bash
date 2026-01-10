#!/usr/bin/env bash
BATS_FILE_PATH=$(dirname "${BATS_TEST_FILENAME}")
export PROJECT_ROOT=$(cd "${BATS_FILE_PATH}/../.." && pwd)
export BASE_DIR="${PROJECT_ROOT}"

# Source all library files so they are available to the test environment
source "${PROJECT_ROOT}/lib/runner.sh"
source "${PROJECT_ROOT}/lib/parser.sh"
source "${PROJECT_ROOT}/lib/stats.sh"
source "${PROJECT_ROOT}/lib/workload.sh"
source "${PROJECT_ROOT}/lib/normality.sh"
source "${PROJECT_ROOT}/lib/report.sh"