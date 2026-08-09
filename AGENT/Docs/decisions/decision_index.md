# Decision Index

**Date opened:** 2026-06-13
**Status:** Active — central navigation index for all project decisions (DOC-009).
**Schema:** `../governance/documentation_governance_2026-06-13.md` → "Decision-Record
Schema & ID Namespace (DOC-009)".

One row per decision ID. `Decision state` records owner acceptance/lifecycle;
`Delivery status` independently records implementation progress. Exact values are
defined by DOC-009 and enforced by `check_docs.py`. Homes:

- **REG** = `../governance/documentation_consolidation_decisions_2026-06-12.md` (DOC-/RULE-/SET-)
- **JUN** = `decision_record_2026-06-13_june_reference_import.md` (D-A…E, OPEN-, RNG-, PL#, pipeline)
- **GOV** = `../governance/documentation_governance_2026-06-13.md`
- **RNG** = `../design/rng_determinism_design_2026-06-11.md`
- **AWR** = `../plans/awakening_compatability_refactor_plan_2026-05-22.md`

## ID Namespace (DOC-009)

| Prefix | Scope |
|--------|-------|
| `DOC-` | Documentation-governance decisions |
| `RULE-` | Rules / migration decisions |
| `SET-` | Settled owner directions |
| `OPEN-` | June-reference open questions (resolved; kept as aliases) |
| `RNG-` | RNG / determinism contract decisions |
| `AWR-` | Awakening-refactor roadmap milestones |
| `D-A…E` | **Deprecated aliases** for June ratified decisions (mapped below) |
| `PL#` | Parking-lot items from the June reference |

## DOC — documentation governance

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| DOC-001 | Project/corpus authority boundary | Ratified | Implemented | REG | GDD owns rules, corpus is reference. **Supersedes D-C.** Applied to GDD_00 authority order (Stage 2.1). |
| DOC-002 | Current/target layout (section template) | Ratified | In implementation | REG | Template in GOV; remaining campaign shape enforcement is tracked by this follow-up. |
| DOC-003 | Status vocabulary | Ratified | Implemented | REG | Vocabulary in GOV and mechanically enforced. |
| DOC-004 | Roadmap ownership | Ratified | Implemented | REG | GDD_10 owns roadmap tracking; GDD_10a retired. |
| DOC-005 | Feature-index location | Ratified | Implemented | REG | `AGENT/GDD/GDD_Feature_Index.md` is generated and enforced. |
| DOC-006 | Historical checklist/assumptions | Ratified | Implemented | REG | GDD_09 and GDD_Assumptions were retired through the archive lifecycle. |
| DOC-007 | Manual-test playbook location | Ratified | Implemented | REG | Playbook lives at `AGENT/Docs/guides/manual_test_playbook.md`. |
| DOC-008 | Superseded-document policy | Ratified | Implemented | REG | Archive markers and targets are enforced by `check_docs.py`. |
| DOC-009 | Decision-log structure | Ratified | Implemented | REG | Dated records plus this enforced two-column index. |
| DOC-010 | Location of June reference contracts | Ratified | Implemented | REG | June reference contracts were moved into the typed Docs layout. |
| DOC-011 | Documentation validation in CI | Ratified | Implemented | REG | `check_docs.py` runs locally and in CI. |
| DOC-012 | Legal/licensing release gate | Ratified | Planned | REG | Blocking pre-1.0 gate; pairs with OPEN-12. |
| DOC-013 | Split-status phrasing (project/corpus) | Ratified | Implemented | REG | Phrasing in GOV; enforced by `check_docs.py` checks 7–8. |

## RULE — rules / migration

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| RULE-001 | Exact two-RN hit model | Ratified | Implemented | REG | Option A (two 0–99, floor avg). Default resolver preset among author-selectable resolvers (CRR-1); selection = `CampaignRules.hit_formula`. Single-roll survives as the selectable `single_roll` built-in, no longer the shipped rule. In GDD_02 §Combat Resolution & GDD_01 §Determinism. |
| RULE-002 | S-rank bonus | Ratified | Target design | REG | +10 Hit/+5 Crit/+1 Dmg via combat engine; retire `s_rank_mastery`. In GDD_04 §S-Rank Weapon Bonus (3.3). |
| RULE-003 | WEXP migration | Ratified | Target design | REG | Option B (proportional within rank); runtime conversion. In GDD_04 §Weapon Proficiency (3.3). |
| RULE-004 | WEXP gain timing | Ratified | Target design | REG | Per valid use; may change in a balance pass. In GDD_04 §Weapon Proficiency (3.3). |
| RULE-005 | Promotion trigger timing | Ratified | Target design | REG | Seal@10 + optional auto-promote@cap; mandatory modal blocks all controllers, no cancel. |
| RULE-006 | Reclass EXP counters | Ratified | Target design | REG | `displayed_level`/`exp_basis_level`/`lifetime_levels_gained`. In GDD_03 §Progression Counters (3.2). |
| RULE-007 | Class replacement scope | Ratified | Target design | REG | Full corpus classes; project-only rejected/archived. In GDD_03 §Starter Roster (3.2). |
| RULE-008 | Personal vs class growths | Ratified | Target design | REG | Replace personal growths; effective = corpus archetype + class. In GDD_03 §Starter Roster (3.2). |
| RULE-009 | Light/Dark magic design scope | Ratified | In implementation | REG | Light/Dark tome families and track coverage implemented 2026-07-30; three-way magic-triangle wiring remains Planned. Owns OPEN-10. |
| RULE-010 | Terrain migration rollout | Ratified | Target design | REG | Show both tables until migration. In GDD_06 §Terrain & Movement (3.6). |
| RULE-011 | Existing terrain ID mapping | Ratified | Deferred | REG | Roadmap owner **AWR-8**; GDD terrain ID section stays Open decision until then. |
| RULE-012 | Pair Up/support release scope | Ratified | In implementation | REG | Pair Up pass 1 is implemented; Dual Strike/Guard and supports 4–8 remain later slices. |
| RULE-013 | Magic-triangle rank source | Ratified | Target design | REG | Equipped weapon's trained WEXP track sets magnitude; `triangle_family` sets relationship. |

## SET — settled owner directions

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| SET-001 | Combat formulas → corpus | Ratified | Target design | REG | Corpus formulas remain the migration target. |
| SET-002 | Hit RNG → two-RN (see RULE-001) | Ratified | Implemented | REG | Delivered by RULE-001. |
| SET-003 | Weapon triangles (retain both, rank-scaled) | Ratified | Target design | REG | GDD_04 §Weapon Families & Triangle Membership (3.3). |
| SET-004 | WEXP → corpus thresholds/caps | Ratified | Target design | REG | GDD_04 §Weapon Proficiency (3.3). |
| SET-005 | Weapon-rank combat bonuses → engine | Ratified | Target design | REG | GDD_04 §S-Rank Weapon Bonus (3.3). |
| SET-006 | Promotion → corpus model | Ratified | Target design | REG | GDD_03 §Promotion (3.2). |
| SET-007 | Reclass progression counters | Ratified | Target design | REG | GDD_03 §Progression Counters / §Reclass (3.2). |
| SET-008 | Terrain → corpus values/categories | Ratified | Target design | REG | GDD_06 §Terrain & Movement (3.6). |
| SET-009 | Class definitions → corpus + Light/Dark task | Ratified | Target design | REG | GDD_03 §Starter Roster (3.2). |
| SET-010 | Pair Up/supports → corpus eventual target | Ratified | Planned | REG | GDD_05 §Pair Up & Support System (3.4). |
| SET-011 | Project goal → learning and portfolio first | Ratified | Implemented | `decision_record_2026-06-29_scope_reframe.md` | Reflected in `GDD_00_Overview.md`. |
| SET-012 | Product direction → tactical-RPG builder second | Ratified | Implemented | `decision_record_2026-06-29_scope_reframe.md` | Reflected in `GDD_00_Overview.md`. |
| SET-013 | Authoring security boundary → data-only first, sandboxed ceiling, fork for full access | Ratified | Implemented | `decision_record_2026-06-29_scope_reframe.md` | Reflected in `GDD_00_Overview.md`. |
| SET-014 | Portfolio target → slice-first playable web demo, no band resequencing | Ratified | Planned | `decision_record_2026-06-29_scope_reframe.md` | Owned by `REL-WEB-DEMO`. |

## D — June ratified decisions (deprecated short aliases)

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| D-A | Public identity rename | Historical | Planned | JUN | Deprecated alias; data-pass rename is due by first public RC. |
| D-B | 1.0 definition | Historical | Implemented | JUN | Deprecated alias; reflected in GDD_00 Release Definition. |
| D-C | Rules authority | Superseded | Not applicable | JUN | Reversed by DOC-001: GDD owns rules, corpus is reference. |
| D-D | Campaign prerequisites | Historical | In implementation | JUN | Deprecated alias; deployment delivered while shops/recruitment remain roadmap work. |
| D-E | Reclass growth to caps | Historical | Target design | JUN | Deprecated alias; reflected in GDD_03 §Reclass (3.2). |

## RNG — determinism contract

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| RNG-1 | Hash-chained context-seeded dice | Ratified | In implementation | RNG→GDD_01 | Dice sourcing is implemented; non-dice event commits remain Slice 1d. |
| RNG-2 | RNG state in snapshot contract | Ratified | Implemented | RNG→GDD_01 | Retry, suspend, rewind, and unified mid-map slots persist the RNG timeline. |
| RNG-3 | Accepted exploits priced by rewind charges | Ratified | Target design | RNG→GDD_01 | In GDD_01 §Determinism (3.1). |
| RNG-4 | Online play host-authoritative | Ratified | Target design | RNG→GDD_01 | M15B; engine-local determinism. |

## OPEN — June open questions (all resolved 2026-06-13)

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| OPEN-1 | Supports in/out | Ratified | Deferred | JUN | Committed feature, post-1.0; confirms RULE-012. |
| OPEN-2 | Condition/skill precedence | Ratified | Implemented | JUN | Conditions differ from skills; one general precedence rule. |
| OPEN-3 | Mid-exchange weapon breakage | Ratified | Implemented | JUN | Cancels remaining strikes. |
| OPEN-4 | Enemy/AI EXP | Ratified | Implemented | JUN | `CampaignRules.exp_gaining_factions`, default Blue+Green. |
| OPEN-5 | Durability soft-lock | Ratified | Planned | JUN | Accepted for now; degraded-mode backlog item remains. |
| OPEN-6 | Simultaneous victory/defeat | Ratified | Implemented | JUN | Defeat before victory; tie goes to acting faction. |
| OPEN-7 | Fort/throne heal rounding | Ratified | Implemented | JUN | `max(1, floor(0.10 × max_hp))`. |
| OPEN-8 | Renderer backend | Ratified | Implemented | JUN | Compatibility renderer recorded in GDD_00. |
| OPEN-9 | Soldier class | Ratified | Deferred | JUN | Placeholder enemy-only Soldier until AWR-2. |
| OPEN-10 | Cleric "Light E" | Ratified | Implemented | JUN | Cleric is staff-only; Light arrives on promotion to Bishop. The `light` track is removed from the base class. |
| OPEN-11 | Steam Deck 16:10 | Ratified | Implemented | JUN | Letterbox; revisit once UI-scale setting exists. |
| OPEN-12 | Handbook licensing/attribution | Ratified | Planned | JUN | Blocking pre-1.0 gate owned with DOC-012. |
| OPEN-13 | Suspend-file lifecycle | Ratified | Implemented | JUN | Persists until map resolves, then deleted; no delete-on-load. |

## Other ratifications

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| Combat modifier pipeline order | Modifier order ratified | Ratified | Implemented | JUN | base → permanent → pair-up → combat-duration skills → conditions → terrain → triangle → S-rank → clamps. |
| PL#8 | Doc-lifecycle DoD rule | Ratified | Implemented | JUN | Same-commit GDD + roadmap update; ratified as **DoD#1**. |
| PL#9 | Minimal SFX | Ratified | Deferred | JUN | Wait for Phase 3 audio milestone. |

## AWR — roadmap milestones referenced by decisions

| ID | Title | Decision state | Delivery status | Home | Notes |
|----|-------|----------------|-----------------|------|-------|
| AWR-2 | Class corpus migration | Ratified | Planned | AWR | Owns OPEN-9 (Soldier identity). |
| AWR-8 | Terrain corpus migration & ID mapping | Ratified | Planned | AWR | Owns RULE-011. |

> Full `AWR-` milestone list lives in the AWR plan; only IDs referenced by other
> decisions are mirrored here.
