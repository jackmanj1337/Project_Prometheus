---
Type: plan
Status: Active - next-session handoff
Last verified: 2026-06-30
---

# Band 4 Implementation Plan — Next-Session Handoff

**Purpose.** Hand the next session everything it needs to write the Band 4
campaign-loop-vertical-slice implementation plan(s), the same way the Band 1,
Band 2, and Band 3 plans were drafted. This doc does not write the plan; it
scopes it, lists read-first material, fixes the bootstrap order, names the
decisions not to reopen, and surfaces the owner questions.

**Deliverable to produce next session:** the Band 4 implementation plan under
`AGENT/Docs/plans/` (see the Owner Question on one-combined-plan vs split), plus
updated Band 4 control-plane rows, a regenerated docs index, and a commit.

## Gating Reality

Plan now; implement after gates. Band 4 implementation must not start before:

- Band 1 (`B1-PKGA`, `B1-F1`, `B1-CST`/`B1-SAVECODEC`) lands — Band 4 is the
  first band that runs a *whole campaign loop*, so it needs the save/campaign
  spine, not just the determinism gate.
- Band 2 services exist for the consumers that need them: `B2-OCCUPANCY`
  (map objects), `B2-RESOURCE-LEDGER` (shop), `B2-DEATH-LIFECYCLE` (death mode),
  `B2-ACTION-EFFECT` (object/dialogue/map-event primitives).
- The relevant Band 3 contracts are accepted and building: `B3-STAT-REGISTRY`
  (items read stats), `B3-MET` + `B3-PHB` (map objects), `B3-TEXT` + `B3-REQ`
  + `B3-MET` (dialogue), `B3-CAMPAIGN-RULES` + `B3-TCV` (difficulty/death mode).

Writing the plan now is fine; it is a planning artifact, not a build
authorization. The `B4-CAMPAIGN-LOOP` row's standing next-action is "draft after
Band 1-3 contracts are accepted" — that condition is the trigger for *building*,
not for *planning*.

## Rows To Cover

