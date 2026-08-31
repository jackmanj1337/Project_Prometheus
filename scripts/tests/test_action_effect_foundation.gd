extends SceneTree

const JournalScript = preload("res://scripts/actions/EffectMutationJournal.gd")
const StateViewScript = preload("res://scripts/actions/EffectStateView.gd")


func _init() -> void:
	print("=== Shared Effect Foundation Test ===")
	var passed := 0
	var failed := 0
	var live := {"hp": {"unit_a": 20}, "flags": {"door": false}}
	var view = StateViewScript.new(JournalScript.new())
	view.register_authority(
		"unit",
		func(field, ref): return live[field][ref],
		func(field, ref, value): live[field][ref] = value
	)
	view.register_authority(
		"campaign",
		func(field, ref): return live[field][ref],
		func(field, ref, value): live[field][ref] = value
	)

	view.write("damage", "unit", "hp", "unit_a", 15)
	view.write("heal", "unit", "hp", "unit_a", 18)
	view.write("story", "campaign", "flags", "door", true)
	if (
		live.hp.unit_a == 20
		and not live.flags.door
		and view.read("unit", "hp", "unit_a") == 18
		and (
			view.journal.entries.map(func(entry): return entry.step_id)
			== ["damage", "heal", "story"]
		)
	):
		print("OK  prepare overlays ordered writes without touching live state")
		passed += 1
	else:
		print("FAIL overlay isolation or ordering")
		failed += 1

	var committed: Dictionary = view.commit()
	if committed.ok and live.hp.unit_a == 18 and live.flags.door:
		print("OK  a valid journal commits in order")
		passed += 1
	else:
		print("FAIL journal commit: %s" % [committed])
		failed += 1

	var stale_live := {"hp": {"unit_b": 12}}
	var stale_view = StateViewScript.new()
	stale_view.register_authority(
		"unit",
		func(field, ref): return stale_live[field][ref],
		func(field, ref, value): stale_live[field][ref] = value
	)
	stale_view.write("damage", "unit", "hp", "unit_b", 5)
	stale_live.hp.unit_b = 10
	var rejected: Dictionary = stale_view.commit()
	if not rejected.ok and rejected.code == "stale_precondition" and stale_live.hp.unit_b == 10:
		print("OK  stale-before rejection applies nothing")
		passed += 1
	else:
		print("FAIL stale journal: %s" % [rejected])
		failed += 1

	var abandoned_live := {"flags": {"visited": false}}
	var abandoned_view = StateViewScript.new()
	abandoned_view.register_authority(
		"campaign",
		func(field, ref): return abandoned_live[field][ref],
		func(field, ref, value): abandoned_live[field][ref] = value
	)
	abandoned_view.write("visit", "campaign", "flags", "visited", true)
	if not abandoned_live.flags.visited:
		print("OK  abandoning prepare leaves live state unchanged")
		passed += 1
	else:
		print("FAIL abandoned prepare mutated live state")
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
