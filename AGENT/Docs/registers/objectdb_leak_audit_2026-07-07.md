# ObjectDB Leaked-Instance Audit (2026-07-07)

**Status:** RESOLVED (2026-07-07) — benign test-teardown artifact; production node
lifecycle is clean. Guard test added so the noise can no longer mask a real regression.

**Register:** `[ODB-1]` — is the recurring `ObjectDB instances leaked at exit`
warning a production memory leak or test noise?

**Scope:** headless test suite + production runtime node/dialog lifecycle on
`v0.3.0-features`.

---

## Trigger

`WARNING: ObjectDB instances leaked at exit (run with --verbose for details)` has
appeared at the tail of Godot runs since v0.2.0 and recurs in returned playtest logs
(v0.2.6, v0.2.7 evidence logs). Prior triage (v0.2.0 plan, gdd10 legacy roadmap)
ruled it **monitor-only** pending verbose leak details. This audit gathers those
details and closes `[ODB-1]`.

## Method

Ran all 62 `scripts/tests/test_*.gd` suites individually with `--verbose`, capturing
per-suite `Leaked instance: Node:` counts and `Resource still in use:` lines. Then
inspected production node lifecycle for the two ways a "not in scene tree" orphan can
arise: `remove_child()` without a free, and transient nodes (dialogs) not freed on
dismissal.

## Findings

**51 of 62 suites are leak-clean.** The 11 that emit the warning:

| Suite | Leaked Nodes |
| --- | --- |
| `test_combat` | 53 |
| `test_turn_manager` | 9 |
| `test_grid_manager` | 7 |
| `test_enemy_ai` | 6 |
| `test_pair_up_bonus_resolver` | 5 |
| `test_action_menu` | 4 |
| `test_rng_combat_determinism` | 4 |
| `test_map_cursor` | 2 |
| `test_game_map_scene` | 1 |
| `test_input_bindings` | 1 |
| `test_pair_up_registry` | 1 |

The `Resource still in use:` lines are all GDScript class scripts (e.g.
`UnitData.gd`, `TurnManager.gd`) and `ResourceLoader`-cached `.tres`
(`heal_staff.tres`) — the normal script/resource cache, not leaked game state.

## Root cause — benign test teardown, not a production leak

Three independent lines of evidence:

1. **The count scales with test fixtures, not production instances.** `test_combat`
   (53) builds dozens of `Unit`/`UnitData`/`WeaponData` fixtures; the clean suites
   build none or free what they build. `test_game_map_scene` instantiates
   `GameMap.tscn` **five** times yet leaks exactly **one** node — a per-load
   production leak would scale to ~5. The leaked count tracks unfreed local fixtures
   held only by vars/signal closures when `quit()` fires.

2. **Production has zero `remove_child()`.** `grep -rn remove_child scripts/` (minus
   `scripts/tests/`) returns nothing. The "removed from tree but not freed" orphan
   pattern the engine hint describes cannot originate from production reparenting.

3. **Every transient production dialog frees on all dismissal paths.** The per-
   interaction dialogs in `MapCursor.gd` (`_on_end_turn_*`, `_on_quit_to_menu_*`,
   `_on_suspend_and_quit_*`, `_show_suspend_failed_dialog`) each `queue_free()` in
   both the `confirmed` and `canceled` handlers; `DisplayConfirmDialog` frees on
   Keep, Revert, and countdown-expiry. None persist across a session.

A `SceneTree`-based test that calls `quit()` does not recursively free nodes that are
detached or held only by local references, and RefCounted resources still held by
closures report "still in use." The process then exits and the OS reclaims all
memory — the warning is cosmetic.

## Disposition

`[ODB-1]` RESOLVED:

- **Confirmed benign.** The exit warning is not a production memory leak; no runtime
  fix is warranted.
- **The noise masked signal.** Because the warning already fires from fixture
  teardown, a *real* future production leak (a dialog that stops freeing) would be
  invisible in the same log line. To restore signal, a targeted guard was added
  rather than retrofitting teardown into 11 heavy suites.
- **Guard added:** `scripts/tests/test_node_lifecycle_leak.gd` drives a
  representative code-built production subtree (`DisplayConfirmDialog`) through the
  full create → `add_child` → free cycle 12× and on a mid-countdown free, asserting
  `Performance.OBJECT_ORPHAN_NODE_COUNT` returns to baseline (the monitor is precise:
  +1 on an unparented `Node.new()`, back to baseline on `free()`). The suite frees
  every fixture it creates, so it is itself leak-clean (`leakwarn=0`) — the pattern
  future suites should follow if the exit noise is ever to be driven to zero.

## Follow-ups (optional, not blocking)

- Test-teardown hygiene: the 11 leaking suites could free their fixtures before
  `quit()` to silence the exit warning entirely. Low value (cosmetic) vs. the churn
  across large suites; deferred. The guard above already covers the real risk.
