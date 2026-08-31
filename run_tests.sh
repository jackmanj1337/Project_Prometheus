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
#
# Rerunning a subset: the failing suite names are kept in .test-failures (gitignored)
# after every red run, and `--rerun-failed` re-runs exactly those. Parallel runs can
# produce timeouts under process contention, and the honest way to tell contention
# from a real defect is to re-run the affected suites in isolation — which previously
# meant retyping suite names by hand and left no record of what was retried.
cd "$(dirname "$0")"

# Infrastructure and browser-shell tests used to require ad-hoc commands and could
# silently miss the normal fast/full gate. Their runner owns glob discovery.
#
# Its exit status is checked because for a while it was not, and this script does
# not run under `set -e`: on 2026-08-31 check_foundation_adopters failed, its
# unittest suite printed "FAILED (failures=1)", and this run still printed
# "PASS: all suites green" and exited 0. The required non-Godot suite could not
# fail a commit or a push. Found by reading a log, not by the gate.
if ! bash scripts/ci/run_required_non_godot_tests.sh; then
	echo ""
	echo "FAIL: required non-Godot tests failed; Godot suites were not run."
	exit 1
fi

JOBS="${TEST_JOBS:-8}"
FAILURES_FILE=".test-failures"
RERUN_FAILED="false"
SERIAL="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rerun-failed) RERUN_FAILED="true"; shift ;;
    --serial) SERIAL="true"; shift ;;
    -h|--help)
      echo "Usage: $0 [--rerun-failed] [--serial]"
      echo "  --rerun-failed  re-run only the suites listed in $FAILURES_FILE"
      echo "  --serial        one worker (equivalent to TEST_JOBS=1)"
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Isolation is the point of a rerun, so it defaults to serial unless TEST_JOBS was
# set explicitly for this invocation.
if [[ "$SERIAL" == "true" ]] || { [[ "$RERUN_FAILED" == "true" ]] && [[ -z "${TEST_JOBS:-}" ]]; }; then
  JOBS=1
fi

TESTS=()
if [[ "$RERUN_FAILED" == "true" ]]; then
  if [[ ! -s "$FAILURES_FILE" ]]; then
    echo "No recorded failures in $FAILURES_FILE — nothing to re-run."
    exit 0
  fi
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if [[ -f "scripts/tests/${name}.gd" ]]; then
      TESTS+=("$name")
    else
      echo "warning: $name is listed in $FAILURES_FILE but no longer exists; skipping" >&2
    fi
  done < "$FAILURES_FILE"
  echo "re-running ${#TESTS[@]} previously failing suite(s) with ${JOBS} worker(s)"
else
  while IFS= read -r f; do
    TESTS+=("$(basename "$f" .gd)")
  done < <(find scripts/tests -maxdepth 1 -name 'test_*.gd' -type f | sort)
