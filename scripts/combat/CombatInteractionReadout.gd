class_name CombatInteractionReadout
extends RefCounted
# THE PLAYER-FACING READOUT for authored trait interactions — slice 6 of
# AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10, the `[ITR-6]` ruling of 2026-09-10:
# **authored presentation over a generic fallback.**
#
# WHAT IT REPLACES. `preview_combat()` used to answer the question "what relationship is in
# this fight?" with `attacker_triangle`, one String with three legal words, plus
# `attacker_effectiveness_mult`, one float. That was adequate for exactly one relationship
# named in the engine. It cannot survive N authored profiles: three words cannot say WHICH
# profile produced a number, a single float cannot carry two multipliers, and neither can
# carry a name the pack chose. Slice 5 left both in place as a derived interim and this file
# is what replaces them — one row per authored relationship, in the author's order, naming
# itself.
#
# A ROW IS A PROFILE, NOT A RULE. `[ITR-6]` gives `presentation` to the profile, and that is
# the right grain for a player: "Weapon Triangle" is the relationship, `axe_vs_lance` is
# which arm of it fired. The rules that fired are named in the row's detail, where a tester
# looking for the authored data can find them, and never in the row itself.
#
# IT READS TWO SOURCES AND RECOMPUTES NEITHER.
#   * the LEDGER, for the numbers — because the ledger holds what the arithmetic actually
#     used. Deriving a row from the resolver's magnitudes instead would be a second
#     computation of the same figures, which is how `preview_combat()` and
#     `project_exchange()` drifted in the first place.
#   * the RECORDS, for the presentation and the provenance — the profile's authored label,
#     its stack policy, and what its rules suppressed.
# The join between them is the attribution slice 6 put on each ledger entry; see
# `CombatTermLedger.attribute`.
#
# EVERYTHING IS PLAIN DATA. A row holds Strings and ints and nothing else: it travels
# through `preview_combat()`'s dictionary, through `ProjectionService`, and through a
# `duplicate(true)` for the debug audience. A row carrying a Node would be a row that
# cannot be copied and a row that keeps a dead unit alive.
#
# WHAT IT DOES NOT DECIDE. Colour, when the author declared none. The engine names a
# DIRECTION ("this helps the unit", "this hurts it") and the surface maps that onto its own
# palette, because the preview panel, a log line and a future combat forecast overlay do
# not share a colour scheme and should not be given one here.
#
# Authority: the `[ITR-1..7]` rulings. Resolve them through `GDD_Feature_Index.md` rather
# than by path.

const Ledger = preload("res://scripts/combat/CombatTermLedger.gd")

# The shape of one row, asserted by `test_combat_interaction_readout` in both directions so
# a consumer and this file cannot disagree about what a row carries.
const ROW_FIELDS: Array[String] = [
	"profile_id",
	"rule_ids",
	"label",
	"glyph",
	"color",
	"display_order",
	"authored",
	"terms",
	"summary",
	"direction",
	"detail",
]

# The shape of one term line inside a row. `on` is "actor" or "target" — which combatant
# carries the number — and it is in the row because it changes the SENSE of the sign: +10
# accuracy on the actor and +10 dodge on the target both read as "+10" and pull the strike
# in opposite directions.
const TERM_FIELDS: Array[String] = ["term", "label", "value", "percent", "on", "helps", "text"]

# The four directions a row may read. `mixed` exists because a single authored profile may
# perfectly well hand a unit a bonus and a penalty at once — the interim marker could not
# say that, and rounding it to "neutral" would report a relationship that is doing two
# things as one that is doing nothing.
const DIRECTION_ADVANTAGE := "advantage"
const DIRECTION_DISADVANTAGE := "disadvantage"
const DIRECTION_NEUTRAL := "neutral"
const DIRECTION_MIXED := "mixed"

