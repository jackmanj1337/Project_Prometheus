---
Role: topic
---

# Branch Consolidation Inventory - 2026-07-16

## Scope and safety state

This inventory records the fetched Git state before consolidation. No protected
branch was changed, no remote branch was deleted, and no dirty worktree was
rebased, reset, or removed.

Fetched stable base: `origin/main` at
`c88ce987459ef9f3501fd2fe72408c339c74d723`.

## Preserved dirty work

| Source worktree | Recovery branch | Preserved tip | Remote state |
|---|---|---|---|
| stale `main` checkout | `agent/codex/2026-07-16/recover-stale-main-ai-scorer` | `7861e38078c473209f3d03b33b67a27a65a43a54` | pushed |
| encounter planning checkout | `agent/codex/2026-07-16/recover-encounter-planning` | `e24dcc75a589598f21da0b6611ed0f8f6fd5ab24` | local; push blocked because inherited history changes `.github/workflows/tests-pr.yml` |
| v0.4 release checkout | `agent/codex/2026-07-16/recover-v041-playtest` | `540d021ed44b4dc291346b80d015a489421d7066` | pushed |

The v0.3.2 checkout's `CLAUDE.md` modification and six tracked modifications in
the stale-main checkout are line-ending-only noise under an
`--ignore-space-at-eol` comparison. They remain byte-preserved in their original
worktrees and are not integration candidates.

The pre-existing stash is `acbc8e258d0924cebafabea3138cd4b85c47d64a`,
based on `26c6a16dd5a9659f18c69799d6e88017574181e8`. Its stable patch id is
`d20c98df015e45807eece87e6d89cba2c4fce713`; it contains only the same six
line-ending-only paths.

## Branch ancestry and final disposition

| Branch | Delta from fetched `origin/main` | Final disposition |
|---|---:|---|
| `agent/b4-encounter-model-slice2` | 53 commits ahead | Merged as the primary spine at `33d1c0c`; its 51-commit prep-save ancestor is fully included. |
| `agent/codex/2026-07-15/prep-save-followup` | 51 commits ahead | Superseded by the primary spine; locally marked for archival. |
| `agent/codex/2026-07-14/v0.4.0-windows-build` | 36 behind, 8 ahead | Relevant behavior was reimplemented on the split architecture at `15297c9`; release evidence was preserved at `ea03797`. The old line is superseded. |
| `agent/codex/2026-07-12/v0.3.2-build` | 92 behind, 4 ahead | Build/checklist evidence was preserved at `430ba3a`; two obsolete reverts were intentionally rejected. The old line is superseded. |
| `agent/GUI-testing` | 107 behind, 4 ahead | Relevant UI and research were ported at `430ba3a`, including ownership of `B8-TILE-RESCALE`. The old line is superseded. |

All formerly reported merged lines were reconfirmed as ancestors of fetched
`origin/main`: `agent/claude/2026-07-12/v0.4-prep`,
`agent/claude/2026-07-14/prep-deployment`,
`agent/codex/2026-07-13/band0-gdd-consolidation`,
`agent/codex/2026-07-14/v0.4.0-integration`,
`awakening-compatability-refactor`, `v0.3.0-features`, and the old local `main`.
Scorer planning was preserved on the integrated spine at `808103e`. The stale
scorer implementation was not imported because it lacks weapon enumeration,
exposure, target-value, open-term, mutation, and RNG diagnostics required by the
new architecture; it remains recoverable at pushed branch
`agent/codex/2026-07-16/recover-stale-main-ai-scorer`.

The durable coordination candidate is rooted at `3922b7b` on pushed branch
`agent/codex/2026-07-16/coordination-candidate`. It provides ownership and
release registries, lifecycle mutations, generated views, and automated stale,
duplicate, ref, evidence, and retirement checks. No remote ref was deleted.

## Local build identity

The executables remain local artifacts and are not committed as source history.

| Artifact | SHA-256 |
|---|---|
| `Project_Prometheus_v0.3.3_debug.exe` | `fd7b40b8b77ccb7db2cc218324b83cc4432545a87077dea160b3a94293d795ba` |
| `Project_Prometheus_v0.3.4_debug.exe` | `195c13cf6702d1336850c90a228fdeb4b9ca1e565e9ddf9021fe726d65290364` |
| `Project_Prometheus_v0.3.5_debug.exe` | `8e2adbb373c4348ac0b0287ae4f82d48d04cf4a781563097a3b40f661296e8ec` |
| `Project_Prometheus_v0.3.6_debug.exe` | `0695aaa733dc204e2398effa1cfb8705d7f46482aa3a842fc234bb67fad325c6` |
| `Project_Prometheus_v0.4.0_debug.exe` | `651bc28deca99724bef1a7a438350defc47fb6cdebd479050d4ad8140cc326a2` |

`build_info.json` identifies v0.4.0 source `d12eb33`, build time
`2026-07-14T07:01:49Z`, and has SHA-256
`fb42befeb494e69beddae3ebae65dadd57af342ee5a403b8d4e5c7dd0c7baeb9`.
The metadata and returned v0.4.0 evidence are preserved at `7861e38`; returned
v0.4.1 evidence is preserved at `540d021`.

## Separate repositories

`Project_Prometheus_Campaign_Pack_0` still has a deleted tracked README and
untracked downloaded art/archive content. `Project_Prometheus_Campaign_Pack_FE`
is clean. Both remain outside this consolidation goal; asset licensing and
attribution require a separate Work ID before any campaign-pack commit.

## Publication boundary

The complete integration result was published on
`agent/codex/2026-07-16/integration-candidate` and promoted to the agent-owned
`agent/integration` lifecycle ref. `agent/stable-release` retains the fetched
stable `main` tip, `agent/playtest-release` starts from the verified integration
candidate, and the orphan registry is published at `agent/coordination`. A local
Git bundle remains an independent transport. Review and live playtest remain
required before advancing the stable-release ref or retiring superseded remote
branches; agents do not advance `main`.
