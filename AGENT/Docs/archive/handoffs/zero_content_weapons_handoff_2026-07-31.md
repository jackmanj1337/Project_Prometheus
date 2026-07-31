---
Type: handoff
Status: Superseded
Last verified: 2026-07-31
Tracker: IMPL-ZERO-CONTENT-FAMILIES
---

> **Superseded** by [the Rosters-family handoff](../../plans/zero_content_rosters_handoff_2026-07-31.md).
> Sections 1-3 and the fixture/exit list in section 4 are implemented; the two
> deferrals (asset/item cross-references, durable weapon-variant selection) are
> carried forward in the successor.

# Next-session handoff — zero-content Weapons family

**Managed by:** [`project_control_plane_2026-06-29.md`](../../plans/project_control_plane_2026-06-29.md),
with cross-branch state in `coordination/tasks.json` under
`IMPL-ZERO-CONTENT-FAMILIES`.

Continue `IMPL-ZERO-CONTENT-FAMILIES` on
`agent/from-integration/zero-content-families-class`. The completed class vertical
is the dependency base; do not reopen it while adding Weapons.

## State entering the session

Class, advancement edge, and advancement route now have engine-owned schemas,
trusted handler admission, complete occurrence-audit binding, package-local
cross-references, Tier-2 runtime adoption, and durable selected-variant state.
`UnitData.class_variant_id`, `advancement_edge_id`, and
`advancement_edge_variant_id` use the shared `SaveCodec` snapshot, so campaign
save, suspend, Retry, and Rewind all restore the authored selection without
re-evaluating eligibility.

The Z0/Z1 corpus is normalized at its FE-pack authoring source and mirrored into
the engine. All 11 roots match engine-owned expected diagnostics.

## Why Weapons is next

Weapons share the class vertical's WEXP vocabulary and already consume the v1
range-formula registry. They are required by roster inventories and encounters,
so landing them now follows dependency order and avoids building campaign-level
schemas over unchecked equipment documents.

## 1. Freeze the Weapon v1 envelope

Project the existing `WeaponData` surface into `EntitySchemaRegistry` rather than
inventing parallel names. Required identity/provenance fields should match the
class header. Admit combat family, WEXP track/rank, might/hit/crit, range formula
selections and parameters, weight, uses, cost, WEXP gain, effects, magic/triangle,
strike-count, natural-weapon, icon, completeness, and bounded variants only where
the public plan explicitly permits them.

Keep legacy `range_*_formula` strings at the compatibility/import boundary; new
Tier-2 documents select registered `range_min_formula_id` and
`range_max_formula_id` plus parameters.

## 2. Validate semantics and references

- Reject unknown fields with exact entity-qualified paths.
- Resolve source and occurrence audits using the completed generic contract.
- Admit only registered range formula ids/versions and validate their parameters.
- Validate combat-family/WEXP/rank/stat/effect/resource vocabulary through open
  registries, not new closed switches.
- Enforce nonnegative numeric fields, positive `strikes_per_attack`, coherent
  min/max range, and natural-weapon cost/use rules without encoding FE-specific
  balance values.
- Add package-local asset/item/effect references to the Tier-2 cross-reference pass.

## 3. Adopt the runtime adapter vertically

Replace the legacy `_validate_weapon` shape check with the registered schema while
keeping compatibility activation green. Adapt a validated document into
`WeaponData`, including registered range formulas, and prove the resulting resource
produces the same range/equip/combat inputs as the authored JSON.

## 4. Fixtures and exits

Add one synthetic golden weapon and narrow invalid siblings for unknown formula,
bad WEXP/rank/family, unresolved provenance/resource ids, invalid range, forbidden
variant override, and runtime parity. Include it in the same Tier-2 pack fixture
used by `test_campaign_tier2_runtime_adapter.gd`; do not copy FE weapon data.

Exit only when focused tests, the full suite, GDScript formatting, documentation
checks, and the tracker are green. Update GDD_04 and GDD_10 in the behavior commit.

## Watch-outs

- The implementation plan orders full skills/items before Weapons. If a weapon
  field needs an effect/item schema that is not registered yet, add only the
  smallest identity/reference schema required to resolve it; do not silently
  design the full family inside the Weapons change.
- `WeaponData` still has compatibility strings and runtime defaults. Schema
  defaults must not make malformed Tier-2 input appear valid.
- Do not use the current baked `data/weapons/*.tres` values as public fixtures;
  the FE-number audit and base-pack extraction own their eventual destinations.
