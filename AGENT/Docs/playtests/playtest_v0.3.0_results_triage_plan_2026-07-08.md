---
Type: playtest
Status: Returned results - diagnosed 2026-07-08; owner walkthrough Q1-Q5 DECIDED and root causes source-confirmed the same day (suspend a-d, Settings follow_focus, menu stick cadence, trigger threshold, pad brand); two holdouts need live repro (New Game focus gap, one-axis drag readout); V030-SUS-01 (all four sub-defects) FIXED 2026-07-09 (Pending validation, awaiting live rerun); remaining fix passes (GP/DSP) build next
Last verified: 2026-07-09
---

# v0.3.0 Playtest Results Triage And Fix Plan - 2026-07-08

## Scope

Triage for the returned v0.3.0 feature-build playtest (handbook Parts I-VIII).
This was the first live pass over controller support, input mode/prompts, key
rebinding, Suspend & Continue, map readability, true-hit feel, and the remaining
`VAL-V023-DISPLAY` section 1.6 close-out.

Evidence:

- Returned checklist: `playtest_checklist_v0.3.0_returned_2026-07-08.md`
- Build manifest: `playtest_build_v0.3.0.md` (source commit `7b23412`, SHA-256
  `d003060b...`). Every BUILD STAMP in the returned logs reads
  `version=0.3.0 commit=7b23412 built_at=2026-07-08T07:02:14Z` — the tester ran
  the shipped artifact.
- Logs in `AGENT/Docs/archive/evidence/`:
  - `godot_log_v0.3.0_returned_2026-07-08.log` (final session)
  - `godot_v0.3.0_session_2026-07-08T13.59.17.log`, `...T14.01.09.log`,
    `...T14.04.10.log`, `...T14.21.32.log`
- Screenshots in `AGENT/Docs/archive/evidence/`:
  - `v030_resize_windowed_preset_1920x1080_2x_2026-07-08.png` (preset baseline)
  - `v030_resize_custom_2368x1903_client_readout_2026-07-08.png` (+ `_b` variant)
  - `v030_resize_custom_2368x1310_client_readout_2026-07-08.png`
  - `v030_resize_custom_2368x1310_letterbox_2026-07-08.png`
  - `v030_resize_maximized_stale_client_readout_2026-07-08.png`
  - `v030_main_menu_2x_overlap_2026-07-08.png`
  - `v030_suspend_resume_support_offmap_2026-07-08.png`
- Tester environment: Windows desktop, NVIDIA RTX 5070 Ti, OpenGL Compatibility
  renderer, exe run from `E:/Utilities/ObsidianPortable/`. Controllers: an
  Xbox-layout pad plus a PlayStation pad (section 7 notes). Touch hardware not
  available this pass (`NOT RUN`, planned on a touchscreen Windows machine).

## Findings First

1. **`VAL-V030-GAMEPAD` FAILS.** Section 5 (mixed input) passed, but sections
   1-4 are unchecked with real failures: controller focus cannot reach
   off-screen Settings rows and the list does not scroll (a controller-only
   focus trap), menus have no directional repeat, the New Game screen focus
   highlight vanishes between specific rows, stick cadence in menus is too
   fast and stops oddly, and LT/RT zoom is so sensitive the tester rebound
   zoom to the d-pad to finish the pass. The gate stays open.
2. **`VAL-V023-DISPLAY` stays open but narrowed again.** The v0.2.8 fix core
   held live: a two-axis edge drag writes `Custom (2368x1903)` +
   `client 2368x1903` with no bogus second applied size (screenshots), the
   Settings panel stayed centered through maximize/un-maximize at 2.0x Menu
   Scale ("did stay centered the entire time"), and maximize is not persisted
   as a saved resolution. What remains: the readout does not update on a
   one-axis drag that only grows the black bars, the maximized window still
   shows the stale pre-maximize `client WxH` label
   (`v030_resize_maximized_stale_client_readout_2026-07-08.png`), and
   quit/relaunch size persistence was not explicitly confirmed.
