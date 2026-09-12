class_name RecordSelector extends RefCounted
# `[TSV-10]`/`[TSV-24]`/`[EPUX-04]`'s shared selector, and `[CEUI-S15]`'s ruling that the
# campaign editor's reference picker IS this selector rather than a sixth private one.
#
# WHAT IT OWNS, verbatim from `[TSV-10]`'s ruling B: stable identity, focus, the selected
# set, eligibility together with its reason, quantity, filters/sort, and the detail
# payload. WHAT IT DOES NOT OWN: business rules. Services decide what is eligible and why;
# this presents their answer. Option C -- a selector that owned the rules -- was rejected
# because it becomes a monolithic shop/convoy/forge switch, which is the closed-enum smell
# the open-registry principle exists to prevent. So there is no domain vocabulary anywhere
# in this file: no item, no unit, no pack, no reference kind. Records arrive as an opaque
# stable id plus a payload the caller understands and this class never inspects.
#
# WHY IT IS A MODEL AND NOT A CONTROL. Every rule the three rulings actually make is about
# STATE -- what is focusable, what survives recomposition, what activation does when an
# entry is gated. A Control cannot be asserted headlessly and would drag one screen's
# layout into a primitive five surfaces share. `ResponsiveLayout` set the precedent: ship
# the seam, convert screens one at a time.
#
# GATING IS THE SHELL'S, NOT THE ADAPTER'S (`[EPUX-04]`). An adapter supplies only the
# predicate result and its player-facing unmet reason; this class decides hidden-versus-
# disabled and keeps disabled entries in the focus order. That is the whole reason the
# ruling promoted gating into the shell: four adapters cannot drift into four different
# disabled treatments when the decision is made once, here.
#
# `[EPUX-07]`/`[RPD-15]`: a gated entry is FOCUSABLE BUT NOT ACTIVATABLE. Both halves are
# load-bearing and they pull in opposite directions, which is why `activate()` returns a
# refusal carrying the reason rather than simply doing nothing -- the reason has to be
# reachable by someone standing on the entry, and a silent no-op is how it stops being.
#
# `[TSV-24]`: subject, filters/sort, focused instance and meaningful focus survive
# responsive recomposition and a change of input mode. Rotating a phone mid-purchase must
# cost the player nothing, and the mobile-web controller makes that routine rather than
# rare. `capture_state()`/`restore_state()` are keyed by STABLE ID for exactly that reason
# -- an index survives nothing, because recomposition is usually accompanied by a filter
# or availability change that moves every row.

## How a gated entry presents. Ruled per entry by the author (`EPUX-02`), defaulting to
## visible-disabled: a player who cannot see that a thing exists cannot learn what to do
## about it, so hiding is the opt-in.
const GATE_VISIBLE_DISABLED := "visible_disabled_with_reason"
const GATE_HIDDEN_UNTIL_MET := "hidden_until_met"

## Why `activate()` refused. `REFUSED_UNAVAILABLE` always carries the adapter's reason.
const ACTIVATED := "activated"
const REFUSED_UNAVAILABLE := "refused_unavailable"
const REFUSED_UNKNOWN := "refused_unknown"

## Emitted when the focused record changes, including when focus moves because the record
## it was on disappeared. Never emitted for a rebuild that lands on the same id -- a
## screen that rebuilds on every publish is the state-loss bug `ResponsiveLayout` was
## careful to avoid, and this is the same contract one level down.
signal focus_changed(new_id: String, previous_id: String)
signal selection_changed
signal records_changed

## Multi-select is off by default: most surfaces select one thing, and a selector that
## silently allowed a growing set would make `selected_ids()` mean something different
## per caller.
var allow_multi_select: bool = false

## Supplies availability for one record: `func(id: String, payload: Variant) -> Dictionary`
## returning `{available: bool, reason: String, gate: String}`. `reason` is the adapter's
## player-facing string and is REQUIRED when unavailable -- `_availability_for` refuses to
## invent one, because a gate with an invented reason reads exactly like a gate with a
## real one.
var availability_provider: Callable = Callable()

## Supplies the detail payload for one record: `func(id, payload) -> Variant`. Absent, the
## record's own payload is the detail.
var detail_provider: Callable = Callable()

## `func(id, payload) -> bool`. Filtered-out records are gone, not disabled: a filter is
## the player narrowing what they are looking at, which is a different act from the engine
## refusing them something.
var filter: Callable = Callable()

