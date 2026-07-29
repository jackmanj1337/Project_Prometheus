---
Type: implementation plan
Status: Planned — approved contract; implementation not started
Last verified: 2026-07-29
Decision source: campaign_data_ownership_research_findings_2026-07-23.md
Tracker: IMPL-ZERO-CONTENT-FOUNDATION, IMPL-ZERO-CONTENT-FAMILIES, IMPL-ZERO-CONTENT-BASE-PACK, IMPL-ZERO-CONTENT-EXPORT-GATE
---

# Zero-Content Engine — Implementation Plan

## Outcome and boundary

The engine boots with no active gameplay catalogue. It retains Main Menu,
settings/accessibility/input, package discovery/install/selection, trusted primitive
handlers, validators/adapters, and empty inactive catalogues. New Game and gameplay
stay disabled until one self-contained pack validates and activates. No hidden base
pack, implicit `res://data` fallback, or v1 pack dependency is permitted.

Product slices merge to `agent/integration`. This plan changes no behavior itself.

## Current-state inventory

- `scripts/autoloads/DataManager.gd`: `_ready`, `reload_presets`,
  `activate_campaign_package`, `deactivate_campaign_package`, map/campaign/class/
  roster catalogues; `_ready` loads project `data/`.
- `scripts/autoloads/RegistryManager.gd`: `DEFAULT_CONTENT_SOURCE`,
  `REQUIRED_FAMILIES`, `_ready`, `reload_presets`; five registry families load from
  `res://data/registries`.
- `scripts/resources/Tier2Catalogue.gd`: `parse`, `load_and_validate`,
  `load_campaign_pack`, `validate_campaign_documents`, `get_document`.
- `scripts/resources/CampaignTier2Validators.gd`: `registry`,
  `collect_cross_reference_errors`, validators for campaign, map registry, map,
  roster, and class.
- `scripts/resources/CampaignTier2RuntimeAdapter.gd`: `load`, `_build_classes`,
  `_build_rosters`, `_build_maps`, `_build_map_registry`, `_build_campaigns`.
- `CampaignPackRegistry`, `PackManifest`, archive preflight/installer,
  `CampaignPackExporter.export_zip`, `MainMenu._on_new_game`, and the campaign
  selector are the existing package and player-flow seams.
- `data/` currently contains campaigns; split battle maps/encounters plus legacy
  map resources; rosters; classes; weapons; items; skills; Pair Up; registry
  entries; and map registry JSON. Media lives under `assets/` and must be admitted
  by pack index/resolver rather than copied wholesale.

## Target package contract

`manifest.json` identifies package/version and content-schema version.
`data/catalogue.json` is the sole indexed document list. Each entry has a supported
`kind`, durable `id`, safe relative JSON path, and schema version. Media is indexed
through logical asset ids. Activation builds a candidate `ContentSession` containing
typed catalogues plus pack identity/fingerprint; only a fully validated candidate is
swapped into `DataManager`/`RegistryManager`. Deactivation returns both to a valid
empty state. Primitive callables remain engine-owned; pack registry documents only
select registered handler ids and validated parameters.

## Content-family migration matrix

| Family | Tier-2 work before movement | References / activation exit |
|---|---|---|
| Campaigns | Expand existing validator for profile id, defaults, mandates, nodes and presentation ids. | Campaign/node/map/profile ids resolve; selector can launch. |
| Map registry | Preserve labels, roster policy/source and package-qualified map ids. | Every entry resolves one map/encounter pair and valid roster policy. |
| Battle maps | JSON grid, terrain cells, start/objective tiles, asset ids. | Bounds/terrain/objective cross-checks pass. |
| Encounters | Factions, turn order, placements, objectives, rewards, overrides. | All faction/unit/class/item/skill/objective ids resolve. |
| Rosters/units | Full stats, progression, inventory, skills, faction and authored state. | Durable unit ids unique; mutable runtime copies build. |
| Classes | Engine-owned declarative schema over existing `ClassData`: flat `base_*`, player/enemy growths, caps, WEXP bases/caps, `skill_unlocks`, `tier`, `internal_level_rule`, compatibility `promotes_to`, bounded variants, movement and sprite ids. | Unknown fields fail with exact paths; stat/skill/class/media/provenance ids resolve; selected durable variants are saveable. |
| Weapons | Full combat fields, effects, costs and registered range formula selection. | Item/stat/formula/resource references validate. |
| Items | Uses, effects, costs, class requirements, icons. | Effect/requirement/resource/class ids validate. |
| Skills | Triggers, modifiers and registered engine primitive selections. | Handler/stat/resource ids validate; no pack callable. |
| Terrain | Movement/avoid/defence/healing and media ids. | Movement/stat/media ids validate. |
| Pair Up | Bonus table schema and stat-id validation. | Every table cell and referenced stat is bounded. |
| Registry documents | JSON adapters for resource types, objective conditions, item effects, action primitives, occupancy policies. | Handler ids exist in trusted primitive registries. |
| Rule profiles | Added by the rule-profile plan after save/schema seams. | Profile ids unique and CampaignRules-valid. |
| Media | Logical id, admitted path/type/size and repair metadata. | Every referenced id resolves inside pack root. |

