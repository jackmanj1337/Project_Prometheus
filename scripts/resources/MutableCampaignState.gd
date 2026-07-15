class_name MutableCampaignState extends Resource
# One open, data-shaped store for permanent campaign mutations and portable
# carry-forward facts. Rule ids and fact ids are authored strings, not fields.

@export var rule_patches: Array[Dictionary] = []
@export var carry_forward_facts: Dictionary = {}
@export var imported_record_ref: Dictionary = {}


func append_rule_patch(rule_id: String, value: Variant, reason: String,
		source: String = "runtime") -> bool:
	if rule_id == "":
		return false
	rule_patches.append({
		"rule_id": rule_id,
		"value": value,
		"reason": reason,
		"source": source,
	})
	return true


func patched_value(rule_id: String, fallback: Variant = null) -> Variant:
	for index in range(rule_patches.size() - 1, -1, -1):
		var patch: Dictionary = rule_patches[index]
		if String(patch.get("rule_id", "")) == rule_id:
			return patch.get("value", fallback)
	return fallback


func has_patch(rule_id: String) -> bool:
	for patch in rule_patches:
		if String(patch.get("rule_id", "")) == rule_id:
			return true
	return false


func to_dict() -> Dictionary:
	return {
		"rule_patches": rule_patches.duplicate(true),
		"carry_forward_facts": carry_forward_facts.duplicate(true),
		"imported_record_ref": imported_record_ref.duplicate(true),
	}


func apply_dict(source: Variant) -> bool:
	if not (source is Dictionary):
		return false
	var raw_patches: Variant = source.get("rule_patches", [])
	var raw_facts: Variant = source.get("carry_forward_facts", {})
	var raw_ref: Variant = source.get("imported_record_ref", {})
	if not (raw_patches is Array) or not (raw_facts is Dictionary) \
			or not (raw_ref is Dictionary):
		return false
	var patches: Array[Dictionary] = []
	for raw_patch in raw_patches:
		if not (raw_patch is Dictionary) \
				or String(raw_patch.get("rule_id", "")) == "":
			return false
		patches.append({
			"rule_id": String(raw_patch.get("rule_id", "")),
			"value": raw_patch.get("value", null),
			"reason": String(raw_patch.get("reason", "")),
			"source": String(raw_patch.get("source", "runtime")),
		})
	for key in raw_facts:
		if not (key is String) or String(key) == "":
			return false
	rule_patches = patches
	carry_forward_facts = raw_facts.duplicate(true)
	imported_record_ref = raw_ref.duplicate(true)
	return true
