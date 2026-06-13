# GDD Feature Index

**Date opened:** 2026-06-13
**Status:** Seed (DOC-005). Navigation only — **not** a second specification. Rule
detail lives in the owning numbered-GDD chapter; this table only points to owners.
**Linked from:** `GDD_00_Overview.md` (link added in Stage 2).

## How to read this

One row per feature group (plan §5). `Status` is a coarse pointer; the authoritative
status lives in the owning chapter's section (governance status vocabulary). Cells
marked **TBD (S3)** are populated as each chapter is rewritten in Stage 3 (code/data,
test, and manual anchors are verified at that point, not asserted here). Section
headings (`§ …`) are finalized during the Stage 3 rewrites.

## Feature groups

| Feature | Status | Rule owner | Arch. owner | Roadmap owner | Code/data anchors | Automated coverage | Manual coverage | Decisions | Reference source |
|---|---|---|---|---|---|---|---|---|---|
| Combat calculations & RNG | Split (project Implemented / corpus + two-RN Target) | GDD_02 §Combat Resolution & Hit RNG | GDD_01 §Determinism, Snapshot & Online Contract | TBD (S4) | `CombatResolver.gd` (target `RngService.gd`) | `test_combat.gd` (target RNG T1–T7) | TBD (S3) | SET-001, RULE-001, RNG-1…4, pipeline order, OPEN-3/6/7 | `awakening_lookup_tables.md`, `awakening_core_systems.md` |
| Weapon triangle & rank bonuses | Split (flat project Implemented / rank-scaled Target) | GDD_04 §Weapon Families & Triangle Membership, §S-Rank Weapon Bonus | GDD_02 §Combat Modifier Pipeline Order | TBD (S4) | `DataManager.gd` (`get_weapon_triangle_result`), `GameConstants.WEAPON_TRIANGLE` | `test_data_manager.gd` | TBD (S3) | SET-003, SET-005, RULE-002, RULE-013 | `awakening_weapons_physical.md`, `awakening_weapons_magic.md`, `awakening_lookup_tables.md` |
| WEXP & equipment legality | Split (project thresholds Implemented / corpus Target) | GDD_04 §Weapon Proficiency (WEXP) | GDD_01 §Item/weapon data | TBD (S4) | `DataManager.gd`, `GameConstants` (`WEXP_RANK_THRESHOLDS`) | TBD (S3) | TBD (S3) | SET-004, RULE-003, RULE-004 | `awakening_lookup_tables.md` |
| EXP, leveling, promotion & reclass | Split (project Implemented / corpus Target) | GDD_03 §Promotion, §Reclass, §Progression Counters (EXP/leveling math → GDD_02) | GDD_01 §UnitData/ClassData | AWR-2 (TBD slot) | `Unit.gd` (`promote`/`reclass`/`level_up`) | `test_unit_stats.gd`, `test_level_up_screen.gd` | `map_950_promotion_validation` | SET-006, SET-007, RULE-005, RULE-006, D-E, RULE-008 | `awakening_core_systems.md`, `awakening_archetypes.md` |
| Classes & class skills | Split (project Implemented / corpus Target, AWR-2) | GDD_03 §Starter Roster & Classes / GDD_05 §Class skills (TBD) | GDD_01 §ClassData | AWR-2 | `data/classes/`, `GameState.load_default_roster` | `test_unit_stats.gd` | TBD (S3) | SET-009, RULE-007, RULE-008, RULE-009, OPEN-9, OPEN-10 | `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md` |
| Pair Up & support systems | Split (pass 1 Implemented / rest Deferred) | GDD_05 §Pair Up (TBD) | GDD_01 §PairUpRegistry | TBD (S4) | TBD (S3) | TBD (S3) | TBD (S3) | SET-010, RULE-012, OPEN-1 | `awakening_core_systems.md` |
| Terrain & movement categories | Split (Implemented + Target) | GDD_06 §Terrain | GDD_02 §Terrain combat | AWR-8 | TBD (S3) | TBD (S3) | TBD (S3) | SET-008, RULE-010, RULE-011 | `awakening_lookup_tables.md` |
| Objectives & map authoring | Implemented (pending verify) | GDD_06 §Objectives | — | TBD (S4) | TBD (S3) | TBD (S3) | `map_authoring_guide.md` | — | — |
| Faction scheduling & controllers | Implemented | GDD_02 §Turn Structure (+ §Win/Loss Evaluation) | GDD_01 §TurnManager | — | `TurnManager.gd`, `HotseatController.gd` | `test_turn_manager.gd` | TBD (S3) | OPEN-6 | — |
| Status conditions | Target design (M8) | GDD_02 §Status Conditions | — | TBD (S4) | `ConditionManager.gd` (stub) | TBD (S3) | TBD (S3) | OPEN-2 | `awakening_skills.md` (interactions) |
| Skills | Mixed | GDD_05 §Skills | GDD_01 §SkillHandler | TBD (S4) | TBD (S3) | TBD (S3) | TBD (S3) | OPEN-2, RULE-009 | `awakening_skills.md` |
| Inventory, trade, convoy, shops & economy | Mixed (shops/recruit Planned) | GDD_04 §Items & Economy, §Inventory Management | GDD_01 §Inventory | TBD (S4) — D-D edge | `ItemHandler.gd`, `ItemData.gd`, `GameState.gd` (`max_inventory`) | TBD (S3) | TBD (S3) | D-D, OPEN-5 | `awakening_items.md` |
| Save, retry, suspend & rewind | Split (Retry Implemented / rest Target) | GDD_01 §Determinism, Snapshot & Online Contract | GDD_01 §Determinism, Snapshot & Online Contract | TBD (S4) | `GameState.gd` snapshot; impl. plan `AGENT/Docs/rng_determinism_design_2026-06-11.md` §8 | TBD (S3) | TBD (S3) | RNG-2, RNG-3, OPEN-13 | — |
| UI, input, settings & accessibility | Mixed | GDD_07 §UI/UX | — | TBD (S4) | TBD (S3) | TBD (S3) | TBD (S3) | OPEN-11 | — |
| AI behavior | Implemented (parity TBD) | GDD_08 §AI | — | TBD (S4) | TBD (S3) | TBD (S3) | TBD (S3) | — | — |
| Campaign flow & recruitment | Planned | GDD_10 §Campaign / CampaignRules | GDD_01 §CampaignRules | TBD (S4) — D-D | `campaign_rules.md` | TBD (S3) | TBD (S3) | D-B, D-D, OPEN-4 | — |
| Online play | Deferred (post-1.0, M15B) | GDD_01 §Online seam | GDD_01 §Snapshot/result payload | M15B | RNG contract §9 | TBD (S3) | TBD (S3) | RNG-4 | `online_play_design_decisions.md` |

## Backlog features (no owning chapter section yet)

| Feature | Status | Tracking | Decisions |
|---|---|---|---|
| Broken-weapon degraded mode | Backlog (optional rule) | Stage 4.3 roadmap | OPEN-5 |
| `CampaignRules.exp_gaining_factions` | Planned | Stage 4.3 / CampaignRules stub | OPEN-4 |

> Anchors and exact section headings are filled in during Stage 3 chapter rewrites,
> when code/test/manual coverage is verified per-chapter. Until then this index is a
> routing table, not a coverage claim.
