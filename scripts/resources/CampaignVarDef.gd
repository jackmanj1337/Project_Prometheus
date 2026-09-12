class_name CampaignVarDef
# adopter-todo: B6-MUTABLE-CAMPAIGN-STATE-2026-07-23
# The typed campaign variable store that reads these defs is that row's subject.
# Nothing outside scripts/tests/ reaches this type until it lands.
extends "res://scripts/resources/RegistryEntry.gd"

## Author-declared typed campaign variable. The registry owns identity while
## CampaignVars owns mutable values.

@export_enum("bool", "int", "enum") var value_type: String = "bool"
@export var default_bool: bool = false
@export var default_int: int = 0
@export var default_enum: String = ""
@export_enum("locked", "start", "mid_run") var exposed: String = "locked"
@export_enum("campaign", "map") var scope: String = "campaign"
@export var min_value: int = 0
@export var max_value: int = 0
@export var options: Array[String] = []


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if value_type not in ["bool", "int", "enum"]:
		errors.append("CampaignVarDef '%s' has unknown type '%s'" % [id, value_type])
	if exposed not in ["locked", "start", "mid_run"]:
		errors.append("CampaignVarDef '%s' has unknown exposure '%s'" % [id, exposed])
	if scope not in ["campaign", "map"]:
		errors.append("CampaignVarDef '%s' has unknown scope '%s'" % [id, scope])
	if value_type == "int":
		if min_value > max_value or default_int < min_value or default_int > max_value:
			errors.append("CampaignVarDef '%s' default is outside its bounds" % id)
	elif value_type == "enum":
		if options.is_empty():
			errors.append("CampaignVarDef '%s' enum options are empty" % id)
		elif default_enum not in options:
			errors.append("CampaignVarDef '%s' default is not an enum option" % id)
	return errors


func normalized_default_value() -> Variant:
	match value_type:
		"bool":
			return default_bool
		"int":
			return default_int
		"enum":
			return default_enum
	return null