3. **Suspend & Continue regressed hardest (`V030-SUS-01`).** After Continue:
   units render refreshed but cannot move; paired support units are drawn at
   the off-map `(-1,-1)` placeholder
   (`v030_suspend_resume_support_offmap_2026-07-08.png`); a suspend/resume
   while debug-controlling the red team leaves the cursor unmovable and menus
   unopenable; and the turn counter reads wrong until a full round passes.
   This is a shipped-feature failure and the top fix priority.
4. **Multi-pad prompt branding is wrong by construction.** Prompts swap live
   between keyboard and pad, but with two pads connected the brand follows the
   FIRST-connected pad, not the pad in use —
   `InputDisplay.active_pad_brand()` reads `Input.get_connected_joypads()[0]`
   (`scripts/shared/InputDisplay.gd:99-103`). PlayStation prompts also print
   the word "Square" instead of a symbol, and the rebind rows do not brand
   their pad labels at all.
5. **Input Mode selection changes prompts but does not constrain devices.**
   The tester expected an explicit mode to block other input. Current design
   (input-mode resolver) only drives prompts/focus. This is a spec ambiguity
   to settle, not an obvious defect.
6. **Threat-overlay layering is the main readability note.** Watch-set "D"
   markers vanish whenever the overlay is hidden, and the overlay is cleared
   by selecting units or opening the pause menu; the movement selector cannot
   coexist with the threat overlay (range peek can). The tester asks for
   concurrent overlays with distinct textures or a strong border. This is
   `B6-MRD` precedence-registry design work, not a gate blocker.
7. **True hit landed as intended.** Part VI checked with no adverse comments.
8. **Main Menu overlaps at 2.0x Menu Scale.** `v030_main_menu_2x_overlap_2026-07-08.png`
   shows Continue overlapping the title — fresh evidence for the already-routed
   `V027-05a` MainMenu Menu-Scale exemption under `UI-INSPECTION`.
9. **Logs are clean for defects.** Only known M9 `SkillHandler` stub warnings
   (`armsthrift`, `dash`), one transient `HIDAPI device disconnected while
   opening` on gamepad index 5 (dual-pad session), and one `ObjectDB instances
   leaked at exit` warning in a real exported-game session — worth a
   low-priority cross-check against the `[ODB-1]` audit, which only proved the
   TEST-side leaks benign.

## Workstreams

### V030-GP-01 - Controller menu focus: no scroll-follow, no repeat, focus gaps

Tester (section 1): "in the settings menu the controller focus wouldn't go past
the visible screen and wouldn't scroll the menu either. The menu also doesn't
have any directional repeat". On the New Game screen the highlight disappears
for one press between permadeath→auto promote, auto promote→leveling,
leveling→pair up, and pair up→start (but not map→permadeath or start→back).

**Diagnosis (run 2026-07-08, second pass):**

- **Scroll half CONFIRMED:** the SettingsScreen `ScrollContainer`
  (`scenes/ui/SettingsScreen.tscn:35`) has no `follow_focus = true`. Only
  `PromotionScreen.tscn:66` and `ReclassScreen.tscn:66` carry it — the exact
  bug class fixed at V026-05b, recurring on Settings. Fix: set `follow_focus`
  on the Settings scroll frame (and audit the other scroll-frame modals).
- **Repeat half:** engine focus navigation moves exactly one step per press
  with no joypad echo, and no screen owns a repeat policy. Fix seam shared
  with V030-GP-02 below: one owned menu repeat/deadzone policy.
- **New Game focus gap DOWNGRADED — scene chain exonerated.** A headless
  probe (with SettingsManager keybinds applied) walked the chain with both
  keyboard `ui_down` and real `InputEventJoypadButton` d-pad presses:
  OptMap → OptPermadeath → OptAutoPromote → OptLeveling → OptPairUp →
  BtnStart → BtnBack, one row per press, and
  `find_valid_focus_neighbor(SIDE_BOTTOM)` resolves every hop. The live
  one-press gap is NOT the focus chain. Live-only suspects, in order:
  (i) `ModalScreen._focus_default()` firing on an `input_mode_changed` flip
  (mouse↔pad alternation steals one press to re-grab default focus);
  (ii) stick release overshoot past center emitting a transient `ui_up`;
  (iii) theme focus-style rendering on `OptionButton`. Needs a live repro
  with instrumentation before fixing.

