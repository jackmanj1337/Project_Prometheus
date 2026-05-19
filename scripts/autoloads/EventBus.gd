extends Node
# Central signal bus. All game systems emit here; no direct cross-system references needed.
# [NOTE — M-1] class_name cannot be added here: Godot 4 forbids class_name on a script
# that is registered as an autoload singleton with the same name (name collision).

signal unit_selected(unit: Node)
signal unit_deselected()
signal unit_moved(unit: Node, from_tile: Vector2i, to_tile: Vector2i)
signal unit_action_taken(unit: Node)
signal combat_started(attacker: Node, defender: Node)
# Emitted AFTER handle_death() has been called on any loser(s). Listeners MUST
# use is_instance_valid() before dereferencing attacker/defender across frames.
signal combat_resolved(attacker: Node, defender: Node, result: Dictionary)
signal unit_damaged(unit: Node, amount: int)
signal unit_died(unit: Node)
signal unit_healed(unit: Node, amount: int)
signal unit_leveled_up(unit: Node, stat_increases: Dictionary)
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
