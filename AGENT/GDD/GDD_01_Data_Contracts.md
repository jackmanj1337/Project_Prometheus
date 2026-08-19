# GDD_01 — Data Contracts

**Status:** Active data contract — implemented and target fields are labelled per section.
**Last verified:** 2026-08-19
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
    # compatibility-preserved ids registered under data/registries/item_effects
@export var uses: int = 1                 # -1 = infinite / equippable
@export var cost: int = 0
@export var effect_id: String = ""
    # parameters validated by the selected ItemEffectRegistry entry
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

### Battle map and encounter resources

Implemented by `B4-ENCOUNTER-MODEL` Slices 1-2 on 2026-07-16.

Authored battles split reusable layout from fight payload. `BattleMapDef` owns
identity/display, tilemap/grid, camera/player starts, and `enemy_start_tiles`.
`BattleEncounterDef` owns identity, `battle_map_id`, ordered enemy placements,
factions/scheduling, grouped objectives, and rewards. `ResolvedBattleData` is
the single runtime composition boundary and records split versus legacy origin.
Campaign battle nodes author exactly one of preferred `encounter_id` and legacy
`map_id`; saves remain bound to durable `node_id` and add no field.

Both catalogues are manifest-backed below `data/maps/`. DataManager validates
ids, types, grids/start tiles, map references, placements, factions, scheduling,
objectives, and rewards before launch.

### `MapData.gd` compatibility resource

`MapData` remains supported for direct developer launches and legacy/package
content. DataManager adapts it once at the load boundary into the same
`ResolvedBattleData` shape; gameplay does not branch on legacy fields.

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

## Campaign Data Contracts

Status: **Split** — campaign graph, package/catalogue, status-record,
CampaignManager, and deployment contracts are **Implemented**; public builder and
content-resynchronization tools remain **Deferred**
Last verified: 2026-07-19

### Summary

Campaign content is portable, data-only JSON with durable ids. The engine validates
the complete graph/catalogue before activation, walks it through one campaign
manager, persists only durable campaign state, and treats deployment as transient
between-map input.

### Specs

The subordinate contracts below divide schema, runtime ownership, and validation
without duplicating their code owners.

### CampaignData Contract

Status: **Split** — progression graph **Implemented** (`B1-CST` Slice 1,
2026-07-14), the runtime flow that walks it **Implemented** (`B1-CST`
Slice 2, 2026-07-14, see §CampaignManager Contract below), and the campaign save
envelope **Implemented** (`B1-CST` Slice 3, 2026-07-14); campaign-owned rule
mandates/defaults and their saved authority are **Implemented** (2026-07-15).
Last verified: 2026-07-24

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
@export var author_id: String = ""        # status-record compatibility identity
@export var campaign_version: String = "1.0.0"
@export var compatible_status_sources: Array[Dictionary] = []
@export var protected_fields: Array[String] = [] # dotted save paths added to protected hash
@export var is_dev_only: bool = false     # filtered from the player-facing list [CST-6]
@export var start_node_id: String = ""    # defaults to the first authored node
@export var nodes: Array[CampaignNode] = []   # AUTHORED ORDER is the ordering contract
@export var rule_overrides: Dictionary = {}  # normalized rule_id -> value
@export var mandated_rule_ids: Array[String] = []

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
@export var rule_overrides: Dictionary = {}     # open rule-id -> map value layer

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

`DataManager` deterministically auto-wraps every map-registry entry as
`single_map__{map_id}` with one terminal `map` node. The wrapper inherits label,
description, and `is_dev_only`; the same helper is applied after Tier-2 package
activation, and pack discovery exposes matching inert selector summaries. An
authored collision with the reserved generated id fails loud instead of silently
replacing either campaign.

An authored `rules` entry may be `{authority:"mandate", value:...}` (locked) or
`{authority:"default", value:...}` (editable). Legacy direct values normalize as
editable defaults. `CampaignManager` seeds both values and mandate ids before a
run; New Game locks visible mandated controls while allowing defaults to change,
and `SaveData.campaign.rules.mandated_rules[]` preserves the authority on reload.
Each node may also author `rule_overrides`; these are transient map-layer values,
not permanent edits to the campaign defaults.

