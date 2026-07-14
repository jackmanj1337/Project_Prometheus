# GDD_01 — Data Contracts

**Status:** Active data contract — implemented and target fields are labelled per section.
**Last verified:** 2026-07-14
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This companion chapter owns custom resource shapes, persistence fields, validation
invariants, and authoring bindings shared across gameplay domains. Project composition
remains in [GDD_01 — Architecture](GDD_01_Architecture.md); runtime/save behavior lives
in [GDD_01 — Runtime Contracts](GDD_01_Runtime_Contracts.md).

---
## Resource Class Definitions

The full `@export` field definitions for every custom Resource class. Each class
lives in `scripts/resources/` and is saved as `.tres` files in its `data/` subfolder.

> **Headless `.tres` note:** in `--script` runs the global class registry is not
> initialized, so `.tres` files are written with `type="Resource"` and the real
> class assigned via the `script = ExtResource(...)` line — see Implementation Notes.

### `UnitData.gd`

```gdscript
class_name UnitData extends Resource

@export var unit_id: String = ""           # unique id — survivor checks & save/load
@export var unit_name: String = ""
var tile_position: Vector2i = Vector2i.ZERO
    # NOT @export — runtime map state. Captured by GameState's manual snapshot,
    # not by ResourceSaver. Unit.tile_position is a pass-through to this field.
@export var class_id: String = ""
@export var level: int = 1
@export var exp: int = 0
@export var is_promoted: bool = false
@export var internal_level: int = 1        # hidden progression state for promotion/reclass

# Stats — implemented storage fields. Combat code reads these via
# Unit.get_effective_stat(). The stat NAME/LABEL vocabulary is now unified in
# scripts/core/StatRegistry.gd (B3-STAT-REGISTRY, non-schema slice landed): the
# id list + short labels live there, read by ClassData/Unit/DataManager/UI
# instead of ~7 hardcoded copies. The base-stat @export -> Dictionary STORAGE
# migration and the author-declared CampaignRules stat registry stay F1-gated.
# [STM-5] reference policy: an authored resource that NAMES a stat outside the
# registry (skill activation_chance_stat, class growth/cap dict keys, Pair Up
# scaling_stats/class_bonuses) fails LOUD at DataManager boot — never a silent 0;
# a registered stat left unset stays a soft default (read-path fallback).
@export var max_hp: int = 0
@export var hp: int = 0                    # current HP
@export var strength: int = 0
@export var magic: int = 0
@export var defense: int = 0
@export var resistance: int = 0
@export var skill: int = 0
@export var speed: int = 0
@export var luck: int = 0
@export var movement: int = 0
@export var constitution: int = 0
@export var line_of_sight: int = 4

# Personal growth rates, added to the class growth table for player units.
@export var growth_rates: Dictionary = {}

# Authoritative numeric WEXP totals keyed by track (e.g. "sword", "staff",
# "elemental_magic"). Rank display is derived from these totals.
@export var weapon_wexp: Dictionary = {}

# Equipped skill IDs (future prep UI can swap a subset out of earned_skills)
@export var skills: Array[String] = []
@export var earned_skills: Array[String] = []
@export var reclass_options: Array[String] = []
@export var class_line_id: String = ""
@export var can_seize: bool = false
# Permanently earned mastery skills. NOT @export — runtime only.
var mastery_skills: Array[String] = []

# Typed inventory — Array[InventoryEntry] (replaced the old Array[Dictionary]).
@export var inventory: Array[InventoryEntry] = []

# Conditions — Array of Dictionaries; see GDD_02. Target: condition/effect registry.
@export var conditions: Array[Dictionary] = []

@export var gold: int = 1000             # legacy field; active economy uses GameState.party_gold
@export var is_incapacitated: bool = false  # permadeath flag
@export var ai_profile: String = "basic"    # Implemented profile id; target AISpec/profile registry — see GDD_08
@export var is_default_roster: bool = false # true for the 6 generated starter units

# ── Phase 2 runtime state ────────────────────────────────────────────────────
# Active temporary stat modifiers. Each entry:
#   { "stat": String, "delta": int, "source": String, "duration": int,
#     "duration_type": "turn"|"map_turn"|"combat"|"permanent" }
# duration -1 or "permanent" type = never auto-removed.
var active_modifiers: Array[Dictionary] = []
var skill_use_counters: Dictionary = {}     # skill.id -> uses this map
var damage_taken_this_map: int = 0          # used by Vengeance (M9)
@export var growth_accumulators: Dictionary = {}   # carry-over for growth_fixed leveling

# Laguz fields — safe defaults for all Beorc units; ignored until M12.
@export var shift_gauge: int = 0
@export var is_shifted: bool = false
@export var shift_profile_id: String = ""
```

