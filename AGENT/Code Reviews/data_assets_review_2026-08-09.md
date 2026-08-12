# Pillar 3 — Scenes, Data & Assets Review (2026-08-09)

> **Pillar:** 3 — Scenes, Data & Assets
> **Procedure:** `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md`
> **Snapshot:** `agent/integration` at `41c0e5fc1116a9a01aed3afc48dbc92f021d018d`
> **Audit baseline:** clean pinned source; documentation 43/43 PASS; all 135 suites PASS
> **Previous review:** `AGENT/Code Reviews/data_assets_review_2026-07-15.md`

**Score:** 10/10

## Executive Summary

No actionable scene, resource, data, asset-import, autoload, UID, or directory
defect was found at the pinned snapshot. The pillar grew substantially since July:
the project now has 25 scenes, 221 `.tres` resources, split battle-map/encounter
catalogues for all eight maps, seven authored objective predicates, five item effects,
and 313 script UID sidecars. Exhaustive path, manifest, ID, import, UID, campaign-graph,
and clean-editor scans were green, as were 129 focused assertions over the live data
catalogues and their runtime adapters.

The only Pillar 3 differences between the pinned snapshot and frozen v0.7.1 candidate
`0db30fd17adb83fb7e912c57b7630933c31588d6` are
`scenes/ui/MainMenu.tscn` and `scenes/units/Unit.tscn`. Neither contains an audited
defect. The latter is the post-freeze `AnimatedSprite2D` conversion, so it cannot
affect that frozen candidate.

## Scope and Evidence

### Scene wiring

- Exhaustively scanned all 25 tracked `.tscn` files. Every attached script, nested
  `PackedScene`, texture, TileSet, and other `ext_resource` path exists; zero broken
  external resource paths were found.
- `python3 scripts/ci/check_scene_integrity.py` validated all static `@onready` `$`
  paths across 23 scene-attached scripts and passed.
- Manually reconciled all nine serialized `NodePath` exports on
  `scenes/core/GameMap.tscn:44-52` against their instantiated nodes at lines 67-126.
- Inspected the two newly added scenes: `scenes/ui/RewindSelector.tscn:5-54` and
  `scenes/ui/text_entry/GridKeyboard.tscn:6-11`. Their attached scripts exist and
  their shallow node contracts agree with the runtime paths covered by the scene
  integrity gate.

### Resources, catalogues, and cross-references

- Loaded the entire project with
  `godot --headless --editor --quit --path .` under an isolated writable cache. It
  exited 0 with no scene/resource parse or load error, covering all 221 `.tres`
  resources and their current script-class fields.
- Exhaustively checked IDs in the six primary resource families: 24 classes, eight
  items, 55 skills, 16 weapons, eight `BattleMapDef` resources, and eight
  `BattleEncounterDef` resources. Every resource has a non-empty ID and each family
  has zero duplicates.
- Exhaustively checked all five open-registry families: one action primitive, five
  item effects, seven objective conditions, seven occupancy policies, and two
  resource types. IDs are unique per family; every entry's `family` matches its
  directory; required handler/kind fields are populated. For example, the new
  objective record at `data/registries/objective_conditions/defeat_boss.tres:4-11`
  names the correct family and primitive.
- All 15 `resource_manifest.json` files exactly enumerate their sibling catalogue
  files with no missing or extra entry. Focused `test_data_manager` coverage also
  passed its live catalogue, map registry, duplicate-ID, bad-reference, and content
  activation checks (29 assertions).
- Exhaustively reconciled the eight map-registry rows at
  `data/maps/map_registry.json:1-98` with their `MapData`, `BattleMapDef`, encounter,
  and roster paths. Every path and ID resolves.
- The five Proving Grounds nodes at
  `data/campaigns/proving_grounds.json:8-40` have unique IDs, are all reachable from
  the start node, have only resolving successor links, and reference existing
  encounter IDs. All encounter placement resource paths resolve and placement tiles
  are unique within each encounter.
