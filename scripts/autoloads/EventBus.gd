extends Node
# Central signal bus. All game systems emit here; no direct cross-system references needed.
# [NOTE — M-1] class_name cannot be added here: Godot 4 forbids class_name on a script
# that is registered as an autoload singleton with the same name (name collision).

signal unit_selected(unit: Node)
signal unit_deselected()
signal unit_moved(unit: Node, from_tile: Vector2i, to_tile: Vector2i)
signal unit_action_taken(unit: Node)
# Fires at the TOP of CombatResolver.resolve_combat — before any RNG is rolled,
# before exchanges are computed, before stats are committed. Listeners that want
# a "fight is about to begin" hook (intro animation, camera focus, sfx) read this
# one. preview_combat does NOT emit it — the signal marks an actual fight, not a
# forecast. (B2 / 05-18 review §2: previously fired from apply_combat_result,
# misnaming an apply-phase event.)
signal combat_started(attacker: Node, defender: Node)
# Emitted AFTER handle_death() has been called on any loser(s). Listeners MUST
# use is_instance_valid() before dereferencing attacker/defender across frames.
signal combat_resolved(attacker: Node, defender: Node, result: Dictionary)
signal unit_damaged(unit: Node, amount: int)
signal unit_died(unit: Node)
signal unit_healed(unit: Node, amount: int)
signal unit_leveled_up(unit: Node, stat_increases: Dictionary, learned_skills: Array)
# Brackets the level-up screen being on-screen — fired when it first appears and
# again once its whole queue is dismissed. MapCursor uses these to suppress input
# so the cursor can't be driven underneath the screen (#12).
signal level_up_started()
signal level_up_finished()
signal phase_changed(new_phase: int)  # GameState.Phase enum value
signal cursor_moved(tile: Vector2i)
# Emitted by EnemyAI as each enemy is about to act, so GameMap can pan the
# camera to keep the enemy phase on-screen (#7).
signal ai_unit_acting(unit: Node)
signal map_victory()
signal map_defeat()
# M16 stage 4: emitted alongside map_victory / map_defeat with the full per-group
# standings. winner_group is the alliance group that won (e.g. "allies") or ""
# for a draw. standings is an Array of dictionaries — one per group in play —
# each with keys: group (String), eliminated_round (int; -1 = winner / never
# eliminated), rank (int; 1 = top), is_blue_group (bool). The new
# ranked-standings results screen consumes this directly; the existing
# blue-perspective signals stay for back-compat.
signal map_resolved(winner_group: String, standings: Array)
# Fired when any GameState debug-aid flag flips (force-levelup, growth-boost).
# Lets the HUD's DEBUG MODE banner re-render the list of active aids in real
# time when a flag is toggled from the remote debugger. DEBUG AID — remove with
# the flags themselves before release; see GDD_10_Roadmap.md § Pre-Release Cleanup.
signal debug_flags_changed()