**Routing:** gate blocker for `VAL-V030-GAMEPAD`; implementation under
`B6-INPUT` (focus seam already flagged as the open feature-branch option).

### V030-GP-02 - Left-stick cadence in menus too fast / odd stops

Tester (section 2): map cursor feel is good; the action menu, equip menu, and
character sheet feel "too fast and occasionally stops weirdly".

**Diagnosis CONFIRMED (2026-07-08):** two navigation systems fail differently.
The custom menus (`ActionMenu._input`, `scripts/ui/ActionMenu.gd:162-167`;
`UnitDetailsScreen._input`, `scripts/ui/UnitDetailsScreen.gd:621+`) move
selection via stateless per-event `event.is_action_pressed("cursor_*")`, and
`cursor_down` is bound to the left-stick axis — so while the stick is held,
every analog value fluctuation above the threshold delivers another motion
event that reports "pressed" and steps the menu again ("too fast"), and when
the value stabilizes no events arrive at all ("occasionally stops weirdly").
The map cursor is immune because `MapCursorInput` polls through its tuned
repeat timer. Settings (engine focus navigation) correctly steps once per
press but has no repeat. Fix: one owned menu repeat/deadzone policy (the
`SelectionCursor`/`ModalScreen` seam), replacing per-event action checks.

**Routing:** gate blocker for `VAL-V030-GAMEPAD`; `B6-INPUT`.

### V030-GP-03 - Held LT/RT zoom too sensitive

Tester (section 3): triggers work but are "too sensitive"; the tester rebound
zoom to d-pad up/down for the rest of the pass. L3 reset is good. Section 12.4
adds: "Consider adding sensitivity sliders to the triggers and joysticks".

**Diagnosis CONFIRMED (2026-07-08):** `MapCursor._poll_held_zoom`
(`scripts/core/MapCursor.gd:1909-1924`) has **no activation threshold** — the
only gate is `strength <= 0.0` (`:1913`), so the lightest trigger contact
fires an immediate zoom step (`:1919`) and arms the repeat, whose rate lerps
down to `ZOOM_REPEAT_RATE_FAST = 0.12s` at full pull (`:123`, `:1927-1929`).
Fix: add a press threshold (~0.25) before any step, keep the strength scaling
above it (and consider softening the fast rate); the sensitivity sliders stay
`B6-INPUT` backlog, not a rerun blocker.

**Routing:** gate blocker (feel item) for `VAL-V030-GAMEPAD`; `B6-INPUT`.

### V030-MRD-01 - Threat overlay / watch marker concurrency

Tester (section 4): R3 behaviors work, but watch "D" markers disappear with
the overlay; the overlay is dismissed by selecting units (spent or not) and by
opening the pause menu; the movement selector and threat overlay cannot show
at the same time (peek can). Request: concurrent overlays, distinguished by
texture or a strong border line.

**Routing:** `B6-MRD` design slice against the precedence-ordered overlay
registry (this is exactly the registry's job: make watch markers a standing
layer instead of a mode). Owner question Q3 in the companion review. Re-verify
section 4 in the gamepad rerun, but do not treat as a mapping failure.

### V030-INP-01 - Input Mode semantics + Touch NOT RUN

Tester (section 6): "input mode selector exists, but it does not seem to block
input but does change prompts." Touch will be tested later on a touchscreen
Windows machine. Auto/explicit persistence was not explicitly contradicted.

**Routing:** owner question Q1 (should an explicit mode gate device events, or
only prompts/focus?). If prompts/focus-only is confirmed, fix the HANDBOOK
expectation text rather than the code, and re-verify persistence in the rerun.
`B6-INPUT`.

### V030-INP-02 - Pad-to-pad prompt brand, PS symbols, rebind-row labels

Tester (section 7): keyboard↔pad prompt swaps are live, but "when playstation
controller is connected first, swaping to xbox mid map does not update prompts
and vice versa"; PS prompts print "Square" as a word; the rebind menu shows no
brand-specific labels.

**Diagnosis:** `InputDisplay.active_pad_brand()` brands from
`Input.get_connected_joypads()[0]` — first-connected wins regardless of which
pad emitted the events (`scripts/shared/InputDisplay.gd:99-103`).

**Fix direction:**

