# Session Note - 2026-08-05-15-30-08Z - controller modal inert fix

## Branch context

- Branch: `agent/from-integration/mobile-controller-web-wiring`
- Base branch: `agent/integration`
- Base SHA: `d61de61398f307b82a3c19aa9a9adcaef487b7ab`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`

## What was done

Took the defect the previous session recorded as **found, not fixed** and
outranked the remaining slices with: `CONTROLLER-TOUCH-MODAL-INERT-2026-08-05`,
"on touch, every on-screen control goes inert once a modal screen is open".

**It is two independent defects, not one, and both are now fixed.** The previous
session's recommended first step was to instrument whether
`ControllerService.press()` was reached at all. It is — the shell was never the
problem, and the browser was never needed to find out. Both reproduce headlessly
against a real `SettingsScreen`, which is how they were measured and how they are
now guarded.

**Defect 1 — the controller only ever spoke `ui_*`, and the game does not.**
`_emit_action` pressed the action and injected the mirrored `ui_*` event, which
is enough for Godot's GUI and reaches nothing else. But every screen under
`scripts/ui/` reads its own vocabulary out of `_input` / `_unhandled_input` —
`cancel`, `confirm`, `open_menu`, `inspect_unit`, `more_info`, `prev_unit`,
`next_unit` — and none of those is a `ui_*` action. `ModalScreen._unhandled_input`
asks for `cancel`; the controller sent `ui_cancel`; an `InputEventAction` matches
only its own name, so Back could not close anything. Measured: an injected
`cancel` closed the screen, an injected `ui_cancel` did not, a hardware Escape
did.

This was never modal-specific. Since Slice 2, *every* event-driven handler in the
game has been unreachable by touch — `MapMenu`, `ItemMenu`, `WeaponMenu`,
`ActionMenu`, `UnitDetailsScreen`, `LevelUpScreen`, `RewindSelector`,
`HudLayoutEditor`, `MapCursorInput`. A modal is just where it is impossible to
work around, because you cannot leave.

`_deliver_events()` now sends one event per action name, `ui_*` first and the
game action second, because that is what a hardware key already is: the mirror
stamps each game key onto its `ui_*` counterpart, so one press of Z is `confirm`
**and** `ui_accept`, and no single `InputEventAction` can stand in for that.

**Defect 2 — a tap could be shorter than a frame.** The shell reports pointerdown
and pointerup as two JavaScript callbacks; a synthesized tap, or a real one across
a dropped frame, delivers both before the engine next runs. Everything that reads
input by *polling* then sees the action go up and back down between two polls and
registers nothing at all — and that is exactly how a modal navigates: `ModalScreen`
consumes the `ui_up`/`ui_down` events in `_input` (so engine focus nav cannot also
move the highlight) and steps focus from `MenuRepeatPolicy` polling `_process`
instead. The map cursor polls too. `_emit_action` now holds a release that arrives
in its press's own frame until the next one, which is the shortest press a finger
could have produced anyway.

The lifecycle releases are deliberately exempt and let go at once: a release still
pending when the tab blurs or the scene changes is precisely the stuck action this
service exists to prevent, and the ledger no longer knows about it, so
`release_all_actions()` force-flushes.

**Three findings worth keeping, none of them visible in the code.**

1. **`Input.parse_input_event()` is not synchronous.** Events are buffered and
   dispatched at the next frame's flush. Two designs were built on the assumption
   that it dispatches inline and both had to be discarded — see below.
2. **`Viewport.is_input_handled()` cannot be read back after injecting an event**
   (measured: `false` even for an event a `_input` handler demonstrably consumed).
   So "did anything consume the `ui_*` event?" is not answerable at the injection
   site, which is what settled the ordering question by elimination.
3. **A focused `Button` does not consume an injected `InputEventAction("ui_accept")`
   at the GUI stage** even though it does activate on it — the event still reaches
   `_unhandled_input`. So gating the second event on "the GUI did not take it" would
   not have worked either. Ordering does the job instead: the `ui_*` event goes
   first, the focused button acts, and the screen-level `confirm` handler that
   follows finds itself already closed. Verified by counting emissions, not by
   watching the outcome: `back_pressed` fires **exactly once** per tap, on both the
   Back path and the Confirm-on-focused-button path.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

One substantive commit carrying the service fix, its two regression tests, the
GDD_07 rules and guard `[47]`.

## Gates

- `bash run_tests.sh` — all suites green. `test_controller_service` 86 → 92.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 301 files.
- `python3 AGENT/Docs/check_docs.py` — PASS, 47 checks.
- `node --test tools/web/controller_shell.test.mjs` — pass, 0 fail.
- **Each half of the fix was reverted in turn and the suite re-run**, because two
  green tests prove nothing about which defect they cover. Dropping the
  game-action event fails exactly the two modal cases; dropping the deferral fails
  exactly the tap-timing and modal-directional cases. Neither overlaps.
- Guard `[47]` verified to fail from four sides — the game-action injection
  removed, the deferral removed, the force-flush weakened, and the GDD wording
  softened. Its first version passed against code that released immediately,
  because an `_emit_action` that only *clears* the deferral dictionary still
  mentions it; the guard now requires the frame comparison and the write.
- **Not browser-verified.** Everything above is headless, driven through the real
  `ControllerService` against the real `SettingsScreen.tscn`. The seam the browser
  adds — the shell reporting element ids — was already proven in the previous
  session and is not what changed here. A fresh export and a Pixel 7 pass would
  still be worth having before the row closes.

## Next

**A browser pass on a fresh export** to close this row: open Settings from the
main menu on an emulated phone, step the rows, and come back out. That is the one
thing the headless evidence cannot supply, and it is now a short probe rather than
an investigation.

Then **Slice 4 step 3, element editing** (drag, scale, opacity) on the existing
`set_editing` seam, per the ordering in
`AGENT/Docs/plans/mobile_web_controller_remaining_slices_handoff_2026-08-05.md`.

Two things this session did not do and did not need to:
`scripts/playwright-drive.sh` still has no mobile-emulation flag, so any browser
pass is still hand-written; and `CONTROLLER-TOUCH-MODAL-INERT-2026-08-05` has **no
row in `coordination/tasks.json`** — the previous note says "tracked as", but the
container checkout has no such row and cannot be fetched from here (no git
credentials in this session). It needs registering and closing by someone who can
reach the tracker.

Branch is unmerged; no PR opened.
