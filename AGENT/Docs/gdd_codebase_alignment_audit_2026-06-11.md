# GDD / Codebase Alignment Audit

> **Historical** — all findings were applied during the documentation consolidation
> Stages 1–3 (2026-06-13). GDD_01–GDD_08 are now the authoritative record. Retained
> as evidence of the alignment analysis. Do not use as a live action list.

**Date:** 2026-06-11
**Scope:** `AGENT/GDD`, ratified decision records in `AGENT/Docs`, current
GDScript, scenes, data resources, registry content, and automated tests.
**Purpose:** List material differences between the documented design and the
current repository, explain the risk, and recommend how each difference should
be settled.

This is an audit document. It does not silently choose new game rules. Where a
ratified decision exists, that decision is treated as authoritative. Where no
decision exists, the recommendation favors the coherent behavior already
implemented and tested.

## Recommended Authority Order

The GDD does not currently state a reliable authority order. Use this order:

1. Ratified dated decisions and later addenda.
2. Current code and tests for shipped behavior, except where they violate a
   ratified decision.
3. `GDD_01` through `GDD_08` as the live design/implementation contract.
4. `GDD_10_Roadmap.md` and `GDD_10a_Overview.md` for future work and status.
5. `GDD_Assumptions.md` and `GDD_09_Checklist.md` as historical records only.
6. The Awakening technical corpus as external reference material until a rule
   is explicitly adopted into this game's GDD.

Recommended status labels used below:

- **Fix code:** The implementation violates a ratified/current rule.
- **Update GDD:** The implementation is coherent and should become the documented rule.
- **Reconcile:** Both sides contain useful intent; make an explicit decision first.

## Settlement Addendum - 2026-06-11

The review following this audit settled the code-facing recommendations:

- P0-1 and P0-2 were implemented with regression tests.
- M14 tactical scoring moved to a separate deferred AI task.
- The M15 CLI/dev controller override was deferred; `Faction - Controller`
  labels were implemented.
- Flying movement remains planned for terrain movement-cost categories.
- Rout is never implicit; affected wipe-failure maps now author it explicitly.
- Defaults changed to 5 equipped skills and a 5-point follow-up threshold,
  with future campaign override ownership recorded.
- Current class WEXP caps default to A; explicit S-cap classes remain possible.
- The Awakening corpus is external reference, has an adoption matrix, and uses
  repository-relative links.
- The misspelled content-expansion directories were renamed with references.

## P0: Behavior Violates Locked Decisions

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P0-1 | `turn_number` does not advance at the full-round boundary in `WHOLE_PHASE`. | Decision 7 and `GDD_02`/`GDD_10` say it increments once when the faction cycle wraps. `TurnManager.end_player_phase()` increments it immediately after blue, before green/red/yellow. Survive, turn-limit, odd/even rhythm, standings, and any round-based effects can observe the wrong round during non-blue phases. Existing tests currently pin the incorrect behavior. | **Fix code.** Move the increment and `turn_changed` emission to the `WHOLE_PHASE` cycle wrap, matching the existing `ALTERNATING` wrap behavior. Replace tests that expect an increment at blue phase end with multi-faction round-boundary tests. |
| P0-2 | Seize still supports a per-map `allowed_unit_ids` gate. | The 2026-05-25 locked decision and `GDD_06` require only the unit-level `can_seize` tag. `ObjectiveCondition.allowed_unit_ids`, `_unit_matches_seize_gate()`, tests, and four serialized empty arrays preserve the superseded allowlist path. A future map can accidentally bypass the canonical eligibility rule. | **Fix code.** Remove `allowed_unit_ids`, migrate affected `.tres` files, and test that `can_seize` is the only eligibility gate. |