- Track the device id of the last joypad event (the input-mode resolver
  already classifies every event; carry `event.device` through
  `InputModeManager`) and brand prompts from that pad.
- Owner question Q2 on PS glyphs: printing real ✕○□△ needs font glyph
  coverage; words are the cheap fallback. Decide before polishing.
- Extend the Settings rebind rows through the same brand-aware label helper
  used by prompts (`InputDisplay.joypad_button_label`).

**Routing:** cosmetic-to-functional mix; the wrong-brand PROMPT with correct
physical behavior is cosmetic per the gate rules, so this does not by itself
hold `VAL-V030-GAMEPAD`, but the first-connected bug is cheap and should ride
the same fix pass. `B6-INPUT`.

### V030-SUS-01 - Suspend/Continue restore defects (top defect)

Tester (section 9): after Continue, units are "visually refreshed but unable
to move"; paired support units render at the `(-1,-1)` placeholder; suspend +
resume while debug-controlling the red team leaves cursor/menus dead; the turn
counter is wrong until a full round completes.

**STATUS: all four FIXED 2026-07-09** (Pending validation — awaiting the live
section-9 rerun). Failing-first headless repros landed in
`test_suspend_map_runtime.gd` (8 checks, full suite green). Fixes below.

**Sub-defects — all four root causes CONFIRMED by source trace (2026-07-08).
Fix + failing-first headless repro test each:**

- **(a) "Visually refreshed but unable to move" — the VISUAL is the bug.**
  `TurnManager._restore_unit_states` (`scripts/core/TurnManager.gd:184-194`)
  writes `_unit_states[unit] = int(...)` directly, bypassing
  `set_unit_state` (`:582-593`) whose DONE branch applies
  `unit.set_done_appearance()`. Restored DONE units keep the fresh-spawn
  sprite tint, so they LOOK ready while `can_unit_act` correctly refuses
  them. Fix: apply the appearance side effect during restore (route through
  `set_unit_state` or re-apply appearance after the state fill).
  **FIXED 2026-07-09:** `_restore_unit_states` (`TurnManager.gd`) now calls
  `set_done_appearance()` for any restored DONE unit.
- **(b) Pair-up supports rendered at `(-1,-1)`.** Pairing hides the support
  at the sentinel (`MapCursor.gd:1203-1204`: `tile_position = OFF_MAP_TILE;
  visible = false`), and that sentinel is what the payload serializes. On
  resume `GameMap._spawn_units_from_suspend` (`GameMap.gd:240-258`) spawns
  EVERY payload unit through the normal visible `_spawn_unit` path, and
  `PairUpRegistry.restore` (`PairUpRegistry.gd:193-195`) restores only the id
  dictionary — nothing re-hides the support node. Fix: after registry
  restore, re-apply node state for support-role units (hide + keep sentinel),
  or skip spawning units whose tile is the sentinel and re-attach them.
  **FIXED 2026-07-09:** `_spawn_units_from_suspend` (`GameMap.gd`) re-hides any
  unit whose serialized tile is `OFF_MAP_TILE` right after spawning it.
- **(c) Debug red-team suspend resumes into a driverless phase.**
  `start_map_from_suspend` (`TurnManager.gd:112-135`) restores
  `_active_faction_idx` and calls `gs.set_phase(ENEMY, ...)` for a non-blue
  capture — which locks the cursor (`MapCursor.gd:214-217`) — but NOTHING
  re-enters the awaited faction-scheduler loop (`TurnManager.gd:~430-486`)
  that drives non-blue phases, so no controller ever acts and no unlock ever
  comes: cursor frozen, menus unopenable. The debug-hotseat latch is also
  re-derived from the CURRENT flags at restore (`:135`), which are off after
  a relaunch. Fix decision needed: gate Suspend & Quit to the blue phase
  (cheap v1 answer) OR make restore re-enter the scheduler loop for a
  non-blue active faction.
  **FIXED 2026-07-09 — DECISION: gate to the blue player phase (cheap v1).**
  `MapCursor.can_capture_suspend` now returns true only when
  `GameState.is_player_turn()` (was `_turn.is_locally_controlled_faction(...)`,
  which allowed a debug-hotseat red capture). With the gate, restore never
  loads a non-blue phase, so the debug-hotseat latch re-derivation at
  `TurnManager.gd:135` is moot (documented in-code). Scheduler re-entry on a
  non-blue restore remains the deferred alternative.
