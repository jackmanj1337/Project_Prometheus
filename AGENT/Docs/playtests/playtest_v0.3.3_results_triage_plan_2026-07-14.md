Status: Planned - triaged; one owner decision before implementation
Last verified: 2026-07-14

# v0.3.3 Playtest Results and Root-Cause Triage

## Evidence and outcome

The returned checklist is preserved as
[`playtest_checklist_v0.3.3_returned_2026-07-14.md`](playtest_checklist_v0.3.3_returned_2026-07-14.md).
The three original-resolution screenshots are preserved in
`AGENT/Docs/archive/evidence/`:

- `v033_action_menu_text_overflow_2x_2026-07-13.png`
- `v033_settings_focus_lookahead_2x_2026-07-13.png`
- `v033_unit_details_focus_lookahead_2x_2026-07-13.png`

No `godot.log`, controller model, Windows version, build hash confirmation, or
dedicated threat-under-menu screenshots were returned. The checklist and images
still establish four actionable findings:

| Issue | Severity | Tracker | Triage result |
|---|---|---|---|
| `V033-GP-01` trigger threshold/double step | Medium | `VAL-V030-GAMEPAD` | Failed; gate stays Pending validation |
| `V033-UI-01` 2x focus lookahead around slider rows | Low | `UI-INSPECTION` | Partial pass; bounded correction |
| `V033-MRD-01` watch state leaks between faction turns | Medium | `B6-MRD` | New defect; owner decision required |
| `V033-UI-02` Action Menu text exceeds button art | Medium | `UI-INSPECTION` | New live UI regression |

The menu threat-composition behavior itself passed: Action Menu and Map Menu
retain the intended layers, clear their transient layers, and restore cleanly.
`dual_outline` is accepted as the fixed default.

## V033-GP-01 - trigger threshold and double step

**Report.** A gentle pull still produces a quick zoom, and one full pull can
produce two steps. A full pull has the intended slower distinct cadence after an
initial rush.

**Root cause.** The same trigger is consumed by two paths in `MapCursor.gd`.
`_unhandled_input()` calls `_is_fresh_action_press(event, "zoom_in/out")` and
immediately applies a step for the raw `InputEventJoypadMotion`; this path does
not check `ZOOM_PRESS_THRESHOLD`. Later, `_process()` polls action strength.
When the strength first reaches `0.85`, `_poll_held_zoom()` sees a direction
different from `_zoom_held_direction`, arms repeat, and returns another immediate
step. A gradual pull can therefore step below threshold through the event path
and again at threshold through the polling path. Keyboard and mouse need the
event path, but analog triggers need one threshold-aware owner.

**Recommended solution.** Ignore joypad-motion zoom in `_unhandled_input()` and
let `_poll_held_zoom()` exclusively own trigger activation/repeat. Keep immediate
event handling for keys, mouse buttons, and discrete action events. Add tests
that ramp a trigger through below/at/above threshold and prove exactly zero/one/
one steps before the delay, plus release/repress and both-direction cases.

**Decision.** None. This fixes the implemented 0.85 contract without changing
zoom levels or feel constants.

## V033-UI-01 - 2x focus lookahead around slider rows

**Report.** Settings and Unit Details pass at 0.5x and 1x. At 2x, Settings feels
cramped near the top; the tester specifically suspected slider rows. The returned
Settings screenshot shows only a small amount of context above the first volume
row after returning toward the top. Unit Details is reachable and unclipped.

**Root cause.** `ModalScreen._apply_focus_lookahead()` defines three rows as
`focused_control.height * 3`. A Settings focusable may be the `HSlider`, whose
height is smaller than its containing `HBoxContainer` row and neighboring
OptionButton rows. The calculation therefore underestimates three visual rows.
The half-viewport cap is behaving as designed and is not the primary cause.

**Recommended solution.** Measure the focusable's owning direct list row (the
child below the scrolling VBox), not the leaf slider/button. Use that row height
for the focused extent and derive lookahead from the next three actual visible
sibling row heights when available; fall back to three owner-row heights. Preserve
the viewport cap. Add mixed-height slider/OptionButton fixtures at 2x and assert
the focused owner row plus the available next rows remain visible.

**Decision.** None. This makes the existing “three row heights” contract match
what the player sees.

## V033-MRD-01 - faction watchlist leakage

**Report.** During a red phase, red can watch a blue unit. On the next blue turn,
that blue unit remains visibly marked but blue cannot remove it. The tester asks
for separate watchlists and markers visible only to their owning faction.

**Root cause.** `MapCursor` owns one global `_watch_set` and one global
`_danger_mode`. `set_controlling_faction()` updates selection and targeting but
does not swap threat-view state. `_watched_units()` resolves ids without checking
hostility to the current controller, while `_is_watchable_enemy()` correctly
prevents the new controller from toggling a friendly unit. This creates the exact
visible-but-not-removable state. Suspend save also serializes one `watch_set`, so
changing runtime ownership alone would leave persistence ambiguous.

**Recommended solution.** Store a small faction-keyed view-state dictionary:
`faction_id -> {watch_set, danger_mode}`. On faction handoff, save the outgoing
state, load/default the incoming state, and repaint only when interactive. Prune
each set against living units and its owning faction's hostility relation. Render
markers only from the active faction's state. Extend suspend encoding to a
versioned `threat_views_by_faction` field, while accepting the old single-set
shape as the controlling faction's state for backward compatibility. Tests must
cover blue/red/green isolation, allied-faction hostility rules, death pruning,
phase repaint, and suspend round-trip.

**Owner decision (`V033-D1`).** Should watch state be per controlling faction
(recommended, matching the tester request and existing per-faction camera view)
or per local player/seat (better only if allied factions controlled by one player
should deliberately share watches)? The current runtime has faction identity but
no durable player-seat identity, so per-player ownership expands scope and save
schema beyond this defect.

## V033-UI-02 - Action Menu text exceeds button art

**Report.** At 2x Menu Scale, Action Menu labels extend outside the ornate button
frames. The screenshot clearly shows `Pair Up` crossing both inner borders; the
other visible labels have very little safe inset.

**Root cause.** `ActionMenu.tscn` has a fixed 128 px minimum width. Menu scaling
increases the 16 px theme font and style margins but does not increase this width
budget. The pixel font also has wider glyph metrics than the previous default.
The theme's button content margins consume 24 px before scaling, leaving too
little text width at 2x. This is a layout constraint mismatch, not an anchoring or
overlay-composition fault.

**Recommended solution.** Make the Action Menu width content-driven at each Menu
Scale: compute the maximum visible label minimum width plus the effective left/
right button content margins and set the panel minimum width before placement.
Keep 128 px as the 1x floor; do not shrink the global font or clip labels. Re-run
placement after the size change so edge flipping uses the final width. Extend the
UI inspection harness across all seven scale factors and all labels, especially
`Separate` and `Pair Up`, asserting each button's content rect contains its text.

**Decision.** None unless the desired visual is a fixed-width menu; content-driven
width is the accessibility-safe default and preserves the selected font.

## Proposed implementation order

1. Fix `V033-GP-01`; it is a contained input correctness bug and keeps the
   gamepad validation gate open.
2. Resolve `V033-D1`, then implement faction-scoped watch state and its suspend
   migration together.
3. Fix Action Menu content sizing before the next UI-themed build.
4. Correct focus lookahead row measurement and add mixed-height 2x coverage.
5. Run automated coverage, then cut one focused Windows/controller rerun. Require
   the build hash, controller/Windows fields, log, trigger ramp checks, two-faction
   watch isolation, and 2x screenshots in the return package.
