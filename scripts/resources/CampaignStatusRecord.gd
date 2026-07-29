class_name CampaignStatusRecord extends RefCounted
# Compact portable carry-forward artifact. Facts/counters are open dictionaries;
# no story fact becomes an engine field.

const FORMAT_VERSION := 1

var record_id := ""
var author_id := ""
var campaign_id := ""
var campaign_version := "1.0.0"
var created_at_utc := ""
var completion: Dictionary = {}
var facts: Dictionary = {}
var counters: Dictionary = {}
var checksum := ""


static func from_dict(source: Variant, errors: Array[String]) -> CampaignStatusRecord:
	if not (source is Dictionary):
		errors.append("CampaignStatusRecord: document must be an object")
		return null
	if int(source.get("format_version", -1)) != FORMAT_VERSION:
		errors.append("CampaignStatusRecord: unsupported format_version")
		return null
	var record := CampaignStatusRecord.new()
	record.record_id = String(source.get("record_id", ""))
	record.author_id = String(source.get("author_id", ""))
	record.campaign_id = String(source.get("campaign_id", ""))
	record.campaign_version = String(source.get("campaign_version", ""))
	record.created_at_utc = String(source.get("created_at_utc", ""))
	for field in ["record_id", "author_id", "campaign_id", "campaign_version"]:
		if String(record.get(field)) == "":
			errors.append("CampaignStatusRecord: %s is required" % field)
	if (
		not (source.get("completion", {}) is Dictionary)
		or not (source.get("facts", {}) is Dictionary)
		or not (source.get("counters", {}) is Dictionary)
	):
		errors.append("CampaignStatusRecord: completion, facts, and counters must be objects")
		return null
	record.completion = source.get("completion", {}).duplicate(true)
	record.facts = source.get("facts", {}).duplicate(true)
	record.counters = source.get("counters", {}).duplicate(true)
	record.checksum = String(source.get("checksum", ""))
	for fact_id in record.facts:
		if not (fact_id is String) or String(fact_id) == "":
			errors.append("CampaignStatusRecord: facts contains an invalid id")
	if not errors.is_empty():
		return null
	if record.checksum == "" or record.checksum != record.calculate_checksum():
		errors.append("CampaignStatusRecord: checksum mismatch")
		return null
	return record


func to_dict() -> Dictionary:
	var out := _payload()
	out["checksum"] = calculate_checksum()
	return out


func calculate_checksum() -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(JSON.stringify(_canonicalize(_payload()), "", false).to_utf8_buffer())
	return context.finish().hex_encode()


func _payload() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"record_id": record_id,
		"author_id": author_id,
		"campaign_id": campaign_id,
		"campaign_version": campaign_version,
		"created_at_utc": created_at_utc,
		"completion": completion.duplicate(true),
		"facts": facts.duplicate(true),
		"counters": counters.duplicate(true),
	}


static func _canonicalize(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, float(int(value))):
		return int(value)
	if value is Array:
		var array: Array = []
		for entry in value:
			array.append(_canonicalize(entry))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		for key in value:
			dictionary[key] = _canonicalize(value[key])
		return dictionary
	return value
