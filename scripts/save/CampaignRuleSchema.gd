class_name CampaignRuleSchema extends RefCounted
# Shared serialization/default authority for campaign rules. Invalid values are
# normalized to safe defaults so a damaged save cannot partially mutate a run.

const SaveCodec = preload("res://scripts/save/SaveCodec.gd")
const SavePolicy = preload("res://scripts/save/SavePolicy.gd")

const RESOURCE_FIELDS: Array[String] = [
	"leveling_method",
	"auto_promote_at_max_level",
	"pair_up_enabled",
	"max_skills",
	"max_inventory",
	"exp_gaining_factions",
	"hit_formula",
	"rewind_charges_per_map",
	"rewind_cost_mode",
	"requirement_node_budget",
	"value_term_node_budget",
	"requirement_depth_budget",
	"value_term_depth_budget",
	"undo_activations",
	"undo_rounds",
	"battle_result_actions",
	"save_slot_classes",
	"autosave_rules",
]


static func defaults() -> Dictionary:
	return {
		"death_mode": "casual",
		"leveling_method": "growth_random",
		"auto_promote_at_max_level": false,
		"pair_up_enabled": true,
		"max_skills": 5,
		"max_inventory": 8,
		"exp_gaining_factions": ["blue", "green"],
		"hit_formula": "two_roll",
		"rewind_charges_per_map": 4,
		"rewind_cost_mode": "per_activation",
		"requirement_node_budget": 128,
		"value_term_node_budget": 128,
		"requirement_depth_budget": 16,
		"value_term_depth_budget": 16,
		"undo_activations": 0,
		"undo_rounds": 0,
		"battle_result_actions":
		{
			"victory": {"continue": true, "retry": true, "save": true, "quit": true},
			"defeat": {"retry": true, "reload": true, "load": true, "rewind": true, "quit": true},
		},
		"save_slot_classes": SavePolicy.classic_gba(),
		"autosave_rules": SavePolicy.default_autosave_rules(),
		"mandated_rules": [],
		"profile_selections": {},
		"exposed_tunables": {},
		"pxp_profiles": {},
	}


static func normalize(source: Variant) -> Dictionary:
	var out := defaults()
	if source is Dictionary:
		for key in source:
			out[key] = source[key]
	if out.has("permadeath_enabled") and not (source is Dictionary and source.has("death_mode")):
		out["death_mode"] = "classic" if bool(out["permadeath_enabled"]) else "casual"
	out.erase("permadeath_enabled")
	out["death_mode"] = "classic" if String(out["death_mode"]) == "classic" else "casual"
	for field in [
		"max_skills",
		"max_inventory",
		"rewind_charges_per_map",
		"requirement_node_budget",
		"value_term_node_budget",
		"requirement_depth_budget",
		"value_term_depth_budget",
		"undo_activations",
		"undo_rounds"
	]:
		out[field] = SaveCodec.as_int(out.get(field, defaults()[field]), defaults()[field])
	out["exp_gaining_factions"] = SaveCodec.string_array_from_variant(
		out.get("exp_gaining_factions", ["blue", "green"])
	)
	out["rewind_cost_mode"] = String(out.get("rewind_cost_mode", "per_activation"))
	if out["rewind_cost_mode"] not in ["per_activation", "full_history"]:
		out["rewind_cost_mode"] = "per_activation"
	out["save_slot_classes"] = SavePolicy.normalize_slot_classes(out.get("save_slot_classes", []))
	out["autosave_rules"] = SavePolicy.normalize_autosave_rules(out.get("autosave_rules", []))
	out["mandated_rules"] = SaveCodec.string_array_from_variant(out.get("mandated_rules", []))
	return out


static func from_resource(rules: Resource, mandated: Variant = []) -> Dictionary:
	var out := defaults()
	if rules == null:
		return out
	out["death_mode"] = "classic" if bool(rules.get("permadeath_enabled")) else "casual"
	for field in RESOURCE_FIELDS:
		var value: Variant = rules.get(field)
		out[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	out["mandated_rules"] = mandated
	return normalize(out)


static func apply_to_resource(rules: Resource, source: Variant) -> Dictionary:
	var out := normalize(source)
	if rules == null:
		return out
	rules.set("permadeath_enabled", out["death_mode"] == "classic")
	for field in RESOURCE_FIELDS:
		var value: Variant = out[field]
		rules.set(field, value.duplicate(true) if value is Array or value is Dictionary else value)
	return out
