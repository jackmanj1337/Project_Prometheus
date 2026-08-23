---
Role: dated
Type: plan
Status: Active - next-session handoff
Last verified: 2026-07-02
---

# Band 5 Implementation Plan — Next-Session Handoff

**Purpose.** Hand the next session everything it needs to write the Band 5
tactical-v1-enrichment implementation plan(s), the same way the Band 1-4 plans
were drafted. This doc does not write the plans; it scopes them, lists
read-first material, fixes the bootstrap order, names the decisions not to
reopen, and surfaces the owner questions. Written to close audit finding C1
([`band_plans_audit_2026-07-02.md`](../../Code%20Reviews/band_plans_audit_2026-07-02.md)).

**Standing on settled design:** unlike the Band 3/4 handoffs, most Band 5
design forks are already decided — the owner settled **Q1-Q7** in the
2026-07-01 walkthrough
([`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
→ "Walkthrough Decisions (2026-07-01)"). Draft against those decisions; do not
re-derive them. The only remaining Band 5 design gate is the **Q2 effect
manifest** (demo-campaign-dependent) plus the `on_level_up` trigger resolution.

**Deliverable to produce next session:** separate Band 5 implementation plans
under `AGENT/Docs/plans/` per the recommended grouping below (owner question
Q-B5-2 confirms it), plus updated Band 5 control-plane rows, a regenerated docs
index, and commits.

## Gating Reality

Plan now; implement after gates. Band 5 implementation must not start before:

- Band 1 (`B1-PKGA`, `B1-F1`) lands — condition/skill state needs F1 rows;
  contests (`REQ-10`) and scorer determinism route through `RngService`.
  `B1-SUSPEND` gates only the action-grant counter persistence and can trail.
- Band 2 services exist for the consumers that need them: `B2-REGISTRY`
  (every Band 5 vocabulary), `B2-ACTION-EFFECT` (effects/grants),
  `B2-PROJECTION` (forecasted conditions, effect forecast, AI scorer),
  `B2-OCCUPANCY` (rescue staff, secondary movement).
- The relevant Band 3 contracts are building: `B3-REQ` (contests, cap
  predicates, target filters), `B3-MET` (`set_ai`, group wake), `B3-PHB`
  (loadout panel), `B3-STAT-REGISTRY` (author stats in effect terms).
- `B4-IEQ` for `B5-SOURCE-STYLE` (sources ride items) and for the
  `until_unequipped` producer boundary (see Q-B5-3).

Writing the plans now is fine; they are planning artifacts, not build
authorizations.

## Rows To Cover

From the Project Control Plane Band 5 block
([`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)),
with their settled decisions:

- `B5-CONDITIONS` — combined condition + lifecycle substrate (**Q1**): v1 floor
  = poison, sleep/stun, silence, berserk, Restore/Panacea cure hooks, and the
  `until_unequipped`/`until_end_of_map`/fixed-N duration modes. Silence's
  blocking is a **general capability-gating primitive** (conditions suppress
  named capability tags that actions declare); sleep suppresses all; berserk
  overrides target selection. Adding a condition or gated capability = pure
  data. Row next-action stands: rewrite the old `GDD_10` M8 checklist around
  the registry/condition lifecycle before build.
- `B5-SKILLS-EFFECTS` — effect-id registry conversion, grants/revokes, loadout
  interactions. The **required-v1-ids manifest is Q2, DEFERRED** until the demo
  campaign is designed; plan the machinery so the manifest slots in as a late
  content slice. `on_level_up` is a must-resolve engine trigger, not
  deferrable content.
- `B5-LOADOUT-CAPS` — one panel shell + registry-backed category adapters
  (**Q4**): ship the skills adapter first so this row is not blocked on
  Source+Style; styles/sources plug into the same shell + caps logic later.
  Each category declares its own cap-rule predicate and row renderer.
- `B5-SOURCE-STYLE` — full substrate in one pass (**Q5**): source/style model,
  **effect registry**, target-filter registry, shape registry (interface now;
  single-tile = a 1-tile shape), cost/projection hooks reading the Band 2
  ledger/projection layer, and a generalized effect-forecast rendering damage
  and non-damage outcomes. Prove with exactly **two consumers: one hostile
  style + one utility staff**. Gambits/capture-carry/broad AoE are later
  consumers; the casual-author preset library is later content on the
  registries.
- `B5-UTILITY-STAVES` — the four v1 archetypes (**Q6**): Heal, Restore/Cure
  (proves Q1 cure hooks end-to-end), Rescue (positional; watch `B2-OCCUPANCY`
  edge cases), and a condition-inflicting staff whose hit/resist contest routes
  through the **F16 contest primitive (`REQ-10`)**, never a bespoke roll.
  Exact staff ids are demo-campaign-gated like Q2; Repair/Hammerne deferred.
- `B5-DURATION-LIFECYCLE` — per **Q1** the duration modes are part of the
  combined substrate; per the control-plane row this lands **with its first
  producer, not as label-only work**. See Q-B5-3 for the `B4-IEQ` boundary.
