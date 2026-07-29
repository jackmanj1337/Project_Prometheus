#!/usr/bin/env python3
"""Gate new multi-slice Implemented tracks on a requirement/evidence matrix."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTROL = ROOT / "AGENT/Docs/plans/project_control_plane_2026-06-29.md"
LEDGER = ROOT / "AGENT/Docs/governance/implemented_track_evidence.json"


def main() -> int:
	ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
	grandfathered = set(ledger["grandfathered_before_2026_07_15"])
	matrices = ledger["matrices"]
	errors: list[str] = []
	for line in CONTROL.read_text(encoding="utf-8").splitlines():
		if not line.startswith("| `"):
			continue
		cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
		if len(cells) != 12 or cells[2] != "Implemented" or not re.search(r"\b(?:slice|phase)s?\b", line, re.I):
			continue
		track = cells[0].strip("`")
		if track in grandfathered:
			continue
		matrix = matrices.get(track, "")
		if not matrix:
			errors.append(f"{track}: multi-slice Implemented track has no matrix ledger entry")
		elif not (ROOT / matrix).is_file():
			errors.append(f"{track}: matrix does not exist: {matrix}")
	if errors:
		print("evidence-matrices: FAIL")
		for error in errors:
			print(f"  {error}")
		return 1
	print("evidence-matrices: PASS")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
