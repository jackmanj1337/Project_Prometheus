#!/usr/bin/env python3

import importlib.util
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).with_name("check_release_source_branch.py")
SPEC = importlib.util.spec_from_file_location("release_source", MODULE_PATH)
release_source = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(release_source)


class ReleaseSourceBranchTests(unittest.TestCase):
    def test_current_branch_strips_git_output(self):
        completed = mock.Mock(stdout="agent/playtest-release-v0.5-fixes\n")
        with mock.patch.object(release_source.subprocess, "run", return_value=completed):
            self.assertEqual(
                release_source.current_branch(), "agent/playtest-release-v0.5-fixes"
            )

    def test_version_matches_export_preset(self):
        self.assertEqual(release_source.read_version(), "0.5.1")


if __name__ == "__main__":
    unittest.main()
