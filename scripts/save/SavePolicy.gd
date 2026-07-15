extends RefCounted
# Pure campaign-authored save policy validation and selection.

const BETWEEN_MAP := "between_map"
const MID_MAP := "mid_map"
const ANY := "any"
const ACCEPTS: Array[String] = [BETWEEN_MAP, MID_MAP, ANY]


static func classic_gba() -> Array[Dictionary]:
	return [
		{"count": 3, "accepts": BETWEEN_MAP, "consumed_on_load": false, "label": "Campaign Save"},
		{"count": 1, "accepts": MID_MAP, "consumed_on_load": true, "label": "Suspend"},
	]


static func single_consumable() -> Array[Dictionary]:
	return [{"count": 1, "accepts": ANY, "consumed_on_load": true, "label": "Save"}]


static func thirty_interchangeable() -> Array[Dictionary]:
	return [{"count": 30, "accepts": ANY, "consumed_on_load": false, "label": "Save"}]


static func default_autosave_rules() -> Array[Dictionary]:
	return [
		{
			"rule_id": "campaign_progress",
			"trigger": "battle_end",
			"keep": 1,
			"label": "Campaign Autosave",
			"consumed_on_load": false,
		}
	]


static func normalize_slot_classes(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for raw in value:
		if not (raw is Dictionary):
			continue
		(
			out
			. append(
				{
					"count": int(raw.get("count", 0)),
					"accepts": String(raw.get("accepts", "")),
					"consumed_on_load": bool(raw.get("consumed_on_load", false)),
					"label": String(raw.get("label", "")),
				}
			)
		)
	return out


static func normalize_autosave_rules(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for raw in value:
		if not (raw is Dictionary):
			continue
		(
			out
			. append(
				{
					"rule_id": String(raw.get("rule_id", "")),
					"trigger": String(raw.get("trigger", "")),
					"keep": int(raw.get("keep", 0)),
					"label": String(raw.get("label", "")),
					"consumed_on_load": bool(raw.get("consumed_on_load", false)),
				}
			)
		)
	return out


static func validate(
	slot_classes: Variant, autosave_rules: Variant, rewind_charges_per_map: int
) -> Array[String]:
	var errors: Array[String] = []
	var classes := normalize_slot_classes(slot_classes)
	if classes.is_empty():
		errors.append("SavePolicy: save_slot_classes must contain at least one class")
	for i in classes.size():
		var entry := classes[i]
		if int(entry["count"]) < 0:
			errors.append("SavePolicy: class %d count must be >= 0" % i)
		if String(entry["accepts"]) not in ACCEPTS:
			errors.append("SavePolicy: class %d has unknown accepts '%s'" % [i, entry["accepts"]])
		if String(entry["label"]).is_empty():
			errors.append("SavePolicy: class %d label must not be empty" % i)
	var seen_rules := {}
	var normalized_autos := normalize_autosave_rules(autosave_rules)
	for i in normalized_autos.size():
		var rule := normalized_autos[i]
		var rule_id := String(rule["rule_id"])
		if rule_id.is_empty() or not _is_safe_id(rule_id):
			errors.append("SavePolicy: autosave rule %d has invalid rule_id" % i)
		elif seen_rules.has(rule_id):
			errors.append("SavePolicy: duplicate autosave rule_id '%s'" % rule_id)
		seen_rules[rule_id] = true
		if String(rule["trigger"]).is_empty():
			errors.append("SavePolicy: autosave rule '%s' has empty trigger" % rule_id)
		if int(rule["keep"]) < 0:
			errors.append("SavePolicy: autosave rule '%s' keep must be >= 0" % rule_id)
		if bool(rule["consumed_on_load"]):
			errors.append(
				"SavePolicy: autosave rule '%s' must set consumed_on_load false" % rule_id
			)
	# Non-blocking builder warning is returned separately, not a validation error.
	return errors


static func builder_warnings(slot_classes: Variant, rewind_charges_per_map: int) -> Array[String]:
	var warnings: Array[String] = []
	if rewind_charges_per_map < 0:
		return warnings
	for entry in normalize_slot_classes(slot_classes):
		if (
			int(entry["count"]) > 0
			and not bool(entry["consumed_on_load"])
			and String(entry["accepts"]) in [MID_MAP, ANY]
		):
			(
				warnings
				. append(
					(
						"SavePolicy: durable mid_map saves require infinite rewind "
						+ "(rewind_charges_per_map = -1) to avoid bypassing a finite decision-undo budget"
					)
				)
			)
			break
	return warnings


static func class_for_kind(slot_classes: Variant, save_kind: String) -> Dictionary:
	for entry in normalize_slot_classes(slot_classes):
		if int(entry["count"]) > 0 and String(entry["accepts"]) in [save_kind, ANY]:
			return entry
	return {}


static func is_consumed_on_load(slot_classes: Variant, save_kind: String) -> bool:
	var entry := class_for_kind(slot_classes, save_kind)
	return not entry.is_empty() and bool(entry["consumed_on_load"])


static func _is_safe_id(value: String) -> bool:
	if value.is_empty() or value.length() > 48:
		return false
	for character in value:
		if not "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-".contains(
			character
		):
			return false
	return true
