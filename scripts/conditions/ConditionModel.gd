class_name ConditionModel extends RefCounted

## Pure rules for the durable `UnitData.conditions` array.
##
## Nothing here reads live state, writes live state, or knows what a transaction
## is. It answers three questions the condition system asks over and over —
## "what does this array actually mean", "what does it become when a definition
## is applied to it", and "what does it contribute to a stat" — so that the
## system, the sink, the projection and the save normaliser all get the same
## answer from one place instead of four.
##
## THE STORED SHAPE is the one UnitData already declared and SaveCodec already
## round-trips: an Array[Dictionary] of {"type", "turns_remaining"}. `stacks` is
## the only key this build adds, it defaults to 1, and normalize() supplies it
## for every entry saved before it existed — which is why there is no save
## migration here and no schema version bump. A pre-existing save loads, is
## normalised on read, and means exactly what it meant.
##
## DURATION. `turns_remaining` counts subscribed tick firings, not game turns:
## a condition that subscribes to two sources is decremented by whichever fires.
## -1 means indefinite and is never decremented.

const INDEFINITE := -1

## Stacking rules an authored definition may choose from. The engine owns the
## rule SET; the definition owns which one it uses (owner ruling 1, 2026-09-01).
const STACK_REFRESH := "refresh_duration"
const STACK_ADD_INSTANCE := "add_instance"
const STACK_TAKE_MAX := "take_max"
const STACKING_RULES: Array[String] = [STACK_REFRESH, STACK_ADD_INSTANCE, STACK_TAKE_MAX]


static func normalize_entry(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var id := String((raw as Dictionary).get("type", ""))
	if id.strip_edges() == "":
		return {}
	var stacks: int = int((raw as Dictionary).get("stacks", 1))
	return {
		"type": id,
		"turns_remaining": int((raw as Dictionary).get("turns_remaining", INDEFINITE)),
		"stacks": maxi(1, stacks),
	}


## Drops entries with no id and fills in defaults. Every read of the durable
## array goes through this, so an entry written by an older build, by hand, or
## by a pack that omitted an optional key can never reach the rules half-formed.
static func normalize(conditions: Variant) -> Array:
	var result: Array = []
	if not conditions is Array:
		return result
	for raw in conditions as Array:
		var entry := normalize_entry(raw)
		if not entry.is_empty():
			result.append(entry)
	return result


static func index_of(conditions: Array, condition_id: String) -> int:
	for index in conditions.size():
		if String((conditions[index] as Dictionary).get("type", "")) == condition_id:
			return index
	return -1


static func has(conditions: Variant, condition_id: String) -> bool:
	return index_of(normalize(conditions), condition_id) >= 0


## Applies `definition` to a copy of `conditions` and returns the new array.
## Returns the array unchanged when the definition's own stacking rule says the
## application adds nothing — a `take_max` re-application at a shorter duration,
## for instance, which is a real outcome and not a failure.
static func applied(conditions: Variant, definition: Resource, duration: int) -> Array:
	var result := normalize(conditions)
	if definition == null:
		return result
	var id := String(definition.id)
	var index := index_of(result, id)
	if index < 0:
		result.append({"type": id, "turns_remaining": duration, "stacks": 1})
		return result
	var existing: Dictionary = result[index]
	match String(definition.stacking):
		STACK_ADD_INSTANCE:
			var cap: int = int(definition.max_stacks)
			var stacks: int = int(existing["stacks"]) + 1
			existing["stacks"] = stacks if cap <= 0 else mini(cap, stacks)
			existing["turns_remaining"] = duration
		STACK_TAKE_MAX:
			existing["turns_remaining"] = _longer(int(existing["turns_remaining"]), duration)
		_:
			existing["turns_remaining"] = duration
	result[index] = existing
	return result


static func removed(conditions: Variant, condition_id: String) -> Array:
	var result := normalize(conditions)
	var index := index_of(result, condition_id)
	if index >= 0:
		result.remove_at(index)
	return result


## Decrements every entry subscribed to `source` by one firing and reports what
## the array becomes plus which ids expired on this firing. Expiry is REPORTED,
## not acted on: the consequence of expiring is a shared composition the caller
## prepares into the same transaction, which is the whole point of one tick being
## one transaction rather than a decrement here and a cleanup somewhere else.
static func ticked(conditions: Variant, definitions: Dictionary, source: String) -> Dictionary:
	var remaining: Array = []
	var expired: Array[String] = []
	var ticked_ids: Array[String] = []
	for entry in normalize(conditions):
		var id := String(entry["type"])
		var definition: Resource = definitions.get(id)
		if definition == null or not subscribes(definition, source):
			remaining.append(entry)
			continue
		ticked_ids.append(id)
		var turns: int = int(entry["turns_remaining"])
		if turns == INDEFINITE:
			remaining.append(entry)
			continue
		turns -= 1
		if turns <= 0:
			expired.append(id)
			continue
		entry["turns_remaining"] = turns
		remaining.append(entry)
	return {"conditions": remaining, "expired": expired, "ticked": ticked_ids}


static func subscribes(definition: Resource, source: String) -> bool:
	return definition != null and definition.tick_sources.has(source)


## Every stat delta the held conditions contribute, in the shape
## get_effective_stat() already understands. A definition's stat_modifiers apply
## once PER STACK, which is what makes `add_instance` mean anything numerically.
##
## The source string is per condition and per stat for the same reason the pair-up
## bonuses are: anything that keys modifiers by source collapses them otherwise.
static func stat_modifiers(conditions: Variant, definitions: Dictionary) -> Array:
	var modifiers: Array = []
	for entry in normalize(conditions):
		var id := String(entry["type"])
		var definition: Resource = definitions.get(id)
		if definition == null:
			continue
		var stacks: int = int(entry["stacks"])
		for raw in definition.stat_modifiers:
			var stat := String((raw as Dictionary).get("stat", ""))
			var delta: int = int((raw as Dictionary).get("delta", 0))
			if stat == "" or delta == 0:
				continue
			(
				modifiers
				. append(
					{
						"stat": stat,
						"delta": delta * stacks,
						"source": "condition:%s:%s" % [id, stat],
						"duration": INDEFINITE,
						"duration_type": "condition",
					}
				)
			)
	return modifiers


## Conditions kept when `event` happens. Both events clear by default and both
## honour the same authored opt-out, because "poison survives the map" and
## "poison survives death" are one authoring decision, not two (owner ruling 5).
static func retained_after(conditions: Variant, definitions: Dictionary, event: String) -> Array:
	var result: Array = []
	for entry in normalize(conditions):
		var definition: Resource = definitions.get(String(entry["type"]))
		if definition != null and _survives(definition, event):
			result.append(entry)
	return result


static func _survives(definition: Resource, event: String) -> bool:
	match event:
		"map_end":
			return bool(definition.persists_across_maps)
		"death":
			return bool(definition.persists_across_maps) and bool(definition.persists_through_death)
	return false


static func _longer(a: int, b: int) -> int:
	if a == INDEFINITE or b == INDEFINITE:
		return INDEFINITE
	return maxi(a, b)
