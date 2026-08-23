#!/usr/bin/env python3
"""Structural regression tests for the exported-registry gate."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent


class ExportedRegistryGateTests(unittest.TestCase):
    def test_engine_registries_are_outside_excluded_campaign_data(self) -> None:
        preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
        self.assertIn("data/**", preset)
        self.assertNotIn("engine_data/**", preset)
        for family in (
            "action_primitives",
            "resource_types",
            "occupancy_policies",
            "objective_conditions",
            "item_effects",
            "campaign_vars",
        ):
            root = ROOT / "engine_data" / "registries" / family
            self.assertTrue(root.is_dir(), family)
            self.assertTrue((root / "resource_manifest.json").is_file(), family)

    def test_archive_gate_checks_runtime_registry_activation(self) -> None:
        gate = (ROOT / "scripts/shared/ExportedRegistryGate.gd").read_text(encoding="utf-8")
        self.assertIn("CampaignTier2RuntimeAdapter.gd", gate)
        self.assertIn("build_candidate_from_entries", gate)
        self.assertIn("archive activation:", gate)

    def test_shell_gate_resolves_windows_preset_and_checks_output(self) -> None:
        gate = (ROOT / "check_exported_registry_gate.sh").read_text(encoding="utf-8")
        self.assertIn('platform == "Windows Desktop"', gate)
        self.assertIn('--export-pack "$WINDOWS_PRESET" "$PCK"', gate)
        self.assertIn('[[ -s "$PCK" ]]', gate)
        self.assertNotIn('Project Prometheus v0.7.0', gate)

    def test_no_registry_resources_remain_under_campaign_data(self) -> None:
        self.assertFalse((ROOT / "data" / "registries").exists())

    def test_runtime_and_extractor_use_export_safe_root(self) -> None:
        expectations = {
            "scripts/autoloads/RegistryManager.gd": "res://engine_data",
            "scripts/autoloads/DataManager.gd": "res://engine_data",
            "scripts/registries/ItemEffectRegistry.gd": "res://engine_data/registries",
            "scripts/registries/ObjectiveConditionRegistry.gd": "res://engine_data/registries",
            "scripts/tools/extract_proving_grounds_pack.gd": "res://engine_data/registries",
        }
        for relative, expected in expectations.items():
            text = (ROOT / relative).read_text(encoding="utf-8")
            self.assertIn(expected, text, relative)
            self.assertNotIn("res://data/registries", text, relative)


if __name__ == "__main__":
    unittest.main()
