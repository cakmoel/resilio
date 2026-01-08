#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) ;;
  esac
done

source "$BASE_DIR/config/dlt.conf"
source "$BASE_DIR/lib/workload.sh"
source "$BASE_DIR/lib/runner.sh"
source "$BASE_DIR/lib/parser.sh"
source "$BASE_DIR/lib/stats.sh"
source "$BASE_DIR/lib/normality.sh"
source "$BASE_DIR/lib/report.sh"

init_run
init_report

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DLT dry-run completed successfully."
  exit 0
fi

run_all_scenarios
finalize_report
