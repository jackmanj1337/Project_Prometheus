---
Type: planning handoff
Status: Planned — execute next session; planning only
Last verified: 2026-07-23
Research source: campaign_data_ownership_research_findings_2026-07-23.md
Owner approval: 2026-07-23 — all ten research recommendations approved
Tracker: PLAN-CAMPAIGN-DATA-OWNERSHIP-2026-07-23
---

# Campaign Data Ownership — Implementation-Planning Handoff

## Next-session outcome

Write implementation plans for all five approved changes:

1. multi-owner, multi-resource economy;
2. pack-associated saves, migrations, and export/backup surfaces;
3. a zero-content engine with self-contained campaign packs;
4. separate allow-listed formula registries; and
5. pack-authored rule profiles resolved into stable per-run snapshots.

This is a **planning session only**. Do not change runtime code, save schemas,
pack formats, content, scenes, or tests. The deliverable is a complete set of
reviewable, dependency-aware implementation plans and tracker rows. The plans
must preserve the decisions in
[`campaign_data_ownership_research_findings_2026-07-23.md`](campaign_data_ownership_research_findings_2026-07-23.md);
they must not reopen those decisions as design questions.

Work status and final delivery sequencing remain owned by the
[Project Control Plane](project_control_plane_2026-06-29.md).

## Required reading before planning

1. `campaign_data_ownership_research_findings_2026-07-23.md` — approved
   contract, evidence, and player/author outcomes.
2. `campaign_data_ownership_research_handoff_2026-07-23.md` — original scope
   and thread boundaries.
3. `campaign_pack_engine_boundary_plan_2026-07-15.md` — existing security and
   executable-authority boundary. Reconcile its older “engine owns saves” wording
   with the approved meaning: the engine writes user state while pack identity
   owns its namespace and interpretation.
4. `project_control_plane_2026-06-29.md` and `GDD_10_Roadmap.md` — existing
   feature ownership and scheduling.
5. `coordination/tasks.json` rows `PP-FACTION-GOLD-ECONOMY`,
   `PP-STRATEGIC-DATA-OWNERSHIP`, `B3-CAMPAIGN-RULES`,
   `LEG-AUDIT-FE-NUMBERS`, and the four completed `RESEARCH-*` rows.

## Planning order

Plan in this order because each step constrains the next:

1. **Zero-content engine** — establish the target package boundary, boot state,
   content-family migration matrix, and transition strategy.
2. **Formula registries** — define which live formulas move with content and
   which reviewed primitives remain engine-side before pack schemas are frozen.
3. **Pack-associated saves** — bind persistence, compatibility, migration, and
   exports to the package identity/schema established above.
4. **Economy wallets** — place wallet state into the approved save/checkpoint
   model and avoid creating a temporary scalar migration twice.
5. **Rule profiles** — use the final pack catalogue and save snapshot seams for
   the smallest independent authoring slice.

The plans may recommend parallel implementation slices after shared foundations
land, but they must show the machine-checkable dependency order explicitly.

## Plan 1 — Zero-content engine

Create `zero_content_engine_implementation_plan_2026-07-<date>.md` covering:

- the engine-only boot set: main menu, settings/accessibility/input, package
  discovery/installation/selection, trusted primitive registries, and empty
  inactive content catalogues;
- removal of unconditional `res://data` loading from `DataManager` and
  `RegistryManager`;
- a content-family migration table for campaigns, maps/encounters, rosters,
  classes, weapons, items, skills, terrain, Pair Up tables, registry entries,
  media, and every current `data/` file family;
- the full Tier-2 validator/adapter/catalogue expansion required before each
  family moves;
- base-game extraction into a normal self-contained pack, coordinated with
  `LEG-AUDIT-FE-NUMBERS` so values/provenance move once;
- no-pack, invalid-pack, missing-family, and pack-selection player flows;
- incremental slices that keep `agent/integration` bootable and testable at
  every commit—no flag day that deletes `data/` before a valid pack replaces it;
- automated gates proving an engine export contains no playable content and a
  selected pack supplies every referenced family; and
- GDD/control-plane/feature-index changes required alongside behavioral slices.

Explicitly reject hidden base-pack inheritance and v1 pack dependencies.

## Plan 2 — Formula registries

Create `formula_registries_implementation_plan_2026-07-<date>.md` covering:

- separate registry/schema contracts for hit rolls, damage, range, growth,
  costs, requirements/predicates, and AI scoring;
- an inventory of existing hardcoded formulas/selectors and the first safe
  migration candidates (`hit_formula`, weapon range grammar,
  `CostSpec.formula_term`, objective/item/action primitive seams);
- fixed determinism contracts per family, especially RNG draw count/order,
  numeric bounds, allowed inputs, mutation authority, preview behavior, and
  failure behavior;
- parameter validation and unknown-id rejection before pack activation;
- replacement of closed field/type switches where author vocabulary must grow,
  while keeping executable handlers engine-side;
- explicit non-goals: no general expression language, arbitrary loops, pack
  scripts, dynamic filesystem/runtime-object access, or universal formula VM;
- staged adoption so existing formulas become registered defaults before pack
  data selects alternatives; and
- focused fixtures for deterministic evaluation, malformed parameters, unknown
  ids, save stability, and preview/runtime parity.

The plan must identify which registries are v1-required for zero-content and
which can remain later extensions without blocking base-pack extraction.

## Plan 3 — Pack-associated saves and exports

Create `pack_associated_save_implementation_plan_2026-07-<date>.md` covering:

- canonical save ownership: engine-written user state grouped by package and
  campaign identity, never stored inside an installable pack;
- a single save-schema/default provider that removes manual duplication between
  `CampaignRules`, `SaveData`, codecs, headers, and runtime capture;
