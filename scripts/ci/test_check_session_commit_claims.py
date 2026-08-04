#!/usr/bin/env python3
"""Regression tests for canonical docs-line commit claims."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).with_name("check_session_commit_claims.py")


class ClaimFixture:
	def __init__(self) -> None:
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		self.git("init", "-q")
		self.git("config", "user.name", "Fixture")
		self.git("config", "user.email", "fixture@example.invalid")
		(self.root / "scripts/ci").mkdir(parents=True)
		(self.root / "AGENT/Session Notes").mkdir(parents=True)
		shutil.copy2(SOURCE, self.root / "scripts/ci/check_session_commit_claims.py")
		(self.root / "seed.txt").write_text("seed\n", encoding="utf-8")
		self.commit("Seed")
		self.base = self.git("rev-parse", "HEAD")
		(self.root / "AGENT/Session Notes/COMMIT_CLAIMS_BASE").write_text(
			self.base + "\n", encoding="utf-8"
		)
		self.git("add", ".")
		self.git("commit", "-qm", "Add claim tooling")
		self.tooling = self.git("rev-parse", "HEAD")
		(self.root / "AGENT/Session Notes/COMMIT_CLAIMS_BASE").write_text(
			self.tooling + "\n", encoding="utf-8"
		)
		self.git("switch", "-qc", "agent/feature")
		(self.root / "feature.txt").write_text("feature\n", encoding="utf-8")
		self.commit("Feature work")
		self.feature = self.git("rev-parse", "HEAD")

	def close(self) -> None:
		self.temp.cleanup()

	def git(self, *args: str) -> str:
		return subprocess.check_output(["git", *args], cwd=self.root, text=True).strip()

	def commit(self, subject: str) -> None:
		self.git("add", ".")
		self.git("commit", "-qm", subject)

	def publish_note(self, subject: str = "Feature work", duplicate: bool = False) -> None:
		self.git("branch", "agent/staging-area", self.tooling)
		self.git("switch", "-q", "agent/staging-area")
		note = f"# Note\n\n- `{self.feature}` — {subject}\n"
		(self.root / "AGENT/Session Notes/note.md").write_text(note, encoding="utf-8")
		if duplicate:
			(self.root / "AGENT/Session Notes/other.md").write_text(note, encoding="utf-8")
		self.commit("Claim feature")
		staging = self.git("rev-parse", "HEAD")
		self.git("update-ref", "refs/remotes/origin/agent/staging-area", staging)
		self.git("switch", "-q", "agent/feature")

	def run(self) -> subprocess.CompletedProcess[str]:
		return subprocess.run(
			["python3", "scripts/ci/check_session_commit_claims.py"], cwd=self.root,
			text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
			env={**os.environ, "SESSION_CLAIMS_REF": "refs/remotes/origin/agent/staging-area"},
		)


class CanonicalClaimsTest(unittest.TestCase):
	def setUp(self) -> None:
		self.fixture = ClaimFixture()

	def tearDown(self) -> None:
		self.fixture.close()

	def test_feature_claimed_only_on_staging_passes(self) -> None:
		self.fixture.publish_note()
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)
		self.assertIn("claims=agent/staging-area", result.stdout)

	def test_missing_staging_ref_fails_with_fetch_instruction(self) -> None:
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("canonical claims ref is missing", result.stdout)
		self.assertIn("Fetch agent/staging-area", result.stdout)

	def test_unclaimed_feature_fails(self) -> None:
		self.fixture.publish_note(subject="Different subject")
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("git has 'Feature work'", result.stdout)

	def test_duplicate_claim_fails(self) -> None:
		self.fixture.publish_note(duplicate=True)
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("claimed 2 time(s)", result.stdout)

	def test_staging_precommit_reads_uncommitted_note(self) -> None:
		self.fixture.git("branch", "agent/staging-area", self.fixture.feature)
		self.fixture.git("switch", "-q", "agent/staging-area")
		(self.fixture.root / "AGENT/Session Notes/note.md").write_text(
			f"# Note\n\n- `{self.fixture.feature}` — Feature work\n", encoding="utf-8"
		)
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
	unittest.main()
