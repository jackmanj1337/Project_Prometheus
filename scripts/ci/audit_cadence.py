#!/usr/bin/env python3
"""Report, but never gate on, elapsed time/work since the newest full audit."""

from __future__ import annotations

import subprocess
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def git(*args: str) -> str:
	return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def main() -> int:
	try:
		rollups = sorted((ROOT / "AGENT/Code Reviews").glob("full_review_rollup_*.md"))
		if not rollups:
			print("audit-cadence: no full review rollup found")
			return 0
		newest = rollups[-1]
		sha = git("log", "-1", "--format=%H", "--", str(newest.relative_to(ROOT)))
		committed = date.fromisoformat(git("show", "-s", "--format=%cs", sha))
		commits = int(git("rev-list", "--count", f"{sha}..HEAD"))
		days = (date.today() - committed).days
		print(
			f"audit-cadence: {days} day(s) and {commits} commit(s) "
			f"since {newest.name} ({sha[:12]})"
		)
	except (OSError, subprocess.CalledProcessError, ValueError) as exc:
		print(f"audit-cadence: unavailable ({exc})")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
