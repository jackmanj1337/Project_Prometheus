> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Unit Progression Extraction Plan — 2026-06-17

## Status — Planned

Last verified: 2026-06-17

Plan to slice the class-change (promotion / reclass / second-seal) cluster out of
`scripts/units/Unit.gd` into a unit-testable `RefCounted` helper, following the
same pattern already used to slice `MapCursor.gd` into `MapCursorSelection`,
`MapCursorTargeting`, and `MapCursorInput`. Originates from the 2026-06-17
comprehensive code review, finding #5 (large-file readability).

## Motivation

`Unit.gd` is 1188 lines and mixes five concerns: identity/position, HP/death,
movement animation, the modifier-aware combat stats, EXP/level-up growth, and the
class-change state machine. The class-change cluster is ~300 lines and is the most
self-contained — it is a cohesive "what class is this unit and how does it change"
concern that combat and movement never touch directly. Extracting it:

- drops `Unit.gd` to roughly the size of `CombatResolver.gd` (~810 lines);
- makes the second-seal option matrix (tier-1 reclass, tier-2 lateral, demote,
  self-reset) testable without instancing a `Unit` Node + SceneTree;
- isolates the one genuinely intricate algorithm (base-stat replacement across
  class lines) behind a named seam with its own test file.

This is a **pure refactor** — no behavior change. DoD#1 (GDD + roadmap flip) does
**not** apply; DoD#2 (check) does not apply (no new mechanical rule). Success is
defined as: the existing `test_unit_stats.gd`, `test_reclass_screen.gd`, and
`test_promotion_screen.gd` suites pass unchanged.

## Established pattern to mirror

`MapCursorSelection` (see `scripts/core/MapCursorSelection.gd`):

- `class_name UnitProgression extends RefCounted` — a plain RefCounted, NOT a
  Node, so it is testable without a SceneTree.
- Dependencies injected via `setup(...)` rather than tree walks.
- The owning object keeps its public surface and FSM/signal relays; the helper
  holds only the extracted logic.
- A dedicated `test_*` suite drives the helper directly.

## What moves

The cohesive class-change cluster (current `Unit.gd` line ranges approximate):

| Method | Role |
|---|---|
| `promote` / `can_promote` | tier-1 → tier-2 promotion |
| `_apply_promotion_stat_bonuses` / `_apply_class_weapon_bases` | promotion stat + wexp baselines |
| `can_use_second_seal` / `get_second_seal_options` | second-seal option matrix |
| `reclass` | apply a chosen second-seal option |
| `_self_reset_only` / `_append_second_seal_option` | option-list builders |
| `_target_line_ids_for_promoted_class` / `_normalize_line_id` | class-line resolution |
| `_remove_promotion_stat_bonuses` | demote bonus removal |
| `_replace_class_base_stats` / `_class_base_contributor` | cross-line base-stat swap |
| `_clamp_stats_to_caps` / `_clamp_to_cap` | cap clamping |
| `_effective_second_seal_tier` | special-rule tier resolution |
| `_ensure_class_line_id` / `_current_class_line_id` | line-id seeding |
| `_ensure_internal_level` / `_recalculate_internal_level` | internal-level math |
| `_reset_class_level_state` | level/exp/accumulator reset on class change |

## What STAYS on Unit (explicitly out of scope for phase 1)

- EXP/level-up growth (`add_exp`, `level_up`, `_level_up_random/_fixed`,
  `_apply_stat_gain`, `_increment_stat`, growth-rate resolution). This is the
  per-combat hot path, is tightly bound to the HP bar and the debug growth aids,
  and emits `unit_leveled_up`. Slicing it is a separate future candidate.
- `_get_class_data` / `_class_data_for` stay on Unit (used everywhere) and become
  the DataManager-access shape the helper reuses via injection (below).
- Skill granting (`_grant_*`, `_learn_skill`, `_seed_earned_skills`). `reclass`
  and `promote` will call back into the Unit for these (see seam) rather than
  duplicate them — they are level-up/skill concerns, not class-change math.

## The seam (dependency injection)

The blocker is that these methods mutate `data` (a `UnitData`) and refresh the
`_hp_bar` Node mid-computation. The helper must not hold a Node reference if it is
to stay SceneTree-free. Inject three things via `setup()`:

```gdscript
# UnitProgression.gd
var _data: UnitData = null
var _dm: Node = null                  # DataManager (or null in pure-data tests)
var _on_hp_changed: Callable          # Unit wires this to refresh its HPBar

func setup(data: UnitData, data_manager: Node, on_hp_changed: Callable) -> void:
    _data = data
    _dm = data_manager
    _on_hp_changed = on_hp_changed
```