## P1: Authority and Roadmap Status

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P1-1 | `GDD_00` says `GDD_01` through `GDD_09` describe the code as built. | `GDD_09` explicitly identifies itself as a historical checklist and contains many completed tasks still unchecked plus superseded schema names. This makes obsolete text appear authoritative. | **Update GDD.** State the authority order above and classify `GDD_09` as historical. |
| P1-2 | `GDD_Assumptions` still says the turn counter increments at player-phase start. | Assumption 18 predates ratified Decision 7 and conflicts with the current round/cycle definition. | **Update GDD.** Mark Assumption 18 superseded by Decision 7 rather than leaving two active rules. |
| P1-3 | M14 is marked complete although its stage-4 tactical scoring was not built. | `GDD_10` requires faction-blind scoring using HP, strength, terrain danger, and objective criticality. `EnemyAI` remains nearest-target AI; `GDD_08` accurately says kill scoring is future work. | **Reconcile.** Recommended: mark “faction architecture, dispatch, and content” complete, but keep tactical target scoring as an open M14/M9-era AI task. Do not label the entire milestone complete unless the scoring requirement is removed by decision. |
| P1-4 | M16 is marked complete while its “Current state” and checklist describe the pre-M16 system. | `GDD_10` still says `MapData` has legacy `objective_type`, `turn_limit`, and `required_survivor_ids`; those fields were removed. Nearly all M16 checklist items remain unchecked despite the implementation and maps being present. | **Update GDD.** Rewrite the current-state block to the shipped typed, per-group evaluator and mark completed checklist items. Preserve migration history in a clearly historical subsection. |
| P1-5 | M15 Part A status understates and overstates different pieces. | Validation map/content already exists, but the locked CLI/dev override and generic `Faction - Controller` phase text do not. HUD/banner only show the faction label, and map 900 bakes “Green Hotseat” into display data. | **Reconcile.** Mark core hotseat and validation content complete; keep manual validation, controller-label formatting, and either CLI override implementation or formal CLI deferral open. |
| P1-6 | M15 Part B presents the sync model as both open and ratified. | The roadmap first asks the team to choose lockstep vs client-server, then later records ratified host-authoritative client-server. | **Update GDD.** Remove the obsolete open-choice wording and retain the ratified model. |
| P1-7 | The roadmap introduction says Pair Up is out of scope. | Pair Up pass 1 is implemented and listed in `GDD_00`/`GDD_10a`: registry, bonuses, Pair Up/Swap/Separate actions, and snapshot support. Only Dual Strike/Guard and related UI remain deferred. | **Update GDD.** Replace “Pair Up mechanic is out of scope” with a pass-1/current-vs-deferred breakdown. |
| P1-8 | `GDD_09` reports 35 test suites and retains many unchecked completed tasks. | There are 36 `scripts/tests/test_*.gd` suites. Promotion, maps 002-005, faction phases, settings, and other completed work still appear open in the historical checklist. | **Update GDD.** Keep it historical, update the suite count, and add completion/supersession annotations instead of treating unchecked boxes as current backlog. |
| P1-9 | `GDD_10a` is stale after substantial June work. | It was last refreshed 2026-05-26, points B10 at the old `revised_classes_and_skills.md`, and records stage-3 escape as automatic on movement even though the locked addendum and code use an explicit Escape action. | **Update GDD.** Refresh the status summary, replace B10 with a reconciliation task for the active corpus, and correct the escape history. |

## P1: Core Rules and Progression

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P1-10 | `GDD_02` documents the superseded promotion model. | It allows early item promotion, grants a promotion skill immediately, tracks pre/post levels separately, and adds 5% to all growths. Current M6 code requires class max level, resets displayed level to 1, preserves progression through `internal_level`, applies class bonuses, and learns promoted skills at authored levels such as 5/15. | **Update GDD.** Adopt the implemented M6 promotion/reclass contract. |
| P1-11 | `GDD_03` also says Master Seals promote before level 20. | `Unit.can_promote()` requires `data.level >= class_data.max_level`, and promotion items call that gate. | **Update GDD.** State that both automatic availability and item use require the class maximum under the current design. |
| P1-12 | Promotion-item names and eligibility schema are stale. | `GDD_03` lists Knight Crest, Hero Crest, Ocean Seal, Elysian Whip, and Fell Contract as if present and uses `eligible_classes`. Live data has Master Seal, Orion Bolt, Guiding Ring, and Second Seal; validation reads `allowed_classes` and `allowed_class_groups`. | **Update GDD.** Separate current items from planned items and use the live parameter names. |
| P1-13 | `GDD_02` documents one `ClassData.growth_rates` table. | Live classes use `player_growth_rates` plus personal `UnitData.growth_rates` for blue units and `enemy_growth_rates` for non-blue generation. | **Update GDD.** Copy the accurate split already documented in `GDD_01`/`GDD_03`. |
| P1-14 | Gold ownership is contradictory. | `GDD_02`/`GDD_03` say each unit owns 1,000 gold. `UnitData.gold` exists but has no consumer; rewards and retry persistence use `GameState.party_gold` and `party_items`. | **Update GDD**, then deprecate the dead unit-gold field in a separate code change. Party treasury is the coherent implemented model. |
| P1-15 | Unit creation is documented as class-base generation. | `GDD_03` says a new `UnitData` is built by copying class bases. Current roster and map units are authored `.tres` resources; `GameMap` loads/duplicates them, while class bases are used by progression/reclass logic. | **Update GDD.** Describe authored units as current behavior and move class-base generation to a future character/enemy generator section. |

