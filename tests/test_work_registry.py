#!/usr/bin/env python3
from __future__ import annotations

import copy
import datetime as dt
import importlib.util
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("work_registry", ROOT / "scripts/work_registry.py")
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class RegistryValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.data = MODULE.load()
        self.today = dt.date(2026, 7, 16)

    def errors(self, data):
        return MODULE.validate(data, check_git=False, today=self.today)

    def test_seed_is_structurally_valid(self):
        self.assertEqual([], self.errors(self.data))

    def test_duplicate_work_id_is_rejected(self):
        broken = copy.deepcopy(self.data)
        duplicate = copy.deepcopy(broken["work"][0])
        duplicate["branch"] = "agent/codex/2026-07-16/other"
        broken["work"].append(duplicate)
        self.assertTrue(any("duplicate Work ID" in error for error in self.errors(broken)))

    def test_duplicate_branch_claim_is_rejected(self):
        broken = copy.deepcopy(self.data)
        duplicate = copy.deepcopy(broken["work"][0])
        duplicate["work_id"] = "OTHER-WORK"
        broken["work"].append(duplicate)
        self.assertTrue(any("duplicate branch claim" in error for error in self.errors(broken)))

    def test_missing_required_field_is_rejected(self):
        broken = copy.deepcopy(self.data)
        del broken["work"][0]["base_sha"]
        self.assertTrue(any("missing fields" in error for error in self.errors(broken)))

    def test_unexpected_base_is_rejected(self):
        broken = copy.deepcopy(self.data)
        broken["work"][0]["base_branch"] = "random-old-branch"
        self.assertTrue(any("unexpected feature base" in error for error in self.errors(broken)))

    def test_declared_lifecycle_branch_is_accepted(self):
        lifecycle = next(item for item in self.data["work"] if item["branch"] == "agent/integration")
        self.assertFalse(any(lifecycle["work_id"] in error for error in self.errors(self.data)))

    def test_stale_active_item_is_rejected(self):
        broken = copy.deepcopy(self.data)
        broken["work"][0]["last_update"] = "2026-06-01"
        self.assertTrue(any("stale active item" in error for error in self.errors(broken)))

    def test_blocked_work_requires_resume_trigger(self):
        broken = copy.deepcopy(self.data)
        broken["work"][0]["status"] = "blocked"
        broken["work"][0].pop("trigger", None)
        self.assertTrue(any("requires a resume trigger" in error for error in self.errors(broken)))

    def test_playtesting_release_requires_tag(self):
        broken = copy.deepcopy(self.data)
        broken["release_trains"][0]["acceptance"] = "playtesting"
        broken["release_trains"][0]["playtest_tags"] = []
        self.assertTrue(any("missing playtest tag" in error for error in self.errors(broken)))

    def test_accepted_release_requires_stable_tag(self):
        broken = copy.deepcopy(self.data)
        broken["release_trains"][0]["acceptance"] = "accepted"
        self.assertTrue(any("missing stable tag" in error for error in self.errors(broken)))

    def test_registered_missing_branch_is_rejected(self):
        with mock.patch.object(MODULE, "ref_exists", return_value=False), \
                mock.patch.object(MODULE, "git_lines", return_value=[]):
            errors = MODULE.validate(self.data, check_git=True, today=self.today)
        self.assertTrue(any("registered branch does not exist" in error for error in errors))

    def test_unregistered_remote_branch_is_rejected(self):
        def exists(ref):
            return ref.startswith("refs/remotes/origin/") or ref.startswith("refs/heads/")
        with mock.patch.object(MODULE, "ref_exists", side_effect=exists), \
                mock.patch.object(MODULE, "git_lines", return_value=["origin/agent/codex/2026-07-16/unclaimed"]):
            errors = MODULE.validate(self.data, check_git=True, today=self.today)
        self.assertTrue(any("active remote branch absent" in error for error in errors))

    def test_completed_branch_must_be_retired(self):
        broken = copy.deepcopy(self.data)
        broken["work"][0]["status"] = "completed"
        with mock.patch.object(MODULE, "ref_exists", return_value=True), \
                mock.patch.object(MODULE, "git_lines", return_value=[]):
            errors = MODULE.validate(broken, check_git=True, today=self.today)
        self.assertTrue(any("completed work still has a branch" in error for error in errors))

    def test_release_requires_source_sha(self):
        broken = copy.deepcopy(self.data)
        broken["release_trains"][0]["source_sha"] = ""
        self.assertTrue(any("missing source SHA" in error for error in self.errors(broken)))


if __name__ == "__main__":
    unittest.main()
