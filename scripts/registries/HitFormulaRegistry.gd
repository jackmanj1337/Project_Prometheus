class_name HitFormulaRegistry
extends RefCounted

const DEFAULT_ID := "two_roll"
const DESCRIPTORS := {
	"two_roll": {"schema_version": 1, "rn_count": 2},
	"single_roll": {"schema_version": 1, "rn_count": 1},
}


static func validate(id: String, parameters: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	if not DESCRIPTORS.has(id):
		errors.append("unknown hit formula '%s'" % id)
	if not parameters.is_empty():
		errors.append("hit formula '%s' accepts no parameters" % id)
	return errors


static func rn_count(id: String) -> int:
	return int(DESCRIPTORS[id]["rn_count"]) if DESCRIPTORS.has(id) else -1


static func evaluate(id: String, displayed_hit: int, rns: Array[int]) -> FormulaResult:
	var errors := validate(id)
	if not errors.is_empty():
		return FormulaResult.failure(errors[0])
	var expected := rn_count(id)
	if rns.size() != expected:
		return FormulaResult.failure("hit formula '%s' requires %d rolls" % [id, expected])
	for rn in rns:
		if rn < 0 or rn > 99:
			return FormulaResult.failure("hit roll is outside 0..99")
	var hit := clampi(displayed_hit, 0, 100)
	if id == "two_roll":
		return FormulaResult.success((rns[0] + rns[1]) / 2 < hit)
	return FormulaResult.success(rns[0] < hit)


static func preview_probability(id: String, displayed_hit: int) -> FormulaResult:
	if not DESCRIPTORS.has(id):
		return FormulaResult.failure("unknown hit formula '%s'" % id)
	var hit := clampi(displayed_hit, 0, 100)
	if id == "single_roll":
		return FormulaResult.success(float(hit) / 100.0)
	var successes := 0
	for first in 100:
		for second in 100:
			if (first + second) / 2 < hit:
				successes += 1
	return FormulaResult.success(float(successes) / 10000.0)
