extends SceneTree
# Crossing resolver ([PCM-1]..[PCM-7]).
#
# The load-bearing case is PARITY: the same map, the same path and the same
# trigger must resolve identically for an animated player move, an Instant-speed
# move, and an AI move. That assertion is the one that would have caught the
# original defect — hooking the tween silently does nothing at Instant speed,
# because move_along_path's per-tile loop never executes there.

const ResolverScript = preload("res://scripts/core/CrossingResolver.gd")
const ServiceScript = preload("res://scripts/autoloads/CrossingService.gd")
# Instantiate from the scene so the @onready sprite/HP-bar refs are populated —
# move_along_path itself needs none of them, but _ready() does.
const UnitScene = preload("res://scenes/units/Unit.tscn")

var passed := 0
var failed := 0


func check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s%s" % [label, "" if detail.is_empty() else ": " + detail])
		failed += 1


# A consumer that fires on one tile with a declared interrupt/ends_activation.
class TileTrigger:
	extends RefCounted
	var tile: Vector2i
	var declaration: Dictionary
	var effect_tiles: Array[Vector2i] = []

	func _init(t: Vector2i, decl: Dictionary) -> void:
		tile = t
		declaration = decl

	func probe(context: Dictionary) -> Variant:
		if context["tile"] != tile:
			return null
		var out: Dictionary = declaration.duplicate()
		out["effect"] = func(ctx: Dictionary) -> void: effect_tiles.append(ctx["tile"])
		return out


# A consumer that fires carrying NO effect Callable at all. TileTrigger always
# injects one, so it structurally cannot produce the effect-less case [PCM-7]
# was actually ruled on.
class EffectlessTrigger:
	extends RefCounted
	var tile: Vector2i
	var declaration: Dictionary

	func _init(t: Vector2i, decl: Dictionary) -> void:
		tile = t
		declaration = decl

	func probe(context: Dictionary) -> Variant:
		if context["tile"] != tile:
			return null
		return declaration.duplicate()