- `B5-ACTION-GRANT` — bounded v1 slice (**Q3**): single-target full-turn ally
  refresh; range, target filter, named grant mode (default
  `refresh_full_turn`), one-refresh-per-unit cap as a **general per-unit
  per-turn action-budget guard**, suspend-safe counters, effect-forecast
  display. Built on the Q5 shared effect pipeline; AoE/remote/self-refresh are
  later authored extensions.
- `B5-SECONDARY-MOVEMENT` — skill-driven move-after-acting with
  remaining/flat modes and an allowed-action list; needs `B2-OCCUPANCY` and a
  safe expression in the action flow.
- `B5-AI-COMPOSITION` — `AIProfileDef` registry data (not an enum, `[AIP]`),
  author-selectable activation order, `set_ai`, seek-tile, group wake; F1 row
  `ai_awake`.
- `B5-AI-MIN-SCORER` — single-ply deterministic scorer (**Q7**): enumerate
  legal (action + target + weapon/source) tuples, weighted sum of
  **registry-backed scorer terms from day one** (immediate projected outcome,
  survival danger, objective pressure, author profile weights),
  best-with-stable-tie-breaks, reusing the same forecast the player sees.
  Knowingly baitable; Band 7 `[VAL]`/`[PER]` adds perception/economy terms and
  `search_depth` as new registered scorers, same engine.

## Bootstrap Order (Do Not Get Wrong)

Two nearly independent chains; the AI chain can run in parallel with the
content chain.

**Content chain:**

1. **`B5-CONDITIONS` first** (needs `B1-F1`, `B2-PROJECTION`,
   `B2-ACTION-EFFECT`). The Q1 combined substrate — conditions, duration
   lifecycle, capability gating, cure hooks — underlies skills, staves, and
   grants. `B5-DURATION-LIFECYCLE` rides here and with each first producer.
2. **`B5-SKILLS-EFFECTS` after conditions** — effect ids/grants consume the
   condition substrate; the Q2 manifest is a late demo-gated slice.
3. **`B5-LOADOUT-CAPS` after skills** (Q4: skills adapter first; do not wait
   on Source+Style). Needs `B3-PHB` + `B3-REQ`.
4. **`B5-SOURCE-STYLE` after `B4-IEQ` + `B3-RESOURCE-POOLS`** — the Q5
   substrate pass with its two proof consumers (the utility-staff proof
   consumer is the first `B5-UTILITY-STAVES` archetype; build it once, in this
   pass).
5. **`B5-UTILITY-STAVES` after Source+Style + conditions** — the remaining
   archetypes as data on the finished pipeline (Restore proves the cure hooks;
   the inflict staff proves `REQ-10` contests).
6. **`B5-ACTION-GRANT` after skills + the Q5 pipeline** (counters' persistence
   trails `B1-SUSPEND`).
7. **`B5-SECONDARY-MOVEMENT` after skills + `B2-OCCUPANCY`** — last of the
   action-flow features.

**AI chain (parallel):**

1. **`B5-AI-COMPOSITION`** once `B2-REGISTRY`, `B1-F1`, and `B3-MET` exist —
   it does not wait on the content chain.
2. **`B5-AI-MIN-SCORER` after composition + `B2-PROJECTION`** — and after the
   Q5 projection hooks if styles are to be scored at parity with weapons.

## Read First