# Player-facing names for the engine's term vocabulary. They live here rather than on
# `CombatTermLedger` because the ledger is arithmetic and these are words on a panel; they
# match the labels the forecast rows already use ("Hit", "Dmg", "Crit") so a player reads
# the same name twice rather than two names for one number.
const TERM_LABELS := {
	"accuracy": "Hit",
	"damage": "Dmg",
	"crit": "Crit",
	"crit_avoid": "Crit Avoid",
	"dodge": "Avoid",
	"might_multiplier_pct": "Might",
	"damage_multiplier_pct": "Damage",
}

# The generic glyphs, used for any row whose profile declared none.
const GLYPH_ADVANTAGE := "▲"
const GLYPH_DISADVANTAGE := "▼"
const GLYPH_NEUTRAL := "■"
const GLYPH_MIXED := "±"


# Builds the ordered readout for ONE STRIKE.
#
# A ROW BELONGS TO A STRIKE, NOT TO A UNIT, and that is the correction slice 6 had to make
# to its own first shape. `CombatResolver.strike_forecast()` reads a direction's terms from
# both combatants — the actor's accuracy, damage, crit and multipliers, and the TARGET's
# dodge and crit-avoid — so "everything recorded against the attacker" is neither all of
# what shapes the attacker's strike nor only that. An authored rule handing the defender an
# avoid bonus would have appeared in no column at all while changing the displayed hit rate.
# `CombatTermLedger.ACTOR_TERMS`/`TARGET_TERMS` is that split, declared where the vocabulary
# is, and every term lands in exactly one strike's readout.
#
# `records` is the resolver envelope's `records` array; `ledger` is the `CombatTermLedger`
# this direction's strike filled. An empty array is the answer a pack authoring no
# interactions gives — `[ITR-1]`. It is not a missing readout, it is a fight with no
# relationships in it, and a surface that renders a placeholder row for it invents one.
static func build(
	records: Array, ledger: Object, actor: Object, target: Object
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if actor == null or ledger == null or not ledger.has_method("contributions"):
		return rows

	# ONE WALK OF THE LEDGER IN RECORDING ORDER, not one per side concatenated: the order a
	# term was recorded in is the resolution order, which is what breaks a tie between two
	# profiles that declared no display_order. Reading the actor's contributions and then the
	# target's would put a target-side profile after an actor-side one regardless of which
	# the author declared first.
	var relevant: Array[Dictionary] = []
	for raw in ledger.entries:
		var entry := raw as Dictionary
		var side := Ledger.strike_side(String(entry.get("term", "")))
		var unit: Object = entry.get("unit")
		if side == "actor" and unit == actor:
			relevant.append(entry)
		elif side == "target" and unit == target and target != null and target != actor:
			relevant.append(entry)

	var by_profile: Dictionary = {}
	var order: Array[String] = []
	for entry in relevant:
		var profile_id := String(entry.get("profile_id", ""))
		if not by_profile.has(profile_id):
			var bucket: Array[Dictionary] = []
			by_profile[profile_id] = bucket
			order.append(profile_id)
		(by_profile[profile_id] as Array[Dictionary]).append(entry)

	var suppressed_labels := _suppressed_labels_by_suppressor(records)
	var indexed: Array[Dictionary] = []
	for position in order.size():
		var profile_id: String = order[position]
		var record := _record_for(records, profile_id)
		var labels_for_profile: Array[String] = []
		if suppressed_labels.has(profile_id):
			labels_for_profile.assign(suppressed_labels[profile_id])
		var row := _row(
			profile_id, by_profile[profile_id] as Array[Dictionary], record, labels_for_profile
		)
		# The declaration index rides alongside rather than inside the row: it is how this
		# file sorts, not something a consumer reads, and ROW_FIELDS is asserted exactly.
		indexed.append({"row": row, "index": position})

	# AUTHORED ORDER WINS, DECLARATION ORDER BREAKS EVERY TIE, and the tie-break is
	# EXPLICIT for the same reason the resolver's is: `Array.sort_custom` is not documented
	# as stable, so a comparator that answers "equal" for two rows may return them in either
	# order between Godot versions. A profile that declares no `display_order` sits at 0,
	# which is where an unauthored readout belongs relative to one an author placed.
	indexed.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var left := int((a["row"] as Dictionary)["display_order"])
			var right := int((b["row"] as Dictionary)["display_order"])
			if left != right:
				return left < right
			return int(a["index"]) < int(b["index"])
	)
	for item in indexed:
		rows.append(item["row"] as Dictionary)
	return rows


