---
Type: design
Status: Target design
Last verified: 2026-07-03
---

# Band 5 V1 Content Manifest (the Q2 effect / condition / staff floor)

**Started:** 2026-07-03.

**Owns:** the `B5-SKILLS-EFFECTS` required-v1-ids manifest, the `B5-CONDITIONS`
condition set, the `B5-UTILITY-STAVES` archetype ids, and the concrete
Source+Style / action-grant / secondary-movement / AI content the Band 5
machinery must ship. Consumed by the four Band 5 implementation plans.

## Why this exists now (Q-B5-1 reversed)

The 2026-07-01 walkthrough **deferred** the effect manifest (Q2) on the theory
that the demo campaign must be designed first. **Owner decision 2026-07-03:
build the full manifest now and design the demo campaign to consume it.** This
inverts the dependency and is the cleaner order: the manifest is the **v1 content
floor** — the set of content that guarantees every *coded* Band 5 feature has at
least one player-facing showcase (the V1 demo goal:
[`project_v1_demo_campaign`] ≥1 player-facing feature per code feature). The demo
campaign then *selects and arranges* from this floor; it does not define it.

This supersedes the "do not draft the Q2 content-floor slices" watchout for Band
5. The prune-not-carry rule still holds: content on this floor must have a
showcase; anything that ends up unconsumed by the shipped demo is pruned, not
carried.

**Grounding:** the ~50 skill effects and the item effects below are **already
coded** (`scripts/skills/SkillHandler.gd` dispatch + `data/skills/*.tres`;
`scripts/items/ItemHandler.gd` `IMPLEMENTED_EFFECT_IDS`; `data/weapons/heal_staff.tres`).
The manifest certifies those as the v1 floor and enumerates the **new** content
the machinery introduces. New content is marked **[NEW]**; already-coded content
is marked **[HAVE]**.

## 1. Conditions (`B5-CONDITIONS`)

All five are **[NEW]** behavior (the `ConditionManager` is a stub;
`data/` has no condition defs yet). Each is a `ConditionDef`; params below are the
authoring defaults, all data.

| id | suppresses (capability tags) | overrides_targeting | per_turn_effect | default_duration | cured_by | showcase |
|---|---|---|---|---|---|---|
| `poison` | — | no | HP loss (flat or %, floors at 1 — never lethal) | `until_end_of_map` | `restore` | poison tile / poison-coat style / poison staff |
| `sleep` | `attack, staff_use, skill_use, move, trade` (all) | no | — | `fixed_n` (3) | `restore` | Sleep staff |
| `stun` | `attack, skill_use` | no | — | `fixed_n` (1) | `restore` | a stun-on-hit style/skill |
| `silence` | `staff_use, skill_use` | no | — | `until_end_of_map` | `restore` | Silence staff (shuts a healer/mage) |
| `berserk` | — | **yes** (hostile to all, incl. allies) | — | `fixed_n` (3) | `restore` | Berserk staff (turns an enemy on its own) |

Capability tags declared by actions (registry, grows by data):
`attack, staff_use, skill_use, move, trade`. Cure tag registry: `restore` (the
Restore staff cure set) and a `panacea` clear-all consumable.

**Cure hooks [NEW]:** the `restore` cure tag (Restore staff, §3) removes any
condition whose `cured_by` includes it; the **Panacea** consumable
(`effect_id: clear_all_conditions`) removes all — proves Q1's cure hooks
end-to-end.

## 2. Skill effects (`B5-SKILLS-EFFECTS`)

**v1 skill-effect floor = the effect ids already coded** in
`SkillHandler._dispatch`, retained and carried through the registry conversion
(Plan 1 Slice 4) with **no behavior change**. They are the floor because they
already have `.tres` content and tests:

`renewal, vantage, nihil, resolve, wrath, miracle, stat_bonus, faire, breaker,
charm, anathema, daunt, s_rank_mastery, prescience, patience, discipline,
outdoor_fighter, indoor_fighter, focus, armsthrift, healtouch, swiftfoot,
multishot, hawkeye, deadeye, rally_skill, strike_true, challenge, counter,
supremacy, blessing, holy_aura, boon, judgement, sol, odd_rhythm, even_rhythm,
bastion, iron_wall, pavise, charge, aegis, flare, phasing, deeper_knowledge,
lifetaker, shadowgift, dash, disarm, vigilance, diehard` **[HAVE]**.

