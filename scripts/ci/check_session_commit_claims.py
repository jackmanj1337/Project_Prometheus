#!/usr/bin/env python3
"""Require each substantive post-bootstrap commit to be claimed by one session note."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE_FILE = ROOT / "AGENT/Session Notes/COMMIT_CLAIMS_BASE"
NOTES = ROOT / "AGENT/Session Notes"
CLAIM_RE = re.compile(r"^- `([0-9a-f]{40})` — (.+)$", re.MULTILINE)


def git(*args: str) -> str:
	return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def note_only_commit(sha: str) -> bool:
	paths = git("diff-tree", "--no-commit-id", "--name-only", "-r", sha).splitlines()
	return bool(paths) and all(
		path == "AGENT/Session Notes/INDEX.md"
		or (path.startswith("AGENT/Session Notes/") and path.endswith(".md"))
		for path in paths
	)


def main() -> int:
	base = BASE_FILE.read_text(encoding="utf-8").strip()
	commits = git("rev-list", "--reverse", "--no-merges", f"{base}..HEAD").splitlines()
	claims: dict[str, list[tuple[Path, str]]] = {}
	for path in NOTES.glob("*.md"):
		for sha, subject in CLAIM_RE.findall(path.read_text(encoding="utf-8")):
			claims.setdefault(sha, []).append((path, subject))

	errors: list[str] = []
	for sha in commits:
		if note_only_commit(sha):
			continue
		subject = git("show", "-s", "--format=%s", sha)
		owners = claims.get(sha, [])
		if len(owners) != 1:
			errors.append(f"{sha} {subject!r} is claimed {len(owners)} time(s)")
		elif owners[0][1] != subject:
			errors.append(
				f"{owners[0][0].relative_to(ROOT)} claims {sha} with subject "
				f"{owners[0][1]!r}; git has {subject!r}"
			)
	for sha, owners in claims.items():
		if len(owners) > 1 and sha in commits:
			errors.append(f"{sha} is duplicated in: {', '.join(str(p.relative_to(ROOT)) for p, _ in owners)}")

	if errors:
		print("session-claims: FAIL")
		for error in errors:
			print(f"  {error}")
		return 1
	print(f"session-claims: PASS ({len(commits)} post-bootstrap commit(s) audited)")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