- exact fields for `save_format_version`, package id/version,
  `content_schema_version`, deterministic content fingerprint, campaign id, and
  resolved defaults;
- the mutable-snapshot/durable-id boundary for roster, inventory, wallets,
  campaign state, map state, and rewind checkpoints;
- transactional load order: save-format migration, compatible-pack resolution,
  declarative pack migration chain, full reference validation, then activation;
- an engine-owned migration primitive registry and initial operations derived
  from real known migrations—no pack scripts;
- missing-pack and incompatible/mutated-pack UI, including import-but-disabled
  portable saves;
- three explicit export/restore surfaces: portable save, clean installable pack,
  and full backup envelope with clean pack plus separate user state;
- compatibility with existing `SaveManager.export_slot`, package exporter,
  installer/preflight, integrity stamping, and status records; and
- old-save migration tests, failure injection, rollback, fingerprint mismatch,
  round-trip, security, size-budget, and human-readable diagnostics.

The plan must distinguish intentional history/header copies from harmful
authoring duplication.

## Plan 4 — Multi-owner economy

Create `multi_owner_economy_implementation_plan_2026-07-<date>.md` covering:

- structured `owner_ref = {kind, id}` validation and canonical keys for
  `faction`, `shop`, `campaign`, `unit`, and `arena`;
- explicit `campaign | map | transaction` lifetime for shop/arena owners;
- wallet storage for `gold`, `bonus_exp`, and `training_points` from the first
  slice, with resource definitions remaining open-registry data;
- `CostSpec.scope`/`subject_binding` resolution into owner refs without adding a
  faction-only cost field;
- the complete consumer migration from `party_gold`: `GameState`,
  `ResourceLedger`, `TurnManager`, `MapMenu`, `ProjectionService`, save/header
  codecs, measurements, and tests;
- legacy migration in which the blue/player campaign wallet inherits
  `party_gold`;
- atomic quote/commit/refund across multiple wallets and resources;
- complete wallet snapshots in Retry/Rewind checkpoints, with validate-before-
  commit restore and projection purity;
- rewind charges remaining a separate non-rewindable timeline budget for v1;
  do not force them into ordinary wallets; and
- player-facing selection/display rules for hotseat controllers, factions,
  shops, rewards, insufficient-resource messages, and results totals.

The plan must name the first end-to-end playable slice—not only the storage
foundation—and prevent a half-migration where UI or rewards still read the old
scalar.

## Plan 5 — Rule profiles

Create `rule_profiles_implementation_plan_2026-07-<date>.md` covering:

- a pack-catalogued JSON profile containing an id, schema version, and existing
  `CampaignRules` fields only for the first slice;
- validator/adapter/catalogue support and clear unknown-field/value errors;
- campaign `profile_id` reference, resolution at New Game, explicit campaign
  default overlay, and storage of both selected id and resolved defaults;
- existing-run stability: pack/profile updates affect future runs unless an
  explicit migration updates an existing run;
- unchanged precedence: mandate → node override → mid-map override → resolved
  campaign default; profiles never create another runtime layer;
- editor/import/copy authoring flows in which copied profiles become ordinary
  pack-owned documents with local ids;
- base/template profiles shipping as pack data, never engine-baked gameplay
  content; and
- fixtures for resolution, overlay, mandates, overrides, unknown ids, copied
  profiles, pack updates, save/load, and migration.

Keep this plan small and independently deliverable after the shared pack/save
schema seams are available.

## Cross-plan requirements

Every plan must include:

- current-state code/file inventory with exact symbols;
- target data shapes and ownership boundaries;
- incremental commits/slices, dependencies, and merge target
  (`agent/integration` for product work);
- compatibility and migration strategy;
- negative/security/failure cases;
- automated tests plus any Windows visual/player validation;
- documentation changes required by DoD#1 and enforcement changes required by
  DoD#2;
- explicit exclusions to prevent scope creep;
- retirement/supersession targets for older plans whose wording conflicts; and
- a new canonical `coordination/tasks.json` implementation row (or child rows)
  with real `dependencies`, claimed paths, phase, and trigger.

Do not put open work only in the five plan documents. The tracker rows are part
of the planning definition of done.

## Planning definition of done

- [ ] Five implementation plans exist and pass `AGENT/Docs/check_docs.py`.
- [ ] Their dependency graph is consistent across all five documents.
- [ ] Each implementation slice has a canonical tracker row and no claim
      conflicts.
- [ ] The Project Control Plane and Feature Index link the new active sources or
      the role manifest explicitly owns them.
- [ ] The four completed research rows remain completed with their approved
      decision summaries.
- [ ] No runtime, schema, pack, content, scene, or test implementation is mixed
      into the planning commits.
- [ ] `coordination/gen_active_work.py` and `coordination/check_tasks.py` pass.
- [ ] The session note claims every planning commit and states the first
      implementation slice to start next.

## Handoff references

- Approved research and owner decisions:
  `campaign_data_ownership_research_findings_2026-07-23.md`
- Original research handoff:
  `campaign_data_ownership_research_handoff_2026-07-23.md`
- Existing pack/engine boundary:
  `campaign_pack_engine_boundary_plan_2026-07-15.md`
- Runtime/save sources inventoried in the findings:
  `DataManager.gd`, `RegistryManager.gd`, `ResourceLedger.gd`, `GameState.gd`,
  `SaveData.gd`, `SaveManager.gd`, `CampaignPackExporter.gd`,
  `CampaignTier2Validators.gd`, `CampaignTier2RuntimeAdapter.gd`,
  `CampaignRules.gd`, and the formula/primitive registries listed there.