1. This handoff.
2. [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
   → "Walkthrough Decisions (2026-07-01)", Q1-Q7 (the settled design).
3. [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
   Band 5 rows.
4. The accepted upstream plans: Band 1, Band 2, Band 3, and the `B4-IEQ` plan
   (for the item/instance seams sources ride).
5. Registers named by the Band 5 rows:
   [`skill_model_open_questions_2026-06-23.md`](../registers/skill_model_open_questions_2026-06-23.md),
   [`loadout_cap_open_questions_2026-06-27.md`](../registers/loadout_cap_open_questions_2026-06-27.md),
   [`source_style_combat_model_2026-06-24.md`](../registers/source_style_combat_model_2026-06-24.md),
   [`action_grant_open_questions_2026-06-25.md`](../registers/action_grant_open_questions_2026-06-25.md),
   [`secondary_movement_open_questions_2026-06-24.md`](../registers/secondary_movement_open_questions_2026-06-24.md),
   [`ai_profiles_open_questions_2026-06-21.md`](../registers/ai_profiles_open_questions_2026-06-21.md),
   [`ai_valuation_engagement_open_questions_2026-06-27.md`](../registers/ai_valuation_engagement_open_questions_2026-06-27.md)
   (Band 7 boundary only).
6. Design docs:
   [`source_style_player_and_authoring_2026-06-24.md`](../design/source_style_player_and_authoring_2026-06-24.md),
   [`ai_first_build_design_2026-06-22.md`](../design/ai_first_build_design_2026-06-22.md).
7. The old `GDD_10` M8 condition checklist (source detail for the
   `B5-CONDITIONS` rewrite).

## Recommended Plan Shape

Separate plans (Band 4 pattern), grouped by chain (confirm via Q-B5-2):

1. **Conditions & skill effects plan** — `B5-CONDITIONS` +
   `B5-DURATION-LIFECYCLE` + `B5-SKILLS-EFFECTS` + the `B5-LOADOUT-CAPS`
   shell/skills-adapter (Q1 + Q4; one combined substrate, ordered slices).
2. **Source + Style plan** — `B5-SOURCE-STYLE` + `B5-UTILITY-STAVES`
   (Q5 + Q6; the substrate pass and its proof/archetype consumers, including
   the styles/sources loadout adapters registering into the plan-1 shell).
3. **Action economy plan** — `B5-ACTION-GRANT` + `B5-SECONDARY-MOVEMENT`
   (Q3; both are skill-driven action-flow features on the shared pipeline).
4. **AI plan** — `B5-AI-COMPOSITION` + `B5-AI-MIN-SCORER` (Q7; parallel
   chain).

Each plan follows the established per-slice shape: files-to-touch,
implementation steps, tests, F1/save rows, registry obligations, DoD#2
obligations, plus the Implementation Commit Order and Verification Checklist
closing sections (audit finding C3 — do not omit them again).

## Decisions Not To Reopen

- The Q1/Q3/Q4/Q5/Q6/Q7 walkthrough decisions summarized in Rows To Cover.
- Author-facing vocabularies are open registries / data composition, not
  closed `enum` + `match`: conditions, capability tags, effect ids, target
  filters, shapes, grant modes, scorer terms, AI profiles, loadout categories,
  duration modes.
- F1 owns saved-field manifest rows before any Band 5 feature adds saved state
  (active conditions, learned/equipped skills, counters, source/style state,
  `ai_awake`, action-grant counters).
- Any contest/skill-check/opposed roll is the F16 `REQ-10` primitive — search
  F16 before building bespoke (this got re-derived repeatedly before being
  pinned).
- Effects/grants execute through `B2-ACTION-EFFECT`; forecasts go through
  `B2-PROJECTION`; costs go through `B2-RESOURCE-LEDGER` / `B3-RESOURCE-POOLS`.
- Advanced AI valuation (`[VAL-1..13]`), perception (`[PER]`), and
  `search_depth` are **Band 7**; the v1 scorer stays single-ply with registry
  seams for those terms.
- Unconsumed effect placeholders are pruned, not carried (Q2 default
  disposition).

## Owner Questions To Surface

Raise these while drafting; do not assume answers:

- **Q-B5-1 (the Q2 gate).** The `B5-SKILLS-EFFECTS` required-ids manifest and
  exact staff ids need the demo campaign design first. Should the demo-campaign
  design pass be scheduled **before** the Band 5 plans are drafted (so the
  manifest slice is concrete), or do the plans land now with the manifest as an
  explicitly demo-gated late slice? (Lean: draft now, manifest demo-gated —
  matches the 2026-07-01 watchout.) `on_level_up` must be resolved either way;
  it is an engine trigger, not content.
- **Q-B5-2.** Confirm the four-plan grouping above, or regroup.
- **Q-B5-3.** `B5-DURATION-LIFECYCLE` boundary: the `B4-IEQ` accessory slice
  already builds the `until_unequipped` producer/remover for equipment. Confirm
  this row's remaining scope = `until_end_of_map` + fixed-N tick semantics + the
  shared lifecycle store that both IEQ equipment and Band 5 conditions/skills
  register into (one lifecycle engine, two producers — not two lifecycle
  implementations).
- **Q-B5-4.** The Band 7 forging plan's `[FRG-18]` effect-grants depend on the
  Q5 **Source/Style effect registry**, and the demo campaign includes forging.
  Does that pull `B5-SOURCE-STYLE` earlier in the Band 5 sequence (it already
  sits behind `B4-IEQ`), or does forging v1 simply wait? (Lean: forging v1
  waits; its v1 slice reserves the seam and only `FRG-18` needs the registry.)

## Watchouts

- **Do not draft the Q2 content-floor slices** (exact effect/staff ids) before
  the demo campaign is designed — 2026-07-01 owner watchout. Machinery yes,
  manifest no.
- Do not start Band 5 implementation before the Band 1-3 gates and `B4-IEQ`
  (for Source+Style) exist.
- Do not add saved Band 5 fields without F1 manifest rows.
- Silence/sleep blocking must land as the **general capability-gating
  primitive** — if a condition needs an engine `match` to block an action, the
  substrate is wrong (Q1).
- The anti-loop refresh cap is a **general action-budget guard**, not a
  dance-specific flag (Q3).
- Scorer terms and AI profiles are registries from day one (Q7); do not ship a
  fixed 4-term sum that Band 7 has to crack open.
- The AI scorer must reuse the same projection the player sees — AI and UI
  forecasts never diverge (Q7).
- The `B5-UTILITY-STAVES` proof consumer is built once, inside the
  Source+Style pass — do not build a second staff pipeline in the staves plan.
- Keep the `B5-DURATION-LIFECYCLE` work joined to real producers (row
  next-action: "land with first producer, not as label-only work").