`protected_fields` is stamped into each save and interpreted as dotted paths from
the save root. These author additions join the mandatory progression/rules
baseline in the protected SHA-256 projection; they never replace that baseline.

### CampaignStatusRecord Contract

Status: **Implemented 2026-07-15** (`B6-CAMPAIGN-STATUS`)
Last verified: 2026-07-15

A status record is portable player state, not a full save and never pack content.
Its fixed envelope is `format_version`, `record_id`, `author_id`, `campaign_id`,
`campaign_version`, `created_at_utc`, `completion`, `facts`, `counters`, and a
SHA-256 `checksum`. `facts` and `counters` are open dictionaries; adding a story
fact requires no resource-field or engine-switch edit.

Completion exports the active store's carry-forward facts plus the compact
ending/maps/turns/gold subset. New Game scans records automatically for same-campaign
NG+ or an authored `compatible_status_sources` row (author, source campaign, and
optional accepted version list). It always offers **None**. Foreign records are
absent from automatic results and require the explicit manual import action.
Checksum/schema failure changes no new-run state. A successful choice writes the
source identity/checksum to `MutableCampaignState.imported_record_ref`, copies
facts into its `carry_forward_facts`, and seeds the normal open `campaign.vars`
store used by conditions/predicates. Re-export stages the replacement record and
rolls back to the prior record if filesystem promotion fails.

Campaigns may author open `status_import_benefits` rows matched by source
author/campaign/version. After the first-node roster loads, a matching row may
replace the new party wallet with the recorded completion gold and grant
pack-catalogued items to authored unit ids. Benefits validate all unit/item
targets before mutation and apply once. Tier-2 catalogues therefore support the
`item` kind alongside campaign, map, roster, and class documents.

### Typed Campaign Variables

Status: **Implemented 2026-08-19** (`B3-TCV`)
Last verified: 2026-08-19

`CampaignVarDef` entries declare open `bool`, bounded `int`, and option-backed
`enum` variables. Each definition also declares campaign or map scope and whether
the value is locked, selected at run start, or adjustable mid-run. `CampaignVars`
validates every read/write against those definitions: unknown ids, wrong types,
out-of-range integers, and unknown enum options fail loud.

Campaign-scope values share the existing `campaign.vars` save-envelope row and
survive a campaign save round-trip. Map-scope values are transient and reset with
`GameState.reset_map_state()`. `UnitData.groups` is the authored semantic-tag
surface consumed by the shared requirement system's later `in_group` predicate.

### Shared Requirements and Formula Terms

Status: **Pending validation 2026-08-19** (`B3-REQ` / `F16`)
Last verified: 2026-08-19

Requirements use one author-facing boolean tree (`all`, `any`, `not`) over
registered predicate ids. Consumers supply an explicit context, so campaign,
prep, and menu gates evaluate without a loaded tactical map. Results include the
boolean answer, a trace, and structured unmet reasons rendered through stable
text keys. Existing tactical objective conditions remain compatible through the
same result envelope while their established registry continues to evaluate them.

Formula terms use signed fixed-point values scaled by 1000. The shared evaluator
validates arithmetic trees before evaluation, requires an explicit divide-by-zero
policy, applies bounded node/depth budgets, and exposes registered value sources
instead of consumer-local switches.

### Campaign Tier-1 Asset References

Status: **Implemented** (`B6-CAMPAIGN-SHARING`, 2026-07-15).
Last verified: 2026-07-15

`WeaponData.icon` and `ItemData.icon` are optional string ids/pack-relative paths,
not `Texture2D` fields. `AssetResolver` resolves those references inside a selected
campaign root through two registries: engine-provided loader primitives and
author-provided asset groups. Each group names a loader plus an ordered fallback
chain. Missing optional media returns the registered fallback (or `null`) and adds
a structured repair-report row; it is not a content-load crash. Paths may not be
absolute or traverse outside the pack root.

