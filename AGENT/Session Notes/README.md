# Session Notes — RETIRED and FROZEN (2026-08-23)

**Do not add a file to this directory.** The session-note practice was retired on
2026-08-23 by `RETIRE-SESSION-NOTES-2026-08-23`, owner-ruled. What is here is a
**frozen evidence corpus**: 596 notes covering 2026-05-12 → 2026-08-22, kept because
121 of them are cited by live documents, tracker rows and GDScript comments. Read
them; do not update them. A dated record of what happened is wrong the moment it is
edited.

## Why it was retired

The practice had already lapsed before it was retired. The newest note here is
`2026-08-22-04-30-18Z-session-index-ordering.md`; the four sessions that followed
wrote no note at all, on any branch, and nothing was lost — they wrote into
`AGENT/WAITING_WORK.md`, tracker row `reference` fields, and the registers instead.
Retiring the practice ratified what was already true rather than changing it.

Every purpose a note served has a better-placed owner, and had one before this
change:

| What a note carried | Where it lives now |
|---|---|
| Commits made | `AGENT/Ledger/CLAIMS.tsv` — machine-read, one line per commit |
| Plans for next session | `AGENT/WAITING_WORK.md` + a tracker row's `trigger` / `order` / `dependencies` |
| What was done, and why | the tracker row's `reference` in `coordination/tasks.json` |
| Decisions and rulings | `AGENT/Docs/registers/` — 2,273 ruling-ID citations from 158 files |
| Design and build detail | `AGENT/Docs/plans/`, `AGENT/Docs/design/`, `AGENT/Code Reviews/` |

The third row was tested, not assumed: `SESSION-INDEX-ORDERING-2026-08-22`'s tracker
`reference` is a strict superset of its 141-line note, and additionally records the
cross-repo branch SHAs the note never carried.

## What was retired with it

- `scripts/ci/check_note_index.py` and its test — the index gate
- `AGENT/Docs/check_docs.py` check `[43]`, session-note filename enforcement
- `AGENT/Session Notes/TEMPLATE.md`
- the in-note prose-claim scan in `scripts/ci/check_session_commit_claims.py`
- the `check_note_index` calls in `scripts/hooks/pre-push` and `scripts/session_closeout.sh`
- container-side: `scripts/agent-session-note.py`, its integration test, and the
  `notes` subcommand of `tools/history_audit.py`

## The ledger is NOT retired

`CLAIMS.tsv` was never a session note — it is machine-read commit ownership, and it
is load-bearing at commit and push time. It moved **out** of this directory to
`AGENT/Ledger/CLAIMS.tsv` (with `COMMIT_CLAIMS_BASE`) so the two stop being
conflated. `scripts/ci/check_session_commit_claims.py` reads the old path too, so
branches cut before the move keep working; that fallback is deleted once no live
branch predates it.

## INDEX.md

`INDEX.md` stays as this corpus's navigation and is now frozen with it. It is no
longer verified by any check — there is nothing left to drift, because nothing is
added.

## What happens to these files next

They are input to the unified documentation system planned in
[`AGENT/Docs/plans/unified_documentation_system_plan_2026-08-23.md`](../Docs/plans/unified_documentation_system_plan_2026-08-23.md).
444 of the 596 notes are cited by nothing at all, transitively — they are candidates
for deletion, but **only after** the plan's anchor phase makes citation a resolvable
ID rather than a file path. Deleting them before that would break the 121 live
citations the same way the archive move silently broke nine GDScript comments.
