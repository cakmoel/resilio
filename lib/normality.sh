# shellcheck shell=bash

choose_test() {
  local n="$1"
  local skew="$2"
  local kurt="$3"

  # Small sample → non-parametric
  if (( n < 30 )); then
    echo "mann-whitney"
    return
  fi

  # Severe non-normality → non-parametric
  if awk -v s="$skew" -v k="$kurt" 'BEGIN { exit !( (s > 1.5 || s < -1.5) || (k > 3.0) ) }'; then
    echo "mann-whitney"
    return
  fi

  # Default: Welch's t-test
  echo "welch"
}
