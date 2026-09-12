#!/usr/bin/env python3
"""Regression tests for the gated-entry reason guard.

Pins the shape of the real incidents the guard exists for: OverworldScreen's gated
nodes and MainMenu's Continue / Load Game, all disabled with no reason anywhere, none
of which failed anything. A guard verified only in the green direction is how the pack
freshness check briefly reported SKIPPED against a workspace that had both packs
cloned, so every case here is asserted in both directions.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECKER = Path(__file__).with_name("check_availability_reasons.py")


class Fixture:
    """A throwaway tree with the two directories the checker scans."""

    def __init__(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "scripts/ui").mkdir(parents=True)
        (self.root / "scripts/tests").mkdir(parents=True)
        (self.root / "scenes/ui").mkdir(parents=True)

    def close(self) -> None:
        self.temp.cleanup()

    def write(self, rel: str, body: str) -> None:
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(CHECKER), "--root", str(self.root)],
            capture_output=True,
            text=True,
            check=False,
        )


class CheckAvailabilityReasonsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = Fixture()
        self.addCleanup(self.fixture.close)

    def assert_clean(self, result: subprocess.CompletedProcess[str]) -> None:
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS", result.stdout)

    def assert_flags(self, result: subprocess.CompletedProcess[str], needle: str) -> None:
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn(needle, result.stdout)

    def test_gate_without_a_reason_fails(self) -> None:
        """The MainMenu incident: disabled set, no carrier anywhere in the file."""
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _refresh() -> void:\n\t_continue_btn.disabled = slots.is_empty()\n",
        )
        self.assert_flags(self.fixture.run(), "scripts/ui/Probe.gd:2")

    def test_gate_with_a_tooltip_passes(self) -> None:
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _refresh() -> void:\n"
            "\t_continue_btn.disabled = slots.is_empty()\n"
            '\t_continue_btn.tooltip_text = "" if not _continue_btn.disabled else _key()\n',
        )
        self.assert_clean(self.fixture.run())

    def test_a_label_does_not_satisfy_the_check(self) -> None:
        """PrepScreen's shape: explained on screen, silent when focus lands on it."""
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _refresh() -> void:\n"
            "\t_begin_button.disabled = not errors.is_empty()\n"
            "\t_validation.text = errors[0]\n",
        )
        self.assert_flags(self.fixture.run(), "_begin_button")

    def test_enabling_is_not_a_gate(self) -> None:
        """`disabled = false` is the reset at the top of a refresh, not a gate."""
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _refresh() -> void:\n\t_continue_button.disabled = false\n",
        )
        self.assert_clean(self.fixture.run())

    def test_cast_receiver_resolves_to_the_underlying_name(self) -> None:
        """`(control as OptionButton).disabled` is gating `control`."""
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _apply() -> void:\n\t(control as OptionButton).disabled = mandated\n",
        )
        self.assert_flags(self.fixture.run(), "scripts/ui/Probe.gd:2")
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _apply() -> void:\n"
            "\t(control as OptionButton).disabled = mandated\n"
            "\tcontrol.tooltip_text = _mandate_reason()\n",
        )
        self.assert_clean(self.fixture.run())

    def test_carrier_match_respects_name_boundaries(self) -> None:
        """A tooltip on `group` must not satisfy a gate on `up`."""
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _row() -> void:\n"
            "\tup.disabled = position <= 0\n"
            '\tgroup.tooltip_text = "unrelated"\n',
        )
        self.assert_flags(self.fixture.run(), "scripts/ui/Probe.gd:2")

    def test_allow_marker_waives_on_either_line(self) -> None:
        for body in (
            "func _row() -> void:\n"
            "\tup.disabled = position <= 0  # availability-allow: end of travel\n",
            "func _row() -> void:\n"
            "\t# availability-allow: end of travel\n"
            "\tup.disabled = position <= 0\n",
        ):
            with self.subTest(body=body):
                self.fixture.write("scripts/ui/Probe.gd", body)
                self.assert_clean(self.fixture.run())

    def test_todo_marker_defers_and_is_reported(self) -> None:
        """A deferred gate passes, but is printed every run so it cannot go quiet."""
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _row() -> void:\n"
            "\t# availability-todo: SOME-ROW-2026-08-21 — no packages installed\n"
            "\t_export_button.disabled = _summaries.is_empty()\n",
        )
        result = self.fixture.run()
        self.assert_clean(result)
        self.assertIn("1 gate(s) still owe a reason", result.stdout)
        self.assertIn("owed by SOME-ROW-2026-08-21", result.stdout)

    def test_marker_on_an_unrelated_preceding_line_does_not_waive(self) -> None:
        """Only a comment line directly above counts, not the nearest comment."""
        self.fixture.write(
            "scripts/ui/Probe.gd",
            "func _row() -> void:\n"
            "\t# availability-allow: end of travel\n"
            "\tup.disabled = position <= 0\n"
            "\tdown.disabled = position >= last\n",
        )
        self.assert_flags(self.fixture.run(), "down")

    def test_suites_are_not_scanned(self) -> None:
        """Tests disable buttons to build the very states this check is about."""
        self.fixture.write(
            "scripts/tests/test_probe.gd",
            "func test_gate() -> void:\n\tbutton.disabled = true\n",
        )
        self.assert_clean(self.fixture.run())

    def test_scene_disabled_node_needs_a_tooltip(self) -> None:
        """The scene file must not become the way around the script rule."""
        node = '[node name="Continue" type="Button" parent="."]\ndisabled = true\n'
        self.fixture.write("scenes/ui/Probe.tscn", '[gd_scene format=3]\n\n' + node)
        self.assert_flags(self.fixture.run(), "scenes/ui/Probe.tscn")
        self.fixture.write(
            "scenes/ui/Probe.tscn",
            '[gd_scene format=3]\n\n' + node + 'tooltip_text = "No saves yet."\n',
        )
        self.assert_clean(self.fixture.run())

    def test_scene_tooltip_on_a_different_node_does_not_count(self) -> None:
        self.fixture.write(
            "scenes/ui/Probe.tscn",
            "[gd_scene format=3]\n\n"
            '[node name="Other" type="Button" parent="."]\n'
            'tooltip_text = "Explained."\n\n'
            '[node name="Continue" type="Button" parent="."]\n'
            "disabled = true\n",
        )
        self.assert_flags(self.fixture.run(), "scenes/ui/Probe.tscn")


if __name__ == "__main__":
    unittest.main()
