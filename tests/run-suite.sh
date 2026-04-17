#!/usr/bin/env bash
# run-suite.sh — Orchestrate test suite execution.
#
# Usage:
#   ./tests/run-suite.sh tests/suites/00-smoke.md   # run one suite
#   ./tests/run-suite.sh all                         # run all suites in order
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITES_DIR="$SCRIPT_DIR/suites"
RESET_SCRIPT="$SCRIPT_DIR/reset-state.sh"
RESULTS_DIR="$SCRIPT_DIR/results/$(date +%Y%m%dT%H%M%S)"

usage() {
  echo "Usage: $0 <suite-file|all>"
  echo "  suite-file  Path to a .md suite file (e.g., tests/suites/00-smoke.md)"
  echo "  all         Run every suite in tests/suites/ in sorted order"
  exit 1
}

[ $# -ge 1 ] || usage

mkdir -p "$RESULTS_DIR"
echo "Results directory: $RESULTS_DIR"

# Build list of suites to run
SUITES=()
if [ "$1" = "all" ]; then
  for f in "$SUITES_DIR"/*.md; do
    [ -f "$f" ] || { echo "No suite files found in $SUITES_DIR" >&2; exit 1; }
    SUITES+=("$f")
  done
else
  [ -f "$1" ] || { echo "ERROR: Suite file not found: $1" >&2; exit 1; }
  SUITES+=("$1")
fi

TOTAL=${#SUITES[@]}
PASSED=0
FAILED=0

for suite in "${SUITES[@]}"; do
  name="$(basename "$suite" .md)"
  echo ""
  echo "========================================"
  echo "Suite: $name"
  echo "========================================"

  # Reset state before each suite
  echo "--- Resetting state ---"
  if ! "$RESET_SCRIPT"; then
    echo "WARN: State reset failed for $name" >&2
  fi

  start=$(date +%s)

  # The LLM agent runs the suite externally via Playwright MCP.
  # To run manually: pipe the suite to your agent with MCP configured at localhost:3002/sse
  # The agent should produce a JSON results file at $RESULTS_DIR/${name}.json
  cp "$suite" "$RESULTS_DIR/${name}.md"
  echo "Suite ready at: $RESULTS_DIR/${name}.md"
  echo "Agent should write results to: $RESULTS_DIR/${name}.json"

  end=$(date +%s)
  elapsed=$((end - start))

  # Check for a results JSON (may be produced asynchronously by the agent)
  result_file="$RESULTS_DIR/${name}.json"
  if [ -f "$result_file" ]; then
    if grep -q '"failed"' "$result_file"; then
      echo "Status: FAILED (${elapsed}s)"
      FAILED=$((FAILED + 1))
    else
      echo "Status: PASSED (${elapsed}s)"
      PASSED=$((PASSED + 1))
    fi
  else
    echo "Status: PENDING (${elapsed}s) — no results file yet"
  fi
done

echo ""
echo "========================================"
echo "Summary: $TOTAL suite(s) | $PASSED passed | $FAILED failed | $((TOTAL - PASSED - FAILED)) pending"
echo "Results: $RESULTS_DIR"
echo "========================================"

[ "$FAILED" -eq 0 ] || exit 1
