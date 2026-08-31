class_name UnitStateSink extends RefCounted

## Prepares durable UnitData mutations into an EffectStateView journal.
##
## Every source that changes a unit's saved state — combat exchanges, item
## effects, triggered skills, and (next) conditions and world events — used to
## own a private copy of "read the field, compute the new value, write it back",
## and each copy wrote LIVE state the moment it ran. That is what made a fight a
## half-committed transaction: skill counters had already moved when the HP
## commit ran, and an abandoned forecast had to be undone by hand with a
## snapshot/restore pair.
##
## This is the one shared primitive for that step. Nothing here touches live
## state; it records before/after evidence in the journal and the owning
## transaction commits it in one place. Presentation is recorded alongside the
## write and replayed at commit, so nothing paints a change that has not landed.
##
## Refs are unit instance ids rather than the nodes themselves: the journal is
## evidence that outlives the nodes it describes, and an id stays comparable
## after a unit is freed. resolve() maps an id back to its node for the writer.

const AUTHORITY := "unit_state"

var state_view: RefCounted
var presentation: Array[Dictionary] = []

var _units: Dictionary = {}  # instance id -> Node


func _init(view: RefCounted = null) -> void:
	state_view = view if view != null else load("res://scripts/actions/EffectStateView.gd").new()
	state_view.register_authority(AUTHORITY, Callable(self, "read_field"), Callable(self, "_write"))


# ---- Registration / raw field access ----


func track(unit: Node) -> int:
	var id: int = unit.get_instance_id()
	_units[id] = unit
	return id


func resolve(ref: Variant) -> Node:
	var unit: Variant = _units.get(int(ref))
	return unit if unit is Node and is_instance_valid(unit) else null


func read_field(save_field: String, ref: Variant) -> Variant:
	var unit := resolve(ref)
	if unit == null or unit.data == null:
		return null
	return unit.data.get(save_field)


# Pending (prepared, uncommitted) value of a field for a unit.
func read(unit: Node, save_field: String) -> Variant:
	return state_view.read(AUTHORITY, save_field, track(unit))


func write(step_id: String, unit: Node, save_field: String, value: Variant) -> Dictionary:
	return state_view.write(step_id, AUTHORITY, save_field, track(unit), value)


func _write(save_field: String, ref: Variant, value: Variant) -> void:
	var unit := resolve(ref)
	if unit == null or unit.data == null:
		return
	unit.data.set(save_field, value)


# ---- Domain-shaped preparations ----


# Prepares HP loss. Returns HP actually lost, which is not the same as `amount`
# on an overkill blow — callers that tally damage taken need the clamped figure.
func damage(step_id: String, unit: Node, amount: int) -> int:
	if unit == null or unit.data == null or amount <= 0:
		return 0
	var before: int = int(read(unit, "hp"))
	var after: int = maxi(0, before - amount)
	if after == before:
		return 0
	write(step_id, unit, "hp", after)
	presentation.append({"kind": "unit_damaged", "unit": unit, "amount": before - after})
	return before - after


func heal(step_id: String, unit: Node, amount: int) -> int:
	if unit == null or unit.data == null or amount <= 0:
		return 0
	var before: int = int(read(unit, "hp"))
	var after: int = mini(int(unit.data.max_hp), before + amount)
	if after == before:
		return 0
	write(step_id, unit, "hp", after)
	presentation.append({"kind": "unit_healed", "unit": unit, "amount": after - before})
	return after - before


func add_damage_taken(step_id: String, unit: Node, amount: int) -> void:
	if unit == null or unit.data == null or amount <= 0:
		return
	write(step_id, unit, "damage_taken_this_map", int(read(unit, "damage_taken_this_map")) + amount)


# Mirrors Unit.add_modifier(): one modifier per source, replacing any earlier
# modifier from that source, so a caller cannot silently stack itself.
func add_modifier(
	step_id: String,
	unit: Node,
	stat: String,
	delta: int,
	source: String,
	duration: int,
	duration_type: String
) -> void:
	if unit == null or unit.data == null:
		return
	var modifiers: Array = (read(unit, "active_modifiers") as Array).filter(
		func(m): return String(m.get("source", "")) != source
	)
	(
		modifiers
		. append(
			{
				"stat": stat,
				"delta": delta,
				"source": source,
				"duration": duration,
				"duration_type": duration_type,
			}
		)
	)
	write(step_id, unit, "active_modifiers", modifiers)


func bump_counter(step_id: String, unit: Node, save_field: String, key: String) -> void:
	if unit == null or unit.data == null:
		return
	var counters: Dictionary = read(unit, save_field)
	counters[key] = int(counters.get(key, 0)) + 1
	write(step_id, unit, save_field, counters)


# ---- Presentation ----


# Replayed by the owning transaction AFTER the journal lands, so a bar or a
# signal can never announce a change the commit went on to reject.
func flush_presentation(bus: Node) -> void:
	for event in presentation:
		var unit: Node = event["unit"]
		if unit == null or not is_instance_valid(unit):
			continue
		if unit.has_method("refresh_hp_display"):
			unit.refresh_hp_display()
		if bus == null:
			continue
		match String(event["kind"]):
			"unit_damaged":
				bus.unit_damaged.emit(unit, int(event["amount"]))
			"unit_healed":
				bus.unit_healed.emit(unit, int(event["amount"]))
	presentation.clear()
