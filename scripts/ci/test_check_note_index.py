#!/usr/bin/env python3
"""Regression tests for the session-note index guard.

Every case is asserted in BOTH directions. A guard verified only in the green
direction is how the pack freshness check briefly reported SKIPPED against a
workspace that had both packs cloned -- and how this checker's own first draft
printed a clean exit while calling the audit with arguments it rejected.

The fixture copies the REAL container audit rather than stubbing it, so a
regression in its ordering key fails here too. That is deliberate: the whole
reason this checker reaches across repos is to keep one implementation of the
ordering rule, and a stub would quietly restore the second one.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECKER = Path(__file__).with_name("check_note_index.py")
# scripts/ci -> scripts -> Project_Prometheus -> repo -> <container>
REAL_AUDIT = Path(__file__).resolve().parents[4] / "tools" / "history_audit.py"
# In CI this repo is checked out alone, so the audit these tests exercise is not
# there. Skipping is correct and matches what the checker itself does; erroring
# would make the required non-Godot gate red on every CI run.
NEEDS_AUDIT = unittest.skipUnless(
    REAL_AUDIT.is_file(), f"container audit not present at {REAL_AUDIT}"
)


class Fixture:
    """A throwaway <container>/repo/<project> layout with its own notes corpus."""

    def __init__(self, with_audit: bool = True) -> None:
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        self.notes = root / "repo" / "P" / "AGENT" / "Session Notes"
        self.notes.mkdir(parents=True)
        ci = root / "repo" / "P" / "scripts" / "ci"
        ci.mkdir(parents=True)
        self.checker = ci / CHECKER.name
        shutil.copy(CHECKER, self.checker)
        self.audit = root / "tools" / "history_audit.py"
        if with_audit:
            self.audit.parent.mkdir(parents=True)
            shutil.copy(REAL_AUDIT, self.audit)

    def close(self) -> None:
        self.temp.cleanup()

    def write(self, names: list[str], index: list[str] | None = None) -> None:
        for name in names:
            (self.notes / name).write_text(name, encoding="utf-8")
        rows = names if index is None else index
        (self.notes / "INDEX.md").write_text(
            "".join(f"- [{row}]({row})\n" for row in rows), encoding="utf-8"
        )

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(self.checker)],
            capture_output=True, text=True, check=False,
        )


NEWEST_FIRST = [
    "2026-08-09-07-11-37Z-baseline.md",
    "2026-08-09-06-21-32Z-dialogue.md",
    "2026-07-15aa.md",
    "2026-07-15z.md",
    "2026-07-15b.md",
]


@NEEDS_AUDIT
class CheckNoteIndexTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = Fixture()
        self.addCleanup(self.fixture.close)

    def test_passes_on_a_consistent_index(self) -> None:
        self.fixture.write(NEWEST_FIRST)
        result = self.fixture.run()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("PASS", result.stdout)
        self.assertIn("5 note(s)", result.stdout)

    def test_fails_and_names_the_note_missing_from_the_index(self) -> None:
        self.fixture.write(NEWEST_FIRST, index=NEWEST_FIRST[1:])
        result = self.fixture.run()
        self.assertEqual(1, result.returncode)
        self.assertIn("orphan note", result.stderr)
        self.assertIn(NEWEST_FIRST[0], result.stderr)

    def test_fails_on_a_dead_link(self) -> None:
        self.fixture.write(NEWEST_FIRST, index=NEWEST_FIRST + ["2026-01-01-gone.md"])
        result = self.fixture.run()
        self.assertEqual(1, result.returncode)
        self.assertIn("dead link", result.stderr)
        self.assertIn("2026-01-01-gone.md", result.stderr)

    def test_fails_on_a_duplicate_row(self) -> None:
        self.fixture.write(NEWEST_FIRST, index=NEWEST_FIRST + [NEWEST_FIRST[0]])
        result = self.fixture.run()
        self.assertEqual(1, result.returncode)
        self.assertIn("duplicate index row", result.stderr)

    def test_fails_on_a_displaced_row_and_names_the_first_one(self) -> None:
        swapped = [NEWEST_FIRST[1], NEWEST_FIRST[0]] + NEWEST_FIRST[2:]
        self.fixture.write(NEWEST_FIRST, index=swapped)
        result = self.fixture.run()
        self.assertEqual(1, result.returncode)
        self.assertIn("out of order at index row 1", result.stderr)
        self.assertIn(f"expected there: {NEWEST_FIRST[0]}", result.stderr)

    def test_says_the_error_count_cascades(self) -> None:
        # One row moved to the end misorders every position after it. The message
        # must not invite reading that number as a count of misplaced rows.
        moved = NEWEST_FIRST[1:] + [NEWEST_FIRST[0]]
        self.fixture.write(NEWEST_FIRST, index=moved)
        result = self.fixture.run()
        self.assertEqual(1, result.returncode)
        self.assertIn("CASCADES", result.stderr)

    def test_two_letter_suffix_outranks_a_single_letter_one(self) -> None:
        # Pins the ordering key this checker depends on: aa follows z, not b.
        self.fixture.write(["2026-07-15b.md", "2026-07-15z.md", "2026-07-15aa.md"],
                           index=["2026-07-15aa.md", "2026-07-15z.md", "2026-07-15b.md"])
        self.assertEqual(0, self.fixture.run().returncode)

    def test_descriptive_slug_is_not_ranked_as_a_suffix(self) -> None:
        # "-v050-publication" must not parse as suffix "v" and outrank "c".
        names = ["2026-07-17c.md", "2026-07-17-v050-publication.md", "2026-07-17.md"]
        self.fixture.write(names, index=names)
        self.assertEqual(0, self.fixture.run().returncode)


class MissingAuditTests(unittest.TestCase):
    def test_skips_loudly_when_the_container_audit_is_absent(self) -> None:
        fixture = Fixture(with_audit=False)
        self.addCleanup(fixture.close)
        fixture.write(NEWEST_FIRST)
        result = fixture.run()
        self.assertEqual(0, result.returncode)
        self.assertIn("SKIPPED", result.stderr)
        self.assertIn("NOT verified", result.stderr)

    def test_fails_when_the_audit_is_present_but_errors(self) -> None:
        fixture = Fixture(with_audit=False)
        self.addCleanup(fixture.close)
        fixture.write(NEWEST_FIRST)
        fixture.audit.parent.mkdir(parents=True, exist_ok=True)
        fixture.audit.write_text(
            "import sys\nsys.stderr.write('boom\\n')\nsys.exit(2)\n", encoding="utf-8"
        )
        result = fixture.run()
        self.assertEqual(1, result.returncode, "a present-but-broken audit must not skip")
        self.assertIn("present but errored", result.stderr)


if __name__ == "__main__":
    unittest.main()
