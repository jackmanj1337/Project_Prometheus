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


def stranded_commits(pushed: str, base_ref: str) -> list[tuple[str, str]]:
	"""Commits in `pushed` that touch executed infrastructure and are absent from base."""
	out = git(
		"rev-list", f"{base_ref}..{pushed}", "--no-merges",
		"--", *EXECUTED_PREFIXES,
	)
	shas = [line for line in out.splitlines() if line]
	return [(sha, git("show", "-s", "--format=%s", sha)) for sha in shas]


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

	stranded = stranded_commits(args.pushed, args.base)
	if not stranded:
		print(f"infra-sync: PASS (executed infrastructure is present on {FEATURE_BASE})")
		return 0

	print("infra-sync: FAIL")
	print(
		f"  These commits change code that feature branches EXECUTE, and are on\n"
		f"  {STAGING_BRANCH} but not on {FEATURE_BASE}. Feature branches would keep\n"
		f"  running the old version, and the two would disagree:"
	)
	for sha, subject in stranded:
		print(f"    {sha[:12]} {subject}")
	print(
		f"\n  Infrastructure still goes direct to {STAGING_BRANCH} — that part is right.\n"
		f"  It just has to reach the feature base too. Merge it there as well:\n"
		f"    git switch {FEATURE_BASE} && git merge {STAGING_BRANCH}\n"
		f"  (or cherry-pick the commits above), push that, then re-push here."
	)
	return 1


if __name__ == "__main__":
	raise SystemExit(main())
