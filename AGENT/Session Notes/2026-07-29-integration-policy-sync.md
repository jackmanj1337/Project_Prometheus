# Session Notes — 2026-07-29 (feature-base policy block sync)

## What was done

Applied the same managed-`[policy]`-block regeneration to `agent/integration`
that `agent/from-staging-area/agents-policy-block-sync` applied to the staging
line. Run with `scripts/check-agents-sync.py --write`; no hand edits.

The block claimed `agent/coordination` was a live lifecycle ref owning the
active-work registry. Canonical `config/shared/policy.md` retired that: the
workspace `coordination/tasks.json` owns the registry and the Project-local
coordination branch survives only as `agent/archive/coordination-registry`.

## Factual Git state

- Branch: `agent/from-integration/agents-policy-sync`
- Base: `agent/integration` at `6fa2a7ea`
- HEAD: `86a145c2cfd2df903c0366438b29f5f31c804b34`

## Commits

- `86a145c2cfd2df903c0366438b29f5f31c804b34` — Sync the AGENTS.md policy block on the feature base

## Checks

- `scripts/check-agents-sync.py` — all writable blocks in sync.
- `check_docs.py` and `check_gdscript_style.sh` green via the pre-commit hook.
- Docs-only change; the hook skipped the Godot suite.

## Decisions and context

**Why a second branch instead of waiting for the reconcile to carry it.** The
staging-line fix was cut from `agent/staging-area`, so on its own it corrects
`main` only. `agent/integration` is the branch every feature session actually
reads, and the reconcile that would otherwise carry the fix across
(`PP-INTEGRATION-RELEASE-RECONCILE`) completed earlier today — the next one could
be weeks out. Leaving the feature base pointing agents at a retired branch for
that long was the thing worth avoiding.

**Duplicating the change on two branches is safe here specifically because the
block is generated.** Both sides are byte-identical output from the same
canonical source, so when the two lines next merge the region either
auto-resolves or is regenerated; there is no hand-authored variant to reconcile.
That is also why the fix is a `--write` run and never an edit.

## Next session

Nothing pending from this note. The staging-line half is
[PR #17](https://github.com/jackmanj1337/Project_Prometheus/pull/17), awaiting a
human merge. Tracked by `PP-AGENTS-POLICY-BLOCK-SYNC-2026-07-29`.
