#!/usr/bin/env python3
"""Regression tests for the project-owned cadence authority."""
import subprocess
import tempfile
import unittest
from datetime import date
from pathlib import Path

import audit_cadence


class AuditCadenceTests(unittest.TestCase):
    def make_repo(self):
        fixture = tempfile.TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        root = Path(fixture.name)
        reviews = root / "AGENT" / "Code Reviews"
        reviews.mkdir(parents=True)
        for args in (("init", "-q"), ("config", "user.name", "Test"), ("config", "user.email", "test@example.invalid")):
            subprocess.run(["git", "-C", str(root), *args], check=True)
        return root, reviews

    def commit(self, root, message):
        subprocess.run(["git", "-C", str(root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(root), "commit", "-qm", message], check=True)
        return audit_cadence.git("rev-parse", "HEAD", repo=root)

    def test_metadata_is_stable_after_report_correction_and_suffix_is_supported(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            reviews = repo / "AGENT" / "Code Reviews"
            reviews.mkdir(parents=True)
            for args in (("init", "-q"), ("config", "user.name", "Test"), ("config", "user.email", "test@example.invalid")):
                subprocess.run(["git", "-C", str(repo), *args], check=True)
            report = reviews / "full_review_rollup_2026-01-01-b.md"
            report.write_text("**Audit date:** 2026-01-01\n", encoding="utf-8")
            subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "audit"], check=True)
            audited = audit_cadence.git("rev-parse", "HEAD", repo=repo)
            (repo / "later").write_text("x", encoding="utf-8")
            subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "later"], check=True)
            report.write_text(f"**Audit date:** 2026-01-01\n**Audited commit:** {audited}\n", encoding="utf-8")
            subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "correction"], check=True)
            result = audit_cadence.audit_cadence(repo)
            self.assertEqual("metadata", result["baseline_source"])
            self.assertEqual(audited, result["commit"])
            self.assertEqual(2, result["commits_since_rollup"])
            self.assertEqual((date.today() - date(2026, 1, 1)).days, result["days_since_rollup"])

    def test_bad_metadata_future_duplicate_missing_and_untracked(self):
        for body in (
            "**Audit date:** nope\n**Audited commit:** bad\n",
            "**Audit date:** 2999-01-01\n**Audited commit:** " + "0" * 40 + "\n",
            "**Audit date:** 2020-01-01\n**Audit date:** 2020-01-02\n**Audited commit:** " + "0" * 40 + "\n",
            "**Audit date:** 2020-01-01\n",
        ):
            with tempfile.TemporaryDirectory() as directory:
                root, reviews = self.make_repo()
                report = reviews / "full_review_rollup_2020-01-01.md"
                report.write_text(body, encoding="utf-8")
                self.commit(root, "report")
                self.assertEqual("unknown", audit_cadence.audit_cadence(root)["status"])
        with tempfile.TemporaryDirectory() as directory:
            root, reviews = self.make_repo()
            report = reviews / "full_review_rollup_2020-01-01.md"
            report.write_text("**Audit date:** 2020-01-01\n**Audited commit:** " + "0" * 40 + "\n", encoding="utf-8")
            self.assertEqual("unknown", audit_cadence.audit_cadence(root)["status"])

    def test_invalid_filename_does_not_crash(self):
        with tempfile.TemporaryDirectory() as directory:
            root, reviews = self.make_repo()
            (reviews / "full_review_rollup_2026-99-99.md").write_text("x", encoding="utf-8")
            (reviews / "full_review_rollup_2020-01-01.md").write_text("x", encoding="utf-8")
            self.commit(root, "reports")
            result = audit_cadence.audit_cadence(root)
            self.assertEqual("2020-01-01", result["audit_date"])

    def test_legacy_correction_keeps_first_add_commit_and_filename_date(self):
        root, reviews = self.make_repo()
        report = reviews / "full_review_rollup_2020-01-01.md"
        report.write_text("Original audit\n", encoding="utf-8")
        first = self.commit(root, "audit")
        report.write_text("Corrected wording\n", encoding="utf-8")
        self.commit(root, "correction")
        result = audit_cadence.audit_cadence(root)
        self.assertEqual("legacy", result["baseline_source"])
        self.assertEqual(first, result["commit"])
        self.assertEqual(1, result["commits_since_rollup"])
        self.assertEqual((date.today() - date(2020, 1, 1)).days, result["days_since_rollup"])

    def test_suffix_run_wins_over_base_even_after_base_is_edited(self):
        root, reviews = self.make_repo()
        base = reviews / "full_review_rollup_2020-01-01.md"
        suffix = reviews / "full_review_rollup_2020-01-01-b.md"
        base.write_text("first\n", encoding="utf-8")
        self.commit(root, "first audit")
        suffix.write_text("second\n", encoding="utf-8")
        second = self.commit(root, "second audit")
        base.write_text("corrected first\n", encoding="utf-8")
        self.commit(root, "correct old report")
        result = audit_cadence.audit_cadence(root)
        self.assertTrue(result["file"].endswith("-b.md"))
        self.assertEqual(second, result["commit"])

    def test_missing_and_nonancestor_sha_do_not_report_freshness(self):
        root, reviews = self.make_repo()
        (root / "base").write_text("base\n", encoding="utf-8")
        base = self.commit(root, "base")
        subprocess.run(["git", "-C", str(root), "switch", "-qc", "other"], check=True)
        (root / "other").write_text("other\n", encoding="utf-8")
        other = self.commit(root, "other branch")
        subprocess.run(["git", "-C", str(root), "checkout", "-q", base], check=True)
        for sha in (other, "f" * 40):
            report = reviews / "full_review_rollup_2020-01-01.md"
            report.write_text(f"**Audit date:** 2020-01-01\n**Audited commit:** {sha}\n")
            self.commit(root, "audit metadata")
            result = audit_cadence.audit_cadence(root)
            self.assertEqual("unknown", result["status"])
            self.assertIsNone(result["commits_since_rollup"])
            self.assertIsNone(result["days_since_rollup"])

    def test_absent_and_untracked_legacy_reports_are_distinct(self):
        root, reviews = self.make_repo()
        self.assertEqual("absent", audit_cadence.audit_cadence(root)["status"])
        (reviews / "full_review_rollup_2020-01-01.md").write_text("draft\n")
        result = audit_cadence.audit_cadence(root)
        self.assertEqual("unknown", result["status"])
        self.assertIsNone(result["days_since_rollup"])


if __name__ == "__main__":
    unittest.main()
