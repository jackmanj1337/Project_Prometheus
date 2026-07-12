# v0.3.1 Playtest Triage - Code Review Plan - 2026-07-12

Status: DECIDED - root causes diagnosed from returned live evidence + source; owner decisions locked 2026-07-12 (see per-finding "Owner decision" lines); fix stream follows
Scope: returned `v0.3.1` checklist, the three v0.3.1 logs, both drag screenshots,
and the code paths behind each V031-* issue.
Companion: `AGENT/Docs/playtests/playtest_v0.3.1_results_triage_plan_2026-07-12.md`

## Verdict

The 2026-07-10 fix pass held where it was aimed: Settings repeat/scroll, keybind
capture containment, stick target cycling, and the maximize readout all passed
live. The remaining defects again cluster in two seams rather than in per-screen
bugs: **global input polling that ignores event capture** (R1, and the same
blindness class that R5/R6 tune around), and **display write-back that does
too much work per resize event and trusts signal delivery too far** (R2/R3).
Both seams have one-place fixes. MRD-7 needs a small new rendering surface, not
a rework.

What the return proves clean (no action): `resize_write_back_action()`'s
maximize/restore policy is correct on live hardware; the
`_modal_focus_repeat_enabled` capture gate fixed the keybind-scroll leak;
polled-stick targeting matches d-pad behavior.

## Findings

### R1 (HIGH) - `V031-GP-02`: modal focus polling is blind to popup capture

Evidence: `v031_new_game_submenu_selector_moving_2026-07-12.png` (Leveling
dropdown open, selector moving behind it) and the rapid
`OptLeveling <-> OptPairUp` `focus_entered` alternation in
`godot_log_v0.3.1_ngfocus_submenu_returned_2026-07-12.log`. Focus never
*escapes* the panel — containment holds — but it moves while a sub-menu should
own the input.

Root cause, source-confirmed: `ModalScreen._process()`
(`scripts/ui/ModalScreen.gd:123-131`) steps focus from
`_modal_repeat.poll(delta)`, and `MenuRepeatPolicy._direction_from_actions()`
(`scripts/shared/MenuRepeatPolicy.gd:91-106`) reads
`Input.get_action_strength()` — the **process-global** input singleton. When an
`OptionButton` popup opens, it is a separate (embedded) `Window` that captures
the *event* stream, so `ModalScreen._input` stops seeing events — but the
polled singleton still reports the held direction, so `_process` keeps
stepping the panel behind the popup. Every up/down tap inside the dropdown
also steps the panel. This is exactly the class of the fixed keybind-capture
bug: polling must stand down while any capture-mode UI is active.

Possible fix (one place, covers New Game *and* the Settings dropdowns): a
`_capture_ui_active()` check in `ModalScreen._process()` before polling —
true while the viewport has a visible embedded subwindow
(`get_viewport().get_embedded_subwindows()`); on the transition back to
false, call `_modal_repeat.clear()` so its wait-for-neutral latch swallows the
still-held direction. Gate `_enforce_focus_containment()` behind the same
check so containment never fights the popup, and skip the `_input`
`set_input_as_handled` consume too.

Tests: headless — instantiate `NewGameScreen`, `show_popup()` on an
`OptionButton`, hold `ui_down` via `Input.action_press`, run `_process`
frames, assert the panel focus owner does not change; assert one popup-close
frame with the direction still held produces no step (neutral latch).

### R2 (HIGH) - `V031-DSP-01`: resize write-back does per-event disk I/O and has no recovery when size events stop

Evidence: `godot_log_v0.3.1_menus_display_drag_returned_2026-07-12.log` ends
mid-drag — stepwise `write_back_apply` rows `1125x575 -> 581 -> 584 -> 613 ->
622 -> 633`, then **zero further size events of any kind** while the OS window
visibly kept growing to roughly `1125x975`
(`v031_one_axis_drag_stale_readout_2026-07-12.png`, taken ~3 minutes before
the log rotated at relaunch). The relaunch then restored the stale `1125x633`
(`v031_one_axis_drag_relaunch_custom_size_2026-07-12.png`) — the tester's
"black bars not preserved" note is this same stall downstream.

