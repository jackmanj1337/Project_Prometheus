# Code Review — 2026-05-24

## 1. Executive Summary
- **Overall code quality rating:** 8/10
- The recent More Info work is cohesive, well-commented, and backed by solid test coverage. The biggest concerns are around behavioral accuracy at integration boundaries: the HUD can currently imply tile actions are immediately available when they are only conditionally available, and some of the new UI behavior still depends on fragile scene wiring or manual playtest coverage.

## 2. Issues Found

**[SEVERITY: Medium]**
- **File & Line:** `scripts/ui/HUD.gd:312`, `scripts/shared/TileActions.gd:39`, `scripts/core/TurnManager.gd:899`
- **Problem:** The expanded terrain HUD can claim a selected unit can `Seize` or `Escape` on the cursor tile even when that action is not actually available in the current turn flow yet. `TileActions.available_for()` only asks whether the authored objective gate matches `(unit, tile)`. It does not check whether the unit can currently end movement on that tile, whether the cursor is previewing a legal destination, or whether the unit is already standing there. That means the HUD can disagree with `ActionMenu`, which only appears after movement is committed on the real tile.
- **Root Cause:** The helper was extracted as a single source of truth for tile-action gating, but its API models only objective eligibility, not turn-state reachability.
- **Recommended Fix:** Split the concept into two checks: one for objective eligibility and one for “available right now in the current flow.” For example:

```gdscript
static func is_conditionally_available(action_id: String, unit: Node,
		tile: Vector2i, turn: Node) -> bool:
	# current TurnManager-backed logic

static func is_available_now(action_id: String, unit: Node, tile: Vector2i,
		turn: Node, grid: Node, movement_range: Dictionary = {}) -> bool:
	if not is_conditionally_available(action_id, unit, tile, turn):
		return false
	if unit == null:
		return false
	if tile != unit.tile_position and not movement_range.has(tile):
		return false
	return true
```

- **Tradeoffs:** This adds some API surface and forces the HUD to know more about current cursor/move state. The alternative is weaker but simpler wording in the HUD, such as “Possible on this tile if the unit ends here.”

**[SEVERITY: Medium]**
- **File & Line:** `scripts/ui/HUD.gd:347`
- **Problem:** `_higher_priority_more_info_visible()` hard-codes absolute scene paths (`GameMap/HUDLayer/AttackPreview` and `GameMap/UnitDetailsLayer/UnitDetailsScreen`). If either node is renamed, reparented, instanced under a different root, or reused in another scene, the F-key priority chain quietly stops working.
- **Root Cause:** The HUD reaches outward through the scene tree instead of receiving references during setup or using a looser lookup mechanism.
- **Recommended Fix:** Inject these dependencies in `HUD.setup()` or register the hosts in a group:

```gdscript
var _attack_preview: Control = null
var _unit_details: Control = null

func setup(grid: Node, turn_node: Node, attack_preview: Control = null,
		unit_details: Control = null) -> void:
	_grid = grid
	_turn_manager = turn_node
	_attack_preview = attack_preview
	_unit_details = unit_details
```

- **Tradeoffs:** Slightly more setup wiring in `GameMap`, but it removes a brittle hidden dependency on one exact scene layout.

**[SEVERITY: Low]**
- **File & Line:** `scripts/shared/MoreInfoContent.gd:64`
- **Problem:** Terrain More Info coverage is incomplete for terrain ids already used elsewhere in the project, notably `desert` and `wall`. The HUD does not crash because `describe()` has a fallback, but players will still see “No description yet” on common terrain types in a feature that was just shipped as learn-mode UX.
- **Root Cause:** The coverage test only verifies that the terrain category has at least one authored entry, not that all authored gameplay terrain ids are covered.
- **Recommended Fix:** Add descriptions for every terrain currently surfaced by `GridManager`, and extend `test_more_info_content.gd` to assert coverage for the full authored terrain set.

```gdscript
const TERRAIN: Dictionary = {
	"plain":    "...",
	"forest":   "...",
	"mountain": "...",
	"fort":     "...",
	"sea":      "...",
	"desert":   "...",
	"wall":     "...",
}
```

- **Tradeoffs:** Slightly more copy to maintain now, but it prevents placeholder text from leaking into normal play.

## 3. Positive Observations
- The More Info feature is consistently structured across `UnitDetailsScreen`, `AttackPreview`, and `HUD`, which reduces cognitive load for both players and future maintainers.
- The `TileActions` extraction is directionally correct. Centralizing labels and objective-gate logic is the right move even though the API needs one more pass.
- `AttackPreview.gd` is unusually readable for UI code with selection, content rendering, and camera-aware positioning all in one file. The inline comments explain intent rather than restating syntax.
- Test coverage is strong overall. The new work shipped with dedicated tests for selector behavior, HUD expansion, tile actions, and camera pan clamping, and the full suite is still green.

## 4. Architectural Observations
- The current More Info priority chain is implemented as distributed visibility checks across three UI surfaces. That works today, but it would scale better if one small coordinator owned “which surface currently owns F”.
- `MoreInfoContent.gd` is still a reasonable inline table at this size, but it is already acting like authored content data rather than logic. If terrain/item/skill copy expands, moving it into a data file will reduce merge pressure.
- `AttackPreview` repositioning is the least deterministic part of the new feature and is still validated mainly by playtest. That is understandable in Godot UI tests, but it remains the area most likely to regress under viewport/layout changes.

## 5. Prioritized Action Plan
1. Fix the HUD tile-action semantics so it cannot imply `Seize`/`Escape` are available “now” when they are only conditionally valid on that tile.
2. Remove the hard-coded `GameMap/...` path dependency from the HUD’s More Info priority check.
3. Fill in missing terrain descriptions for all currently authored terrain ids and strengthen the coverage test accordingly.
4. If the More Info UI is iterated again, extract `AttackPreview` positioning math into a purer helper so it can be tested without relying on a live layout pass.

## Notes
- Assumption: this review focused on the recently landed More Info Phase 1 work from commits `51b0cdb`, `2ed9efc`, and `46f5e70`, because the worktree is clean and there is no open uncommitted diff to review.
- Verification run during review: `./run_tests.sh` completed successfully with all suites green.
