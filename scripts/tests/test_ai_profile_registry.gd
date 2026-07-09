extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_ai_profile_registry.gd
# Tests the AIProfileRegistry composition seam (build-slice steps 1-2 of
# ai_first_build_design_2026-06-22.md): profile validation and profile -> AISpec
# resolution. This is the seam that replaced DataManager's closed
# `_VALID_AI_PROFILES` const and EnemyAI's `match enemy.data.ai_profile`.

const AIProfileRegistry = preload("res://scripts/core/AIProfileRegistry.gd")

func _init() -> void:
	print("=== AIProfileRegistry Test ===")
	var passed := 0
	var failed := 0

	# ---- is_valid_profile: the three shipped profiles are valid ----
	if AIProfileRegistry.is_valid_profile("basic") \
			and AIProfileRegistry.is_valid_profile("passive") \
			and AIProfileRegistry.is_valid_profile("healer"):
		print("OK  is_valid_profile accepts basic/passive/healer"); passed += 1
	else:
		print("FAIL is_valid_profile rejected a shipped profile"); failed += 1

	# ---- is_valid_profile: an unregistered profile is rejected ----
	# Mirrors DataManager boot validation (test_data_manager rejects "berserk").
	if not AIProfileRegistry.is_valid_profile("berserk"):
		print("OK  is_valid_profile rejects an unregistered profile"); passed += 1
	else:
		print("FAIL is_valid_profile accepted an unknown profile"); failed += 1

	# ---- valid_profile_ids: exactly the three shipped profiles (no vocabulary
	# opened ahead of its behavior in steps 1-2) ----
	var ids: Array = AIProfileRegistry.valid_profile_ids()
	if ids.size() == 3 and ids.has("basic") and ids.has("passive") and ids.has("healer"):
		print("OK  valid_profile_ids = the three shipped profiles"); passed += 1
	else:
		print("FAIL valid_profile_ids = %s" % str(ids)); failed += 1

	# ---- resolve_ai_spec: each profile maps to its disposition + default axes ----
	var basic_spec: RefCounted = AIProfileRegistry.resolve_ai_spec("basic")
	if basic_spec.disposition == AIProfileRegistry.DISP_PURSUE_UNIT \
			and basic_spec.activation == "always" and basic_spec.engagement == "nearest":
		print("OK  resolve_ai_spec(basic) -> pursue_unit / always / nearest"); passed += 1
	else:
		print("FAIL resolve_ai_spec(basic): %s/%s/%s" % [
			basic_spec.activation, basic_spec.disposition, basic_spec.engagement]); failed += 1

	if AIProfileRegistry.resolve_ai_spec("passive").disposition == AIProfileRegistry.DISP_HOLD_TILE:
		print("OK  resolve_ai_spec(passive) -> hold_tile"); passed += 1
	else:
		print("FAIL resolve_ai_spec(passive) disposition"); failed += 1

	if AIProfileRegistry.resolve_ai_spec("healer").disposition == AIProfileRegistry.DISP_HEAL:
		print("OK  resolve_ai_spec(healer) -> heal"); passed += 1
	else:
		print("FAIL resolve_ai_spec(healer) disposition"); failed += 1

	# ---- resolve_ai_spec: an unknown profile falls back to pursue_unit, matching
	# EnemyAI's old `_: pass` runtime behavior (boot validation still rejects it) ----
	if AIProfileRegistry.resolve_ai_spec("berserk").disposition == AIProfileRegistry.DISP_PURSUE_UNIT:
		print("OK  resolve_ai_spec(unknown) falls back to pursue_unit"); passed += 1
	else:
		print("FAIL resolve_ai_spec(unknown) fallback"); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
