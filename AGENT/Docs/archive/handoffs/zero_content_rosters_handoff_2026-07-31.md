---
Type: handoff
Status: Superseded
Last verified: 2026-08-01
Tracker: IMPL-ZERO-CONTENT-FAMILIES
---

> **Superseded** by [the Maps/encounters-family handoff](../../plans/zero_content_maps_encounters_handoff_2026-08-01.md).
> Sections 1, 2, 4, and 5 are implemented, and section 3's durable weapon-variant
> selection is closed. Section 3's asset/item cross-reference deferral is **not**
> closed and was not forced to: `UnitData` has no sprite or portrait property, so a
> roster needs no asset reference — it moves on to the Media family unchanged.

# Next-session handoff — zero-content Rosters/units family

**Managed by:** [`project_control_plane_2026-06-29.md`](../../plans/project_control_plane_2026-06-29.md),
with cross-branch state in `coordination/tasks.json` under
`IMPL-ZERO-CONTENT-FAMILIES`.

Continue `IMPL-ZERO-CONTENT-FAMILIES` on
`agent/from-integration/zero-content-families-class`. The class and weapon
verticals are the dependency base; do not reopen either while adding Rosters.

## State entering the session

`class`, `advancement_edge`, `advancement_route`, and `weapon` are registered
engine-owned schemas with trusted handler admission, open vocabularies, complete
occurrence-audit binding, package-local cross-references, and Tier-2 runtime
adoption. A validated weapon document adapts into `WeaponData` with the same
range/equip/combat inputs the JSON authored.

`roster` is still on the legacy shape check in `CampaignTier2Validators`: it
verifies a non-empty `units` array, unique `unit_id`, and a present `class_id`,
and nothing else. Every stat, growth, inventory, and authored-state field on a
Tier-2 unit is currently unvalidated.

## 1. Freeze the Roster/unit v1 envelope

Project the existing `UnitData` surface into `EntitySchemaRegistry` rather than
inventing parallel names — the runtime adapter writes admitted field names
straight onto the resource, so a divergent name is a silently dropped field.
Admit identity, faction, level and EXP, the stat block, growths, WEXP totals,
inventory, skills, reclass options, AI profile, sprite/portrait ids, and the
durable advancement selections (`class_variant_id`, `advancement_edge_id`,
`advancement_edge_variant_id`) that the class vertical already round-trips.

A roster document holds many units, so decide up front whether the registered
schema is `roster` (one document, `units` array) or `unit` (one document each).
The catalogue already indexes rosters by id and cross-references
`roster.units[].class_id` and `.inventory[].weapon_id`, which argues for keeping
`roster` as the document and validating `units` as a nested array.

## 2. Validate semantics and references

- Reject unknown fields with exact entity-qualified paths, including inside
  `units[i]` and `units[i].inventory[j]`.
- Validate stat ids through `StatRegistry` and WEXP track keys through the
  `wexp_track` vocabulary registered for weapons — extend that registry, do not
  add a second list.
- Enforce positive `hp`/`max_hp` in the schema rather than only in the runtime
  adapter, so the diagnostic carries a path.
- Keep the existing class/weapon cross-references and add package-local skill and
  item references once those families have identity schemas.

## 3. Carry the two Weapons deferrals

Both were deliberately left out of the Weapons change and belong here:

- **Durable weapon-variant selection.** Weapon variants are validated but nothing
  selects one. The selection belongs on `InventoryEntry` (alongside
  `weapon_id`/`uses`), written where inventory is authored and restored through
  the same `SaveCodec` snapshot as `UnitData.class_variant_id` — save, suspend,
  Retry, and Rewind must all restore it without re-evaluating eligibility.
- **Asset/item cross-references.** `WeaponData.icon` and any unit sprite/portrait
  id are admitted as plain strings because the campaign Tier-2 validator set has
  no `media`/`asset_registry` kind. Add the smallest asset-identity schema the
  roster actually needs; do not design the Media family inside this change.

## 4. Adopt the runtime adapter vertically

`CampaignTier2RuntimeAdapter._build_rosters` already applies class bases then
overlays authored properties. Two traps proven by the Weapons work apply again:

- `Array[String]` exports (`skills`, `earned_skills`, `reclass_options`) are
  **silently left empty** by `Object.set()` with a raw JSON array — convert them
  explicitly with `_strings()`, as `effect_tags` now is.
- JSON decodes every number as a float. Use
  `EntitySchemaRegistry.normalize_json_integers` for anything handed to a
  registry that requires true integers.

`ClassData.allowed_weapon_families` has the same typed-array trap and is still
unconverted in `_build_classes`; fix it in this change rather than leaving a
known-silent field.

## 5. Fixtures and exits

Extend the same in-code Tier-2 pack fixture used by
`test_campaign_tier2_runtime_adapter.gd` with a registered roster, and add narrow
invalid siblings to `test_entity_schema_registry.gd` for unknown fields inside
`units[i]`, an unknown stat/track key, non-positive hp, a dangling class/weapon
reference, and a durable selection that does not resolve.

Exit only when focused tests, the full suite, GDScript formatting, documentation
checks, and the tracker are green. Update GDD_03 and GDD_10 in the behavior
commit.

## Watch-outs

- Compatibility packs (`test_fixtures/campaign_packs/*`) carry no
  `schema_version` and must keep activating. The weapon validator dispatches on
  its presence — follow that pattern rather than deleting the legacy check.
- Do not use the baked `data/` roster values as public fixtures; the FE-number
  audit and base-pack extraction own their eventual destinations.
