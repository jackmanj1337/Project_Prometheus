#!/usr/bin/env bash
# Run all GDScript tests; exit 1 if any fail.
#
# Test discovery is glob-based (code review 2026-06-10 issue 2.2): every
# scripts/tests/test_*.gd is picked up automatically and run in sorted order.
# Prior to this, the list was hand-maintained and five test files (~40 assertions)
# had drifted off the array.
#
# A new test file lands in CI as soon as it's added to scripts/tests/. If you
# need a specific order (e.g. one test must run before another due to user://
# state), prefix its filename — sorted ASCII order is stable.
cd "$(dirname "$0")"
TESTS=()
while IFS= read -r f; do
  TESTS+=("$(basename "$f" .gd)")
done < <(find scripts/tests -maxdepth 1 -name 'test_*.gd' -type f | sort)
if [[ ${#TESTS[@]} -eq 0 ]]; then
  echo "FAIL: no test files found under scripts/tests/"
  exit 1
fi
fail_count=0
for t in "${TESTS[@]}"; do
  out=$(godot --headless --path . --script "res://scripts/tests/$t.gd" 2>&1)
  exit_code=$?
  summary=$(echo "$out" | grep "Results")
  echo "$t: ${summary:-'(no summary)'}"
  if [[ $exit_code -ne 0 ]]; then
    fail_count=$((fail_count + 1))
  fi
done
echo ""
if [[ $fail_count -gt 0 ]]; then
  echo "FAIL: $fail_count suite(s) failed"
  exit 1
fi
echo "PASS: all suites green"
