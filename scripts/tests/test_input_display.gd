extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_input_display.gd
# Covers the B6-INPUT brand-aware prompt swapping added to InputDisplay:
#   - detect_brand classifies joypad name strings into Brand
#   - joypad_button_label swaps face-button labels per brand (SDL gives POSITION,
#     the player reads the brand LABEL) and defers non-face buttons
#   - action_prompt renders the key in keyboard mode and the brand-correct pad
#     label in gamepad mode, falling back to the key when no pad binding exists
#
# Uses the live project InputMap (loaded in --script runs): `confirm` binds pad
# button 0 (physical bottom → Xbox A / Switch B / PS Cross); `more_info` binds
# pad button 2 (physical left → Xbox X / Switch Y / PS Square).

const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== InputDisplay Prompt Test ===")

	# ---- detect_brand ---------------------------------------------------
	var brand_cases := {
		"Xbox 360 Controller": InputDisplay.Brand.XBOX,
		"Xbox Series Controller": InputDisplay.Brand.XBOX,
		"Nintendo Switch Pro Controller": InputDisplay.Brand.NINTENDO,
		"Joy-Con (L)": InputDisplay.Brand.NINTENDO,
		"Sony DualSense Wireless Controller": InputDisplay.Brand.PLAYSTATION,
		"PS4 Controller": InputDisplay.Brand.PLAYSTATION,
		"8BitDo Generic Gamepad": InputDisplay.Brand.GENERIC,
	}
	var brand_ok := true
	var brand_detail := ""
	for name_str in brand_cases:
		var got: int = InputDisplay.detect_brand(name_str)
		if got != brand_cases[name_str]:
			brand_ok = false
			brand_detail += " [%s→%d expected %d]" % [name_str, got, brand_cases[name_str]]
	_check(brand_ok, "detect_brand classifies Xbox/Nintendo/PlayStation/generic",
		"detect_brand mismatch:%s" % brand_detail)

	# ---- joypad_button_label brand swap ---------------------------------
	var bottom := JOY_BUTTON_A  # physical bottom on every pad
	_check(
		InputDisplay.joypad_button_label(bottom, InputDisplay.Brand.XBOX) == "A"
		and InputDisplay.joypad_button_label(bottom, InputDisplay.Brand.NINTENDO) == "B"
		and InputDisplay.joypad_button_label(bottom, InputDisplay.Brand.PLAYSTATION) == "Cross"
		and InputDisplay.joypad_button_label(JOY_BUTTON_X, InputDisplay.Brand.NINTENDO) == "Y"
		and InputDisplay.joypad_button_label(JOY_BUTTON_Y, InputDisplay.Brand.PLAYSTATION) == "Triangle",
		"joypad_button_label swaps face buttons per brand", "face-label swap wrong")

	# ---- non-face buttons defer (and PS shoulders relabel) --------------
	_check(
		InputDisplay.joypad_button_label(JOY_BUTTON_LEFT_SHOULDER, InputDisplay.Brand.XBOX) == "LB"
		and InputDisplay.joypad_button_label(JOY_BUTTON_LEFT_SHOULDER, InputDisplay.Brand.PLAYSTATION) == "L1"
		and InputDisplay.joypad_button_label(JOY_BUTTON_START, InputDisplay.Brand.NINTENDO) == "Start",
		"non-face buttons defer to positional label (PS shoulders relabel)", "non-face defer wrong")

	# ---- action_prompt: keyboard mode = the key -------------------------
	var kbd_prompt: String = InputDisplay.action_prompt("confirm", "mouse_keyboard")
	_check(kbd_prompt != "" and kbd_prompt == InputDisplay.first_key_for_action("confirm"),
		"action_prompt in keyboard mode returns the confirm key (%s)" % kbd_prompt,
		"keyboard prompt: %s" % kbd_prompt)

	# ---- action_prompt: gamepad mode = brand-correct pad label ----------
	_check(
		InputDisplay.action_prompt("confirm", "gamepad", InputDisplay.Brand.XBOX) == "A"
		and InputDisplay.action_prompt("confirm", "gamepad", InputDisplay.Brand.NINTENDO) == "B"
		and InputDisplay.action_prompt("confirm", "gamepad", InputDisplay.Brand.PLAYSTATION) == "Cross"
		and InputDisplay.action_prompt("more_info", "gamepad", InputDisplay.Brand.XBOX) == "X"
		and InputDisplay.action_prompt("more_info", "gamepad", InputDisplay.Brand.NINTENDO) == "Y",
		"action_prompt in gamepad mode returns the brand-correct pad label", "gamepad prompt wrong")

	# ---- gamepad mode falls back to the key when no pad binding ---------
	# A missing action has neither pad nor key, so both resolve to "".
	_check(
		InputDisplay.first_pad_label_for_action("no_such_action", InputDisplay.Brand.XBOX) == ""
		and InputDisplay.action_prompt("no_such_action", "gamepad", InputDisplay.Brand.XBOX) == "",
		"unbound action yields empty prompt (gamepad falls back to key)", "fallback wrong")

	# ---- more_info_hint_for swaps verb + token by mode ------------------
	var mi_key: String = InputDisplay.first_key_for_action("more_info")
	_check(
		InputDisplay.more_info_hint_for("mouse_keyboard", "value")
			== "Click any value, or press %s, for details." % mi_key
		and InputDisplay.more_info_hint_for("gamepad", "value", InputDisplay.Brand.XBOX)
			== "Press X for details."
		and InputDisplay.more_info_hint_for("gamepad", "", InputDisplay.Brand.NINTENDO)
			== "Press Y for more info"
		and InputDisplay.more_info_hint_for("touch", "entry") == "Tap any entry for details.",
		"more_info_hint_for swaps verb + token per mode", "more_info_hint wrong")

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(cond: bool, ok_msg: String, fail_msg: String) -> void:
	if cond:
		print("OK  %s" % ok_msg)
		_passed += 1
	else:
		print("FAIL %s" % fail_msg)
		_failed += 1
