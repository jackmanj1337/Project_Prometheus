---
Type: plan
Status: Active - implementation plan
Last verified: 2026-06-30
---

# Band 3 Core Authoring Foundations Implementation Plan

**Started:** 2026-06-30.

**Track IDs:** `B3-CAMPAIGN-RULES`, `B3-COMBAT-ROLL-RESOLVER`, `B3-TCV`,
`B3-REQ`, `B3-MET`, `B3-PHB`, `B3-TEXT`, `B3-MOVEMENT-VULN-REGISTRY`,
`B3-STAT-REGISTRY`, `B3-RESOURCE-POOLS`, `B3-CALENDAR-LITE`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 3 rows. Drafted from
[`band3_implementation_plan_handoff_2026-06-30.md`](band3_implementation_plan_handoff_2026-06-30.md).

## Purpose

Turn the ratified Band 3 design registers into one code-ready, ordered build
sequence. Band 3 is the **core authoring layer**: the typed variable store,
the shared predicate/formula vocabulary, campaign rule profiles, map events,
the prep/option-panel surface, text indirection, the stat/movement registries,
author resources, and the author-selectable hit resolver. Every later content
feature (dialogue, shops, recruit, difficulty, training, AI, perception)
consumes these foundations rather than inventing private copies.

This is a build plan only. It does not authorize starting Band 3 code before the
Band 1 and Band 2 gates land (see Dependency Note).

## Scope

This plan covers the first Band 3 implementation run, one combined plan with
ordered slices:

1. The two registry sub-plans already written (stat, movement/vulnerability),
   reused by reference — not restated.
2. Text indirection (`B3-TEXT`) — stable text keys before predicate display and
   dialogue text grow.
3. The typed campaign-variable store (`B3-TCV`).
4. The shared requirement/predicate + arithmetic-formula system (`B3-REQ`, F16
   incl. REQ-16).
5. Author-tunable campaign rule profiles (`B3-CAMPAIGN-RULES`).
6. The registry promotion + author tiers of the hit resolver
   (`B3-COMBAT-ROLL-RESOLVER`).
7. The map events/triggers framework (`B3-MET`).
8. The prep-hub / option-panel framework (`B3-PHB`).
9. Author resources and unit pools (`B3-RESOURCE-POOLS`).
10. The in-world time substrate (`B3-CALENDAR-LITE`) — promoted from deferred
    after the owner named concrete consumers (in-world date in dialogue,
    overworld encounter spawning, post-combat date-advance events, shop refresh).
    Substrate only; consumers stay in their own bands.

## Non-Goals

- Do not implement Band 3 before `B1-PKGA`, `B1-F1`, `B2-REGISTRY`, and the
  Band 2 services the consumers need (`B2-ACTION-EFFECT`,
  `B2-RESOURCE-LEDGER`).
- Do not build the consumers of these foundations here. No dialogue runtime,
  no shop/convoy/arena/training panels, no difficulty palettes, no recruit
  flow, no perception, no AI valuation. Those are Band 4+ rows that *call* Band 3.
- Do not re-derive any resolved register decision. TCV, REQ, MET, PHB, DIF,
  THL, and CRR are settled; this plan assembles them.
- Do not add a closed `enum` + `match` for any growing author vocabulary
  (predicate types, variable types, trigger/action types, panel types, resource
  types, resolvers). Each is a registry/data-driven extension point.
- Do not add saved Band 3 state without an F1 manifest row first.
- Do not build the string front-end formula parser, the `from_predicate`
  bridge, per-map override scopes, or the tier-3 GDScript handler author path in
  the first run. They are explicitly deferred below.

## Source Docs

- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
- [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](band2_shared_runtime_contracts_implementation_plan_2026-06-30.md)
- [`movement_vulnerability_registry_implementation_plan_2026-06-29.md`](movement_vulnerability_registry_implementation_plan_2026-06-29.md)
- [`stat_registry_implementation_plan_2026-06-29.md`](stat_registry_implementation_plan_2026-06-29.md)
- [`typed_campaign_variable_store_open_questions_2026-06-27.md`](../registers/typed_campaign_variable_store_open_questions_2026-06-27.md) (`TCV-1..6`)
- [`requirement_predicate_system_open_questions_2026-06-25.md`](../registers/requirement_predicate_system_open_questions_2026-06-25.md) (`REQ-1..16`)
- [`difficulty_death_mode_open_questions_2026-06-27.md`](../registers/difficulty_death_mode_open_questions_2026-06-27.md) (`DIF-1..7`)
- [`combat_roll_resolver_open_questions_2026-06-30.md`](../registers/combat_roll_resolver_open_questions_2026-06-30.md) (`CRR-1..8`)
- [`map_events_triggers_open_questions_2026-06-21.md`](../registers/map_events_triggers_open_questions_2026-06-21.md) (`MET-1..9`)
- [`prep_hub_open_questions_2026-06-23.md`](../registers/prep_hub_open_questions_2026-06-23.md) (`PHB-1..7`)
- [`training_halls_open_questions_2026-06-27.md`](../registers/training_halls_open_questions_2026-06-27.md) (`THL-1..8`, resource model)
- [`dialogue_conversation_system_open_questions_2026-06-25.md`](../registers/dialogue_conversation_system_open_questions_2026-06-25.md) (text-key consumer)