## P1: Maps, Terrain, and Objectives

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P1-16 | The GDD claims editor-painted map scenes are supported. | `MapData.tilemap_scene_path` is validated but never instanced. `GameMap._ready()` rejects an empty `grid` and always paints the generic `GameMap` terrain layer from strings. All live maps use string grids. | **Update GDD** to say only runtime string-grid maps are supported. Either remove the unused field later or implement the scene-loading path before documenting it as supported. |
| P1-17 | `GDD_06` says every map is a TileMapLayer scene paired with `MapData`. | Battles use one generic `GameMap.tscn`; map-specific terrain and placements come from `MapData`. | **Update GDD.** Describe the generic scene plus data-resource architecture. |
| P1-18 | Flying movement rules are documented but not implemented. | `GDD_02` says flying ignores movement penalties. `GridManager.get_move_cost()` only implements desert quality exceptions; there is no flying override. | **Reconcile.** Recommended: mark the rule planned until movement-family support is implemented. Add it before introducing playable flying classes. |
| P1-19 | The MVP map-size limit is already exceeded. | `GDD_02` says up to 30x30; map 001 and its tests are 42x26. | **Update GDD.** Remove the obsolete MVP limit or state the tested practical range instead. |
| P1-20 | Terrain documentation treats Fort and Throne as live terrain types. | Runtime terrain codes contain `fort` but no `throne`; fort healing checks only `fort`. | **Update GDD.** Say throne art currently reuses fort behavior, or add a real throne terrain type before treating it as distinct. |
| P1-21 | Map 001's player deployment table has the wrong class for Unit_01. | `GDD_06` lists Unit_01 as Soldier. The current authored default roster and `GDD_03` use Cavalier. | **Update GDD.** Change the map table to Cavalier. |
| P1-22 | Move undo references hidden-enemy discovery that does not exist. | `GDD_02` says a move cannot be undone after revealing an enemy. Current selection code always allows undo until an action; fog/hidden-enemy detection is deferred. | **Update GDD.** State the current unconditional pre-action undo rule and move reveal-lock behavior to the fog-of-war backlog. |
| P1-23 | Trade appears as a normal inventory capability in `GDD_04`. | `GDD_02` correctly says Trade is future work and no Trade action is implemented. | **Update GDD.** Label Trade design-only wherever it appears. |
| P1-24 | Objective fallback comments describe an opt-out the code cannot represent. | `TurnManager` says an explicitly empty defeat array opts out of implicit rout, but `_conditions_for_group()` returns an empty array for both missing and explicit-empty keys, and both receive implicit rout. | **Reconcile.** Recommended: keep implicit rout mandatory so every group can be eliminated, and remove the misleading opt-out comments. If an opt-out is desired, represent key presence explicitly and add tests. |

