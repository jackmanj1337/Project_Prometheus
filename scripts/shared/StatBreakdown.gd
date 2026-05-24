extends RefCounted
# Shared helper that turns a unit + a stat name into a structured breakdown the
# More Info surfaces (UnitDetailsScreen, AttackPreview, HUD) can render
# uniformly. Math authority stays with Unit.get_effective_stat() — this helper
# only *explains* the result, it does not recompute it.
#
# Usage:
#   const StatBreakdown = preload("res://scripts/shared/StatBreakdown.gd")
#   var info: Dictionary = StatBreakdown.build(unit, "strength")
#
# Returns the locked shape from more_info_mode_plan_2026-05-24.md:
#   {
#     "stat": "strength",
#     "label": "Str",
#     "base": 9,
#     "effective": 11,
#     "total_delta": 2,
#     "mods": [
#       {
#         "source_id": "tonic",
#         "source_label": "Tonic",
#         "delta": 2,
#         "duration_type": "turn",
#         "remaining": 1,
#       }
#     ]
#   }

# Friendly short labels keyed by canonical stat name. Anything not in here
# falls back to the capitalised stat id so a new stat never crashes the UI.
const STAT_LABELS: Dictionary = {
	"strength":   "Str",
	"magic":      "Mag",
	"skill":      "Skl",
	"speed":      "Spd",
	"defense":    "Def",
	"resistance": "Res",
	"luck":       "Lck",
	"movement":   "Mov",
}

# Friendly source labels for known modifier sources. Unknown sources fall back
# to the raw id so debugging output still tells you what is going on.
const SOURCE_LABELS: Dictionary = {
	"tonic":           "Tonic",
	"pair_up":         "Pair Up",
	"terrain":         "Terrain",
	"rally":           "Rally",
	"weapon_triangle": "Weapon Triangle",
	"skill":           "Skill",
}


# Builds the breakdown dict for unit + stat_name. unit must respond to
# get_effective_stat() and expose data.active_modifiers; if either is missing
# the helper returns a safe empty shape rather than throwing.
static func build(unit, stat_name: String) -> Dictionary:
	var label := label_for_stat(stat_name)
	if unit == null or not is_instance_valid(unit) or unit.get("data") == null:
		return {
			"stat": stat_name, "label": label,
			"base": 0, "effective": 0, "total_delta": 0,
			"mods": [],
		}
	var data = unit.data
	var base_value: int = int(data.get(stat_name)) if data.get(stat_name) != null else 0
	var effective: int = base_value
	if unit.has_method("get_effective_stat"):
		effective = int(unit.get_effective_stat(stat_name))
	var mods: Array = _collect_mods(data, stat_name)
	var total_delta: int = 0
	for m in mods:
		total_delta += int(m["delta"])
	return {
		"stat": stat_name,
		"label": label,
		"base": base_value,
		"effective": effective,
		"total_delta": total_delta,
		"mods": mods,
	}


# Returns the friendly short label for a stat id, falling back to the id
# capitalised so unknown stats still render readably.
static func label_for_stat(stat_name: String) -> String:
	if STAT_LABELS.has(stat_name):
		return STAT_LABELS[stat_name]
	return stat_name.capitalize()


# Returns the friendly source label, falling back to the raw id when no
# friendly label is authored yet.
static func label_for_source(source_id: String) -> String:
	if SOURCE_LABELS.has(source_id):
		return SOURCE_LABELS[source_id]
	return source_id


# Format a signed integer with explicit sign — used by every UI consumer so
# row formatting stays consistent without each caller rolling its own.
static func format_signed(value: int) -> String:
	return "%+d" % value


# Format the remaining-duration text. duration_type "permanent" or duration -1
# means never auto-removed and is shown as a dash. "combat" duration shows
# "this combat" so the player understands the scope without seeing a number.
static func format_duration(duration_type: String, remaining: int) -> String:
	if duration_type == "permanent" or remaining < 0:
		return "—"
	match duration_type:
		"turn":     return "%d turn%s" % [remaining, "" if remaining == 1 else "s"]
		"map_turn": return "%d round%s" % [remaining, "" if remaining == 1 else "s"]
		"combat":   return "this combat"
		_:          return "%d" % remaining


# Collects + groups modifiers for the requested stat. Same source ids are
# merged into one row (delta summed, duration takes the max remaining) so the
# UI shows one "Tonic +4" instead of "Tonic +2, Tonic +2". add_modifier()
# already de-duplicates same-source mods, but other code paths may not, and
# grouping keeps the display stable either way.
static func _collect_mods(data, stat_name: String) -> Array:
	var grouped: Dictionary = {}
	var order: Array[String] = []
	for mod in data.active_modifiers:
		if String(mod.get("stat", "")) != stat_name:
			continue
		var source_id := String(mod.get("source", "?"))
		var delta := int(mod.get("delta", 0))
		var duration := int(mod.get("duration", 0))
		var duration_type := String(mod.get("duration_type", ""))
		if not grouped.has(source_id):
			order.append(source_id)
			grouped[source_id] = {
				"source_id":     source_id,
				"source_label":  label_for_source(source_id),
				"delta":         delta,
				"duration_type": duration_type,
				"remaining":     duration,
			}
		else:
			# Merge a duplicate same-source row: sum deltas, keep the longest
			# remaining duration so the player sees the most generous lifetime.
			var existing: Dictionary = grouped[source_id]
			existing["delta"] = int(existing["delta"]) + delta
			if duration > int(existing["remaining"]):
				existing["remaining"] = duration
				existing["duration_type"] = duration_type
	var out: Array = []
	for source_id in order:
		out.append(grouped[source_id])
	return out
