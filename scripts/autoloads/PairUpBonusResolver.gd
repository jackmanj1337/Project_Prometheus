extends Node
# Pair Up bonus resolver — single source of truth for the stat bonus a paired
# support unit contributes to its lead (Q5). Both combat preview and live
# combat call bonuses_for() so the forecast and the actual fight never
# disagree.
#
# Returned dict is keyed by UnitData stat names (strength, magic, defense,
# resistance, skill, speed, luck). CombatResolver applies them as
# duration_type="combat" modifiers so existing get_effective_stat readers
# pick them up without bespoke combat-stat translation here.
#
# class_name omitted to skip global class-cache maintenance.

const PairUpBonusTableScript = preload("res://scripts/resources/PairUpBonusTable.gd")
const _DEFAULT_TABLE_PATH := "res://data/pair_up/pair_up_bonus_table.tres"

# Loaded lazily on first call so headless tests that don't need the table
# never pay the .tres load cost. Settable directly by tests via load_table().
var _table: Resource = null


# Returns the stat-bonus dictionary the given support unit contributes to its
# paired lead. Empty dict on null/data-less support, when the table cannot be
# loaded, or when the support's class has no entry. Caller may mutate the
# returned dict freely — it is built fresh on every call.
func bonuses_for(support_unit: Node) -> Dictionary:
	if support_unit == null or support_unit.data == null:
		return {}
	if not _ensure_table_loaded():
		return {}
	return _compute_bonuses(support_unit.data.class_id, support_unit)


# Test seam: lets tests inject a custom PairUpBonusTable resource without
# touching the on-disk .tres. Passing null forces the next bonuses_for() call
# to re-load the default table.
func load_table(table: Resource) -> void:
	_table = table


# Test seam: compute bonuses from a class id + a stat dictionary (e.g.
# {"strength": 12, "skill": 8}) without needing a real Unit / UnitData. Lets
# the unit-test layer exercise the formula independently of Unit plumbing.
func bonuses_for_class_and_stats(class_id: String, support_stats: Dictionary) -> Dictionary:
	if not _ensure_table_loaded():
		return {}
	return _compute_bonuses_from_stats(class_id, support_stats)


func _ensure_table_loaded() -> bool:
	if _table != null:
		return true
	if not ResourceLoader.exists(_DEFAULT_TABLE_PATH):
		return false
	_table = load(_DEFAULT_TABLE_PATH)
	return _table != null


func _compute_bonuses(class_id: String, support_unit: Node) -> Dictionary:
	return _compute_bonuses_common(
		class_id, func(stat: String) -> int: return _read_support_stat(support_unit, stat)
	)


# Variant used by bonuses_for_class_and_stats — same shape as _compute_bonuses
# but reads scaling input from the supplied dict rather than a Unit Node.
# Routes through the same body so a missing stat key reads as 0 (production
# behaviour via _read_support_stat), not skipped (code review 2026-06-10
# issue 2.3 — the previous "if not support_stats.has(...)" silently
# diverged from production).
func _compute_bonuses_from_stats(class_id: String, support_stats: Dictionary) -> Dictionary:
	return _compute_bonuses_common(
		class_id, func(stat: String) -> int: return int(support_stats.get(stat, 0))
	)


# Shared body: builds the bonus dict from the flat block + scaling layer.
# `read_stat` is a Callable(String) -> int that yields the support's value for
# a stat — Unit-backed for production, dict-backed for the test seam — so the
# two entry points cannot drift on the "missing stat reads 0" rule.
func _compute_bonuses_common(class_id: String, read_stat: Callable) -> Dictionary:
	var flat: Dictionary = _table.call("get_class_bonus", class_id)
	var divisor: int = int(_table.get("scaling_divisor"))
	var scaling_stats: PackedStringArray = _table.get("scaling_stats")
	var out: Dictionary = {}
	# Start with the flat block — copy each entry so the caller can mutate freely.
	for stat in flat.keys():
		var stat_key: String = String(stat)
		out[stat_key] = int(flat[stat_key])
	# Scaling layer: floor(support.effective_stat / divisor) for each scaling stat.
	if divisor > 0:
		for stat in scaling_stats:
			var stat_key: String = String(stat)
			var scale: int = int(read_stat.call(stat_key)) / divisor
			if scale == 0:
				continue
			out[stat_key] = int(out.get(stat_key, 0)) + scale
	return out


# Reads a support unit's effective stat, preferring get_effective_stat (so
# active modifiers count) and falling back to raw data fields for stubs.
func _read_support_stat(support_unit: Node, stat: String) -> int:
	if support_unit.has_method("get_effective_stat"):
		return int(support_unit.get_effective_stat(stat))
	var data = support_unit.data
	if data == null:
		return 0
	var v = data.get(stat)
	return int(v) if v != null else 0
