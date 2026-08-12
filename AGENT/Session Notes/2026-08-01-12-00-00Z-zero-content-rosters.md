# Session Note - 2026-08-01-12-00-00Z-zero-content-rosters

## Branch context

- Branch: `agent/from-integration/zero-content-families-class`
- Base branch: `agent/integration`
- Base SHA: `a8a558bc19cb9402804b2b369fa8355b4e3f802f`
- Coordination Work ID: `IMPL-ZERO-CONTENT-FAMILIES`

## What was done

Picked up the Rosters handoff
(`AGENT/Docs/plans/zero_content_rosters_handoff_2026-07-31.md`, now archived) and
landed the Rosters/units vertical of zero-content Slice 2.

**Envelope (handoff §1).** `roster` version 1 is a registered engine-owned schema
projecting the existing `UnitData` surface. The handoff left the document-shape
question open — one `roster` document with a `units` array, or one `unit` document
each — and it was answered as `roster`, because the catalogue already indexes
rosters by id and cross-references `roster.units[].class_id`, so per-unit documents
would have added a second identity layer for nothing. `units` is validated as a
nested array with `unique_key: "unit_id"`.

Two fields the handoff listed were **deliberately not admitted**, and this is the
part worth reading:

- **`faction`.** `UnitData` has no such property. Faction lives on a map's enemy
  placement, not on the unit, so admitting it would have authored a field nothing
  reads — exactly the silent-drop failure the handoff's own §1 warns about.
- **Sprite / portrait ids.** Same reason: `UnitData` has neither. This also means
  handoff §3's asset-identity ask has no roster-side subject at all (see below).

Runtime/battle state (`conditions`, `active_modifiers`, `is_incapacitated`,
`is_default_roster`) is not authorable either; it is engine-written.

**Validation (handoff §2).** The open vocabulary registry gained a **key** form:
`{"key_vocabulary": "<id>"}` on an object schema validates the map's KEYS, not just
its values. `growth_rates`, `growth_accumulators`, and `weapon_wexp` use it, seeded
from `StatRegistry.GROWTH_STAT_IDS` and the `wexp_track` registry the weapon family
already registered — extended, not duplicated, as the handoff asked. This closes a
real hole: an authored `strenght: 40` was previously admitted by any value-only map
check and then silently never rolled. `ai_profile` resolves through
`AIProfileRegistry.PROFILES` on the same seam, so the engine's AI vocabulary stays
one list. Positive HP is enforced in the schema (so the diagnostic carries a path)
rather than only in the runtime adapter, plus HP within the unit's own maximum,
unique unit ids, inventory `uses` of -1 or at least 1, and an edge-variant selection
that names the edge it belongs to.

**Durable weapon-variant selection (handoff §3) — closed.**
`InventoryEntry.weapon_variant_id` records the choice per slot. Whole-pack
validation resolves it, and `class_variant_id` / `advancement_edge_id` /
`advancement_edge_variant_id`, against the document that actually owns the variant —
not just against the id index — so a selection whose target was deleted rejects the
pack instead of surviving as an id pointing at nothing. It round-trips through the
one `SaveCodec` snapshot used by campaign save, suspend, Retry, and Rewind. Saves
written before the field existed carry no key and load as the base weapon.

**Runtime adoption (handoff §4).** `_build_rosters` and `_enemy_placements` now
share `_apply_unit_properties`, which converts the typed `Array[String]` exports
(`skills`, `earned_skills`, `reclass_options`) with `_strings()` and narrows the
JSON-float stat maps with `normalize_json_integers` — both traps the Weapons session
measured. The same silent-empty trap on `ClassData` was repaired, and for all
**four** admitted string lists rather than only `allowed_weapon_families`: the
handoff named one, but `class_groups`, `special_qualities`, and
`vulnerability_groups` fail identically and are admitted by the same class schema.

**Deferred deliberately, and NOT forced closed:** handoff §3's asset/item
cross-references. The handoff asked for "the smallest asset-identity schema the
roster actually needs" — the honest answer is *none*, because `UnitData` has no
sprite or portrait property. Building one here would have invented a surface to
justify the deferral rather than resolve it. `WeaponData.icon` and
`ClassData.sprite_id` stay plain strings until the Media family; maps carry
`tilemap_scene_path` and terrain asset ids, so the successor handoff names
Maps/encounters as the likely landing place. Inventory slots also admit weapons
only — item and equip slots wait on the Items family identity schema.

**One thing left open on purpose:** the class family's `player_growth_rates`,
`enemy_growth_rates`, `stat_caps`, and `weapon_wexp_bases`/`_caps` still validate
values but not keys. Retrofitting the new key vocabulary onto them would be a
one-line change each, but the handoff said not to reopen the closed class vertical,
so it is recorded in the plan and the successor handoff as the first follow-up to
take the next time that family is opened for another reason.

Archived the Rosters handoff and wrote
`AGENT/Docs/plans/zero_content_maps_encounters_handoff_2026-08-01.md`, repointing
the control plane at it.

## Commits claimed

- `15f0a642e461b0ab67f5117470fe282dd48e290e` — Add the Tier-2 roster schema and adopt it through the runtime
- `91062daacbfbeb45c19c6f84d227c3c5fddef466` — Record the Tier-2 roster family and hand off Maps/encounters

## Gates

- `godot --headless --script scripts/tests/test_entity_schema_registry.gd` —
  44 passed, 0 failed (was 38; +6 roster cases).
- `godot --headless --script scripts/tests/test_campaign_tier2_runtime_adapter.gd` —
  8 passed, 0 failed (was 6; +1 roster runtime-parity case, +1 dangling-selection
  rejection).
- `godot --headless --script scripts/tests/test_save_codec.gd` — 8 passed, 0 failed
  (was 7; +1 pre-variant save case, plus the variant added to the weapon round-trip).
- `godot --headless --script scripts/tests/test_campaign_package_catalogue.gd` —
  7 passed, 0 failed (unchanged; proves compatibility packs still activate).
- `bash run_tests.sh` — PASS: all suites green.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 260 tracked files.
- `python3 AGENT/Docs/check_docs.py` — PASS: all documentation checks green
  (after `gen_docs_index.py`).

## Next

Maps/encounters, per
[`zero_content_maps_encounters_handoff_2026-08-01.md`](../Docs/plans/zero_content_maps_encounters_handoff_2026-08-01.md).

Note for whoever takes it: this branch is 3 commits behind `agent/integration`,
which now carries the `pre-commit` docs-line guard fencing `AGENT/Docs/plans/` off
feature branches. This branch's plan and handoff edits predate that guard and were
made in the same place the previous two sessions used. Merging `agent/integration`
in will fence further plan edits here (override: `DOCS_GUARD_OVERRIDE=1`), so decide
that deliberately rather than as a side effect of a routine base merge.
