#!/usr/bin/env python3
"""Refuse to strand executed infrastructure on the staging line.

THE FAILURE THIS PREVENTS
-------------------------
Per AGENTS.md, infrastructure -- hooks, CI checks, policy -- correctly goes DIRECT to
`agent/staging-area`, bypassing the release line, because gating a safety mechanism
behind a game release delivers it late for no benefit. But feature branches are cut
from `agent/integration`, and staging only ever flows onward to `main` -- never back
into integration. So a change to a hook that FEATURE BRANCHES THEMSELVES EXECUTE lands
somewhere those branches can never reach.

That is not hypothetical. The canonical session-claim check (de037e1f) landed on
staging and rewrote how claims are validated. Feature branches kept running the old
one. For every commit thereafter, `agent-claim.sh` and `agent-push.sh` returned
opposite verdicts on the same commit, and the resolution had to be worked out by hand
twice before anyone wrote down why.

The direct-to-staging route is still right. What was missing is the second half: a
change to code that runs on other branches has to REACH those branches. This check is
that second half, and it is structural rather than advisory -- it fails the push that
would create the gap, naming the person who can still fix it cheaply.

SCOPE
-----
Only paths whose contents are EXECUTED by other branches. A doc or a plan on staging
strands harmlessly; a hook does not. Widen EXECUTED_PREFIXES if that set grows.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Code that a branch other than the one it landed on will actually run.
EXECUTED_PREFIXES = ("scripts/hooks/", "scripts/ci/")

STAGING_BRANCH = "agent/staging-area"
FEATURE_BASE = "agent/integration"


def git(*args: str) -> str:
	return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def ref_exists(ref: str) -> bool:
	# rev-parse, not `show-ref --verify`, which demands a full refname and would
	# silently SKIP the whole check when handed a short ref like origin/agent/x.
	return subprocess.run(
		["git", "rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"],
		cwd=ROOT, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
	).returncode == 0


def tracked_paths(ref: str) -> list[str]:
	out = git("ls-tree", "-r", "--name-only", ref, "--", *EXECUTED_PREFIXES)
	return [line for line in out.splitlines() if line]


def blob_at(ref: str, path: str) -> str | None:
	result = subprocess.run(
		["git", "rev-parse", "--verify", "--quiet", f"{ref}:{path}"],
		cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
		check=False,
	)
	return result.stdout.strip() or None


def blobs_in_history(base_ref: str, path: str) -> set[str]:
	"""Every version of `path` the base branch has ever held.

	Needed because the base legitimately moves AHEAD. If staging carries version 3 of
	a hook and the base is already on version 4, the base has plainly seen version 3 --
	that is not a gap. Only content the base has never held at any point is stranded.
	"""
	commits = git("log", "--format=%H", base_ref, "--", path).splitlines()
	blobs = {blob for sha in commits if (blob := blob_at(sha, path))}
	return blobs


def stranded_paths(pushed: str, base_ref: str) -> list[tuple[str, str]]:
	"""Executed-infrastructure files whose pushed content the base has never held.

	Compares CONTENT, not commit identity. An earlier revision compared commits, and
	it was wrong for the workflow this check exists to encourage: the base is often
	many product commits ahead, so infrastructure cannot always be merged wholesale
	and gets carried across as a separate commit with identical content. That is a
	correctly-synced state, and a commit-identity check calls it a gap every time --
	which would train people to ignore the check, the opposite of the point.
	"""
	stranded: list[tuple[str, str]] = []
	for path in tracked_paths(pushed):
		pushed_blob = blob_at(pushed, path)
		if pushed_blob is None:
			continue
		if pushed_blob == blob_at(base_ref, path):
			continue  # identical at both tips -- the common case
		if pushed_blob in blobs_in_history(base_ref, path):
			continue  # the base held this version and has since moved on
		reason = (
			"the feature base has no such file"
			if blob_at(base_ref, path) is None
			else "the feature base has never held this content"
		)
		stranded.append((path, reason))
	return stranded


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--pushed", required=True,
		help="the commit being pushed to the staging branch",
	)
	parser.add_argument("--base", default=f"refs/remotes/origin/{FEATURE_BASE}")
	args = parser.parse_args()

	if not ref_exists(args.base):
		# Cannot judge without the feature base. Say so rather than passing silently:
		# a check that quietly no-ops is how the original gap survived unnoticed.
		print(
			f"infra-sync: SKIPPED — {args.base} is not present locally.\n"
			f"  Fetch {FEATURE_BASE} to let this check run.",
			file=sys.stderr,
		)
		return 0

	stranded = stranded_paths(args.pushed, args.base)
	if not stranded:
		print(f"infra-sync: PASS (executed infrastructure is present on {FEATURE_BASE})")
		return 0

	print("infra-sync: FAIL")
	print(
		f"  These files are code that feature branches EXECUTE, and the version on\n"
		f"  {STAGING_BRANCH} has never been on {FEATURE_BASE}. Feature branches would\n"
		f"  keep running a different version, and the two lines would disagree:"
	)
	for path, reason in stranded:
		print(f"    {path}  ({reason})")
	print(
		f"\n  Infrastructure still goes direct to {STAGING_BRANCH} — that part is right.\n"
		f"  It just has to reach the feature base too. Put the same content there:\n"
		f"    git switch {FEATURE_BASE} && git merge {STAGING_BRANCH}\n"
		f"  or, when the base is far ahead and cannot take a merge, carry the files\n"
		f"  across on a branch off {FEATURE_BASE}. Push that, then re-push here."
	)
	return 1


if __name__ == "__main__":
	raise SystemExit(main())