New skill-machinery content the plan must add:

- **`on_level_up` trigger wiring [NEW]** + **≥1 skill that uses it** (e.g. an
  `aptitude`/`paragon`-style growth skill) — proves the previously-unwired engine
  trigger. This is the one Q2 item that was always engine, not content.
- **≥1 grant/revoke skill [NEW]** — a skill that grants another effect id for a
  duration and revokes it on expiry (routed through the lifecycle store), proving
  the grant/revoke path. `rally_skill` **[HAVE]** is a candidate consumer to
  generalize.
- **Loadout cap showcase [HAVE→exercised]:** a unit whose learned set exceeds
  `GameState.max_skills`, so the equipped-subset cap and auto-unequip are visible.

## 3. Utility staves (`B5-UTILITY-STAVES`, on the Source+Style pipeline)

The four Q6 archetypes; each is a `source` whose effect set drives the pipeline.

| Staff | effect kind(s) | target_filter | condition tie-in | status |
|---|---|---|---|---|
| **Heal** | `heal` | `ally` | — | **[HAVE]** (`heal_staff.tres`), re-expressed as a `heal` effect |
| **Restore** | `cure` | `ally` | removes `restore`-cured conditions | **[NEW]** — proves §1 cure hooks |
| **Rescue** | `displace` | `ally` | — (positional; `B2-OCCUPANCY`) | **[NEW]** |
| **Sleep** (inflict) | `condition_apply` (sleep) | `enemy` | applies `sleep` via an F16 `REQ-10` hit/resist contest | **[NEW]** |
| **Silence** (inflict) | `condition_apply` (silence) | `enemy` | applies `silence` via `REQ-10` | **[NEW]** |
| **Berserk** (inflict) | `condition_apply` (berserk) | `enemy` | applies `berserk` via `REQ-10` | **[NEW]** |

Deferred (not v1 unless the demo pulls them): Physic (ranged heal), Fortify (AoE
heal — needs a Q5 shape), Warp (ally teleport), Repair/Hammerne (needs
durability content). All are later data on the same pipeline.

## 4. Source + Style (`B5-SOURCE-STYLE`)

**Effect kinds registered [NEW]:** `strike` (attack), `heal`, `cure`,
`condition_apply`, `displace`, `refresh` (action grant, §6). `strike` +
hostile-filter reproduces plain attack (the null style).

**Target filters registered [NEW]:** `enemy, ally, self, empty_tile,
weapon_holder, any`.

**Shapes registered [NEW]:** `single_tile` (v1; the `TargetShape` interface
lands so line/blast/cross AoE register later without an engine edit).

**Cost backends [NEW]:** durability (weapon per-use), and ≥1 resource pool
(`B3-RESOURCE-POOLS`) so a style can spend a pool; `override_source_cost` proven
by a style that spends 0 durability.

**Concrete styles for the demo [NEW] (proof consumers + showcase):**

- **Wrath Strike** — a hostile combat-art style: `+Mt`/`-Hit` stat-mod on a
  `strike`, costs weapon durability. Proof consumer #1 (hostile style).
- **Poison Edge** — a style that *adds* a `condition_apply` (`poison`, gate
  `on_hit`) to the base `strike` — proves style-adds-effect **and**
  condition-via-style in one consumer.

