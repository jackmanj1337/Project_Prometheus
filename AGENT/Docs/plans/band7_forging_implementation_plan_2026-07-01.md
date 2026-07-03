---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-01
---

# Band 7 Forging Implementation Plan

**Started:** 2026-07-01.

**Track ID:** `B7-FORGING`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 7 rows. Drafted from the resolved register
[`forging_open_questions_2026-07-01.md`](../registers/forging_open_questions_2026-07-01.md)
(`[FRG-1..20]` RESOLVED, see its §3c/§3d/§3e).

## Purpose

Turn the resolved forge design into a code-ready build sequence. Forging is a
registry-driven **service + PHB panel** consumer that mirrors `ShopService`/`ShopPanel`,
spends through `ResourceLedger`, and writes **per-instance** upgrade state onto
`InventoryEntry`. The one load-bearing engine change is an **effective-weapon-stat
resolver** so combat/range/UI stop reading raw weapon stats.

This plan is a build plan only. It does not authorize starting `B7-FORGING`
before the Band 1-4 gates, `B4-IEQ`, `B4-SHOP-ECONOMY`, and `B4-CONVOY` land.

## Scope (v1 slice, per register §3c/§3e)

1. Add the forge **open registries**: upgrade ops, forgeable-attribute targets, and
   forge-cost resources.
2. Add the **effective-weapon-stat resolver** seam and route all readers through it.
3. Add the **`forged_mods` op-overlay** schema + a player **custom-name** field, with
   F1 reservations.
4. Add the **effective-cap + target-item predicate resolver** (`min(item, forge-instance)`
   caps; forge offering/hide predicates that read the candidate item instance).
5. Add `ForgeService` **quote/commit** through `ResourceLedger` for **point-allocation
   upgrades** and **repair** (author formula), gold-only fixtures, multi-resource shape.
6. Build the two-mode **PHB forge panel** (allocation grid + Modify item-op list) reusing
   `PanelSelector`/`FocusedDetailPane`.
7. Make forged instances **player-renamable and non-mergeable** in convoy.
8. Reserve — do not build — transform, effect-grants, item-as-cost, on-map/dialogue
   entry points, and the per-map forge allowance.

## Non-Goals

- Do not build **transform** (`[FRG-4]`), **effect/effect-bundle grants** (`[FRG-18]`,
  depends on Band 5 Q5), **item-as-forge-cost** (`[FRG-19]`), on-map/dialogue forge entry
  points, or the per-map/shop-cadence forge charge (`[FRG-7]`) in the v1 slice. Reserve
  their seams only.
- Do not fold the forge into the shop panel yet. v1 is a **standalone** forge panel on the
  **shared transaction core**; the shared surface refactor lands with transform (`[FRG-20]`).
- Do not read raw `weapon.mt`/`hit`/`crit`/`wt` at any combat/range/UI call site after
  Slice 2 — go through the resolver.
- Do not mutate wallets directly; all quotes/commits go through `ResourceLedger`.
- Do not build polished UI or full control-scheme support; `B6-INPUT` owns that follow-up.
- Do not hardcode a forge upgrade table, cost table, or gate as an `enum`+`match`. Every
  forge vocabulary is an open registry read by the service (AGENTS.md / `[EXT]`).

## Source Docs

- [`forging_open_questions_2026-07-01.md`](../registers/forging_open_questions_2026-07-01.md)
  (`[FRG-1..20]`, the authoritative spec — §3c decisions, §3d refinements, §3e UI)
- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`band4_items_equipment_implementation_plan_2026-06-30.md`](band4_items_equipment_implementation_plan_2026-06-30.md)
  (`InventoryEntry`/`forged_mods`/`WeaponComponent` substrate)
- [`band4_shop_economy_implementation_plan_2026-06-30.md`](band4_shop_economy_implementation_plan_2026-06-30.md)
  (service/panel template forging mirrors)
- [`band4_convoy_implementation_plan_2026-06-30.md`](band4_convoy_implementation_plan_2026-06-30.md)
  (merge/grouping the non-mergeable rule keys off)
- [`resource_ledger_cost_resolver_contract_2026-06-28.md`](../design/resource_ledger_cost_resolver_contract_2026-06-28.md)

## Decisions Not To Reopen (register §3c/§3d/§3e)

- v1 upgrade shape is **point allocation** (total-point max + per-stat max + per-stat step
  size, all author data). `+N` and transform stay registerable but unauthored in v1.
- `forged_mods` stores **applied ops** (op ids + params), not raw stat deltas; the registry
  derives effective deltas.
- Effective caps = **min(item author caps, forge-instance caps)**; forge-instance caps may be
  fixed or predicate-derived.