- Focused compatibility checks passed: `test_registry_manager` (9 assertions),
  `test_battle_encounter_def` (45), `test_campaign_manager` (44), and
  `test_unit_inventory_refs` (2). Together with `test_data_manager`, this was 129
  passing focused assertions and zero failures.

### Assets, imports, UIDs, autoloads, and directories

- All 125 tracked importable source assets in the live `assets/` and
  `Draft UI assets/` trees have sibling `.import` metadata; no live import is
  orphaned. The three new PWA icons and imports are paired. Documentation evidence
  trees are intentionally excluded from Godot by tracked `.gdignore` files.
- Every one of the 313 tracked `.gd` scripts has exactly one tracked `.gd.uid`
  sidecar. There are no missing, untracked, or orphan UIDs, and `.gitignore` does not
  suppress them.
- All 28 autoload paths at `project.godot:27-56` exist. Provider services precede
  the state/content/campaign/save consumers, which precede handlers and combat/AI
  consumers; the clean editor scan instantiated them without a load failure.
- The tracked top-level tree matches the baseline coverage map. The only empty
  top-level directory is ignored generated output `ui_previews/`; no tracked stray or
  misplaced resource directory was found. Root `default_bus_layout.tres` and the two
  TileSet resources under `assets/` parse and are intentional project resources.

## Issues

No actionable issues found.

## Positive Observations

1. **The map split retained exact compatibility.** All eight authored map/encounter
   pairs resolve both through the split catalogues and the legacy adapter, with terrain,
   deployment, placement, rules, and rewards equivalent across 45 focused assertions.
2. **Open content registries are internally disciplined.** The new objective and item
   effect families carry unique IDs, family identity, handlers, documentation keys, and
   manifest membership without reintroducing a closed authoring switch into the data.
3. **Campaign graph integrity is exact.** Every Proving Grounds node is reachable and
   every node, successor, encounter, map, roster, and unit inventory reference resolves.
4. **Large source growth preserved repository hygiene.** Scene paths, imports, UIDs,
   manifests, and project loading all remain exact after adding 33 `.tres` resources,
   two scenes, three PWA assets, and substantial scene edits since the July snapshot.

## Prioritized Action Plan

There is no defect-driven action for this pillar.

1. Keep scene integrity, live catalogue validation, split-map compatibility, UID
   tracking, and clean project loading in the required gates.
2. Extend the scene-integrity analyzer when practical to cover serialized exported
   `NodePath` properties and static relative `get_node(...)` calls, which remain a
   small manual review seam.
3. Preserve the existing `.gdignore` boundary around playtest screenshots so evidence
   files do not enter the runtime import pipeline.

## Delta Vs Previous Review

- **Fixed:** no carried Pillar 3 defect remained open from 2026-07-15.
- **New:** no actionable scene/data/asset finding.
- **Regressed:** none. Scene paths, catalogue manifests, imports, UIDs, autoloads, and
  the campaign graph remain clean.
- **Scope growth:** scenes increased from 23 to 25; `.tres` resources from 188 to 221;
  tracked script/UID pairs from 220 to 313. The data delta includes split battle
  map/encounter resources for eight maps, seven objective-condition entries, five item
  effects, four weapons, and one skill.
- **Frozen v0.7.1 applicability:** no finding applies. The post-freeze Unit scene
  conversion is integration-only and is structurally valid; the audit did not modify
  the frozen candidate.

## Procedure Friction

- The requested godot-analyzer MCP service was not exposed in this environment. The
  repository scene-integrity checker, direct structural scans, focused Godot suites,
  and a clean headless editor load covered the same required evidence without mutating
  audited content.
- `scripts/ci/check_scene_integrity.py` validates `@onready` `$` paths but still does
  not cover serialized exported `NodePath` values or relative `get_node(...)` calls;
  the nine live serialized values required manual reconciliation.
- The procedure's blanket asset/import wording needs the existing `.gdignore`
  distinction: screenshots under ignored evidence directories correctly do not carry
  `.import` files, while every live runtime asset does.
