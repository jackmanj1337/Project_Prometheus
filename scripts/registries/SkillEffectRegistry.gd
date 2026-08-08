class_name SkillEffectRegistry extends RefCounted
# Engine-owned skill-effect vocabulary. Content may reference these ids, while
# engine modules can register additional handlers without editing SkillHandler.

var _entries: Dictionary = {}


func register_effect(
	effect_id: String, handler: Callable, implemented: bool = true
) -> Array[String]:
	var errors: Array[String] = []
	if effect_id.strip_edges().is_empty():
		errors.append("SkillEffectRegistry: effect id is empty")
	if not handler.is_valid():
		errors.append("SkillEffectRegistry: effect '%s' has no handler" % effect_id)
	if _entries.has(effect_id):
		errors.append("SkillEffectRegistry: duplicate effect id '%s'" % effect_id)
	if errors.is_empty():
		_entries[effect_id] = {"handler": handler, "implemented": implemented}
	return errors


func register_builtins(handler_owner: Object) -> Array[String]:
	var errors: Array[String] = []
	for effect_id: String in _builtin_handler_names():
		var handler_name: String = _builtin_handler_names()[effect_id]
		errors.append_array(
			register_effect(
				effect_id,
				Callable(handler_owner, handler_name),
				handler_name != "_apply_unimplemented"
			)
		)
	return errors


func has_effect(effect_id: String) -> bool:
	return _entries.has(effect_id)


func is_implemented(effect_id: String) -> bool:
	return _entries.has(effect_id) and bool((_entries[effect_id] as Dictionary)["implemented"])


func ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_entries.keys())
	result.sort()
	return result


func implemented_ids() -> Array[String]:
	return _ids_with_implementation(true)


func inert_ids() -> Array[String]:
	return _ids_with_implementation(false)


func execute(effect_id: String, skill: SkillData, unit: Node, context: Dictionary) -> Variant:
	if not _entries.has(effect_id):
		return null
	return ((_entries[effect_id] as Dictionary)["handler"] as Callable).call(skill, unit, context)


func _ids_with_implementation(implemented: bool) -> Array[String]:
	var result: Array[String] = []
	for effect_id: String in _entries:
		if bool((_entries[effect_id] as Dictionary)["implemented"]) == implemented:
			result.append(effect_id)
	result.sort()
	return result


func _builtin_handler_names() -> Dictionary:
	return {
		"renewal": "_apply_renewal",
		"vantage": "_apply_vantage",
		"nihil": "_apply_nihil",
		"resolve": "_apply_resolve",
		"wrath": "_apply_wrath",
		"miracle": "_apply_miracle",
		"stat_bonus": "_apply_stat_bonus",
		"faire": "_apply_faire",
		"breaker": "_apply_breaker",
		"charm": "_apply_charm",
		"anathema": "_apply_anathema",
		"daunt": "_apply_daunt",
		"s_rank_mastery": "_apply_s_rank_mastery",
		"prescience": "_apply_prescience",
		"patience": "_apply_patience",
		"discipline": "_apply_discipline",
		"focus": "_apply_focus",
		"healtouch": "_apply_healtouch",
		"outdoor_fighter": "_apply_unimplemented",
		"indoor_fighter": "_apply_unimplemented",
		"armsthrift": "_apply_unimplemented",
		"swiftfoot": "_apply_unimplemented",
		"multishot": "_apply_unimplemented",
		"hawkeye": "_apply_unimplemented",
		"deadeye": "_apply_unimplemented",
		"rally_skill": "_apply_unimplemented",
		"strike_true": "_apply_unimplemented",
		"challenge": "_apply_unimplemented",
		"counter": "_apply_unimplemented",
		"supremacy": "_apply_unimplemented",
		"blessing": "_apply_unimplemented",
		"holy_aura": "_apply_unimplemented",
		"boon": "_apply_unimplemented",
		"judgement": "_apply_unimplemented",
		"sol": "_apply_unimplemented",
		"odd_rhythm": "_apply_unimplemented",
		"even_rhythm": "_apply_unimplemented",
		"bastion": "_apply_unimplemented",
		"iron_wall": "_apply_unimplemented",
		"pavise": "_apply_unimplemented",
		"charge": "_apply_unimplemented",
		"aegis": "_apply_unimplemented",
		"flare": "_apply_unimplemented",
		"phasing": "_apply_unimplemented",
		"deeper_knowledge": "_apply_unimplemented",
		"lifetaker": "_apply_unimplemented",
		"shadowgift": "_apply_unimplemented",
		"dash": "_apply_unimplemented",
		"disarm": "_apply_unimplemented",
		"vigilance": "_apply_unimplemented",
		"diehard": "_apply_unimplemented",
	}
