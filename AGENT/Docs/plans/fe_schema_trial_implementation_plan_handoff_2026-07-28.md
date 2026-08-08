---
Type: handoff
Status: Active - next-session planning input
Last verified: 2026-07-28
---

# Cross-ruleset schema trial — implementation-plan update handoff

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
and the canonical workspace rows `ENTITY-SCHEMA-PROTOTYPE-2026-07-28`,
`FED20-PROVENANCE-IMPLEMENTATION-REVIEW-2026-07-28`, and
`IMPL-PROGRESSION-PRESSURE-2026-07-28`.

## Outcome

The three-fixture class/progression/provenance trial is design-complete. Do not run
another paper-schema pass next session. Update the owning implementation plans with
the accepted contracts below, ensure each contract has one tracker owner, and only
then begin another engine slice.

Private derivative fixtures and numeric evidence remain in
`Project_Prometheus_Campaign_Pack_FE`; do not copy that content into this repository.
This handoff carries only generic engine contracts.

## Accepted contracts to propagate

### Entity schemas and existing vocabulary

- The engine-owned declarative schema registry is canonical; generated JSON Schema,
  references, and golden fixtures are projections.
- Expand class schema definitions using existing `ClassData` vocabulary before
  inventing replacement fields: flat `base_*`, `player_growth_rates`,
  `enemy_growth_rates`, `stat_caps`, `weapon_wexp_bases`, `weapon_wexp_caps`,
  `skill_unlocks`, `tier`, `internal_level_rule`, and compatibility `promotes_to`.
- Unknown fields fail closed. Ordinary packs cannot register scripts, expressions,
  validators, or formula handlers.

### Provenance

- Packages own reusable source registries.
- Every identity-bearing document requires nonempty resolving `source_refs`.
- Direct transcription needs document references only. Transformed, disputed,
  conflicting, or ambiguous fields additionally require stable occurrence-audit ids.
- Dangling references are never waivable.
- Editor-only draft launch may waive missing occurrence coverage temporarily, with a
  persistent warning, a prelaunch report, and isolated saves.
- Complete-pack loading/export rejects missing or dangling required provenance.
- Structured errors carry package, catalogue entry, document path, field path, code,
  source/audit id, actionable message, and suggested fix where possible.

### Class and advancement variants

- One identity-bearing base entity owns durable class mechanics.
- A variant has a stable `variant_id`, an eligibility predicate, and bounded typed
  `overrides`.
- Class variants override only class-owned admitted fields. Advancement-edge variants
  override only edge-owned admitted fields.
- No identity/schema/provenance override and no arbitrary deep merge.
- Selected durable variants must survive save/load and migration.

### Advancement and class change

- Replace compatibility-only `promotes_to` semantics with the ratified generic
  `ClassAdvancement` edge/route model; retain a migration adapter while old content
  exists.
- Classes reference edges. Edges own source/destination, transition gains, rank
  grants, variant selection, and one-time operations.
- Routes compose registered trigger, requirements, cost, selection, and transition
  handlers. Packs provide data only.
- Reclass destinations remain unit-owned (`UnitData.reclass_options` or its eventual
  Tier-2 successor), not class-owned.

### Author-opt-in progression pressure

- Progression pressure is generic durable unit state selected by a campaign/rule
  profile. No selected profile means no pressure state or behavior.
- Updates occur only on the profile's registered committed route trigger. Preview and
  failed/cancelled class changes cannot mutate pressure.
- A profile selects trusted update/internal-level formula ids, class-offset bindings,
  rounding, caps, and downstream formula bindings. Packs cannot embed expressions.
- The accepted compatibility preset requires: initial zero; reclass-only accumulated
  half-effective-level pressure with floor rounding; class offsets for base/promoted/
  special categories; author/difficulty-selected caps; no pressure update on ordinary
  promotion; computed internal level supplied to EXP-related formulas.
- Save/suspend/retry/rewind and deterministic event records include pressure state and
  the committed route result.

## Plans and contracts to update next session

Update these owning documents from their latest authoritative branches; do not create
a parallel plan:

1. `zero_content_engine_implementation_plan_2026-07-23.md`
   - add entity-schema/provenance/variant validation to the class vertical slice;
   - add golden/invalid fixture and structured-error exits;
   - sequence class schema before bulk family transcription.
2. `formula_registries_implementation_plan_2026-07-23.md`
   - add trusted progression-pressure update and internal-level formula families;
   - specify freeze, versioning, rounding, input bindings, and preview purity.
3. `class_exp_pxp_boundary_plan_2026-06-29.md`
   - keep class EXP separate from PXP;
   - make computed internal level an input to profile-selected EXP formulas;
   - record durable pressure as sibling unit progression state, not PXP.
4. Campaign-data ownership planning handoff/research findings
   - add one-document-per-entity, source registry, occurrence audit, and generated
     contents/reference obligations.
5. F1 save-schema inventory/manifest
   - add selected class/edge variant ids and generic progression-pressure state;
   - cover codec round trip, migration default, retry/suspend/rewind, and pack identity.
6. Conditions/skills and class-progression plans
   - preserve `skill_unlocks` -> durable `earned_skills` ownership;
   - ensure advancement/reclass transitions use bounded operation registries.

After edits, update the Project Control Plane and canonical workspace tracker in the
same change. Archive or supersede contradictory historical wording rather than
silently leaving two active contracts.

## Required implementation tests to add to plans

- Existing class fields pass; unknown fields fail with exact paths.
- Missing/dangling provenance and missing occurrence coverage have distinct codes.
- Variant overrides reject fields owned by another entity or identity metadata.
- Variant selection round-trips through saves and migrations.
- Fixed and branching advancement edges share one path; cancelled/failed transitions
  mutate nothing.
- No pressure profile preserves current behavior and save bytes except versioned
  migration defaults.
- Opt-in pressure updates once per committed qualifying route, clamps by selected cap,
  survives save/retry/rewind, and feeds the same computed internal level to preview
  and execution.
- The private compatibility fixture verifies its reference examples without entering
  public source or exports.

## Evidence and branch identities

- Generic validator prototype: `Project_Prometheus` branch
  `agent/from-integration/entity-schema-prototype`, tip `39a99863`, 108 suites green.
- Private FEd20 review baseline: `agent/from-main/fed20-rules-profile-draft`, tip
  `5e28552`, 21 tests green.
- Private FE7 pressure fixture: `agent/fe7-schema-sample`, tip `d5bc71b`, 20 tests
  green.
- Private Awakening pressure fixture: `agent/awakening-schema-sample`, tip `566ae1d`,
  21 tests green.
- Canonical decisions and exact private formulas live in the FE pack review documents;
  this public-side handoff intentionally retains only the generic contract.

## Next-session completion signal

The plan-update session is complete when every accepted contract above appears in one
authoritative implementation plan, every new implementation row has dependencies and
test exits in `coordination/tasks.json`, generated tracker/docs views are current, and
no open work exists only in this handoff.
