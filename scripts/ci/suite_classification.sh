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
