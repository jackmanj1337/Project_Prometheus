# Session Notes — 2026-07-29 (AGENTS.md policy block sync)

## What was done

Regenerated the managed `[policy]` block in `AGENTS.md` from the container's
canonical `config/shared/policy.md` via `scripts/check-agents-sync.py --write`.

One paragraph changed. The block claimed `agent/coordination` was a live
lifecycle ref owning the active-work registry. Canonical policy retired that:
the workspace `coordination/tasks.json` owns the registry, and the Project-local
coordination branch is preserved only under `agent/archive/coordination-registry`.

No hand edits — the block is generated, so the fix is to regenerate it.

## Factual Git state

- Branch: `agent/from-staging-area/agents-policy-block-sync`
- Base: `agent/staging-area` at `1f2901be`
- HEAD: `911ed3e6149b48a52f80f0210d32a04d3680ad94`

## Commits

- `911ed3e6149b48a52f80f0210d32a04d3680ad94` — Sync the AGENTS.md policy block with the canonical source

## Checks

- Container `python3 -m pytest tests/` — **72 passed**, up from 71 passed /
  1 failed. `tests/test_agents_sync.py::test_live_workspace_is_in_sync` was the
  only failure and this clears it.
- `scripts/check-agents-sync.py` — all writable blocks in sync.
- `check_docs.py` and `check_gdscript_style.sh` green via the pre-commit hook.

## Decisions and context

The drift was **pre-existing and long-lived**, not introduced by the v0.5.8
promotion. Verified 2026-07-29: the stale text is present on `main`,
`agent/integration`, `agent/staging-area`, `agent/stable-release`, and
`agent/playtest-release-v0.5.8-fixes`, and the container test reproduces the
failure with the pre-merge release tip checked out. The promotion's `AGENTS.md`
conflict resolution touched a different part of the file.

Deliberately kept **off** `agent/staging-area` while
[PR #16](https://github.com/jackmanj1337/Project_Prometheus/pull/16) is open, so
the v0.5.8 release PR under review is not altered underneath the reviewer. This
is infrastructure and is not release-gated, so it can merge to
`agent/staging-area` at any time — before or after #16 — at the owner's
discretion.

Note the test that caught this asserts against the **live sibling checkout**, so
its result depends on which branch `repo/Project_Prometheus` happens to be on.
That makes it sensitive to workspace state rather than to repository content,
which is worth remembering when it flips unexpectedly.

## Next session

Fold this branch into `agent/staging-area` once #16 is merged, or sooner if the
owner prefers it in the same promotion. The remaining queued work is
`PP-INTEGRATION-RELEASE-RECONCILE`.