## Decisions Not To Reopen

- Author-facing vocabularies are open registries / data composition, not closed
  `enum` + `match` additions (AGENTS.md architecture principle).
- F1 owns saved-field manifest rows before any Band 3 feature adds saved state.
- `B3-TCV`/`B3-REQ` reuse the existing modifier + tags + objective AND/OR
  substrate; they assemble, they do not invent a parallel system.
- `REQ-16` arithmetic is **Option A data-composition** — a recursive data tree,
  fixed-point ×1000, iterative evaluator, required `on_zero` on `div`. No
  author-authored expression strings in v1 (parser is later sugar over the same
  tree).
- The hit-roll resolver design is settled at `CRR-1..8`: the two built-ins ship
  under `B1-PKGA` Slice 1b; the registry promotion + sandboxed-expression tier
  are this plan; the GDScript handler tier is fork-only and not built here.
- `MET` is one `trigger -> action` framework on the shared action/effect runner
  (`MET-1..9`); `ObjectiveCondition` stays a separate evaluator that events can
  influence, not absorb (`MET-7`).
- `PHB` is a flat opt-in `prep_panels` list with `node_type {battle|hub}`,
  free navigation, immediate transaction commit, no hub-suspend snapshot
  (`PHB-1..7`).
- `B3-CALENDAR-LITE` is a **substrate-only** Band 3 slice (owner, 2026-06-30):
  **per-node authored advance** (each progression node declares `advance_days`)
  driving a campaign-scope day counter, with a **structured calendar**
  (authored months/seasons) deriving day/month/year/season for dialogue and
  triggers. Consumers (dialogue interpolation, shop refresh, overworld
  encounter spawning) stay in their own bands.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before any Band 3 slice:

- `B1-PKGA` Steps 1-2 (deterministic RNG + snapshot) — `B3-REQ` `chance`
  (`REQ-10`) and the resolver registry both route through `RngService`.
- `B1-F1` — every Band 3 saved field needs a manifest row first.
- `B2-REGISTRY` — every Band 3 vocabulary is a registry consumer; nothing in
  Band 3 loads before it.
- `B2-ACTION-EFFECT` — `B3-MET` and `B3-PHB` execute primitives through the
  shared runner, not private switches.
- `B2-RESOURCE-LEDGER` — `B3-RESOURCE-POOLS` extends the ledger's wallet/cost
  path; it does not fork a second spending system.

`B1-CST` Slice 6 (CampaignRules consolidation) must exist before
`B3-CAMPAIGN-RULES` adds the author-tunable profile layer on top of it.

## Bootstrap Order (Do Not Reorder)

1. **`B2-REGISTRY` first** (Band 2 gate). Every Band 3 vocabulary loads through it.
2. **`B3-STAT-REGISTRY` and `B3-MOVEMENT-VULN-REGISTRY`** — independent registry
   consumers; the stat registry must precede content that reads author stats in
   formulas.
3. **`B3-TEXT` before `B3-REQ` display** — `REQ-5` renders predicates through
   F13 text keys; the key layer should exist before predicate display lands.
4. **`B3-TCV` before `B3-REQ`** — variable definitions must type-check before
   predicates/formulas reference them.
5. **`B3-REQ` before gated features** (`MET` conditions, objective predicates,
   and every Band 4+ shop/recruit/perception/AI consumer).
6. **`B3-CAMPAIGN-RULES` before `B3-COMBAT-ROLL-RESOLVER`** — the resolver
   registry reads the `CampaignRules.hit_formula` selection.
7. **`B2-ACTION-EFFECT` before `B3-MET`/`B3-PHB`**.

## Existing Code Touchpoints

