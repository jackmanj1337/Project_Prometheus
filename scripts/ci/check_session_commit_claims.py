#!/usr/bin/env python3
"""Require substantive commits to be claimed on the canonical docs line."""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE_FILE = ROOT / "AGENT/Session Notes/COMMIT_CLAIMS_BASE"
NOTES_PATH = "AGENT/Session Notes"
CANONICAL_BRANCH = os.environ.get("SESSION_CLAIMS_BRANCH", "agent/staging-area")
CANONICAL_REF = os.environ.get(
	"SESSION_CLAIMS_REF", f"refs/remotes/origin/{CANONICAL_BRANCH}"
)
CLAIM_RE = re.compile(r"^- `([0-9a-f]{40})` — (.+)$", re.MULTILINE)


def git(*args: str, check: bool = True) -> str:
	result = subprocess.run(
		["git", *args], cwd=ROOT, text=True, stdout=subprocess.PIPE,
		stderr=subprocess.PIPE, check=False,
	)
	if check and result.returncode != 0:
		raise RuntimeError(result.stderr.strip() or "git command failed")
	return result.stdout.strip()


def note_only_commit(sha: str) -> bool:
	paths = git("diff-tree", "--no-commit-id", "--name-only", "-r", sha).splitlines()
	return bool(paths) and all(
		path == f"{NOTES_PATH}/INDEX.md"
		or (path.startswith(f"{NOTES_PATH}/") and path.endswith(".md"))
		for path in paths
	)


def _working_tree_claims() -> dict[str, list[tuple[str, str]]]:
	claims: dict[str, list[tuple[str, str]]] = {}
	for path in (ROOT / NOTES_PATH).glob("*.md"):
		for sha, subject in CLAIM_RE.findall(path.read_text(encoding="utf-8")):
			claims.setdefault(sha, []).append((str(path.relative_to(ROOT)), subject))
	return claims


def _tree_claims(ref: str) -> dict[str, list[tuple[str, str]]]:
	if subprocess.run(
		["git", "show-ref", "--verify", "--quiet", ref], cwd=ROOT, check=False
	).returncode != 0:
		raise RuntimeError(
			f"canonical claims ref is missing: {ref}\n"
			f"  Fetch {CANONICAL_BRANCH} before checking or pushing."
		)
	paths = git("ls-tree", "-r", "--name-only", ref, "--", NOTES_PATH).splitlines()
	claims: dict[str, list[tuple[str, str]]] = {}
	for path in paths:
		if not path.endswith(".md"):
			continue
		text = git("show", f"{ref}:{path}")
		for sha, subject in CLAIM_RE.findall(text):
			claims.setdefault(sha, []).append((f"{ref}:{path}", subject))
	return claims


def _claims() -> dict[str, list[tuple[str, str]]]:
	branch = git("branch", "--show-current")
	# A note being committed to the docs line is not in HEAD yet, so its pre-commit
	# check must read the staged/working file. Feature branches are intentionally
	# denied that escape hatch and read only the canonical Git ref.
	if branch == CANONICAL_BRANCH:
		return _working_tree_claims()
	return _tree_claims(CANONICAL_REF)


def main() -> int:
	base = BASE_FILE.read_text(encoding="utf-8").strip()
	commits = git("rev-list", "--reverse", "--no-merges", f"{base}..HEAD").splitlines()
	try:
		claims = _claims()
	except RuntimeError as exc:
		print(f"session-claims: FAIL\n  {exc}")
		return 1

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
				f"{owners[0][0]} claims {sha} with subject {owners[0][1]!r}; "
				f"git has {subject!r}"
			)
	for sha, owners in claims.items():
		if len(owners) > 1 and sha in commits:
			errors.append(f"{sha} is duplicated in: {', '.join(path for path, _ in owners)}")

	if errors:
		print("session-claims: FAIL")
		for error in errors:
			print(f"  {error}")
		return 1
	print(
		f"session-claims: PASS ({len(commits)} post-bootstrap commit(s) audited; "
		f"claims={CANONICAL_BRANCH})"
	)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
