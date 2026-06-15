#!/usr/bin/env python3
"""check_scene_integrity.py — CI gate for scene wiring.

Every `@onready` `$`-path in a script that is attached to a scene must resolve
against that scene. This catches the silent node-rename / scene-reorg breakage
class the 2026-06-14 audit (Pillar 3) found by hand — none of which the GDScript
compiler or the unit suite necessarily flags.

Reuses the in-repo godot-analyzer (stdlib only; no pip dependency), so it runs the
same parsing the MCP tools and their tests already exercise.

Run from the repo root: python3 scripts/ci/check_scene_integrity.py
Exit 0 = every scene-attached @onready path resolves. Exit 1 = one or more MISS.
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools" / "godot-analyzer-mcp"))

from tools.script import validate_onready_paths  # noqa: E402  (needs sys.path first)


def main() -> int:
    failures: list[tuple[Path, str]] = []
    checked = 0
    for gd in sorted(ROOT.rglob("*.gd")):
        rel = gd.relative_to(ROOT)
        out = validate_onready_paths(str(gd), ROOT)
        # Skip scripts that are irrelevant to this check: not found, no @onready
        # declarations, or not attached to any scene (helpers, autoloads, resources).
        if out.startswith("Error:") or "No @onready" in out or "No scene found" in out:
            continue
        checked += 1
        if "MISS" in out:
            failures.append((rel, out))

    print(f"check_scene_integrity: validated @onready $-paths in {checked} "
          f"scene-attached script(s)")
    if failures:
        print(f"\nFAIL: {len(failures)} script(s) with unresolved @onready paths:")
        for rel, out in failures:
            print(f"\n--- {rel} ---\n{out}")
        return 1
    print("PASS: all @onready $-paths resolve against their scenes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
