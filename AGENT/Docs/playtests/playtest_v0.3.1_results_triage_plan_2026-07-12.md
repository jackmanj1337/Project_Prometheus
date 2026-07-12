---
Type: playtest
Status: Returned results - triaged 2026-07-12; suspend + maximize + stick targeting hold; VAL-V030-GAMEPAD and VAL-V023-DISPLAY stay open; MRD-7 routes to a dual-outline candidate
Last verified: 2026-07-12
---

# v0.3.1 Playtest Results Triage Plan - 2026-07-12

## Scope And Evidence

Triage for the returned `v0.3.1` focused rerun (fix-confirmation pass for the
v0.3.0.d gamepad/display holdouts plus the MRD-7 presentation pick).

- Returned checklist:
  [`playtest_checklist_v0.3.1_returned_2026-07-12.md`](playtest_checklist_v0.3.1_returned_2026-07-12.md)
- Build manifest: [`playtest_build_v0.3.1.md`](playtest_build_v0.3.1.md)
  (source `c7ce311`, SHA-256 `ac4b079a...205332`)
- Logs in `AGENT/Docs/archive/evidence/` (all three v0.3.1 BUILD STAMPs verify
  `version=0.3.1 commit=c7ce311`):
  - `godot_log_v0.3.1_menus_display_drag_returned_2026-07-12.log` — 2026-07-10
    19:22Z launch (Intel iGPU machine): sections 1, 2, and the section 4 drag
    session. Ends mid-drag at the `1125x633` write-back.
  - `godot_log_v0.3.1_relaunch_mrd_returned_2026-07-12.log` — 2026-07-10
    19:55Z relaunch (same machine): relaunch persistence + MRD-7 F8 cycles.
  - `godot_log_v0.3.1_ngfocus_submenu_returned_2026-07-12.log` — 2026-07-12
    19:01Z launch (NVIDIA/4K machine): New Game sub-menu selector session.
    Startup shows `saved_resolution 491x1913` (see `V031-DSP-01b`).
  - `godot_log_v0.3.0.d_stray_returned_2026-07-12.log` — stray **v0.3.0.d**
    log (`e19ac9b`), kept for provenance only (`V031-LOG-01`).
- Screenshots in `AGENT/Docs/archive/evidence/`:
  - `v031_new_game_submenu_selector_moving_2026-07-12.png`
  - `v031_one_axis_drag_stale_readout_2026-07-12.png`
  - `v031_one_axis_drag_relaunch_custom_size_2026-07-12.png`
- Tester: Jacob Jackman, Windows 11, two machines (Intel iGPU laptop 2026-07-10,
  NVIDIA 4K desktop 2026-07-12). Controller model and Menu Scale not recorded
  on the form; §1-§3 were run with a real pad per the notes.

## Findings First

1. **`B1-SUSPEND` holds.** Section 6 checked, no regression noted. Row stays
   Implemented / live-validated. No action.
2. **`VAL-V030-GAMEPAD` improved but stays open.** Settings now scrolls with
   held-direction repeat, keybind capture no longer scrolls the list, and
   stick attack/Pair Up target cycling **passed** (section 3 checked). What
   remains: focus behind an open dropdown still moves while picking from the
   sub-menu (`V031-GP-02`), the character sheet does not scroll with focus and
   skips the View Support / View Lead buttons on both keyboard and pad
   (`V031-GP-05`), repeat cadence is still slightly fast in the character
   sheet and Action Menu (`V031-GP-03`), and LT/RT zoom is still too
   sensitive (`V031-GP-04`). Comfort request: more visible rows above/below
   the focused row while scrolling (`V031-GP-01`).