Legacy `data/maps/<id>/*_data.tres` is retired only after split battle-map and
encounter JSON provides equivalent coverage. Every current `data/` file must appear
in an extraction inventory with destination, disposition, and provenance; no
unclassified file may be deleted.

### Class entity, provenance, and advancement contract

The concrete pre-freeze serialization and synthetic conformance inputs are defined
by [`class_schema_trial_v1_2026-07-29.md`](../design/class_schema_trial_v1_2026-07-29.md).
Implement that narrowly versioned trial, run its promotion exits, and update its
registry and fixtures together if implementation exposes a defect. Do not treat the
trial label as permission to invent a second schema in implementation.

The engine-owned schema registry is canonical. Generated JSON Schema, references,
and golden fixtures are projections, not competing authorities. Class documents use
one identity-bearing base entity plus optional bounded variants: each variant has a
stable `variant_id`, eligibility predicate, and typed overrides. Class variants may
override only admitted class-owned fields; advancement-edge variants may override
only admitted edge-owned fields. Identity, schema, provenance, and arbitrary
deep-merge overrides are rejected.

Packages own reusable source registries. Every identity-bearing document has nonempty
resolving `source_refs`; direct transcription needs document references, while
transformed, disputed, conflicting, or ambiguous fields also name stable occurrence
audit ids. Missing document coverage, missing occurrence coverage, and dangling
references are distinct structured errors. Dangling references are never waivable.
Editor-only draft launch may temporarily waive missing occurrence coverage with a
persistent warning, prelaunch report, and isolated saves; complete-pack load/export
rejects all missing or dangling required provenance. Errors carry package, catalogue
entry, document path, field path, code, source/audit id, actionable message, and a
suggested fix where possible.

Exact field evidence may optionally use a `transcribed` occurrence record; ordinary
direct transcription does not require one unless an authoring/audit policy opts in.
Required class maps carry completeness states. Draft packs may retain `unverified`
fields, while complete-pack export/load rejects them; an empty required map must be
explicitly `unverified` or rules-profile-permitted `not_applicable`.

`ClassAdvancement` replaces compatibility-only `promotes_to` semantics. Classes
reference stable edges; edges own source/destination, transition gains, rank grants,
variant selection, and bounded one-time operations. Routes compose registered
trigger, requirement, cost, selection, and transition handlers, all engine-owned;
packs provide data only. Fixed and branching advancement use this same path.
Reclass destinations remain unit-owned. Keep a `promotes_to` import adapter only
while old content exists, and sequence this schema before bulk class transcription.

Trusted handler registrations declare typed required/optional parameters, local
entity-reference targets, consumed advancement-context bindings, and preview versus
mutation behavior. Eligibility facts are typed open-registry entries. Commit records
route, edge, destination, class-variant, and edge-variant ids; restore validates that
record instead of rerunning historical eligibility.

Whole-field variant replacement remains v1 behavior. Authoring preview expands the
effective value and warns when a replacement map removes an inherited key. Optional
localization keys accompany required fallback display names.

## Incremental slices and dependencies

1. **`IMPL-ZERO-CONTENT-FOUNDATION` — inactive boot and atomic session.** Add
   explicit inactive catalogue state; remove unconditional loads from both `_ready`
   methods; keep an opt-in compatibility activation of project data while extraction
   proceeds. Main Menu shows No Packs / invalid-pack diagnostics and disables play.
   Exit: headless engine boots with empty catalogues and can activate/deactivate the
   existing complete Tier-2 fixture atomically.
2. **`IMPL-FORMULA-REGISTRY-V1`** (separate plan) lands the v1-required range, hit,
   cost and requirement registry contracts before weapon/item schemas freeze.
