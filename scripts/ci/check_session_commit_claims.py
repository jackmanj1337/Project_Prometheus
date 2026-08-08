#!/usr/bin/env python3
"""Require each substantive post-bootstrap commit to be claimed in the commit ledger.

WHY A LEDGER RATHER THAN THE SESSION NOTES THEMSELVES
-----------------------------------------------------
Ownership and narrative are two artifacts with two churn rates, and fusing them is
what produced the model contradiction this file used to embody:

  * Ownership is per COMMIT and purely mechanical -- one line, machine-read.
  * A session note is per SESSION and written for humans -- what was done and why.

When claims lived inside the notes, centralizing ownership forced one stub note file
(plus an index row, plus a push) per commit onto the docs branch. 511 note files for
453 commits is the measured result: an archive that had become a commit log with
extra steps. Splitting them lets each sit at its own rate -- the ledger grows a line
per commit, the notes grow a file per session.

WHERE CLAIMS ARE READ FROM
--------------------------
The union of two sources:

  1. The ledger in the WORKING TREE. A branch cut from the docs line inherits the
     file, so this is already a superset of canonical history at branch point, and
     it is where this session's new claims land.
  2. The ledger on the canonical docs line, when that remote-tracking ref happens to
     be present. This catches claims that reached the docs line after you branched.

Source 2 is deliberately OPTIONAL. An earlier revision read the canonical ref
*exclusively*, which made every check depend on a freshly fetched remote-tracking
ref -- a stale ref failed a correctly-claimed commit, and only the scripted push
path fetched it. Because the ledger is a real file that travels with the branch,
the working tree alone is sufficient to validate a branch's own commits, so a
missing canonical ref is reported and skipped rather than failed.

`--fix` appends the unclaimed commits to the ledger. The check already computes
exactly which commits are unclaimed, in exactly the line format a claim takes;
refusing to write them made every push a commit -> rejected-push -> edit -> amend
loop, once per commit in a long session.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NOTES_PATH = "AGENT/Session Notes"
BASE_FILE = ROOT / NOTES_PATH / "COMMIT_CLAIMS_BASE"
LEDGER_PATH = f"{NOTES_PATH}/CLAIMS.tsv"
LEDGER = ROOT / LEDGER_PATH

# The docs line: where narrative notes, plans, and this ledger converge. It is the
# FEATURE BASE, not the staging branch -- feature branches are cut from it and merge
# back into it, so docs land there with no extra publishing step, and it is measurably
# the fullest store (it carried 511 notes and 95 plans to staging's 430 and 77).
CANONICAL_BRANCH = os.environ.get("SESSION_CLAIMS_BRANCH", "agent/integration")
CANONICAL_REF = os.environ.get(
	"SESSION_CLAIMS_REF", f"refs/remotes/origin/{CANONICAL_BRANCH}"
)

LEDGER_HEADER = (
	"# Commit ownership ledger -- one line per substantive commit: <sha><TAB><subject>\n"
	"# Sorted by SHA so concurrent branches append to different regions and git\n"
	"# auto-merges them; appending at the tail would conflict on every merge.\n"
	"# Machine-maintained: add entries with\n"
	"#   python3 scripts/ci/check_session_commit_claims.py --fix\n"
)
# A note's prose claim line, still matched so the retired in-note model cannot quietly
# come back: a claim written only in a note is invisible to this check.
NOTE_CLAIM_RE = re.compile(r"^- `([0-9a-f]{40})` — (.+)$", re.MULTILINE)


def git(*args: str) -> str:
	return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def ref_exists(ref: str) -> bool:
	return subprocess.run(
		["git", "show-ref", "--verify", "--quiet", ref], cwd=ROOT, check=False
	).returncode == 0


def note_only_commit(sha: str) -> bool:
	"""A commit that touches nothing but session notes claims itself by existing."""
	paths = git("diff-tree", "--no-commit-id", "--name-only", "-r", sha).splitlines()
	return bool(paths) and all(
		path in (f"{NOTES_PATH}/INDEX.md", LEDGER_PATH)
		or (path.startswith(f"{NOTES_PATH}/") and path.endswith(".md"))
		for path in paths
	)


def parse_ledger(text: str, origin: str) -> dict[str, list[tuple[str, str]]]:
	"""Parse ledger text into {sha: [(origin, subject), ...]}."""
	claims: dict[str, list[tuple[str, str]]] = {}
	for line in text.splitlines():
		if not line.strip() or line.lstrip().startswith("#"):
			continue
		sha, _, subject = line.partition("\t")
		sha, subject = sha.strip(), subject.strip()
		if len(sha) == 40 and subject:
			claims.setdefault(sha, []).append((origin, subject))
	return claims


def collect_claims() -> tuple[dict[str, list[tuple[str, str]]], list[str]]:
	"""Working-tree ledger, unioned with the canonical one when its ref is present.

	Identical (sha, subject) pairs from both sources collapse to ONE claim -- that is
	the same claim seen twice, not a double-claim. Only two DIFFERENT subjects for one
	sha is a real disagreement, and that still fails.
	"""
	notes: list[str] = []
	claims: dict[str, list[tuple[str, str]]] = {}
	if LEDGER.exists():
		claims = parse_ledger(LEDGER.read_text(encoding="utf-8"), LEDGER_PATH)
	else:
		notes.append(f"no working-tree ledger at {LEDGER_PATH}")

	if ref_exists(CANONICAL_REF):
		# Probe first: git writes a bare "fatal:" to stderr for a missing path, which
		# reads like a crash in hook output when it only means "not migrated yet".
		read = subprocess.run(
			["git", "show", f"{CANONICAL_REF}:{LEDGER_PATH}"], cwd=ROOT, text=True,
			stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False,
		)
		if read.returncode != 0:
			notes.append(f"{CANONICAL_BRANCH} carries no ledger yet")
		else:
			canonical = read.stdout
			source = f"{CANONICAL_REF}:{LEDGER_PATH}"
			for sha, owners in parse_ledger(canonical, source).items():
				known = {subject for _, subject in claims.get(sha, [])}
				for origin, subject in owners:
					if subject not in known:
						claims.setdefault(sha, []).append((origin, subject))
	else:
		# Not fatal: the working-tree ledger travelled with this branch and already
		# covers its own commits. See the module docstring.
		notes.append(f"canonical ref absent, using working tree only ({CANONICAL_REF})")
	return claims, notes


def note_claims() -> dict[str, str]:
	"""Claims still written in note prose, so the retired model is caught, not ignored."""
	found: dict[str, str] = {}
	notes_dir = ROOT / NOTES_PATH
	if not notes_dir.is_dir():
		return found
	for path in notes_dir.glob("*.md"):
		if path.name == "TEMPLATE.md":
			continue  # its claim line is a placeholder shape, not a real claim
		for sha, subject in NOTE_CLAIM_RE.findall(path.read_text(encoding="utf-8")):
			found.setdefault(sha, subject)
	return found


def audited_commits() -> list[str]:
	base = BASE_FILE.read_text(encoding="utf-8").strip()
	return git("rev-list", "--reverse", "--no-merges", f"{base}..HEAD").splitlines()


def write_ledger(claims: dict[str, str]) -> None:
	"""Rewrite the ledger, SHA-sorted. Sorting is what keeps merges automatic."""
	body = "".join(f"{sha}\t{subject}\n" for sha, subject in sorted(claims.items()))
	LEDGER.parent.mkdir(parents=True, exist_ok=True)
	LEDGER.write_text(LEDGER_HEADER + body, encoding="utf-8")


def fix_unclaimed() -> int:
	"""Add missing claims. Only ADDS what git reports on the branch; it never rewrites
	or removes an existing claim, so a wrong-subject claim still has to be corrected by
	hand -- that is a disagreement, not an omission."""
	existing: dict[str, str] = {}
	if LEDGER.exists():
		for sha, owners in parse_ledger(
			LEDGER.read_text(encoding="utf-8"), LEDGER_PATH
		).items():
			existing[sha] = owners[0][1]
	missing = [
		(sha, git("show", "-s", "--format=%s", sha))
		for sha in audited_commits()
		if sha not in existing and not note_only_commit(sha)
	]
	if not missing:
		print("session-claims: nothing to fix")
		return 0
	existing.update(dict(missing))
	write_ledger(existing)
	print(f"session-claims: added {len(missing)} claim(s) to {LEDGER_PATH}")
	for sha, subject in missing:
		print(f"  {sha[:12]} {subject}")
	return 0


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--fix", action="store_true",
		help="append unclaimed commits to the ledger, then re-check",
	)
	args = parser.parse_args()
	if args.fix and fix_unclaimed() != 0:
		return 1

	commits = audited_commits()
	claims, notes = collect_claims()

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

	# The retired in-note model: a claim line in a note that the ledger does not carry
	# would silently count for nothing, which is exactly how the two models diverged.
	audited = set(commits)
	stranded = sorted(
		sha for sha in note_claims() if sha not in claims and sha in audited
	)
	for sha in stranded:
		errors.append(
			f"{sha} is claimed in a session note but not in {LEDGER_PATH} "
			f"(the ledger is authoritative; run --fix)"
		)

	for note in notes:
		print(f"session-claims: note: {note}")
	if errors:
		print("session-claims: FAIL")
		for error in errors:
			print(f"  {error}")
		return 1
	print(
		f"session-claims: PASS ({len(commits)} post-bootstrap commit(s) audited; "
		f"ledger={LEDGER_PATH})"
	)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
