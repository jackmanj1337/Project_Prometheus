"""Smoke tests for the godot-analyzer MCP tools.

Run from /workspace:
    python3 -m unittest tools.godot-analyzer-mcp.tests.test_tools
Or directly:
    cd /workspace/tools/godot-analyzer-mcp && python3 -m unittest tests.test_tools

Covers the regression where validate_onready_paths returned "No scene found"
for every script because relative paths weren't anchored to project_root
before being round-tripped through _to_res.
"""

import sys
import unittest
from pathlib import Path

# Make tools/ importable regardless of cwd
HERE = Path(__file__).resolve().parent
MCP_ROOT = HERE.parent
sys.path.insert(0, str(MCP_ROOT))

from tools.script import validate_onready_paths
from tools.scene import find_scenes_with_script, get_scene_nodes
from tools.project import get_autoloads
from tools.resource import get_resource_fields

PROJECT_ROOT = MCP_ROOT.parent.parent  # /workspace


class TestValidateOnreadyPaths(unittest.TestCase):
    """The regression that motivated these tests: HUD.gd is attached to
    HUD.tscn, but validate_onready_paths returned "No scene found" for
    both relative and res:// inputs."""

    def test_relative_path_resolves_scene(self):
        out = validate_onready_paths("scripts/ui/HUD.gd", PROJECT_ROOT)
        self.assertIn("Scene:", out)
        self.assertIn("res://scenes/ui/HUD.tscn", out)
        self.assertNotIn("No scene found", out)

    def test_res_prefix_path_resolves_scene(self):
        out = validate_onready_paths("res://scripts/ui/HUD.gd", PROJECT_ROOT)
        self.assertIn("Scene:", out)
        self.assertIn("res://scenes/ui/HUD.tscn", out)

    def test_all_hud_paths_validate_ok(self):
        # Every @onready var in HUD.gd resolves against HUD.tscn. Assert no misses
        # rather than a hardcoded count (the count drifts as HUD.tscn grows).
        out = validate_onready_paths("scripts/ui/HUD.gd", PROJECT_ROOT)
        self.assertIn(" OK", out)
        self.assertNotIn("MISS", out)

    def test_script_with_no_onready_declarations(self):
        # CombatHUD.gd is a CanvasLayer subscriber, no @onready vars
        out = validate_onready_paths("scripts/ui/CombatHUD.gd", PROJECT_ROOT)
        self.assertIn("No @onready", out)

    def test_missing_file_returns_error(self):
        out = validate_onready_paths("scripts/does/not/exist.gd", PROJECT_ROOT)
        self.assertIn("Error:", out)


class TestFindScenesWithScript(unittest.TestCase):
    def test_relative_path(self):
        out = find_scenes_with_script("scripts/ui/HUD.gd", PROJECT_ROOT)
        self.assertIn("res://scenes/ui/HUD.tscn", out)

    def test_res_prefix_path(self):
        out = find_scenes_with_script("res://scripts/ui/HUD.gd", PROJECT_ROOT)
        self.assertIn("res://scenes/ui/HUD.tscn", out)

    def test_script_attached_to_no_scene(self):
        # CampaignRules.gd is a Resource subclass — never attached to any .tscn.
        # (SettingsScreen.gd, the old fixture, is now scene-attached.)
        out = find_scenes_with_script("scripts/resources/CampaignRules.gd", PROJECT_ROOT)
        self.assertIn("No scenes found", out)


class TestGetSceneNodes(unittest.TestCase):
    def test_hud_scene_has_expected_nodes(self):
        out = get_scene_nodes("scenes/ui/HUD.tscn", PROJECT_ROOT)
        for expected in ("HUD", "PhaseLabel", "TurnLabel", "UnitInfoPanel/VBox/UnitName"):
            self.assertIn(expected, out)

    def test_game_map_lists_attached_scripts(self):
        out = get_scene_nodes("scenes/core/GameMap.tscn", PROJECT_ROOT)
        # Script paths in the table should appear (with or without res:// prefix)
        self.assertIn("GameMap.gd", out)
        self.assertIn("MapCursor.gd", out)
        self.assertIn("GridManager.gd", out)


class TestGetAutoloads(unittest.TestCase):
    def test_all_ten_autoloads_present(self):
        out = get_autoloads(PROJECT_ROOT)
        for name in ("GameConstants", "EventBus", "SettingsManager", "GameState",
                     "DataManager", "ConditionManager", "SkillHandler",
                     "ItemHandler", "CombatResolver", "EnemyAI"):
            self.assertIn(name, out)


class TestGetResourceFields(unittest.TestCase):
    def test_iron_sword_fields(self):
        out = get_resource_fields("data/weapons/iron_sword.tres", PROJECT_ROOT)
        self.assertIn('id', out)
        self.assertIn('"iron_sword"', out)
        # Field was renamed weapon_type -> combat_family in the weapon schema.
        self.assertIn('combat_family', out)
        self.assertIn('"sword"', out)


if __name__ == "__main__":
    unittest.main()