## P2: Architecture and Data Reference Drift

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P2-1 | Resource inventory counts are stale. | `GDD_01` correctly lists 24 classes and 54 skills but says 6 items. The repository has 7 items after `strength_tonic.tres`; it has 10 weapons and 8 registered map entries across 7 map directories. | **Update GDD.** List the current resources and distinguish registry entries from directories. |
| P2-2 | `UnitData.active_modifiers` export status is wrong. | `GDD_01` shows it as `@export`; live `UnitData.gd` keeps it runtime-only and snapshots it manually. | **Update GDD.** Match the live non-export runtime field. |
| P2-3 | Skill-use counter keys are documented inconsistently. | `GDD_01` and a `UnitData` comment say `effect_id`; `SkillData`, `SkillHandler`, and the June fix use `skill.id` so shared handlers do not share quotas. | **Update GDD and the stale code comment.** `skill.id` is the correct key. |
| P2-4 | `ItemData.effect_id` documentation only names healing effects. | `ItemHandler.IMPLEMENTED_EFFECT_IDS` also contains `promote`, `reclass`, and `stat_buff`. | **Update GDD.** Document every implemented effect family. |
| P2-5 | Settings architecture omits live settings. | `SettingsManager` and `SettingsScreen` include `auto_end_turn` and `camera_edge_buffer`; `GDD_01` and the `GDD_07` layout/gameplay list omit them. | **Update GDD.** Add both fields, defaults, ranges/options, persistence, and UI rows. |
| P2-6 | Hybrid triangle field name is stale. | `GDD_04` says `magic_triangle_type`; live `WeaponData` uses `triangle_family` and `get_triangle_family()`. | **Update GDD.** Use `triangle_family`; retain the old name only in migration notes. |
| P2-7 | Effectiveness is documented against class qualities instead of vulnerabilities. | `GDD_04` examples use `has_quality("flying")`. Combat now deliberately checks `ClassData.vulnerability_groups` through `has_vulnerability()`. Mixing identity and susceptibility can make content silently immune or vulnerable. | **Update GDD.** Explain the distinction and author effectiveness against vulnerability groups. |
| P2-8 | Planned camera zoom visibility math is wrong. | At 1280x720 with 64px tiles, 1x is about 20x11 tiles. A 0.75 zoom shows about 27x15, not 53x29; 1.5 shows about 13x7.5, not 27x15. | **Update GDD before implementation.** Correct the figures and centralize viewport/tile conversion rather than hardcoding estimates. |

## P1: Skills and AI

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P1-25 | `GDD_05` implies M9a trigger coverage has landed. | It says recent M9a work extended coverage and that every relevant path calls its hook. Live calls cover start-of-turn and combat hooks, but there are no `on_move`, `on_level_up`, `player_activated`, or `on_defend` calls. | **Update GDD.** Call the current work a partial/pre-M9 engine seam and list live triggers separately from reserved trigger names. |
| P1-26 | Authored skill data can be mistaken for implemented behavior. | There are 54 skill resources, but many effect IDs dispatch to `_apply_unimplemented` and warn at runtime. `GDD_05` also calls class/promotion skills “designed, not implemented” even though their data exists. | **Update GDD.** Use three states: data authored, handler implemented, and end-to-end trigger wired. |
| P1-27 | AI profile extension instructions omit validation. | `GDD_08` says to add a match branch and function. `DataManager._VALID_AI_PROFILES` must also be updated or authored units/maps fail validation. | **Update GDD.** Include validator, data, behavior, and tests in the extension checklist. |
| P1-28 | AI pacing documentation says there is no per-enemy pause. | `EnemyAI._focus_camera()` waits 0.25 seconds at normal speed and 0.12 at fast speed before each acting unit. | **Update GDD.** Document the camera-focus delay and its movement-speed scaling. |

## P1: UI and Presentation

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P1-29 | `GDD_00` lists the Settings menu as a future Phase 3 item. | Settings, audio sliders, gameplay options, persistence, and a read-only control list are already implemented. Key rebinding, display options, and accessibility expansion remain future work. | **Update GDD.** Split implemented Settings from the remaining display/rebinding/accessibility backlog. |
| P1-30 | Cursor scene type is wrong in `GDD_07`. | It says `AnimatedSprite2D`; `GameMap.tscn` uses a `Sprite2D` child. | **Update GDD.** Describe the current Sprite2D and keep animation as future art work. |
| P1-31 | Phase UI promises controller context that is not rendered. | `GDD_07` and the locked M15 rule require `Faction - Controller`. `HUD` and `PhaseBanner` render only `<faction> PHASE`. | **Fix code** unless the M15 decision is formally revised. Use one shared formatter for banner and HUD so labels cannot drift. |
| P1-32 | Attack Preview dimensions are stale. | `GDD_07` says about 500x130. Current minimum columns are 150 + 150 + 260 pixels before margins, and row heights are content-driven. | **Update GDD.** Describe content-sized columns and viewport clamping instead of a fixed approximate size. |
| P1-33 | A selection ring is documented as live feedback. | The current scene has no wired selection-ring node; movement overlays and sprite darkening are the live indicators. | **Update GDD.** Mark the ring as planned or implement it before listing it as current feedback. |
| P1-34 | Attack Preview is said to open from a “Target Select List.” | Targeting occurs directly on the map; there is no target-list panel. | **Update GDD.** Rename this to map target selection. |

