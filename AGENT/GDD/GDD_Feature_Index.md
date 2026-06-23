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
| Combat calculations & RNG | Split (project Implemented / corpus + two-RN Target) | GDD_02 §Combat Resolution & Hit RNG | GDD_01 §Determinism, Snapshot & Online Contract | GDD_10 §M9a (RNG engine); Phase 3 Backlog (RngService + T1–T7 fixture) | `CombatResolver.gd` (target `RngService.gd`) | `test_combat.gd` (target RNG T1–T7) | TBD (S3) | SET-001, RULE-001, RNG-1…4, pipeline order, OPEN-3/6/7 | `awakening_lookup_tables.md`, `awakening_core_systems.md` |
| Weapon triangle & rank bonuses | Split (flat project Implemented / rank-scaled Target) | GDD_04 §Weapon Families & Triangle Membership, §S-Rank Weapon Bonus | GDD_02 §Combat Modifier Pipeline Order | GDD_10 §M11 (Content Expansion — rank-scaled table + S-rank engine) | `DataManager.gd` (`get_weapon_triangle_result`), `GameConstants.WEAPON_TRIANGLE` | `test_data_manager.gd` | TBD (S3) | SET-003, SET-005, RULE-002, RULE-013 | `awakening_weapons_physical.md`, `awakening_weapons_magic.md`, `awakening_lookup_tables.md` |
| WEXP & equipment legality | Split (project thresholds Implemented / corpus Target) | GDD_04 §Weapon Proficiency (WEXP) | GDD_01 §Item/weapon data | GDD_10 §M11 (Content Expansion — corpus WEXP thresholds) | `DataManager.gd`, `GameConstants` (`WEXP_RANK_THRESHOLDS`) | `test_data_manager.gd`, `test_unit_stats.gd` | TBD (S3) | SET-004, RULE-003, RULE-004 | `awakening_lookup_tables.md` |
| EXP, leveling, promotion & reclass | Split (project Implemented / corpus Target) | GDD_03 §Promotion, §Reclass, §Progression Counters (EXP/leveling math → GDD_02) | GDD_01 §UnitData/ClassData | AWR-2 (TBD slot) | `Unit.gd` (`promote`/`reclass`/`level_up`) | `test_unit_stats.gd`, `test_level_up_screen.gd` | `map_950_promotion_validation` | SET-006, SET-007, RULE-005, RULE-006, D-E, RULE-008 | `awakening_core_systems.md`, `awakening_archetypes.md` |
| Classes & class skills | Split (project Implemented / corpus Target, AWR-2) | GDD_03 §Starter Roster & Classes / GDD_05 §Skill Acquisition | GDD_01 §ClassData | AWR-2 | `data/classes/`, `GameState.load_default_roster` | `test_unit_stats.gd` | TBD (S3) | SET-009, RULE-007, RULE-008, RULE-009, OPEN-9, OPEN-10 | `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md` |
| Pair Up & support systems | Split (pass 1 Implemented / rest Deferred) | GDD_05 §Pair Up & Support System | GDD_01 §PairUpRegistry | GDD_10 §M13 (Awakening Supplement — DS/DG/adjacent support); Phase 3 Backlog (value migration RULE-012) | `PairUpRegistry.gd`, `PairUpBonusResolver.gd`, `PairUpBonusTable.gd` | `test_pair_up_registry.gd`, `test_pair_up_bonus_resolver.gd`, `test_pair_up_combat_context.gd` | TBD (S3) | SET-010, RULE-012, OPEN-1 | `awakening_core_systems.md` |
| Terrain & movement categories | Split (Implemented + Target) | GDD_06 §Terrain & Movement | GDD_02 §Terrain | AWR-8 | `GridManager.gd` (`get_move_cost`, `TERRAIN_*_BONUS`) | `test_grid_manager.gd` | TBD (S3) | SET-008, RULE-010, RULE-011 | `awakening_lookup_tables.md` |
| Objectives & map authoring | Implemented (pending verify) | GDD_06 §Objective System | — | GDD_10 §M16 (COMPLETE) | `TurnManager.gd` (`check_victory_conditions`), `ObjectiveCondition.gd`, `MapData.gd` | `test_turn_manager.gd` | `map_authoring_guide.md` | — | — |
| Faction scheduling & controllers | Implemented | GDD_02 §Turn Structure (+ §Win/Loss Evaluation) | GDD_01 §TurnManager | — | `TurnManager.gd`, `HotseatController.gd` | `test_turn_manager.gd` | TBD (S3) | OPEN-6 | — |
| Status conditions | Target design (M8) | GDD_02 §Status Conditions | — | GDD_10 §M8 (Status Conditions) | `ConditionManager.gd` (stub) | None yet (stub; M8) | TBD (S3) | OPEN-2 | `awakening_skills.md` (interactions) |
| Skills | Mixed | GDD_05 §Skill System Overview, §Skill Acquisition | GDD_01 §SkillHandler | GDD_10 §M9a (engine), §M9b (content/data) | `SkillHandler.gd`, `SkillData.gd`, `data/skills/` | `test_skill_item_handler.gd` | TBD (S3) | OPEN-2, RULE-009 | `awakening_skills.md` |
| Inventory, trade, convoy, shops & economy | Mixed (shops/recruit Planned) | GDD_04 §Items & Economy, §Inventory Management | GDD_01 §Inventory | GDD_10 Phase 3 Backlog (forging, shop, convoy; D-D prerequisite edge) | `ItemHandler.gd`, `ItemData.gd`, `GameState.gd` (`max_inventory`) | `test_skill_item_handler.gd`, `test_action_menu.gd`; trade/convoy/shops Planned | TBD (S3) | D-D, OPEN-5 | `awakening_items.md` |
| Save, retry, suspend & rewind | Split (Retry Implemented / rest Target) | GDD_01 §Determinism, Snapshot & Online Contract | GDD_01 §Determinism, Snapshot & Online Contract | GDD_10 Phase 3 Backlog (suspend save; mid-battle serialization) | `GameState.gd` snapshot; impl. plan `AGENT/Docs/design/rng_determinism_design_2026-06-11.md` §8 | `test_snapshot_coverage.gd`, `test_game_state.gd` (Retry); suspend/rewind Target | TBD (S3) | RNG-2, RNG-3, OPEN-13 | — |
| UI, input, settings & accessibility | Mixed | GDD_07 §Input System, §Accessibility & Input Parity | GDD_01 §SettingsManager | GDD_10 §Near-Term (Display & Accessibility Controls); Phase 3 Backlog (key rebind, gamepad) | `MapCursor.gd`, `SettingsManager.gd`, `scripts/ui/` | `test_settings_manager.gd`, `test_settings_screen.gd`, `test_hud.gd` | TBD (S3) | OPEN-11 (GDD_00) | — |
| AI behavior | Split (basic profiles Implemented / scoring + parity Target) | GDD_08 §Implemented Profiles, §AI Determinism & Parity | GDD_01 §EnemyAI / §Determinism | GDD_10 §M14 stages 4–5 (COMPLETE); Phase 3 Backlog (scoring, additional profiles) | `EnemyAI.gd`, `GridManager.gd` (`dijkstra_costs`) | `test_enemy_ai.gd` | TBD (S3) | RNG-4, OPEN-4 | `awakening_core_systems.md` |
| Campaign flow & recruitment | Planned | GDD_10 §Campaign / CampaignRules | GDD_01 §CampaignRules Contract | GDD_10 §Release Gates (D-B, D-D prerequisite edges); Phase 3 Backlog (deployment screen, CampaignRules stub — Stage 4.3) | `GameState.gd` (rule fields), `campaign_rules.md` | None yet (Planned) | TBD (S3) | D-B, D-D, OPEN-4 | — |
| Online play | Deferred (post-1.0, M15B) | GDD_01 §Online seam | GDD_01 §Snapshot/result payload | M15B | RNG contract §9 | None (Deferred, post-1.0) | TBD (S3) | RNG-4 | `online_play_design_decisions.md` |

## Backlog features (no owning chapter section yet)

| Feature | Status | Tracking | Decisions |
|---|---|---|---|
| Broken-weapon degraded mode | Backlog (optional rule) | GDD_10 §Release Gates (OPEN-5); Phase 3 Backlog §Systems | OPEN-5 |
| `CampaignRules.exp_gaining_factions` | Stub created (Stage 4.3) | GDD_10 §Release Gates / CampaignRules Stub; GDD_01 §CampaignRules Contract | OPEN-4 |

> Anchors and exact section headings are filled in during Stage 3 chapter rewrites,
> when code/test/manual coverage is verified per-chapter. Until then this index is a
> routing table, not a coverage claim.
