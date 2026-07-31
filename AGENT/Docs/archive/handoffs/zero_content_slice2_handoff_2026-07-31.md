---
Type: handoff
Status: Superseded
Last verified: 2026-07-31
Tracker: IMPL-ZERO-CONTENT-FAMILIES
---

> **Superseded** by [the Weapons-family handoff](zero_content_weapons_handoff_2026-07-31.md).

# Next-session handoff — zero-content Slice 2 (for codex)

**Managed by:** [`project_control_plane_2026-06-29.md`](../../plans/project_control_plane_2026-06-29.md),
with cross-branch state in `coordination/tasks.json` under
`IMPL-ZERO-CONTENT-FAMILIES`. Implementation plan:
[`zero_content_engine_implementation_plan_2026-07-23.md`](../../plans/zero_content_engine_implementation_plan_2026-07-23.md).

Picks up `IMPL-ZERO-CONTENT-FAMILIES` after the 2026-07-31 edge/route session.
Branch `agent/from-integration/zero-content-families-class`, tip `18e0a1d2`,
pushed. Session note:
`AGENT/Session Notes/2026-07-31-05-59-31Z-zero-content-slice2-edge-routes.md`.

Slice 2 is the only buildable row on the zero-content line — `IMPL-ZERO-CONTENT-BASE-PACK`,
the three pack-save slices, `IMPL-RULE-PROFILES`, `IMPL-ZERO-CONTENT-EXPORT-GATE`
and `B3-CAMPAIGN-RULES` all queue behind it. `LEG-AUDIT-FE-NUMBERS-2026-07-20`,
Slice 3's other dependency, is already completed, so Slice 3 opens the moment this
row closes.

## State entering the session

Landed 2026-07-30 (`031303b7`, `bfe039e8`): the bounded class foundation — required
class mechanics, typed nested schema objects, distinct source/occurrence provenance
errors, bounded class variants, WEXP invariants, and the pure `ClassAdvancement`
resolve/atomic-commit seam.

Landed 2026-07-31 (`58cddb17`, `b29359d2`, `a255170c`):

- `advancement_edge` and `advancement_route` registered as engine-owned schemas.
  Fixed and branching edges share one schema and one commit path, differing only in
  destination count. Edge variants may override destination, gains, and operations
  but never `route_refs` — the routes that gate whether the transition may happen.
- An **open handler registry** (`EntitySchemaRegistry.register_handler`, seeded with
  `class_advancement_v1`). Executable descriptors previously had no trusted-registry
  check at all, so a pack could name any `handler_id` and fail only at runtime,
  mid-transition. Unknown handlers and unadmitted handler versions now fail
  validation before preview. Built as a registry rather than a `match` per the repo
  architecture principle: a new handler is a registration, not an engine edit.
- The synthetic Z0/Z1 fixture corpus ported out of `Campaign_Pack_FE` into
  `test_fixtures/zero_content/` (35 files) and
  `test_fixtures/zero_content_expected_errors/` (8 files).

Gates: import pass first (a bare `--quit` rebuilds neither the import nor the class
cache), then `bash run_tests.sh` green before and after.
`test_entity_schema_registry` is 22 passed / 0 failed. `gdformat --check` clean.

## 1. Coordinate with the FE-pack fixture work — do this first

The only time-sensitive item. `ZERO-CONTENT-PREDICATE-FIXTURE-PLAN-2026-07-29` is
in progress on `agent/from-main/zero-content-predicate-fixture-plan`, and two things
now overlap with the engine.

**Fixture regeneration.** Review findings 4 and 5 require RFC 4122 UUID
`package_id`s and `distribution_policy: private_only` replacing the non-contract
`internal_only`. Those fixtures now exist in both repos. If the pack branch
regenerates while the engine copy is normalized separately, the two corpora diverge
on exactly the field that decides distribution eligibility. Agree who does it and
where before either side starts. `test_fixtures/zero_content/README.md` lists all
four known drifts, including two beyond findings 4/5:
`rights_status: "project_owned_test_data"` and
`distribution_scope: "internal_only"`, both outside their closed vocabularies, plus
`license_id: "project-owned"`, which is neither an SPDX id nor a `LicenseRef-*`.