Source walk (`scripts/autoloads/SettingsManager.gd`): every
`size_changed` runs `_queue_resize_refresh` (`:483-498`) -> deferred
`_reapply_menu_scale_after_resize` (`:501-507`) -> full menu-scale group
re-apply + `_maybe_write_back_os_resize` -> `apply_resize_write_back`
(`:571-590`) which calls **`save()` — a synchronous ConfigFile disk write —
on every step of a live OS drag**, plus a `resolution_written_back` emit that
refreshes the Settings readout. That is a lot of main-thread work inside
Windows' modal resize loop on an Intel iGPU machine; whatever the final
trigger (the engine's drag pump starving, or the OS coalescing after slow
frames), the design offers **no reconciliation path once a signal is missed**
— the readout and the saved size simply stay wrong until the next event that
never comes.

Two-part fix direction (policy stays in testable pure functions):

1. **Settle-then-persist.** During a live resize, *record only* — update the
   in-memory observed size and readout, but move `save()` (and ideally the
   `resolution` assignment) behind a one-shot settle timer (~0.5-0.75s after
   the last size event). One disk write per drag instead of dozens, and no
   heavy work inside the modal loop.
2. **Poll reconciliation.** Because live evidence proves event delivery can
   stop entirely, add a low-frequency safety poll (a 0.25-0.5s `Timer`, active
   only while windowed + display supported): compare
   `DisplayServer.window_get_size()` against the last observed size and run
   the same settle path on mismatch. This converges the readout and the saved
   size even in a total event stall — it makes the one-axis gate closable
   without ever fully explaining the Windows-side stall.

Tests: headless pure-policy tests for the settle state machine (observe ->
settle -> persist-once; poll-detected mismatch feeds the same path). The stall
itself needs the live Windows rerun.

### R3 (MEDIUM) - `V031-DSP-01b`: write-back accepts any positive size

Evidence: the 2026-07-12 launch booted with `saved_resolution "491x1913"` —
plausibly a genuine left-edge width drag during testing, but now the
persistent windowed size. `apply_resize_write_back` (`:571-577`) rejects only
non-positive sizes; nothing stops a 491-px-wide (or 50-px-tall) window from
becoming the relaunch size.

Possible fix: clamp (not reject — the readout should still follow reality
mid-session) the *persisted* value to a sane minimum, e.g. no smaller than a
minimum playable client (960x540 or half the smallest preset;
`RESOLUTION_CHOICES` floor is `1280x720`, owner call). Pure-function
testable alongside R2's settle policy.

**Owner decision (2026-07-12): leave unclamped — no action.** A dragged size,
however extreme, is the user's choice and relaunch honors it. R2's
settle-then-persist still removes the *mid-drag transient* class of weird
persists on its own.

### R4 (MEDIUM) - `V031-GP-05`: View Support / View Lead unreachable; character sheet never scrolls with selection

Evidence: tester §1 note — both keyboard and pad skip the buttons; the sheet
does not scroll like Settings.

Root cause, source-confirmed (`scripts/ui/UnitDetailsScreen.gd`):

- `open()` appends only one control entry — `_append_control_entry("back",
  "Back")` (`:141` region); `_btn_pair` never enters `_entries`, and `_input`
  (`:628-652`) consumes all directional events precisely so GUI focus nav can
  never run — the code comment at `:631-635` documents that the button is
  unreachable and offers the `next_unit`/`prev_unit` jump as the only pad
  path. The tester does not know that; traversal must visit it.
- `MainScroll` has `follow_focus = true`, but the custom selector moves a
  RichTextLabel highlight, not GUI focus — so `follow_focus` fires only for
  Back/pair grabs and the sheet effectively never scrolls with selection.

Possible fix: (a) when `_btn_pair.visible`, append a `"pair"` control entry
(before "back", matching visual order); handle it in `_on_selector_changed`
(grab `_btn_pair` focus) and in the `_input` confirm branch
(`_current_entry_is_control("pair")` -> `_on_pair_button_pressed()`). (b) on
selector change, call `_main_scroll.ensure_control_visible()` on the section
label owning the selected entry (plus the R7 lookahead margin) so selection
drives scrolling.

Tests: extend `test_unit_details_screen.gd` — walk the full entry cycle with a
paired unit and assert both control entries are visited and confirm activates
them; assert `scroll_vertical` changes when selection moves to the last
section on an overflowing sheet.

### R5 (LOW) - `V031-GP-03`: menu repeat cadence is borrowed from the map cursor