## `func(a: Dictionary, b: Dictionary) -> bool` over `{id, payload}`. Absent, the order the
## caller supplied is kept -- deliberately, so a caller with a meaningful authored order
## does not have to invent a comparator to preserve it.
var sort_comparator: Callable = Callable()

var _records: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _visible: Array[String] = []
var _focused_id: String = ""
var _selected: Dictionary = {}
var _quantities: Dictionary = {}


## Records are `{id: String, payload: Variant}`. Ids must be stable across rebuilds and
## opaque to this class; a duplicate id is dropped rather than silently shadowing, because
## two rows answering to one id makes focus restoration ambiguous forever after.
func set_records(records: Array) -> Array[String]:
	var errors: Array[String] = []
	_records.clear()
	_by_id.clear()
	for record in records:
		if not (record is Dictionary) or not (record as Dictionary).has("id"):
			errors.append("RecordSelector: a record needs an 'id'")
			continue
		var id := String((record as Dictionary)["id"])
		if id == "":
			errors.append("RecordSelector: a record id is empty")
			continue
		if _by_id.has(id):
			errors.append("RecordSelector: duplicate record id '%s'" % id)
			continue
		var entry := {"id": id, "payload": (record as Dictionary).get("payload")}
		_by_id[id] = entry
		_records.append(entry)
	_rebuild()
	return errors


## Re-applies filter, sort and availability, then repairs focus and selection against what
## survived. Call it after changing a filter, a comparator, or anything a provider reads.
func refresh() -> void:
	_rebuild()


## The rows a surface draws, in order, each carrying everything needed to draw it:
## `{id, payload, available, reason, gate, focused, selected, quantity, detail}`.
func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _visible:
		out.append(row(id))
	return out


func row(id: String) -> Dictionary:
	if not _by_id.has(id):
		return {}
	var entry: Dictionary = _by_id[id]
	var availability := _availability_for(id)
	return {
		"id": id,
		"payload": entry["payload"],
		"available": bool(availability["available"]),
		"reason": String(availability["reason"]),
		"gate": String(availability["gate"]),
		"focused": id == _focused_id,
		"selected": _selected.has(id),
		"quantity": int(_quantities.get(id, 1)),
		"detail": detail_for(id),
	}


func ids() -> Array[String]:
	return _visible.duplicate()


func has(id: String) -> bool:
	return _by_id.has(id)


func size() -> int:
	return _visible.size()


func detail_for(id: String) -> Variant:
	if not _by_id.has(id):
		return null
	var entry: Dictionary = _by_id[id]
	if detail_provider.is_valid():
		return detail_provider.call(id, entry["payload"])
	return entry["payload"]


# ---- focus ----


func focused_id() -> String:
	return _focused_id


## Moves focus THROUGH unavailable entries rather than around them -- `[EPUX-07]`'s
## focusable half. Skipping them is how a reason becomes unreachable to the keyboard and
## screen-reader user it was written for.
func focus_next() -> String:
	return _focus_step(1)


func focus_previous() -> String:
	return _focus_step(-1)


func focus(id: String) -> bool:
	if not (id in _visible):
		return false
	_set_focus(id)
	return true


# ---- selection ----


## Selecting is not activating. A disabled row can be focused; whether it can be SELECTED
## is the same question as whether it can be activated, so it cannot.
func select(id: String) -> bool:
	if not (id in _visible) or not is_available(id):
		return false
	if not allow_multi_select:
		_selected.clear()
	_selected[id] = true
	selection_changed.emit()
	return true


func deselect(id: String) -> bool:
	if not _selected.has(id):
		return false
	_selected.erase(id)
	selection_changed.emit()
	return true


func toggle(id: String) -> bool:
	if _selected.has(id):
		return deselect(id)
	return select(id)


func clear_selection() -> void:
	if _selected.is_empty():
		return
	_selected.clear()
	selection_changed.emit()


func selected_ids() -> Array[String]:
	var out: Array[String] = []
	for id in _visible:
		if _selected.has(id):
			out.append(id)
	return out


func is_selected(id: String) -> bool:
	return _selected.has(id)


# ---- eligibility ----


func is_available(id: String) -> bool:
	return bool(_availability_for(id)["available"])


func unmet_reason(id: String) -> String:
	return String(_availability_for(id)["reason"])


## `{outcome, id, reason}`. An unavailable entry refuses AND RETURNS ITS REASON: that is
## the whole of "focusable but not activatable", and a silent no-op would satisfy the
## second half while quietly failing the first.
func activate(id: String) -> Dictionary:
	if not _by_id.has(id):
		return {"outcome": REFUSED_UNKNOWN, "id": id, "reason": ""}
	var availability := _availability_for(id)
	if not bool(availability["available"]):
		return {"outcome": REFUSED_UNAVAILABLE, "id": id, "reason": String(availability["reason"])}
	return {"outcome": ACTIVATED, "id": id, "reason": ""}


