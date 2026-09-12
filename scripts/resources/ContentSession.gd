class_name ContentSession extends RefCounted
# Immutable-at-commit candidate assembled before live content is replaced.
# Keeping the package identity beside every catalogue prevents partial activation
# and gives deactivation one well-defined empty-state inverse.

var classes: Dictionary = {}
var weapons: Dictionary = {}
var items: Dictionary = {}
var skills: Dictionary = {}
var pair_up_bonus_table: Resource = null
var registry_entries: Array[Resource] = []
var campaigns: Dictionary = {}
var map_registry: Dictionary = {}
var battle_maps: Dictionary = {}
var battle_encounters: Dictionary = {}
var pack_maps: Dictionary = {}
var pack_rosters: Dictionary = {}
# Terrain is the one catalogue with a non-empty inactive state: the engine can always
# paint its own terrain, so a candidate starts from the engine definitions and a
# pack's `terrain` documents retune them. Carried on the session like every other
# catalogue so activation stays one atomic swap.
var terrain: TerrainRegistry = TerrainRegistry.engine_defaults()
# Resolved media: logical asset id -> {path, decoded_type}. Carried on the session
# because terrain art is now resolved at map load ([TER-2]) — the renderer needs the
# same atomic swap the catalogues get, or a map could paint with the previous pack's
# tiles.
var assets: Dictionary = {}
var palette_swaps: Dictionary = {}
var package_id := ""
var package_version := ""
var content_schema_version := 0
var content_fingerprint := ""
var package_path := ""
var compatibility_source := false
# Rollback-only state captured from a committed session. Candidate builders leave
# these at their defaults; DataManager fills them when a caller opens a wider
# transaction that may need to restore the exact live session.
var content_state := 0
var activation_errors: Array[String] = []
var content_warnings: Array[String] = []
var reported_unknown_ids: Dictionary = {}
var registry_snapshot: Dictionary = {}


static func empty() -> ContentSession:
	return ContentSession.new()
