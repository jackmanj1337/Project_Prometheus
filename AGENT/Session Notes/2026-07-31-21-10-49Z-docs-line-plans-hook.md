# Session Notes — 2026-07-31-21-10-49Z-docs-line-plans-hook (docs-line plans hook)

## What was done

Added a docs-line guard to `scripts/hooks/pre-commit` that refuses commits touching
`AGENT/Docs/plans/` on a code feature branch. Plans are allowed on the docs line
(`agent/integration`, `agent/staging-area`, `main`); a logged `DOCS_GUARD_OVERRIDE=1`
bypasses it for a legitimate exception. This is the Project_Prometheus counterpart to the
container repo's docs-guard hook (workspace `hooks/docs-guard.sh`), part of the
docs/tracker-store effort tracked as `DOCS-STORE-PROMETHEUS-HOOK-2026-07-31`.

## Factual Git state

- Branch: `agent/from-integration/docs-line-plans-hook`
- HEAD: `fb016213d847b7aefd64ceec1ea7346d96d8c0c7`
- Task merge base: `a8a558bc19cb9402804b2b369fa8355b4e3f802f`

## Commits

- `fb016213d847b7aefd64ceec1ea7346d96d8c0c7` — pre-commit: fence AGENT/Docs/plans off feature branches (docs-line guard)

## Checks

- No exact-HEAD receipts found

## Decisions and context

Scope was kept deliberately narrow: only `AGENT/Docs/plans/` is fenced. Session notes,
design, decisions, playtests, and the GDD are NOT fenced — session notes in particular are
authored alongside their feature work and `check_session_commit_claims.py` binds each note
to this branch's commits, so fencing them would break that workflow. Plans are the clearest
"strand-prone, meant to be visible immediately" category, matching AGENTS.md's stranding
warning. The fenced set is a one-line `case` pattern, easy to widen later if desired.

## Next session

Optional: widen the fenced set (design/decisions/registers) if the team wants more of
AGENT/Docs on the docs line. Route this branch through the normal agent/integration review.
