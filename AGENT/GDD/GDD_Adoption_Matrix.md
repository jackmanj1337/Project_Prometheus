# Project Adoption Matrix

**Date opened:** 2026-06-13 (expanded from the corpus-folder stub)
**Status:** Active — project authority artifact (Phase 4 / Stage 3.0 structure).
**Home decision (Stage 3.0):** lives in the live GDD set (`AGENT/GDD/`), beside
`GDD_Feature_Index.md`, **not** in the corpus folder — per DOC-001 the Awakening corpus
is *reference* and must not hold project status. The corpus indices link up to this
file.

## What this is

For each relevant Awakening corpus area, this records the **adoption decision** and the
**GDD owner** of any project variation. A corpus rule becomes a project target only via
a row here (`Adopted target` / `Adopted w/ variation`) **plus** a GDD update — it is
never authoritative on its own (DOC-001).

**Adoption** (plan §4.4): `Not reviewed` · `Adopted target` · `Adopted w/ variation` ·
`Rejected` · `Deferred` · `Implemented`. This is distinct from **Impl. status**
(governance vocabulary: Implemented / Target design / Planned / Deferred / Open
decision) — a rule can be *adopted* as a target while still *unimplemented*.

Per the Stage 3 sequencing rule, each chapter's rows are finalized (exact corpus
headings + GDD section anchors) **before/with** that chapter's rewrite (3.1–3.8). Rows
below carry the ratified decision now; `§ TBD (3.x)` marks anchors filled at rewrite.

Corpus sources use the file map in `New_Content_Expansion/awakening_project_index.md`.

---

## Combat & RNG  → GDD_02 (3.1)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Combat-stat formulas (Atk/Hit/Avo/Crit/AS) | `awakening_core_systems`, `awakening_lookup_tables` | Adopted target | GDD_02 §Combat (TBD) | — | Target design | SET-001 |
| Hit RNG model | `awakening_core_systems` | Adopted w/ variation | GDD_02 §Combat Resolution & Hit RNG; GDD_01 §Determinism, Snapshot & Online Contract | Two-RN math is corpus; **sourcing is project** — hash-chained deterministic `RngService` | Target design | RULE-001, SET-002, RNG-1…4 |
| Crit resolution | `awakening_core_systems` | Adopted target | GDD_02 §Combat (TBD) | Crit only after a hit (roll order) | Target design | RULE-001 |
| Effectiveness multiplier | `awakening_core_systems`, `awakening_lookup_tables` | Adopted target | GDD_02 / GDD_04 (TBD) | — | Target design | — |
| Follow-up at +5 AS | `awakening_core_systems` | Implemented | GDD_02 §Combat (TBD) | Current default; campaigns may override | Implemented | — |
| Combat modifier pipeline order | (project ratification) | Adopted w/ variation | GDD_01 §Combat context (TBD) | **Project-defined order:** base→permanent→pair-up→combat-duration skills→conditions→terrain→triangle→S-rank→clamps | Target design | pipeline order |
| Mid-exchange weapon breakage | (project ruling) | Adopted w/ variation | GDD_02 §Combat (TBD) | Breakage **cancels remaining strikes**; weapon gone after combat | Target design | OPEN-3 |
| Fort/throne heal | (project ruling) | Adopted w/ variation | GDD_02 / GDD_06 (TBD) | `heal = max(1, floor(0.10 × max_hp))` | Target design | OPEN-7 |
| Simultaneous victory/defeat | (project ruling) | Adopted w/ variation | GDD_02 / GDD_06 (TBD) | Defeat before victory; tie → acting faction | Target design | OPEN-6 |
| Condition/skill precedence | `awakening_skills` (interactions) | Adopted w/ variation | GDD_02 / GDD_05 (TBD) | **Conditions ≠ skills**; one general rule, per-skill exceptions | Target design | OPEN-2 |