# The surface's fallback glyph for a row that declared none. Exposed rather than inlined so
# a second surface renders the same shape without copying the mapping.
static func glyph_for(direction: String) -> String:
	match direction:
		DIRECTION_ADVANTAGE:
			return GLYPH_ADVANTAGE
		DIRECTION_DISADVANTAGE:
			return GLYPH_DISADVANTAGE
		DIRECTION_MIXED:
			return GLYPH_MIXED
		_:
			return GLYPH_NEUTRAL


static func _record_for(records: Array, profile_id: String) -> Dictionary:
	for record in records:
		if (
			record is Dictionary
			and String((record as Dictionary).get("profile_id", "")) == profile_id
		):
			return record as Dictionary
	return {}


static func _row(
	profile_id: String,
	entries: Array[Dictionary],
	record: Dictionary,
	suppressed_labels: Array[String] = []
) -> Dictionary:
	var presentation: Dictionary = (
		(record.get("presentation", {}) as Dictionary)
		if record.get("presentation") is Dictionary
		else {}
	)
	var terms := _terms(entries)
	var direction := _direction(terms)
	var rule_ids := _rule_ids(entries)
	var label := _label(profile_id, presentation)
	var authored := not presentation.is_empty()
	var summary := _summary(terms)
	return {
		"profile_id": profile_id,
		"rule_ids": rule_ids,
		"label": label,
		# An authored glyph is used EXACTLY as written, including an empty string: an author
		# who declares `"glyph": ""` is asking for no glyph, and substituting the generic
		# one would overrule them. Only an UNDECLARED glyph falls back.
		"glyph":
		# Left empty when unauthored, deliberately. A colour name here would be this
		# module choosing a palette for surfaces it cannot see; `direction` is what it
		String(presentation["glyph"]) if presentation.has("glyph") else glyph_for(direction),
		# knows and what a surface can map.
		"color": String(presentation.get("color", "")),
		"display_order": int(presentation.get("display_order", 0)),
		"authored": authored,
		"terms": terms,
		"summary": summary,
		"direction": direction,
		"detail":
		_detail(label, rule_ids, summary, record, _show_authoring_rule_ids(), suppressed_labels),
	}


# Suppression evidence lives on the relationship that was removed, while the useful
# explanation belongs on the relationship the player can still select. Join the two by the
# suppressor profile id and carry only player-facing labels across the boundary. Raw profile
# and rule ids remain available in debug builds through the existing authoring detail.
static func _suppressed_labels_by_suppressor(records: Array) -> Dictionary:
	var labels := {}
	for raw_record in records:
		if not raw_record is Dictionary:
			continue
		var record := raw_record as Dictionary
		var presentation: Dictionary = (
			(record.get("presentation", {}) as Dictionary)
			if record.get("presentation") is Dictionary
			else {}
		)
		var suppressed_label := _label(String(record.get("profile_id", "")), presentation)
		for raw_suppressed in record.get("suppressed_rules", []):
			if not raw_suppressed is Dictionary:
				continue
			for raw_by in (raw_suppressed as Dictionary).get("by", []):
				if not raw_by is Dictionary:
					continue
				var suppressor_id := String((raw_by as Dictionary).get("profile_id", ""))
				if suppressor_id.is_empty() or suppressed_label.is_empty():
					continue
				if not labels.has(suppressor_id):
					var bucket: Array[String] = []
					labels[suppressor_id] = bucket
				var bucket := labels[suppressor_id] as Array[String]
				if suppressed_label not in bucket:
					bucket.append(suppressed_label)
	return labels


