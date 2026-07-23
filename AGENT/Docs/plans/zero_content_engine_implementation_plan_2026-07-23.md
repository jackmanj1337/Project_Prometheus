---
Type: implementation plan
Status: Planned — approved contract; implementation not started
Last verified: 2026-07-23
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
| Classes | Full bases/growths/caps, movement, promotions, skills, sprite ids. | Stat/skill/class/media ids resolve. |
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
   dependency order: registries/media → terrain/classes/skills → weapons/items →
   rosters → maps/encounters → campaigns. Keep compatibility activation green.
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
- Multiple packs: explicit selection; current active identity is visible.
- Removed pack with saves: save remains indexed but disabled; persistence plan owns
  compatible-pack resolution/import behavior.
- Reject traversal, symlinks, duplicate/case-colliding ids/paths, unknown kinds,
  unknown primitive/formula ids, unindexed bytes, and partial activation.

## Verification and documentation

- Focused validators/adapters per family; hostile archive and cross-family fixtures;
  atomic activation/deactivation; no-pack boot; invalid/missing-family UI tests.
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