The implemented raw primitives cover PNG textures, TTF/OTF fonts, OGG music/SFX,
and WAV SFX. The resolver deliberately does not enumerate packs, validate Tier-2
JSON, install archives, or choose the active campaign; those responsibilities
belong to the package catalogue/validator/installer and `DataManager` seams.

### Campaign Package Manifest and Tier-2 Catalogue

Status: **Implemented** (`B6-CAMPAIGN-SHARING`, 2026-07-15); manifest/catalogue,
archive pipeline, discovery, Tier-2 runtime adaptation, explicit campaign
selection, and player-facing package import/export are shipped.
Last verified: 2026-07-15

`PackManifest` parses the package identity document at `manifest.json`. Its
required fields are `id`, `version`, `builder_content_version`, and integer
`format_version`; optional `forked_from` records lineage without changing pack
identity. Format version 1 is the only accepted package contract. Pack ids use
portable lowercase letters, digits, `_`, and `-`. Malformed or incompatible
manifests return no partial object and collect actionable validation errors.

The canonical Tier-2 index is the pack's data-directory `catalogue.json`:

```json
{
  "format_version": 1,
  "entries": [
    {"kind": "campaign", "id": "proving_grounds", "path": "data/campaign.json"}
  ]
}
```

Authored entry order is deterministic catalogue order. Every `{kind, id}` and
path is unique; paths must be relative `.json` files below `data/` and cannot
name the catalogue itself or traverse outside the pack. `Tier2Catalogue` reads
the index and documents, then dispatches a non-mutating schema validator
registered for each `kind`. An unknown kind fails loud rather than loading
unchecked content. This preserves the open-registry extension rule: a new
content family registers a validator instead of adding a closed type switch.

The concrete validator registry covers the playable campaign-pack surface:
`campaign`, `map_registry`, `map_data`, `roster`, `class`, `item`, and `weapon`. Existing
`CampaignData.parse` owns campaign graph structure; the other handlers enforce
their JSON identity/required-field boundaries. A second whole-catalogue pass
then proves campaign node -> map registry entry -> map data/roster -> class and
inventory -> weapon references before archive I/O can consume the pack. Missing structured
dependencies reject the complete catalogue rather than leaving a partial pack.

This boundary only parses and validates. It does not extract/copy archives,
write `user://campaigns`, replace `DataManager` catalogues, register campaigns
with a selector, or select runtime content. Those downstream consumers may act
only on a successfully validated manifest/catalogue result.

`CampaignTier2RuntimeAdapter` is the explicit bridge from this JSON contract to
the engine's existing `CampaignData`, `MapData`, `ClassData`, and `UnitData`
objects. It creates no generated resources and never edits installed bytes.
Package-scoped `campaign-pack://{id}/{version}/{map_id}` identifiers let the
existing launch/suspend paths resolve in-memory maps while keeping a durable save
identity. Runtime activation is all-or-nothing: the adapter builds and validates
a complete replacement set before `DataManager` swaps live registries.

The zero-content boundary is **Implemented 2026-08-09**. `DataManager` and
`RegistryManager` begin inactive and playable content can enter the runtime only
through one validated, self-contained campaign package. A `ContentSession` owns
the candidate catalogues and package identity; failed Tier-2 candidates preserve
the prior session, and package deactivation clears both managers back to empty
catalogues. The checked-in `data/` tree remains an authoring/extraction fixture,
but every export preset excludes it and its compatibility bridge is editor-gated;
no exported player or New Game path can activate it.

Package-backed campaign resume is also one outer transaction. Values that can be
checked against the current catalogues are staged first; the saved package then
activates so its campaign references can resolve. Any rejection after activation
restores the complete prior `ContentSession`, registry catalogue, campaign position,
rules, mutable overrides, convoy, and roster together. A failed Continue therefore
cannot leave a mixed old-campaign/new-package runtime.

