#!/usr/bin/env bash
# How run_tests.sh decides what one suite's run means. Sourced by run_tests.sh and
# driven directly by scripts/ci/test_suite_classification.py.
#
# It lives in its own file because the rule it encodes had never been tested, and
# the reason this row exists is that an untested classifier reported "PASS: all
# suites green" for suites that had not run. Splitting it out is what lets the
# three outcomes be asserted against crafted output instead of against a real
# Godot run that can only ever produce the happy one.
#
# classify_suite_output <exit_code> <timeout_seconds> <output>
# prints "<state>\t<summary>", state being pass | skip | fail.

classify_suite_output() {
	local exit_code="$1"
	local timeout_seconds="$2"
	local out="$3"
	local summary skip
	summary="$(printf '%s' "$out" | grep "Results" | head -1)"
	skip="$(printf '%s' "$out" | grep "^SKIP: " | head -1)"

	# 124 = timed out (killed by `timeout`): a hung or never-quitting suite.
	if [[ "$exit_code" -eq 124 ]]; then
		printf 'fail\tTIMED OUT after %ss (no quit() reached — likely errored before finishing)\n' \
			"$timeout_seconds"
		return
	fi

	# A suite that exits 0 while reporting NOTHING is the run's blind spot, and it
	# was load-bearing: the shared-effect adopter proofs printed a skip line and
	# quit(0) on every gated run, were recorded as "'(no summary)'", and the run
	# called itself green while the milestone proof had not executed. A GDScript
	# error inside _init() produces the same shape -- it aborts before quit(1), so
	# the process still exits 0. Two legitimate outcomes, and no third:
	#   a Results line  -> the suite ran and counted itself
	#   a SKIP: line    -> the suite could not run here and said so
	# anything else is a failure.
	if [[ "$exit_code" -eq 0 && -z "$summary" ]]; then
		if [[ -n "$skip" ]]; then
			printf 'skip\t%s\n' "$skip"
			return
		fi
		printf 'fail\tFAIL — exited 0 with no Results summary and no SKIP: line.\n'
		return
	fi

	if [[ "$exit_code" -ne 0 ]]; then
		printf 'fail\t%s\n' "${summary:-'(no summary)'}"
		return
	fi
	printf 'pass\t%s\n' "$summary"
}


# What a red suite says about ITSELF, for the log line that names it.
#
# classify_suite_output returns one summary line, so a suite that counted itself
# red printed "Results: 11 passed, 1 failed" and nothing else: the run said how
# many checks failed and never which. On 2026-09-05 diagnosing one load-dependent
# failure in test_phase_banner meant reproducing it by hand, 48 times over, against
# an instrumented copy of the suite -- every bit of which the failing run had
# already printed and thrown away.
#
# Suites name a failed check on a line starting FAIL (the `_check` helper in every
# scripts/tests/*.gd), and an engine-level abort announces itself on a SCRIPT ERROR
# or USER ERROR line. Those lines, not the whole log: a red suite's output is mostly
# its passing checks, and the point is to keep the parallel run readable. Bare
# `ERROR:` is deliberately excluded -- the engine emits those in runs that pass, and
# a flood of them would push the FAIL line past the cap.
#
# suite_failure_detail <output> [max_lines]
suite_failure_detail() {
	local out="$1"
	local max="${2:-20}"
	local matched count
	matched="$(printf '%s\n' "$out" | grep -E '^(FAIL|SCRIPT ERROR|USER ERROR)' || true)"
	if [[ -z "$matched" ]]; then
		return
	fi
	count="$(printf '%s\n' "$matched" | wc -l | tr -d ' ')"
	printf '%s\n' "$matched" | head -n "$max"
	if (( count > max )); then
		printf '... and %d more\n' "$(( count - max ))"
	fi
}
