class_name EffectStateView extends RefCounted
# adopter-todo: SHARED-EFFECT-RUNNER-WIRING-2026-08-31

const JournalScript = preload("res://scripts/actions/EffectMutationJournal.gd")

## Read-through overlay. Authorities are registered with read/write callables so
## prepare can remain ignorant of the live state's concrete owner.

var journal: RefCounted
var _authorities: Dictionary = {}
var _overlay: Dictionary = {}


func _init(existing_journal: RefCounted = null) -> void:
	journal = existing_journal if existing_journal != null else JournalScript.new()


func register_authority(authority_id: String, reader: Callable, writer: Callable) -> void:
	_authorities[authority_id] = {"read": reader, "write": writer}


func read(authority_id: String, save_field: String, ref: Variant = null) -> Variant:
	var key := _key(authority_id, save_field, ref)
	if _overlay.has(key):
		return _copy(_overlay[key])
	var authority: Dictionary = _authorities.get(authority_id, {})
	if authority.is_empty() or not (authority.read as Callable).is_valid():
		return null
	return _copy((authority.read as Callable).call(save_field, ref))


func write(
	step_id: String, authority_id: String, save_field: String, ref: Variant, after: Variant
) -> Dictionary:
	var before: Variant = read(authority_id, save_field, ref)
	var key := _key(authority_id, save_field, ref)
	_overlay[key] = _copy(after)
	return journal.append(step_id, authority_id, save_field, ref, before, after)


func revalidate() -> Dictionary:
	var checked: Dictionary = {}
	for entry in journal.entries:
		var key := _key(entry.authority_id, entry.save_field, entry.ref)
		if checked.has(key):
			continue
		checked[key] = true
		var authority: Dictionary = _authorities.get(entry.authority_id, {})
		if authority.is_empty() or not (authority.read as Callable).is_valid():
			return {"ok": false, "code": "missing_authority", "entry": entry}
		var live: Variant = (authority.read as Callable).call(entry.save_field, entry.ref)
		if live != entry.before:
			return {"ok": false, "code": "stale_precondition", "entry": entry, "live": live}
	return {"ok": true}


func commit() -> Dictionary:
	var check := revalidate()
	if not check.ok:
		return check
	for entry in journal.entries:
		var writer: Callable = _authorities[entry.authority_id].write
		writer.call(entry.save_field, entry.ref, _copy(entry.after))
	return {"ok": true}


func _key(authority_id: String, save_field: String, ref: Variant) -> String:
	return "%s\u001f%s\u001f%s" % [authority_id, save_field, ref_key(ref)]


# Object refs must key by identity, not by value. var_to_str() serialises an
# Object's exported properties, so two distinct units holding equal property
# values produced the SAME key — one overlay slot for two subjects, and a
# revalidate() that compared the wrong before-value. Found 2026-08-31 by the
# Session 7 combat migration, the first caller to write two subjects in one
# transaction. Non-object refs (tile coordinates, campaign keys) keep the
# value-identity var_to_str gives them, which is what those refs mean.
static func ref_key(ref: Variant) -> String:
	if ref is Object:
		return "obj:%d" % (ref as Object).get_instance_id()
	return var_to_str(ref)


static func _copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