`content_status()` reports the two outcomes separately and they never mix.
`errors` is why activation **failed**; a commit clears it, so a non-empty list
always means no content went live. `warnings` are content-authoring facts about
the content that **is** live — an id a document references and the active
catalogues cannot resolve. Those leave one skill or item inert rather than the
pack unplayable, so they are reported as warnings and never refuse activation:
a Tier-2 pack carries no skills catalogue yet, and failing on an unresolved
skill id would make every pack unlaunchable.

An unresolved id is reported **once per content activation**, not once per
lookup (`V070-11`). Activation walks the units the committed package carries —
its rosters and the enemies placed on its maps — and reports each distinct unresolved skill id with the unit that named
it; this is the coverage `collect_validation_errors` never had, since it walks
`ClassData.skill_unlocks` and no unit's own skill arrays. An id reached by any
other route is still reported by the first lookup that misses it, and then
suppressed. Lookups keep returning `null` and callers keep null-checking: only
the report's cardinality changed. Per-call reporting made one authored typo cost
roughly 3,200 identical `ERROR:` lines in a single returned v0.7.0 session,
which is what trains a triager to skim past `ERROR:` lines.

### CampaignManager Contract

Status: **Implemented** (`B1-CST` Slice 2, 2026-07-14; persistence added in Slice 3, 2026-07-14).
Last verified: 2026-07-15

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
func prepare_pending_advance() -> bool             # validate successor binding + roster without consuming win
func commit_pending_result() -> bool               # the ONLY thing that advances the position; autosaves
func launch_prepared_node() -> bool                 # launch only the validated successor
func clear_pending_result() -> void                # Retry drops the unapplied result
func restore_retry_branch(source: Variant, node_id: String) -> bool # branch active run after a committed Save
func is_campaign_active() -> bool
func is_campaign_complete() -> bool

# Persistence (Slice 3) — the serializer seam. SaveManager owns every user:// path.
func capture_campaign_state() -> Dictionary        # position plus campaign flags/vars
func restore_campaign_state(source: Variant) -> bool   # ids/shapes must validate or load fails
func has_campaign_flag(flag_id: String) -> bool
func set_campaign_flag(flag_id: String, enabled: bool = true) -> bool
func get_campaign_var(var_id: String, default_value: Variant = null) -> Variant
func set_campaign_var(var_id: String, value: Variant) -> bool
func write_autosave() -> bool                      # origin:auto / campaign_progress
func write_campaign_slot(slot_id: String, save_label: String,
    origin: String = "manual", rule_id: String = "") -> bool
