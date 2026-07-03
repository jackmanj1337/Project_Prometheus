---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 5 Source And Style Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B5-SOURCE-STYLE`, `B5-UTILITY-STAVES` (and the styles/sources
loadout adapters registering into the Plan 1 `LoadoutPanel` shell).

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 5 rows. Drafted from
[`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
(Content-chain steps 4-5) against the settled **Q5/Q6** walkthrough decisions of
2026-07-01.

## Purpose

Build the unified Source + Style combat-action substrate in one pass, then prove
it end-to-end with exactly two consumers (one hostile style + one utility
staff), then add the remaining v1 utility-staff archetypes as pure data on the
finished pipeline. This is the substrate that folds attack, combat arts, staves,
gambits, capture, and AoE into one "select source → select style → combined
preview → re-derived targeting → pay cost → resolve" flow.

This is a build plan only. It does not authorize starting `B5-SOURCE-STYLE`
before the Band 1-3 gates, `B4-IEQ`, and `B3-RESOURCE-POOLS` land, nor before
Plan 1's condition substrate (the cure/inflict staves consume it).

## Scope

1. The source/style model: `StyleDef` resource, the `EffectSpec` set on a
   source/style (kind + payload + per-effect `target_filter` + gate), and
   style-adds-or-overrides-effects composition (`source effects ∪ style
   effects`).
2. The four registries the model reads: **effect registry** (the full STY-16
   kind set — `strike/heal/cure/condition_apply/bolster/displace/teleport/refresh`),
   **target-filter registry** (`enemy | ally | self | empty_tile |
   weapon_holder | any`), **shape registry** (**widened to real AoE:
   single_tile/line/blast/cross**, owner "widen everything"), and the **cost
   model** (per-use component sets incl. per-map charges, reading the Band 2
   resource ledger — never embedding their own economy).
3. A generalized **effect-forecast** rendering both damage and non-damage
   outcomes through `B2-PROJECTION`, reused by the player preview and the AI
   scorer (Plan 4).
4. **Two proof consumers, built once in this pass:** one hostile style (a combat
   art) and one utility staff (the first `B5-UTILITY-STAVES` archetype — Heal).
5. The remaining v1 utility-staff archetypes as data: Restore/Cure (proves Plan
   1 cure hooks), Rescue (positional; `B2-OCCUPANCY`), and a condition-inflicting
   staff (proves the condition apply path + F16 `REQ-10` contest).
6. **[WIDENED]** The **displacement primitive** (`displace` effect kind + carry
   state on `B2-OCCUPANCY`, per the resolved `displacement_carry` register),
   **capture** (non-lethal style → `sleep` + carry/jail), and **gambit-as-style**
   (AoE source + per-map charges). The movement-assists (shove/swap/pivot) ride
   the same primitive.
7. The **styles** and **granted-sources** loadout adapters registering into the
   Plan 1 `LoadoutPanel` shell.

The effect kinds, target filters, styles, and staff ids are **specified** in
[`band5_v1_content_manifest_2026-07-03.md`](../design/band5_v1_content_manifest_2026-07-03.md)
§3/§4 (Q-B5-1 resolved 2026-07-03). This plan builds the pipeline and ships that
floor: the `strike/heal/cure/condition_apply/displace/refresh` kinds, the demo
styles (Wrath Strike, Poison Edge), and the four staff archetypes.

**Pulled forward (Q-B5-4 resolved 2026-07-03):** Source+Style is elevated to run
as early as its hard gates allow (`B4-IEQ` + `B3-RESOURCE-POOLS` + conditions for
the cure/inflict staves) — **in parallel with skills/loadout, not after them** —
because the AI scorer (C5) and Band 7 forging (`FRG-18`) both consume its effect
registry. Forging v1 no longer waits on a separate schedule; it builds once this
pipeline lands.

## Non-Goals

