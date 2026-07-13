extends Node
# Combat math engine. resolve_combat() returns a result dict; HP, weapon durability,
# and EXP are not applied to units until apply_combat_result() is called.
# NOTE: this is not fully side-effect-free — the skill triggers fired during
# resolve_combat (on_combat_start / on_combat_end / on_damaged) DO mutate unit state
# (e.g. active_modifiers, skill_use_counters). preview_combat() snapshots and restores
# unit state around exactly these writes so the forecast leaves no trace.
#
# RNG: all rolls draw from the per-event RNG in context["rng"] (RngService,
# RNG-1) in the CANONICAL ROLL ORDER — per strike: the hit resolver's fixed
# rn_count of 0-99 draws, then a crit draw only on a hit, then skill-activation
# draws at their trigger slots. Reordering is save/replay-breaking. Authority:
# AGENT/Docs/design/rng_determinism_design_2026-06-11.md §5.
#
# ── Combat Context Dictionary Schema ────────────────────────────────────────
# Built by _build_combat_context(); extended by skills during trigger processing.
# All keys present from construction unless marked [skill-added].
#
#   "attacker"              Node         — initiating unit (may be null in some previews)
#   "defender"              Node         — defending unit
#   "attacker_weapon"       WeaponData   — attacker's equipped weapon (null if unarmed)
#   "defender_weapon"       WeaponData   — defender's equipped weapon (null if can't ctr)
#   "attacker_support"      Node         — attacker's Pair Up support partner (null when
#                                          attacker is unpaired or registry/GameState absent).
#                                          The on-map combatant is always the lead per
#                                          design Q2, so this is the off-map partner.
#   "defender_support"      Node         — defender's Pair Up support partner (same shape
#                                          as attacker_support).
#   "attacker_faction"      String       — attacker's faction id ("blue", "red", …; "" if attacker null).
#                                          M14 stage 1 replacement for the old `is_player_initiated` bool —
#                                          a literal "player"-team check meant nothing in red-vs-yellow
#                                          combat. Skills wanting "did the player initiate?" check
#                                          attacker_faction against the active controlling faction; skills
#                                          wanting "am I the initiator?" should compare against
#                                          `context.attacker` directly (no faction needed).
#   "turn_number"           int          — GameState.turn_number at combat start
#   "rng"                   RandomNumberGenerator — the event's private RNG, seeded by
#                                          RngService.begin_event("attack", record). ALL
#                                          combat/skill rolls must draw from it (RNG-1).
#                                          Set by resolve_combat(); absent in previews.
#   "hit_formula"           String       — hit-roll resolver id ("two_roll"/"single_roll",
#                                          CRR-2/CRR-4). Set by resolve_combat().
#   "atk_mod"               Dictionary   — attacker modifiers:
#       "accuracy"          int          — flat hit modifier
#       "damage"            int          — flat damage modifier
#       "crit"              int          — flat crit modifier
#       "crit_avoid"        int          — flat crit-avoid modifier
#       "dodge"             int          — flat dodge modifier
#       "strikes"           int          — extra attack count
#       "damage_multiplier" float        — multiplicative damage scale (default 1.0)
#   "def_mod"               Dictionary   — same structure as "atk_mod" for the defender
#   "flags"                 Dictionary   — combat flag overrides:
#       "vantage"               bool     — defender attacks first
#       "skip_effectiveness"    bool     — ignore weapon effectiveness
#       "attacker_ignores_def"  float    — fraction of defender's DEF ignored (0.0–1.0)
#       "attacker_ignores_res"  float    — fraction of defender's RES ignored
#       "defender_ignores_def"  float    — fraction of attacker's DEF ignored (unused currently)
#       "defender_ignores_res"  float    — fraction of attacker's RES ignored (unused currently)
#       "lifesteal_pct"         float    — fraction of damage healed back to attacker
#       "vengeance_bonus"       int      — flat damage added from Vengeance skill
#
# Keys added by skills during trigger processing [skill-added]:
#   "defender_skills_blocked"   bool     — nihil: skip the defender's on_combat_start modifier skills
#   "attacker_skills_blocked"   bool     — nihil: skip the attacker's on_combat_start modifier skills
#                                          (also checked per-strike for on_attack/on_hit/on_kill)
#   "effectiveness_mult"        float    — computed once in _collect_combat_modifiers
# ─────────────────────────────────────────────────────────────────────────────

# EXP table from GDD_02: index = clamp(attacker_level - defender_level + 6, 0, 12)
const _EXP_TABLE: Array = [
	[59, 20], [57, 19], [53, 18], [47, 16], [41, 14], [35, 12],
	[30, 10],  # index 6 = equal level
	[25, 8], [19, 6], [13, 4], [7, 2], [3, 1], [1, 0],
]

# Weapon types that always lose durability (hit or miss) per GDD_02.
const _ALWAYS_USE_DURABILITY: Array[String] = [
	"bow", "fire", "thunder", "wind", "light", "dark", "staff",
]


# ── Hit-Roll Resolver Seam (CRR-2) ──────────────────────────────────────────
# The engine draws a resolver-declared, FIXED rn_count of 0-99 integers from the
# event RNG in canonical order, then asks a pure predicate did_hit(hit, rns).
# The formula never draws RNs itself — that keeps the draw count outcome-
# independent (RNG-1) and replay/suspend/online-safe (CRR-7). Two built-ins is
# a bounded engine set, not a content-growth enum; promotion to an author
# registry is the Band 3 follow-on B3-COMBAT-ROLL-RESOLVER (CRR-8).

const DEFAULT_HIT_FORMULA := "two_roll"

# id -> {"rn_count": int, "predicate": Callable(displayed_hit, rns) -> bool}
var _hit_resolvers: Dictionary = {
	"two_roll":    {"rn_count": 2, "predicate": _hit_two_roll},
	"single_roll": {"rn_count": 1, "predicate": _hit_single_roll},
}


# RULE-001 default: hit when floor((r1 + r2) / 2) < displayed hit. GDScript
# integer division of non-negative ints IS the floor, so `/ 2` matches the rule.
static func _hit_two_roll(displayed_hit: int, rns: Array[int]) -> bool:
	return (rns[0] + rns[1]) / 2 < displayed_hit