`MenuRepeatPolicy` reuses `CURSOR_KEY_REPEAT_DELAY/RATE` = `0.25s/0.10s`
(`scripts/shared/GameConstants.gd:124-125`) — 10 steps/second was tuned for
map-cursor travel, and the tester has now twice called it fast in the Action
Menu / character sheet. Add dedicated `MENU_REPEAT_DELAY/RATE` constants
(suggest `0.30s/0.15s`) consumed by `MenuRepeatPolicy`, leaving the map cursor
untouched. Settings shares the policy: the tester did not flag Settings speed,
so one shared menu cadence is fine — flag in the rerun handbook that Settings
will step slightly slower.

### R6 (LOW) - `V031-GP-04`: LT/RT zoom — third feel complaint; stop tuning blind

`_poll_held_zoom` (`scripts/core/MapCursor.gd:1978-1999`): threshold `0.35`,
repeat lerps `0.45s -> 0.18s` with pull strength. A full pull still steps
~5.5x/second across a short zoom range. Two-step recommendation: (1) remove
the strength-scaled lerp (constant `0.45s` repeat — the analog lerp is
precisely what "too sensitive" keeps pointing at) and raise the threshold to
`0.5`; (2) if the next return still complains, stop tuning constants and
promote the `B6-INPUT` sensitivity sliders — three strikes is the signal that
feel is per-player, not per-constant.

**Owner decision (2026-07-12): drop strength scaling entirely.** Any pull past
the activation threshold steps once, then repeats at the constant slow cadence
(`0.45s`); pull depth changes nothing. Sensitivity sliders stay `B6-INPUT`
backlog to revisit later.

### R7 (LOW) - `V031-GP-01`: no focus lookahead in scrolling lists

`ScrollContainer.follow_focus` scrolls the focused control just barely into
view — no margin knob exists. Add a small shared helper (SettingsScreen +
UnitDetailsScreen after R4): on focus/selection change, nudge
`scroll_vertical` so at least ~1 row-height of context stays visible past the
focused row in the movement direction. Headless-assertable on scroll offsets.

### R8 (MEDIUM) - `V031-MRD-01`: requested dual outline cannot be expressed by the current perimeter tiles

The tester's spec (color assignment corrected by the owner 2026-07-12):
**dark-red** strong outline around the **watched** threat area, **bright-red**
around the **entire** danger area, both rendered **above units**, with the
dark watch outline drawn **over** the bright general-danger outline.

Current machinery (`scripts/core/GridManager.gd:683-732`):
`_paint_stacked_perimeter` bakes perimeter edges as tile *alternates* into the
`_overlay` TileMapLayer — which (a) renders **below** unit sprites, (b) knows
only one union (`_threat_union` merges watch + faction threat), and (c) one
color/width per threat source. Extending the tile-alternate route means ~15
new art variants per color and still can't get above units without a third
z-lifted TileMapLayer.

Possible fix — a dedicated draw surface instead of more tile art: a
`ThreatPerimeterOverlay` `Node2D` with `z_index` above the unit layer whose
`_draw()` renders edge polylines. Feed it **two** tile unions (watch-only, and
watch+faction) computed from the existing tested
`threat_perimeter_mask()` helper; draw bright (general danger union) first,
dark (watch union) second so the dark watch outline wins overlaps; line
width/colors as exported constants for the next F8 comparison. Stacked fill
stays on the existing layers underneath, and the F8 cycle gains this as the
fifth mode (`dual_outline`) rather than replacing `stacked_perimeter` until
the owner accepts it live.

Tests: pure edge-mask tests for the two-union split (watched subset vs full
union, shared edges, concave shapes); keep `test_mrd_scene.gd` nonblank
screenshot coverage for the new mode.

## Fix Order

1. **R1** popup standdown in `ModalScreen` (functional, one seam, headless-provable).
2. **R4** character-sheet pair entry + selection scrolling (functional reach bug).
3. **R2** display settle-then-persist + poll reconciliation (gate closer;
   policy tests headless, stall verification live). R3 clamp declined — skip.
4. **R5 + R7** cadence constants + scroll lookahead (small, same screens as R4).
5. **R6** zoom: constant slow repeat, no strength scaling (owner-decided);
   sliders stay backlog.
6. **R8** MRD-7 `dual_outline` draw surface, new F8 mode (dark watch outline
   over bright general-danger outline, above units).
7. Diagnostics (`V030-NG-FOCUS`, `V030-DSP-TRACE`) and F8 stay until their
   gates close; remove in one release-cleanup commit.

Then cut `v0.3.2` as the focused rerun for: dropdown sub-menu focus, character
sheet navigation/scroll, one-axis drag + relaunch, zoom feel, and the MRD-7
pick.
