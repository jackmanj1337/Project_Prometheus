# Session Note - 2026-08-05

## Branch context

- Branch: `agent/from-integration/proving-grounds-extractor`
- Base branch: `agent/integration`
- Base SHA: `c2e78cd2` (merged forward at the start of the session)
- Coordination Work ID: `IMPL-ZERO-CONTENT-BASE-PACK`

## What was done

Finished the code slice that makes an extracted campaign pack **playable**, so the
v0.7.0 bundle can ship one instead of shipping a pack that opens an empty board.

**The extractor emits encounters.** `extract_proving_grounds_pack.gd` wrote maps as
grid plus `player_start_tiles` and nothing else: no enemies, no factions, no turn
order, no objectives, no rewards. It now joins each `BattleMapDef` to its
`BattleEncounterDef` — the same join `DataManager`'s own boot projection does — and
inlines each placement's `UnitData` as the unit object the map schema already reuses
from the roster schema. Nothing new was needed on the runtime side: the registered
`map_data` schema and `CampaignTier2RuntimeAdapter` have admitted the whole encounter
surface since the families slice. Only the producer was missing.

**Rosters were equally thin.** Inventories were not emitted at all, so no unit in the
pack carried a weapon — a pack that validated and could not fight. One shared
`_unit_object()` projection now serves roster units and placement units, so the two
cannot drift, and it carries inventory, growths, WEXP, skills, reclass options,
`class_line_id`, constitution, line of sight, gold and `can_seize`.

**One engine defect, found by extracting real content.** `select_tier2_campaign_source`
shared a single `seen_unit_ids` table across every map in a pack, so two maps re-using
an enemy archetype id failed activation. The engine's own content does exactly that —
`map_001` and `map_001_c3_factions` share all eight enemies — and only one map is ever
loaded, so no runtime rule needs the wider scope; the project-data path already scopes
it per map registry entry. The table is now per map, seeded with the units of every
roster a `map_registry` row binds to that map, which keeps the collision that actually
matters (a roster unit colliding with an enemy on the map it deploys onto). Both cases
are covered in `test_campaign_tier2_runtime_adapter.gd`.

**`validate_pack.gd` now means what its header claimed.** It said passing implied
`DataManager` could activate the pack, but it only ran the adapter — map *semantics*
(tile bounds, terrain codes, faction coherence, duplicate unit ids, objective
validity) are checked at activation and were never exercised. It activates now. It
also reports **playability** separately, because activating is not playing: a map with
no enemies and no victory condition breaks no rule, and neither does a side whose
units carry no weapon the pack resolves. Both were true of the previous extraction and
neither was visible. `--require-playable` turns them into an exit code.

Both packs were regenerated and both validate: 8/8 maps playable, every roster armed.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

`3be76253` scopes pack unit-id uniqueness to one battle and adds the two regression
cases. `67079a10` is the extractor change (encounters + the shared unit projection).
`30975d5c` rewrites `validate_pack.gd` to validate through activation and to report
playability. The plan's Slice 4 status paragraph is updated in the same change set.

## Gates

- `bash run_tests.sh` — all suites green (run three times through `agent-commit.sh`;
  one run showed `test_campaign_pack_exporter` red under parallel contention and it
  passed in isolation, which is the documented way to tell contention from a defect).
- `godot --headless --script res://scripts/tools/validate_pack.gd -- --pack <pack>
  --require-playable` — exit 0 for both packs:
  - `Campaign_Pack_FE/packs/proving_grounds` (internal): activates, 8/8 playable,
    rosters 6/2/12 units, none unarmed.
  - `Campaign_Pack_0/packs/proving_grounds` (public, regenerated through
    `retune_public_pack.py`): same.
- Emitted values spot-checked against their source resources (`m003_fighter_1`:
  level 3, max_hp 21, strength 9, constitution 11 — all match the `.tres`).

## Next

`IMPL-ZERO-CONTENT-BASE-PACK` stays open. Its exit is "finishes one encounter", and
nobody has finished one — that is the human-with-a-display step the v0.7.0 bundle
buys. The pack is no longer the thing blocking the bundle's §6.

Still absent from the pack, reported as gaps rather than assumed: skills (units carry
ids nothing in the pack resolves, so they answer against the engine set), pair-up, and
fog — an encounter authoring `fog_enabled` extracts as a clear map, because the
`map_data` schema admits no such field. Adding it belongs with `IMPL-FOG-RENDER`.
