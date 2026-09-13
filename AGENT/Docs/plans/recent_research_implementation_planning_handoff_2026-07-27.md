---
Role: dated
Type: plan
Status: ACCEPTED — EXECUTION TRACKED BY SLICE ROWS
Last verified: 2026-07-27
---

# Next-session handoff — plan and review recently researched systems

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md), with the
cross-branch next-session task in `coordination/tasks.json` under
`PLAN-RECENT-RESEARCH-SYSTEMS-2026-07-27`.

## Goal

Write and review implementation plans for every Project Prometheus system that has recently completed
a research pass and owner discussion. Reconcile accepted decisions across registers, design packets,
existing plans, current code, and the consolidated task tracker before any product implementation
begins.

## First action next session

Audit `coordination/tasks.json` for research/discussion rows completed or materially updated during
the recent 2026-07-23 through 2026-07-27 passes. Produce a finite planning inventory. Do not rely only
on filenames or memory, and do not omit work merely because an older implementation plan already
exists.

The initial inventory must include at least:

- campaign-data ownership and its economy-wallet, pack-save, zero-content engine, formula/registry,
  and campaign-rule-profile consequences;
- campaign-library and shared UI/UX interaction architecture decisions;
- prep/economy/Explore activities, Shop, Training Hall, Convoy, Trade, forging, and their transaction
  and rollback policies;
- text-entry strategy, presenters, layout, validation, and platform seams;
- dialogue, recruitment, temporary control, capture/custody, Prison visits, relationship and
  requirement hooks, Incapacitate/Capture/Extract objectives, displacement/carry protections, and
  stat set/floor/cap effects;
- every spun-out requirement or dependency row created by those discussions.

## Deliverables

1. A tracker-backed inventory mapping each completed research/discussion source to an existing plan
   that needs review, a missing plan that must be written, or an explicitly deferred/no-build result.
2. Dependency-ordered implementation plans split into reviewable slices. Each slice identifies code
   ownership, schema/save and migration effects, campaign-data contracts, low-code authoring and
   validation, player UI/UX, deterministic action/event behavior, automated tests, documentation, and
   required playtest evidence.
3. A cross-plan architecture review covering shared foundations and duplicate machinery: registries,
   predicates, action/effect execution, staged transactions, spatial target queries, inventory/resource
   ledgers, unit transitions, save/rewind, UI presenters, and activity routing.
4. A V1 scope and sequencing review that calls out contradictions, obsolete assumptions, oversized
   slices, missing dependencies, and post-v1 seams. Present owner decisions only where a real product
   fork remains; resolve mechanical reconciliation directly.
5. Updated `coordination/tasks.json` dependencies and plan pointers, regenerated
   `coordination/ACTIVE_WORK.md`, and passing tracker/documentation checks.

## Planning rules

- Review existing plans against current code and newer owner rulings; do not treat an old plan as
  valid merely because it is detailed.
- Prefer shared foundations over feature-local copies, but keep subsystem ownership clear. Dialogue
  transaction tools may support map-end orchestration without turning map-end processing into
  dialogue; staff targeting may seed a shared spatial-query service without importing heal rules.
- Preserve the project's open-registry architecture. Author-facing vocabularies and policy presets
  must not become closed engine switches.
- Separate V1 implementation from post-v1 tunable seams. A seam belongs in V1 only when omitting it
  would force data/save incompatibility or duplicate architecture later.
- Do not begin product implementation in this planning pass. Finish plan review and owner acceptance
  first.

## Primary dialogue/custody source

The accepted decisions and recent cross-register amendments are anchored in
`AGENT/Docs/registers/dialogue_recruit_capture_research_questions_2026-07-27.md`, with connected
changes in the Convoy, Displacement/Carry, and Extensible Stat Model registers. Reconcile those
decisions into older Dialogue, Recruit/Capture, Requirement, Map Event, Objective, Relationship,
Death/Disposition, Save, Prep Hub, and Source/Style sources rather than preserving stale assumptions.

## Planning deliverables produced

- [`dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md`](dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md)
  provides the current-code audit, architecture, data/save contracts, twelve dependency-ordered V1
  slices, low-code minimum, validation, tests, documentation, and playtest gates.
- [`recent_research_implementation_portfolio_review_2026-07-27.md`](recent_research_implementation_portfolio_review_2026-07-27.md)
  inventories the recent research streams, reviews the five campaign-data plans, supplies missing
  Campaign Library/UI/Prep/Text Entry sequences, and records the cross-portfolio dependency order.

## Review focus for the next session

The mechanical reconciliation is complete. Owner review should concentrate on four scope gates:

1. whether the shared Requirement, transaction/journal, spatial-query, and unit-transition
   foundations are accepted as portfolio dependencies rather than feature-local helpers;
2. whether the proposed V1 cuts are strict enough, especially atomic conversations, one ASCII text
   layout, inert Campaign Library before pack extraction, and Prison as the final composition slice;
3. whether Campaign Library, shared record-screen UI, Prep/economy, and Dialogue/custody should each
   become one umbrella epic with slice rows, or independent feature rows from the outset; and
4. which Windows-host playtest tranche should be the first release-facing milestone.

Do not reopen resolved feature behavior unless the implementation review exposes a concrete conflict.
