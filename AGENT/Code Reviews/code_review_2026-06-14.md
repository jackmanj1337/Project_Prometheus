# Code Review — v0.1.4 playtest fix pass (2026-06-14)

**Scope:** all production changes since the playtest results came back —
`3e77577..HEAD` (commits `09e47fb`…`a4ceaa1`). 13 production files
(`scripts/**.gd`, `scenes/ui/PromotionScreen.tscn`, `data/weapons/*`) plus their
tests and docs. Tests and GDD/notes are supporting material and not re-reviewed
line-by-line here.

Reviewer note: I wrote these changes, so this is a deliberately adversarial
self-review — I went looking for what I got wrong, not for confirmation.

## 1. Executive Summary

**Overall quality: 8.5 / 10.**

The fixes are correct, narrowly scoped, and each is backed by a focused regression
test — including two that convert previously-untestable logic (combat-preview
placement; the pair-up bonus pipeline) into pure, asserted helpers. The standout is
that the pair-up bonus bug (#3) was found *by writing the test*, not by reading the
code, which corrected an earlier wrong "this path is fine" conclusion. Biggest
remaining concerns are not in the changed code but adjacent to it: a sibling UI scene
(`ReclassScreen.tscn`) still carries the exact un-centered layout pattern that was
just fixed in `PromotionScreen.tscn`, and a couple of defensive edge cases in the new
Swap and preview-placement paths. None are shipping blockers.

## 2. Issues Found

### [Medium] ReclassScreen shares the un-centered fixed-offset layout that PromotionScreen just lost
- **File & Line:** `scenes/ui/ReclassScreen.tscn:27-32` (`Panel`: `layout_mode = 0`,
  `offset_left = 320`, `offset_right = 960`)
- **Problem:** This is the same left-pinned, fixed-width, no-grow layout that caused
  the promotion modal to run off the right edge (#8.7). It is currently masked because
  ReclassScreen wraps its options in an `OptionsScroll` `ScrollContainer` (so content
  can't force the panel wider) and the tester passed 8.6. But the panel is still pinned
  by absolute offsets rather than centered, so it is only coincidentally centered at
  1280×720 and will drift at other viewport sizes — exactly the fragility we removed
  from PromotionScreen.
- **Root Cause:** The two modals were authored from the same template; only
  PromotionScreen was in the playtest's failing path, so only it got fixed.
- **Recommended Fix:** Apply the same change as PromotionScreen — center via anchors
  with symmetric grow:
  ```
  [node name="Panel" type="PanelContainer" parent="."]
  anchors_preset = 8
  anchor_left = 0.5 ; anchor_top = 0.5 ; anchor_right = 0.5 ; anchor_bottom = 0.5
  offset_left = -320.0 ; offset_top = -275.0 ; offset_right = 320.0 ; offset_bottom = 275.0
  grow_horizontal = 2 ; grow_vertical = 2
  ```
  Keep the existing `OptionsScroll`.
- **Tradeoffs:** None functional; it's a layout consistency + resolution-robustness fix.

### [Low] Swap leaves registry roles desynced if the partner Node is invalid
- **File & Line:** `scripts/core/MapCursor.gd:_commit_swap_roles` (the
  `registry.call("swap_roles", …)` then `is_instance_valid(new_lead)` guard)
- **Problem:** `swap_roles()` flips the registry role labels with no liveness check.
  If `find_unit_by_id(partner_id)` then returns null/invalid, the position swap is
  skipped but the **roles stay flipped** — leaving the on-map unit tagged `support`
  while it is still on the map. `get_living_units_of` would then exclude a visible,
  on-map unit.
- **Root Cause:** Roles are mutated before the partner Node is resolved.
- **Recommended Fix:** Resolve the partner *before* `swap_roles()` and bail if it's
  invalid (don't flip roles you can't physically complete):
  ```gdscript
  var new_lead := gs.find_unit_by_id(registry.call("get_partner_id", old_lead.data.unit_id))
  if not is_instance_valid(new_lead) or new_lead.data == null:
      _finish_action(); return
  if not registry.call("swap_roles", old_lead.data.unit_id):
      _finish_action(); return
  # …then the position swap, which is now guaranteed to run.
  ```
- **Tradeoffs:** None. Note this edge is **not reachable in normal play** — a paired
  support is off-map and unkillable, so it's alive whenever Swap is offered. This is
  defensive only.

### [Low] AttackPreview couples to the HUD via a hardcoded node path
- **File & Line:** `scripts/ui/AttackPreview.gd:_hud_avoid_rects`
  (`get_node_or_null("../../HUDMainLayer/HUD")`)
- **Problem:** The preview reaches across two CanvasLayers by literal path. If the
  GameMap scene tree is reorganized, avoidance silently turns off (returns `[]`).
- **Root Cause:** Quickest way to get the HUD rects without changing `setup()`'s
  signature.
- **Recommended Fix:** Inject the HUD (or an avoid-rect provider) through
  `AttackPreview.setup(...)` from the GameMap wiring, the same way `camera` /
  `camera_ctrl` are passed. Keep the null-safe `[]` fallback.
- **Tradeoffs:** Touches the one `setup()` call site; small. Acceptable to defer since
  the failure mode is graceful (no avoidance, still viewport-clamped).

### [Low] `_place_clear_of` is single-pass for multiple avoid rects
- **File & Line:** `scripts/ui/AttackPreview.gd:_place_clear_of`
- **Problem:** Nudging clear of one rect can re-introduce overlap with another rect
  processed earlier in the loop. With the three HUD corners this is unlikely (a panel
  rarely overlaps two at once), but it's not guaranteed.
- **Root Cause:** Deliberately simple, best-effort avoidance for a low-priority cosmetic
  issue.
- **Recommended Fix:** If it ever matters, iterate to a fixpoint (re-run until no
  overlap or no progress) or pick the largest contiguous gap. Documented as best-effort
  for now.
- **Tradeoffs:** Added complexity for a cosmetic gain; not worth it yet.

### [Low] PromotionScreen has no ScrollContainer; tall content can clip vertically
- **File & Line:** `scenes/ui/PromotionScreen.tscn` (`Panel` is content-sized with
  `grow_vertical = 2`, no scroll)
- **Problem:** With the panel now content-sized, a class offering many promotion
  targets with long autowrapped rows could exceed the viewport height and clip the
  Cancel button (no scrollbar, unlike ReclassScreen).
- **Root Cause:** Promotion targets are ≤3 today (Hero/Sentinel/Bow Knight), so a
  scroll affordance wasn't needed.
- **Recommended Fix:** If promotion target counts ever grow, wrap `Options` in a
  `ScrollContainer` with a capped panel height (mirror ReclassScreen). Not needed now.
- **Tradeoffs:** None; purely future-proofing.

## 3. Positive Observations

1. **Test-first caught a real bug.** The pair-up bonus fix (#3) only surfaced because
   the asserting test failed; the root cause (every stat sharing one `add_modifier`
   source, so each wiped the last) was invisible to static reading. The fix mirrors the
   pattern `SkillHandler`'s Resolve already documents — consistent, not novel.
2. **Previously-untestable logic was made testable.** `_place_clear_of` (preview
   placement) and `_pairup_bonus_text` were written as pure/seam-friendly functions so
   they could be unit-tested headlessly, where the old positioning code explicitly
   gave up ("verified by playtest").
3. **Durable, generalized guard.** `test_unit_inventory_refs.gd` scans *every* UnitData
   under `data/maps` + `data/roster` for dangling weapon/item refs — it guards the whole
   class of defect, not just `iron_axe`.
4. **Consistent graceful degradation.** HUD avoidance → plain viewport clamp when the
   HUD isn't reachable; pair-up/preview helpers → `SKIP`/empty when autoloads are
   absent; rout eval uses an explicit true-liveness query. Failures are soft, not crashes.
5. **Docs discipline.** Every behavior change carried its GDD section + GDD_10 status +
   `Last verified` bump in the same commit (PL#8), and the triage mistake was corrected
   in-place rather than left to mislead.

## 4. Architectural Observations

- **`get_living_units_of` vs `get_all_living_units_of` is now a load-bearing
  distinction.** The split is correct (selection/turn-end excludes off-map supports;
  objective liveness counts them), but it's a footgun: a future objective evaluator
  could pick the wrong one and silently mis-resolve a map. The doc-comments are good;
  consider funneling all objective-liveness reads through a single named helper so the
  choice can't be made wrong at a new call site. (The EnemyAI `OFF_MAP_TILE` backstop is
  a second, position-based safety net for the same hazard — good defense in depth.)
- **Combat-only modifiers are invisible outside combat by design.** The pair-up
  indicator works around this by recomputing the bonus on demand in the HUD. That's fine
  for one feature, but if more combat-only bonuses become player-relevant outside a
  fight (auras, conditions in M8), a single "effective-stats-for-display" path would beat
  N per-feature recompute call sites. Worth keeping in mind, not acting on now.
- **Two near-identical modal scenes (Promotion / Reclass) drift independently.** The
  Medium finding above is a symptom. If a third class-change modal appears, factor the
  shared centered-panel chrome into one base scene.

## 5. Prioritized Action Plan

1. **Center `ReclassScreen.tscn`** the same way as PromotionScreen (Medium; ~5 min,
   resolution-robustness + consistency). Best impact/effort. — **DONE `92a171b`**
   (re-centered + on-screen test).
2. **Make Swap resolve the partner before flipping roles** (Low; tiny, removes a
   defensive desync). Quick win. — **DONE `92a171b`** (resolve-first + guard test).
3. **Route objective-liveness through one helper / lint** so `get_living_units_of` can't
   be misused by future evaluators (Low-Medium; small, prevents a repeat of #4-A).
   — **DEFERRED to next session.**
4. **Inject the HUD into AttackPreview via `setup()`** to drop the hardcoded path (Low;
   defer — graceful fallback today). — **DEFERRED to next session.**
5. **ScrollContainer / fixpoint avoidance** for PromotionScreen and `_place_clear_of`
   (Low; future-proofing only, not needed at current content scale).
   — **DEFERRED to next session.**

No critical or high-severity issues. The changed code is shippable as-is; the items
above are hardening and consistency. #1 and #2 are done; #3–#5 are explicitly
deferred to next session (none blocks the v0.1.5.0 build).
