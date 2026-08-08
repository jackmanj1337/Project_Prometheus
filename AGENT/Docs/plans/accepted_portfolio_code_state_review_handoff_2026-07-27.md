---
Type: plan
Status: WAITING FOR ACCEPTED STABLE v0.5 RELEASE
Last verified: 2026-07-28
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

## Release gate and recorded merge order

This review must use the post-v0.5 reconciled integration line, not the currently divergent
pre-acceptance branches. It is therefore waiting for an exact accepted stable v0.5 release identity.
Release tags remain numeric `vX.Y.Z`: use `v0.5.7` if the existing artifact is accepted unchanged;
if any code or build-affecting change is required, cut and validate the next numeric patch (normally
`v0.5.8`). Do not use `v0.5.s`, because it violates the repository tag policy and does not provide a
sortable patch identity.

Once that identity exists, use this order:

1. Promote the accepted playtest source through `agent/playtest-release` to
   `agent/stable-release`, then through `agent/staging-area` for the human-controlled promotion to
   `main`. Do not add integration-only features to the evidenced release.
2. Merge the accepted `agent/stable-release` back into `agent/integration` through the tracked
   reconciliation task. Preserve both sides: integration and the v0.5.7 fix line diverged from
   merge base `258ed12a`, with 72 integration-only and 94 release-only commits when reviewed on
   2026-07-27. Resolve shared documentation, GDD, policy, hook, and session-index paths by content.
3. Merge the independent Phase 0 branches in order: BBCode injection hardening, text-entry
   governance, then the web-distribution freeze. Project Exchange, Prep activity registry,
   headless hardening, and branch-policy guards are already contained in integration/main and must
   not be merged again.
4. Consolidate `agent/from-integration/campaign-data-research`, then
   `agent/from-integration/dialogue-recruit-capture-research`; regenerate documentation indexes and
   reconcile the Control Plane rather than accepting either branch's generated files blindly.
5. Perform the code-state evidence review in this handoff against the resulting exact
   `agent/integration` SHA. Only after it passes may the accepted implementation slices begin.

The post-review implementation sequence remains:

```text
zero-content/session + pack/save identity
  -> Requirement + shared record-screen foundations
  -> formula/wallet/item/unit-state/condition foundations
  -> thin Campaign Library/Prep authored-interaction Windows milestone
  -> spatial/carry/Trade/Convoy + Dialogue journal/presenter
  -> Talk/recruit/objectives/map-end
  -> Explore/Prison
  -> migration, author tools, and final Windows/end-to-end review
```

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
