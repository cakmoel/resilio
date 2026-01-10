#!/usr/bin/env bash

# Helper function to source all library scripts
source_lib_scripts() {
  source "${PROJECT_ROOT}/lib/runner.sh"
  source "${PROJECT_ROOT}/lib/parser.sh"
  source "${PROJECT_ROOT}/lib/stats.sh"
  source "${PROJECT_ROOT}/lib/workload.sh"
  source "${PROJECT_ROOT}/lib/normality.sh"
  source "${PROJECT_ROOT}/lib/report.sh"
}

export -f source_lib_scripts