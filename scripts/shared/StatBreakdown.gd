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
	"constitution":  "Con",
	"line_of_sight": "LoS",
}

# Friendly source labels for known modifier sources. Unknown sources fall back
# to the raw id so debugging output still tells you what is going on.
const SOURCE_LABELS: Dictionary = {
	"tonic":           "Tonic",
	"item":            "Item",
	"pair_up":         "Pair Up",
	"terrain":         "Terrain",
	"rally":           "Rally",
	"weapon_triangle": "Weapon Triangle",
	"skill":           "Skill",
}

# Sentinel cap value used when a class authors no cap for a STAT_KEYS stat — a
# data-integrity hole the character sheet surfaces loudly rather than hiding.
const CAP_MISSING := -1


# Builds the breakdown dict for unit + stat_name. unit must respond to
# get_effective_stat() and expose data.active_modifiers; if either is missing
# the helper returns a safe empty shape rather than throwing.
#
# Optional args:
#   class_data  — the unit's ClassData. When supplied, the result carries the
#                 personal/class decomposition (`personal_base`, `class_base`)
#                 and the class `cap` (+ `cap_state`). Math authority for the
#                 effective stat still lives in Unit.get_effective_stat().
#   extra_mods  — combat-only contribution rows the caller computed (pair-up,
#                 stat skills) via StatContributions. They don't live in
#                 active_modifiers outside a fight, so the caller injects them;
#                 they are merged into `mods` and added into `effective_display`.
static func build(unit, stat_name: String, class_data = null,
		extra_mods: Array = []) -> Dictionary:
	var label := label_for_stat(stat_name)
	if unit == null or not is_instance_valid(unit) or unit.get("data") == null:
		return {
			"stat": stat_name, "label": label,
			"base": 0, "effective": 0, "effective_display": 0, "total_delta": 0,
			"personal_base": 0, "class_base": 0,
			"cap": CAP_MISSING, "cap_state": "unknown",
			"mods": [],
		}
	var data = unit.data
	var base_value: int = int(data.get(stat_name)) if data.get(stat_name) != null else 0
	var effective: int = base_value
	if unit.has_method("get_effective_stat"):
		effective = int(unit.get_effective_stat(stat_name))
	var mods: Array = _collect_mods(data, stat_name)
	# Merge the injected combat-only rows after the persistent ones.
	for em in extra_mods:
		mods.append(em)
	var total_delta: int = 0
	for m in mods:
		total_delta += int(m["delta"])
	# effective_display includes the combat-only rows (which aren't in
	# active_modifiers outside a fight); effective stays the live engine value.
	var extra_delta: int = 0
	for em in extra_mods:
		extra_delta += int(em.get("delta", 0))
	var class_info := _class_decomposition(class_data, stat_name, base_value)
	return {
		"stat": stat_name,
		"label": label,
		"base": base_value,
		"effective": effective,
		"effective_display": effective + extra_delta,
		"total_delta": total_delta,
		"personal_base": class_info["personal_base"],
		"class_base": class_info["class_base"],
		"cap": class_info["cap"],
		"cap_state": class_info["cap_state"],
		"mods": mods,
	}


# Splits base_value into the class-base contribution and the unit's personal
# value, and reads the class cap. STAT_KEYS stats with no cap key report
# cap_state "missing" (a data hole); stats outside STAT_KEYS (MOV/CON/LoS) are
# intentionally "uncapped". With no class_data the split is "unknown".
static func _class_decomposition(class_data, stat_name: String, base_value: int) -> Dictionary:
	if class_data == null:
		return {"personal_base": base_value, "class_base": 0,
			"cap": CAP_MISSING, "cap_state": "unknown"}
	var class_base: int = 0
	var base_field := "base_%s" % stat_name
	if base_field in class_data:
		class_base = int(class_data.get(base_field))
	var cap: int = CAP_MISSING
	var cap_state := "uncapped"
	var caps: Dictionary = class_data.get("stat_caps")
	if stat_name in ClassData.STAT_KEYS:
		if caps != null and caps.has(stat_name):
			cap = int(caps[stat_name])
			cap_state = "capped"
		else:
			cap_state = "missing"
	return {
		# personal value = stored stat minus the class base contribution. Authored
		# units can store a stat below their class base; clamp at 0 so the row never
		# shows a negative "personal" value.
		"personal_base": maxi(0, base_value - class_base),
		"class_base": class_base,
		"cap": cap,
		"cap_state": cap_state,
	}


# Returns the friendly short label for a stat id, falling back to the id
# capitalised so unknown stats still render readably.
static func label_for_stat(stat_name: String) -> String:
	if STAT_LABELS.has(stat_name):
		return STAT_LABELS[stat_name]
	return stat_name.capitalize()


# Returns the friendly source label. Sources are often namespaced
# (`pair_up:<id>:<stat>`, `item:<id>`, `skill:<id>`); we match the whole id
# first, then the prefix before the first ':'. Unknown sources fall back to the
# raw id so debugging output still tells you what is going on.
static func label_for_source(source_id: String) -> String:
	if SOURCE_LABELS.has(source_id):
		return SOURCE_LABELS[source_id]
	var prefix := source_id.get_slice(":", 0)
	if SOURCE_LABELS.has(prefix):
		return SOURCE_LABELS[prefix]
	return source_id


# Format a signed integer with explicit sign — used by every UI consumer so
# row formatting stays consistent without each caller rolling its own.
static func format_signed(value: int) -> String:
	return "%+d" % value


# Format the remaining-duration text. "combat" scope expires at end of combat
# rather than on a turn counter, so it carries the -1 sentinel and must be
# matched by type BEFORE the negative-remaining fallback (else Pair Up's "-1"
# would print as a bare "—"). duration_type "permanent" or any other negative
# remaining means never auto-removed and is shown as a dash.
static func format_duration(duration_type: String, remaining: int) -> String:
	if duration_type == "combat":
		return "this combat"
	if duration_type == "permanent" or remaining < 0:
		return "—"
	match duration_type:
		"turn":     return "%d turn%s" % [remaining, "" if remaining == 1 else "s"]
		"map_turn": return "%d round%s" % [remaining, "" if remaining == 1 else "s"]
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
