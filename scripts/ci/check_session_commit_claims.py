#!/usr/bin/env python3
"""Require each substantive post-bootstrap commit to be claimed by one session note.

`--fix` appends the unclaimed commits to the newest session note. The check already
computes exactly which commits are unclaimed and in exactly the line format a claim
takes; refusing to write them made every push a commit → rejected-push → edit-note →
amend loop, repeated once per commit in a long session. Claims stay auditable because
the check still runs afterwards, and because --fix only ever appends what git already
says is on the branch.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE_FILE = ROOT / "AGENT/Session Notes/COMMIT_CLAIMS_BASE"
NOTES = ROOT / "AGENT/Session Notes"
CLAIM_RE = re.compile(r"^- `([0-9a-f]{40})` — (.+)$", re.MULTILINE)
CLAIMS_HEADING = "## Commits claimed"


def git(*args: str) -> str:
	return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def note_only_commit(sha: str) -> bool:
	paths = git("diff-tree", "--no-commit-id", "--name-only", "-r", sha).splitlines()
	return bool(paths) and all(
		path == "AGENT/Session Notes/INDEX.md"
		or (path.startswith("AGENT/Session Notes/") and path.endswith(".md"))
		for path in paths
	)


def fix_unclaimed() -> int:
	"""Write the missing claims. Only ADDS lines for commits git reports on the branch;
	it never rewrites or removes an existing claim, so a wrong-subject claim still has
	to be corrected by hand — that is a disagreement, not an omission."""
	base = BASE_FILE.read_text(encoding="utf-8").strip()
	commits = git("rev-list", "--reverse", "--no-merges", f"{base}..HEAD").splitlines()
	claimed = {
		sha
		for path in NOTES.glob("*.md")
		for sha, _ in CLAIM_RE.findall(path.read_text(encoding="utf-8"))
	}
	missing = [
		(sha, git("show", "-s", "--format=%s", sha))
		for sha in commits
		if sha not in claimed and not note_only_commit(sha)
	]
	if not missing:
		print("session-claims: nothing to fix")
		return 0
	note = newest_note()
	if note is None:
		print("session-claims: no session note to append to", file=sys.stderr)
		return 1
	append_claims(note, missing)
	print(f"session-claims: added {len(missing)} claim(s) to {note.name}")
	for sha, subject in missing:
		print(f"  {sha[:12]} {subject}")
	return 0


def newest_note() -> Path | None:
	"""The session note this session is writing: newest by name, which is a UTC stamp."""
	notes = sorted(p for p in NOTES.glob("*.md") if p.name[:4].isdigit())
	return notes[-1] if notes else None


def append_claims(note: Path, claims: list[tuple[str, str]]) -> None:
	"""Insert claim lines under the note's claims heading, preserving section order."""
	text = note.read_text(encoding="utf-8")
	lines = [f"- `{sha}` — {subject}" for sha, subject in claims]
	if CLAIMS_HEADING in text:
		head, _, tail = text.partition(CLAIMS_HEADING)
		# Append at the end of the existing claim list: the next heading, or the end.
		body, next_heading, rest = tail.partition("\n## ")
		body = body.rstrip("\n") + "\n" + "\n".join(lines) + "\n"
		text = head + CLAIMS_HEADING + body + next_heading + rest
	else:
		text = text.rstrip("\n") + f"\n\n{CLAIMS_HEADING}\n\n" + "\n".join(lines) + "\n"
	note.write_text(text, encoding="utf-8")


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--fix", action="store_true",
		help="append unclaimed commits to the newest session note, then re-check",
	)
	args = parser.parse_args()
	if args.fix and fix_unclaimed() != 0:
		return 1
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