**The 16-item completeness checklist is stale.** The fixture plan's
"Plan-completeness checks against the public engine work" section says the engine
plans are incomplete until all sixteen are answered. Spot-checking against
`band3_core_authoring_foundations_implementation_plan_2026-06-30.md` Slice 5 and
`zero_content_engine_implementation_plan_2026-07-23.md`, most already are:
predicate and value-term serialization, missing-subject/unavailable-value semantics,
complexity budgets, consumer context bindings, unmet-reason and hidden-versus-disabled
presentation, the fingerprint byte stream and algorithm version, same-id/different-fingerprint
quarantine, draft-waivable provenance, the rights/licence/distribution vocabulary,
and SVG admission. The genuine residue is fixture-side (the receipt binding engine
commit to fixture-pack commit, and public/private fixture pairing), which belongs
where it already is.

The fix is to resolve the checklist in place with pointers to where each item is
answered, so a future reader does not reopen settled contracts. That edit lands on
the pack branch, which is why it was left rather than made underneath active work.

## 2. Close the variant-eligibility handler gap

Small, bounded, and it finishes the descriptor-trust story. `transition`,
`operations`, and all five route descriptors now resolve against the handler
registry. `variants[].eligibility` does not — for class **or** edge variants.

Do both in one change. They are consistent today; checking only edges would make the
two variant kinds diverge for no reason.

Note that the golden class fixture in `test_entity_schema_registry.gd` uses
`fact_contains_v1`, which is not registered. Closing this gap therefore forces the
real decision about what the eligibility handler family is, instead of leaving a
placeholder sitting in a golden fixture. That is the substantive part of the task.

## 3. Wire the ported corpus into an engine suite

Highest leverage after item 2. The Z0/Z1 fixtures are in the tree with nothing
reading them. An engine-side suite that loads each fixture and asserts against
`test_fixtures/zero_content_expected_errors/` does three things at once: proves the
port, gives the vocabulary normalization from item 1 a test to normalize against,
and creates the parity client that the pack's `tests/test_zero_content_fixtures.py`
is already declared to become ("deliberately non-canonical", per its own plan).

## 4. Tier-2 catalogue and runtime adapter adoption

`scripts/resources/CampaignTier2Validators.gd` and
`scripts/resources/CampaignTier2RuntimeAdapter.gd` are claimed by the tracker row,
but neither the class foundation nor the edge/route session touched them — all work
so far is in `EntitySchemaRegistry`. Until the adapters consume the registered
schemas, the contract is validated but not used, and nothing downstream can depend
on it.

Worth doing before adding more families, otherwise each new family adds schema with
no consumer.

## 5. Then the next family — decide which, deliberately

A real ambiguity, not a detail. The plan says to add families vertically in the
plan's order, and the migration matrix order is Campaigns, Map registry, Battle maps,
Encounters, Rosters/units, **Classes**, Weapons, Items, Skills, Terrain, Pair Up,
Registry documents, Rule profiles, Media. Classes was taken first, out of order,
because `class_schema_trial_v1_2026-07-29.md` drove it.

So "next" is genuinely undecided: resume at the top with Campaigns, or continue
adjacent to warm context with Weapons, which shares the WEXP and formula-selection
surface just worked on. Either is defensible. Pick one explicitly and record it in
the plan so the following session does not re-litigate it.

## Parallel work, if engine context is not wanted

`FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31` is open in `0-unblock`, docs-only,
and independent of everything above. Roughly 18 of its ~20 sites are writable now;
only the two palette sentences are gated on `DECIDE-EDITOR-CONTENT-PALETTE-2026-07-31`.

## One scope question for the owner

Slice 2 is 13 families wide and blocks the entire rest of the line. If closing it
fully looks like several sessions, it is worth asking whether Slice 3 needs every
family validated, or only the families the base pack actually uses. That is an owner
call about scope, not one to make mid-implementation.
