# shellcheck shell=bash

init_run() {
  RUN_ID="$(date +%Y%m%d_%H%M%S)"
  OUT_DIR="$REPORT_ROOT/run_$RUN_ID"
  RAW_DIR="$OUT_DIR/raw"
  mkdir -p "$RAW_DIR"
}

run_scenario() {
  local name="$1"
  local url="$2"

  local csv="$RAW_DIR/$name.csv"
  : > "$csv"

  local failures=0

  for ((i=1;i<=ITERATIONS;i++)); do
    tmp="$RAW_DIR/${name}_$i.csv"
    if ! "$AB_BIN" -n 1 -c 1 -e "$tmp" "$url" >/dev/null 2>&1; then
      ((failures++))
      continue
    fi
    awk -F',' 'NR>1 {print $5}' "$tmp" >> "$csv"
    sleep "$THINK_TIME"
  done

  echo "$failures" > "$RAW_DIR/${name}.failures"
}
