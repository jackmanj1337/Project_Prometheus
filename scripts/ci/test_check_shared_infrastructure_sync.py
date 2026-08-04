#!/usr/bin/env python3
"""Regression tests for the executed-infrastructure sync guard.

Pins the shape of the real incident: a hook change that landed on the staging line
and never reached the feature base, so the two lines ran different code.
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).with_name("check_shared_infrastructure_sync.py")


class InfraFixture:
	"""A repo with a feature base and a staging line that can diverge."""

	def __init__(self) -> None:
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		self.git("init", "-q", "-b", "agent/integration")
		self.git("config", "user.name", "Fixture")
		self.git("config", "user.email", "fixture@example.invalid")
		(self.root / "scripts/ci").mkdir(parents=True)
		(self.root / "scripts/hooks").mkdir(parents=True)
		shutil.copy2(SOURCE, self.root / "scripts/ci/check_shared_infrastructure_sync.py")
		(self.root / "scripts/hooks/pre-push").write_text("v1\n", encoding="utf-8")
		(self.root / "README.md").write_text("readme\n", encoding="utf-8")
		self.commit("Seed")
		self.git("update-ref", "refs/remotes/origin/agent/integration", "HEAD")
		self.git("switch", "-qc", "agent/staging-area")

	def close(self) -> None:
		self.temp.cleanup()

	def git(self, *args: str) -> str:
		return subprocess.check_output(["git", *args], cwd=self.root, text=True).strip()

	def commit(self, subject: str) -> None:
		self.git("add", "-A")
		self.git("commit", "-qm", subject)

	def write(self, rel: str, text: str) -> None:
		path = self.root / rel
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")

	def sync_base(self) -> None:
		"""Bring the feature base up to the staging line, as the remedy instructs."""
		head = self.git("rev-parse", "HEAD")
		self.git("update-ref", "refs/remotes/origin/agent/integration", head)

	def run(self, *args: str) -> subprocess.CompletedProcess[str]:
		return subprocess.run(
			["python3", "scripts/ci/check_shared_infrastructure_sync.py",
			 "--pushed", "HEAD", *args],
			cwd=self.root, text=True, stdout=subprocess.PIPE,
			stderr=subprocess.STDOUT, check=False,
		)


class InfraSyncTest(unittest.TestCase):
	def setUp(self) -> None:
		self.fixture = InfraFixture()

	def tearDown(self) -> None:
		self.fixture.close()

	def test_hook_change_only_on_staging_fails(self) -> None:
		"""The actual incident: a hook lands on staging, feature branches never see it."""
		self.fixture.write("scripts/hooks/pre-push", "v2\n")
		self.fixture.commit("Rewrite the pre-push hook")
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0, result.stdout)
		self.assertIn("infra-sync: FAIL", result.stdout)
		self.assertIn("Rewrite the pre-push hook", result.stdout)

	def test_ci_check_change_only_on_staging_fails(self) -> None:
		self.fixture.write("scripts/ci/check_something.py", "print('v2')\n")
		self.fixture.commit("Add a CI check")
		result = self.fixture.run()
		self.assertNotEqual(result.returncode, 0)
		self.assertIn("Add a CI check", result.stdout)

	def test_remedy_clears_it(self) -> None:
		self.fixture.write("scripts/hooks/pre-push", "v2\n")
		self.fixture.commit("Rewrite the pre-push hook")
		self.assertNotEqual(self.fixture.run().returncode, 0)
		self.fixture.sync_base()
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)
		self.assertIn("infra-sync: PASS", result.stdout)

	def test_non_executed_paths_may_strand(self) -> None:
		"""Docs on staging strand harmlessly; only executed code is fenced."""
		self.fixture.write("AGENT/Docs/plans/whatever.md", "plan\n")
		self.fixture.write("README.md", "changed\n")
		self.fixture.commit("Docs only")
		result = self.fixture.run()
		self.assertEqual(result.returncode, 0, result.stdout)

	def test_missing_base_skips_loudly(self) -> None:
		"""A check that quietly no-ops is how the original gap survived."""
		self.fixture.write("scripts/hooks/pre-push", "v2\n")
		self.fixture.commit("Rewrite the pre-push hook")
		result = self.fixture.run("--base", "refs/remotes/origin/nonexistent")
		self.assertEqual(result.returncode, 0)
		self.assertIn("SKIPPED", result.stdout)

	def test_short_base_ref_is_resolved_not_skipped(self) -> None:
		"""A short ref must be judged, not silently treated as absent."""
		self.fixture.write("scripts/hooks/pre-push", "v2\n")
		self.fixture.commit("Rewrite the pre-push hook")
		result = self.fixture.run("--base", "origin/agent/integration")
		self.assertNotEqual(result.returncode, 0, result.stdout)
		self.assertNotIn("SKIPPED", result.stdout)


if __name__ == "__main__":
	unittest.main()