- **[REVISED — owner "widen everything" 2026-07-03]** AoE shapes, gambit-as-style,
  and capture-carry are now **v1** authorable primitives (§4/§4b of the manifest),
  not deferred. Build them here. This reverses the Q5/Q6 "later consumer" line for
  these three (recorded in the review doc).
- Do **not** build the full **battalion entity** (STY-7 A2): assignment UI,
  endurance, passive `StatContributions`, leveling. Gambit-as-style needs only a
  granted AoE source + per-map charges, not an attached unit. The entity stays
  deferred.
- Do not build the casual-author preset library. Presets are later content that
  compose existing effect/filter/shape primitives — not engine work.
- Do not build a second staff pipeline in the staves work: the Heal proof
  consumer is built once, inside the substrate pass; the other three archetypes
  are data on it.
- Do not embed a resource economy in styles. Costs read `B2-RESOURCE-LEDGER` /
  `B3-RESOURCE-POOLS`.
- Do not route any hit/resist/opposed roll through a bespoke RNG call. Every
  contest is F16 `REQ-10`.
- Do not replace effect kinds, target filters, shapes, or cost backends with a
  closed `enum` + `match`.
- Do not add saved source/style state without F1 manifest rows.
- Do not invent content beyond the §3/§4 manifest floor; content beyond it is
  later demo data.

## Source Docs

