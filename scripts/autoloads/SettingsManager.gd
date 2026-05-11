extends Node
# Persists player preferences to user://settings.cfg via ConfigFile.
# Loaded once at startup; written immediately on every change.

const SETTINGS_PATH := "user://settings.cfg"

# --- Audio (0–100 int scale) ---
var master_volume: int = 80
var music_volume: int = 70
var sfx_volume: int = 90

# --- Gameplay ---
# "all"|"player_only"|"enemy_only"|"none"
var combat_animations: String = "all"
# "normal"|"fast"|"instant"
var movement_speed: String = "normal"
# "show"|"skip"
var phase_banner: String = "show"
# "show"|"auto"|"skip"
var level_up_screen: String = "show"
# "off"|"on"
var permadeath: String = "off"
# "growth_rates"|"point_buy"|"coin_flip"|"dice"
var leveling_method: String = "growth_rates"

# --- Controls ---
# { action_name: Array[InputEvent] }; applied to InputMap at startup
var keybindings: Dictionary = {}


func _ready() -> void:
	load_settings()
	_apply_audio()
	_apply_keybindings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		# First run or missing file — defaults stay in place
		return

	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	music_volume  = cfg.get_value("audio", "music_volume",  music_volume)
	sfx_volume    = cfg.get_value("audio", "sfx_volume",    sfx_volume)

	combat_animations = cfg.get_value("gameplay", "combat_animations", combat_animations)
	movement_speed    = cfg.get_value("gameplay", "movement_speed",    movement_speed)
	phase_banner      = cfg.get_value("gameplay", "phase_banner",      phase_banner)
	level_up_screen   = cfg.get_value("gameplay", "level_up_screen",   level_up_screen)
	permadeath        = cfg.get_value("gameplay", "permadeath",        permadeath)
	leveling_method   = cfg.get_value("gameplay", "leveling_method",   leveling_method)

	keybindings = cfg.get_value("controls", "keybindings", {})
	# GameState sync happens in GameState._ready() — at this point GameState autoload
	# hasn't loaded yet (autoload order: EventBus, SettingsManager, GameState, DataManager)


func save() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume",  music_volume)
	cfg.set_value("audio", "sfx_volume",    sfx_volume)

	cfg.set_value("gameplay", "combat_animations", combat_animations)
	cfg.set_value("gameplay", "movement_speed",    movement_speed)
	cfg.set_value("gameplay", "phase_banner",      phase_banner)
	cfg.set_value("gameplay", "level_up_screen",   level_up_screen)
	cfg.set_value("gameplay", "permadeath",        permadeath)
	cfg.set_value("gameplay", "leveling_method",   leveling_method)

	cfg.set_value("controls", "keybindings", keybindings)

	cfg.save(SETTINGS_PATH)


# Resets one section ("audio"|"controls"|"gameplay") to defaults and saves.
func reset_section_to_defaults(section: String) -> void:
	match section:
		"audio":
			master_volume = 80
			music_volume  = 70
			sfx_volume    = 90
			_apply_audio()
		"gameplay":
			combat_animations = "all"
			movement_speed    = "normal"
			phase_banner      = "show"
			level_up_screen   = "show"
			permadeath        = "off"
			leveling_method   = "growth_rates"
		"controls":
			keybindings = {}
			_apply_keybindings()
	save()


# Formula per GDD_01: linear_to_db(volume / 100.0).
# Look up by name so bus order in the editor doesn't matter.
# Buses that don't exist yet (Music/SFX must be added in editor) are silently skipped.
func _apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx  := AudioServer.get_bus_index("Music")
	var sfx_idx    := AudioServer.get_bus_index("SFX")
	if master_idx >= 0: AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume / 100.0))
	if music_idx  >= 0: AudioServer.set_bus_volume_db(music_idx,  linear_to_db(music_volume  / 100.0))
	if sfx_idx    >= 0: AudioServer.set_bus_volume_db(sfx_idx,    linear_to_db(sfx_volume    / 100.0))


func _apply_keybindings() -> void:
	for action in keybindings:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event in keybindings[action]:
			InputMap.action_add_event(action, event)


func set_volume(bus_name: String, value: int) -> void:
	match bus_name:
		"Master": master_volume = value
		"Music":  music_volume  = value
		"SFX":    sfx_volume    = value
	_apply_audio()
	save()


func rebind_action(action_name: String, event: InputEvent) -> void:
	keybindings[action_name] = [event]
	_apply_keybindings()
	save()


# Returns per-tile Tween duration in seconds based on movement_speed setting
func get_movement_speed_seconds() -> float:
	match movement_speed:
		"fast":    return 0.06
		"instant": return 0.0
		_:         return 0.12