3. **`IMPL-ZERO-CONTENT-FAMILIES` — catalogue expansion.** Add each table row as a
   vertical validator + adapter + cross-reference fixture. Commit families in
   dependency order: registries/media → minimal skill/item identity and local-reference
   schemas → terrain/classes/advancement → full skills/items → weapons → rosters →
   maps/encounters → campaigns. The minimal skill/item stage resolves class unlocks
   and promotion-item parameters without prematurely implementing full behavior.
   Keep compatibility activation green. The class vertical then lands: canonical schema projection,
   source registry and occurrence-audit validation, bounded class/edge variants,
   `ClassAdvancement`, runtime adapter, structured diagnostics, then golden and
   invalid fixtures. Do not begin bulk class transcription before this exit passes.
   Treat exits in two layers: class-contract closure covers provenance, completeness,
   typed descriptors/facts, local skill/item identities, variants, and advancement;
   expanded-pack closure adds maps/campaigns, shared catalogue use, presentation
   warnings, and the separately implemented Awakening pressure profile.
4. **`IMPL-ZERO-CONTENT-BASE-PACK` — extract playable content once.** Build the
   base game as an ordinary self-contained pack, using the same importer/installer/
   selector path as third-party packs. Coordinate with `LEG-AUDIT-FE-NUMBERS-2026-07-20`:
   audited values and provenance move or are retuned once, never copied into two
   authorities. Exit: first end-to-end playable slice selects the base pack, starts
   a campaign, loads a map/roster and finishes one encounter.
5. **`IMPL-ZERO-CONTENT-EXPORT-GATE` — remove compatibility source.** Delete the
   project-data activation and baked playable data only after Slice 4 passes.
   Add export audit proving the engine PCK has no catalogue/playable definitions,
   and pack closure proving all referenced families are contained. Missing/invalid/
   mutated packs remain non-activatable with human-readable errors.

Every commit leaves `agent/integration` bootable. The extraction commit cannot
precede a passing replacement-pack fixture and rollback path.

## Player flows and failure/security cases

- No packs: Main Menu remains usable; New/Load explains how to install/select.
- Invalid pack: package remains listed as disabled with path-safe validator errors.
- Missing family/reference: activation fails before global state changes.
- Multiple packs: explicit selection; current active identity is visible. Installation,
  export, and load-set scans reject exact or case-folded catalogue-id collisions even
  across kinds or inactive packs.
- Removed pack with saves: save remains indexed but disabled; persistence plan owns
  compatible-pack resolution/import behavior.
- Reject traversal, symlinks, duplicate/case-colliding ids/paths, unknown kinds,
  unknown primitive/formula ids, unindexed bytes, and partial activation.
- Equal/case-folded display names or localization keys remain legal, but exporter and
  loader emit severe non-suppressing diagnostics naming every package/entity/path.

## Verification and documentation

- Focused validators/adapters per family; hostile archive and cross-family fixtures;
  atomic activation/deactivation; no-pack boot; invalid/missing-family UI tests.
- Class fixtures prove existing fields pass, unknown fields report exact paths,
  missing/dangling provenance differs from missing occurrence coverage, cross-owner
  and identity variant overrides fail, selected variants round-trip/migrate, and
  cancelled or failed advancement routes mutate nothing.
- Fixture exits also prove draft/complete completeness gates, typed handler/fact
  failures, pack-local skill/item references, variant map-removal warnings, global id
  collision rejection, presentation-name warnings, and recorded-selection restore.
- Export audit compares admitted engine paths against a forbidden playable-family
  list; base-pack closure walks every reference. Full `run_tests.sh` per slice.
- Windows: install/select pack, no-pack/invalid-pack dialogs, New Game and one full
  encounter; check focus, readable diagnostics, and pack identity labels.
- DoD#1: update GDD 01/03/04/05/06/07/08 as affected and GDD 10 plus Feature Index
  in each behavioral slice. Control Plane owns status/sequencing.
- DoD#2: extend `AGENT/Docs/check_docs.py` in the same slice that ratifies the
  engine-export no-content and self-contained-pack rules.

## Exclusions and supersession

No pack scripts, general expressions, dependencies, hidden inheritance, editor
redesign, DLC/store service, or save migration implementation here. Supersede the
“engine owns saves” wording in `campaign_pack_engine_boundary_plan_2026-07-15.md`
with “engine writes user state; package identity owns namespace/interpretation”;
retain its executable-authority and archive-security decisions. This plan refines,
not replaces, the Project Control Plane.
