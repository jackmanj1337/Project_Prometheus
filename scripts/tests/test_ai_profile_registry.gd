extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_ai_profile_registry.gd
# Tests the AIProfileRegistry composition seam (build-slice steps 1-2 of
# [GDD-08-ENEMY-AI]): profile validation and profile -> AISpec
# resolution. This is the seam that replaced DataManager's closed
# `_VALID_AI_PROFILES` const and EnemyAI's `match enemy.data.ai_profile`.

const AIProfileRegistry = preload("res://scripts/core/AIProfileRegistry.gd")


func _init() -> void:
	print("=== AIProfileRegistry Test ===")
	var passed := 0
	var failed := 0

	# ---- is_valid_profile: the three shipped profiles are valid ----
	if (
		AIProfileRegistry.is_valid_profile("basic")
		and AIProfileRegistry.is_valid_profile("passive")
		and AIProfileRegistry.is_valid_profile("healer")
	):
		print("OK  is_valid_profile accepts basic/passive/healer")
		passed += 1
	else:
		print("FAIL is_valid_profile rejected a shipped profile")
		failed += 1

	# ---- is_valid_profile: an unregistered profile is rejected ----
	# Mirrors DataManager boot validation (test_data_manager rejects "berserk").
	if not AIProfileRegistry.is_valid_profile("berserk"):
		print("OK  is_valid_profile rejects an unregistered profile")
		passed += 1
	else:
		print("FAIL is_valid_profile accepted an unknown profile")
		failed += 1

	# ---- valid_profile_ids: exactly the shipped profiles — the 3 legacy names plus
	# `hunter` (the non-schema weakest-target slice). No vocabulary is opened ahead
	# of its behavior: every id here resolves to a disposition/engagement EnemyAI
	# honours today. ----
	var ids: Array = AIProfileRegistry.valid_profile_ids()
	if (
		ids.size() == 4
		and ids.has("basic")
		and ids.has("passive")
		and ids.has("healer")
		and ids.has("hunter")
	):
		print("OK  valid_profile_ids = the shipped profiles (basic/passive/healer/hunter)")
		passed += 1
	else:
		print("FAIL valid_profile_ids = %s" % str(ids))
		failed += 1

	# ---- resolve_ai_spec: each profile maps to its disposition + default axes ----
	var basic_spec: RefCounted = AIProfileRegistry.resolve_ai_spec("basic")
	if (
		basic_spec.disposition == AIProfileRegistry.DISP_PURSUE_UNIT
		and basic_spec.activation == "always"
		and basic_spec.engagement == "nearest"
	):
		print("OK  resolve_ai_spec(basic) -> pursue_unit / always / nearest")
		passed += 1
	else:
		print(
			(
				"FAIL resolve_ai_spec(basic): %s/%s/%s"
				% [basic_spec.activation, basic_spec.disposition, basic_spec.engagement]
			)
		)
		failed += 1

	if AIProfileRegistry.resolve_ai_spec("passive").disposition == AIProfileRegistry.DISP_HOLD_TILE:
		print("OK  resolve_ai_spec(passive) -> hold_tile")
		passed += 1
	else:
		print("FAIL resolve_ai_spec(passive) disposition")
		failed += 1

	if AIProfileRegistry.resolve_ai_spec("healer").disposition == AIProfileRegistry.DISP_HEAL:
		print("OK  resolve_ai_spec(healer) -> heal")
		passed += 1
	else:
		print("FAIL resolve_ai_spec(healer) disposition")
		failed += 1

	# ---- resolve_ai_spec: an unknown profile falls back to pursue_unit, matching
	# EnemyAI's old `_: pass` runtime behavior (boot validation still rejects it) ----
	if (
		AIProfileRegistry.resolve_ai_spec("berserk").disposition
		== AIProfileRegistry.DISP_PURSUE_UNIT
	):
		print("OK  resolve_ai_spec(unknown) falls back to pursue_unit")
		passed += 1
	else:
		print("FAIL resolve_ai_spec(unknown) fallback")
		failed += 1

	# ---- hunter: shipped weakest-target profile on the existing pursue_unit
	# disposition (non-schema target_policy slice) ----
	var hunter: RefCounted = AIProfileRegistry.resolve_ai_spec("hunter")
	if (
		hunter.disposition == AIProfileRegistry.DISP_PURSUE_UNIT
		and hunter.engagement == AIProfileRegistry.ENG_WEAKEST
		and hunter.activation == "always"
		and AIProfileRegistry.is_valid_profile("hunter")
	):
		print("OK  resolve_ai_spec(hunter) -> pursue_unit / always / weakest, boot-valid")
		passed += 1
	else:
		print(
			(
				"FAIL resolve_ai_spec(hunter): %s/%s/%s valid=%s"
				% [
					hunter.activation,
					hunter.disposition,
					hunter.engagement,
					AIProfileRegistry.is_valid_profile("hunter")
				]
			)
		)
		failed += 1

	# Every registered profile's engagement must be a known policy (no typo'd axis).
	var all_eng_valid := true
	for pid in AIProfileRegistry.valid_profile_ids():
		if not (
			AIProfileRegistry.resolve_ai_spec(pid).engagement in AIProfileRegistry.VALID_ENGAGEMENTS
		):
			all_eng_valid = false
	if all_eng_valid:
		print("OK  every profile's engagement is a VALID_ENGAGEMENTS value")
		passed += 1
	else:
		print("FAIL a profile declares an unknown engagement policy")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
