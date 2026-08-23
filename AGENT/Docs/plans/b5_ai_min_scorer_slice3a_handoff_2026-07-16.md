---
Role: dated
Type: plan
Status: Planned - next-session implementation handoff
Last verified: 2026-07-16
---

# `B5-AI-MIN-SCORER` Slice 3A Handoff - 2026-07-16

## Next-session goal

Implement and prove the bounded deterministic weapon-attack scorer on the
existing `AISpec`, `EnemyAI`, and `B2-PROJECTION` seams, while preserving every
shipped AI profile's existing decisions through an explicit compatibility
preset. Land the smallest green increment that establishes the open scorer-term
registry and pure scoring path; mark `B5-AI-MIN-SCORER` **Split**, not
Implemented.

## Resume point

- Work in `repo/Project_Prometheus_prep_save` on
  `agent/codex/2026-07-15/prep-save-followup`, or branch from its clean head.
- Read the latest session note and
  [`playtest_waiting_work_queue_handoff_2026-07-16.md`](playtest_waiting_work_queue_handoff_2026-07-16.md).
- Re-read the reconciled
  [`band5_ai_implementation_plan_2026-07-03.md`](band5_ai_implementation_plan_2026-07-03.md)
  Slice 3A contract, `GDD_08`, and the `B5-AI-MIN-SCORER` control-plane row.
- Before work and before each new logical commit, check for either outstanding
  Windows playtest return. A return preempts this work at the current green
  commit. Do not rebuild or modify the protected playtest artifacts.

## Scope

Slice 3A scores only legal weapon attacks the present AI can already plan and
execute. Candidate enumeration, projection, term evaluation, diagnostics, and
selection must be pure and deterministic.

Required terms:

- expected damage;
- lethal result;
- counter-damage;
- destination exposure;
- target value.

Full ties resolve with stable unit, tile, and weapon identifiers. Slice 3A draws
no RNG. Registered scorer terms are the extension seam; do not implement a fixed
term expression or a new forecast path.

The compatibility preset must retain the shipped `basic`, `passive`, `healer`,
and `hunter` decision behavior. Staff healing and wait remain delegated fallback
paths and receive regression coverage; they are not scored as new action tuples
in this slice.

## Explicit non-goals

- No scored staves, styles, refresh, AoE, gambits, capture, or other non-weapon
  actions. Those belong to Slice 3B after `B5-SOURCE-STYLE`.
- No `set_ai`, group wake, seek-tile expansion, or activation-order rebuild.
- No lookahead, search depth, perception, hidden-information model, learned
  evaluation, or multi-activation optimization.
- No new saved state, RNG stream, release artifact, or live-log spam.
- Do not mark the track Implemented.

## First actions

1. Confirm the tree is clean enough to isolate this work and check for returned
   playtest evidence.
2. Inventory `EnemyAI` candidate selection/execution, `AISpec` resolution,
   `ProjectionService` request/result fields, danger/exposure helpers, and stable
   weapon/unit identifiers. Record exact code anchors in the implementation
   commit or handoff update.
3. Write a compact requirement/evidence matrix before production code. If one
   of the five required terms cannot be computed purely from existing seams,
   stop and document that technical gap; do not invent live-state simulation.
4. Add focused failing tests for purity, compatibility, and deterministic
   selection.
5. Implement the smallest generic scorer-term registry and selection loop that
   makes those tests pass.

## Requirement/evidence matrix

| Requirement | Required evidence |
|---|---|
| Existing legal weapon attacks only | Candidate fixture excludes unusable/out-of-range weapons and never invents an executor path. |
| Expected damage and lethal terms | Lethal and non-lethal fixtures select the intended tuple from Projection results. |
| Counter-damage and exposure | Counter/no-counter and safer-destination fixtures distinguish otherwise similar attacks. |
| Target value | Equal combat outcomes prefer the authored higher-value target. |
| Stable ties, no RNG | Repeated/reordered fixture runs choose the same stable tuple and leave RNG history byte-identical. |
| Pure scoring | Unit, board, inventory, campaign, ledger, and projection-owned state are byte-identical before/after scoring. |
| Open term seam | A fixture term registers and affects the result without editing the scorer loop. |
| Compatibility preset | Existing profile decision fixtures remain byte/decision-identical; staff and wait fallbacks still execute. |
| Quiet diagnostics | Headless failure output exposes term components; normal execution emits no per-candidate logging. |

## Suggested commit boundaries

1. **Plan/evidence preflight:** inventory anchors and finalize the matrix if code
   inspection exposes a narrower technical boundary.
2. **Scorer foundation:** pure candidate contract, registry-backed term loop,
   stable selection, compatibility preset, and focused tests.
3. **Track handoff:** update `GDD_08`, `GDD_10`, Feature Index/control plane to
   **Split**, record exact implemented behavior and Slice 3B gates, then add the
   session note and evidence.

Keep production behavior, owning GDD/roadmap status, and enforcement evidence in
the same logical delivery. Do not flip documentation ahead of the code.

## Exit gates

Run at minimum:

```bash
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
bash scripts/check_gdformat.sh
bash scripts/check_gdlint.sh
bash run_tests.sh
```

Also run the focused AI, projection, RNG, and compatibility suites directly so
their counts and names can be recorded in the session note. Run
`bash scripts/session_closeout.sh` before handoff or push.

## Definition of done

Slice 3A is done only when the generic scorer selects among existing legal
weapon attacks using all five required terms, is proven pure and deterministic,
preserves shipped behavior through the compatibility preset, and all gates are
green. The control plane and roadmap then say **Split** and name Slice 3B's
remaining dependencies. Any missing full-action support is expected Slice 3B
work, not grounds for overstating Slice 3A or silently widening it.