# Classic single-RN true-odds roll.
static func _hit_single_roll(displayed_hit: int, rns: Array[int]) -> bool:
	return rns[0] < displayed_hit


# How many 0-99 draws the resolver consumes per strike (always consumed, even
# on a miss — the roll order must never depend on the outcome).
func hit_rn_count(formula: String) -> int:
	return _hit_resolvers.get(formula, _hit_resolvers[DEFAULT_HIT_FORMULA])["rn_count"]


# Pure hit predicate — public so the T7 roll-order fixtures can assert each
# built-in's literal outcomes without running a full combat.
func did_hit(formula: String, displayed_hit: int, rns: Array[int]) -> bool:
	var resolver: Dictionary = _hit_resolvers.get(
		formula, _hit_resolvers[DEFAULT_HIT_FORMULA])
	return resolver["predicate"].call(displayed_hit, rns)


# CampaignRules.hit_formula selects the resolver (CRR-4; campaign-default
# scope). GameState.campaign_rules lands with the Slice 6 CampaignRules
# consolidation — until then gs.get() returns null and the default applies.
func _current_hit_formula() -> String:
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	if gs != null:
		var rules: Variant = gs.get("campaign_rules")
		if rules != null:
			var formula: Variant = rules.get("hit_formula")
			if formula is String and _hit_resolvers.has(formula):
				return formula
	return DEFAULT_HIT_FORMULA


# ── RNG Event Records (design §3) ───────────────────────────────────────────

# Canonical "attack" event record: [attacker_id, from_tile, to_tile, defender_id]
# with tiles as "x,y" internal 0-based coords. from_tile is the PRE-MOVE tile
# (TurnManager.get_action_start_tile) so a unit's chosen destination changes its
# own dice, per the ratified every-committed-action rule.
func make_attack_event_record(attacker: Node, defender: Node,
		from_tile: Vector2i) -> Array[String]:
	var atk_id: String = attacker.data.unit_id \
		if attacker != null and attacker.data != null else "-"
	var def_id: String = defender.data.unit_id \
		if defender != null and defender.data != null else "-"
	var to_tile: Vector2i = attacker.tile_position if attacker != null else Vector2i.ZERO
	return [
		atk_id,
		"%d,%d" % [from_tile.x, from_tile.y],
		"%d,%d" % [to_tile.x, to_tile.y],
		def_id,
	]


# ── Context Construction ─────────────────────────────────────────────────────

# Builds the initial context dict with zero modifiers and default flags.
# Both resolve_combat() and preview_combat() call this first.
func _build_combat_context(attacker: Node, defender: Node) -> Dictionary:
	var aw: WeaponData = attacker.get_equipped_weapon() if attacker else null
	var can_ctr := can_counterattack(defender, attacker.tile_position) if attacker else false
	var dw: WeaponData = defender.get_equipped_weapon() if (defender and can_ctr) else null
	var gs := get_node_or_null("/root/GameState")
	return {
		"attacker":            attacker,
		"defender":            defender,
		"attacker_weapon":     aw,
		"defender_weapon":     dw,
		"attacker_support":    _resolve_pair_partner(attacker),
		"defender_support":    _resolve_pair_partner(defender),
		"attacker_faction":    attacker.team if attacker != null else "",
		"turn_number":         gs.turn_number if gs else 0,
		"atk_mod": {"accuracy": 0, "damage": 0, "crit": 0, "crit_avoid": 0,
			"dodge": 0, "strikes": 0, "damage_multiplier": 1.0},
		"def_mod": {"accuracy": 0, "damage": 0, "crit": 0, "crit_avoid": 0,
			"dodge": 0, "strikes": 0, "damage_multiplier": 1.0},
		"flags": {
			"vantage":              false,
			"skip_effectiveness":   false,
			"attacker_ignores_def": 0.0,
			"attacker_ignores_res": 0.0,
			"defender_ignores_def": 0.0,
			"defender_ignores_res": 0.0,
			"lifesteal_pct":        0.0,
			"vengeance_bonus":      0,
		}
	}


# Looks up a combatant's Pair Up support partner via PairUpRegistry and
# GameState. Returns null when the unit is unpaired, when its data/unit_id is
# missing, when either autoload is absent, or when the partner is not currently
# registered. Step 4 will layer the bonus resolver on top of this lookup.
func _resolve_pair_partner(unit: Node) -> Node:
	if unit == null or unit.data == null or unit.data.unit_id == "":
		return null
	if not is_inside_tree():
		return null
	var reg := get_node_or_null("/root/PairUpRegistry")
	if reg == null:
		return null
	var partner_id: String = reg.call("get_partner_id", unit.data.unit_id)
	if partner_id == "":
		return null
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return null
	return gs.call("find_unit_by_id", partner_id)