> The non-`@export` fields (`tile_position`, `mastery_skills`, `active_modifiers`,
> `skill_use_counters`, `damage_taken_this_map`) are runtime state. `GameState`'s map snapshot copies them
> by hand for Retry; a future `ResourceSaver`-based save must serialize them via that
> snapshot dict (a `ResourceSaver` write does not persist non-exported vars).

### `InventoryEntry.gd`

A unit's inventory is `Array[InventoryEntry]` — a typed `Resource`, **not** the old
`Array[Dictionary]` format. One `InventoryEntry` per slot; `entry_type` discriminates.

```gdscript
class_name InventoryEntry extends Resource

@export var entry_type: String = ""    # "weapon" | "item" | "equip"

# Weapon fields
@export var weapon_id: String = ""     # must match a WeaponData id
@export var forged_mods: Dictionary = {}   # reserved for forging (M10)

# Item fields
@export var item_id: String = ""       # must match an ItemData id

# Shared — remaining uses. -1 = infinite, 0 = exhausted, >0 = finite.
# Equip-type entries ignore this (gate them with is_equip()).
@export var uses_remaining: int = 0

# Equipment bonus fields (equip type — M10 forging)
@export var accuracy: int = 0
@export var damage: int = 0
@export var crit: int = 0
@export var dodge: int = 0

func is_weapon() -> bool       # entry_type == "weapon"
func is_item() -> bool         # entry_type == "item"
func is_equip() -> bool        # entry_type == "equip"
func has_uses() -> bool        # uses_remaining != 0
func validate() -> bool        # checks type/id consistency
static func make_weapon(weapon_id: String, uses: int) -> InventoryEntry
static func make_item(item_id: String, uses: int) -> InventoryEntry
```

`Unit.get_equipped_weapon()` returns the first `is_weapon()` entry that still
`has_uses()` and whose `WeaponData` the unit can equip (proficiency rank check).
Items are never auto-equipped.

### `WeaponData.gd`

```gdscript
class_name WeaponData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var combat_family: String = ""    # canonical equip / skill family; target profile data validates ids
@export var wexp_track: String = ""       # canonical trained progression track
@export var required_rank: String = "E"
@export var mt: int = 0                   # staves: 0 (heal = 10 + MAG, computed separately)
@export var hit: int = 0                  # staves: 0 (healing always lands)
@export var crit: int = 0                 # staves: 0 (staves cannot crit)

# Range as formula strings so dynamic ranges (e.g. Physic "MAG/2") work uniformly.
# Static weapons store integer strings ("1", "2"). Always read via get_range_min/max().
@export var range_min_formula: String = "1"
@export var range_max_formula: String = "1"

@export var wt: int = 0
@export var uses: int = 1
@export var cost: int = 0
@export var wexp: int = 1                 # wEXP granted per successful hit
@export var effect_tags: Array[String] = []   # built-in ids today; target component/effect registry
@export var uses_mag: bool = false        # true: MAG for damage, targets RES (tomes)
@export var triangle_family: String = ""       # hybrid override for triangle checks
@export var strikes_per_attack: int = 1   # 2 for Brave weapons
@export var is_natural_weapon: bool = false    # Laguz Fang/Claw/Beak/Talon (deferred)

func is_healing_staff() -> bool                # staff type + heal_10_plus_mag tag
func get_range_min(unit: Node = null) -> int   # evaluates range_min_formula
func get_range_max(unit: Node = null) -> int   # evaluates range_max_formula
func get_triangle_family() -> String
```

**Staff note:** healing staves have `weapon_type = "staff"` and the `heal_10_plus_mag`
effect tag. `is_healing_staff()` keys off the **tag** (not the type), so future
offensive/debuff staves remain attack-capable. Healing staves cannot attack or
counterattack — staff use runs through `Unit.perform_staff_heal()`, not `CombatResolver`.

### `ClassData.gd`