fi
if [[ ${#TESTS[@]} -eq 0 ]]; then
  echo "FAIL: no test files found under scripts/tests/"
  exit 1
fi

# The schema-pressure fixtures are JSON plus a Python validator rather than a
# SceneTree suite. Keep their positive and negative contracts in the same required
# gate so expected_errors.json cannot decay into an unexecuted checklist.
SCHEMA_TRIAL_CHECK="test_fixtures/schema_trial/check_trial_fixtures.py"
if [[ -f "$SCHEMA_TRIAL_CHECK" ]]; then
  python3 "$SCHEMA_TRIAL_CHECK"
fi

# Scratch space for per-suite output, failure markers, and isolated homes.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/out"

# Warm the import / global class cache once so the parallel workers don't all
# try to (re)build .godot/ at the same time.
#
# --import must come first, and --quit alone is not enough. The .import sidecars
# are tracked but .godot/ is gitignored (bar the class cache), so a fresh
# checkout has no converted textures: every scene test then fails to load
# assets/themes/manasoul_ui.tres and its dependent .tscn. --import also rebuilds
# global_script_class_cache.cfg, so a newly added class_name resolves; --quit
# rebuilds neither. Without this a clean clone reports 7 phantom failures that
# look like broken code (diagnosed 2026-07-29).
echo "running test suite (${#TESTS[@]} suites, ${JOBS} workers)..."
IMPORT_LOG="$WORK/godot-import.log"
if ! godot --headless --path . --import --quit-after 1000 >"$IMPORT_LOG" 2>&1; then
  echo "FAIL: Godot project import failed; complete import log follows:"
  cat "$IMPORT_LOG"
  exit 1
fi
if [[ ! -f .godot/global_script_class_cache.cfg ]]; then
  echo "FAIL: Godot import did not generate .godot/global_script_class_cache.cfg"
  cat "$IMPORT_LOG"
  exit 1
fi

# Per-suite hard timeout. A SceneTree test only exits when its _init() reaches the
# explicit quit(); a test that errors out *before* that line leaves godot idling
# forever (headless --script has no idle auto-quit). Without this guard such a
# suite would hang the whole run — and pre-commit/CI — indefinitely, and ad-hoc
# runs orphan the godot process. timeout kills it (SIGTERM, then SIGKILL) and the
# resulting non-zero exit is recorded as a failure. Generous vs the ~8s real
# runtime; override with TEST_TIMEOUT for slow machines.
TIMEOUT="${TEST_TIMEOUT:-180}"
export TIMEOUT

# The pass/skip/fail rule lives in its own file so it can be tested against
# crafted suite output; see the header there.
source scripts/ci/suite_classification.sh

# Runs a single suite. Writes its summary line to out/<name> and records the suite
# name in the failures (or skips) file. Exported for xargs workers.
run_one() {
  local name="$1"
  local home="$WORK/home/$name"
  mkdir -p "$home/.local/share"
  local out exit_code
  out="$(HOME="$home" XDG_DATA_HOME="$home/.local/share" \
    timeout --kill-after=10 "$TIMEOUT" \
    godot --headless --path . --script "res://scripts/tests/$name.gd" 2>&1)"
  exit_code=$?
  local classified state summary
  classified="$(classify_suite_output "$exit_code" "$TIMEOUT" "$out")"
  state="${classified%%$'\t'*}"
  summary="${classified#*$'\t'}"
  case "$state" in
    skip)
      echo "$name: $summary" > "$WORK/out/$name"
      echo "$name" >> "$WORK/skips"
      ;;
    fail)
      {
        echo "$name: $summary"
        # The full log only for the outcome that has no summary of its own —
        # a suite that never reached its end leaves nothing else to read.
        if [[ "$summary" == FAIL\ —* ]]; then
          echo "  The suite did not reach its own end. Complete output:"
          echo "$out" | sed 's/^/    /'
        fi
      } > "$WORK/out/$name"
      echo "$name" >> "$WORK/failures"
      ;;
    *)
      echo "$name: $summary" > "$WORK/out/$name"
      ;;
  esac
}
export -f run_one classify_suite_output
export WORK

printf '%s\n' "${TESTS[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one "$1"' _ {}

# Print results in the deterministic sorted suite order.
for name in "${TESTS[@]}"; do
  [[ -f "$WORK/out/$name" ]] && cat "$WORK/out/$name"
done

echo ""
# Skips are printed as their own block, not left to scroll past in a long log. A
# skipped suite is absent coverage, and the whole point of the state is that it
# cannot be mistaken for a pass.
if [[ -f "$WORK/skips" ]]; then
  skip_count="$(wc -l < "$WORK/skips" | tr -d ' ')"
  echo "SKIPPED: $skip_count suite(s) could not run in this environment:"
  sed 's/^/  /' "$WORK/skips"
  echo "  Their coverage is NOT verified by this run."
  echo ""
fi
if [[ -f "$WORK/failures" ]]; then
  fail_count="$(wc -l < "$WORK/failures" | tr -d ' ')"
  # Persist outside the scratch dir so --rerun-failed has something to read; the
  # list previously died with the mktemp directory on exit.
  sort "$WORK/failures" > "$FAILURES_FILE"
  echo "FAIL: $fail_count suite(s) failed:"
  sed 's/^/  /' "$FAILURES_FILE"
  echo ""
  echo "Re-run just these in isolation:  bash run_tests.sh --rerun-failed"
  exit 1
fi
# A green run clears the record, so a stale list can never make a passing tree look
# like it still has something to retry.
rm -f "$FAILURES_FILE"
if [[ -f "$WORK/skips" ]]; then
  # Not "all suites green": some did not run. Saying so in the line people read
  # first is the difference between a gate and a habit.
  echo "PASS: all executed suites green ($skip_count skipped, listed above)"
else
  echo "PASS: all suites green"
fi