# Populates atk_mod/def_mod/flags from all sources before the first attack.
# Steps: (1) Pair Up support bonuses (so subsequent passes see them as live
# active_modifiers); (2) UnitData.active_modifiers; (3) aura skills from all
# other units; (4) equip-type inventory items; (5) on_combat_start triggers.
# preview = true forwards to SkillHandler so the forecast skips random-activation
# skills (see SkillHandler.apply_trigger).
# dry_run = true (passed by preview_combat) tells SkillHandler not to persist any
# limited-use skill counters — so opening a preview never burns a skill's uses.
func _collect_combat_modifiers(context: Dictionary, preview: bool = false,
		dry_run: bool = false) -> void:
	var attacker: Node = context["attacker"]
	var defender: Node = context["defender"]
	var sh := get_node_or_null("/root/SkillHandler")
	var gs := get_node_or_null("/root/GameState")
	# Scope max_uses_per_combat to this fight — reset before any skill fires.
	if sh:
		sh.reset_combat_uses()
	# Pair Up bonuses: apply BEFORE _apply_unit_data_modifiers so the support's
	# contribution flows through get_effective_stat (and through the modifier
	# pass) like any other temporary stat buff. clear_combat_modifiers() at the
	# end of combat removes them again.
	_apply_pair_up_bonuses(attacker, context.get("attacker_support"))
	_apply_pair_up_bonuses(defender, context.get("defender_support"))
	_apply_unit_data_modifiers(attacker, context["atk_mod"])
	_apply_unit_data_modifiers(defender, context["def_mod"])
	# Aura skills from every other living unit on the map. Not gated by Nihil — these
	# fire before the negate pre-pass and pass no skills_blocked flag (see _apply_nihil).
	if sh and gs:
		for u in gs.all_units:
			if is_instance_valid(u) and u.data != null and u.data.hp > 0 \
					and u != attacker and u != defender:
				context = sh.apply_trigger(u, "on_combat_apply_modifiers", context,
					preview, false, dry_run)
	_apply_equip_item_modifiers(attacker, context["atk_mod"])
	_apply_equip_item_modifiers(defender, context["def_mod"])
	if sh:
		# Negate pre-pass: Nihil (and any future skill-canceller) resolves the
		# *_skills_blocked flags BEFORE any modifier skill runs, so a Nihil bearer
		# negates the opponent whether it is attacking or defending. A single
		# attacker-then-defender on_combat_start pass would let the attacker's
		# modifier skills apply before a defending Nihil could block them.
		context = sh.apply_trigger(attacker, "on_combat_start_negate", context,
			preview, false, dry_run)
		context = sh.apply_trigger(defender, "on_combat_start_negate", context,
			preview, false, dry_run)
		# Modifier pass: each side's on_combat_start skills. When the opponent's Nihil
		# blocked this side, apply_trigger still fires the Nihil-exempt skills (see
		# SkillHandler.NIHIL_EXEMPT_SKILLS) and skips the rest.
		context = sh.apply_trigger(attacker, "on_combat_start", context, preview,
			context.get("attacker_skills_blocked", false), dry_run)
		context = sh.apply_trigger(defender, "on_combat_start", context, preview,
			context.get("defender_skills_blocked", false), dry_run)


func _apply_unit_data_modifiers(unit: Node, mod_dict: Dictionary) -> void:
	if unit == null or unit.data == null:
		return
	for m in unit.data.active_modifiers:
		match m.get("stat", ""):
			"accuracy": mod_dict["accuracy"] += m.get("delta", 0)
			"damage":   mod_dict["damage"]   += m.get("delta", 0)
			"crit":     mod_dict["crit"]     += m.get("delta", 0)
			"dodge":    mod_dict["dodge"]    += m.get("delta", 0)


# Pair Up bonus application — queries PairUpBonusResolver and stamps each
# non-zero stat as a duration_type="combat" modifier on the combatant. These
# are cleared by Unit.clear_combat_modifiers() at the end of combat (see the
# tail of apply_combat_result). Reads via get_effective_stat in the damage /
# accuracy formulas pick them up automatically — no per-stat translation
# table needed here.
func _apply_pair_up_bonuses(combatant: Node, support: Node) -> void:
	if combatant == null or support == null or support.data == null:
		return
	if not combatant.has_method("add_modifier"):
		return
	var resolver := get_node_or_null("/root/PairUpBonusResolver")
	if resolver == null:
		return
	var bonuses: Dictionary = resolver.call("bonuses_for", support)
	if bonuses.is_empty():
		return
	for stat_key in bonuses.keys():
		var stat: String = String(stat_key)
		var delta: int = int(bonuses[stat])
		if delta == 0:
			continue
		# Distinct source PER STAT. add_modifier() calls remove_modifier(source)
		# first, so a shared source made each stat wipe the previous one — only the
		# last bonus (luck) survived, which is why a paired lead's damage never
		# changed (playtest v0.1.4 #8.5). Same lesson SkillHandler's Resolve already
		# encodes. clear_combat_modifiers() removes them by duration_type="combat",
		# not source, so unique sources still get cleared after the fight.
		var source: String = "pair_up:%s:%s" % [support.data.unit_id, stat]
		# duration -1 = no auto-decrement; duration_type="combat" ensures
		# clear_combat_modifiers() removes the modifier after the fight.
		combatant.add_modifier(stat, delta, source, -1, "combat")


func _apply_equip_item_modifiers(unit: Node, mod_dict: Dictionary) -> void:
	if unit == null or unit.data == null:
		return
	for entry in unit.data.inventory:
		if not entry.is_equip():
			continue
		mod_dict["accuracy"] += entry.accuracy
		mod_dict["damage"]   += entry.damage
		mod_dict["crit"]     += entry.crit
		mod_dict["dodge"]    += entry.dodge


# ── Weapon Triangle ──────────────────────────────────────────────────────────

func _get_triangle_result(aw: WeaponData, dw: WeaponData) -> String:
	if aw == null or dw == null:
		return "neutral"
	var atype: String = aw.get_triangle_family()
	var dtype: String = dw.get_triangle_family()
	if GameConstants.WEAPON_TRIANGLE.has(atype):
		var row: Dictionary = GameConstants.WEAPON_TRIANGLE[atype]
		if row.has(dtype):
			return row[dtype]
	return "neutral"


func _triangle_accuracy(attacker: Node, defender: Node) -> int:
	var aw: WeaponData = attacker.get_equipped_weapon() if attacker else null
	var dw: WeaponData = defender.get_equipped_weapon() if defender else null
	var result := _get_triangle_result(aw, dw)
	return 10 if result == "advantage" else (-10 if result == "disadvantage" else 0)


func _triangle_damage(attacker: Node, defender: Node) -> int:
	var aw: WeaponData = attacker.get_equipped_weapon() if attacker else null
	var dw: WeaponData = defender.get_equipped_weapon() if defender else null
	var result := _get_triangle_result(aw, dw)
	return 2 if result == "advantage" else (-2 if result == "disadvantage" else 0)


# ── Effectiveness ────────────────────────────────────────────────────────────