## P1: Awakening Corpus Conflicts

| ID | Difference | Evidence and risk | Recommendation |
|---|---|---|---|
| P1-35 | The Awakening corpus calls itself canonical without limiting that authority to Awakening reference data. | `awakening_project_index.md` describes a complete canonical implementation source. The project GDD and runtime intentionally use different rules in several places. Readers can reasonably treat the corpus as superseding the game GDD. | **Update corpus headers.** Label it “external Awakening reference; not the live project contract until adopted through a decision/GDD change.” |
| P1-36 | Equipped skill limits conflict. | Corpus: 5. Current project rule and `GameState.max_skills`: 4. | **Reconcile.** Recommended: retain 4 because it is the tabletop-derived current rule; record 5 as the Awakening-reference value unless the game deliberately adopts it. |
| P1-37 | Follow-up thresholds conflict. | Corpus: speed advantage 5. Current GDD/code: 4. | **Reconcile.** Recommended: retain 4 unless an explicit Awakening-compatibility decision changes combat balance. |
| P1-38 | Normal class WEXP caps conflict with the project rank model. | Corpus class tables generally cap normal classes at A/250 while also preserving a global S/400 convention. Current project supports S rank and S-rank mastery in the live class/weapon system. | **Reconcile before importing classes.** Define whether S is globally reachable, class-limited, or special-only, then normalize imported class caps to that rule. |
| P1-39 | Corpus Pair Up describes the full Awakening system as if implementation-ready. | It includes support scaling, Dual Strike, Dual Guard, and adjacent support. Current project only implements Pair Up pass 1 stat bonuses/actions; Dual Strike/Guard and forecast UI remain pending. | **Update corpus integration notes.** Add an adoption matrix showing implemented, planned, and intentionally omitted mechanics. |
| P1-40 | Corpus links are not repository-portable. | `awakening_master_index.md` links to `sandbox:/mnt/data/...`, which is dead outside the generation environment. | **Update corpus.** Replace links with relative repository links. |
| P2-9 | Content-expansion directory names contain persistent typos. | At audit time the active and archived directories used `New_Contet_expansion` and `Old-deffered`. This made links and search terms error-prone. | **Reconcile carefully.** Rename only in a dedicated link-migration commit after locating every reference. This is low priority but should not become permanent public structure. |

## Verified Alignments

The following high-risk areas were checked and currently agree:

- At audit time, the follow-up threshold was 4 in both `GDD_02` and
  `GameConstants`; the settlement addendum deliberately changes it to 5.
- Current content counts for classes (24), skills (54), weapons (10), and registered
  maps (8) are otherwise consistent with the implementation baseline.
- Explicit Escape action semantics in code match the post-2026-05-20 decision
  addendum and current `GDD_06`.
- Per-group objective dictionaries, AND-victory/OR-defeat evaluation, standings,
  objective HUD text, and maps 002-005 are implemented.
- Party rewards are applied once through the map-over latch and are included in
  retry snapshots.
- Pair Up pass 1 is accurately summarized in `GDD_00` and the newer `GDD_10a`
  completion row.

## Recommended Settlement Order

1. Fix P0-1 and P0-2 with regression tests.
2. Establish the authority order in `GDD_00`; mark assumptions/checklists historical.
3. Refresh M14-M16 status and checklists so roadmap ordering is trustworthy.
4. Correct progression, economy, map-loading, and objective documentation.
5. Correct architecture/data/UI reference drift.
6. Add the Awakening-corpus authority banner and adoption matrix before M9/M11
   imports create more conflicting live content.
7. Resolve remaining explicit design choices: flying movement, implicit-rout opt-out,
   skill cap, follow-up threshold, and S-rank reachability.

## Suggested Follow-Up Work Packages

- **Round semantics:** TurnManager implementation, objective/parity regression tests,
  and Decision 7 documentation.
- **Seize schema cleanup:** resource field removal, data migration, validator/tests,
  and GDD schema update.
- **Roadmap truth pass:** M14/M15/M16 status, checked tasks, current-state prose,
  Pair Up scope, and historical notes.
- **Core GDD resync:** progression, economy, unit creation, terrain, maps, and data
  field names/counts.
- **Corpus integration contract:** authority banner, relative links, adoption matrix,
  and explicit conflict decisions.
