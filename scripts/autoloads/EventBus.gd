extends Node
# Central signal bus. All game systems emit here; no direct cross-system references needed.

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
signal phase_changed(new_phase: int)  # GameState.Phase enum value
signal cursor_moved(tile: Vector2i)
signal map_victory()
signal map_defeat()
