extends Node
# Local human controller for a non-blue faction. Reuses the existing cursor:
# point it at the acting faction, unlock it, then wait for TurnManager to
# commit the phase via request_end_phase() or map resolution.

var _cursor: Node = null


func set_cursor(cursor: Node) -> void:
	_cursor = cursor


func run_phase(_grid: GridManager, turn: TurnManager, faction_id: String) -> void:
	if turn == null or _cursor == null or not is_instance_valid(_cursor):
		return
	if turn._map_over:
		return
	_cursor.set_controlling_faction(faction_id)
	_cursor.unlock()
	await turn.phase_committed
