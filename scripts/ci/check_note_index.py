#!/usr/bin/env python3
"""Fail when the session-note index no longer matches the notes on disk.

WHY THIS EXISTS. `AGENT/Session Notes/INDEX.md` is the navigation layer over 580+
notes, and nothing verified it. The workspace audit
(`<container>/tools/history_audit.py notes`) has always MEASURED it -- dead links,
orphaned notes, duplicate rows, reverse-chronological order -- but it only ever
printed a report, and that report had never been green, so nobody could tell a new
breakage from the standing one. SESSION-INDEX-ORDERING-2026-08-22 fixed the sort key
and sorted the index; `consistent` is now true, which is what makes gating on it
possible for the first time.

WHY IT LIVES HERE AND REACHES OUT. The notes are this repo's, but the audit and its
ordering key are the container repo's, one level above the workspace `repo/`
directory. Copying the key here would put two implementations of the same ordering
rule in two repos that are merged on different lines -- the exact drift that made
`agent-claim.sh` and `agent-push.sh` return opposite verdicts on one commit. So this
reads the container's implementation rather than restating it.

THE TRADEOFF, STATED PLAINLY. This repo's CI checks out only this repo, so the
container is not there and this SKIPS on every CI run. It binds at pre-push, in a
developer workspace, which is the one place both sides are visible -- the same
reasoning and the same binding point as `check_pack_freshness.sh`. A skip is loud
for that reason: silence here would read as coverage that does not exist.

Usage: python3 scripts/ci/check_note_index.py
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
# <container>/repo/Project_Prometheus -> <container>
AUDIT = ROOT.parent.parent / "tools" / "history_audit.py"


def main() -> int:
	if not AUDIT.is_file():
		# LOUD, and deliberately not fatal -- see the module docstring.
		print(f"check_note_index: SKIPPED -- no workspace audit at {AUDIT}", file=sys.stderr)
		print("  Session-note index consistency is NOT verified in this environment.", file=sys.stderr)
		print("  It is checked on pre-push in a workspace that has the container repo.", file=sys.stderr)
		return 0
	try:
		result = subprocess.run(
			[sys.executable, str(AUDIT), "--repo", str(ROOT), "--format", "json", "notes"],
			text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
		)
	except OSError as exc:
		print(f"check_note_index: SKIPPED -- audit not runnable ({exc})", file=sys.stderr)
		return 0
	# An ABSENT tool is an environment fact and skips above. A tool that is present
	# and then fails is a BUG -- a bad invocation, a moved flag, a crash -- and must
	# not wear the same silent-skip clothes. Treating the two alike is how this very
	# check passed green while calling the audit with arguments it rejected.
	if result.returncode != 0:
		print("check_note_index: FAIL -- the workspace audit is present but errored", file=sys.stderr)
		print((result.stderr.strip() or "(no stderr)"), file=sys.stderr)
		return 1
	try:
		report = json.loads(result.stdout)["report"]
	except (ValueError, KeyError) as exc:
		print(f"check_note_index: FAIL -- unreadable audit output ({exc})", file=sys.stderr)
		return 1

	if report.get("consistent"):
		print(
			f"check_note_index: PASS -- {report['note_count']} note(s) indexed, "
			"no dead/orphan/duplicate links, order clean"
		)
		return 0

	print("check_note_index: FAIL -- AGENT/Session Notes/INDEX.md does not match the notes", file=sys.stderr)
	for label, key in (
		("dead link (indexed, no such note)", "dead_links"),
		("orphan note (on disk, not indexed)", "orphan_notes"),
		("duplicate index row", "duplicate_links"),
	):
		for name in report.get(key) or []:
			print(f"  {label}: {name}", file=sys.stderr)

	errors = report.get("ordering_errors") or []
	if errors:
		# ordering_errors is POSITIONAL: one displaced row reports an error at every
		# position below it, so its length is not a count of misplaced rows. Naming
		# the first one is what actually helps -- it is usually the whole defect.
		first = errors[0]
		print(
			f"  out of order at index row {first['position']}: {first['actual']}\n"
			f"    expected there: {first['expected']}",
			file=sys.stderr,
		)
		if len(errors) > 1:
			print(
				f"  ...and {len(errors) - 1} further position(s). That number CASCADES from"
				" the rows above it; fixing the first often clears most of them.",
				file=sys.stderr,
			)
	print("  Fix: add the missing row, or move the row named above, in AGENT/Session Notes/INDEX.md", file=sys.stderr)
	return 1


if __name__ == "__main__":
	raise SystemExit(main())
