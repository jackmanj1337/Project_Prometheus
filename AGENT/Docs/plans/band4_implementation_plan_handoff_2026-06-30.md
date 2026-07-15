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

**Deliverable to produce next session:** **separate** Band 4 implementation
plans under `AGENT/Docs/plans/` (owner decision `D1` below — not one combined
plan), starting with the two internal sub-foundations (`B4-IEQ`,
`B4-MAP-OBJECTS`); plus updated Band 4 control-plane rows, a regenerated docs
index, and commits. The owner questions in this handoff are now **resolved** —
see "Resolved Owner Decisions" below; draft against those.

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

Per `D1`, write **separate** plans, not one combined plan. Distinct plans:
`B4-IEQ`, `B4-MAP-OBJECTS`, `B4-CONVOY`, `B4-SHOP-ECONOMY`, and the thin
`B4-CAMPAIGN-LOOP` integration plan. The smaller consumers (`B4-PXP`,
`B4-DIALOGUE-V1`, `B4-DCH`, `B4-VILLAGE`, `B4-RECRUIT-BASIC`,
`B4-DIFFICULTY-DEATHMODE`, `B4-PREP-DEPLOYMENT`) may be grouped pragmatically but
follow the bootstrap order. Start with `B4-IEQ` and `B4-MAP-OBJECTS`.

Each plan:

- Frontmatter: `Type: plan`, `Status: Active - implementation plan`,
  `Last verified: <date>`.
- Purpose, scope, non-goals.
- Dependency note: planning now; implementation after Band 1-3 gates.
- Ordered slices, each carrying files-to-touch, implementation steps, tests,
  F1/save rows, registry obligations, and DoD#2 obligations (same per-slice
  shape as the Band 2/3 plans).
- Reuse the existing `map_object_component_contract`, `class_exp_pxp_boundary`,
  and `campaign_save_player_facing_firming` docs by reference instead of
  restating them.
- Treat `B4-IEQ` as a **staged migration** plan (the current item model exists),
  not a greenfield build — call out the migration steps explicitly.
- `B4-CAMPAIGN-LOOP` is the **integration** plan: it references the others and
  proves the loop end to end; it does not restate their slices.
- After adding each plan: update its Band 4 control-plane row(s) to point at it,
  run `python3 AGENT/Docs/gen_docs_index.py`, `python3 AGENT/Docs/check_docs.py`,
  and `git diff --check`, then commit the plan and generated index together.

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

## Resolved Owner Decisions (2026-06-30)

These were the open owner questions; all are now decided. Draft against them; do
not reopen.

**D1 — Plan structure: separate plans, not one combined plan.** Write `B4-IEQ`,
`B4-MAP-OBJECTS`, `B4-CONVOY`, `B4-SHOP-ECONOMY`, and a thin `B4-CAMPAIGN-LOOP`
integration plan as distinct plans; the smaller consumers may be grouped
pragmatically but follow the bootstrap order. `B4-PROMOTION-UI` stays deferred
until content needs 3+ promotion paths.

**D2 — Minimum playable loop / sequencing.** **Convoy and shop are separable
from the first playable loop for playtesting, but must follow closely.** The
first `B4-CAMPAIGN-LOOP` slice proves map -> victory/defeat -> prep -> next map
with save/suspend; convoy lands as a close fast-follow and shop closely after
convoy (shared economy/PHB surfaces; pair the UX). The exact minimum-loop
content is finalized inside the campaign-loop plan.

**D3 — Convoy/shop UI/UX timing (was Q3).** Build functional panels on the
`B3-PHB` surface now — **keyboard+mouse-first and visually rough** — with both
consuming a thin **selector abstraction** that `B6-INPUT` later fills/extracts
(flag the overlap so the selector is not built twice). Two firm commitments that
are **not** dropped: (1) every planned control scheme (gamepad, key-rebind) gets
full support via `B6-INPUT`; (2) UI polish lands as a follow-up. Convoy interface
design targets are captured as `[CNV-8]` in the convoy register: per-character
inventory view; author-defined groups + an "All" category with author-defined
sorting; per-item rows showing author-selected fields from {name, uses info,
count, base value, stack value}; and a top "more info" detail pane for the
focused item.

**D4 — Dialogue v1 command set (was Q4).** The `B4-DIALOGUE-V1` slice ships:
- Entry types: `line`, `choice` (`goto` + `set_flag`), `label`.
- Commands: `set_background: map | <bg>`; **positioned stage elements** — a
  portrait can `enter` at an authored screen location, `move` to another
  location, `exit`, and be replaced (exit+enter); plus a small MET-action
  passthrough (`set_var`/`flag`, `grant_item`, the recruit hook).
- `B3-REQ`/F16 branch gating at **option + conversation** scope (segment-scope
  deferred), with per-option `hidden | shown_disabled`.
- Manual pacing; **static** portraits; **atomic (run-to-completion) playback**.
- **Deferred** (reserved by the format, layer in later without changing authored
  data): the animation/expression effect tiers (`DLG-3`), the reflect effect
  (`DLG-9`), auto-advance/skip-to-decision pacing (`DLG-4`), camera, scene-wide
  filters, runtime `set_layer` (`DLG-12`), mid-conversation suspend (`DLG-11`),
  and the dedicated editor (`DLG-8`).

This is the `DLG-7` "v1 slice = build-time call" decision; the dialogue register
`DLG-7` carries a pointer back here.

**D5 — Grouping of the seven smaller consumers (owner, 2026-07-02).** Decided
while closing audit finding C2
([`band_plans_audit_2026-07-02.md`](../../Code%20Reviews/band_plans_audit_2026-07-02.md)).
The thin `B4-CAMPAIGN-LOOP` integration plan is now written
([`band4_campaign_loop_implementation_plan_2026-07-02.md`](band4_campaign_loop_implementation_plan_2026-07-02.md)).
The remaining seven tracks are owned by **three grouped plans**, drafted at the
existing trigger (when the Band 1-3 contracts are accepted), following the
bootstrap order:

1. **Band 4 enablers plan** — `B4-PXP` + `B4-DIALOGUE-V1` (the two mid-order
   prerequisites; PXP drafts from the existing class-EXP/PXP boundary plan).
2. **Band 4 map-content plan** — `B4-DCH` + `B4-VILLAGE` + `B4-RECRUIT-BASIC`
   (specialized map-object + dialogue consumers with shared fixtures).
3. **Band 4 campaign-wrappers plan** — `B4-DIFFICULTY-DEATHMODE` +
   `B4-PREP-DEPLOYMENT` (wrap the campaign/prep spine, not the map).

`B4-PROMOTION-UI` stays conditional/deferred per `D1`.

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