3. **`VAL-V023-DISPLAY` improved but stays open.** Maximize now reads
   `Maximized (WxH)` — the v0.3.0.d miss is fixed live. Relaunch returns to
   the last *saved* size. The one-axis drag holdout has a much sharper
   signature now (`V031-DSP-01`): the trace shows the bottom-edge drag being
   tracked and written back step by step (`1125x575 -> 581 -> 584 -> 613 ->
   622 -> 633`) and then **all window/viewport size events stop arriving
   mid-drag** while the OS window kept growing to roughly `1125x975`. The
   readout froze at `Custom (1125x633)`, and the relaunch restored that stale
   size — the tester's "does not preserve the black bars" note is this same
   defect downstream, not a separate one. Separately, the 2026-07-12 launch
   booted with `saved_resolution 491x1913`, proving live write-back can
   persist a degenerate size (`V031-DSP-01b`).
4. **MRD-7 has no shipped pick yet.** The tester did not accept any current
   mode as-is and instead specified a refined candidate (`V031-MRD-01`): a
   strong **dark-red + bright-red dual outline**, drawn around **both** the
   watched-threat area and the entire danger area, with both lines rendering
   **above units** and the dark line layered over the bright one.
5. **Recorded-request boundaries held.** Nothing was re-filed; the keybind-row
   focus order note routes to `UI-INSPECTION`, selector-look intuitiveness is
   a design note, and trigger sliders stay `B6-INPUT` backlog.

## Issue Workstreams

### V031-GP-01 — Focus scroll margin (comfort tune)

Settings scrolling works, but the focused row hugs the scroll edge so the
tester cannot see what is coming next. Request: visual padding above and below
the focus marker. Applies to every scrolling focus list (Settings, and the
character sheet once `V031-GP-05` lands). Headless repro credible (assert
scroll offset keeps N pixels of lookahead around the focused control).

### V031-GP-02 — Selector moves behind an open dropdown

With the New Game panel open and an `OptionButton` popup up (e.g. Leveling),
directional input still moves the focus selector in the panel behind the
popup. Focus containment inside the panel held (no `V030-NG-FOCUS` line ever
leaves New Game controls), but input is double-routed while a popup is
capturing. Evidence: `v031_new_game_submenu_selector_moving_2026-07-12.png`
plus the rapid `OptLeveling <-> OptPairUp` `focus_entered` alternation in the
ngfocus log. Same class as the fixed keybind-capture leak: repeat/focus
handling needs to stand down while *any* capture-mode UI (popup, capture
prompt) is active. Headless repro credible.

### V031-GP-03 — Repeat cadence still fast in character sheet / Action Menu

Repeat works everywhere now, but the tester finds the Unit Details and Action
Menu cadence "still a little fast" (second consecutive tune request). Tune the
modal repeat interval; consider unifying on the Settings cadence the tester
did not flag. Headless-assertable once constants move.

### V031-GP-04 — LT/RT zoom still too sensitive

Third consecutive feel complaint. The 0.35 threshold / 0.45s->0.18s repeat
tune was not enough. Either tune again more aggressively (higher threshold,
slower floor) or accept that a constant cannot satisfy feel and pull the
`B6-INPUT` sensitivity-slider backlog item forward.

### V031-GP-05 — Character sheet: no focus scrolling; View Support / View Lead skipped

Two defects on `UnitDetailsScreen`: (a) the list does not scroll to follow
focus the way Settings now does; (b) the View Support and View Lead buttons
are skipped by focus traversal on **both** keyboard and gamepad — so the
functionality is unreachable without a mouse. (b) is the most functional
defect in the gamepad return. Headless repro credible (walk focus chain,
assert both buttons are visited).

### V031-GP-06 — Keybind grid focus order (note only)

Keybind rows traverse left-right-then-down instead of straight down like the
stat rows. Tester explicitly deprioritized: "a note on the ui pass". Routed to
`UI-INSPECTION`; no v0.3.x action.

### V031-DSP-01 — One-axis drag: size events stall mid-drag

