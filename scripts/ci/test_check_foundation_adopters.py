#!/usr/bin/env python3
"""Regression tests for the foundation-adopter guard.

Every case is asserted in BOTH directions. A guard verified only where it passes is
how the pack-freshness check came to report SKIPPED against a workspace that had both
packs cloned, and this guard has its own instance of that failure: its first draft
went green on `ControllerWebBridge` because a marker comment written in the same pass
named it, which made an unadopted type look reached. `test_comment_mention_is_not_adoption`
is that incident.

The last test runs the checker over the real repository. That is what gates it: the
required-test runner discovers every `scripts/ci/test_*.py`, so the guard cannot be
left out of the gate by forgetting a workflow line.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECKER = Path(__file__).with_name("check_foundation_adopters.py")
REPO_ROOT = Path(__file__).resolve().parents[2]

# A scene whose script is `rel`, in the shape the checker's SCENE_SCRIPT regex reads.
SCENE = '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://{rel}" id="1"]\n\n[node name="Root" type="Control"]\nscript = ExtResource("1")\n'


class Fixture:
    """A throwaway tree with the directories and project.godot the checker scans."""

    def __init__(self, autoloads: dict[str, str] | None = None) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir(parents=True)
        (self.root / "scripts/tests").mkdir(parents=True)
        (self.root / "scenes").mkdir(parents=True)
        body = "[application]\n\n[autoload]\n\n"
        for name, rel in (autoloads or {}).items():
            body += f'{name}="*res://{rel}"\n'
        body += "\n[rendering]\n"
        (self.root / "project.godot").write_text(body, encoding="utf-8")

    def close(self) -> None:
        self.temp.cleanup()

    def write(self, rel: str, body: str) -> None:
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def scene(self, rel: str, script_rel: str) -> None:
        self.write(rel, SCENE.format(rel=script_rel))

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(CHECKER), "--root", str(self.root), "--list-waivers"],
            capture_output=True, text=True, check=False,
        )


class FoundationAdopterGuardTest(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = Fixture()
        self.addCleanup(self.fixture.close)

    def test_type_reached_from_a_scene_passes(self):
        self.fixture.write("scripts/Screen.gd", "extends Control\n\nfunc _ready():\n\tvar x = Widget.new()\n")
        self.fixture.write("scripts/Widget.gd", "class_name Widget extends RefCounted\n")
        self.fixture.scene("scenes/Screen.tscn", "scripts/Screen.gd")
        result = self.fixture.run()
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_type_reached_only_by_a_test_fails(self):
        self.fixture.write("scripts/Widget.gd", "class_name Widget extends RefCounted\n")
        self.fixture.write("scripts/tests/test_widget.gd", "extends Node\n\nfunc t():\n\tvar x = Widget.new()\n")
        result = self.fixture.run()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("Widget", result.stdout)

    def test_orphan_cluster_is_caught(self):
        # The PrepActivityRegistry/PrepActivityDef shape: two types that reference each
        # other and nothing else. A direct-reference check calls the registry adopted;
        # reachability from real entry points does not, which is the whole reason this
        # check walks the graph instead of grepping.
        self.fixture.write("scripts/Registry.gd", "class_name Registry extends RefCounted\n")
        self.fixture.write("scripts/Def.gd", "class_name Def extends Resource\n\nvar r = Registry.new()\n")
        result = self.fixture.run()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("Registry", result.stdout)
        self.assertIn("Def", result.stdout)

    def test_comment_mention_is_not_adoption(self):
        # The incident this guard had on itself. `Widget` is named only in prose from a
        # file that IS reachable; prose is not a caller.
        self.fixture.write("scripts/Screen.gd", "extends Control\n# See Widget for the parsing rules.\n")
        self.fixture.write("scripts/Widget.gd", "class_name Widget extends RefCounted\n")
        self.fixture.scene("scenes/Screen.tscn", "scripts/Screen.gd")
        result = self.fixture.run()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("Widget", result.stdout)

    def test_hash_inside_a_string_is_not_a_comment(self):
        # strip_comments must not eat code after a `#` that sits in a string literal,
        # or it would hide real adoptions and the guard would fail in the loud
        # direction on files that are fine.
        self.fixture.write(
            "scripts/Screen.gd",
            'extends Control\n\nfunc _ready():\n\tvar s = "#ffffff"\n\tvar w = Widget.new()\n',
        )
        self.fixture.write("scripts/Widget.gd", "class_name Widget extends RefCounted\n")
        self.fixture.scene("scenes/Screen.tscn", "scripts/Screen.gd")
        result = self.fixture.run()
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_allow_marker_waives_and_is_listed(self):
        self.fixture.write(
            "scripts/Widget.gd",
            "class_name Widget extends RefCounted\n# adopter-allow: read by an out-of-repo harness\n",
        )
        result = self.fixture.run()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("read by an out-of-repo harness", result.stdout)

    def test_todo_marker_defers_but_is_printed(self):
        self.fixture.write(
            "scripts/Widget.gd",
            "class_name Widget extends RefCounted\n# adopter-todo: SOME-ROW-2026-08-22\n",
        )
        result = self.fixture.run()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("owed by SOME-ROW-2026-08-22", result.stdout)

    def test_marker_below_the_window_does_not_waive(self):
        # A marker written for one declaration must not silence another far below it.
        body = "class_name Widget extends RefCounted\n" + "\n" * 40 + "# adopter-allow: too far away\n"
        self.fixture.write("scripts/Widget.gd", body)
        result = self.fixture.run()
        self.assertEqual(result.returncode, 1, result.stdout)

    def test_autoload_with_a_caller_passes(self):
        fixture = Fixture(autoloads={"Service": "scripts/Service.gd"})
        self.addCleanup(fixture.close)
        fixture.write("scripts/Service.gd", "extends Node\n")
        fixture.write("scripts/User.gd", 'extends Node\n\nfunc f():\n\treturn get_node("/root/Service")\n')
        fixture.scene("scenes/User.tscn", "scripts/User.gd")
        result = fixture.run()
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_autoload_with_no_caller_fails(self):
        # Rule 1 can never flag an autoload -- it is its own reachability root. This is
        # why the second rule exists, and it is the rule that covers an `extends Node`
        # service with no class_name at all.
        fixture = Fixture(autoloads={"Service": "scripts/Service.gd"})
        self.addCleanup(fixture.close)
        fixture.write("scripts/Service.gd", "extends Node\n")
        result = fixture.run()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("autoload", result.stdout)
        self.assertIn("Service", result.stdout)

    def test_autoload_named_only_by_a_test_fails(self):
        fixture = Fixture(autoloads={"Service": "scripts/Service.gd"})
        self.addCleanup(fixture.close)
        fixture.write("scripts/Service.gd", "extends Node\n")
        fixture.write("scripts/tests/test_service.gd", 'extends Node\n\nfunc t():\n\treturn Service\n')
        result = fixture.run()
        self.assertEqual(result.returncode, 1, result.stdout)

    def test_real_repository_is_clean(self):
        """The gate. Every real instance is adopted, deferred with a row, or waived."""
        result = subprocess.run(
            [sys.executable, str(CHECKER), "--root", str(REPO_ROOT)],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
