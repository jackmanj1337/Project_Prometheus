---
Type: plan
Status: READY FOR NEXT-SESSION REVIEW
Last verified: 2026-07-27
Tracker: REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27
---

# Next-session handoff — review the accepted portfolio against current code

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md), with
cross-branch review state in `coordination/tasks.json` under
`REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27`.

## Goal

Review the accepted implementation portfolio against the actual current Project Prometheus codebase
before any product implementation begins. Confirm that every proposed slice starts from an accurate
description of existing code, uses the correct state owner and extension seam, and has complete
dependencies, tests, migrations, documentation, and playtest gates.

This is a review and planning-correction session only. **Do not implement runtime, UI, schema, data,
save, migration, or authoring-tool changes.** If the review finds a defect, record it in the owning
plan and tracker row; do not fix the product code in the same session.

## Authoritative inputs

- [`recent_research_implementation_portfolio_review_2026-07-27.md`](recent_research_implementation_portfolio_review_2026-07-27.md)
- [`dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md`](dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md)
- `coordination/tasks.json`, especially `UIREC-V1-*`, `LIB-V1-*`, `PREP-V1-*`, `TEXT-V1-*`,
  `DRC-V1-*`, the four `EPIC-*` rows, and `MILESTONE-V1-FOUNDATION-GAMEPLAY-PROOF`
- The accepted owner rulings recorded in portfolio section 11
- Current `agent/integration` code after the accepted planning branch is reconciled into it

The tracker is authoritative for scope and dependencies. The codebase is authoritative for what
already exists. The accepted design registers are authoritative for intended behavior.

## Required review sequence

1. Fetch current refs and record the exact reviewed `agent/integration` SHA. Do not review against an
   unspecified or stale checkout.
2. Inventory the real classes, autoloads, services, registries, codecs, scenes, tests, and data
   families touched by every proposed foundation and first consumer.
3. For each plan slice, compare the claimed starting state and proposed ownership with the code.
   Classify every assertion as confirmed, stale, incomplete, conflicting, or requiring investigation.
4. Trace the accepted shared contracts through their consumers:
   - Requirement with narrow domain predicates/adapters;
   - ActionJournal/StateView with domain-owned workflows;
   - SpatialTargetQuery with domain-owned eligibility filters;
   - UnitTransitionService as the sole multi-dimension transition writer;
   - shared record-screen state with domain-owned data and transactions.
5. Review schema/save/rewind boundaries, including compatibility seams. Confirm that a seam prevents
   a known incompatibility without implementing deferred behavior speculatively.
6. Review dependency order and tracker granularity. Detect cycles, hidden prerequisites, duplicate
   authorities, old coarse rows that still compete with slice rows, and slices too large for one
   reviewable branch.
7. Review tests and evidence gates against existing test infrastructure. Name the exact test suites
   that can be extended and any missing harness required before implementation.
8. Amend plans and tracker rows only where the code review provides concrete evidence. Present any
   real product fork to the owner with options, tradeoffs, and a recommendation; wait for an answer.

## Minimum code areas to inspect

- Campaign/package/session activation, Library screens, pack installer/exporter, save identity,
  codecs, migration, and no-content behavior.
- Prep activity registry, Prep screen, campaign node/cadence data, inventories, resource ledgers,
  shops, Convoy, and any existing transaction/rollback utilities.
- RegistryManager, condition/skill infrastructure, action/effect runners, targeting/GridManager,
  occupancy, unit/team/controller/roster state, TurnManager, result processing, Retry/Rewind, and
  campaign saves.
- Shared UI state/focus/input/menu-scale patterns and the current Campaign Library and Prep tests.
- Current text-input handling, sanitization/BBCode boundaries, settings/input-mode ownership, and
  platform-specific seams.

## Deliverables

1. A code-state evidence matrix mapping every accepted slice to exact current files/symbols and a
   verdict: confirmed, amend, split, merge, reorder, defer, or investigate.
2. An architecture collision report identifying duplicate machinery, incorrect ownership, closed
   switches that should be registries, and services at risk of becoming feature-aware god objects.
3. Corrected dependency edges and plan text where evidence requires them, with generated tracker and
   documentation views refreshed.
4. A first-tranche readiness verdict for the foundation plus non-mutating authored-interaction
   milestone. List explicit blockers; do not start the tranche.
5. Passing documentation/tracker checks. Run existing automated tests as baseline evidence, but make
   no product-code or test-code changes.

## Stop conditions

- Stop and ask the owner when evidence exposes a genuine behavior, scope, compatibility, or milestone
  choice. Explain the question, options, arguments for and against, and a recommendation.
- Do not treat an implementation inconvenience as a product question; reconcile mechanical facts in
  the review artifacts directly.
- Do not create implementation branches, edit product code, add schemas, or begin Slice 0/1 work.
- Do not silently broaden V1. Atomic Conversation restart, one ASCII grid plus hardware entry, narrow
  Library first, and Prison last remain accepted unless a concrete incompatibility is demonstrated.

## Definition of done

The review is complete when every accepted slice has current-code evidence, every dependency is
machine-readable, all plan corrections are documented, the first tranche has a clear readiness
verdict, tracker/documentation checks pass, and no product implementation was performed.