# One line per term this profile moved for this unit, in the order the terms were first
# contributed. Additive terms SUM and percent terms COMPOSE, exactly as the ledger composes
# them — a row's numbers are this profile's share of the ledger's totals, and the shares of
# every row add (or multiply) back up to them.
static func _terms(entries: Array[Dictionary]) -> Array[Dictionary]:
	var totals: Dictionary = {}
	var order: Array[String] = []
	for entry in entries:
		var term := String(entry.get("term", ""))
		var value := int(entry.get("value", 0))
		if not totals.has(term):
			order.append(term)
			totals[term] = 1.0 if Ledger.is_percent(term) else 0
		if Ledger.is_percent(term):
			totals[term] = float(totals[term]) * (float(value) / float(Ledger.PERCENT_BASE))
		else:
			totals[term] = int(totals[term]) + value

	var terms: Array[Dictionary] = []
	for term in order:
		var percent := Ledger.is_percent(term)
		# A percent term that composed back to exactly 1.0 changed nothing and is dropped:
		# "×1 Might" is a row saying a relationship applied and did not apply. An additive
		# 0 is dropped for the same reason. Both are reachable from honest authoring — a
		# +2/-2 pair in one profile — and neither is worth a line.
		if percent and is_equal_approx(float(totals[term]), 1.0):
			continue
		if not percent and int(totals[term]) == 0:
			continue
		var label := String(TERM_LABELS.get(term, term))
		var value: float = float(totals[term]) if percent else float(int(totals[term]))
		var side := Ledger.strike_side(term)
		# Does this term help THE STRIKE? A number on the actor helps when it is above the
		# identity; the same number on the target is the opponent's avoid or crit-avoid, so
		# it helps the strike when it is BELOW it.
		var above: bool = value > 1.0 if percent else value > 0.0
		(
			terms
			. append(
				{
					"term": term,
					"label": label,
					# `value` is the composed MULTIPLIER for a percent term (3.0), not the
					# authored percent (300). A consumer reading "×%s" off a row must not have
					# to know the ledger's storage units to render it. It is always signed as
					# the AUTHOR wrote it, never flipped to suit the strike — `helps` carries
					# the sense, so a tester reading a row sees the authored number.
					"value": value,
					"percent": percent,
					"on": side,
					"helps": above if side == "actor" else not above,
					"text": _term_text(label, value, percent, side),
				}
			)
		)
	return terms


static func _term_text(label: String, value: float, percent: bool, side: String) -> String:
	var body: String
	if percent:
		# Whole multipliers read as "×3" and fractional ones as "×1.5"; the trailing-zero
		# trim is why this is not a bare "%.2f", which would print the triangle's ×3 as
		# "×3.00" beside a "+10 Hit".
		body = "×%s %s" % [_trim_number(value), label]
	else:
		body = "%+d %s" % [int(value), label]
	# The bearer is named only when it is the OPPONENT, because the unnamed case is the
	# common one and "(opponent)" on every line would be noise. "Opponent" rather than
	# "defender": in the counter direction the target is the original attacker.
	return body if side == "actor" else "%s (opponent)" % body


static func _trim_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return String.num(value, 2).rstrip("0").rstrip(".")