- Class lookups go through `_dm.get_class_data(id)` with the same null-guards
  `Unit._class_data_for` uses today (headless tests can pass a stub or null).
- Every site that currently does `if _hp_bar: _hp_bar.max_value = ...; .value = ...`
  becomes `if _on_hp_changed.is_valid(): _on_hp_changed.call()` after mutating
  `_data.max_hp/hp`. `Unit` supplies a one-line callable that re-syncs the bar.
- Skill granting after reclass: the helper returns a small result (e.g. the new
  class_id) and `Unit.reclass` calls `_grant_current_level_class_skills()` itself,
  OR the helper takes a second `on_class_changed: Callable`. Prefer the former —
  fewer injected callables, and skill granting already lives on Unit.

`Unit` keeps the public methods (`promote`, `reclass`, `get_second_seal_options`,
`can_promote`, `can_use_second_seal`) as thin delegators that forward to
`_progression`, so every existing caller (ReclassScreen, PromotionScreen,
MapCursor, tests) is untouched. Signal emission (`unit_promoted`,
`unit_reclassed`) stays on `Unit` — same split as MapCursor keeping the EventBus
relays.

## Phasing (each phase: green suite + its own commit)

1. **Scaffold (no logic moved).** Add `UnitProgression.gd` (RefCounted, empty
   `setup`), instantiate it as `var _progression := UnitProgression.new()` on
   Unit, call `setup` from `_ready` once `data` is known. Add a `test_unit_
   progression.gd` that asserts the helper constructs and `setup` injects.
2. **Move the pure (non-mutating) readers first:** `get_second_seal_options`,
   `_self_reset_only`, `_append_second_seal_option`,
   `_target_line_ids_for_promoted_class`, `_normalize_line_id`,
   `_effective_second_seal_tier`, line-id readers. These have no HP-bar side
   effects, so they validate the DataManager-injection seam in isolation. Move
   the relevant assertions out of `test_unit_stats.gd` into
   `test_unit_progression.gd` (drive the helper directly with stub ClassData).
3. **Move the mutators:** `promote`, `reclass`, `_apply_promotion_stat_bonuses`,
   `_apply_class_weapon_bases`, `_remove_promotion_stat_bonuses`,
   `_replace_class_base_stats`, `_class_base_contributor`, `_clamp_stats_to_caps`,
   `_reset_class_level_state`, internal-level helpers. Wire the `on_hp_changed`
   callable. Keep `Unit`'s public methods as delegators that still emit signals
   and call skill-granting.
4. **Cleanup:** delete the now-dead private methods from `Unit.gd`; update the
   `Unit.gd` header comment to describe the new split (the header was just
   corrected in the 2026-06-17 review to stop referencing a non-existent
   `UnitStatBlock.gd` — keep it honest this time).

## Test strategy

- New `scripts/tests/test_unit_progression.gd` drives `UnitProgression` against
  hand-built `UnitData` + stub/real `ClassData`, with a captured `on_hp_changed`
  Callable asserting it fires when max_hp changes. This is the payoff: the
  second-seal matrix and base-stat-swap math become SceneTree-free tests.
- `test_unit_stats.gd`, `test_reclass_screen.gd`, `test_promotion_screen.gd` must
  pass UNCHANGED through phases 1 and 3 (they exercise the Unit delegators) — they
  are the regression guard that the refactor preserved behavior. Only in phase 2
  do the pure-reader assertions migrate to the new suite.
- Run `run_tests.sh` (full suite) at the end of every phase; the glob picks up the
  new suite automatically.

## Risks / watch-items

- **HP-bar refresh ordering.** Several mutators refresh the bar mid-method (e.g.
  `_replace_class_base_stats` adjusts max_hp then clamps). Keep the exact mutate →
  refresh order; route each refresh through the one Callable. A single drift-guard
  test that promotes a near-cap unit and checks final hp == max_hp covers this.
- **`class_name` cache.** `UnitProgression` is a new `class_name` script; per the
  saved memory + `.gitignore` note, add it to `.godot/global_script_class_cache.cfg`
  (the tracked cache) or headless `--script` runs can't resolve it.
- **Internal-level seeding runs at `_ready`.** `_ensure_class_line_id` /
  `_ensure_internal_level` are called from `Unit._ready`, not only reclass. Ensure
  `setup` runs before those calls (or have `_ready` call them through the helper
  after `setup`). Sequencing bug here would mis-seed brand-new units.
- **No behavior change is the bar.** If any assertion needs editing to keep a
  suite green (beyond the planned phase-2 migration), stop — that signals the slice
  changed behavior, which this refactor must not.

## Estimated effort

~Half a session. Phase 1–2 are mechanical; phase 3 is the careful part (the
base-stat-swap math). Phase 4 is trivial once 3 is green.
