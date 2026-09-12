#!/usr/bin/env python3

import importlib.util
import json
import os
import tempfile
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

    def test_only_public_bound_pack_checkouts_are_scanned(self):
        for branch, expected in (
            ("main", True),
            ("agent/staging-area", True),
            ("agent/from-main/retune", False),
        ):
            completed = mock.Mock(stdout=branch + "\n")
            with self.subTest(branch=branch), mock.patch.object(
                release_source.subprocess, "run", return_value=completed
            ):
                self.assertEqual(release_source.is_public_line_checkout(Path(".")), expected)

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

    def test_distribution_defaults_to_public(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            self.assertEqual(release_source.distribution_scope(), "public")

    def test_distribution_rejects_unknown_scope(self):
        with mock.patch.dict(
            os.environ, {"PROMETHEUS_DISTRIBUTION_SCOPE": "maybe"}, clear=True
        ):
            with self.assertRaisesRegex(SystemExit, "must be public or internal"):
                release_source.distribution_scope()

    def test_private_manifest_in_export_surface_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pack = root / "packs" / "internal"
            pack.mkdir(parents=True)
            (pack / "manifest.json").write_text(
                json.dumps({"distribution_policy": "private_only"}), encoding="utf-8"
            )
            self.assertEqual(
                release_source.private_export_manifests(root, ("test_fixtures/**",)),
                [Path("packs/internal/manifest.json")],
            )

    def test_private_manifest_in_excluded_fixture_is_allowed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / "test_fixtures" / "internal"
            fixture.mkdir(parents=True)
            (fixture / "manifest.json").write_text(
                json.dumps({"distribution_policy": "private_only"}), encoding="utf-8"
            )
            self.assertEqual(
                release_source.private_export_manifests(root, ("test_fixtures/**",)), []
            )

    def test_renamed_fe_payload_is_detected_by_content(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            public_root = workspace / "public"
            fe_root = workspace / "fe"
            (public_root / "assets").mkdir(parents=True)
            (fe_root / "packs" / "sample" / "data").mkdir(parents=True)
            source = fe_root / "packs" / "sample" / "data" / "unit.json"
            target = public_root / "assets" / "renamed.json"
            source.write_text('{"growth": 80}\n', encoding="utf-8")
            target.write_bytes(source.read_bytes())

            self.assertEqual(
                release_source.copied_fe_payloads(public_root, fe_root, ()),
                [(Path("assets/renamed.json"), Path("packs/sample/data/unit.json"))],
            )

    def test_excluded_copy_does_not_block_export(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            public_root = workspace / "public"
            fe_root = workspace / "fe"
            (public_root / "data").mkdir(parents=True)
            (fe_root / "packs" / "sample" / "data").mkdir(parents=True)
            source = fe_root / "packs" / "sample" / "data" / "unit.json"
            target = public_root / "data" / "unit.json"
            source.write_text('{"growth": 80}\n', encoding="utf-8")
            target.write_bytes(source.read_bytes())

            self.assertEqual(
                release_source.copied_fe_payloads(public_root, fe_root, ("data/**",)), []
            )


if __name__ == "__main__":
    unittest.main()
