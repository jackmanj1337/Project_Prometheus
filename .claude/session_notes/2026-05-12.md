# Session Notes — 2026-05-12

## What Was Done

### Merged MVP Amendments (A1–A4) from GDD_updates.md into main codebase and GDD docs

**Amendment A1 — Data Layer Extensions**
- Added Phase 2 runtime fields to `UnitData.gd`: `active_modifiers`, `skill_use_counters`, `damage_taken_this_map`, `shift_gauge`, `is_shifted`, `shift_profile_id`
- Added Laguz gauge fields to `ClassData.gd` (all safe defaults for Beorc)
- Added `strikes_per_attack` and `is_natural_weapon` to `WeaponData.gd`
- Added `max_uses_per_map`, `max_uses_per_combat` and updated trigger docstring in `SkillData.gd`
- Created `scripts/autoloads/ConditionManager.gd` — stub autoload (all no-ops until M8)
- Updated `GameState._snapshot_unit_data()` and `_restore_unit_data()` to include new runtime fields

**Amendment A2 — Unit Script Modifier System**
- Added `get_effective_stat(stat_name)` to `Unit.gd` — base + modifier sum, clamped ≥ 0
- Added `has_skill()`, `get_skill_uses_remaining()`, `consume_skill_use()` helpers
- Added modifier lifecycle: `add_modifier()`, `remove_modifier()`, `tick_modifiers()`, `clear_combat_modifiers()`, `reset_map_state()`
- Refactored all 6 combat stat functions (`battle_speed`, `accuracy`, `dodge`, `damage`, `crit_rate`, `crit_avoid`) to read through `get_effective_stat()` instead of `data.strength` etc. directly

**Amendment A4 — Grid System Skill Hooks**
- Added `SkillHandler.get_move_cost_override()`, `can_pass_through_enemies()`, `can_phase_through()` stubs
- Modified `GridManager.get_move_cost()` to check skill overrides before terrain table
- Modified `GridManager.is_passable()` to check Pass and Phasing skill stubs
- Added `GridManager.can_end_on_tile()` — separates passable-through from stoppable

**Naming decision:** Using `"strength"` (not `"str"`) as the modifier stat key to match existing `UnitData` property names.

**GDD Documentation Updated**
- `GDD_01_Architecture.md`: resource class definitions updated with all new fields; ConditionManager added to autoloads section; Unit.gd signatures updated; autoload order updated
- `GDD_09_Checklist.md`: status snapshot updated; amendment checklists (A1–A4) added within relevant milestones

### Renamed All Abbreviated Stat Names to Full English Words

Extended the `str→strength` pattern to every other abbreviated stat across the entire codebase:
- `mag→magic`, `def→defense`, `res→resistance`, `skl→skill`, `spd→speed`, `luk→luck`, `mov→movement`, `con→constitution`, `los→line_of_sight`
- `base_str→base_strength` and all other `base_*` fields in `ClassData.gd`
- 36 files changed: all `.gd` scripts, all 14 `.tres` unit/class data files, `miracle.tres`, and GDD docs
- All 131 tests still green after rename

### Git Push Now Works Without Token URL
- Configured `~/.git-credentials` with GitHub PAT via `credential.helper store`
- Plain `git push` now works in all future sessions — no need for the long token URL

## Commits Made
- Merged A1–A4 amendments (see earlier commits)
- `Rename all abbreviated stat names to full English words` — 36 files, 314 changes, all 131 tests green

## Remaining Action Required
- **Register `ConditionManager` as autoload in Godot Project Settings** (after DataManager). The file exists at `scripts/autoloads/ConditionManager.gd` — only the project.godot entry is missing.

## Pending / Not Yet Done (A2/A4 follow-on)
- Hook `tick_modifiers()` into TurnManager at unit turn start
- Hook `clear_combat_modifiers()` into CombatResolver after each combat
- Hook `reset_map_state()` into GameMap._ready() before snapshot
- Update `get_movement_range()` and MapCursor to use `can_end_on_tile()`

## Plans for Next Session
- Start **M4 — Combat System** (Amendment A3 is part of M4)
- CombatResolver already partially implemented; A3 adds context pipeline and multi-strike support
- Wire the remaining A2/A4 hooks (TurnManager, CombatResolver, GameMap, MapCursor)
- All 131 tests still passing after this session's changes