```gdscript
class_name ClassData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var tier: int = 1
@export var max_level: int = 20
@export var base_hp: int = 0
@export var base_strength: int = 0
@export var base_magic: int = 0
@export var base_defense: int = 0
@export var base_resistance: int = 0
@export var base_skill: int = 0
@export var base_speed: int = 0
@export var base_luck: int = 0
@export var base_movement: int = 0
@export var base_constitution: int = 0
@export var base_line_of_sight: int = 4
@export var weapon_wexp_bases: Dictionary = {}
@export var weapon_wexp_caps: Dictionary = {}
@export var allowed_weapon_families: Array[String] = []
@export var class_groups: Array[String] = []
@export var special_qualities: Array[String] = []
@export var vulnerability_groups: Array[String] = []
@export var internal_level_rule: String = ""
@export var class_availability: String = "playable"
@export var promotes_to: Array[String] = []
@export var promotes_from: Array[String] = []
@export var promotion_stat_bonuses: Dictionary = {}
const STAT_KEYS: Array[String] = StatRegistry.GROWTH_STAT_IDS  # single stat vocabulary (B3-STAT-REGISTRY)
@export var player_growth_rates: Dictionary = {}
@export var enemy_growth_rates: Dictionary = {}
@export var stat_caps: Dictionary = {}
@export var skill_unlocks: Dictionary = {}
@export var sprite_id: String = ""        # [PLACEHOLDER] links to sprite sheet row

# ── Laguz gauge parameters ───────────────────────────────────────────────────
# All default to 0/false/"" for Beorc classes — safe to ignore until M12.
@export var is_laguz: bool = false
@export var max_shift_gauge: int = 0
@export var shift_gauge_start: int = 0
@export var shift_gain_per_turn_humanoid: int = 0
@export var shift_gain_per_turn_animal: int = 0
@export var shift_gain_per_combat_humanoid: int = 0
@export var shift_gain_per_combat_animal: int = 0
@export var animal_stat_bonus_pct: float = 0.5    # +50%; reduced to +25% with Feral Instincts
@export var natural_weapon_type: String = ""       # "fang"|"claw"|"beak"|"talon"|"" for Beorc
@export var animal_con_bonus_pct: float = 0.75     # CON ~+75% in animal form

func get_weapon_wexp_base(track: String) -> int
func get_weapon_wexp_cap(track: String) -> int
func get_allowed_weapon_families() -> Array[String]
func resolved_internal_level_rule() -> String
func is_menu_visible() -> bool
```

Each usable WEXP track has an authored class cap. Current classes default to
the A-rank threshold (400 WEXP); special classes may explicitly author S-rank
caps later. `Unit.add_wexp()` stops at the active class cap.

### `ItemData.gd`

```gdscript
class_name ItemData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: String = ""
    # implemented built-in ids; target item/component registry validates this
@export var uses: int = 1                 # -1 = infinite / equippable
@export var cost: int = 0
@export var effect_id: String = ""
    # implemented ItemHandler ids; target action/effect primitive registry validates this
@export var effect_params: Dictionary = {}
```

### `SkillData.gd`

```gdscript
class_name SkillData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var trigger: String = ""
    # implemented built-in trigger ids:
    # "passive" | "start_of_turn" | "on_attack" | "on_defend" | "on_hit"
    # | "on_kill" | "on_damaged" | "on_combat_start" | "on_combat_end"
    # | "on_move" | "on_level_up" | "player_activated"
    # | "on_combat_start_negate"  (pre-pass before on_combat_start — Nihil)
    # Phase 2: "on_combat_apply_modifiers" | "on_ally_attacked"
    # | "on_enemy_leaves_adjacent" | "on_map_start" | "on_shift"
@export var activation_chance_stat: String = ""
    # e.g. "skill" — empty string if the skill always triggers
@export var activation_divisor: int = 2    # 2 = SKL/2 % activation chance
@export var effect_id: String = ""         # implemented dispatch id; target effect registry
@export var effect_params: Dictionary = {}
@export var is_player_activated: bool = false
@export var max_uses_per_map: int = -1     # -1 = unlimited (vs skill_use_counters)
@export var max_uses_per_combat: int = -1  # -1 = unlimited (reset after each combat)

func validate() -> void   # warns on missing id/effect_id/trigger; called by DataManager
```

### `MapData.gd`

```gdscript
class_name MapData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tilemap_scene_path: String = ""
@export var player_start_tiles: Array[Vector2i] = []
@export var enemy_placements: Array[Dictionary] = []
    # Each entry carries exactly one UnitData source:
    # { "unit_data_path": String OR "unit_data": UnitData,
    #   "tile": Vector2i, "ai_profile": String?, "is_boss": bool, "faction": String? }
    # "ai_profile" is an explicit placement override; omission preserves the
    # UnitData profile.
    # Target: ai_profile resolves through the AI spec/profile registry, not a match branch.
@export var reward_gold: int = 0
@export var reward_items: Array[String] = []
# Terrain string grid — one String per row; chars per GameMap._CHAR_TO_SOURCE
# (. F M T S D W). Height = grid.size(), width = grid[0].length().
@export var grid: Array[String] = []
# Camera start; Vector2i(-1,-1) = unset -> centroid of player_start_tiles.
@export var camera_start_tile: Vector2i = Vector2i(-1, -1)
@export var factions: Array[FactionData] = []
@export var turn_order: Array[String] = []
@export var activation_mode: String = "WHOLE_PHASE"
@export var victory_conditions: Dictionary = {}   # alliance_group -> Array[ObjectiveCondition]
@export var defeat_conditions: Dictionary = {}

func get_faction(faction_id: String) -> FactionData
```