Verified 2026-06-30 (and via the Band 1/2 plans' code-grounding sections):

- `scripts/resources/CampaignRules.gd` holds sibling rule knobs
  (`leveling_method`, `max_skills`, `max_inventory`, `exp_gaining_factions`,
  `permadeath_enabled`); `B1-CST` Slice 6 adds `hit_formula` and
  `rewind_charges_per_map` and migrates call sites to `gs.campaign_rules.*`.
- `scripts/autoloads/GameState.gd` has only debug-aid flags today — **no flag
  store** (the `B3-TCV` store is greenfield) — and owns `party_gold` plus the
  map-snapshot path the TCV map-scope reset must hook.
- `scripts/units/Unit.gd` `add_modifier`/`remove_modifier`/`tick_modifiers`
  read through `get_effective_stat(name)` (string-keyed → covers extension
  stats) — the substrate `TCV-3` parametric effects and every `REQ` stat
  predicate read.
- `scripts/resources/ObjectiveCondition.gd` is a closed `type` enum, phase-poll
  evaluated — `TCV-4` opens it to a flag/predicate condition type and adds an
  `end_map` action without merging it into MET.
- `scripts/resources/MapData.gd` has no `map_events` field — `MET` adds the
  `Array[Dictionary]` authoring home; `scripts/core/GameMap.gd` `_spawn_unit`
  is the seam `MET` `spawn` extends (occupancy via `B2-OCCUPANCY`).
- `scripts/autoloads/EventBus.gd` already broadcasts `unit_died`,
  `turn_changed`, `phase_changed`, `combat_resolved`, `object_broken` — the
  `MET` trigger substrate.
- `scripts/core/CombatResolver.gd` `compute_hit_pct` (the displayed number,
  unchanged) and the Slice 1b pure `did_hit(displayed_hit, rns)` seam — the
  `B3-COMBAT-ROLL-RESOLVER` registry promotes the two built-ins behind it.
- Existing prep flow (deploy/bench/placement/Save/Begin Battle) and
  `CampaignData` are the `PHB` container `prep_panels` plug into.
- Tests to extend first: `test_game_state.gd`, `test_data_manager.gd`,
  `test_combat.gd`, `test_game_map_scene.gd`, plus new focused suites.

## Slice 0 - Preflight After Band 1/2 Gates

**Goal:** confirm gates and keep each Band 3 commit small and reviewable.

Implementation checklist:

- Confirm `RngService`, `RegistryManager`, `DataManager` load/validate phases,
  `ActionEffectRunner`, and `ResourceLedger` exist and pass their suites.
- Confirm the F1 manifest already has rows for the fields Band 3 will touch or
  reserve new rows before code: `CampaignRules.hit_formula`, campaign/map var
  store, per-unit `groups`/tags, objective predicate refs, `map_events_fired`,
  map/campaign flags, `node_type`/`prep_panels`/`theme`, the party
  multi-resource wallet, per-unit pools, and per-unit extension stats.
- Decide per slice whether it is behavior-preserving or behavior-changing.
  Behavior-changing commits update the owning GDD chapter and control-plane row
  in the same commit (DoD#1).

Tests: none in preflight.

## Slice 1 - `B3-STAT-REGISTRY` (Reuse Sub-Plan)

Build per
[`stat_registry_implementation_plan_2026-06-29.md`](stat_registry_implementation_plan_2026-06-29.md).
Do not restate it. Land it before any formula/predicate content reads author
stats so `get_effective_stat(name)` covers extension stats end-to-end.
F1 reserves per-unit extension stats; registry obligation = stat definitions /
display info / missing-stat handling. After it lands, update the
`B3-STAT-REGISTRY` row status.

## Slice 2 - `B3-MOVEMENT-VULN-REGISTRY` (Reuse Sub-Plan)

Build per
[`movement_vulnerability_registry_implementation_plan_2026-06-29.md`](movement_vulnerability_registry_implementation_plan_2026-06-29.md).
Do not restate it. Independent registry consumer; existing movement/vulnerability
ids become developer presets. No per-unit save unless overrides are added.
After it lands, update the `B3-MOVEMENT-VULN-REGISTRY` row status.

## Slice 3 - `B3-TEXT`: Text Indirection

**Goal:** stable text keys (F13) before predicate display and dialogue text grow.

Files to create or touch:

- `scripts/text/TextDB.gd` (autoload) and `data/text/` key tables
- `scripts/autoloads/DataManager.gd` (validate key presence)
- `scripts/tests/test_text_db.gd`

Implementation steps:

1. Add a `TextDB` that resolves `text_key -> string` from data tables, with a
   single missing-key policy (return a visible `#missing:<key>` sentinel and
   collect a validation warning, never crash).
2. Register the `text` **family** with `RegistryManager` and validate
   referenced keys against the loaded data tables — do **not** create one
   `RegistryEntry` resource per key (a campaign with thousands of lines must
   not pay a per-key resource cost). Open family, not a hardcoded list; the
   table is the key source of truth.
3. Provide `tr_key(key, params := {})` for simple `{name}`-style substitution.
4. Do not migrate existing UI strings wholesale; add the seam and one fixture
   table. Migration rides each consuming feature.

Tests:

- Known key resolves; missing key returns the sentinel and reports one warning.
- Parameter substitution fills named placeholders.
- A data-defined key table loads without an engine edit.

F1 obligations: text data is authoring, not saved (`no_save_guard` row).

Registry obligations: `text` id family registered.

DoD#2 obligations: add a check/test that referenced text keys resolve (or are
reported), so a dangling `text_key` fails loud at load.

## Slice 4 - `B3-TCV`: Typed Campaign-Variable Store

**Goal:** a typed `bool|int|enum` variable store at campaign and map scope, the
author-exposed tunable mechanism, and the `in_group` substrate — assembled from
the modifier system + registry, per `TCV-1..6`.

Files to create or touch:

- `scripts/resources/CampaignVarDef.gd` (registry entry: `{id, type, default,
  exposed: locked|start|mid_run, bounds|options, scope: campaign|map}`)
- `scripts/autoloads/CampaignVars.gd` (typed get/set store, two scopes)
- `scripts/autoloads/GameState.gd` (campaign-scope persistence + map-scope reset
  hook in the map-snapshot/teardown path)
- `scripts/resources/UnitData.gd` (author-assignable `groups`/tags field)
- `scripts/autoloads/RegistryManager.gd` (variable-definition family)
- `scripts/tests/test_campaign_vars.gd`

Implementation steps:

1. Add `CampaignVarDef` as a registry entry; load author + built-in knob
   definitions through `RegistryManager` (no closed enum).
2. Add `CampaignVars` with typed `get_var(id)` / `set_var(id, value)` validated
   against the definition (type + bounds/options). Reject unknown ids and
   out-of-bounds writes with structured errors.
3. Two scopes: **campaign** vars persist (campaign save); **map** vars reset on
   map start (hook the existing snapshot/teardown path). `string`/run-scope
   stay deferred (`TCV-1`).
4. Add the per-unit `groups`/tags field on `UnitData` (extends `ClassData`
   semantic tags) — the substrate the `REQ` `in_group`/`has_trait` predicate
   reads in Slice 5. Do not build the predicate here.
5. Expose the tunable read path for `start`/`mid_run` vars; the player options
   menu surface and the `MET` `set_var` action are wired in their own slices
   (CAMPAIGN-RULES / MET) — `TCV` provides the store + validation only.

Tests:

- Typed get/set round-trips for `bool`/`int`/`enum`; bad type/value rejected.
- Campaign var persists across a save round-trip; map var resets on map start.
- Unknown var id fails loud.
- A data-defined var loads without an engine edit.
- `UnitData.groups` round-trips through the save codec.

F1 obligations: reserve rows for campaign-scope vars, map-scope vars (transient,
reset semantics noted), the player's exposed-tunable picks, and per-unit
`groups`/tags (`TCV-6`).

Registry obligations: `campaign_var` definition family.

DoD#2 obligations: add a check that every `set_var`/`get_var` call site targets a
registered var id once two consumers exist (guard against ad-hoc string keys).

## Slice 5 - `B3-REQ`: Requirement / Predicate + Arithmetic Formula System (F16)

**Goal:** one shared `Requirement` evaluator (boolean tree of typed predicates
over a named subject) plus the `REQ-16` fixed-point arithmetic value-term tree,
per `REQ-1..16`. Built before any gated authoring feature.

Files to create or touch:

- `scripts/req/Requirement.gd` (the `all`/`any`/`not` tree)
- `scripts/req/Predicate.gd` + a registry of predicate evaluators
- `scripts/req/ValueTerm.gd` (leaf + compound arithmetic tree)
- `scripts/req/FormulaEvaluator.gd` (iterative, explicit-stack, fixed-point ×1000)
- `scripts/autoloads/RequirementSystem.gd` (evaluate / render entry points)
- `scripts/resources/CampaignRules.gd` (add `max_formula_depth`,
  `max_formula_nodes` budget fields — the profile/tunable layer is Slice 6)
- `scripts/autoloads/RegistryManager.gd` (predicate-type + value-source families)
- `scripts/tests/test_requirement.gd`, `scripts/tests/test_formula_evaluator.gd`

Implementation steps:

1. Add `Requirement` as a nestable `all`/`any`/`not` tree over typed predicates;
   a bare predicate is the degenerate case (`REQ-1`, `REQ-4`).
2. Add the v1 predicate vocabulary as registered thin-adapter evaluators
   (`REQ-2`): `flag`, `unit_is`/`unit_present`, `class_level`, `proficiency`,
   `stat`, `has_skill`/`has_trait` (+ `in_group` over the Slice 4 `groups`
   field), `has_item {held|equipped|convoy}`. Add `compare` (`REQ-9`) over value
   terms. Each predicate names a subject selector (`REQ-3`):
   `speaker`/`participant:<role>`/`unit:<id>`/`active_unit`/`party(any|all)`.
3. Add the `REQ-16` value-term tree: leaf `{subject, source}` / `{literal}` and
   compound `{op, operands, round?, on_zero?}`. Operators `add sub mul div pow
   min max abs neg` + number-domain booleans `not and or truthy`. Fixed-point
   ×1000, 64-bit, every node clamped; half-up rounding with `floor`/`ceil`
   override; **required `on_zero` on every `div`** (missing = validate error);
   integer-exponent `pow`. The evaluator is **iterative (explicit stack)**, with
   an absolute safety ceiling; per-pack budget = the two CampaignRules fields.
4. Add `REQ-5` display: per-predicate-type F13 templates (Slice 3 `TextDB`),
   compositional render, per-use override string.
5. Add the `chance` predicate (`REQ-10`) **only after `B1-PKGA`**: base + F4
   skew-profile over a difference|ratio (now `sub|div` value terms) of two
   terms, rolled via `RngService`, **roll-once-and-latch** (author
   `re_rollable`); skew `input`/`base` evaluated pure on the roll snapshot. The
   one impure predicate — evaluated on commit, never previewed. Latch rides
   `visited_trail`/flag store (the campaign-save trail field inventoried in
   [`f1_schema_source_inventory_2026-06-28.md`](f1_schema_source_inventory_2026-06-28.md)
   — its F1 row is the latch's owner); no new top-level save field.
6. Build the remaining `REQ-11..15` families (item-property terms, HP/pool/
   ability/style availability sources, spatial/runtime-state/relationship/
   aggregate families, condition potency/param/projection) **per consumer
   demand**, not all up front — each is a registered evaluator. Document them as
   reserved, build as a Band 4+ consumer needs each.
7. Keep the `from_predicate` logic↔term bridge and the string-front-end parser
   **deferred**; v1 uses the flag-upstream pattern (`REQ-16`).

Tests:

- Predicate truth tables for each v1 type; subject selectors resolve correctly.
- `all`/`any`/`not` composition, nested.
- `FormulaEvaluator`: arithmetic correctness at fixed-point scale; clamp on
  overflow; half-up + `floor`/`ceil`; `div` with each `on_zero` policy; missing
  `on_zero` is a validate error; `pow` integer exponents incl. `0^0 = 1`;
  number-domain booleans output canonical `1.0` or `0.0` (fixed-point `1000` /
  `0`); budget overflow fails at load.
- `chance` (post-PKGA): fixed seed reproduces the roll; latch returns the same
  answer after save/reload and rewind; `re_rollable` clears the latch; never
  evaluated in preview.
- A data-defined predicate type loads without an engine edit.

F1 obligations: Requirement/formula data is authoring (not saved, `REQ-7`). The
only new persisted state is the `chance` latch, which rides `visited_trail`/the
flag store — reserve that note, no new top-level field. Confirm the two
CampaignRules budget fields have F1 rows.

Registry obligations: `predicate_type` and `value_source` families; skew-profile
rides the F4 CampaignRules profile mechanism.

DoD#2 obligations: add a validation check that every `div` term declares
`on_zero`, that formula depth/node-count is within the pack budget, and that no
impure predicate (`chance`) is reachable from inside a value term.

## Slice 6 - `B3-CAMPAIGN-RULES`: Author-Tunable Rule Profiles

**Goal:** author-defined rule profiles and the exposed-tunable layer over the
consolidated CampaignRules, per `DIF-3..5` / `TCV-2`. (Death-mode and difficulty
*content* selection are Band 4 `B4-DIFFICULTY-DEATHMODE`; this slice provides the
tunable substrate they ride.)

Files to create or touch:

- `scripts/resources/CampaignRuleProfile.gd` (a named bundle of knob values)
- `scripts/autoloads/RegistryManager.gd` (rule-profile / tunable-knob families)
- `scripts/resources/CampaignRules.gd` (declare which knobs are
  `locked|start|mid_run` exposed, with bounds/options — reusing `CampaignVarDef`)
- `scripts/autoloads/GameState.gd` (selected profile/tunable picks on the save)
- `scripts/tests/test_campaign_rule_profiles.gd`

Implementation steps:

1. Model each built-in CampaignRules knob as a `CampaignVarDef`-style tunable
   (`TCV-2`): one uniform mechanism over built-in knobs **and** author custom
   vars. The New-Game pickers become the `start`-exposed built-in slice.
2. Add `CampaignRuleProfile` registry entries (author-named bundles); the player
   picks from the author-allowed set per save (`DIF-4`).
3. Persist the selected profile + the player's `start`/`mid_run` tunable picks.
4. Leave the death-mode/difficulty-variant *content* selection and the AIP
   overlay to `B4-DIFFICULTY-DEATHMODE`; this slice only proves a knob can be
   author-locked or player-exposed and round-trips on the save.

Tests:

- A profile loads and applies its knob values.
- A `locked` knob rejects a player override; a `start` knob accepts one within
  bounds; an out-of-bounds pick is rejected.
- Selected profile + picks round-trip on the save.
- A data-defined profile loads without an engine edit.

F1 obligations: reserve rows for selected profile id and the tunable picks
(distinct from the per-save `hit_formula`/`death_mode` rows owned by Band 1 /
`B4-DIFFICULTY-DEATHMODE`).

Registry obligations: `rule_profile` + `tunable_knob` families.

DoD#2 obligations: add a check that no rule knob is read via a loose field once
the profile/tunable layer owns it (extends the Band 1 `gs.campaign_rules.*`
migration guard).

## Slice 7 - `B3-COMBAT-ROLL-RESOLVER`: Resolver Registry + Author Tiers

**Goal:** promote the two Slice-1b built-in resolvers to registry entries and
open the tier-2 sandboxed-expression author path, per `CRR-1..8`.

Files to create or touch:

- `scripts/resources/RollResolver.gd` (registry entry: `{id, rn_count,
  kind: builtin|expression, expr?, handler?}`)
- `scripts/combat/RollResolverRegistry.gd` or `RegistryManager` family
- `scripts/core/CombatResolver.gd` (call the registry-resolved `did_hit` instead
  of the two hardcoded built-ins)
- `scripts/tests/test_roll_resolver.gd`

Implementation steps:

1. Move `single_roll` and `two_roll` from inline built-ins to `RegistryEntry`
   data, selected by `CampaignRules.hit_formula` (`CRR-4`, campaign default).
2. Add the tier-2 **sandboxed `Expression`** author tier (`CRR-3`): an
   expression string over `rns` and `hit`, evaluated with Godot `Expression`,
   structurally barred from drawing RNs, reading globals, or mutating state
   (`CRR-7`). The saved value is the resolver id; the expression is authoring
   data, not per-save state.
3. Keep the resolver contract = declared fixed `rn_count` + pure
   `did_hit(displayed_hit, rns) -> bool` (`CRR-2`). Displayed hit stays
   `compute_hit_pct` (`CRR-5`).
4. Reserve (do not build) the tier-3 GDScript handler (fork-only) and the crit/
   activation adoption of the same resolver family (`CRR-6`).

Tests:

- Each built-in registry resolver reproduces its literal outcome for fixed `rns`.
- A sandboxed expression resolver evaluates correctly and **cannot** draw RNs,
  read globals, or mutate state (sandbox-bounds tests).
- Determinism replay stays green; preview shows the unchanged displayed hit.
- A data-defined resolver loads without an engine edit.

F1 obligations: `campaign.hit_formula` row already reserved (Band 1 Slice 6 /
`CRR-4`); no new save surface (expression strings are authoring data).

Registry obligations: `roll_resolver` family.

DoD#2 obligations: add a check that registered resolvers declare a fixed
`rn_count` and a pure-predicate body, and that expression resolvers pass the
sandbox-bounds rules.

## Slice 8 - `B3-MET`: Map Events / Triggers Framework

**Goal:** data-authored `trigger -> action` events on the shared action/effect
runner, per `MET-1..9`.

Files to create or touch:

- `scripts/resources/MapData.gd` (`map_events: Array[Dictionary]`)
- `scripts/autoloads/MapEventManager.gd`
- `scripts/autoloads/DataManager.gd` (validate event shape)
- `scripts/resources/ObjectiveCondition.gd` (open it to a flag/predicate
  condition type + an `end_map` action — `TCV-4`)
- `scripts/core/GameMap.gd` (public `spawn_unit` seam via `B2-OCCUPANCY`)
- `scripts/tests/test_map_events.gd`

Implementation steps:

1. Add `map_events` as a `DataManager`-validated `Array[Dictionary]` (`MET-1` B).
2. `MapEventManager` connects the `EventBus` substrate once, matches authored
   events, checks the optional `condition` (a `Requirement` — generalizes the
   flag-only `MET-4`), runs the action list at the next safe deferred point, and
   latches `once` events (`MET-5`, `map_events_fired`).
3. v1 triggers: `unit_died`, `turn_reached`, `object_broken` (`MET-2`). v1
   actions through the shared `ActionEffectRunner`: `reveal_tiles`, `flag` /
   `set_var` (writes `CampaignVars`), `spawn` (`MET-3`, occupancy via
   `B2-OCCUPANCY`, `on_blocked = nearest_free -> delay`), `set_ai`
   (event-driven aggression, `MET-3` confirmed), and `end_map: victory|defeat`
   (`TCV-4` imperative path).
4. Open `ObjectiveCondition` to a flag/predicate-driven type that reads
   `CampaignVars` + `Requirement`s (`TCV-4` declarative path); re-check is
   event-driven on the triggering change + the existing phase-boundary poll as
   backstop. Do **not** merge objectives into MET (`MET-7`).
5. Use the deferred safe-point timing pattern; never run actions inside a combat
   exchange (`MET-8`).

Tests:

- "boss dies -> set flag + reveal tiles" fires once; re-trigger does nothing.
- Flag/predicate `condition` gates an event; false = skip without consuming the
  latch.
- Save mid-map, reload -> fired events do not re-fire; spawns/reveals persist.
- `turn_reached(N)` fires a spawn wave; blocked spawn uses nearest-free -> delay.
- `set_ai` repoints a unit/group's AI spec.
- `end_map` and a flag-driven `ObjectiveCondition` resolve victory/defeat.

F1 obligations: reserve `map_events_fired` (map-runtime/suspend), map + campaign
flags (the `CampaignVars` rows from Slice 4), and objective predicate refs
(`TCV-6`).

Registry obligations: `trigger_type` + `action_type` families (the latter shared
with `B2-ACTION-EFFECT`).

DoD#2 obligations: add a check that MET actions resolve to registered primitive
ids (no private switch) and that triggers map to known `EventBus` signals.

## Slice 9 - `B3-PHB`: Prep-Hub / Option-Panel Framework

**Goal:** the shared prep + on-map panel surface (the container only), per
`PHB-1..7`. Downstream panels (convoy/shop/arena/training/recruit) are Band 4+
consumers built on this seam.

Files to create or touch:

- `scripts/resources/CampaignData.gd` (progression node: `node_type
  {battle|hub}`, `prep_panels: [...]`, `theme`/`location_label`)
- `scripts/autoloads/RegistryManager.gd` (panel-type family)
- `scripts/ui/PrepHub.gd` (flat panel list; free navigation; single commit)
- `scripts/tests/test_prep_hub.gd`

Implementation steps:

1. Add `node_type` (battle|hub), opt-in `prep_panels: [...]`, and cosmetic
   `theme`/`location_label` to the progression node (`PHB-1/2/4/6`). Empty
   `prep_panels` = today's deploy-only prep.
2. Make the commit action generic: Begin Battle on a `battle` node, Continue on
   a `hub` node (`PHB-4/5`). Free navigation; manual Save throughout.
3. Render panels from a registered `panel_type` family (open vocabulary). Build
   **no** concrete service panel here beyond a test fixture panel; convoy/shop/
   etc. are their own Band 4 rows.
4. Transactions commit immediately to persistent party state; no hub-suspend
   snapshot (`PHB-7`). Reserve the dual-surface (prep + on-map) panel contract
   per `SAC` for the Band 4 `B4-MAP-OBJECTS` consumer — do not build on-map
   placement here.

Tests:

- A node with `prep_panels: []` shows deploy-only prep; a node with panels shows
  the buttons.
- `battle` node commits via Begin Battle; `hub` node advances via Continue.
- A fixture panel's transaction survives suspend/reload by re-deriving from party
  state (no bespoke snapshot).
- A data-defined panel type registers without an engine edit.

F1 obligations: reserve `node_type`/`prep_panels`/`theme` on `CampaignData`;
panel/service state saves only through its owning system (no PHB UI state saved).

Registry obligations: `panel_type` family.

DoD#2 obligations: add a check that panel types resolve to registered ids and
that PHB holds no saved UI state.

## Slice 10 - `B3-RESOURCE-POOLS`: Author Resources + Unit Pools

**Goal:** the two-scope author-resource model — a roster multi-resource wallet +
per-unit pools — over the Band 2 ledger, per `THL-4` / `REQ-12`. (Training/shop
consumers are Band 4+; this slice provides the substrate + registry only.)

Files to create or touch:

- `scripts/resources/ResourceTypeDef.gd` (registry entry: `{id, scope:
  roster|unit, default, max?}`)
- `scripts/autoloads/GameState.gd` (`party_gold` -> `{resource_id: amount}`
  roster wallet)
- `scripts/resources/UnitData.gd` (per-unit pools `{pool_id: {current, max}}`)
- `scripts/autoloads/ResourceLedger.gd` (extend wallet/cost paths to keyed
  resources + unit pools — do not fork a second spending system)
- `scripts/tests/test_resource_pools.gd`

Implementation steps:

1. Add `ResourceTypeDef` registry entries; `party_gold` and `unit_gold` become
   the first developer presets (consistent with the Band 2 ledger).
2. Generalize the roster wallet from a single `party_gold` int to a keyed
   `{resource_id: amount}` dict (e.g. activity/professor points), with a derived
   `party_gold` getter for back-compat.
3. Add per-unit pools on `UnitData` (`current`/`max`), exposing the `REQ-12`
   `pool:<id>.current/max/pct` value-term sources.
4. Route all spend/refill through the existing `ResourceLedger` cost path; a cost
   references `{id, scope}` (`THL-4`). No training/shop UI here.

Tests:

- Roster wallet spend/credit for a custom resource through the ledger.
- Per-unit pool spend/refill; `pct` value-term reads correctly.
- Multi-resource atomic spend; failure mutates nothing.
- `party_gold` back-compat getter matches the keyed wallet.
- A data-defined resource type registers without an engine edit.

F1 obligations: reserve the roster multi-resource wallet (replacing the
`party_gold` row) and per-unit pools (`THL-6`); migrate old saves' `party_gold`
into the keyed wallet.

Registry obligations: `resource_type` family (shared with the Band 2 ledger).

DoD#2 obligations: extend the Band 2 direct-wallet-write guard to the keyed
wallet and unit pools (writes only through `ResourceLedger`).

## Slice 11 - `B3-CALENDAR-LITE`: In-World Time Substrate

**Goal:** an authored advancing in-world date that dialogue, `REQ` formulas, and
`MET` triggers can read — the substrate only. Promoted from deferred after the
owner named consumers (in-world date in dialogue, overworld encounter spawning,
post-combat date-advance events/dialogue, shop refresh). Owner decisions
(2026-06-30): **per-node authored advance** + **structured calendar**.

Depends on `B3-TCV` (Slice 4, the day counter is a campaign var), `B3-TEXT`
(Slice 3, date formatting), `B3-MET` (Slice 8, date triggers), and `B1-CST`
(progression nodes / campaign save).

Files to create or touch:

- `scripts/resources/CalendarDef.gd` (authored calendar: `start_date`,
  `months: [{name, days, season?}]`, optional `year_label`)
- `scripts/resources/CampaignData.gd` (per-node `advance_days`)
- `scripts/calendar/CalendarClock.gd` (derive day/month/year/season + formatted
  string from the flat day counter + `CalendarDef`)
- `scripts/autoloads/CampaignVars.gd` (`campaign_day` campaign-scope counter +
  derived `date.*` read sources)
- `scripts/autoloads/MapEventManager.gd` (add `date_reached` / `date_advanced`
  triggers)
- `scripts/text/TextDB.gd` (date interpolation token)
- `scripts/tests/test_calendar.gd`

Implementation steps:

1. Add `CalendarDef` as authored data (months with lengths/names/seasons); load
   it through the registry as the campaign's calendar (open, not a hardcoded
   Gregorian model).
2. Store the flat in-world day as a campaign-scope `CampaignVars` counter
   (`campaign_day`); `CalendarClock` derives `{day, month, year, season,
   formatted}` from it — flat storage, structured derivation.
3. **Per-node advance:** each progression node declares `advance_days`; on node
   completion (post-combat **victory** for `battle` nodes — defeat/Retry does
   not advance the day — on Continue for `hub` nodes per `PHB-4`) advance
   `campaign_day` by that amount once, latched against re-advance on
   suspend/reload.
4. Expose `date.day` / `date.month` / `date.year` / `date.season` and the
   formatted string as `REQ`/TCV value sources and a `TextDB` interpolation
   token, so dialogue and formulas read the date.
5. Add `date_reached(target)` and `date_advanced` `MET` triggers so events and
   dialogue fire when the date crosses a threshold or ticks (the post-combat
   date-advance consumer).
6. Do **not** build the consumers here: dialogue interpolation rides Band 4
   dialogue, shop refresh rides Band 4 shop (point its `restock_every_n` cadence
   at the date), and overworld encounter spawning rides the post-v1 overworld.

Tests:

- Completing nodes advances `campaign_day` by each node's `advance_days`; the
  advance is latched (suspend/reload does not double-count).
- `CalendarClock` derives the correct day/month/year/season across month
  rollover for a fixed `CalendarDef`.
- A formatted date string interpolates into a text key.
- `date_reached`/`date_advanced` triggers fire at the right time.
- A `compare` formula gating on `date.day` evaluates correctly.

F1 obligations: reserve the `campaign_day` counter (campaign scope; rides the
Slice 4 `CampaignVars` rows) and the per-node advance latch. `CalendarDef` and
per-node `advance_days` are authoring data, not saved.

Registry obligations: the `calendar` family (one per campaign) + the new
`date_reached`/`date_advanced` `trigger_type` entries.

DoD#2 obligations: add a check that `date.*` value sources and the date triggers
resolve to registered ids, and that `campaign_day` is written only through the
node-advance path (not ad-hoc).

## Implementation Commit Order

Recommended logical commits (each independently green and bisectable):

1. `B3-STAT-REGISTRY` (per sub-plan).
2. `B3-MOVEMENT-VULN-REGISTRY` (per sub-plan).
3. `B3-TEXT` text indirection + missing-key check.
4. `B3-TCV` variable store + `groups` field.
5. `B3-REQ` Requirement evaluator + formula evaluator (then `chance` once PKGA
   is in; the remaining `REQ-11..15` families land per Band 4+ consumer).
6. `B3-CAMPAIGN-RULES` rule profiles + tunable layer.
7. `B3-COMBAT-ROLL-RESOLVER` registry promotion + sandboxed-expression tier.
8. `B3-MET` map events + objective opening.
9. `B3-PHB` prep-hub container.
10. `B3-RESOURCE-POOLS` two-scope resources.
11. `B3-CALENDAR-LITE` in-world time substrate (after `TCV`, `TEXT`, `MET`).

If a slice changes player-visible behavior, update the affected `GDD_01`,
`GDD_02`, `GDD_03`, `GDD_06`, `GDD_07`, `GDD_08`, and/or `GDD_10_Roadmap.md`
status rows in the same commit (DoD#1).

## Verification Checklist

Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Run targeted tests as the slice demands:

```bash
godot --headless --path /workspace --script res://scripts/tests/test_text_db.gd
godot --headless --path /workspace --script res://scripts/tests/test_campaign_vars.gd
godot --headless --path /workspace --script res://scripts/tests/test_requirement.gd
godot --headless --path /workspace --script res://scripts/tests/test_formula_evaluator.gd
godot --headless --path /workspace --script res://scripts/tests/test_campaign_rule_profiles.gd
godot --headless --path /workspace --script res://scripts/tests/test_roll_resolver.gd
godot --headless --path /workspace --script res://scripts/tests/test_map_events.gd
godot --headless --path /workspace --script res://scripts/tests/test_prep_hub.gd
godot --headless --path /workspace --script res://scripts/tests/test_resource_pools.gd
godot --headless --path /workspace --script res://scripts/tests/test_calendar.gd
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```

## Open Owner Questions

Tracked in
[`band3_implementation_plan_review_2026-06-30.md`](../../Code%20Reviews/band3_implementation_plan_review_2026-06-30.md):

1. **Per-map override scope.** **Accepted** — campaign-default scope only for v1
   (matches `CRR-4`); `TCV` map-scope vars stay part of `TCV` core (not a
   CampaignRules override), and `MET` `set_var` covers mid-map runtime changes.
   Per-map overrides are delayed but tracked as the deferred control-plane row
   `B6-PER-MAP-OVERRIDES` (depends on `B3-TCV`/`B3-CAMPAIGN-RULES`/`B3-REQ`).
2. **Combat-roll-resolver placement.** **Accepted** — a late slice (Slice 7) in
   this combined plan, not a separate follow-on.
3. **`B3-RESOURCE-POOLS` inclusion.** **Accepted** — a substrate-only slice
   (Slice 10), deferring training/shop wiring to Band 4 consumers.
4. **`B3-CALENDAR-LITE`.** **Resolved (owner)** — promoted from deferred to a
   substrate-only slice (Slice 11): per-node authored advance + structured
   calendar; consumers stay in their own bands.
