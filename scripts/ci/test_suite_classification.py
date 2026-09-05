#!/usr/bin/env python3
"""Assert the three states run_tests.sh can put a suite in.

The rule these tests cover had none until 2026-08-31, and its absence was not
theoretical: a suite that exited 0 without saying anything was recorded as
"'(no summary)'" and counted towards "PASS: all suites green". Both
shared-effect adopter proofs did exactly that on every gated run, so the check
that was supposed to close a milestone could not fail. A real Godot run can
only produce the passing shape, which is why the classifier was split into
scripts/ci/suite_classification.sh and is driven here with crafted output.
"""

import subprocess
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CLASSIFIER = REPO_ROOT / "scripts" / "ci" / "suite_classification.sh"


def classify(output: str, exit_code: int = 0, timeout_seconds: int = 180) -> tuple[str, str]:
    result = subprocess.run(
        [
            "bash",
            "-c",
            f'source "{CLASSIFIER}"; classify_suite_output "$1" "$2" "$3"',
            "_",
            str(exit_code),
            str(timeout_seconds),
            output,
        ],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    state, _, summary = result.stdout.rstrip("\n").partition("\t")
    return state, summary


def failure_detail(output: str, max_lines: int | None = None) -> str:
    args = [str(max_lines)] if max_lines is not None else []
    result = subprocess.run(
        [
            "bash",
            "-c",
            f'source "{CLASSIFIER}"; suite_failure_detail "$@"',
            "_",
            output,
            *args,
        ],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return result.stdout


class SuiteClassificationTests(unittest.TestCase):
    def test_results_line_passes(self):
        state, summary = classify("OK  something\n=== Results: 4 passed, 0 failed ===")
        self.assertEqual(state, "pass")
        self.assertIn("4 passed", summary)

    def test_silent_zero_exit_fails(self):
        """The hole this row closed: exit 0, nothing said, previously a pass."""
        state, summary = classify("Godot Engine v4.6.3.stable.official\n")
        self.assertEqual(state, "fail")
        self.assertIn("no Results summary", summary)

    def test_empty_output_fails(self):
        state, _ = classify("")
        self.assertEqual(state, "fail")

    def test_skip_line_is_a_skip_not_a_pass(self):
        state, summary = classify("SKIP: session 7 pack proof -- pack repo is not checked out")
        self.assertEqual(state, "skip")
        self.assertIn("pack proof", summary)

    def test_skip_must_start_the_line(self):
        """A skip mentioned in passing is not a suite reporting itself skipped."""
        state, _ = classify("OK  the adapter did not SKIP: anything\n")
        self.assertEqual(state, "fail")

    def test_results_wins_over_a_skip_line(self):
        """A suite that skipped one case and still counted itself has run."""
        state, summary = classify("SKIP: one case\nResults: 3 passed, 0 failed")
        self.assertEqual(state, "pass")
        self.assertIn("3 passed", summary)

    def test_nonzero_exit_fails_even_with_a_results_line(self):
        state, summary = classify("Results: 0 passed, 2 failed", exit_code=1)
        self.assertEqual(state, "fail")
        self.assertIn("2 failed", summary)

    def test_nonzero_exit_without_a_summary_still_fails(self):
        state, summary = classify("SCRIPT ERROR: something exploded", exit_code=1)
        self.assertEqual(state, "fail")
        self.assertIn("no summary", summary)

    def test_timeout_fails_and_says_so(self):
        state, summary = classify("", exit_code=124, timeout_seconds=180)
        self.assertEqual(state, "fail")
        self.assertIn("TIMED OUT after 180s", summary)

    def test_a_skipping_suite_that_times_out_is_still_a_failure(self):
        state, _ = classify("SKIP: unreachable", exit_code=124)
        self.assertEqual(state, "fail")


class SuiteFailureDetailTests(unittest.TestCase):
    """A red suite has to NAME the failed check, not just count it.

    Before this, a suite that counted itself red printed only its Results line, so
    a parallel run said "11 passed, 1 failed" and nothing about which check. That
    cost a full hand-reproduction under an instrumented copy of test_phase_banner
    on 2026-09-05 to recover a line the failing run had already printed.
    """

    def test_the_failed_check_is_named(self):
        detail = failure_detail(
            "OK  the banner starts hidden\n"
            "FAIL resize at 0.1s cancels and hides\n"
            "Results: 11 passed, 1 failed"
        )
        self.assertEqual(detail, "FAIL resize at 0.1s cancels and hides\n")

    def test_passing_checks_are_not_echoed_back(self):
        detail = failure_detail("OK  one\nOK  two\nFAIL three")
        self.assertNotIn("OK", detail)

    def test_engine_aborts_are_reported(self):
        detail = failure_detail("SCRIPT ERROR: Invalid call\nUSER ERROR: bad state")
        self.assertIn("SCRIPT ERROR: Invalid call", detail)
        self.assertIn("USER ERROR: bad state", detail)

    def test_bare_engine_errors_are_left_out(self):
        """`ERROR:` appears in runs that PASS; including it would bury the FAIL line."""
        detail = failure_detail("ERROR: could not open a nonessential resource\nFAIL the check")
        self.assertNotIn("could not open", detail)
        self.assertIn("FAIL the check", detail)

    def test_a_mention_of_failure_mid_line_is_not_a_failed_check(self):
        detail = failure_detail("OK  reports FAIL when the roster is empty")
        self.assertEqual(detail, "")

    def test_nothing_to_report_prints_nothing(self):
        self.assertEqual(failure_detail("Results: 4 passed, 0 failed"), "")

    def test_a_flood_is_capped_and_says_how_many_it_dropped(self):
        detail = failure_detail("\n".join(f"FAIL check {i}" for i in range(25)), max_lines=3)
        self.assertEqual(
            detail, "FAIL check 0\nFAIL check 1\nFAIL check 2\n... and 22 more\n"
        )

    def test_exactly_the_cap_is_not_truncated(self):
        detail = failure_detail("\n".join(f"FAIL check {i}" for i in range(3)), max_lines=3)
        self.assertNotIn("more", detail)


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)
