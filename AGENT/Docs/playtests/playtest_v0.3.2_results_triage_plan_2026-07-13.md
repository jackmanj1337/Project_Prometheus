---
Role: dated
---

Status: Planned - owner decisions resolved; implement next session
Last verified: 2026-07-13

# v0.3.2 Playtest Results and Root-Cause Triage

## Evidence and outcome

The returned checklist is preserved as
[`playtest_checklist_v0.3.2_returned_2026-07-13.md`](playtest_checklist_v0.3.2_returned_2026-07-13.md).
Both returned logs are preserved in `AGENT/Docs/archive/evidence/` as
`godot_v0.3.2_session_2026-07-13.log` and
`godot_v0.3.2_session_2026-07-13T14.50.57.log`.

- `VAL-V023-DISPLAY`: **Implemented**. Width-only and height-only resizing,
  convergence, persistence, maximize labeling, and restore all passed live.
- `VAL-V030-GAMEPAD`: remains **Pending validation**, narrowed to trigger zoom
  feel. Dropdown standdown, character-sheet traversal/scrolling, and menu repeat
  cadence passed live.
- `B6-MRD`: `dual_outline` is accepted as the default visual, with one follow-up:
  retain the threat presentation while Action Menu and Map Menu are open.

The hash and startup-stamp boxes were not checked, and the requested screenshots
were not returned. The logs do identify the v0.3.2 build and provide sufficient
display traces for the tested behavior; this is an evidence-packaging gap, not a
reported runtime defect.

## V032-GP-01 - asymmetric trigger zoom feel

**Report.** Left-trigger repeat is slightly fast; right-trigger repeat feels very
fast. Shallow and full pulls did not receive passing checks.

**Root cause.** `MapCursor._poll_held_zoom()` applies the same threshold, initial
delay, and 0.45-second repeat rate to both actions. The input map also gives LT and
RT symmetric positive-axis bindings. The asymmetry is therefore not a second
timer bug. `CameraController.ZOOM_LEVELS` is
`[0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0]`: zoom-in steps above 1x change the
image by 50%, 33%, 50%, and 33%, while several zoom-out steps are perceptually
smaller. Equal temporal cadence produces unequal visual velocity.

**Resolved solution (V032-D1, 2026-07-13).** Keep the existing discrete zoom
levels. Require a full trigger pull before the first zoom step and slow the shared
repeat cadence; do not introduce separate LT/RT rates. For the first implementation
pass, use a near-full `0.85` press threshold and increase both the initial delay and
repeat rate from `0.45s` to `0.65s`, then validate feel on the same controller.
Treat those numbers as the bounded implementation starting point, not a new user
setting. Tests must cover below-threshold rejection, immediate first step only at
or above the new threshold, identical shallow/full behavior above threshold, and
the slower repeat timing in both directions.

## V032-GP-02 - requested focus-cursor clearance

**Report.** The tester requested at least three times more visual padding around
the focus cursor in the same note as map zoom and context-menu anchoring.

**Clarification and root cause.** The request means menu-selection focus padding,
not the map cursor or camera edge buffer. Settings and Unit Details now scroll the
focused control into view, but their lookahead is intentionally small (roughly
1.5 rows in Settings). At large Menu Scale values, fewer rows fit in the viewport,
so that fixed margin shows too little of the direction the player is moving.

**Resolved solution (V032-D2, 2026-07-13).** Keep the map-camera buffer unchanged.
During the next UI implementation session, increase the scroll focus lookahead for
Settings and Unit Details so substantially more of the upcoming menu is visible,
with a target of roughly three visible row heights where the viewport permits it.
Clamp the margin when the viewport is too small rather than forcing overflow or a
horizontal scrollbar. Put the shared calculation beside the selector/scroll helper
instead of maintaining screen-specific pixel constants, and test 0.5x, 1x, and 2x
Menu Scale near both ends of each list.

## V032-MRD-01 - threat display disappears under menus

**Report.** `dual_outline` is accepted, but its highlight/fill disappears while
Action Menu or Map Menu is open; the perimeter can remain visible in at least one
of those transitions. The tester wants the threat display retained.

**Root cause.** Both menu flows call `MapCursor.lock()`. `lock()` always calls
`_clear_overlay_paint()`, which clears the shared GridManager overlay layers,
watch markers, and path arrows. Action Menu also enters `UNIT_MOVED` through a
selection flow that intentionally replaces the threat fill with composed movement
overlays. The threat state (`_danger_mode` and `_watch_set`) is retained; only the
paint is removed. This broad cleanup policy predates the composed MRD layers.

**Recommended solution.** Split input locking from overlay cleanup. Add a lock
policy such as `lock(clear_transient_overlays := true)` or dedicated
`lock_for_menu()`; for Map Menu repaint the base threat specs while clearing only
peek/path/selection transients. For Action Menu keep using
`_repaint_composed_overlays(_selection.overlay_specs())` so movement and retained
threat layers coexist. Never retain overlays across enemy movement, suspend/load,
or phase changes, where recomputation is required. Add regression coverage for
both menus and for enemy-phase cleanup.

**Resolved solution (V032-D3, 2026-07-13).** Retain base threat plus watched
markers in both menus, retain the selected unit's movement range only in Action
Menu, and clear path arrows/hover peek in both. Map Menu does not retain movement
overlays; its current free/empty-tile entry contract remains unchanged. Implement
this policy next session with the phase-change and suspend/load cleanup guards
described above.

## Implementation order

1. Implement the `0.85` full-pull threshold and `0.65s` shared repeat cadence,
   retaining the existing zoom levels.
2. Implement shared, scale-aware menu focus lookahead targeting roughly three
   visible rows where space permits.
3. Implement the resolved V032-MRD-01 menu-overlay policy.
4. Run focused automated coverage, then cut one narrow live rerun for trigger
   feel, high-scale menu lookahead, and overlay retention. Remove the
   temporary F8 mode selector after `dual_outline` becomes the fixed default.