# Returns true when the weapon has an effectiveness tag matching a target quality.
# Used as a fallback when compute_damage is called without a context dict.
func _is_effective(weapon: WeaponData, target: Node) -> bool:
	if weapon == null or target == null:
		return false
	for tag in weapon.effect_tags:
		match tag:
			GameConstants.TAG_EFFECTIVE_FLYING:
				if _target_has_vulnerability(target, "flying"):
					return true
			GameConstants.TAG_EFFECTIVE_ARMOURED:
				if _target_has_vulnerability(target, "armoured"):
					return true
			GameConstants.TAG_EFFECTIVE_MOUNTED:
				if _target_has_vulnerability(target, "mounted"):
					return true
			GameConstants.TAG_EFFECTIVE_DRAGON:
				if _target_has_vulnerability(target, "dragon"):
					return true
			GameConstants.TAG_EFFECTIVE_BEAST:
				if _target_has_vulnerability(target, "beast"):
					return true
	return false


func _target_has_vulnerability(target: Node, group: String) -> bool:
	# has_quality (the unit IS X) and has_vulnerability (the unit is HIT BY X)
	# read different ClassData fields, so the old "fall back to has_quality"
	# path could silently return the wrong answer for an armoured class with
	# an empty vulnerability_groups list. Every Unit instance now defines
	# has_vulnerability, so the fallback is dead and was also incorrect —
	# drop it (code review 2026-06-10 issue 2.8).
	return target.has_method("has_vulnerability") and target.has_vulnerability(group)


# Returns 1.0 normally; 3.0 for effective weapon vs target; 4.0 with Giantkiller.
# Returns 1.0 if context.flags.skip_effectiveness is set (Dragonskin / Nullify).
# actor is the unit firing this attack (may differ from context["attacker"] on counter).
func _get_effectiveness_multiplier(weapon: WeaponData, target: Node,
		context: Dictionary, actor: Node = null) -> float:
	if context["flags"]["skip_effectiveness"]:
		return 1.0
	if not _is_effective(weapon, target):
		return 1.0
	# Use the actual attacker in this exchange so a defending Giantkiller gets the 4× too.
	var check_unit: Node = actor if actor != null else context["attacker"]
	if check_unit != null and check_unit.has_method("has_skill") \
			and check_unit.has_skill("giantkiller"):
		return 4.0
	return 3.0


# ── Core Stat Computations ───────────────────────────────────────────────────
# context keys read: "accuracy_bonus" (+hit), "dodge_bonus" (+defender dodge)