The detection fix works — until it doesn't. The trace proves per-step
write-back during a bottom-edge drag up to `1125x633`, then zero further
`viewport_size_changed` / `window_size_changed` / probe lines while the drag
continued to ~`1125x975` (screenshot shows the stale readout under the taller
window). Working hypothesis for review: the write-back path re-applies the
requested size (`write_back_apply` runs the same apply routine as a dropdown
pick) while the OS drag loop is live, and the programmatic
`window_set_size` during the drag breaks Godot's subsequent size-change
delivery. Fix direction: during a live resize, **record only** — never call
the window-mutating apply path; settle/persist once sizes stop changing.
Needs code diagnosis (see the code review doc) + live Windows re-verification;
the stall itself is likely not headlessly reproducible.

### V031-DSP-01b — Degenerate size persisted (`491x1913`)

The 2026-07-12 launch booted with `saved_resolution "491x1913"` — a 491-px
wide window was persisted by live write-back at some point. Add a sanity
clamp on write-back (minimum size, e.g. the smallest preset) so a mid-drag or
degenerate OS size can never become the relaunch size. Headless-testable.

### V031-DSP-02 — Maximize readout: PASSED

`Maximized (WxH)` confirmed live; un-maximize restores the windowed readout.
No action beyond removing diagnostics at release cleanup.

### V031-MRD-01 — Dual-outline candidate requested

No current F8 mode ships. Build the requested candidate on top of
`stacked_perimeter`'s edge-mask machinery: two perimeter outlines — bright red
around the union of the **watched** threat cells, dark red around the union of
the **entire** danger area — both drawn on a layer above unit sprites, dark
over bright where they overlap. Keep stacked fill underneath. Edge-mask
generation is already tested; the new work is the second mask source, the
z-order lift above units, and the two-tone line style. Headless edge-mask
tests credible; the look itself needs the next live pass.

### V031-LOG-01 — Stray v0.3.0.d log (informational)

One returned log is from the v0.3.0.d build (`e19ac9b`, launched 2026-07-10
00:58Z, before v0.3.1 was cut). No v0.3.1 conclusions were drawn from it; the
three logs used all carry correct stamps. No action.

## Gate Routing

| Gate / row | Result | Route |
|---|---|---|
| `B1-SUSPEND` | §6 passed | No change — stays Implemented / live-validated. |
| `VAL-V030-GAMEPAD` | §1/§2 fail on specifics; §3 passes | Keep Pending validation. Fix `V031-GP-02` (popup input standdown) and `V031-GP-05` (details scroll + skipped buttons); tune `GP-03`/`GP-04`; add `GP-01` scroll margin. |
| `VAL-V023-DISPLAY` | Maximize + relaunch-to-saved pass; one-axis drag fails | Keep Pending validation. Fix `V031-DSP-01` (no window mutation during live drag; settle-then-persist) + `V031-DSP-01b` clamp. |
| `B6-MRD` / MRD-7 | No accepted mode; refined candidate specified | Build `V031-MRD-01` dual-outline candidate; F8 cycle stays until a candidate is accepted live. |
| `UI-INSPECTION` | Notes only | Carry `V031-GP-06` keybind focus order + focus scroll-margin styling into the UI pass. |
| `B6-INPUT` | Backlog pressure | If `GP-04` tuning fails a third time, promote the sensitivity sliders. |

## Sequencing

1. Code review + fixes for the gamepad class: `V031-GP-02` popup standdown,
   `V031-GP-05` details scroll/focus chain, `GP-03`/`GP-04` cadence tunes,
   `GP-01` scroll margin.
2. Display: diagnose and fix `V031-DSP-01` (record-only during live resize,
   settle-then-persist) and add the `DSP-01b` write-back clamp + tests.
3. MRD-7: implement the dual-outline candidate behind the existing F8 cycle.
4. Diagnostics (`V030-NG-FOCUS`, `V030-DSP-TRACE`) and F8 stay in until their
   gates close, then come out in one release-cleanup commit.
5. Cut `v0.3.2` as the next focused rerun: sections shrink to sub-menu focus,
   character-sheet navigation, one-axis drag, and the MRD-7 pick.
