> **Historical** — superseded by the reconciled Slice 3A decision packet.

---
Type: plan
Status: Historical - superseded by the reconciled Slice 3A decision packet
Last verified: 2026-07-16
---

# AI Scorer Questions Handoff

## Purpose

After the v0.4.2 artifact is out for Windows validation, resume at
[`ai_valuation_engagement_open_questions_2026-06-27.md`](../registers/ai_valuation_engagement_open_questions_2026-06-27.md).
`VAL-1..13` are resolved owner decisions, not questions to reopen. The next job is
to reconcile those decisions with the older
[`band5_ai_implementation_plan_2026-07-03.md`](band5_ai_implementation_plan_2026-07-03.md)
and produce a dependency-correct first scorer slice.

## Current code baseline

- `AIProfileRegistry` and `AISpec` already replace the old closed profile switch.
- `basic`, `passive`, `healer`, and `hunter` resolve activation/disposition/
  engagement data; `nearest` and `weakest` targeting are implemented.
- Disposition handlers still plan and execute inline. The pure
  `plan_action(unit, board) -> PlannedAction` seam required by `VAL-10` is absent.
- `ProjectionService` has the Band 2 combat adapter, but the hypothetical
  `{from_tile, weapon}` forecast/outcome terms required by `VAL-6` are not built.
- The F16/REQ score-tree vocabulary and generalized Source+Style action palette
  assumed by the July 3 plan are not built.

## Locked answers to carry forward

1. Score whole legal actions `{move_tile, action, target, source/weapon}` (`VAL-1`).
2. The v1 leaf combines immediate forecast and post-move exposure (`VAL-2`).
3. Use one data-authored fixed-point score-tree path; `nearest` and `weakest`
   become presets of it, not a second selector (`VAL-5`, `VAL-9`).
4. Add the negamax/search-depth seam now, but ship depth 0; do not build the
   board forward model yet (`VAL-3`, `VAL-4`).
5. Delegate forecast features to the shared projection API and support
   hypothetical move tile/weapon context (`VAL-6`).
6. Keep phase activation order above per-unit `AISpec`; support fixed,
   priority-sort, greedy-best-first, and seeded random (`VAL-8`).
7. Non-combat actions eventually enter the same candidate set; depth-0 action
   grants use the bounded enablement heuristic (`VAL-11`).

## Required reconciliation audit

The July 3 Band 5 plan says to ship a minimum registry-backed weighted sum and
defer `VAL` to Band 7. That conflicts with the later locked `VAL-5` answer: one
F16/REQ score-tree path from the first scorer slice, with `nearest`/`weakest`
folded into presets. Update the plan before implementation; do not create a
temporary four-term scorer that will be replaced.

Audit these implementation questions against current code and record evidence:

- What is the smallest pure `PlannedAction` contract that can represent today's
  move/attack/wait behavior without Source+Style or save-schema changes?
- Can `ProjectionService.project_combat` accept hypothetical tile/weapon context
  without mutating units, RNG history, inventory, or party resources?
- Which minimum F16/REQ nodes and forecast term sources are necessary for a
  depth-0 `nearest`/`weakest`-parity scoring tree?
- Which candidate types must remain explicitly deferred until Source+Style,
  utility staves, action grants, conditions, and objective-pressure adapters land?
- Which activation-order modes can be implemented without `ai_awake`, MET, or a
  save migration, while preserving deterministic placement-order behavior?

These are implementation-audit questions under resolved architecture. Escalate
only if current code makes a locked answer impossible or materially changes the
dependency order.

## Recommended first slice

Write a preimplementation delta review first. Unless the audit disproves it,
the first code slice should be the pure planner seam plus deterministic
`PlannedAction`/candidate ordering for today's attack/wait palette, with byte-
equivalent `nearest` behavior and no new scoring formula yet. Follow with the
hypothetical projection adapter, then the minimum data-authored depth-0 scorer.

Do not start advanced recursion, forward modeling, perception/appraisal,
Source+Style action enumeration, or save-backed wake/group behavior in this slice.

## Verification obligations

- Existing `nearest` behavior and RNG chain remain byte-equivalent.
- Planning mutates no board, unit, inventory, resource, save, or RNG state.
- Candidate order and tie-breaks are stable across repeated runs.
- Adding a scorer preset/term is data registration, not an `EnemyAI` switch edit.
- Update GDD 08, GDD 10, the control plane, and DoD#2 checks with each behavioral
  landing.
