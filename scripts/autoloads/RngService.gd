extends Node
# RngService — deterministic gameplay dice (Package A Step 1, RNG-1..RNG-4).
#
# All gameplay dice derive from seed = mix(map_seed, history_hash, event_record).
# history_hash advances on every committed, non-undoable unit action; previews,
# equip, undone moves, and menu/cursor activity never touch it. Restoring the
# two ints (via to_save_dict/from_save_dict) restores the entire dice timeline.
#
# Contract: [GDD-01-RUNTIME-CONTRACTS] (§2-§5).
# Canonical roll order lives in §5; event-record formats in §3. Changing _mix,
# _hash_string, any record format, or the roll order is a SAVE-BREAKING change
# (§11) — do not "improve" the mixer.
#
# Cosmetic/presentation randomness must NOT use this service; give visual
# polish its own un-chained RNG so it can never perturb gameplay dice.

var map_seed: int = 0  # rolled once per map in start_map(); persisted
var history_hash: int = 0  # advances per committed action (RNG-1)


func start_map(seed_override: int = 0) -> void:
	# seed_override != 0 is the test/replay hook; 0 = roll a fresh seed.
	map_seed = seed_override if seed_override != 0 else _entropy_seed()
	history_hash = 0


# ── Event API ────────────────────────────────────────────────────────────────
# A dice-bearing action calls begin_event() to obtain its private RNG, draws
# every roll from it in canonical order (§5), then calls commit_event() with
# the SAME record when the action commits. A non-dice action calls only
# commit_event(). Previews call NEITHER.


func begin_event(kind: String, record: Array[String]) -> RandomNumberGenerator:
	var s := _mix(map_seed, history_hash)
	s = _mix(s, _hash_string(kind))
	for field in record:
		s = _mix(s, _hash_string(field))
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	return rng


func commit_event(kind: String, record: Array[String]) -> void:
	history_hash = _mix(history_hash, _hash_string(kind))
	for field in record:
		history_hash = _mix(history_hash, _hash_string(field))


# ── Persistence (consumed by the snapshot contract, RNG-2) ──────────────────
func to_save_dict() -> Dictionary:
	return {"map_seed": map_seed, "history_hash": history_hash}


func from_save_dict(d: Dictionary) -> void:
	map_seed = int(d.get("map_seed", 0))
	history_hash = int(d.get("history_hash", 0))


# ── Mixing primitives ────────────────────────────────────────────────────────
# SplitMix64-style finalizer. NEVER replace with engine hash(): its semantics
# are not guaranteed stable across Godot versions, and a change would silently
# invalidate in-flight suspend saves and the determinism tests. GDScript ints
# are signed 64-bit with wrapping arithmetic; the decimal constants below are
# the signed equivalents of the canonical hex (given in comments). GDScript's
# >> is arithmetic (sign-extending) — slightly weaker avalanche than unsigned
# SplitMix64, accepted and frozen (§2 notes).
static func _mix(a: int, b: int) -> int:
	var z: int = (a ^ b) + -7046029254386353131  # 0x9E3779B97F4A7C15
	z = (z ^ (z >> 30)) * -4658895280553007687  # 0xBF58476D1CE4E5B9
	z = (z ^ (z >> 27)) * -7723592293110706605  # 0x94D049BB133111EB
	return z ^ (z >> 31)


# Deterministic string fold over UTF-8 bytes. Do NOT use String.hash() —
# same engine-stability argument as above.
static func _hash_string(s: String) -> int:
	var h: int = 0
	for b in s.to_utf8_buffer():
		h = _mix(h, b)
	return h


static func _entropy_seed() -> int:
	var r := RandomNumberGenerator.new()  # rng-allow: entropy source for map_seed itself (§2)
	r.randomize()  # rng-allow: entropy source for map_seed itself (§2)
	return r.randi() | (r.randi() << 32)  # rng-allow: entropy source for map_seed itself (§2)