- [`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → "Walkthrough Decisions (2026-07-01)" Q5, Q6.
- [`band5_v1_content_manifest_2026-07-03.md`](../design/band5_v1_content_manifest_2026-07-03.md)
  (§3 utility staves, §4 source+style content — the floor this plan ships).
- [`source_style_combat_model_2026-06-24.md`](../registers/source_style_combat_model_2026-06-24.md)
  (`STY-1..17`; note the A1/A2 split for gambit/capture is superseded for v1 by
  "widen everything")
- [`displacement_carry_open_questions_2026-06-25.md`](../registers/displacement_carry_open_questions_2026-06-25.md)
  (`DSP` — the displacement primitive Slice 6 builds)
- [`source_style_player_and_authoring_2026-06-24.md`](../design/source_style_player_and_authoring_2026-06-24.md)
- [`band5_conditions_skills_implementation_plan_2026-07-03.md`](band5_conditions_skills_implementation_plan_2026-07-03.md)
  (the condition substrate the cure/inflict staves consume, and the
  `LoadoutPanel` shell the styles/sources adapters register into)
- [`band4_items_equipment_implementation_plan_2026-06-30.md`](band4_items_equipment_implementation_plan_2026-06-30.md)
  (sources ride `ItemDef`)
- [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](band2_shared_runtime_contracts_implementation_plan_2026-06-30.md),
  [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)

## Decisions Not To Reopen (from `STY-1..17`)

- Every combat-like action = a `source` (the `ItemDef`/`WeaponData` — *what*) +
  an optional `style` (a modifier layer — *how*). **Plain attack = the null
  style** — a `strike` effect + hostile targeting.
- A style is its own `StyleDef` resource, referenced like a skill, fired through
  the same pipeline. It adds fields a plain skill lacks: stat-mods, range
  override, targeting/AoE shape, cost set, lethality.
- A source+style combo carries a **SET of effects** (`EffectSpec`s), resolved
  together on one use. Each effect = `{ kind, payload, target_filter, gate }`
  where `gate ∈ {always, on_hit, on_kill}`. A style may **add or override**
  effects; committed set = `source effects ∪ style effects`.
- Targeting = a per-effect `shape`/`origin`; footprint tiles filtered by each
  effect's `target_filter`. Staves are the same pipeline (heal = a `heal` effect
  + `ally` filter).
- Cost = composable multi-resource: source per-use cost + the style's cost set
  (`[{backend, amount}]`), charged on commit; a style may **override** the base
  source cost (`override_source_cost`). Not XOR.
- Choosing a style **is** the unit's attack and costs its one combat action.
- Effect kinds, target filters, shapes, and cost backends are open registries.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before code:

- `B4-IEQ` so sources ride `ItemDef` (weapon component) and the `until_unequipped`
  producer exists.
- `B3-RESOURCE-POOLS` + `B2-RESOURCE-LEDGER` for the cost model.
- `B2-PROJECTION` for the generalized effect-forecast.
- `B2-ACTION-EFFECT` for effect execution.
- `B3-REQ` for target filters and F16 `REQ-10` contests (inflict staff).
- `B2-OCCUPANCY` — a **heavy** gate now: Rescue, the displacement primitive,
  capture-carry, the shove/swap/pivot assists, and AoE footprint clipping all use
  it (Slice 6, widened scope).
- Plan 1's `ConditionManager` + cure hooks (Restore/Cure, inflict staves) and
  the `LoadoutPanel` shell (styles/sources adapters).

## Existing Code Touchpoints

Verified 2026-07-03:

- `scripts/resources/WeaponData.gd` has `effect_tags: Array[String]` whose
  comment already anticipates `poison_on_hit` — the seam the `EffectSpec` set
  generalizes. Sources ride the `B4-IEQ` `ItemDef.weapon_component`.
- `scripts/items/ItemHandler.gd` has `is_healing_staff()` and dispatches staff
  effects through a closed `match`/`IMPLEMENTED_EFFECT_IDS`; this plan replaces
  the bespoke heal/offensive-staff split with the one effects pipeline.
- `scripts/ui/ActionMenu.gd` already frames Attack + Staff rows; `STY-15`
  reframes these around utility-`effect` sources + `target_filter`. Capability
  tags from Plan 1 gate the rows (`staff_use`).
- `scripts/core/CombatResolver.gd` is the resolve site; the effect set runs each
  effect's resolver here, and the forecast reuses the same math.
- Tests to extend: `test_combat.gd`, `test_skill_item_handler.gd`,
  `test_action_menu.gd`, and new `test_source_style.gd` / `test_effect_forecast.gd`
  / `test_utility_staves.gd`.

## Slice 0 - Preflight After Gates

**Goal:** confirm `ItemDef` sources, resource pools, projection, occupancy, and
the condition substrate are all in place.

Implementation checklist:

- Run `rg -n "effect_tags|is_healing_staff|IMPLEMENTED_EFFECT_IDS|CombatResolver|ActionMenu" scripts`.
- Confirm `B4-IEQ`, `B3-RESOURCE-POOLS`, `B2-RESOURCE-LEDGER`, `B2-PROJECTION`,
  `B2-ACTION-EFFECT`, `B2-OCCUPANCY`, `B3-REQ`, and Plan 1 have landed.
- Reserve F1 rows for source/style equipped state and any per-use style counters.

Tests: none required in preflight.

## Slice 1 - EffectSpec, Registries, StyleDef

**Goal:** the data model + the four registries, no resolve behavior yet.

Files to create or touch:

- `scripts/resources/EffectSpec.gd`
- `scripts/resources/StyleDef.gd`
- `scripts/resources/effects/TargetShape.gd` (shape interface; single-tile
  default)
- `scripts/autoloads/RegistryManager.gd` (effect-kind, target-filter, shape ids)
- `scripts/autoloads/DataManager.gd` (load/validate styles)
- `scripts/tests/test_source_style.gd`

Implementation steps:

1. `EffectSpec` fields: `kind`, `payload` (Dictionary), `target_filter`, `gate`
   (`always | on_hit | on_kill`).
2. `StyleDef` fields: `id`, `display_name`, stat-mods, `range_override`,
   `effects` (added/overriding `EffectSpec` set), `shape`, `cost`
   (`{override_source_cost, components: [{backend, amount}]}`), `lethality`,
   binding/availability.
3. Register effect-kind ids, target-filter ids, and shape ids through
   `RegistryManager`. Seed the **full STY-16 kind set**: `strike, heal, cure,
   condition_apply, bolster, displace, teleport, refresh`.
4. `TargetShape` interface **with real AoE shapes built in v1** (owner "widen
   everything"): `single_tile` (`footprint(origin) → [origin]`), `line`
   (length + direction), `blast` (radius), `cross`. The interface stays open for
   more shapes without an engine edit.
5. Add `per_map_charges` as a cost backend (gambit-as-style spends it).
6. Validators: unknown effect kind / target filter / shape / cost backend;
   malformed cost component; AoE footprint bounds (clip at map edges/occupancy).

Tests:

- A `StyleDef` with a stat-mod + one added effect validates.
- Unknown effect kind / target filter / shape reports a useful error.
- `override_source_cost` and `per_map_charges` cost sets validate.
- Each shape footprints correctly: `single_tile` → origin; `line`/`blast`/`cross`
  → the expected tile set, clipped at map bounds.

F1 obligations: none (defs are content).

DoD#2 obligations: a validator test that a new effect kind + target filter +
shape register as data with no engine switch edit.

## Slice 2 - Combo Resolution And Cost

**Goal:** resolve a source+style combo — combine effect sets, re-derive
targeting, charge cost, run each effect.

Files to touch:

- `scripts/core/CombatResolver.gd`
- `scripts/core/GridManager.gd` (targeting from shapes/filters)
- `scripts/autoloads/ResourceLedger.gd` (cost charge — Band 2)
- `scripts/units/Unit.gd` (source/style selection state)
- `scripts/tests/test_source_style.gd`

Implementation steps:

1. Compute the committed effect set = `source effects ∪ style effects` (style
   adds/overrides per `STY-14`).
2. Re-derive targeting: for each effect, footprint the shape at the origin and
   filter by `target_filter`. The combined preview shows all affected tiles.
3. Charge cost on commit: `source per-use cost + style cost set`, or the style's
   override; read/charge through `B2-RESOURCE-LEDGER` / `B3-RESOURCE-POOLS`.
   Choosing a style costs the unit's one combat action.
4. Run each effect's resolver in gate order (`always` → resolve → `on_hit` /
   `on_kill` post-hit), through `B2-ACTION-EFFECT`. Hit/resist gates route
   through F16 `REQ-10`.
5. Plain attack routes through the same path with the null style (a `strike`
   effect + hostile filter) — do not keep a separate attack codepath.

Tests:

- Plain attack resolves through the null-style path with unchanged combat math.
- A combat-art style adds a stat-mod + a second effect; both resolve on one use.
- Cost is charged once on commit; override replaces the source cost.
- `on_hit`/`on_kill`-gated effects only fire on the gate condition.

F1 obligations: source/style selection/equipped state rows before code.

DoD#1 obligations: update `GDD_02`, `GDD_04`, `GDD_05`, `GDD_Feature_Index`,
`GDD_10` for the unified combat-action model.

## Slice 3 - Generalized Effect Forecast

**Goal:** one forecast rendering damage and non-damage outcomes, reused by the
player preview and (Plan 4) the AI scorer.

Files to touch:

- `scripts/autoloads/CombatProjection.gd` (Band 2 projection layer)
- `scripts/ui/AttackPreview.gd`
- `scripts/tests/test_effect_forecast.gd`

Implementation steps:

1. Extend the projection layer to forecast the full effect set: damage, heal
   amount, condition applied (+ contest odds), displacement, cost paid, **and
   every tile in an AoE footprint** (line/blast/cross) with its per-tile outcome.
2. Render non-damage and multi-target outcomes in the preview (e.g. "Sleep 3
   turns, 70%", "Heal +12", an AoE tile highlight with a per-target list)
   alongside damage rows.
3. Guarantee the forecast is the single source of truth: the AI scorer (Plan 4)
   calls the same projection — AI and UI never diverge (Q7 watchout).

Tests:

- Damage forecast matches resolved damage.
- A cure/heal forecast shows the restored amount / removed conditions.
- A condition-inflict forecast shows contest odds matching the `REQ-10` result.

F1 obligations: none (forecast is derived, not saved).

## Slice 4 - Proof Consumers (Hostile Style + Heal Staff)

**Goal:** prove the pipeline with exactly two consumers, built once here.

Files to touch:

- fixture data: one hostile combat-art `StyleDef`, one Heal staff source
- `scripts/ui/ActionMenu.gd` (utility vs hostile framing per `STY-15`)
- `scripts/tests/test_source_style.gd`, `scripts/tests/test_utility_staves.gd`

Implementation steps:

1. Author one hostile style (stat-mod + strike, a cost from a pool) and confirm
   it flows select → preview → resolve → cost.
2. Author the **Heal staff** as a source whose effect is a `heal` kind + `ally`
   filter — the first `B5-UTILITY-STAVES` archetype, built here so the staves
   plan adds no second pipeline.
3. Reframe `ActionMenu` so utility sources surface by their `target_filter`
   (heal → ally-target row), replacing `is_healing_staff()`'s bespoke branch.

Tests:

- The hostile style is selectable, previews correctly, and charges its cost.
- The Heal staff heals an ally and consumes the action; gated off by `silence`
  (Plan 1 `staff_use` capability).

F1 obligations: none beyond Slice 2.

## Slice 5 - Remaining Utility-Staff Archetypes

**Goal:** Restore/Cure, Rescue, and condition-inflict as data on the pipeline.

Files to touch:

- fixture data for the three archetypes
- `scripts/core/CombatResolver.gd` (cure/inflict effect resolvers if not already
  registered), occupancy hooks for Rescue
- `scripts/tests/test_utility_staves.gd`

Implementation steps:

1. **Restore/Cure**: a `cure` effect calling Plan 1's `ConditionManager.cure`
   with the def's cure tags — proves the cure hooks end-to-end.
2. **Rescue**: a positional effect mutating the board through `B2-OCCUPANCY`;
   watch occupied/illegal-tile and rescue-capacity edge cases.
3. **Condition-inflict staff**: a `condition_apply` effect with a `target_filter`
   of `enemy`, whose hit/resist is an F16 `REQ-10` contest — never a bespoke
   roll. Proves Plan 1's condition apply path through the staff pipeline.
4. Repair/Hammerne deferred (durability/broken-weapon content is not v1).

Tests:

- Restore removes the matching conditions (and only those) and clears their
  lifecycle entries.
- Rescue moves the target legally; illegal/occupied targets are rejected.
- The inflict staff applies its condition on a won `REQ-10` contest and misses on
  a lost one; the forecast odds match.

F1 obligations: staff per-map uses/effects rows (shared with `B4-IEQ`
consumable-use fields) before code.

DoD#1 obligations: update `GDD_04`, `GDD_05`, `GDD_10` M8/M11 with the utility
staves landing.

## Slice 6 - Displacement Primitive, Capture, And Gambit-As-Style

**Goal:** the three widened primitives (owner "widen everything"), all on the
shared pipeline + `B2-OCCUPANCY`. Reverses the Q5/Q6 deferral for these.

Files to create or touch:

- `scripts/core/DisplacementService.gd` (or a helper on the occupancy owner) —
  the one occupancy-mutation primitive (per the resolved `displacement_carry`
  register)
- `scripts/core/CombatResolver.gd` (non-lethal damage cap for capture)
- `scripts/skills/SkillHandler.gd` (the shove/swap/pivot assist actions)
- fixture data: a Rescue is already in Slice 5; add a capture style, a gambit AoE
  source, a shove/swap assist
- `scripts/tests/test_displacement.gd`, `scripts/tests/test_capture.gd`,
  `scripts/tests/test_gambit.gd`

Implementation steps:

1. **Displacement primitive:** implement the `displace` effect kind against one
   occupancy-mutation primitive (move-a-unit with legality checks) and a **carry**
   state (a unit holding another). Rescue (Slice 5) migrates onto it; the
   movement-assists (shove / swap / pivot / smite) are data actions over the same
   primitive.
2. **Capture:** a **non-lethal** style — `CombatResolver` caps the hit so it
   cannot reduce the target below 1 HP, and a would-be-lethal hit **applies
   `sleep`** (§1 condition) instead. The sleeping unit is the capture-enabling
   state; carry/jail-release rides the displacement primitive. Ties §1 + this
   slice together.
3. **Gambit-as-style:** an AoE source (a granted weapon/source with a `blast`/
   `line`/`cross` shape) spending `per_map_charges`. **No battalion entity** —
   provenance `battalion` on the granted list is enough; the attached unit stays
   A2.
4. Forecast: the effect forecast (Slice 3) renders the AoE footprint and every
   affected tile's outcome; capture shows "downs to Sleep" not a kill.

Tests:

- A `displace` effect relocates a unit legally; occupied/illegal targets rejected.
- Rescue and a shove/swap assist both run through the one primitive (no duplicate
  occupancy code).
- A capture hit that would kill instead leaves the target at ≥1 HP and asleep;
  carry picks it up.
- A gambit AoE hits every tile in its shape, consumes one charge, and refuses when
  charges are 0.
- The forecast shows the full AoE footprint and the capture "down-to-sleep".

F1 obligations: carry state, per-source `charges_remaining`, and captured/jailed
unit state need manifest rows before code.

DoD#1 obligations: update `GDD_02`, `GDD_04`, `GDD_05`, `GDD_10` for capture,
gambits, and the displacement primitive.

DoD#2 obligations: guard that shove/swap/pivot/rescue/capture all register as data
over the one displacement primitive, not separate occupancy paths.

## Slice 7 - Styles And Sources Loadout Adapters

**Goal:** register the styles and granted-sources adapters into the Plan 1
`LoadoutPanel` shell — no panel edit.

Files to create:

- `scripts/loadout/StylesLoadoutAdapter.gd`
- `scripts/loadout/GrantedSourcesLoadoutAdapter.gd`
- `scripts/tests/test_loadout_panel.gd` (extend)

Implementation steps:

1. Implement the two adapters against the Plan 1 category-adapter interface
   (`list_earned`, `list_equipped`, `cap_predicate`, `row_renderer`,
   `can_equip`). Styles cap by their own rule (count/slot); granted sources by
   theirs.
2. Register both via `LoadoutPanel.register_category` — the shell iterates them
   with no code edit (this is the DoD#2 proof from Plan 1 Slice 5).

Tests:

- The loadout panel shows skills, styles, and granted-sources categories, each
  with its own cap rule, with no `LoadoutPanel` code change.
- Equipping past a category cap is rejected per that category's predicate.

F1 obligations: equipped styles/sources loadout rows before code.

DoD#2 obligations: guard that adding the styles/sources categories required no
edit to `LoadoutPanel` category logic.

## Implementation Commit Order

1. Slice 0 preflight.
2. Slice 1 `EffectSpec` / `StyleDef` / registries.
3. Slice 2 combo resolution + cost.
4. Slice 3 generalized effect forecast.
5. Slice 4 proof consumers (hostile style + Heal staff).
6. Slice 5 remaining utility-staff archetypes.
7. Slice 6 displacement primitive + capture + gambit-as-style (widened).
8. Slice 7 styles/sources loadout adapters.

Do not start before `B4-IEQ`, `B3-RESOURCE-POOLS`, `B2-PROJECTION`,
`B2-OCCUPANCY`, and Plan 1's condition substrate exist. Slices ship the §3/§4
manifest content directly. **Pulled forward (Q-B5-4):** run this in parallel with
Plan 1's skills/loadout slices, not after them — the AI scorer (Plan 4 Slice 3)
and Band 7 forging (`FRG-18`) both gate on this pipeline, so it is on the critical
path. Forging v1 builds once this lands (it no longer waits on a separate gate).

## Verification Checklist

Same as the Band 2/3/4 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```