- Forge offering/hide predicates may read the **candidate item instance** (def, tags, current
  `forged_mods` level), not just campaign/roster state.
- Repair is **default-on and live in v1**; its cost is an author formula over base item,
  current uses, max uses, item value, and current mods.
- Costs are gold-only in v1 via an author `REQ-16` formula (default flat); the `CostSpec`
  shape stays multi-resource.
- Forges are **permanent** in v1; **resource-gated only** (no count cap).
- Forged instances are **player-renamable and non-mergeable**.
- Forge panel is a **standalone two-mode PHB panel** (allocation grid + Modify item-op list)
  on the shared `ResourceLedger` transaction core.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before `B7-FORGING` code:

- `B4-IEQ` for `WeaponComponent`/`ItemDef` stat fields, `InventoryEntry` instances, and the
  reserved `forged_mods` overlay.
- `B4-SHOP-ECONOMY` for the shared transaction core, `PanelSelector`/`FocusedDetailPane`, and
  the shop-hide gating pattern the forge extends.
- `B2-RESOURCE-LEDGER` + `B3-RESOURCE-POOLS` for quote/commit.
- `B3-REQ` + `REQ-16` for offering/cap predicates and cost formulas (with the target-item
  subject extension from Slice 4).
- `B3-PHB` for the panel container.
- `B4-CONVOY` for the non-mergeable grouping rule.

## Existing Code Touchpoints

Verified 2026-07-01:

- `scripts/resources/InventoryEntry.gd` — `forged_mods: Dictionary = {}` exists, **no reader**
  (Slice 3 gives it a schema + reader). No `custom_name` field yet (Slice 7 adds it).
- `scripts/resources/WeaponData.gd` — `mt`, `hit`, `crit`, `wt`, `uses`, `cost`, `effect_tags`,
  `strikes_per_attack`, range formulas, all read directly by combat/range/UI (Slice 2 seam).
- `CombatResolver`, range calc, weapon menu, character sheet — the raw-stat readers to route
  through the resolver.
- `ShopService`/`ShopPanel`/`PanelSelector`/`FocusedDetailPane` (from `B4-SHOP-ECONOMY`) — the
  templates to reuse, not re-implement.
- Tests to extend/create: new `test_forge_*` suites; extend `test_inventory_entry.gd`,
  combat resolver tests (resolver guard), and convoy merge tests.

## Slice 0 - Preflight After Gates

**Goal:** confirm items, ledger, shop core, PHB, and convoy foundations are ready.

Checklist:

- `rg -n "forged_mods|WeaponComponent|ResourceLedger|PanelSelector|FocusedDetailPane|ShopService" scripts data`.
- Confirm `ResourceLedger.quote()`/`commit()` support party/shopper-scoped costs.
- Confirm the shop shared transaction core exposes a reusable quote/commit entry.
- Confirm `PanelSelector`/`FocusedDetailPane` exist and are reusable.
- Confirm `B3-REQ` exposes a subject/context object a new subject can be added to (Slice 4).

Tests: none in preflight.

## Slice 1 - Forge Registries And Def Schemas

**Goal:** represent the forge vocabulary as author data (open registries).

Files to create/touch:

- `scripts/resources/forge/ForgeUpgradeDef.gd` — one upgrade op: `id`, `kind`
  (`allocate` | `repair` | reserved `transform`/`effect_grant`), `applies_to` item filter,
  per-target `stat`/`step_size`/`per_stat_max`, `total_point_max`, `cost_formula`
  (`REQ-16`), optional `req` gate.
- `scripts/resources/forge/ForgeConfig.gd` — a forge **instance**: `id`, offered upgrade-op
  ids, per-instance **cap overrides** (`total_point_cap`, per-stat caps — fixed or predicate),
  offering/hide predicates (the target-item gate, Slice 4), and the effect-slot **campaign
  rule** toggle (do effect grants draw from the point budget or a separate slot pool).
- `scripts/autoloads/DataManager.gd` — register the forge families.
- forgeable-attribute **target registry** entries (`mt/hit/crit/wt`, `uses` via repair).
- `scripts/tests/test_forge_defs.gd`.

Steps:

1. Add the three def/registry types above; all ids validate through the registry.
2. Validate stat targets against the forgeable-attribute registry, resource ids against the
   resource registry, predicates through `B3-REQ`, cost formulas through `REQ-16`.
3. Seed one gold-only point-allocation upgrade + one repair op + one `ForgeConfig` fixture.

Tests:

- A data-defined forge op/config loads with no engine switch edit.
- Unknown stat target, resource id, predicate, or formula term fails validation.
- Adding a second stat target (e.g. `crit`) is pure data.

F1 obligations: none (defs are authoring).
DoD#2 obligations: validation that forge defs reference registry-backed ids only.

## Slice 2 - Effective-Weapon-Stat Resolver Seam (load-bearing)

**Goal:** one resolver returns `base + forged deltas`; all readers route through it.

Files to create/touch:

- `scripts/combat/WeaponStats.gd` (or equivalent) — `effective(component, entry) -> {mt,hit,crit,wt,...}`
  applying the deltas the registry derives from `entry.forged_mods` (Slice 3).
- `CombatResolver`, range calc, weapon menu, character sheet — call the resolver.
- `scripts/tests/test_weapon_stats_effective.gd`.

Steps:

1. Add the resolver; with an empty `forged_mods` it returns base stats unchanged.
2. Migrate every raw `weapon.mt/hit/crit/wt` read to the resolver.
3. Add a guard test/check (DoD#2) that no non-test combat path reads raw weapon stats.

Tests:

- Empty overlay → identical to base (no behavior change for unforged weapons).
- A synthetic `+2 Mt` overlay raises effective Mt everywhere combat reads it.
- Guard: `rg` finds no raw stat reads outside the resolver.

F1 obligations: none.
DoD#2 obligations: the raw-stat-read guard.

## Slice 3 - forged_mods Op-Overlay Schema + F1

**Goal:** give `forged_mods` a replayable op-overlay schema and a reader.

Files to touch:

- `scripts/resources/InventoryEntry.gd` — document/shape `forged_mods` as
  `{ "ops": [ {"op_id","params"} ... ] }`; keep it a `Dictionary` for save compatibility.
- forge registry — a `derive_deltas(entry) -> Dictionary` that replays ops into effective
  stat deltas (consumed by Slice 2).
- `scripts/tests/test_forged_mods_overlay.gd`.

Steps:

1. Define the op-overlay shape and a validator.
2. Implement `derive_deltas` (ops → deltas), enabling reset/caps/preview downstream.
3. Confirm F1 persists the richer overlay (already a saved `Dictionary`; assert round-trip).

Tests:

- Ops round-trip through save/load unchanged.
- `derive_deltas` is deterministic and matches the applied ops.
- A malformed overlay fails validation without crashing combat.

F1 obligations: confirm `forged_mods` saves the op-overlay (no flat-delta assumption).

## Slice 4 - Effective-Cap + Target-Item Predicate Resolver

**Goal:** compute effective caps and gate offerings over the candidate item.

Files to create/touch:

- `scripts/forge/ForgeEligibility.gd` — `effective_caps(item, forge_config)` returning
  `min(item caps, forge-instance caps)` (evaluating predicate-derived instance caps); and
  `can_forge(item, forge_config, ctx)` evaluating offering/hide predicates.
- `B3-REQ` subject/context — extend so a predicate can read the **candidate item instance**
  (def, tags, current `forged_mods` forge level).
- `scripts/tests/test_forge_eligibility.gd`.

Steps:

1. Add the item as an addressable `B3-REQ` subject alongside the shopper/roster subjects.
2. Implement effective-cap min-merge (total point + per-stat).
3. Implement offering/hide predicate evaluation (refuse key item; refuse over-upgraded item).

Tests:

- Forge caps clamp below item caps; item caps clamp below forge caps (min holds both ways).
- Predicate-derived per-stat cap resolves over the item/roster subject.
- A `key`-tagged item is refused; an item already at/above the forge's cap is refused.

F1 obligations: none (predicates read existing state).
DoD#2 obligations: validation that the item subject is available to forge predicates.

## Slice 5 - ForgeService Quote/Commit (allocation + repair)

**Goal:** centralize upgrade and repair affordability/commit through `ResourceLedger`.

Files to create/touch:

- `scripts/forge/ForgeService.gd` — `quote_upgrade`/`commit_upgrade` (writes an `allocate`
  op onto `forged_mods`) and `quote_repair`/`commit_repair` (restores `uses_remaining`,
  clears break state). Both go through the shared shop transaction core.
- repair cost formula wired to `REQ-16` with terms: base item, current uses, max uses, item
  value, current mods.
- `scripts/tests/test_forge_transactions.gd`.

Steps:

1. Quote allocation cost via the upgrade op's `REQ-16` formula (default flat); commit spends
   via `ResourceLedger.commit()` and appends the op to `forged_mods`.
2. Enforce effective caps (Slice 4) at quote and commit; over-cap allocation is rejected.
3. Quote/commit repair via its formula; restore uses and clear `break_behavior`.
4. Failed commits mutate nothing (ledger + overlay rollback).
5. Preview == commit (ledger invariant).

Tests:

- Affordable upgrade spends gold and appends the op; effective Mt rises via the resolver.
- Over-cap or unaffordable upgrade mutates nothing.
- Repair restores uses and clears break state; formula terms resolve.
- Quote equals commit for the same item/context.

F1 obligations: overlay writes persist (Slice 3); wallet owned by `B3-RESOURCE-POOLS`.
DoD#2 obligations: a test that forge transactions use `ResourceLedger`, not direct wallet edits.

## Slice 6 - Two-Mode Forge Panel

**Goal:** the standalone PHB forge panel (register §3e), reusing shop UI shared parts.

Files to create/touch:

- `scripts/ui/panels/ForgePanel.gd`, `scenes/ui/panels/ForgePanel.tscn`.
- reuse `scripts/ui/shared/PanelSelector.gd` and `FocusedDetailPane.gd`.
- PHB panel registry entry for `forge`.
- `scripts/tests/test_forge_panel.gd`.

Steps:

1. Left pane: forgeable-item picker (shows current forge state + custom name).
2. Right pane mode tabs `[Upgrade] [Modify]`.
3. Upgrade: per-stat rows with inline `base → new`, a `◂ ±N ▸` stepper bounded by effective
   caps, running `Points x/total`, `ResourceLedger.quote()` cost, a rename field, and Forge.
4. Modify: item-op list (Repair, and a reserved disabled Transform row) with Confirm.
5. Commit via `ForgeService`; no PHB UI state saved.

Tests:

- Focused item updates detail + quoted cost; steppers respect effective caps.
- Forge button calls `ForgeService.commit_upgrade`; Repair calls `commit_repair`.
- Panel consumes `PanelSelector` (no private selector) — DoD#2 guard.

F1 obligations: no saved UI state.

## Slice 7 - Rename And Non-Mergeable Instances

**Goal:** forged entries are player-nameable and never merge with plain copies.

Files to touch:

- `scripts/resources/InventoryEntry.gd` — add `custom_name: String = ""` (saved).
- `scripts/convoy/ConvoyService.gd` — grouping/merge keys off `forged_mods` emptiness
  (and `custom_name`), so a forged/renamed entry is non-mergeable.
- `scripts/tests/test_forge_identity.gd`.

Steps:

1. Add and persist `custom_name`; the rename field (Slice 6) writes it.
2. Display uses `custom_name` when set, else an auto suffix (e.g. "Iron Sword +2").
3. Convoy merge treats non-empty `forged_mods` (or `custom_name`) as non-mergeable.

Tests:

- A forged entry does not stack/merge with an unforged copy.
- `custom_name` round-trips through save and convoy transfer.
- Display falls back to the auto suffix when unnamed.

F1 obligations: `custom_name` is a new saved field on `InventoryEntry`.

## Slice 8 - Reserved Seams (do not build)

**Goal:** leave clean extension points without implementing the deferred features.

Checklist (assert seams, add no behavior):

- `ForgeUpgradeDef.kind` already admits `transform` and `effect_grant` (`[FRG-4]`, `[FRG-18]`)
  — leave them unimplemented; the Modify Transform row stays disabled. Note
  (Q-B5-4, 2026-07-03): `B5-SOURCE-STYLE` was pulled forward, so the effect
  registry `[FRG-18]` depends on lands earlier — `effect_grant` can be implemented
  as soon as forging chooses to, without a separate Band 5 scheduling wait.
- Cost path stays multi-resource so materials (`[FRG-8]`) and the future `item` cost scope
  (`[FRG-19]`) drop in without a service rewrite.
- The shared transaction core keeps an optional trade-in/consume input for the later
  forge⇄shop fold (`[FRG-20]`).
- The per-map forge allowance (`[FRG-7]`) is a later author rule over the shop refresh
  cadence — not wired here.

Tests: none (assertions that the seams exist and are inert).

## Slice 9 - Cleanup And Guards

**Goal:** prevent stat-read and wallet drift after the first implementation.

Checklist:

- Re-run the raw-weapon-stat-read guard (Slice 2) across the tree.
- Confirm no forge-side direct wallet mutation.
- Run the full Godot suite and docs checks.

DoD#1 obligations: update `GDD_04`, `GDD_07`, `GDD_Feature_Index`, and flip the `B7-FORGING`
status in `GDD_10` in the behavior-changing commit.
DoD#2 obligations: land the raw-stat-read guard and the `ResourceLedger`-only forge check in
`check_docs.py`/tests in the same change.