## Weapon triangles & WEXP  → GDD_04 (3.3 — DONE)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Physical weapon triangle | `awakening_weapons_physical`, `awakening_lookup_tables` | Adopted w/ variation | GDD_04 §Weapon Families & Triangle Membership | Retain project relationship Sword→Axe→Lance; rank-scaled corpus bonuses | Target design | SET-003 |
| Magic weapon triangle | `awakening_weapons_magic` | Adopted w/ variation | GDD_04 §Weapon Families & Triangle Membership | **Retain project Dark→Anima→Light** triangle; same rank-scaling table | Target design | SET-003, RULE-013 |
| Rank-scaled triangle bonus table | `awakening_lookup_tables` | Adopted target | GDD_04 §Weapon Families & Triangle Membership | Hybrid weapons use equipped weapon's trained WEXP track for magnitude | Target design | SET-003, RULE-013 |
| WEXP thresholds & caps (E1/D31/C71/B121/A181/S251/Cap400) | `awakening_project_index`, `awakening_lookup_tables` | Adopted target | GDD_04 §Weapon Proficiency (WEXP) | — | Target design | SET-004 |
| Class weapon-rank caps | `awakening_classes_*` | Adopted w/ variation | GDD_03 (caps) / GDD_04 §Weapon Proficiency (math) | Classes author A as default cap; explicit S caps possible | Target design | SET-004 |
| Weapon-rank combat bonuses | `awakening_lookup_tables` | Adopted w/ variation | GDD_04 §S-Rank Weapon Bonus (+ GDD_02 application) | **S-rank project extension** +10 Hit/+5 Crit/+1 Dmg via combat engine; retire `s_rank_mastery` | Target design | SET-005, RULE-002 |
| WEXP gain timing | `awakening_core_systems` | Adopted target | GDD_04 §Weapon Proficiency (WEXP) | Per valid use; may change in a balance pass | Target design | RULE-004 |
| WEXP migration (runtime conversion) | (project rule) | Adopted w/ variation | GDD_04 §Weapon Proficiency (WEXP) | Proportional within rank; no persistent save to migrate | Target design | RULE-003 |

## Progression: EXP / promotion / reclass  → GDD_03 (3.2)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Promotion model (lvl-10 eligibility) | `awakening_core_systems`, `awakening_appendices` | Adopted w/ variation | GDD_03 §Promotion | Seal promotes @10; **campaign-optional auto-promote @class cap**; mandatory blocking modal, no cancel | Target design | SET-006, RULE-005 |
| Internal level (`20 + displayed`) | `awakening_project_index` | Adopted target | GDD_03 (TBD) | — | Target design | SET-006 |
| Reclass reset behavior | `awakening_core_systems` | Adopted w/ variation | GDD_03 §Reclass | `exp_basis_level` resets; `lifetime_levels_gained` retained (future autoscale only) | Target design | SET-007, RULE-006 |
| Second Seal growth to caps | `awakening_core_systems` | Adopted target | GDD_03 §Reclass | Stat caps are the balance lever; no anti-grind guards | Target design | D-E |

## Classes & class skills  → GDD_03 / GDD_05 (3.2 / 3.4)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Base classes | `awakening_classes_base` | Adopted target | GDD_03 §Starter Roster & Classes | Replace project starter classes wholesale (AWR-2) | Target design | SET-009, RULE-007 |
| Promoted classes | `awakening_classes_promoted` | Adopted target | GDD_03 §Starter Roster & Classes | — | Target design | SET-009, RULE-007 |
| Gender-locked normalization | `awakening_project_index` | Adopted target | GDD_03 (TBD) | — | Target design | — |
| Class growths | `awakening_classes_*`, `awakening_archetypes` | Adopted w/ variation | GDD_03 (TBD) | Effective = corpus archetype growth + corpus class growth; **authored personal growths replaced** | Target design | RULE-008 |
| Project-only classes (Sentinel/Bishop/Paragon/Mage Knight) | (project homebrew) | Rejected | — | Archived (Git history) | Superseded | RULE-007 |
| Light/Dark magic class lines | (project addition; not in corpus) | Deferred | GDD_03 / GDD_05 (TBD) | Dedicated design task before bulk class authoring | Planned | RULE-009 |
| Soldier class identity | `awakening_classes_special` | Deferred | GDD_03 (TBD) | Resolve at class migration; interim placeholder enemy-only | Open decision | OPEN-9 (AWR-2) |
| Class skill acquisition (by class/level) | `awakening_skills`, `awakening_classes_*` | Adopted target | GDD_05 §Skill Acquisition | — | Target design | — |
| Proc skills (rate formulas) | `awakening_skills` | Adopted target | GDD_05 §Skill Activation & RNG | Draw from event RNG at trigger slot | Target design | OPEN-2 |
| Five equipped skills | `awakening_core_systems` | Implemented | GDD_05 §Skill System Overview | Current default; campaigns may override | Implemented | — |
| Cleric "Light E" access | `awakening_classes_*` | Deferred | GDD_05 §Skill Acquisition (→ GDD_03) | Decided by Light/Dark design pass | Open decision | OPEN-10 (RULE-009) |

