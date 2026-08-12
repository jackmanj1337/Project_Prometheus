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
        # Assert the BEHAVIOUR — that read_version returns the preset's
        # product_version — not a literal version string. Pinning the literal made this
        # test fail on every release bump, so a permanently-red suite became something
        # to explain away in release notes rather than a signal. It was red at 0.6.1
        # while claiming 0.5.1.
        preset = (Path(release_source.__file__).resolve().parents[2] / "export_presets.cfg")
        expected = release_source.VERSION_RE.search(preset.read_text(encoding="utf-8"))
        self.assertIsNotNone(expected, "export preset has no application/product_version")
        self.assertEqual(release_source.read_version(), expected.group(1))

    def test_version_is_a_release_number(self):
        self.assertRegex(release_source.read_version(), r"^\d+\.\d+\.\d+$")


if __name__ == "__main__":
    unittest.main()