(The Heal staff, §3, is proof consumer #2, built once inside the substrate pass.)

## 5. Loadout categories (`B5-LOADOUT-CAPS`)

- **Skills** adapter **[HAVE→built]** — earned superset / equipped subset, capped
  by `GameState.max_skills`.
- **Styles** adapter **[NEW]** — caps by count/slot (its own predicate).
- **Granted sources** adapter **[NEW]** — sources conferred by skills/accessories.

Showcase: a unit with more learned styles than style slots, so the styles cap is
visible alongside the skills cap in one panel.

## 6. Action grant (`B5-ACTION-GRANT`)

- **Dance** **[NEW]** — a `refresh` effect, `grant_mode: refresh_full_turn`,
  `target_filter: non-hostile`, single-target, range 1, one-refresh-per-unit
  per-turn budget. Showcase: a Dancer unit refreshing an ally.

## 7. Secondary movement (`B5-SECONDARY-MOVEMENT`)

- **Canto** **[NEW]** — a secondary-move skill, `mode: remaining`,
  `allowed_actions: [attack, staff_use, skill_use]`. Showcase: a mounted unit
  moving after attacking. (`dash`/`swiftfoot` **[HAVE]** are movement skills but
  are pre-action move buffs, not move-after-acting.)

## 8. AI (`B5-AI-COMPOSITION` / `B5-AI-MIN-SCORER`)

**AIProfileDef set [NEW]** (`basic` id **[HAVE]** as the default string):

| profile | behavior | scorer weight bias | showcase |
|---|---|---|---|
| `basic` | engage nearest in range | balanced | default enemies |
| `aggressive` | seek + strike, discount danger | outcome ↑, survival ↓ | berserker/brigand |
| `defensive` | hold/guard a tile until provoked | survival ↑ | fortress guard (group-wake) |
| `healer` | prioritize healing hurt allies | supports `heal`/`cure` sources | **enemy healer (C5 — scores staves)** |
| `seeker` | move toward a seek-tile/objective | objective ↑ | escort/boss rush |

**Scorer terms [NEW], registry from day one:** `immediate_outcome` (reuses the
§4 forecast), `survival_danger`, `objective_pressure`, `profile_weight`. Band 7
adds perception/economy/role terms + `search_depth` as new registered terms.

Because the AI scores **styles and staves** (C5), the `healer` and a
style-wielding enemy exercise the source+style scoring path — the scorer must
consume the §4 forecast, so `B5-AI-MIN-SCORER` Slice 3 gates on `B5-SOURCE-STYLE`.

## 9. Demo-showcase coverage (code feature → floor content)

Every Band 5 code feature has ≥1 showcase on this floor (the v1 demo must include
each right-column item at least once):

| Code feature | Showcase content |
|---|---|
| Conditions + per-turn effect | poison (tile or Poison Edge style) |
| Capability gating (partial) | Silence staff shutting a healer |
| Capability gating (full) | Sleep staff |
| Targeting override | Berserk staff turning an enemy on its allies |
| Cure hooks | Restore staff + Panacea consumable |
| Duration modes | poison (`until_end_of_map`), sleep (`fixed_n`), accessory (`until_unequipped`) |
| Skill effect registry | the ~50 coded skills, still firing post-conversion |
| `on_level_up` trigger | the growth skill |
| Grant/revoke | the grant skill |
| Loadout caps | over-cap skills + styles unit |
| Source+Style substrate | Wrath Strike (hostile style) |
| Style adds effect | Poison Edge |
| Multi-resource / override cost | a pool-spending style; a 0-durability style |
| Utility staves | Heal, Restore, Rescue, Sleep/Silence/Berserk |
| F16 `REQ-10` contest | inflict-staff hit/resist |
| Action grant | Dancer |
| Secondary movement | Canto |
| AI composition | the 5 profiles + group-wake guard + `set_ai` flip |
| AI min-scorer | enemy healer choosing a heal over an attack |

## Source docs

- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → Q1, Q2, Q6, Q7.
- The four Band 5 plans (this manifest is their content input).
- [`source_style_combat_model_2026-06-24.md`](../registers/source_style_combat_model_2026-06-24.md)
- [`skill_model_open_questions_2026-06-23.md`](../registers/skill_model_open_questions_2026-06-23.md)

## Open content picks (adjust freely; not engine decisions)

- Exact poison magnitude (flat N vs % of max HP) and the fixed-N turn counts.
- Which existing skill becomes the `on_level_up` / grant showcase.
- Which combat arts beyond Wrath Strike / Poison Edge the demo ships.
- Whether Berserk staff is v1 or deferred (it is the riskiest to balance).

These are content flavor; none change the machinery the plans build.