```

Rules this contract fixes:

- **A win records; the commit advances.** `EventBus.map_victory` / `map_defeat`
  record a result against the node that was actually launched, and
  `map_resolved` enriches it with the ranked standings. The position moves only
  when `MapResultsScreen` calls `commit_pending_result`. Advancing on the victory
  signal itself would break **Retry**, which
  replays the same map: the campaign would sit on node N+1 while node N is
  replayed, and a second win would skip a node. Before commit, Retry calls
  `clear_pending_result`. Results captures the pre-commit position so Retry after
  Save can call `restore_retry_branch`: the active run returns to the just-played
  node while the already-written advanced save remains an independent timeline.
- **Defeat parks.** No clear, no advance — the campaign stays on the current node.
- **The party carries.** The first node of a run seeds the party from the map
  registry's authored `roster_policy`; every later node launches with
  `keep_current_roster`, or levels and gold would reset each map. Between-map
  saves also round-trip temporary flat party item ids through
  `party.convoy.entries[]`, preserving duplicates and treating an empty saved
  list as an explicit clear.
- **One player path.** New Game has no bare-map bypass: map-registry entries are
  generated one-node campaigns and therefore use the same prep, result, save,
  Retry, and source-identity lifecycle. Direct state configuration remains only
  as an engine/test seam; campaign handlers still no-op safely without an active run.
- **Branch nodes require an explicit choice.** The results surface lists valid
  destination labels in authored order. No successor, preparation, autosave, or
  position mutation occurs until the player selects a real outgoing edge.
- **Only authored terminal nodes finish.** A nonterminal result with no valid
  successor fails closed as a campaign-data error; it never relabels Continue as
  Finish Campaign or consumes the pending victory.
- **Results retain player-unit dispositions.** Per-map blue-unit removals are
  captured before the victory payload: permadeath is labelled `Fallen`, casual
  removal is labelled `Retreated`, and escape/removal paths do not count as casualties.
- **The position and campaign author state persist; the pending result does not.**
  `capture_campaign_state` writes the reserved F1 position, `campaign.flags`, and
  `campaign.vars` rows. Flags are a deduplicated open string vocabulary; vars are
  an open keyed dictionary. The pending
  result is deliberately excluded: it is discarded on quit, so a save taken while
  the results surface is up restores parked on the current node and the map is
  simply replayed. Persisting it would let a reload commit a win for a map that
  was never played that session.
- **A restore is all-or-nothing.** `restore_campaign_state` validates the campaign
  id, the node id, every cleared node, flag/var shapes, convoy item references,
  rules, and roster before it
  writes any state; an id that does not resolve fails loud and leaves no campaign
  active, rather than half-restoring a position the graph cannot walk. Legacy
  engine/test documents may still carry an empty campaign id, but New Game no
  longer authors that shape.
- **The commit is the autosave point.** `commit_pending_result` advances the
  position and then writes the `autosave` slot — the moment the party is parked
  between maps is exactly the state a campaign slot holds, so every route that
  advances the campaign autosaves rather than each results surface remembering to.
- **Successor validation precedes the commit.** A non-terminal pending victory
  must pass `prepare_pending_advance`: the successor node, map-registry binding,
  map path, and carried roster are resolved before position changes. Failure
  leaves the pending result, current node, and Next action retryable.
- **Slot/index writes are one transaction.** `SaveManager.save_slot` stages the
  validated document and its full index update (row plus Continue pointer), then
  replaces both with the index as commit marker. A replacement failure restores
  the prior slot/index pair and removes temporary/backup files.
- **One slot namespace.** Mid-map and between-map documents both use
  `SaveManager.save_slot`; `map_runtime.map_path` is the intrinsic discriminator.
  `GameState.capture_save` selects the document shape from whether a live
  `TurnManager` is supplied. Every document carries `origin: manual|auto` and
  autos carry `rule_id`. A mid-map document also carries the complete reason-tagged
  rewind `ledger[]`, while the mirrored header carries `save_kind`, `turn_number`,
  and `map_id` so Load Game never opens N documents to label them.

Map bindings resolve through `DataManager.get_map_registry_entry(map_id)` /
`has_map_registry_entry(map_id)` — the registry is cached in the catalogue pass,
so the campaign flow does not re-read `map_registry.json` from disk. An unknown
map id is a loud error, never a fallback launch.

### Deployment Plan Contract

Status: **Implemented 2026-07-15** — the plan seam, validator, PrepScreen author,
campaign routing, and manual-save surface are built (`B4-PREP-DEPLOYMENT`
Slices 1-3).
Last verified: 2026-07-15

The deployment plan is the player's answer to "who fights this map, and where do
they stand". It replaces an **inference** with a **choice**: before this slice,
`GameMap` derived the player's side from roster order truncated by the start-tile
count — a fallback that merely looked like a decision.

```gdscript
# GameState — launch staging, beside next_map_data_path / next_map_roster_policy.
var next_map_deployment: Dictionary = {}    # unit_id (String) -> start tile (Vector2i)
func set_next_map_deployment(plan: Dictionary) -> void
func clear_next_map_deployment() -> void

# scripts/shared/DeploymentPlan.gd — the validator, with two consumers: prep (to
# gate Begin Battle) and GameMap (to refuse an illegal plan). `node` may be null.
static func validate(plan: Dictionary, roster: Array[UnitData], node: CampaignNode,
		start_tiles: Array[Vector2i]) -> Array[String]   # empty == legal
