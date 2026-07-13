# Map Authoring Guide

**Last verified:** 2026-07-13

Use this guide when adding or changing a playable map. It centralizes the
practical authoring steps that are otherwise split across `GDD_01`, `GDD_06`,
`README.md`, and validation notes.

For system rules and player-facing behavior, still read:

1. `AGENT/GDD/GDD_06_Maps_Objectives.md`
2. `AGENT/GDD/GDD_01_Architecture.md`
3. `AGENT/Docs/guides/testing_guide.md`

## Minimum deliverables

A shippable map usually needs all of these:

- a `MapData` resource under `data/maps/<map_id>/`
- a tilemap scene or painted grid referenced by that `MapData`
- any authored enemy / ally / neutral `UnitData` resources the map spawns
- a `data/maps/map_registry.json` entry so the map appears in New Game
- `resource_manifest.json` coverage for any new export-loaded content directory
- tests or manual-validation coverage appropriate to the change

If one of these is skipped, the common failure modes are: map not launchable,
wrong roster loaded, missing units in export builds, or no reliable regression
coverage.

## Folder layout

Follow the existing per-map pattern:

```text
data/maps/<map_id>/
├── <map_id>_data.tres
├── enemies/                # if the map has authored hostile spawns
├── units/                  # if the map has authored non-hostile spawns
└── resource_manifest.json  # if the directory is scanned dynamically in export
```

Examples already in the repo:

- `data/maps/map_001_rout/`
- `data/maps/map_900_hotseat_validation/`
- `data/maps/map_950_promotion_validation/`
- `data/maps/map_002_seize/` through `map_005_defend/`

## `MapData` checklist

The active `MapData` contract is documented in `GDD_06`. In practice, check
these fields first:

- `id`
- `display_name`
- `tilemap_scene_path`
- `grid`
- `camera_start_tile`
- `player_start_tiles`
- `enemy_placements`
- `factions`
- `turn_order`
- `activation_mode`
- `victory_conditions`
- `defeat_conditions`
- `reward_gold`
- `reward_items`

Notes:

- `grid` is the runtime source used to paint terrain. Missing or malformed grid
  data can make the map unloadable.
- `factions` and `turn_order` drive phase order, hostility, labels, and hotseat
  routing. Do not assume a fixed Blue/Red loop.
- `activation_mode` is currently `WHOLE_PHASE` for shipped hotseat content.
- `victory_conditions` and `defeat_conditions` are per-faction-group
  dictionaries, not legacy single-objective fields.

## Objective authoring rules

The current primary objectives in shipped content are:

- `rout`
- `seize`
- `defeat_boss`
- `escape`
- `survive`

Important current rules:

- `seize` is gated by `UnitData.can_seize`, not by class and not by a per-map
  allowlist.
- `escape` removes escaped units from the map; they count alive for survival
  checks but cannot act again this map.
- Early objective-showcase maps are authored with one primary objective each.
- Each map should also author at least one meaningful defeat condition beyond
  relying on a generic rout fallback.

If objective data is underspecified, the usual result is a map that technically
loads but resolves incorrectly or leaves the objective panel misleading.

## Roster policy

The New Game selector does not infer roster behavior from the map folder. It
reads `data/maps/map_registry.json`.

Current roster policies in use:

- `default_roster`
  - Loads the campaign starter roster from `data/roster/default/`
- `fixed_test_roster`
  - Loads the roster from the registry entry's `roster_source`

Use `fixed_test_roster` for validation maps that need pre-staged units, items,
or levels. Use `default_roster` for normal campaign-style maps unless there is
a deliberate reason not to.

Current runtime rule:

- map launch requires a roster explicitly prepared for the selected
  `roster_policy`
- a bad or missing roster no longer falls back to `default_roster` inside
  `GameMap`

## Class and roster authoring

When a map or campaign needs a new class, author `data/classes/<id>.tres` as a
`ClassData` resource and fill every required field. In particular:

- author promotion paths explicitly, using an empty array when none exist;
- give every usable WEXP track both a baseline and an authored
  `weapon_wexp_caps` entry (the project preset defaults to A = 400; S is opt-in);
- declare at least one movement type, using `infantry` as the explicit default;
- update every roster or map unit that references the class;
- extend automated coverage or a validation map when progression, equipment, or
  class-change behavior is affected.