# The one-line row text: the term changes, comma-separated, or the label alone when a
# profile applied something this readout has no number for. The glyph is NOT included — a
# surface decides whether it has room for one and how to colour it.
static func _summary(terms: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for term in terms:
		parts.append(String(term["text"]))
	return ", ".join(parts)


# Does this relationship help THE STRIKE? Read straight off each term's own `helps`, which
# already accounts for which combatant carries it — so this is a fold and not a second
# polarity decision that could disagree with the first. A profile doing both gets `mixed`
# rather than being rounded to whichever it does more of.
static func _direction(terms: Array[Dictionary]) -> String:
	var helps := false
	var hurts := false
	for term in terms:
		if bool(term["helps"]):
			helps = true
		else:
			hurts = true
	if helps and hurts:
		return DIRECTION_MIXED
	if helps:
		return DIRECTION_ADVANTAGE
	return DIRECTION_DISADVANTAGE if hurts else DIRECTION_NEUTRAL


static func _rule_ids(entries: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for entry in entries:
		var rule_id := String(entry.get("rule_id", ""))
		if rule_id != "" and not ids.has(rule_id):
			ids.append(rule_id)
	return ids


# Authoring provenance is useful while developing and debugging a campaign, but raw rule
# identifiers are not player-facing copy. A debug run is also how the editor exercises a
# project, so authors retain the exact IDs there while release/player builds do not leak
# the snake_case layer that produced the readable relationship label.
static func _show_authoring_rule_ids() -> bool:
	return OS.is_debug_build() or OS.has_feature("editor")


# THE MORE INFO BODY, GENERATED. `[ITR-6]` is explicit that
# `MoreInfoContent.COMBAT_FIELDS["triangle"]` is "generated from the authored data in slice
# 6, not corrected in place" — and it had to be, because that string claimed a tome triangle
# the shipping table did not have. A hardcoded sentence about authored content is a sentence
# that is true until someone edits the pack. This one is derived from the resolution every
# time, so it cannot be false about the fight it is describing.
static func _detail(
	label: String,
	rule_ids: Array[String],
	summary: String,
	record: Dictionary,
	show_authoring_rule_ids: bool = false,
	suppressed_labels: Array[String] = []
) -> String:
	var lines: Array[String] = []
	lines.append(
		"%s — an interaction this campaign's data declares, not a rule of the engine." % label
	)
	if summary != "":
		lines.append("Applies to this combatant: %s." % summary)
	if not suppressed_labels.is_empty():
		lines.append("Overrides in this fight: %s." % ", ".join(suppressed_labels))
	if show_authoring_rule_ids and not rule_ids.is_empty():
		lines.append("Matched: %s." % ", ".join(rule_ids))
	var policy := String(record.get("stack_policy", ""))
	var group := String(record.get("stack_group", ""))
	if show_authoring_rule_ids and group != "" and policy != "":
		lines.append("Simultaneous matches in '%s' compose by '%s'." % [group, policy])
	# A profile can both apply something and have another of its rules removed — reaver
	# suppressing one arm of a triangle while another applies is exactly that. The reason is
	# the resolver's own sentence, so this never paraphrases a decision it did not make.
	if not show_authoring_rule_ids:
		return "\n".join(lines)
	for suppressed in record.get("suppressed_rules", []):
		var entry := suppressed as Dictionary
		var by: Dictionary = (
			(entry.get("by", {}) as Dictionary) if entry.get("by") is Dictionary else {}
		)
		var reason := String(by.get("reason", "was removed"))
		var source := String(by.get("profile_id", ""))
		lines.append(
			"'%s' did not apply: '%s' %s it." % [String(entry.get("rule_id", "")), source, reason]
		)
	return "\n".join(lines)


# The player-facing name. An authored `label_key` is a LOCALISATION key, so it goes through
# the translation server — and when nothing has translated it, `tr()` hands the key straight
# back. Showing the player "interaction.weapon_triangle" would be the wrong failure, so an
# untranslated key falls back to its last segment, humanised. The authored value is still
# the thing being read: the moment a translation exists this returns it with no change here.
static func _label(profile_id: String, presentation: Dictionary) -> String:
	var key := String(presentation.get("label_key", ""))
	if key != "":
		var translated := String(TranslationServer.translate(key))
		if translated != key and translated != "":
			return translated
		return _humanise(key.get_slice(".", key.get_slice_count(".") - 1))
	return _humanise(profile_id)


# `String.capitalize()` already turns `weapon_triangle` into `Weapon Triangle`; hyphens are
# normalised first because it leaves those alone and an id may use either.
static func _humanise(id: String) -> String:
	return id.replace("-", "_").capitalize()
