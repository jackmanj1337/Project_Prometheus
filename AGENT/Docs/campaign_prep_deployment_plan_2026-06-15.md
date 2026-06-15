# Pre-Battle Deployment Screen — Implementation Plan

**Status:** Planned (approved 2026-06-15; implementation deferred)
**Last verified:** 2026-06-15
**Authority:** GDD_10 §1.0 Definition (D-D campaign prerequisites); GDD_07 §UI
**Depends on:** `campaign_rules_save_load_plan_2026-06-15.md` (persistent roster/economy + CampaignRules contract)
**See also:** `campaign_rules_firming_notes_2026-05-25.md` (§prep/deployment)

## Context

Today every unit in `GameState.player_roster` is spawned **1:1 onto
`MapData.player_start_tiles`** as faction `blue`, with no selection — see
`GameMap._spawn_units()` (`scripts/core/GameMap.gd:162`). A pre-battle **deployment
screen** is one of the three D-D prerequisites gating the 1.0 campaign: it lets the
player choose which roster units deploy and where, once a roster can exceed a map's
slot count. The firming notes want it "designed together with campaign rules +
save/load," which is now planned — this builds on that.

### Decision taken (2026-06-15)
**Pick + assign to start tiles** (full FE-style prep): slots = the map's
`player_start_tiles`; if the roster exceeds slots, the player selects which units
deploy and assigns each chosen unit to a specific start tile. Benched units stay in
the roster (and the campaign save) but don't spawn.

### Adopted defaults (not asked)
- A read-only **convoy** panel (`GameState.party_items`) is shown on the prep screen;
  **moving items unit↔convoy (trade) is a follow-on phase**, designed with the
  `max_inventory` cap UI — out of scope here.
- Permadeath interaction is unchanged: dead units are already skipped
  (`GameMap._spawn_units` line ~186); deployment selection is orthogonal.

## Key findings from exploration

- **The spawn seam is `GameMap._spawn_units()`** — it currently does
  `roster[i] → player_start_tiles[i]` for all units, faction `"blue"`, via
  `_spawn_unit(u_data, tile, "blue")`. This is the one function deployment must change.
- **`is_roster_ready_for_launch()`** + the roster-policy machinery
  (`scripts/autoloads/GameState.gd`) already gate launch; deployment selection layers
  on top as additional launch state.
- `MapData.player_start_tiles: Array[Vector2i]` defines the slots; `camera_start_tile`
  already centroids them.
- Roster persistence + economy now come from the save/load plan (the prep screen reads
  the loaded `player_roster` / `party_gold` / `party_items`).

## Design

1. **New launch state on `GameState`:** `deployment_assignment: Array[Dictionary]` —
   ordered `{ roster_index: int, tile: Vector2i }`, one entry per deployed unit
   (length ≤ `player_start_tiles.size()`). Empty = "deploy all in roster order" (the
   back-compat default so existing direct-boot / test paths are unchanged).
2. **`DeploymentScreen` (`scripts/ui/DeploymentScreen.gd` + scene):** lists
   `player_roster` (name/class/key stats), a slot grid for the map's start tiles, and
   a read-only convoy panel. The player toggles units in/out and assigns each deployed
   unit to a start tile; a Confirm button (disabled until ≥1 unit deployed and no tile
   double-booked) writes `deployment_assignment` and proceeds to the map. Reuse the
   `ModalScreen` base and the `OptionButton`/list patterns from `SettingsScreen`.
3. **`GameMap._spawn_units()` reads the assignment:** if
   `deployment_assignment` is non-empty, spawn only those `roster_index` units at their
   assigned tiles; else fall back to today's 1:1 behavior (keeps tests green).
4. **Flow:** save/load Continue (or New Game) → route to next map → **DeploymentScreen**
   → confirm → `GameMap`. The screen is skippable for maps where roster ≤ slots if you
   want (decision left to wiring; default = always show in campaign flow).
5. **Convoy panel (read-only v1):** render `party_items` via `DataManager.get_item` /
   `get_weapon` names. No transfer yet.

## Tests (headless, glob-discovered)
- **`test_deployment.gd`** (new): a `deployment_assignment` selecting a subset spawns
  exactly those units at the assigned tiles; empty assignment falls back to 1:1;
  double-booked tile / over-limit assignment is rejected by the validator; benched
  units remain in `player_roster` after the map.
- **Extend `test_game_state.gd`**: `deployment_assignment` is launch state that
  `reset_map_state()` clears but a campaign load can repopulate; it is NOT a campaign
  rule (stays off `CampaignRules`).
- Behavior-neutral guard: existing `test_game_map_scene` spawn tests stay green with
  empty assignment (the default path).

## Documentation (DoD#1)
- GDD_07 §UI: add the Deployment screen surface + its convoy panel (read-only).
- GDD_06 §Maps: note `player_start_tiles` defines deployment slots.
- GDD_10: flip the D-D "pre-battle deployment screen" prerequisite to Implemented
  (deployment + read-only convoy; trade deferred). Bump `Last verified`.
- DoD#2: note whether a checkable rule was ratified (likely none).

## Out of scope
- Item trade (unit↔convoy) and the `max_inventory` cap UI — follow-on.
- Squad-size caps beyond `player_start_tiles` count (no separate `deployment_limit`
  field per the chosen option).
- Formation save (remembering last deployment) — nice-to-have, later.

## Verification
- Headless `bash run_tests.sh` green incl. `test_deployment`.
- Live: a map whose roster exceeds start tiles → prep screen forces a selection →
  confirm → only chosen units appear at chosen tiles; benched units still in the roster
  next map.