Adding content that uses existing primitives should not require a code change. A new
engine mechanic needs its own design contract and tests rather than a class-specific
runtime branch. `GDD_03` owns class behavior and relationships; `GDD_01` owns the exact
`ClassData`/`UnitData` schemas.

## Registry entry

Every launchable map needs a `data/maps/map_registry.json` entry like:

```json
{
  "id": "map_002_seize",
  "label": "Map 002 - Seize",
  "map_data_path": "res://data/maps/map_002_seize/map_002_seize_data.tres",
  "roster_policy": "default_roster",
  "roster_source": "",
  "description": "Objective showcase map for Seize using the new per-unit can_seize gate.",
  "is_dev_only": false,
  "tags": ["objective_test", "seize"]
}
```

Field expectations:

- `id`: stable internal id
- `label`: player-facing New Game label
- `map_data_path`: exact `MapData` resource path
- `roster_policy`: `default_roster` or `fixed_test_roster`
- `roster_source`: required for `fixed_test_roster`, otherwise usually empty
- `description`: short selector description
- `is_dev_only`: hide or mark validation-only content appropriately
- `tags`: short searchable labels for map purpose

If this entry is wrong, the most common failures are blank selector entries,
maps launching the wrong roster, or the selected map failing to load.

## Export-safe content rules

When a runtime system scans a folder in exported builds, that directory needs a
`resource_manifest.json`. This matters for dynamic content like rosters and map
asset folders that are not loaded only by hardcoded scene references.

Before adding a new dynamically loaded content directory:

1. Check whether sibling directories already carry a manifest.
2. Add or update `resource_manifest.json` if the directory is enumerated at runtime.
3. Re-test the normal launch path, not just editor-opened scenes.

If this step is skipped, the map may work in-editor and fail in export.

## Testing expectations

Every map change needs verification, but not every map needs a new automated
suite.

Use this rough rule:

- Add or update unit tests when code behavior changes.
- Update manual validation coverage when the authored content or player flow changes.
- For new validation maps, document what the map is supposed to prove.

Start from `AGENT/Docs/guides/testing_guide.md` for the full checklist.

## Recommended workflow

1. Author the `MapData` resource and any supporting unit resources.
2. Add or update the registry entry.
3. Check export-safe manifests for any new scanned directories.
4. Launch from the normal New Game flow.
5. Run targeted automated tests if code changed.
6. Run or update the relevant manual validation steps.
7. Fold any new evergreen rules back into `GDD_06` if the runtime contract changed.

## Deceiving the player (hidden-information encounters)

The `[PER]` perception/masking system (see `registers/perception_masking_open_questions_2026-06-27.md`)
is built primarily to deceive the **AI** (mask units, skew threat, blind the forecast). When you want to
pull a similar trick on the **player** — a "harmless villager" who is really the boss, a weak-looking
defender who turns deadly once engaged — you do **not** need engine PER support. Two authoring patterns
work with today's primitives:

- **Real-unit swap via switch-teleport.** Place a genuine *decoy* unit (real stats, really weak). When
  the deceit should be uncovered (the player commits / engages / steps adjacent), **teleport the decoy
  off and the true unit in** on the same tile. The player fought what they saw; the swap reveals the
  truth at the scripted moment. Reuses ordinary unit placement + a teleport/relocate action.
- **Map-event condition change.** Use a **map event (MET)** trigger → action to **change the unit's
  condition/stats** at the reveal moment — e.g. on `unit_died`/an adjacency or attack trigger, apply a
  transform/buff that exposes the unit's real nature. Keep the deceit reversible and authored, not
  hidden engine state.

Pick swap when the *identity* changes (different unit), condition-change when the *same* unit's
threat changes. Both keep the reveal as **authored, deterministic** content — consistent with the PER
rule that deceit affects perception/presentation, never the canonical resolution. When engine-native
player-facing masking lands (`[PER-9]` forecast-fidelity channels, `[PER-12]` appraisal), prefer it for
runtime/per-unit deceit; these patterns remain the tool for **scripted, set-piece** reveals.

## Common mistakes

- Forgetting the `map_registry.json` entry and then testing by scene override only
- Using the wrong roster policy and accidentally validating with leaked test units
- Assuming all hostile units are `"red"` instead of reading authored factions
- Treating `seize` as class-based instead of using `UnitData.can_seize`
- Adding a scanned content directory without a `resource_manifest.json`
- Updating validation content without updating the manual task coverage
