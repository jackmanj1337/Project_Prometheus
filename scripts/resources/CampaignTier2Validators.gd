class_name CampaignTier2Validators extends RefCounted
# Concrete validators for the smallest self-contained campaign pack. The kind
# table remains open: later content families can extend/replace these Callables.

const CampaignDataScript = preload("res://scripts/resources/CampaignData.gd")


static func registry() -> Dictionary:
	return {
		"campaign": Callable(CampaignTier2Validators, "_validate_campaign"),
		"map_registry": Callable(CampaignTier2Validators, "_validate_map_registry"),
		"map_data": Callable(CampaignTier2Validators, "_validate_map_data"),
		"roster": Callable(CampaignTier2Validators, "_validate_roster"),
		"class": Callable(CampaignTier2Validators, "_validate_class"),
	}


# Cross-document checks run only after every document passed its own parser.
static func collect_cross_reference_errors(catalogue: Tier2Catalogue) -> Array[String]:
	var errors: Array[String] = []
	var ids_by_kind := {}
	for entry in catalogue.entries:
		var indexed_document: Variant = catalogue.get_document(entry["kind"], entry["id"])
		if indexed_document != null:
			ids_by_kind.get_or_add(entry["kind"], {})[entry["id"]] = true
			# Campaign nodes bind to map entry ids, not to the containing registry
			# document's catalogue identity.
			if entry["kind"] == "map_registry":
				for map_entry in indexed_document:
					ids_by_kind["map_registry"][String(map_entry.get("id", ""))] = true

	for entry in catalogue.entries:
		var document: Variant = catalogue.get_document(entry["kind"], entry["id"])
		if document == null:
			continue
		match entry["kind"]:
			"campaign":
				for node in document["nodes"]:
					_require_id("map_registry", String(node.get("map_id", "")),
						"campaign '%s' node '%s' map_id" % [entry["id"], node.get("node_id", "")],
						ids_by_kind, errors)
			"map_registry":
				for map_entry in document:
					_require_id("map_data", String(map_entry.get("map_data_id", "")),
						"map registry '%s' entry '%s' map_data_id" % [entry["id"], map_entry.get("id", "")],
						ids_by_kind, errors)
					_require_id("roster", String(map_entry.get("roster_id", "")),
						"map registry '%s' entry '%s' roster_id" % [entry["id"], map_entry.get("id", "")],
						ids_by_kind, errors)
			"roster":
				for unit in document.get("units", []):
					_require_id("class", String(unit.get("class_id", "")),
						"roster '%s' unit '%s' class_id" % [entry["id"], unit.get("unit_id", "")],
						ids_by_kind, errors)
	return errors


static func _validate_campaign(document: Variant, entry: Dictionary,
		errors: Array[String]) -> void:
	var before := errors.size()
	var campaign = CampaignDataScript.parse(document, entry["path"], errors)
	if campaign != null and campaign.campaign_id != entry["id"]:
		errors.append("CampaignTier2Validators: campaign id '%s' does not match catalogue id '%s'" % [
			campaign.campaign_id, entry["id"]])
	if errors.size() > before:
		return


static func _validate_map_registry(document: Variant, entry: Dictionary,
		errors: Array[String]) -> void:
	if not document is Array or document.is_empty():
		errors.append("CampaignTier2Validators: map registry '%s' must be a non-empty array" % entry["id"])
		return
	var seen := {}
	for index in document.size():
		var row: Variant = document[index]
		if not row is Dictionary:
			errors.append("CampaignTier2Validators: map registry '%s' entry %d must be an object" % [entry["id"], index])
			continue
		for field in ["id", "label", "map_data_id", "roster_id"]:
			_require_string(row, field, "map registry '%s' entry %d" % [entry["id"], index], errors)
		var map_id := String(row.get("id", ""))
		if seen.has(map_id):
			errors.append("CampaignTier2Validators: map registry '%s' duplicates id '%s'" % [entry["id"], map_id])
		seen[map_id] = true


static func _validate_map_data(document: Variant, entry: Dictionary,
		errors: Array[String]) -> void:
	if not document is Dictionary:
		errors.append("CampaignTier2Validators: map data '%s' must be an object" % entry["id"])
		return
	_require_string(document, "id", "map data '%s'" % entry["id"], errors)
	_require_string(document, "display_name", "map data '%s'" % entry["id"], errors)
	if String(document.get("id", "")) != entry["id"]:
		errors.append("CampaignTier2Validators: map data id does not match catalogue id '%s'" % entry["id"])
	var grid: Variant = document.get("grid", null)
	if not grid is Array or grid.is_empty():
		errors.append("CampaignTier2Validators: map data '%s' grid must be a non-empty array" % entry["id"])
	var starts: Variant = document.get("player_start_tiles", null)
	if not starts is Array or starts.is_empty():
		errors.append("CampaignTier2Validators: map data '%s' needs player_start_tiles" % entry["id"])


static func _validate_roster(document: Variant, entry: Dictionary,
		errors: Array[String]) -> void:
	if not document is Dictionary or not document.get("units", null) is Array \
			or document["units"].is_empty():
		errors.append("CampaignTier2Validators: roster '%s' must contain a non-empty units array" % entry["id"])
		return
	var seen := {}
	for unit in document["units"]:
		if not unit is Dictionary:
			errors.append("CampaignTier2Validators: roster '%s' units must be objects" % entry["id"])
			continue
		_require_string(unit, "unit_id", "roster '%s' unit" % entry["id"], errors)
		_require_string(unit, "class_id", "roster '%s' unit '%s'" % [entry["id"], unit.get("unit_id", "")], errors)
		var unit_id := String(unit.get("unit_id", ""))
		if seen.has(unit_id):
			errors.append("CampaignTier2Validators: roster '%s' duplicates unit_id '%s'" % [entry["id"], unit_id])
		seen[unit_id] = true


static func _validate_class(document: Variant, entry: Dictionary,
		errors: Array[String]) -> void:
	if not document is Dictionary:
		errors.append("CampaignTier2Validators: class '%s' must be an object" % entry["id"])
		return
	_require_string(document, "id", "class '%s'" % entry["id"], errors)
	_require_string(document, "display_name", "class '%s'" % entry["id"], errors)
	if String(document.get("id", "")) != entry["id"]:
		errors.append("CampaignTier2Validators: class id does not match catalogue id '%s'" % entry["id"])


static func _require_string(document: Dictionary, field: String, owner: String,
		errors: Array[String]) -> void:
	if typeof(document.get(field)) != TYPE_STRING or String(document[field]).strip_edges().is_empty():
		errors.append("CampaignTier2Validators: %s.%s must be a non-empty string" % [owner, field])


static func _require_id(kind: String, id: String, owner: String,
		ids_by_kind: Dictionary, errors: Array[String]) -> void:
	if id.is_empty() or not ids_by_kind.get(kind, {}).has(id):
		errors.append("CampaignTier2Validators: %s references missing %s '%s'" % [owner, kind, id])
