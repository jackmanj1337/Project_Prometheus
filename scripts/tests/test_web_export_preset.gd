extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_web_export_preset.gd
#
# Guards the web export preset settings that carry a DECISION rather than a preference, so a
# future edit in the Godot export dialog cannot silently revert one. The dialog writes this
# file wholesale, which is exactly how an unnoticed flip happens.

const PRESET_PATH := "res://export_presets.cfg"
const WEB_PRESET_NAME := "Web"


# Returns the [preset.N.options] section name for the preset called `wanted`, or "".
func _options_section_for(cfg: ConfigFile, wanted: String) -> String:
	for section in cfg.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		if String(cfg.get_value(section, "name", "")) == wanted:
			return "%s.options" % section
	return ""


func _init() -> void:
	print("=== Web Export Preset Test ===")
	var passed := 0
	var failed := 0

	var cfg := ConfigFile.new()
	var err := cfg.load(PRESET_PATH)
	if err != OK:
		print("FAIL could not load %s (error %d)" % [PRESET_PATH, err])
		quit(1)
		return

	var options := _options_section_for(cfg, WEB_PRESET_NAME)
	if options != "":
		print("OK  found the '%s' preset options section (%s)" % [WEB_PRESET_NAME, options])
		passed += 1
	else:
		print("FAIL no preset named '%s'" % WEB_PRESET_NAME)
		print("\n=== Results: %d passed, %d failed ===" % [passed, failed + 1])
		quit(1)
		return

	# The decision this guards (2026-08-06): on mobile the OS keyboard is SUPPRESSED and our
	# own keyboard takes over the control region instead.
	#
	# This flag is the mechanism, and it is not obvious from the GDScript side. When it is
	# true the generated index.html sets GODOT_CONFIG.experimentalVK, which makes
	# GodotDisplayVK.available() return true on any touch device
	# (`GodotConfig.virtual_keyboard && "ontouchstart" in window`). The engine then creates a
	# hidden <input>/<textarea> and focuses it, raising the platform keyboard ON TOP OF the
	# grid keyboard — because TextEntryService focuses a real LineEdit and
	# LineEdit.virtual_keyboard_enabled defaults to true.
	#
	# Setting it false makes the whole path unavailable at the platform level, which is why
	# no per-LineEdit change is needed to hold the decision.
	var vk: Variant = cfg.get_value(options, "html/experimental_virtual_keyboard", null)
	if vk == null:
		print("FAIL html/experimental_virtual_keyboard is absent — the export dialog dropped it")
		failed += 1
	elif bool(vk):
		print(
			(
				"FAIL html/experimental_virtual_keyboard is true; the OS keyboard will raise "
				+ "over the in-game keyboard on touch devices"
			)
		)
		failed += 1
	else:
		print("OK  html/experimental_virtual_keyboard is false — the OS keyboard stays suppressed")
		passed += 1

	# The PWA shell is what feeds real safe-area insets and hosts the touch controller; an
	# export that quietly falls back to Godot's stock shell loses both.
	var shell := String(cfg.get_value(options, "html/custom_html_shell", ""))
	if shell.ends_with("pwa_shell.html"):
		print("OK  the custom PWA shell is still wired up (%s)" % shell)
		passed += 1
	else:
		print(
			(
				"FAIL custom_html_shell is %s, expected the PWA shell"
				% [shell if shell != "" else "<empty>"]
			)
		)
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
