#!/usr/bin/env python3
"""Regression tests for the commit ownership ledger.

The behaviours pinned here are the ones the two previous claim models got wrong:
a claim must be readable without a fetched remote ref, the same claim seen in both
sources must not count as a double-claim, and a claim written only in note prose
must be reported rather than silently ignored.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).with_name("check_session_commit_claims.py")
LEDGER = "AGENT/Session Notes/CLAIMS.tsv"


class LedgerFixture:
	"""A throwaway repo with one substantive feature commit awaiting a claim."""

	def __init__(self) -> None:
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		self.git("init", "-q", "-b", "agent/integration")
		self.git("config", "user.name", "Fixture")
		self.git("config", "user.email", "fixture@example.invalid")
		(self.root / "scripts/ci").mkdir(parents=True)
		(self.root / "AGENT/Session Notes").mkdir(parents=True)
		shutil.copy2(SOURCE, self.root / "scripts/ci/check_session_commit_claims.py")
		(self.root / "seed.txt").write_text("seed\n", encoding="utf-8")
		self.commit("Seed")
		self.base = self.git("rev-parse", "HEAD")
		self.write_base(self.base)
		self.git("add", ".")
		self.git("commit", "-qm", "Add claim tooling")
		self.tooling = self.git("rev-parse", "HEAD")
		self.write_base(self.tooling)
		self.git("switch", "-qc", "agent/feature")
		(self.root / "feature.txt").write_text("feature\n", encoding="utf-8")
		self.commit("Feature work")
		self.feature = self.git("rev-parse", "HEAD")

	def close(self) -> None:
		self.temp.cleanup()

	def git(self, *args: str) -> str:
		return subprocess.check_output(["git", *args], cwd=self.root, text=True).strip()

	def write_base(self, sha: str) -> None:
		(self.root / "AGENT/Session Notes/COMMIT_CLAIMS_BASE").write_text(
			sha + "\n", encoding="utf-8"
		)

	def commit(self, subject: str) -> None:
		self.git("add", ".")
		self.git("commit", "-qm", subject)

	def write_ledger(self, *entries: tuple[str, str]) -> None:
		body = "# ledger\n" + "".join(f"{sha}\t{subject}\n" for sha, subject in entries)
		(self.root / LEDGER).write_text(body, encoding="utf-8")

	def write_note(self, text: str, name: str = "note.md") -> None:
		(self.root / "AGENT/Session Notes" / name).write_text(text, encoding="utf-8")

	def publish_canonical(self, *entries: tuple[str, str]) -> None:
		"""Put a ledger on the canonical docs line and point the tracking ref at it.

		The feature branch's own ledger is preserved across the switch so a test can
		set up the two sources independently.
		"""
		path = self.root / LEDGER
		stash = path.read_text(encoding="utf-8") if path.exists() else None
		self.git("stash", "-qu") if stash is not None else None
		self.git("switch", "-q", "agent/integration")
		self.write_ledger(*entries)
		self.commit("Canonical ledger")
		self.git("update-ref", "refs/remotes/origin/agent/integration", "HEAD")
		self.git("switch", "-q", "agent/feature")
		if stash is None:
			path.unlink(missing_ok=True)
		else:
			self.git("stash", "pop", "-q")

	def run(self, *args: str) -> subprocess.CompletedProcess[str]:
		return subprocess.run(
			["python3", "scripts/ci/check_session_commit_claims.py", *args],
			cwd=self.root, text=True, stdout=subprocess.PIPE,
			stderr=subprocess.STDOUT, check=False, env={**os.environ},
		)


class LedgerClaimsTest(unittest.TestCase):
	def setUp(self) -> None:
		self.fixture = LedgerFixture()

	def tearDown(self) -> None:
		self.fixture.close()

	def test_working_tree_ledger_alone_passes(self) -> None:
		"""The core fix: no fetched remote ref is required to validate own commits."""
		self.fixture.write_ledger((self.fixture.feature, "Feature work"))
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)
		self.assertIn("canonical ref absent", result.stdout)

	def test_unclaimed_commit_fails(self) -> None:
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("is claimed 0 time(s)", result.stdout)

	def test_wrong_subject_fails(self) -> None:
		self.fixture.write_ledger((self.fixture.feature, "Different subject"))
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("git has 'Feature work'", result.stdout)

	def test_same_claim_in_both_sources_is_not_a_double_claim(self) -> None:
		"""What broke before: agent-claim.sh and the branch note both held the claim,
		and the check counted two owners for one commit."""
		self.fixture.write_ledger((self.fixture.feature, "Feature work"))
		self.fixture.publish_canonical((self.fixture.feature, "Feature work"))
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)

	def test_canonical_only_claim_passes(self) -> None:
		"""A claim that reached the docs line after this branch was cut still counts."""
		self.fixture.publish_canonical((self.fixture.feature, "Feature work"))
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)

	def test_conflicting_subjects_across_sources_fails(self) -> None:
		self.fixture.write_ledger((self.fixture.feature, "Feature work"))
		self.fixture.publish_canonical((self.fixture.feature, "Canonical subject"))
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("is claimed 2 time(s)", result.stdout)

	def test_claim_only_in_note_prose_is_reported(self) -> None:
		"""The retired model must fail loudly, not count for nothing."""
		self.fixture.write_note(f"# Note\n\n- `{self.fixture.feature}` — Feature work\n")
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("claimed in a session note but not in", result.stdout)

	def test_fix_writes_sorted_ledger(self) -> None:
		(self.fixture.root / "second.txt").write_text("second\n", encoding="utf-8")
		self.fixture.commit("Second commit")
		result = self.fixture.run("--fix")
		self.assertEqual(result.returncode, 0, result.stdout)
		lines = [
			line
			for line in (self.fixture.root / LEDGER)
			.read_text(encoding="utf-8")
			.splitlines()
			if not line.startswith("#")
		]
		self.assertEqual(len(lines), 2, lines)
		shas = [line.split("\t")[0] for line in lines]
		self.assertEqual(shas, sorted(shas))

	def test_fix_is_idempotent(self) -> None:
		self.assertEqual(self.fixture.run("--fix").returncode, 0)
		again = self.fixture.run("--fix")
		self.assertEqual(again.returncode, 0, again.stdout)
		self.assertIn("nothing to fix", again.stdout)

	def test_note_only_commit_needs_no_claim(self) -> None:
		self.fixture.write_ledger((self.fixture.feature, "Feature work"))
		self.fixture.write_note("# Just a note\n", name="2026-08-04-session.md")
		self.fixture.commit("Session note: something")
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)

	def test_ledger_only_commit_needs_no_claim(self) -> None:
		"""Committing the ledger itself must not require a claim for that commit."""
		result = self.fixture.run("--fix")
		self.assertEqual(result.returncode, 0, result.stdout)
		self.fixture.commit("Claim the feature commit")
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
	unittest.main()