# ---- quantity ----


## The transaction register ruled a quantity to be N repetitions of one atomic operation,
## never one bulk one (TSV-12).
## This holds the number; it does not know what an operation is.
func set_quantity(id: String, quantity: int) -> bool:
	if not _by_id.has(id) or quantity < 1:
		return false
	_quantities[id] = quantity
	return true


func quantity(id: String) -> int:
	return int(_quantities.get(id, 1))


# ---- [TSV-24] state across recomposition ----


## Everything the ruling says survives rotation and an input-mode change. Keyed by stable
## id throughout; nothing here is an index.
func capture_state() -> Dictionary:
	return {
		"focused_id": _focused_id,
		"selected_ids": selected_ids(),
		"quantities": _quantities.duplicate(true),
	}


## Restores what still exists and drops what does not, silently -- a restore that failed
## loudly because one row was filtered away would make rotation feel like an error.
## Focus falls back to the first visible row, so the surface is never left focusless.
func restore_state(state: Dictionary) -> void:
	_selected.clear()
	for id in state.get("selected_ids", []):
		if _by_id.has(String(id)) and is_available(String(id)):
			_selected[String(id)] = true
	_quantities.clear()
	for id in (state.get("quantities", {}) as Dictionary).keys():
		if _by_id.has(String(id)):
			_quantities[String(id)] = int((state["quantities"] as Dictionary)[id])
	var wanted := String(state.get("focused_id", ""))
	if wanted != "" and wanted in _visible:
		_set_focus(wanted)
	else:
		_set_focus(_visible[0] if not _visible.is_empty() else "")
	selection_changed.emit()


# ---- internals ----


func _rebuild() -> void:
	var previous_focus := _focused_id
	var entries: Array[Dictionary] = []
	for entry in _records:
		if filter.is_valid() and not bool(filter.call(entry["id"], entry["payload"])):
			continue
		var availability := _availability_for(String(entry["id"]))
		if (
			not bool(availability["available"])
			and String(availability["gate"]) == GATE_HIDDEN_UNTIL_MET
		):
			continue
		entries.append(entry)
	if sort_comparator.is_valid():
		entries.sort_custom(sort_comparator)
	_visible.clear()
	for entry in entries:
		_visible.append(String(entry["id"]))

	for id in _selected.keys().duplicate():
		if not (String(id) in _visible) or not is_available(String(id)):
			_selected.erase(id)
	if previous_focus in _visible:
		_focused_id = previous_focus
	else:
		_set_focus(_visible[0] if not _visible.is_empty() else "")
	records_changed.emit()


func _set_focus(id: String) -> void:
	if id == _focused_id:
		return
	var previous := _focused_id
	_focused_id = id
	focus_changed.emit(id, previous)


func _focus_step(direction: int) -> String:
	if _visible.is_empty():
		return ""
	var index := _visible.find(_focused_id)
	if index < 0:
		_set_focus(_visible[0])
		return _focused_id
	var next := index + direction
	if next < 0 or next >= _visible.size():
		return _focused_id
	_set_focus(_visible[next])
	return _focused_id


## An absent provider means everything is available -- the selector does not invent gates
## either. A provider that reports unavailable WITHOUT a reason is the one case answered
## with a placeholder, because `[EPUX-07]`'s contract is that a reason is always reachable
## and a blank tooltip is indistinguishable from a bug at the point it is read.
func _availability_for(id: String) -> Dictionary:
	if not _by_id.has(id):
		return {"available": false, "reason": "", "gate": GATE_VISIBLE_DISABLED}
	if not availability_provider.is_valid():
		return {"available": true, "reason": "", "gate": GATE_VISIBLE_DISABLED}
	var entry: Dictionary = _by_id[id]
	var answer: Variant = availability_provider.call(id, entry["payload"])
	if not (answer is Dictionary):
		return {"available": true, "reason": "", "gate": GATE_VISIBLE_DISABLED}
	var available := bool((answer as Dictionary).get("available", true))
	var reason := String((answer as Dictionary).get("reason", ""))
	if not available and reason == "":
		reason = "Unavailable"
	return {
		"available": available,
		"reason": "" if available else reason,
		"gate": String((answer as Dictionary).get("gate", GATE_VISIBLE_DISABLED)),
	}