func straight_path(length: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for x in length:
		path.append(Vector2i(x, 0))
	return path


func _init() -> void:
	print("=== CrossingResolver Test ===")
	_test_no_consumers()
	_test_halt_truncates()
	_test_continue_runs_on()
	_test_effectless_trigger_is_permanent()
	_test_ends_activation_axis()
	_test_default_is_halt()
	_test_origin_is_not_crossed()
	_test_deterministic_order()
	_test_malformed_declarations()
	await _test_movement_parity()
	await _test_undo_guard()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_no_consumers() -> void:
	var resolver = ResolverScript.new()
	var path := straight_path(4)
	var outcome = resolver.resolve(null, path)
	check(
		outcome.path == path and not outcome.halted and not outcome.movement_permanent,
		"no consumers: path passes through untouched"
	)


func _test_halt_truncates() -> void:
	var resolver = ResolverScript.new()
	var trigger := TileTrigger.new(Vector2i(2, 0), {"id": "trap", "interrupt": "halt"})
	resolver.register_consumer("trap", trigger.probe)
	var outcome = resolver.resolve(null, straight_path(5))
	# [PCM-5]: the move ENDS on the triggering tile — which is included, because
	# the unit did enter it.
	check(
		outcome.path == ([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i]),
		"halt: path truncated at and including the triggering tile",
		str(outcome.path)
	)
	check(outcome.halted and outcome.halt_tile == Vector2i(2, 0), "halt: halt_tile recorded")
	check(outcome.fired == ["trap"], "halt: trigger id recorded once", str(outcome.fired))
	check(
		trigger.effect_tiles == [Vector2i(2, 0)],
		"halt: effect ran, once, on the triggering tile",
		str(trigger.effect_tiles)
	)
	# [PCM-7] clause 1.
	check(outcome.movement_permanent, "halt: a fired trigger makes the movement permanent")
	# [PCM-6] is a separate axis — halting alone must NOT end the activation.
	check(not outcome.ends_activation, "halt: does not end the activation on its own")


func _test_continue_runs_on() -> void:
	var resolver = ResolverScript.new()
	var bog := TileTrigger.new(Vector2i(1, 0), {"id": "bog", "interrupt": "continue"})
	resolver.register_consumer("bog", bog.probe)
	var path := straight_path(4)
	var outcome = resolver.resolve(null, path)
	check(
		outcome.path == path and not outcome.halted,
		"continue: the unit keeps moving through the trigger"
	)
	check(outcome.fired == ["bog"], "continue: the effect still fired")
	check(outcome.movement_permanent, "continue: a fired effect is still permanent")


func _test_effectless_trigger_is_permanent() -> void:
	# [PCM-7], answered by the v0.7.0 Windows return decision sheet, question 5:
	# "Yes — firing is what commits the move, effect or not." The resolver has
	# always implemented that reading (CrossingResolver sets movement_permanent
	# before it so much as reads the effect key), but every other case in this
	# suite fires through TileTrigger, which injects an effect Callable — so the
	# effect-less half of the ruling had no coverage. A future "only commit when
	# something actually happened" change would have passed the whole suite.
	var resolver = ResolverScript.new()

	# Halting with no effect: a bare halt still reveals the trap that caused it,
	# which is the reason the broad reading was chosen.
	var halt_declaration := {"id": "ambush", "interrupt": "halt"}
	var ambush := EffectlessTrigger.new(Vector2i(2, 0), halt_declaration)
	resolver.register_consumer("ambush", ambush.probe)
	var outcome = resolver.resolve(null, straight_path(5))
	check(
		not halt_declaration.has("effect"),
		"effect-less halt: the declaration really carries no effect"
	)
	check(outcome.fired == ["ambush"], "effect-less halt: the trigger fired", str(outcome.fired))
	check(
		outcome.movement_permanent,
		"effect-less halt: a fired trigger with no effect still commits the move"
	)

	# Continuing with no effect is the most invisible case there is — nothing
	# stops and nothing happens — and it commits the move just the same.
	var walk_resolver = ResolverScript.new()
	var walk_declaration := {"id": "tripwire", "interrupt": "continue"}
	var tripwire := EffectlessTrigger.new(Vector2i(1, 0), walk_declaration)
	walk_resolver.register_consumer("tripwire", tripwire.probe)
	var path := straight_path(4)
	var walked = walk_resolver.resolve(null, path)
	check(walked.path == path and not walked.halted, "effect-less continue: the unit keeps moving")
	check(
		walked.movement_permanent,
		"effect-less continue: firing alone commits the move, with no effect and no halt"
	)


func _test_ends_activation_axis() -> void:
	# [PCM-6]: the two axes compose. {halt, ends_activation: true} is a disabling
	# trap; {halt, false} is the FE ambush.
	var resolver = ResolverScript.new()
	# Hold the trigger in a local: a Callable does NOT keep a RefCounted alive,
	# so an inline TileTrigger.new(...).probe would be freed before resolve runs.
	var trap := TileTrigger.new(Vector2i(1, 0), {"id": "beartrap", "ends_activation": true})
	resolver.register_consumer("beartrap", trap.probe)
	var outcome = resolver.resolve(null, straight_path(4))
	check(
		outcome.halted and outcome.ends_activation,
		"ends_activation: a disabling trap halts AND ends the activation"
	)


func _test_default_is_halt() -> void:
	# [PCM-5]: a trigger that declares no interrupt halts. The failure mode is
	# deliberate — stop the unit visibly rather than silently apply an effect.
	var resolver = ResolverScript.new()
	var bare := TileTrigger.new(Vector2i(1, 0), {"id": "bare"})
	resolver.register_consumer("bare", bare.probe)
	var outcome = resolver.resolve(null, straight_path(4))
	check(outcome.halted, "default interrupt is halt")


func _test_origin_is_not_crossed() -> void:
	# The unit is already standing on path[0]; a trigger there had its chance.
	var resolver = ResolverScript.new()
	var on_origin := TileTrigger.new(Vector2i(0, 0), {"id": "origin"})
	resolver.register_consumer("origin", on_origin.probe)
	var path := straight_path(3)
	var outcome = resolver.resolve(null, path)
	check(
		outcome.fired.is_empty() and outcome.path == path,
		"origin tile is not a crossing",
		str(outcome.fired)
	)


func _test_deterministic_order() -> void:
	# Replay/determinism: consumers resolve in REGISTRATION order, and every
	# consumer on the halting tile fires — the unit entered it.
	var resolver = ResolverScript.new()
	var first := TileTrigger.new(Vector2i(1, 0), {"id": "first", "interrupt": "halt"})
	var second := TileTrigger.new(Vector2i(1, 0), {"id": "second", "interrupt": "continue"})
	resolver.register_consumer("first", first.probe)
	resolver.register_consumer("second", second.probe)
	var outcome = resolver.resolve(null, straight_path(4))
	check(
		outcome.fired == ["first", "second"],
		"co-located triggers all fire, in registration order",
		str(outcome.fired)
	)
	check(outcome.halted, "one halting trigger among co-located triggers still halts")


func _test_malformed_declarations() -> void:
	var resolver = ResolverScript.new()
	resolver.register_consumer("noid", func(_ctx): return {"interrupt": "continue"})
	resolver.register_consumer("bogus", func(_ctx): return {"id": "x", "interrupt": "sideways"})
	resolver.register_consumer("wrongtype", func(_ctx): return 7)
	var outcome = resolver.resolve(null, straight_path(3))
	check(outcome.errors.size() == 3, "malformed declarations are reported", str(outcome.errors))
	# The unknown interrupt falls back to halt, not to continue.
	check(outcome.halted and outcome.fired == ["x"], "unknown interrupt falls back to halt")
	# Duplicate registration is refused rather than silently doubling a trigger.
	check(
		not resolver.register_consumer("noid", func(_ctx): return null).is_empty(),
		"duplicate consumer id is refused"
	)


# ── Movement integration ─────────────────────────────────────────────────────


# Returns the live autoload, or installs one under that exact name if this run
# has none. Never adds a duplicate — see the note in _test_movement_parity.
func _autoload(node_name: String, script: Script) -> Node:
	var existing := root.get_node_or_null("/root/" + node_name)
	if existing != null:
		return existing
	var made: Node = script.new()
	made.name = node_name
	root.add_child(made)
	return made


func _make_unit() -> Unit:
	var unit: Unit = UnitScene.instantiate()
	# tile_position is a pass-through to data.tile_position, so a unit with no
	# data can neither hold nor report a tile — every mover here needs one.
	unit.data = UnitData.new()
	unit.data.tile_position = Vector2i(0, 0)
	root.add_child(unit)
	return unit


# DoD#2: the same trigger on the same path must halt on the same tile whether
# the move animates, snaps instantly, or is driven by the AI.
func _test_movement_parity() -> void:
	# Use the real autoloads. Adding a second node called "CrossingService" only
	# wins the /root name race if it lands before autoloads attach on the first
	# frame — after that Godot renames the newcomer and Unit resolves the
	# autoload instead, so the suite would silently test nothing.
	await process_frame
	var service: Node = _autoload("CrossingService", ServiceScript)
	var settings: Node = _autoload(
		"SettingsManager", load("res://scripts/autoloads/SettingsManager.gd")
	)
	service.clear_consumers()

	var trigger := TileTrigger.new(Vector2i(2, 0), {"id": "ambush"})
	service.register_consumer("ambush", trigger.probe)
	var path := straight_path(6)

	# Animated: "fast" is a real per-tile duration, so the tween branch runs.
	settings.movement_speed = "fast"
	var animated: Unit = _make_unit()
	var animated_outcome = await animated.move_along_path(path)

	# Instant: get_movement_speed_seconds() returns 0.0, so move_along_path takes
	# the snap_to_tile branch where the per-tile loop never executes at all. This
	# is the assertion that fails for any tween-hooked design.
	settings.movement_speed = "instant"
	var instant: Unit = _make_unit()
	var instant_outcome = await instant.move_along_path(path)

	check(
		animated.tile_position == Vector2i(2, 0),
		"animated move halts on the triggering tile",
		str(animated.tile_position)
	)
	check(
		instant.tile_position == Vector2i(2, 0),
		"INSTANT-SPEED move halts on the same tile (tween-hook parity)",
		str(instant.tile_position)
	)
	check(
		(
			animated_outcome.path == instant_outcome.path
			and animated_outcome.fired == instant_outcome.fired
			and animated_outcome.halt_tile == instant_outcome.halt_tile
		),
		"animated and instant outcomes are identical"
	)
	check(
		trigger.effect_tiles.size() == 2,
		"the effect fired exactly once per move, not once per tween step",
		str(trigger.effect_tiles)
	)

	# The AI drives the same Unit.move_along_path, so it inherits resolution by
	# construction; assert it rather than assume it.
	settings.movement_speed = "instant"
	var ai_unit: Unit = _make_unit()
	ai_unit.team = "red"
	var ai_outcome = await ai_unit.move_along_path(path)
	check(
		ai_unit.tile_position == Vector2i(2, 0) and ai_outcome.path == instant_outcome.path,
		"AI-driven move resolves identically to the player's"
	)

	service.clear_consumers()
	# With no consumer the destination is the full path again — the seam is inert
	# until something registers, which is what makes it safe to land before fog.
	var plain: Unit = _make_unit()
	var plain_outcome = await plain.move_along_path(path)
	check(
		plain.tile_position == Vector2i(5, 0) and not plain_outcome.halted,
		"an unobserved move is unchanged by the resolver"
	)


# [PCM-7] clause 1: undo is refused once a trigger fired, and unaffected otherwise.
func _test_undo_guard() -> void:
	var turn: Node = load("res://scripts/core/TurnManager.gd").new()
	root.add_child(turn)
	await process_frame

	var unit: Unit = _make_unit()
	turn.record_move_start(unit)
	unit.snap_to_tile(Vector2i(3, 0))
	check(turn.can_undo_move(unit), "an ordinary move is undoable")
	turn.undo_move(unit)
	check(unit.tile_position == Vector2i(0, 0), "undo restores the pre-move tile")

	turn.record_move_start(unit)
	unit.snap_to_tile(Vector2i(2, 0))
	turn.mark_move_permanent(unit)
	check(not turn.can_undo_move(unit), "a fired crossing effect blocks undo")
	turn.undo_move(unit)
	check(
		unit.tile_position == Vector2i(2, 0),
		"undo_move is a no-op once the move is permanent",
		str(unit.tile_position)
	)

	# The flag must not leak into the unit's next move.
	turn.set_unit_state(unit, TurnManager.UnitState.DONE)
	turn.record_move_start(unit)
	check(turn.can_undo_move(unit), "permanence does not survive into the next move")