Map-start unit placement is implemented through the `OccupancyService` autoload
(2026-07-13, `B2-OCCUPANCY`). `GameMap` resolves a registry-backed policy before
its private instancing seam. Normal map-start spawning defaults to deterministic
`nearest_free`: authored collisions or impassable cells warn when displaced, and
a no-free-tile result skips only that unit rather than aborting map boot.
`require_empty`, runtime-only `delay`, and `skip` remain active policies;
`swap`, `overlap_hidden`, and
`object_unit` are reserved policy rows that return `not_implemented` until their
owning feature slices land. Runtime-only delayed requests are cleared at fresh map
start so scene references cannot leak between battles. Normal traversed movement
and exact suspend-state restoration retain their existing paths.

Objective condition tiles are authored and evaluated in zero-based map coordinates.
HUD display text converts tile coordinates to player-facing one-based coordinates
only at render time.

### CampaignData Contract

Status: **Split** — progression graph **Implemented** (`B1-CST` Slice 1,
2026-07-14), the runtime flow that walks it **Implemented** (`B1-CST`
Slice 2, 2026-07-14, see §CampaignManager Contract below), and the campaign save
envelope **Implemented** (`B1-CST` Slice 3, 2026-07-14); campaign-owned rule
mandates/defaults are **Target design**.

A campaign is an ordered progression graph. Unlike every other content resource
it is authored as **JSON**, not `.tres` ([CST-3]): a campaign must stay one
portable, hand-editable document so `B6-CAMPAIGN-SHARING` can later ship it as a
file. Documents live in `data/campaigns/` and are enumerated by the sibling
`resource_manifest.json` like any other export-scanned directory.

```gdscript
class_name CampaignData extends Resource
@export var campaign_id: String = ""      # durable save identity (campaign.campaign_id)
@export var label: String = ""
@export var description: String = ""
@export var is_dev_only: bool = false     # filtered from the player-facing list [CST-6]
@export var start_node_id: String = ""    # defaults to the first authored node
@export var nodes: Array[CampaignNode] = []   # AUTHORED ORDER is the ordering contract

static func parse(raw: Variant, source_path: String, errors: Array[String]) -> CampaignData
func node_ids() -> Array[String]          # authored order, deterministic
func get_node_by_id(node_id: String) -> CampaignNode   # null for unknown — never a fallback
func has_node(node_id: String) -> bool
func next_node_ids_of(node_id: String) -> Array[String]

class_name CampaignNode extends Resource
@export var node_id: String = ""          # durable progression identity [CNC-1]
@export var label: String = ""
@export var map_id: String = ""           # binds to a map_registry id
@export var next_node_ids: Array[String] = []   # empty = terminal; many = branch
@export var required_units: Array[String] = []  # [CST-5] deployment constraints live
@export var excluded_units: Array[String] = []  #   on the NODE, not the map
@export var deployment_cap: int = -1            # -1 = uncapped

func is_terminal() -> bool
```

`DataManager` loads campaigns in the same catalogue pass as classes/weapons/
items/skills and validates them in two stages, both **loud** (`push_error`,
matching the map registry and registry catalogue): `CampaignData.parse` rejects
structural defects (missing `campaign_id`/`map_id`, duplicate or unreachable
nodes, a successor or `start_node_id` that names no node, a unit that is both
required and excluded, a `deployment_cap` of 0), and
`DataManager.collect_campaign_validation_errors` rejects a node bound to a
`map_id` outside the map registry. A campaign too broken to represent parses to
`null` rather than half-loading a run the player cannot finish.

Node bindings are deliberately `map_id` only. `B4-ENCOUNTER-MODEL` later splits
that into a battle-map / battle-encounter pair; binding by map id today is the
adapter-friendly shape `[CNC-3]` asked for. Node contents are author-editable
without breaking saves — only `node_id` is durable identity.

Shipped campaign: `data/campaigns/proving_grounds.json`, a linear five-node run
over the shipped objective maps (rout, seize, boss, escape, defend).

### CampaignManager Contract

Status: **Implemented** (`B1-CST` Slice 2, 2026-07-14; persistence added in Slice 3, 2026-07-14).

