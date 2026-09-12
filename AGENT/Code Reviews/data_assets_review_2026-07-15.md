---
Role: dated
---

# Pillar 3 - Scenes, Data & Assets Review (2026-07-15)

> **Pillar:** 3 - Scenes, Data & Assets
> **Procedure:** `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md`
> **Snapshot:** branch `agent/codex/2026-07-15/prep-save-followup`, commit `08b3b5c2aa5dfb1e773a87d07890b9c7629ef1b3`
> **Audit baseline:** clean pinned tree; `check_docs.py` 35/35 PASS; `run_tests.sh` 98 suites PASS
> **Previous review:** `AGENT/Code Reviews/data_assets_review_2026-07-05.md`

**Score:** 10/10

## Executive Summary

No actionable scene, resource, data, asset-import, autoload, UID, or directory
defect was found at the pinned snapshot. The campaign/save branch adds six UI
scenes, the five-node Proving Grounds campaign, three registry families, a shared
UI theme, and a substantial set of draft UI assets without introducing dangling
paths or manifest drift. The prior review's sole low-severity issue, Map 950's
stale hardcoded roster count, is fixed. The content pillar is exemplary at this
snapshot.

## Spot-Check / Sample

- **Scene wiring:** ran `python3 scripts/ci/check_scene_integrity.py`; all 22
  scene-attached scripts with `@onready` `$` paths passed. Inspected all 23
  `scenes/**/*.tscn` files for script and nested `ext_resource` paths; zero missing
  paths. Manually checked the relative `_vbox.get_node(...)` paths in
  `scripts/ui/SettingsScreen.gd` against `scenes/ui/SettingsScreen.tscn`.
- **Resources and data:** scanned all 188 repository `.tres` resources and all
  `res://` references in live `.tscn`, `.tres`, JSON, project, and import metadata.
  No live content reference targets a missing path. Checked every one of the 11
  `data/**/resource_manifest.json` files against its sibling content; no missing
  or extra entries. The catalogue families remain 24 classes, 12 weapons, 8
  items, and 54 skills.
- **Campaign graph:** exhaustively checked `data/campaigns/proving_grounds.json`:
  the start node exists, all five node IDs are unique and reachable, all `next`
  links resolve, and every `map_id` resolves through `data/maps/map_registry.json`
  to an existing `MapData` resource.
- **Registry data:** inspected all 10 `RegistryEntry` resources under
  `data/registries/`; IDs are unique within their families, family values match
  their directory/manifests, and each resource points to the existing
  `scripts/resources/RegistryEntry.gd` class.
- **Imports/assets:** checked all 176 PNG/font/audio-style source assets under
  `assets/`, `Draft UI assets/`, and documentation evidence. Every source has a
  sibling `.import`, and no `.import` is orphaned. The three live theme references
  and the three source paths in `assets/themes/manasoul_ui.tres` resolve.
- **Autoloads:** checked all 22 `[autoload]` entries in `project.godot`; every
  registered script exists. Provider-style shared services precede the campaign,
  save, condition, handler, resolver, AI, and Pair Up consumers.
- **UIDs:** full disk-versus-git scan found 220 `.gd` files and 220 tracked
  `.gd.uid` sidecars, with no missing, untracked, or orphan sidecar. `.gitignore`
  does not exclude UIDs. Resource/scene UID headers were treated as inline and
  optional rather than incorrectly expecting `.tres.uid` sidecars.
- **Directories:** inspected all top-level directories and searched for empty
  directories outside ignored/generated trees; no stray or empty directory was
  found.
- **Godot load check:** `godot --headless --editor --quit --path .` completed its
  project scan with no project-resource parse/load error. It did emit environment
  errors because `/home/vscode/.cache/godot` is unwritable; these are tool-host
  constraints, not repository findings.

## Issues

No actionable issues found.

## Positive Observations

1. **The campaign content graph is internally complete.** The five chapters in
   `data/campaigns/proving_grounds.json` form one reachable linear graph and every
   node resolves through the map registry to shipped map data.
2. **The large UI/content delta preserved scene integrity.** Six new scenes and
   extensive edits to existing menus increased the scene set from the prior
   review without producing a broken attached script, nested scene, or
   `@onready` node path.
3. **Import and UID hygiene is exact.** All 176 importable source assets have
   imports, none are orphaned, and all 220 script sidecars are tracked one-for-one.
4. **Open registry data is well-formed.** The action primitive, occupancy policy,
   and resource-type manifests exactly match their resource directories, with
   unique IDs and explicit metadata/test fixtures.
5. **The prior metadata drift is resolved robustly.** Map 950's description at
   `data/maps/map_registry.json:38` no longer embeds a roster count, so future
   fixture growth cannot make the description stale in the same way.

## Prioritized Action Plan

There is no defect-driven action required before pushing this snapshot.

1. Keep `scripts/ci/check_scene_integrity.py`, manifest checks, UID tracking, and
   clean-import validation in the regular gates.
2. As a future enforcement improvement, extend the scene-integrity gate to parse
   static relative `get_node(...)` expressions in addition to `@onready` `$`
   expressions; this audit checked the current Settings-screen cases manually.
3. Perform the already-planned Windows visual pass for the new Prep, Load,
   Results, Campaign Library, and rule-notification scenes. That is presentation
   validation, not evidence of a structural defect in this pillar.

## Delta Vs Previous Review

- **Fixed:** the prior Low finding in `data/maps/map_registry.json:38`; the Map 950
  description no longer says the 12-unit roster contains 10 units.
- **New:** no scene/data/asset findings.
- **Regressed:** none. The previously fixed UID, import, scene-integrity, and
  manifest issues remain fixed.
- **Scope growth:** 23 scenes now exist (up from the prior review's 17 reported
  scene-attached scripts), with new campaign/save UI scenes and campaign/registry
  data all passing structural checks.

## Procedure Friction

- The requested godot-analyzer MCP service was not exposed in this execution
  environment. The repository's `scripts/ci/check_scene_integrity.py` reuses the
  same in-repo analyzer implementation for `@onready` paths; local structural
  scans and Godot's headless editor covered the remaining checks.
- The available scene-integrity gate validates `@onready` `$` expressions but not
  relative `_vbox.get_node("...")` expressions. Those static Settings-screen
  paths required manual scene comparison. Extending the analyzer would remove
  this recurring manual seam.
- A naive whitespace-delimited `res://` scan misreads paths containing spaces in
  `.import` metadata (notably `Draft UI assets/`). Import checks must parse the
  quoted `source_file`/`path` values or operate on source/import sibling pairs.
- Godot's editor scan cannot write `/home/vscode/.cache/godot` in this container,
  so it logs editor-cache errors despite completing the project scan. A writable
  isolated HOME/cache would make this check quieter and its exit status more
  diagnostic.