- **(d) Turn counter stale until the next full round.** Restore assigns
  `gs.turn_number` directly (`TurnManager.gd:131`) and never emits;
  `turn_changed` is only emitted by `_complete_round`, and the HUD label
  updates only via `_on_turn_changed` (`scripts/ui/HUD.gd:374`, `:663`). Fix:
  emit `turn_changed` (or refresh the HUD from `gs.turn_number`) at the end
  of the restore.
  **FIXED 2026-07-09:** `start_map_from_suspend` (`TurnManager.gd`) emits
  `turn_changed(gs.turn_number)` at the end of restore.

**Routing:** `B1-SUSPEND` (+ `B1-CST` for payload contract). Extend
`test_suspend_map_runtime.gd` with post-resume actability, support-unit
attachment, and turn-counter assertions that fail on today's behavior first.
Not a named validation gate, but a release-quality blocker for the v0.3.x
line — schedule it in the same rerun build as the gamepad fixes.

### V030-DSP-01 - Section 1.6 residue: one-axis drag readout, maximized readout

Tester (section 11): "The listed resolution does only seems to update when the
actual picture changes size through manual edge dragging, it does not change
when using the windows fullscreen button or when draggin on one axis where you
just enlarge the black bars. The settings menu did stay centered the entire
time though."

**What held (do not re-fix):** two-axis drag write-back and `client WxH`
readout, no re-clamp of custom sizes, reactive re-centering through
maximize/un-maximize, maximize never persisted (`resize_write_back_action`,
`scripts/autoloads/SettingsManager.gd:522-533`).

**What to diagnose (updated after the 2026-07-08 diagnosis run):**

- One-axis drag: **the code path reads correct end-to-end** — the readout is
  signal-driven (`SettingsScreen.gd:217-218` subscribes
  `resolution_written_back`; `:434-440` refreshes), and
  `_maybe_write_back_os_resize` → `apply_resize_write_back`
  (`SettingsManager.gd:495-543`) has no branch that would skip a one-axis
  drag (the only guards are non-windowed/maximized modes and
  `actual == _requested_window_size`). The failure could NOT be reproduced
  headless (no real OS window events). Do NOT guess a fix: either reproduce
  live on Windows, or ship the rerun with temporary instrumentation (a log
  line in `_on_viewport_size_changed` and `apply_resize_write_back`) so the
  returned log pins whether `size_changed` fires at all on bar-growing drags
  under `stretch/aspect=keep`.
- Maximized readout: DECIDED (owner Q4) — show live `Maximized (WxH)` from
  the actual client size while maximized, mirroring `native WxH`; on
  un-maximize return to the saved windowed readout; persistence unchanged.
  Implementation sites confirmed: `SettingsManager.windowed_size_status()` +
  `SettingsScreen._refresh_applied_size`.
- Add explicit quit/relaunch persistence of a dragged size to the rerun
  handbook — the tester did not confirm it this pass.

**Routing:** `VAL-V023-DISPLAY` stays Pending validation; section-1.6-only
fix + focused rerun coverage.

### V030-REG-01 - Main Menu overlap at 2.0x Menu Scale

`v030_main_menu_2x_overlap_2026-07-08.png`: Continue overlaps the title at
2.0x. Already routed as `V027-05a` (MainMenu Menu-Scale exemption / pinned
home screen) under `UI-INSPECTION`; attach this screenshot as live evidence.
No new workstream.

### V030-FRQ-01 - Feature requests (not defects)

- **Faction-aware unit cycling** (section 7): LB/RB next/prev should cycle
  the faction under the cursor, defaulting to the player's. Route to
  `B6-INPUT` backlog / input register.
- **Cursor-traced manual pathing** (section 10): prefer the path the player
  traces with the cursor (fog/trap avoidance) over the auto-shortest path, up
  to movement limits. Real design work touching path planning and future
  perception/fog (`[PER]`); route to the map-readability/movement register,
  owner question Q5 for v1 scope.
