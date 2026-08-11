---
Type: plan
Status: In progress
Last verified: 2026-08-01
Tracker: IMPL-ZERO-CONTENT-FAMILIES
---

# Next-session handoff — zero-content Maps/encounters family

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md),
with cross-branch state in `coordination/tasks.json` under
`IMPL-ZERO-CONTENT-FAMILIES`.

Continue `IMPL-ZERO-CONTENT-FAMILIES` on
`agent/from-integration/zero-content-families-class`. The class, weapon, and roster
verticals are the dependency base; do not reopen them while adding maps.

## State entering the session

`class`, `advancement_edge`, `advancement_route`, `weapon`, and `roster` are
registered engine-owned schemas with trusted handler admission, open value **and**
key vocabularies, occurrence-audit binding, package-local cross-references, and
Tier-2 runtime adoption. Every durable authored selection a unit can carry —
class variant, advancement edge, edge variant, and per-slot weapon variant —
resolves against the document that owns it during whole-pack validation and
round-trips through the one `SaveCodec` snapshot.

`map_data` is still on the legacy shape check in `CampaignTier2Validators`: it
verifies a matching id, a `display_name`, a non-empty `grid`, and non-empty
`player_start_tiles`. Everything a map actually plays with — enemy placements,
factions, turn order, activation mode, objectives, rewards, camera — is
unvalidated. This is the largest remaining unvalidated surface in the pack.

## 1. Freeze the map/encounter v1 envelope

Project the existing `MapData` surface into `EntitySchemaRegistry`, as the class,
weapon, and roster schemas do. The plan's migration matrix splits **Battle maps**
(grid, terrain cells, start/objective tiles, asset ids) from **Encounters**
(factions, turn order, placements, objectives, rewards, overrides), but `MapData`
holds both today. Decide explicitly whether v1 registers one `map_data` document or
two, and record the reason — the cheaper answer is one document matching the
resource, with the split deferred until an encounter is authored independently of
its terrain.

Two nested shapes need real schemas, not `additional_properties: {}`:

- **`enemy_placements`** — an `Array[Dictionary]` whose entries carry an inline
  `unit` object today. That inline unit is the same surface the `roster` schema
  already describes; **reuse the unit object schema rather than authoring a second
  one**, or the two will drift. Placements add `tile`, `faction`, `is_boss`, and an
  `ai_profile` override (omission preserves the unit's own profile — see
  `GameMap._resolve_placement_unit_data` and the `[PUG-3]` spawn seam).
- **`victory_conditions` / `defeat_conditions`** — a Dictionary keyed by alliance
  group, each value an array of `ObjectiveCondition`. The keys are author-defined
  group names, so this is a place a **key vocabulary would be wrong**; validate the
  values and cross-check the group names against the map's own `factions`.

`activation_mode` (`WHOLE_PHASE` / `ALTERNATING`) is a closed engine vocabulary and
should be registered as one rather than written as an inline `enum`.

## 2. Objective conditions are the open-registry test

Objective conditions are the canonical `[TCV-4]` example in `AGENTS.md`: they must
resolve through a registry, never a `match`. Check what `ObjectiveCondition` already
does before designing anything — if it still keys off a closed type field, adding
the schema is the moment to register the condition handlers the way
`register_handler` seeded `class_advancement_v1`, so a new objective is a
registration rather than an engine edit.

## 3. Carry the one open deferral

**Asset/item cross-references.** Still open, and still deliberately deferred.
`WeaponData.icon` and `ClassData.sprite_id` are plain strings because the campaign
Tier-2 validator set has no `media`/`asset_registry` kind. Rosters needed none
(`UnitData` has no sprite/portrait property), but maps carry `tilemap_scene_path`
and terrain/asset ids, so **this family is where the media identity schema probably
has to land**. Add the smallest one the map actually needs; do not design the whole
Media family inside this change.

Also still open, from the roster family: inventory slots admit weapons only — item
and equip slots wait for the Items family identity schema.

## 4. Adopt the runtime adapter vertically

`CampaignTier2RuntimeAdapter._build_maps` already excludes the structured fields
from the plain property copy and converts them explicitly. Re-check each conversion
against the schema you register; the traps proven twice now still apply:

- `Array[String]` exports (`grid`, `reward_items`, `turn_order`) are **silently
  left empty** by `Object.set()` with a raw JSON array. These three are already
  converted with `_strings()` — keep it that way, and check `factions` (an
  `Array[FactionData]`, currently not built at all by the adapter).
- JSON decodes every number as a float; use
  `EntitySchemaRegistry.normalize_json_integers` for anything handed to a registry
  that requires true integers.

`_enemy_placements` builds its `UnitData` through `_apply_unit_properties`, so it
already inherits the roster family's typed-array and integer handling.

## 5. Fixtures and exits

Extend the in-code Tier-2 pack fixture used by
`test_campaign_tier2_runtime_adapter.gd` with a registered map, and add narrow
invalid siblings to `test_entity_schema_registry.gd` for: an unknown field inside
`enemy_placements[i]` and inside a condition, an out-of-bounds placement tile, a
`turn_order` naming a faction the map does not declare, an objective group that is
not an alliance group, and an unregistered objective condition handler.

Exit only when focused tests, the full suite, GDScript formatting, documentation
checks, and the tracker are green. Update GDD_05 (or whichever chapter owns map and
objective authoring — check `GDD_Feature_Index.md`) and GDD_10 in the behavior
commit.

## Watch-outs

- Compatibility packs (`test_fixtures/campaign_packs/*`) carry no `schema_version`
  and must keep activating. The weapon and roster validators dispatch on its
  presence — follow that pattern rather than deleting the legacy check.
- Do not use the baked `data/` map values as public fixtures; the FE-number audit
  and base-pack extraction own their eventual destinations.
- The class family's growth/cap maps validate values but not keys. That is the
  cheapest follow-up available and should be taken the next time the class family is
  opened for another reason — not as an unprompted reopen.
