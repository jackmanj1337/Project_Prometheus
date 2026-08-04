---
Type: plan
Status: In progress
Last verified: 2026-08-04
Tracker: FIX-SESSION-CLAIM-MODEL-CONTRADICTION-2026-08-04
---

# Next-session handoff — the session-claim model contradicts itself

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md),
with cross-branch state in `coordination/tasks.json` under
`FIX-SESSION-CLAIM-MODEL-CONTRADICTION-2026-08-04`.

Hit while landing the terrain-variants build on 2026-08-04. The work shipped, but
only because the contradiction was worked around by hand twice. It will be hit
again by the next feature branch, so it is written down rather than re-derived.

## The symptom

`scripts/agent-claim.sh` succeeded — it wrote an ownership note to
`agent/staging-area` and reported `session-claims: PASS (claims=agent/staging-area)`.
Then `scripts/agent-push.sh` on the feature branch failed on the **same commit**:

```
session-claims: FAIL
  422e4c1127cd… 'Split terrain art identity…' is claimed 0 time(s)
```

Two tools, one commit, opposite verdicts, neither wrong about its own model.

## The cause: the fix exists, on a branch the feature base cannot see

Three artifacts disagree about where a claim lives.

1. **The canonical model — BUILT, on `agent/staging-area`.** Commit `de037e1f`
   ("Read session claims from canonical docs branch", Codex CLI) rewrites
   `scripts/ci/check_session_commit_claims.py` to read claims from
   `refs/remotes/origin/agent/staging-area` (overridable via `SESSION_CLAIMS_BRANCH` /
   `SESSION_CLAIMS_REF`) instead of globbing the local worktree. It ships a test
   suite, `scripts/ci/test_check_session_commit_claims.py`. `agent-claim.sh` is its
   companion writer. Verified merged:
   `git merge-base --is-ancestor de037e1f origin/agent/staging-area` → true.

2. **The old model — still what every feature branch runs.** The same check on
   `agent/integration` globs `ROOT / "AGENT/Session Notes"`, i.e. the local
   worktree. Verified:
   `git merge-base --is-ancestor de037e1f origin/agent/integration` → **false**.

3. **`scripts/hooks/pre-commit`'s docs-guard comment — now stale on both lines.**
   It justifies not fencing session notes in the old model's terms:

   > Deliberately NARROW: session notes, design/decisions, playtests, GDD, etc. are
   > NOT fenced — session notes especially are authored with their feature work and
   > check_session_commit_claims.py binds them to this branch's commits.

   Under the canonical model the check binds them to the *docs line*, not to this
   branch. The fence decision may still be right; its stated reason is not.

**Why the gap persists, and why it is structural rather than an oversight.** The
claims check is infrastructure, so per `AGENTS.md` it correctly went **direct to
`agent/staging-area`**, bypassing the release line. But feature branches are cut
from `agent/integration`, and staging only ever flows back to `main` — never into
integration. So an infrastructure fix to a hook that *feature branches execute*
lands somewhere those branches can never reach. This will recur for any future
hook or CI change, not just this one.

## What was done by hand on 2026-08-04 (do not re-derive)

- The terrain commit `422e4c1127cd` was claimed by a session note **on its own
  feature branch** (old model), which is what let the push through.
- The `agent-claim.sh` note on `agent/staging-area` was **deleted** (commit
  `324291b9`), because leaving both would make that commit claimed twice once the
  feature note reaches staging through the release line, and the check rejects a
  commit claimed more than once.
- That deletion is correct under **both** models — but its commit message states
  the *old* model's rationale. If the canonical model wins, reword or supersede it
  rather than treating it as precedent.

## The decision to make

Pick one; do not leave both live.

- **(a) Bring the canonical check to `agent/integration`.** Cherry-pick or merge
  `de037e1f` (plus its test) onto integration so feature branches run the same
  check `agent-claim.sh` satisfies. Cheapest, and makes `agent-claim.sh` the
  single documented path. Note it makes a feature-branch push depend on a fetched
  `origin/agent/staging-area`, so confirm the pre-push hook fetches it — a stale
  remote-tracking ref would fail a correctly-claimed commit.
- **(b) Keep claims on feature branches** and retire `agent-claim.sh` for
  Project_Prometheus feature work, restricting it to docs-line-only commits.
  Then `de037e1f` needs reverting or narrowing on staging.

Whichever wins, **fix the `pre-commit` docs-guard comment in the same change**
(DoD#2 — a stated reason that no longer holds is exactly what rots), and state the
rule once in `AGENTS.md` so the next session does not have to infer it from two
disagreeing hooks.

## Also worth resolving while here

`scripts/agent-commit.sh` cannot stage a **deletion** — `git add -- <deleted path>`
exits 128, so removing the duplicate claim needed a hand-written trailered commit
in the docs worktree. Either teach it `git add -A -- <path>`, or document that
deletions take the manual path.

## Verification

- `git merge-base --is-ancestor de037e1f origin/agent/staging-area` → true
- `git merge-base --is-ancestor de037e1f origin/agent/integration` → false
- `scripts/ci/test_check_session_commit_claims.py` exists only on the staging side.