- **Trigger/stick sensitivity sliders** (section 12.4): `B6-INPUT` backlog
  behind the V030-GP-03 default retune.

### V030-LOG-01 - Log intake

Build stamps match `playtest_build_v0.3.0.md` in every session log; the log
path/BUILD STAMP flow worked. Non-defect notes: known M9 stub warnings
(`armsthrift`, `dash`); one transient `HIDAPI device disconnected while
opening` for gamepad index 5 during the dual-pad session (watch for recurrence,
no action); one `ObjectDB instances leaked at exit` in a real game session —
cross-check against the `[ODB-1]` audit, which covered test-harness leaks only.

## Gate Routing

### `VAL-V030-GAMEPAD` — stays `Pending validation`

Part I sections 1-4 did not pass on real hardware (focus trap, no menu
repeat, menu stick cadence, trigger sensitivity). Per the triage kit rules the
row stays open. Control-plane next action: fix `V030-GP-01/02/03` (+ the
V030-INP-02 brand fix riding along) under `B6-INPUT`, land automated coverage
where headless-safe, then cut a focused controller rerun. Section 4's overlay
notes route to `B6-MRD` and do not block the gate by themselves.

### `VAL-V023-DISPLAY` — stays `Pending validation`, narrowed to V030-DSP-01

Section 11 is unchecked, but the returned evidence live-validates the v0.2.8
fix core (custom client readout, no re-clamp, reactive centering, no maximize
persistence). Remaining: one-axis drag readout, maximized-readout label, and
relaunch persistence confirmation. Fix under `V030-DSP-01`, then a
section-1.6-only rerun; flip the row only on that live pass, then proceed
`REL-V023-MERGE` / `B6-WEB-DEBUG`.

### Non-gate routing

| Finding | Home |
|---|---|
| Suspend/Continue defects (`V030-SUS-01`) | `B1-SUSPEND` / `B1-CST` |
| Overlay concurrency (`V030-MRD-01`) | `B6-MRD` |
| Input Mode semantics, prompt brand, rebind labels, cycling, sliders | `B6-INPUT` |
| Main Menu 2.0x overlap (`V030-REG-01` = `V027-05a`) | `UI-INSPECTION` |
| Cursor-traced pathing request | map readability/movement register (Q5) |
| Exit ObjectDB leak note | `[ODB-1]` follow-up, low priority |

## Sequencing

1. Owner walkthrough Q1-Q5 DECIDED 2026-07-08 (see the Walkthrough Decisions
   section of `AGENT/Code Reviews/playtest_v0.3.0_triage_review_2026-07-08.md`):
   Q1 = relabel the Settings row **Input Mode → Input Prompts**, behavior
   unchanged (devices never blocked; internal keys untouched); Q2 = brand-correct
   WORDS now + brand the rebind rows, real glyphs ride `UI-INSPECTION`; Q3 =
   registry-compose plumbing unconditional, then prototype BOTH shared-cell
   treatments (border-through vs second-layer stacking) behind a toggle and
   compare via headless screenshots then the live rerun ([MRD-7]); Q4 = show
   `Maximized (WxH)` live while maximized, persistence unchanged; Q5 =
   cursor-traced pathing backlogged with [PER] as [MRD-8], with a "recorded
   requests" note in every future handbook.
2. `V030-SUS-01` fix pass with failing-first headless repro tests
   (`test_suspend_map_runtime.gd` extensions) — top defect.
3. `V030-GP-01/02/03` fix pass (focus scroll-follow + one menu repeat policy +
   trigger retune) plus the `V030-INP-02` last-device brand fix; headless
   coverage where provable.
4. `V030-DSP-01` repro + fix (one-axis write-back/readout, maximized label).
5. Update the affected GDD sections + control-plane rows with each
   behavior-changing fix (DoD#1), then cut ONE focused rerun build covering
   controller Parts I-II, suspend section 9, and section 1.6, with an explicit
   relaunch-persistence step, the [MRD-7] shared-cell comparison toggle, and a
   "recorded requests" note ([MRD-8] cursor-traced pathing).
6. Flip `VAL-V030-GAMEPAD` / `VAL-V023-DISPLAY` only on that live pass, then
   `REL-V023-MERGE` / `B6-WEB-DEBUG` per the kit.