```

Rules this contract fixes:

- **The plan is a Dictionary keyed by `unit_id`,** which structurally forbids
  deploying one unit twice. Two units on one tile, a tile that is not a
  `MapData.player_start_tiles` entry, a unit outside the party, and a plan larger
  than the start-tile count are all rejected by the validator instead.
- **An empty plan means "no prep screen ran", not "deploy nobody".** `GameMap`
  keeps the historical roster-order fallback for direct engine/test launches;
  New Game's generated single-map campaigns run Prep like every other campaign.
- **`GameMap` revalidates before it spawns.** Prep gates Begin Battle on a legal
  plan, so an illegal plan reaching the map means the party or the map changed
  underneath it; the launch fails loud rather than spawning a half-legal board.
- **The plan is NOT persisted.** It is chosen at prep and consumed at launch, and
  a campaign save is parked BETWEEN maps — so a reload lands back on prep and the
  player deploys again. Same reasoning as the unpersisted pending result above,
  and it means no new F1 save row is owed. It DOES survive a **Retry**. Campaign
  Retry restores ledger entry 0 and reroutes to PrepScreen, where the surviving
  plan is the editable pre-selection. Bare-map Retry still reloads directly, and
  suspend-resumed Retry never enters prep because its serialized live board would
  ignore a fresh deployment plan.
- **The `[CST-5]` node constraints are consumed here, for the first time.**
  `CampaignNode.required_units` / `excluded_units` / `deployment_cap` have been
  authored and validated since `B1-CST` Slice 1 with no reader; prep is that
  reader, which is why no schema change was owed. `deployment_cap` is `-1` for
  uncapped (and `CampaignData` rejects `0`).
- **A fallen `required_unit` is EXCUSED, not a launch block.** Under permadeath a
  dead unit stays in the roster (spawn skips it), so a node can legitimately
  require a unit the player has lost. Blocking would strand the campaign: no legal
  plan for that node could ever exist again, and the player's only recovery would
  be an older save. Whether a key death should END the run is a campaign-rules
  question (permadeath game-over), not a prep-validation one. A required unit that
  was never in the party at all is a different thing — an authoring error — and
  still fails loud.
- **Benched units gain nothing** (campaign flow technical plan §4): a unit left
  out of the plan is never spawned, so it accrues no XP, levels, or items.

### Known gaps

- Public builder editing/repair remains `B8-PUBLIC-BUILDER` (**Deferred**).
- Installed content resynchronization remains `B8-CONTENT-RESYNC` (**Deferred**).
- Recruitment and broader Prep services retain their own control-plane tracks.

### Anchors

- Code: `scripts/resources/CampaignData.gd`,
  `scripts/autoloads/CampaignManager.gd`,
  `scripts/shared/DeploymentPlan.gd`,
  `scripts/resources/CampaignStatusRecord.gd`,
  `scripts/resources/Tier2Catalogue.gd`, and
  `scripts/resources/CampaignTier2RuntimeAdapter.gd`.
- Tests: campaign data/manager, deployment/Prep, package catalogue/adapter, and
  campaign-status suites under `scripts/tests/`.
- Roadmap: `B1-CST`, `B4-PREP-DEPLOYMENT`, `B6-CAMPAIGN-SHARING`, and
  `B6-CAMPAIGN-STATUS`.
- Deferred owners: `B8-PUBLIC-BUILDER`, `B8-CONTENT-RESYNC`.

> **Registry migration note.** The field lists above describe the implemented resource
> schema. Where comments name built-in ids, those ids are the developer preset library
> for today's engine. The target registry rows (`B2-REGISTRY`, `B2-ACTION-EFFECT`,
> `B3-REQ`, `B3-STAT-REGISTRY`, `B3-RESOURCE-POOLS`, `B5-AI-COMPOSITION`) are the
> migration path that prevents new content from requiring one more GDScript `match`.

---
