class_name CrossingResolver extends RefCounted
# The one mechanism that detects "a unit entered/crossed tile T mid-move" and
# runs whatever is registered against it ([PCM-1]). Fog ambush reveals ([FOW-4]),
# pass-through terrain triggers ([TER-7]), perception `on_cross` ([PER-8]) and
# traversing displacement ([PCM-4]) are all CONSUMERS of this resolver — none of
# them builds a second one.
#
# [PCM-3] forces the shape: resolution happens over the PATH AS DATA, before or
# independently of animation. Three constraints rule out hooking the tween —
# Unit.move_along_path commits `tile_position = path[-1]` before animating, the
# Instant speed setting skips the tween loop entirely, and AI/replay must
# resolve identically to an animated player move.
#
# Open-registry architecture (AGENTS.md): consumers register a probe Callable;
# nothing here knows what fog or terrain are, and adding a consumer needs no
# edit to this file.

const OutcomeScript = preload("res://scripts/core/CrossingOutcome.gd")

# Trigger declaration keys. A probe returns dictionaries shaped by these.
const KEY_ID := "id"
const KEY_INTERRUPT := "interrupt"
const KEY_ENDS_ACTIVATION := "ends_activation"
const KEY_EFFECT := "effect"

const INTERRUPT_HALT := "halt"
const INTERRUPT_CONTINUE := "continue"

# Registration order, kept separately from the dictionary so resolution order is
# deterministic (Dictionary preserves insertion order in Godot, but relying on
# that implicitly is what makes a replay diverge after an innocuous refactor).
var _order: Array[String] = []
var _probes: Dictionary = {}


# Registers a consumer's probe. `probe` is called once per crossed tile with a
# context Dictionary and returns the triggers that fire there — an Array of
# trigger dictionaries, a single dictionary, or null/[] for "nothing here".
#
# Context keys: unit, tile, step_index (1-based index into the requested path),
# path (the requested path), origin.
#
# Returns validation errors, [] on success, matching the registry convention
# used by ObjectiveConditionRegistry and friends.
func register_consumer(consumer_id: String, probe: Callable) -> Array[String]:
	if consumer_id.strip_edges().is_empty():
		return ["CrossingResolver: consumer id is empty"]
	if _probes.has(consumer_id):
		return ["CrossingResolver: duplicate consumer id '%s'" % consumer_id]
	if not probe.is_valid():
		return ["CrossingResolver: consumer '%s' has an invalid probe" % consumer_id]
	_probes[consumer_id] = probe
	_order.append(consumer_id)
	return []


func unregister_consumer(consumer_id: String) -> void:
	_probes.erase(consumer_id)
	_order.erase(consumer_id)


func clear_consumers() -> void:
	_probes.clear()
	_order.clear()


func has_consumer(consumer_id: String) -> bool:
	return _probes.has(consumer_id)


func consumer_ids() -> Array[String]:
	return _order.duplicate()


# Resolves `path` for `unit` and returns the movement that actually happens.
#
# The origin tile (path[0]) is NOT crossed — the unit is already standing on it,
# so a trigger there has already had its chance. Every subsequent tile is
# crossed in order, including the destination: entering the last tile is a
# crossing like any other, which is what makes a trap on the destination tile
# work without a special case.
func resolve(unit: Node, path: Array[Vector2i]) -> CrossingOutcome:
	if path.size() <= 1 or _order.is_empty():
		return OutcomeScript.pass_through(path)

	var outcome := OutcomeScript.new()
	outcome.path = [path[0]] as Array[Vector2i]
	var origin: Vector2i = path[0]

	for step_index in range(1, path.size()):
		var tile: Vector2i = path[step_index]
		outcome.path.append(tile)
		var context := {
			"unit": unit,
			"tile": tile,
			"step_index": step_index,
			"path": path,
			"origin": origin,
		}
		# Every consumer is asked about this tile even after one of them halts:
		# the unit did enter the tile, so co-located triggers all fired. Only
		# further MOVEMENT stops.
		var halt_here := false
		for consumer_id in _order:
			for trigger in _collect(consumer_id, context, outcome):
				if _fire(consumer_id, trigger, context, outcome):
					halt_here = true
		if halt_here:
			outcome.halted = true
			outcome.halt_tile = tile
			break

	return outcome


# Normalises whatever a probe returned into an Array of trigger dictionaries.
func _collect(consumer_id: String, context: Dictionary, outcome: CrossingOutcome) -> Array:
	var probe: Callable = _probes[consumer_id]
	# A probe bound to a freed object goes invalid without notice — a consumer
	# whose scene was unloaded without unregistering. Report it and carry on
	# rather than erroring once per crossed tile, per move, forever.
	if not probe.is_valid():
		outcome.errors.append(
			"CrossingResolver: consumer '%s' has a dead probe; unregister it" % consumer_id
		)
		return []
	var returned: Variant = probe.call(context)
	if returned == null:
		return []
	if returned is Dictionary:
		return [returned]
	if returned is Array:
		return returned
	outcome.errors.append(
		(
			"CrossingResolver: consumer '%s' returned %s, expected Dictionary/Array/null"
			% [consumer_id, type_string(typeof(returned))]
		)
	)
	return []


# Applies one trigger. Returns true when it halts the move.
func _fire(
	consumer_id: String, trigger: Variant, context: Dictionary, outcome: CrossingOutcome
) -> bool:
	if not (trigger is Dictionary):
		outcome.errors.append(
			"CrossingResolver: consumer '%s' returned a non-dictionary trigger" % consumer_id
		)
		return false
	var declaration: Dictionary = trigger
	var trigger_id := String(declaration.get(KEY_ID, ""))
	if trigger_id.strip_edges().is_empty():
		outcome.errors.append(
			"CrossingResolver: consumer '%s' returned a trigger with no id" % consumer_id
		)
		return false

	# [PCM-5]: halt is the DEFAULT, and an unrecognised value falls back to it
	# rather than to continue. A trigger that forgets to declare stops the unit
	# visibly instead of silently applying an effect the player never saw.
	var interrupt := String(declaration.get(KEY_INTERRUPT, INTERRUPT_HALT))
	if interrupt != INTERRUPT_HALT and interrupt != INTERRUPT_CONTINUE:
		outcome.errors.append(
			(
				"CrossingResolver: trigger '%s' has unknown interrupt '%s'; halting"
				% [trigger_id, interrupt]
			)
		)
		interrupt = INTERRUPT_HALT

	outcome.fired.append(trigger_id)
	# [PCM-7] clause 1: the move is permanent from the moment a trigger resolves.
	outcome.movement_permanent = true

	# [PCM-6]: a second, independent axis from the halt itself — an ambush reveal
	# and a disabling trap halt alike but differ here.
	if bool(declaration.get(KEY_ENDS_ACTIVATION, false)):
		outcome.ends_activation = true

	# [PCM-2]: the resolver owns the TRIGGER; the consequence still resolves in
	# whatever system owns it (a displacement still goes through
	# DisplacementService). The effect Callable is that hand-off, and it runs
	# here — at resolution time, not at animation time.
	var effect: Variant = declaration.get(KEY_EFFECT, null)
	if effect != null:
		if effect is Callable and (effect as Callable).is_valid():
			(effect as Callable).call(context)
		else:
			outcome.errors.append(
				"CrossingResolver: trigger '%s' has a non-callable effect" % trigger_id
			)

	return interrupt == INTERRUPT_HALT
