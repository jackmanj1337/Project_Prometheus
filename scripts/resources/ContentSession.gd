class_name ContentSession extends RefCounted
# Immutable-at-commit candidate assembled before live content is replaced.
# Keeping the package identity beside every catalogue prevents partial activation
# and gives deactivation one well-defined empty-state inverse.

var classes: Dictionary = {}
var weapons: Dictionary = {}
var items: Dictionary = {}
var skills: Dictionary = {}
var campaigns: Dictionary = {}
var map_registry: Dictionary = {}
var battle_maps: Dictionary = {}
var battle_encounters: Dictionary = {}
var pack_maps: Dictionary = {}
var pack_rosters: Dictionary = {}
var package_id := ""
var package_version := ""
var package_path := ""
var compatibility_source := false


static func empty() -> ContentSession:
	return ContentSession.new()