func compute_hit_pct(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	if w == null:
		return 0
	var acc: int = attacker.accuracy(w) + _triangle_accuracy(attacker, defender) \
		+ context.get("accuracy_bonus", 0)
	var dodge: int = defender.dodge() + defender.get_terrain_dodge_bonus() \
		+ context.get("dodge_bonus", 0)
	return clampi(acc - dodge, 0, 100)


# context keys read: "damage_bonus", "effectiveness_mult" (default: auto-computed),
# "ignore_def_fraction" (0.0–1.0, for Luna etc.)
func compute_damage(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	if w == null:
		return 0
	# Use provided effectiveness or compute from tags (backward compat for direct test calls)
	var eff_mult: float = context.get("effectiveness_mult",
		3.0 if _is_effective(w, defender) else 1.0)
	var mt: int = int(w.mt * eff_mult)
	# Use get_effective_stat so temporary stat modifiers (e.g. Resolve) are reflected in damage.
	var base_stat: int
	if attacker.has_method("get_effective_stat"):
		base_stat = attacker.get_effective_stat("magic") if w.uses_mag \
			else attacker.get_effective_stat("strength")
	else:
		base_stat = attacker.data.magic if w.uses_mag else attacker.data.strength
	var atk: int = base_stat + mt \
		+ _triangle_damage(attacker, defender) + context.get("damage_bonus", 0)
	var def_stat: int
	if defender.has_method("get_effective_stat"):
		def_stat = defender.get_effective_stat("resistance") if w.uses_mag \
			else defender.get_effective_stat("defense")
	else:
		def_stat = defender.data.resistance if w.uses_mag else defender.data.defense
	var ignore_frac: float = context.get("ignore_def_fraction", 0.0)
	var effective_def: int = int(def_stat * (1.0 - ignore_frac))
	var def_bonus: int = defender.get_terrain_def_bonus()
	return maxi(0, atk - effective_def - def_bonus)


# context keys read: "crit_bonus" (net modifier, attacker crit mod minus defender crit_avoid mod)
func compute_crit_pct(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	return clampi(attacker.crit_rate(w) - defender.crit_avoid() \
		+ context.get("crit_bonus", 0), 0, 100)


# ── Sequence Logic ───────────────────────────────────────────────────────────

func can_counterattack(defender: Node, attacker_tile: Vector2i) -> bool:
	var w: WeaponData = defender.get_equipped_weapon()
	if w == null:
		return false
	# Healing staves cannot counterattack — they are gated to the Staff action.
	if w.is_healing_staff():
		return false
	var dist: int = absi(defender.tile_position.x - attacker_tile.x) \
		+ absi(defender.tile_position.y - attacker_tile.y)
	return dist >= w.get_range_min(defender) and dist <= w.get_range_max(defender)


func get_follow_up_attacker(a: Node, b: Node) -> Node:
	if a == null or b == null:
		return null
	var spd_a: int = a.battle_speed()
	var spd_b: int = b.battle_speed()
	if spd_a - spd_b >= GameConstants.FOLLOW_UP_SPEED_THRESHOLD:
		return a
	if spd_b - spd_a >= GameConstants.FOLLOW_UP_SPEED_THRESHOLD:
		return b
	return null


# ── EXP ─────────────────────────────────────────────────────────────────────

func calculate_exp(attacker: Node, defender: Node, killed: bool) -> int:
	# DEBUG TESTING AID (#10) — debug builds only; remove before release, see
	# GDD_10_Roadmap.md § Pre-Release Cleanup. When GameState.debug_force_levelup
	# is on, any landed hit returns a full 100 EXP so a level-up fires at once.
	if OS.is_debug_build():
		var gs := get_node_or_null("/root/GameState")
		if gs != null and gs.get("debug_force_levelup"):
			return 100
	var diff: int = attacker.data.level - defender.data.level
	var idx: int = clampi(diff + 6, 0, 12)
	return _EXP_TABLE[idx][0] if killed else _EXP_TABLE[idx][1]


# ── Single-Attack Resolution ─────────────────────────────────────────────────

# Resolves one attack roll. is_counter=true means actor is the defending side.
# target_sim_hp is needed for Miracle to check whether the blow is lethal.
# Returns { attacker, defender, weapon, hit, crit, damage, loses_durability, is_counter }
func _resolve_single_attack(actor: Node, target: Node, context: Dictionary,
		is_counter: bool, target_sim_hp: int) -> Dictionary:
	var sh := get_node_or_null("/root/SkillHandler")
	var weapon: WeaponData = context["defender_weapon"] if is_counter else context["attacker_weapon"]
	var actor_mod: Dictionary = context["def_mod"] if is_counter else context["atk_mod"]
	var target_mod: Dictionary = context["atk_mod"] if is_counter else context["def_mod"]
	var blocked_key: String = "defender_skills_blocked" if is_counter else "attacker_skills_blocked"

	if sh:
		sh.apply_trigger(actor, "on_attack", context, false, context.get(blocked_key, false))

	var hit_ctx := {
		"accuracy_bonus": actor_mod["accuracy"],
		"dodge_bonus":    target_mod["dodge"],
	}
	var eff_mult: float = _get_effectiveness_multiplier(weapon, target, context, actor)
	var ignore_key: String = "defender_ignores_def" if is_counter else "attacker_ignores_def"
	var dmg_ctx := {
		"damage_bonus":       actor_mod["damage"],
		"effectiveness_mult": eff_mult,
		"ignore_def_fraction": context["flags"].get(ignore_key, 0.0),
	}
	var crit_ctx := {
		"crit_bonus": actor_mod["crit"] - target_mod["crit_avoid"],
	}

	var hit_pct  := compute_hit_pct(actor, target, weapon, hit_ctx)
	var crit_pct := compute_crit_pct(actor, target, weapon, crit_ctx)
	var base_dmg := compute_damage(actor, target, weapon, dmg_ctx)

	# Hit roll via the resolver seam (CRR-2): draw the resolver's FIXED rn_count
	# from the event RNG in canonical order (§5), then ask the pure predicate.
	# All draws are consumed even on a miss so roll order never depends on outcome.
	var rng: RandomNumberGenerator = context["rng"]
	var formula: String = context.get("hit_formula", DEFAULT_HIT_FORMULA)
	var hit_rns: Array[int] = []
	for _i in hit_rn_count(formula):
		hit_rns.append(rng.randi_range(0, 99))  # rng-allow: draw from the RngService event RNG (RNG-1)
	var strike_hit: bool = did_hit(formula, hit_pct, hit_rns)
	var did_crit: bool = false
	var damage: int    = 0

	if strike_hit:
		if sh:
			sh.apply_trigger(actor, "on_hit", context, false, context.get(blocked_key, false))
		# Crit stays a single draw, only after a hit (§5; CRR-6 reserves the
		# resolver family for crit/activation later).
		did_crit = rng.randi_range(0, 99) < crit_pct  # rng-allow: draw from the RngService event RNG (RNG-1)
		damage = base_dmg * 3 if did_crit else base_dmg
		var dmg_mult: float = actor_mod["damage_multiplier"]
		if dmg_mult != 1.0:
			damage = maxi(0, int(damage * dmg_mult))

		# on_damaged trigger (Miracle uses current_sim_hp to detect lethal hits)
		if sh:
			var is_target_blocked: bool = context.get(
				"attacker_skills_blocked" if is_counter else "defender_skills_blocked", false)
			# Carries the event RNG so on_damaged activation rolls (Miracle)
			# stay in this event's canonical draw sequence (§5).
			var dmg_ctx2 := {
				"damage": damage, "current_sim_hp": target_sim_hp,
				"unit": target, "attacker": actor, "defender": target, "weapon": weapon,
				"rng": rng,
			}
			# Nihil-blocked target: apply_trigger fires only NIHIL_EXEMPT_SKILLS.
			dmg_ctx2 = sh.apply_trigger(target, "on_damaged", dmg_ctx2, false, is_target_blocked)
			damage = dmg_ctx2.get("damage", damage)

	# on_kill
	if strike_hit and damage >= target_sim_hp and sh:
		sh.apply_trigger(actor, "on_kill", context, false, context.get(blocked_key, false))

	var loses_use: bool = false
	if weapon != null:
		loses_use = (weapon.combat_family in _ALWAYS_USE_DURABILITY) or strike_hit

	return {
		"attacker":        actor,
		"defender":        target,
		"weapon":          weapon,
		"hit":             strike_hit,
		"crit":            did_crit,
		"damage":          damage,
		"loses_durability": loses_use,
		"is_counter":      is_counter,
	}


# ── Weapon Durability (simulated) ────────────────────────────────────────────

# Remaining uses of a unit's equipped weapon, read from its InventoryEntry.
# Returns -1 (infinite / unknown) when the unit can't report an entry — such weapons
# never break mid-combat.
func _equipped_weapon_uses(unit: Node) -> int:
	if unit == null or not unit.has_method("get_equipped_weapon_entry"):
		return -1
	var entry = unit.get_equipped_weapon_entry()
	if entry == null:
		return -1
	return entry.uses_remaining


# Resolves one strike and decrements simulated weapon durability. Returns the exchange,
# or an empty dict when the actor's weapon has already broken — the caller stops the
# series. Modelling breakage here (rather than only in apply_combat_result) means the
# skill triggers fired inside _resolve_single_attack run only for attacks that actually
# happen, never for exchanges a later weapon break would discard.
func _resolve_strike(actor: Node, target: Node, context: Dictionary, is_counter: bool,
		target_sim_hp: int, weapon_uses: Dictionary, broken: Dictionary) -> Dictionary:
	if broken.get(actor, false):
		return {}
	var ex := _resolve_single_attack(actor, target, context, is_counter, target_sim_hp)
	if ex["loses_durability"]:
		var remaining: int = weapon_uses.get(actor, -1)
		if remaining != -1:
			remaining -= 1
			weapon_uses[actor] = remaining
			if remaining <= 0:
				broken[actor] = true
	return ex


# ── Preview (no RNG, no side effects) ────────────────────────────────────────

# Snapshot the mutable UnitData fields that any on_combat_start skill could touch.
# Restored after _collect_combat_modifiers() so preview has zero side effects on live state.
func _snapshot_unit_state(unit: Node) -> Dictionary:
	if unit == null or unit.data == null:
		return {}
	return {
		"hp":                   unit.data.hp,
		"active_modifiers":     unit.data.active_modifiers.duplicate(true),
		"skill_use_counters":   unit.data.skill_use_counters.duplicate(true),
		"damage_taken_this_map": unit.data.damage_taken_this_map,
	}


func _restore_unit_state(unit: Node, snap: Dictionary) -> void:
	if unit == null or unit.data == null or snap.is_empty():
		return
	unit.data.hp                    = snap["hp"]
	unit.data.active_modifiers      = snap["active_modifiers"]
	unit.data.skill_use_counters    = snap["skill_use_counters"]
	unit.data.damage_taken_this_map = snap["damage_taken_this_map"]


func preview_combat(attacker: Node, defender: Node) -> Dictionary:
	var atk_snap := _snapshot_unit_state(attacker)
	var def_snap := _snapshot_unit_state(defender)
	var context := _build_combat_context(attacker, defender)
	# preview = true: deterministic skills (Resolve, Wrath, Faire, …) apply so the
	# forecast is accurate; random-activation skills are excluded. The snapshot is
	# restored at the END of this function — AFTER every stat read below — so the
	# displayed numbers reflect the same modifier state resolve_combat() will use.
	# dry_run = true: SkillHandler does not persist limited-use counters for a preview.
	_collect_combat_modifiers(context, true, true)
	var aw: WeaponData = context["attacker_weapon"]
	var dw: WeaponData = context["defender_weapon"]
	var can_counter: bool = dw != null
	var follow_up := get_follow_up_attacker(attacker, defender)
	var atk_strikes: int = (aw.strikes_per_attack if aw else 1) + context["atk_mod"]["strikes"]
	var def_strikes: int = ((dw.strikes_per_attack if dw else 1) + context["def_mod"]["strikes"]) \
		if can_counter else 0

	var eff_atk: float = _get_effectiveness_multiplier(aw, defender, context, attacker)
	var eff_def: float = _get_effectiveness_multiplier(dw, attacker, context, defender) if can_counter else 1.0

	var atk_hit_ctx  := {"accuracy_bonus": context["atk_mod"]["accuracy"],
		"dodge_bonus": context["def_mod"]["dodge"]}
	var def_hit_ctx  := {"accuracy_bonus": context["def_mod"]["accuracy"],
		"dodge_bonus": context["atk_mod"]["dodge"]}
	var atk_dmg_ctx  := {"damage_bonus": context["atk_mod"]["damage"], "effectiveness_mult": eff_atk}
	var def_dmg_ctx  := {"damage_bonus": context["def_mod"]["damage"], "effectiveness_mult": eff_def}
	var atk_crit_ctx := {"crit_bonus": context["atk_mod"]["crit"] - context["def_mod"]["crit_avoid"]}
	var def_crit_ctx := {"crit_bonus": context["def_mod"]["crit"] - context["atk_mod"]["crit_avoid"]}

	# Triangle result from the attacker's perspective; the defender's result is
	# always the mirror (advantage <-> disadvantage, neutral stays neutral).
	# Exposed so the More Info preview can show a marker beside each side
	# without re-querying the triangle table.
	var atk_triangle: String = _get_triangle_result(aw, dw)
	var def_triangle: String = "neutral"
	match atk_triangle:
		"advantage":    def_triangle = "disadvantage"
		"disadvantage": def_triangle = "advantage"
	var result := {
		"attacker_hit":     compute_hit_pct(attacker, defender, aw, atk_hit_ctx),
		"attacker_damage":  compute_damage(attacker, defender, aw, atk_dmg_ctx),
		"attacker_crit":    compute_crit_pct(attacker, defender, aw, atk_crit_ctx),
		"attacker_attacks": (2 if follow_up == attacker else 1) * atk_strikes,
		"can_counter":      can_counter,
		"defender_hit":     compute_hit_pct(defender, attacker, dw, def_hit_ctx) if can_counter else 0,
		"defender_damage":  compute_damage(defender, attacker, dw, def_dmg_ctx) if can_counter else 0,
		"defender_crit":    compute_crit_pct(defender, attacker, dw, def_crit_ctx) if can_counter else 0,
		"defender_attacks": ((2 if follow_up == defender else 1) * def_strikes) if can_counter else 0,
		"attacker_weapon":  aw,
		"defender_weapon":  dw,
		# Battle Speed of each side (effective, i.e. with combat modifiers applied —
		# the snapshot is restored after this dict is built). Surfaced so the UI can
		# show the follow-up math the tester couldn't otherwise verify (handbook 8.3).
		# A side needs FOLLOW_UP_SPEED_THRESHOLD more than its opponent to double.
		"attacker_battle_speed": attacker.battle_speed() if attacker and attacker.has_method("battle_speed") else 0,
		"defender_battle_speed": defender.battle_speed() if defender and defender.has_method("battle_speed") else 0,
		"follow_up_threshold":   GameConstants.FOLLOW_UP_SPEED_THRESHOLD,
		# True when Vantage will make the defender strike first — the strike counts
		# above are unaffected, but the exchange order is, so the UI surfaces it.
		"defender_vantage": context["flags"]["vantage"],
		# Phase 1 More Info preview fields. _effective is a bool for the UI
		# marker; _mult is the float multiplier (1.0 / 3.0 / 4.0 for Giantkiller)
		# so the description panel can show "Effective ×3" without recomputing.
		"attacker_triangle":           atk_triangle,
		"defender_triangle":           def_triangle,
		"attacker_effective":          eff_atk > 1.0,
		"defender_effective":          can_counter and eff_def > 1.0,
		"attacker_effectiveness_mult": eff_atk,
		"defender_effectiveness_mult": eff_def if can_counter else 1.0,
	}
	# All stat reads are done — restore now so preview leaves no trace on live state.
	_restore_unit_state(attacker, atk_snap)
	_restore_unit_state(defender, def_snap)
	return result


# ── Full RNG Resolution ──────────────────────────────────────────────────────

# Runs one actor's strike series against target — up to `strikes` attacks — appending
# each exchange to `exchanges`. Stops early when either side is dead (GDD_02:167: "if
# target HP ≤ 0, stop the exchange — no further attacks") or the actor's weapon broke.
# actor_sim_hp is read-only here (an actor never damages itself mid-series); checking it
# means a unit already felled in an earlier series — a Vantage counter-kill, or a
# defender the attacker just killed — never swings. Returns target's updated sim HP.
# This is the single guarded loop behind all four strike series, so the "is either side
# dead?" rule cannot drift between them.
func _run_strike_series(actor: Node, target: Node, context: Dictionary, is_counter: bool,
		strikes: int, actor_sim_hp: int, target_sim_hp: int,
		weapon_uses: Dictionary, broken: Dictionary, exchanges: Array,
		is_follow_up: bool = false) -> int:
	for _i in strikes:
		if actor_sim_hp <= 0 or target_sim_hp <= 0:
			break
		var ex := _resolve_strike(actor, target, context, is_counter, target_sim_hp, weapon_uses, broken)
		if ex.is_empty():
			break  # actor's weapon broke — stop the series
		if is_follow_up:
			ex["is_follow_up"] = true
		if ex["hit"]:
			target_sim_hp -= ex["damage"]
		exchanges.append(ex)
	return target_sim_hp


func resolve_combat(attacker: Node, defender: Node,
		event_record: Array[String] = []) -> Dictionary:
	# combat_started fires before any RNG is rolled — it marks the fight starting,
	# not the apply phase. preview_combat is the side-effect-free forecast and
	# must NOT emit this. See EventBus.gd signal comment (B2).
	var bus := get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.combat_started.emit(attacker, defender)

	# Seed this event's private RNG (RNG-1). Callers pass the canonical record
	# (with the real pre-move from_tile); direct/headless callers get a
	# deterministic fallback record built from the units' current tiles.
	var record: Array[String] = event_record
	if record.is_empty():
		record = make_attack_event_record(attacker, defender,
			attacker.tile_position if attacker != null else Vector2i.ZERO)
	var context := _build_combat_context(attacker, defender)
	context["hit_formula"] = _current_hit_formula()
	var rng_svc := get_node_or_null("/root/RngService") if is_inside_tree() else null
	if rng_svc != null:
		context["rng"] = rng_svc.begin_event("attack", record)
	else:
		# Suites that don't load the RngService autoload still resolve, on a
		# fixed-seed local RNG. Production always has the autoload.
		var fallback := RandomNumberGenerator.new()  # rng-allow: headless fallback when RngService is absent
		fallback.seed = 1
		context["rng"] = fallback
	_collect_combat_modifiers(context)
	var sh := get_node_or_null("/root/SkillHandler")

	var aw: WeaponData = context["attacker_weapon"]
	var dw: WeaponData = context["defender_weapon"]
	var can_counter: bool = dw != null
	var atk_strikes: int = (aw.strikes_per_attack if aw else 1) + context["atk_mod"]["strikes"]
	var def_strikes: int = ((dw.strikes_per_attack if dw else 1) + context["def_mod"]["strikes"]) \
		if can_counter else 0
	# Save original before vantage may zero it — follow-up uses the original count.
	var original_def_strikes: int = def_strikes
	var follow_up: Node = get_follow_up_attacker(attacker, defender)

	var exchanges: Array = []
	var atk_sim_hp: int = attacker.data.hp
	var def_sim_hp: int = defender.data.hp

	# Simulated weapon durability — breakage is modelled here, not bolted onto
	# apply_combat_result, so a unit whose weapon breaks mid-combat stops generating
	# exchanges (and stops firing skill triggers) instead of producing exchanges the
	# apply phase would have to discard. -1 = infinite / never breaks.
	var weapon_uses: Dictionary = {
		attacker: _equipped_weapon_uses(attacker),
		defender: _equipped_weapon_uses(defender),
	}
	var broken: Dictionary = {}  # Node -> true once that unit's weapon has broken

	# Vantage: defender attacks first (set by _apply_vantage in _collect_combat_modifiers)
	if context["flags"]["vantage"] and can_counter:
		atk_sim_hp = _run_strike_series(defender, attacker, context, true,
			def_strikes, def_sim_hp, atk_sim_hp, weapon_uses, broken, exchanges)
		def_strikes = 0  # defender's attacks are spent

	# Attacker's strikes
	def_sim_hp = _run_strike_series(attacker, defender, context, false,
		atk_strikes, atk_sim_hp, def_sim_hp, weapon_uses, broken, exchanges)

	# Defender counter (skipped if Vantage already spent the defender's strikes).
	# _run_strike_series guards the defender's own HP too, so a defender the attacker
	# just killed does not counterattack (GDD_02:167).
	if can_counter and def_strikes > 0:
		atk_sim_hp = _run_strike_series(defender, attacker, context, true,
			def_strikes, def_sim_hp, atk_sim_hp, weapon_uses, broken, exchanges)

	# Follow-up — loops over all strikes so Brave weapons get their full count.
	if follow_up != null:
		var fu_target: Node = defender if follow_up == attacker else attacker
		var fu_sim_hp: int  = atk_sim_hp if follow_up == attacker else def_sim_hp
		var tgt_sim_hp: int = def_sim_hp if follow_up == attacker else atk_sim_hp
		var fu_strikes: int = atk_strikes if follow_up == attacker else original_def_strikes
		var is_fu_counter: bool = (follow_up == defender)
		var new_tgt_hp: int = _run_strike_series(follow_up, fu_target, context, is_fu_counter,
			fu_strikes, fu_sim_hp, tgt_sim_hp, weapon_uses, broken, exchanges, true)
		if follow_up == attacker:
			def_sim_hp = new_tgt_hp
		else:
			atk_sim_hp = new_tgt_hp

	if sh:
		sh.apply_trigger(attacker, "on_combat_end", context)
		sh.apply_trigger(defender, "on_combat_end", context)

	var defender_died: bool = def_sim_hp <= 0
	var attacker_died: bool = atk_sim_hp <= 0
	var atk_dealt: bool = exchanges.any(func(e): return e["attacker"] == attacker and e["hit"])
	var def_dealt: bool = exchanges.any(func(e): return e["attacker"] == defender and e["hit"])

	# attacker_exp / defender_exp are NOT included here — they're computed by
	# apply_combat_result() from the exchanges that actually landed, then set on this dict.
	# rng_event_kind/record carry the event identity so apply_combat_result can
	# commit it to the RNG chain exactly once.
	return {
		"exchanges":        exchanges,
		"attacker_died":    attacker_died,
		"defender_died":    defender_died,
		"context":          context,
		"rng_event_kind":   "attack",
		"rng_event_record": record,
	}


# ── Apply Combat Result ──────────────────────────────────────────────────────

# Applies the result from resolve_combat: HP changes, durability, EXP, wEXP, death.
# combat_started has already fired from resolve_combat (B2); apply emits only
# combat_resolved at the end.
func apply_combat_result(result: Dictionary, attacker: Node, defender: Node) -> void:
	var bus := get_node_or_null("/root/EventBus") if is_inside_tree() else null

	# resolve_combat() already modelled weapon breakage, so every exchange here is a
	# real attack — apply just commits durability/HP/EXP, with no skip logic.
	var atk_hit := false
	var def_hit := false

	for exchange in result["exchanges"]:
		var atk: Node          = exchange["attacker"]
		var def_unit: Node     = exchange["defender"]
		var weapon: WeaponData = exchange.get("weapon", null)
		var weapon_id: String  = weapon.id if weapon != null else ""

		if exchange["loses_durability"] and atk.has_method("use_weapon_durability"):
			atk.use_weapon_durability(weapon_id)

		if exchange["hit"]:
			if atk == attacker:
				atk_hit = true
			else:
				def_hit = true
			if weapon != null and atk.has_method("add_wexp"):
				atk.add_wexp(weapon.wexp_track, weapon.wexp)
			# Count HP actually lost, not the raw computed damage — take_damage clamps
			# at 0, so an overkill blow must not inflate damage_taken_this_map.
			var hp_before: int = def_unit.data.hp
			def_unit.take_damage(exchange["damage"])
			def_unit.data.damage_taken_this_map += hp_before - def_unit.data.hp
		# No break here — the full exchange list is iterated so both units can die
		# in a mutual-kill scenario and both get handle_death() called below.

	# Commit this attack to the RNG chain exactly once, BEFORE EXP/level-up —
	# levelup events must begin on the post-attack hash (design §4 ordering).
	# The once-guard lives on the result dict so a double apply cannot advance
	# the chain twice; TurnManager must never commit combat events itself.
	if not result.get("rng_committed", false):
		result["rng_committed"] = true
		var rng_svc := get_node_or_null("/root/RngService") if is_inside_tree() else null
		if rng_svc != null and result.has("rng_event_record"):
			rng_svc.commit_event(result.get("rng_event_kind", "attack"),
				result["rng_event_record"])

	# Derive death and EXP from final HP after every exchange is applied.
	var defender_died: bool = defender.data.hp <= 0
	var attacker_died: bool = attacker.data.hp <= 0
	result["defender_died"] = defender_died
	result["attacker_died"] = attacker_died
	var atk_exp: int = calculate_exp(attacker, defender, defender_died) if atk_hit else 0
	var def_exp: int = calculate_exp(defender, attacker, attacker_died) if def_hit else 0
	result["attacker_exp"] = atk_exp
	result["defender_exp"] = def_exp

	# Award EXP before calling handle_death (queue_free is deferred; nodes are still valid).
	if attacker.is_inside_tree() and atk_exp > 0 and not attacker_died:
		attacker.add_exp(atk_exp)
	if defender.is_inside_tree() and def_exp > 0 and not defender_died:
		defender.add_exp(def_exp)

	# Clear one-fight buffs from both sides after combat concludes.
	if attacker.has_method("clear_combat_modifiers"):
		attacker.clear_combat_modifiers()
	if defender.has_method("clear_combat_modifiers"):
		defender.clear_combat_modifiers()

	# Snapshot both contexts before either disposition runs, then preserve the
	# established defender-first deterministic resolution order.
	var death_group := ""
	if defender_died and attacker_died:
		death_group = "combat:%s:%s" % [
			str(attacker.data.get("unit_id")), str(defender.data.get("unit_id"))]
	var defender_ctx: RefCounted = null
	var attacker_ctx: RefCounted = null
	if defender_died:
		defender_ctx = DeathContextScript.from_subject(defender, "combat", "attack")
		defender_ctx.responsible_actor = attacker
		defender_ctx.simultaneous_group_id = death_group
	if attacker_died:
		attacker_ctx = DeathContextScript.from_subject(attacker, "combat", "counterattack")
		attacker_ctx.responsible_actor = defender
		attacker_ctx.simultaneous_group_id = death_group
	var lifecycle := get_node_or_null("/root/DeathLifecycle") if is_inside_tree() else null
	if defender_ctx != null:
		if lifecycle != null:
			lifecycle.handle_death(defender_ctx)
		elif defender.has_method("handle_death"):
			defender.handle_death()
	if attacker_ctx != null:
		if lifecycle != null:
			lifecycle.handle_death(attacker_ctx)
		elif attacker.has_method("handle_death"):
			attacker.handle_death()

	if bus:
		bus.combat_resolved.emit(attacker, defender, result)
# Explicit preload keeps headless parse independent of the global class cache.
const DeathContextScript = preload("res://scripts/death/DeathContext.gd")
