#!/usr/bin/env python3
"""Check 11 regressions: assignment must not be inferred from incidental prose."""

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[2] / "AGENT/Docs/check_docs.py"
SPEC = importlib.util.spec_from_file_location("audit_docs_check", SOURCE)
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


def document(rules):
    return "<!-- BEGIN AUDIT COVERAGE -->\n```json\n" + json.dumps(rules) + (
        "\n```\n<!-- END AUDIT COVERAGE -->\n"
    )


class AuditCoverageTests(unittest.TestCase):
    def test_incidental_directory_name_does_not_cover_new_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            master = root / "master.md"
            master.write_text(document([{"patterns": ["scripts/*"], "pillar": 1}])
                              + "An example mentions forgotten/ here.\n")
            with patch.object(CHECK, "ROOT", root), patch.object(
                CHECK, "_MASTER_REVIEW_DOC", master
            ), patch.object(CHECK, "_failures", []), patch.object(
                CHECK.subprocess, "check_output", return_value="forgotten/file.gd\0"
            ):
                CHECK.check_tree_completeness()
                self.assertEqual(len(CHECK._failures), 1)
                self.assertIn("forgotten/file.gd", CHECK._failures[0])

    def test_specific_rule_precedes_general_owner(self):
        rules = CHECK.audit_coverage_rules(document([
            {"patterns": ["scripts/tests/*"], "pillar": 4},
            {"patterns": ["scripts/*"], "pillar": 1},
        ]))
        self.assertEqual(4, CHECK.audit_path_owner("scripts/tests/nested/test.gd", rules))
        self.assertEqual(1, CHECK.audit_path_owner("scripts/core/game.gd", rules))
        self.assertIsNone(CHECK.audit_path_owner("new_config.json", rules))
        self.assertIsNone(CHECK.audit_path_owner(".new_ci/workflow", rules))

    def test_missing_duplicate_invalid_or_catch_all_map_rejected(self):
        good = document([{"patterns": ["scripts/*"], "pillar": 1}])
        for content in ("scripts/ is covered", good + good,
                        document([{"patterns": ["*"], "pillar": 1}]),
                        document([{"patterns": ["scripts/*"], "pillar": 6}]),
                        document([{"patterns": ["scripts/*", "scripts/*"], "pillar": 1}])):
            with self.subTest(content=content), self.assertRaises(ValueError):
                CHECK.audit_coverage_rules(content)

    def test_protected_paths_are_identified_without_opening_them(self):
        for name in (".env", "nested/.env.example", "nested/signing.key",
                     "credentials.json", "secrets.json/file", "cert.PFX"):
            self.assertTrue(CHECK.audit_protected_path(name), name)
        self.assertFalse(CHECK.audit_protected_path("scripts/core/game.gd"))

    def test_missing_master_fails_instead_of_silently_passing(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(CHECK, "_MASTER_REVIEW_DOC", Path(directory) / "missing"), \
                    patch.object(CHECK, "_failures", []):
                CHECK.check_tree_completeness()
                self.assertEqual(len(CHECK._failures), 1)
                self.assertIn("cannot check coverage", CHECK._failures[0])


if __name__ == "__main__":
    unittest.main()