From the Project Control Plane Band 4 block
([`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)):

- `B4-IEQ` — item/equipment composition build. **Internal sub-foundation #1.**
- `B4-MAP-OBJECTS` — unified `map_objects`/activation component contract.
  **Internal sub-foundation #2.** Has a design doc already.
- `B4-PXP` — proficiency / XP framework (sibling to class leveling; has a
  boundary plan already).
- `B4-DIALOGUE-V1` — narrow line/choice/command dialogue slice.
- `B4-CONVOY` — convoy / party inventory (UI/UX plan owed).
- `B4-SHOP-ECONOMY` — shops, shopper subject, dynamic pricing, stock gates
  (UI/UX plan owed; pair with convoy).
- `B4-DCH` — doors and chests (specialized `map_objects`).
- `B4-VILLAGE` — village / house visit.
- `B4-RECRUIT-BASIC` — talk/recruit map units into the roster.
- `B4-DIFFICULTY-DEATHMODE` — difficulty palettes/typed variables +
  `classic`/`casual`/`phoenix` death modes (the content layer over
  `B3-CAMPAIGN-RULES`/`B3-TCV`).
- `B4-PREP-DEPLOYMENT` — pre-battle deployment (roster, inventory/trade, launch).
- `B4-CAMPAIGN-LOOP` — the integrating vertical slice; **last**.
- `B4-PROMOTION-UI` — keep conditional/deferred unless v1 content uses 3+
  promotion paths (no register; only a feature-index need).

## Bootstrap Order (Do Not Get Wrong)

Two internal sub-foundations gate the rest of the band: **`B4-IEQ` (items)** and
**`B4-MAP-OBJECTS` (activation)**. Recommended order:

1. **`B4-IEQ`** — componentized items/weapons/accessories, runtime item state,
   equip/source ownership. Convoy, shop, DCH, and PXP all depend on it. Plan a
   *staged migration* off the current item model, not a big-bang rewrite.
2. **`B4-MAP-OBJECTS`** — the activation component contract (doors, chests,
   shops, villages, breakables, panels, cursor-triggered objects). DCH and
   village are specialized cases; on-map shop/panel instances reuse the
   `B3-PHB` dual-surface.
3. **`B4-PXP`** — proficiency tracks + data-driven class-EXP award hooks; keep
   class-leveling storage separate (the boundary plan already fixes this).
4. **`B4-DIALOGUE-V1`** — depends only on Band 3 (`TEXT`/`REQ`/`MET`); gates
   recruit and village. Define the *narrow* v1 command set.
5. **`B4-CONVOY`** — items + `B3-PHB`; design the panel UX with shop/trade.
6. **`B4-SHOP-ECONOMY`** — `B2-RESOURCE-LEDGER` + `B3-PHB` + items; pair UX with
   convoy.
7. **`B4-DCH`** — after `B4-MAP-OBJECTS` + items.
8. **`B4-VILLAGE`** — after map objects + `B3-MET` + dialogue.
9. **`B4-RECRUIT-BASIC`** — after dialogue + `B3-REQ`; stage recruit before any
   capture-carry expansion.
10. **`B4-DIFFICULTY-DEATHMODE`** — `B3-CAMPAIGN-RULES` + `B2-DEATH-LIFECYCLE` +
    `B3-TCV`; build before broad campaign playtest.
11. **`B4-PREP-DEPLOYMENT`** — `B1-CST` + `B3-PHB` + convoy.
12. **`B4-CAMPAIGN-LOOP`** — the integration slice that proves map ->
    victory/defeat -> prep -> next map with save/suspend. **Last.**
13. **`B4-PROMOTION-UI`** — conditional; defer until content needs 3+ paths.

## Read First

1. This handoff.
2. [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
   Band 4 rows.
3. The accepted upstream plans:
   [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md),
   [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](band2_shared_runtime_contracts_implementation_plan_2026-06-30.md),
   [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md).
4. The Band 4 design docs that already exist (reuse, do not rewrite):
   [`map_object_component_contract_2026-06-28.md`](../design/map_object_component_contract_2026-06-28.md),
   [`class_exp_pxp_boundary_plan_2026-06-29.md`](class_exp_pxp_boundary_plan_2026-06-29.md),
   [`campaign_save_player_facing_firming_2026-06-21.md`](../design/campaign_save_player_facing_firming_2026-06-21.md).
5. The triage that seeded the vertical slice:
   [`planned_unimplemented_feature_triage_2026-06-28.md`](planned_unimplemented_feature_triage_2026-06-28.md).
6. Registers named by the Band 4 rows:
   [`items_equipment_model_open_questions_2026-06-23.md`](../registers/items_equipment_model_open_questions_2026-06-23.md),
   [`proficiency_xp_framework_open_questions_2026-06-23.md`](../registers/proficiency_xp_framework_open_questions_2026-06-23.md),
   [`shop_activate_configs_open_questions_2026-06-27.md`](../registers/shop_activate_configs_open_questions_2026-06-27.md),
   [`convoy_inventory_open_questions_2026-06-23.md`](../registers/convoy_inventory_open_questions_2026-06-23.md),
   [`shop_economy_open_questions_2026-06-23.md`](../registers/shop_economy_open_questions_2026-06-23.md),
   [`doors_chests_open_questions_2026-06-21.md`](../registers/doors_chests_open_questions_2026-06-21.md),
   [`village_events_open_questions_2026-06-25.md`](../registers/village_events_open_questions_2026-06-25.md),
   [`dialogue_conversation_system_open_questions_2026-06-25.md`](../registers/dialogue_conversation_system_open_questions_2026-06-25.md),
   [`recruit_capture_open_questions_2026-06-24.md`](../registers/recruit_capture_open_questions_2026-06-24.md),
   and [`difficulty_death_mode_open_questions_2026-06-27.md`](../registers/difficulty_death_mode_open_questions_2026-06-27.md).

## Recommended Plan Shape

- Frontmatter: `Type: plan`, `Status: Active - implementation plan`,
  `Last verified: <date>`.
- Purpose, scope, non-goals.
- Dependency note: planning now; implementation after Band 1-3 gates.
- Ordered slices following the bootstrap order above. Each slice carries:
  files-to-touch, implementation steps, tests, F1/save rows, registry
  obligations, and DoD#2 obligations (same per-slice shape as the Band 2/3
  plans).
- Reuse the existing `map_object_component_contract`, `class_exp_pxp_boundary`,
  and `campaign_save_player_facing_firming` docs by reference instead of
  restating them.
- Treat `B4-IEQ` as a staged migration plan (the current item model exists), not
  a greenfield build — call out the migration steps explicitly.
- After adding the plan: update the Band 4 control-plane rows to point at it, run
  `python3 AGENT/Docs/gen_docs_index.py`, `python3 AGENT/Docs/check_docs.py`, and
  `git diff --check`, then commit the plan and generated index together.

## Decisions Not To Reopen

- Author-facing vocabularies are open registries / data composition, not closed
  `enum` + `match`. Item components, object/component types, dialogue
  commands, recruit predicates, and difficulty profiles are all registry
  families.
- F1 owns saved-field manifest rows before any Band 4 feature adds saved state
  (item instances, convoy inventory, object state, roster additions, dialogue
  flags via vars, selected difficulty/death mode).
- `B4-MAP-OBJECTS` is the single activation model; doors/chests/villages/shops
  are specialized object/component types on it, not parallel systems (the design
  doc already firms this; `SAC` resolved the dual-surface contract).
- Shops/panels reuse the `B3-PHB` dual-surface (prep button **or** on-map
  trigger), not a bespoke shop UI stack.
- Resource spending goes through `B2-RESOURCE-LEDGER`; shops do not mutate
  wallets directly.
- Deaths route through `B2-DEATH-LIFECYCLE`; death modes
  (`classic`/`casual`/`phoenix`) are a CampaignRules selection over that funnel
  (`DIF-1`), with revived units returning empty (`DTH-1`/`DIF-2`).
- Class EXP storage stays separate from PXP storage (the boundary plan); they
  share award/authoring idioms only.
- `B4-PROMOTION-UI` stays conditional/deferred unless v1 content uses 3+
  promotion paths.

## Owner Questions To Surface

Raise these while drafting; do not assume answers:

- **One combined Band 4 plan, or split?** Band 4 is much larger and more
  UI-heavy than Band 3. Options: (a) one combined plan with all slices; (b) two
  standalone sub-plans for the internal sub-foundations `B4-IEQ` and
  `B4-MAP-OBJECTS` (like the movement/stat sub-plans), plus a thinner
  `B4-CAMPAIGN-LOOP` integration plan that references them. Recommendation: (b),
  because IEQ is a staged migration and map-objects has its own design contract,
  so each reads better as a focused plan.
- **Minimum playable loop for `B4-CAMPAIGN-LOOP` v1.** What is the smallest set
  of consumers the first playable loop must include? E.g. is shop/convoy
  required for the first loop, or can the first loop be
  prep -> map -> victory/defeat -> next map with only deployment + recruit +
  difficulty, deferring shop/convoy to a fast-follow?
- **Convoy + shop UI/UX timing.** Both rows owe a UI/UX plan and are flagged to
  pair. Should the Band 4 plan include their UI design, or defer the UI layer to
  a dedicated UX pass (intersecting the Band 6 `B6-MRD`/`B6-INPUT` UI work)?
- **Dialogue v1 command set.** How narrow is "narrow"? Confirm the v1 command
  vocabulary (line, choice, set_var/flag, `end_map`, recruit hook?) before
  building, since recruit and village depend on it.

## Watchouts

- Do not start Band 4 implementation before Band 1-3 contracts are accepted and
  the named Band 2/3 services exist.
- Do not add saved Band 4 fields without F1 manifest rows.
- `B4-IEQ` is a *migration*, not greenfield — plan to keep the suite green
  through staged steps.
- Keep `B4-IEQ` and `B4-MAP-OBJECTS` first; most of the band depends on one or
  both.
- Band 4 is UI-heavy (convoy, shop, dialogue, prep, promotion); watch the
  overlap with the Band 6 UI/input rows so the same selector/input work is not
  built twice.
- Reuse, do not rewrite, the map-object, PXP-boundary, and prep-firming docs.
