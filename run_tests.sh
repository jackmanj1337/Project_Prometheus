#!/usr/bin/env bash
# Run all GDScript tests in parallel; exit 1 if any fail.
#
# Test discovery is glob-based (code review 2026-06-10 issue 2.2): every
# scripts/tests/test_*.gd is picked up automatically and run in sorted order.
#
# Why parallel: ~95% of a small suite's wall time is just the Godot headless
# boot (~7s), and we boot once per suite. Running suites concurrently across
# cores cuts a ~4.5min sequential run to well under a minute, which keeps the
# pre-commit hook fast enough to finish inside a single shell invocation.
# Override the worker count with TEST_JOBS (default 8). Set SKIP_TESTS=1 in the
# hook to bypass entirely.
#
# Isolation: each worker gets its own HOME/XDG_DATA_HOME so parallel instances
# never race the shared user:// app-data dir (only test_settings_manager writes
# it, but isolation keeps every suite hermetic and removes any cross-suite
# ordering dependency on user:// state). The project's import/class cache
# (.godot/) is warmed once up front so workers read a ready cache instead of
# writing it concurrently.
#
# Output is buffered per suite and printed in sorted order, so the log reads
# identically to the old sequential runner despite running out of order.
cd "$(dirname "$0")"

JOBS="${TEST_JOBS:-8}"

TESTS=()
while IFS= read -r f; do
  TESTS+=("$(basename "$f" .gd)")
done < <(find scripts/tests -maxdepth 1 -name 'test_*.gd' -type f | sort)
if [[ ${#TESTS[@]} -eq 0 ]]; then
  echo "FAIL: no test files found under scripts/tests/"
  exit 1
fi

# Scratch space for per-suite output, failure markers, and isolated homes.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/out"

# Warm the import / global class cache once so the parallel workers don't all
# try to (re)build .godot/ at the same time.
echo "running test suite (${#TESTS[@]} suites, ${JOBS} workers)..."
godot --headless --path . --quit >/dev/null 2>&1 || true

# Runs a single suite. Writes its summary line to out/<name> and, on a non-zero
# exit, records the suite name in the failures file. Exported for xargs workers.
run_one() {
  local name="$1"
  local home="$WORK/home/$name"
  mkdir -p "$home/.local/share"
  local out exit_code summary
  out="$(HOME="$home" XDG_DATA_HOME="$home/.local/share" \
    godot --headless --path . --script "res://scripts/tests/$name.gd" 2>&1)"
  exit_code=$?
  summary="$(echo "$out" | grep "Results")"
  echo "$name: ${summary:-'(no summary)'}" > "$WORK/out/$name"
  if [[ $exit_code -ne 0 ]]; then
    echo "$name" >> "$WORK/failures"
  fi
}
export -f run_one
export WORK

printf '%s\n' "${TESTS[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one "$1"' _ {}

# Print results in the deterministic sorted suite order.
for name in "${TESTS[@]}"; do
  [[ -f "$WORK/out/$name" ]] && cat "$WORK/out/$name"
done

echo ""
if [[ -f "$WORK/failures" ]]; then
  fail_count="$(wc -l < "$WORK/failures" | tr -d ' ')"
  echo "FAIL: $fail_count suite(s) failed:"
  sort "$WORK/failures" | sed 's/^/  /'
  exit 1
fi
echo "PASS: all suites green"