## Pair Up & supports  → GDD_05 (3.4 — DONE)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Pair Up stat bonuses/actions (layer 1) | `awakening_core_systems` | Implemented | GDD_05 §Pair Up & Support System | Pass 1 implemented; **value migration to corpus numbers Planned** | Implemented (+ Target for values) | SET-010, RULE-012 |
| Dual Strike (layer 2) | `awakening_core_systems` | Deferred | GDD_05 §Pair Up & Support System | Scheduled with Dual Guard under AWR combat foundation | Target design | RULE-012 |
| Dual Guard (layer 3) | `awakening_core_systems` | Deferred | GDD_05 §Pair Up & Support System | With Dual Strike | Target design | RULE-012 |
| Adjacent support (layer 4) | `awakening_core_systems` | Deferred | GDD_05 §Pair Up & Support System | Post-1.0 | Deferred | OPEN-1, RULE-012 |
| Support ranks / conversations (5,6) | `awakening_core_systems` | Deferred | — | Post-1.0 | Deferred | OPEN-1, RULE-012 |
| S-rank / marriage (7) | `awakening_core_systems` | Deferred | — | Post-1.0 | Deferred | OPEN-1, RULE-012 |
| Child units / inheritance (8) | `awakening_core_systems`, `awakening_appendices` | Deferred | — | Post-1.0 | Deferred | OPEN-1, RULE-012 |

## Terrain & movement  → GDD_06 (3.6 — DONE)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Terrain values | `awakening_lookup_tables` | Adopted target | GDD_06 §Terrain & Movement | Show both tables (Implemented project + Target corpus) until migration | Target design | SET-008, RULE-010 |
| Movement categories | `awakening_lookup_tables` | Adopted target | GDD_06 §Terrain & Movement | — | Target design | SET-008 |
| Flying movement category | `awakening_lookup_tables` | Adopted target | GDD_06 §Terrain & Movement | Implemented via terrain movement-cost categories | Planned | SET-008 |
| Existing terrain ID mapping | `awakening_lookup_tables` | Deferred | GDD_06 §Terrain & Movement (Known gaps) | sea / wall-building / Fort-behavior throne resolved by mapping pass, not name equality | Open decision | RULE-011 (AWR-8) |

## Weapons & items  → GDD_04 (3.3 — DONE)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Physical weapons | `awakening_weapons_physical` | Adopted target | GDD_04 §Weapon Data & Tables | — | Target design | SET-009 |
| Magic weapons / tomes | `awakening_weapons_magic` | Adopted target | GDD_04 §Weapon Data & Tables | Project magic triangle preserved (see triangles) | Target design | SET-003 |
| Staves | `awakening_weapons_magic` | Adopted target | GDD_04 §Weapon Data & Tables | Heal deterministic; EXP flat (no dice) | Target design | — |
| Items | `awakening_items` | Adopted target | GDD_04 §Items & Economy | — | Target design | — |
| Effectiveness matrix | `awakening_lookup_tables` | Adopted target | GDD_04 §Effectiveness Mechanic | 3× (4× Giantkiller) | Target design | — |
| Broken-weapon degraded mode | (project backlog) | Deferred | GDD_04 §Broken-Weapon Degraded Mode | Optional rule: stat penalty + infinite uses while broken; likely CampaignRules toggle | Planned (backlog) | OPEN-5 |

## AI & enemy generation  → GDD_08 (3.8 — DONE)

| Corpus area | Corpus source | Adoption | GDD owner | Project variation | Impl. status | Decisions |
|---|---|---|---|---|---|---|
| Tactical AI scoring | `awakening_core_systems` | Deferred | GDD_08 §Future AI Profiles / §Phase 2 Scoring Model | Separate AI task | Planned | — |
| Enemy generation / autolevel | `awakening_core_systems`, `awakening_appendices` | Not reviewed | GDD_08 §Enemy Generation & Autolevel (+ GDD_03 stats) | — | — | — |
| Enemy/AI EXP gain | (project rule) | Adopted w/ variation | GDD_02 §EXP / GDD_01 §CampaignRules Contract | `CampaignRules.exp_gaining_factions`, default Blue+Green; Red none | Planned | OPEN-4 |

---

## Coverage check (plan §4 minimum)

stat/combat formulas ✓ · hit RNG ✓ · physical+magic triangles ✓ · WEXP thresholds &
rank bonuses ✓ · promotion & reclass ✓ · terrain & movement ✓ · starter & future class
definitions ✓ · class skill acquisition ✓ · Pair Up/Dual Strike/Dual Guard/supports/
marriage/children ✓ · weapons/items/effectiveness ✓.

For authority ordering, see `GDD_00_Overview.md`.