`CampaignData` is the graph; the `CampaignManager` autoload is what **walks** it.
It holds the campaign RUNTIME position and owns the prep -> map ->
victory/defeat -> results -> next node flow. It is registered after `DataManager`
(it resolves campaigns and map bindings through the catalogue).

```gdscript
# The campaign position. Persisted as the F1 campaign envelope (Slice 3).
var active_campaign_id: String = ""   # "" == no campaign == every handler no-ops
var current_node_id: String = ""      # the node that launches next; "" == complete
var cleared_node_ids: Array[String] = []

func start_campaign(campaign_id: String) -> bool   # seeds at start_node_id; unknown id fails loud
func end_campaign() -> void
func launch_current_node() -> bool                 # resolve map binding -> GameState.configure_next_map -> GameMap
func resolve_launch_params(node: CampaignNode) -> Dictionary   # map_data_path / roster_policy / roster_source
func get_pending_result() -> Dictionary            # results state handoff
func has_pending_victory() -> bool
func commit_pending_result() -> bool               # the ONLY thing that advances the position; autosaves
func clear_pending_result() -> void                # Retry drops the unapplied result
func is_campaign_active() -> bool
func is_campaign_complete() -> bool

# Persistence (Slice 3) — the serializer seam. SaveManager owns every user:// path.
func capture_campaign_state() -> Dictionary        # exactly campaign_id / node_id / cleared_nodes
func restore_campaign_state(source: Variant) -> bool   # ids must resolve or the load fails
func write_autosave() -> bool                      # the reserved "autosave" slot
func write_campaign_slot(slot_id: String, save_label: String) -> bool   # the manual-save seam
```

Rules this contract fixes:

- **A win records; the commit advances.** `EventBus.map_victory` / `map_defeat`
  record a result against the node that was actually launched, and
  `map_resolved` enriches it with the ranked standings. The position moves only
  when the results surface calls `commit_pending_result` (`GameOverScreen`'s
  "Next"). Advancing on the victory signal itself would break **Retry**, which
  replays the same map: the campaign would sit on node N+1 while node N is
  replayed, and a second win would skip a node. Retry calls
  `clear_pending_result`.
- **Defeat parks.** No clear, no advance — the campaign stays on the current node.
- **The party carries.** The first node of a run seeds the party from the map
  registry's authored `roster_policy`; every later node launches with
  `keep_current_roster`, or levels and gold would reset each map.
- **Additive.** With no campaign active every handler no-ops, so the bare
  single-map launch (`NewGameScreen`) is unchanged. `[CST-6]`'s "every map is a
  1-node campaign" auto-wrap is deferred to the campaign selector.
- **Branch nodes take the first authored successor** until the branch-choice UI
  lands with `B6-CAMPAIGN-SHARING`; authored order is the ordering contract.
- **The position persists; the pending result does not.** `capture_campaign_state`
  writes exactly the reserved F1 rows `campaign.campaign_id` / `campaign.node_id` /
  `campaign.cleared_nodes[]` — Slice 3 added no new persisted field. The pending
  result is deliberately excluded: it is discarded on quit, so a save taken while
  the results surface is up restores parked on the current node and the map is
  simply replayed. Persisting it would let a reload commit a win for a map that
  was never played that session.
- **A restore is all-or-nothing.** `restore_campaign_state` validates the campaign
  id, the node id, and every cleared node against the authored graph BEFORE it
  writes any state; an id that does not resolve fails loud and leaves no campaign
  active, rather than half-restoring a position the graph cannot walk. An empty
  `campaign_id` is a valid save (the bare single-map launch), not a corrupt one.
- **The commit is the autosave point.** `commit_pending_result` advances the
  position and then writes the `autosave` slot — the moment the party is parked
  between maps is exactly the state a campaign slot holds, so every route that
  advances the campaign autosaves rather than each results surface remembering to.

Map bindings resolve through `DataManager.get_map_registry_entry(map_id)` /
`has_map_registry_entry(map_id)` — the registry is cached in the catalogue pass,
so the campaign flow does not re-read `map_registry.json` from disk. An unknown
map id is a loud error, never a fallback launch.

> **Registry migration note.** The field lists above describe the implemented resource
> schema. Where comments name built-in ids, those ids are the developer preset library
> for today's engine. The target registry rows (`B2-REGISTRY`, `B2-ACTION-EFFECT`,
> `B3-REQ`, `B3-STAT-REGISTRY`, `B3-RESOURCE-POOLS`, `B5-AI-COMPOSITION`) are the
> migration path that prevents new content from requiring one more GDScript `match`.

---
