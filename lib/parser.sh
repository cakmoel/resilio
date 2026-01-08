# shellcheck shell=bash

extract_samples() {
  local input="$1"
  local warmup

  warmup=$(awk -v n="$ITERATIONS" -v r="$WARMUP_RATIO" 'BEGIN { print int(n * r) }')

  awk -v w="$warmup" 'NR > w { print }' "$input"
}
