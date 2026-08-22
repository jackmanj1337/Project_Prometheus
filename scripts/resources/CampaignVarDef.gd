class_name CampaignVarDef
# adopter-todo: B6-MUTABLE-CAMPAIGN-STATE-2026-07-23
# The typed campaign variable store that reads these defs is that row's subject.
# Nothing outside scripts/tests/ reaches this type until it lands.
extends "res://scripts/resources/RegistryEntry.gd"

## Author-declared typed campaign variable. The registry owns identity while
## CampaignVars owns mutable values.

@export_enum("bool", "int", "enum") var value_type: String = "bool"
@export var default_value: Variant = false
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
	if value_type == "bool" and not default_value is bool:
		errors.append("CampaignVarDef '%s' default must be bool" % id)
	elif value_type == "int":
		if not default_value is int:
			errors.append("CampaignVarDef '%s' default must be int" % id)
		elif (
			min_value > max_value
			or int(default_value) < min_value
			or int(default_value) > max_value
		):
			errors.append("CampaignVarDef '%s' default is outside its bounds" % id)
	elif value_type == "enum":
		if options.is_empty():
			errors.append("CampaignVarDef '%s' enum options are empty" % id)
		elif not default_value is String or String(default_value) not in options:
			errors.append("CampaignVarDef '%s' default is not an enum option" % id)
	return errors
