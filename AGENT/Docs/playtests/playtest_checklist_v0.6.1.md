---
Role: dated
---

# v0.6.1 Windows Verification Checklist

## Build identity

**Do this first and stop if it fails.** The first v0.6.1 bundle shipped two executables
whose startup BUILD STAMP read `version=0.6.0 commit=cbd1f832` while every filename and
document said v0.6.1. A result recorded against a mis-stamped build cannot be attributed
to a commit and has to be thrown away.

- [ ] Both executables match `SHA256SUMS.txt` (`sha256sum -c SHA256SUMS.txt`).
- [ ] Startup log BUILD STAMP reads **`version=0.6.1 commit=a3987961`** — in BOTH
  executables — and matches `BUILD_INFO.json`. Main Menu shows `v0.6.1`.
- [ ] `Project_Prometheus_v0.6.1_debug.exe` shows the DEBUG MODE banner and
  `Project_Prometheus_v0.6.1.exe` does not. That is the difference between the two: they
  are the same source commit, exported with `--export-debug` and `--export-release`.
- [ ] Tester bundle includes the labeled Playwright screenshot album and `report.json`.

## Responsive UI

- [ ] Review centered menus at 1280×720, 1280×800, 1365×768, 1920×1080,
  2560×1440, and 3840×2160.
- [ ] At 2× menu/content scale, New Game scrolls; Unit Details stacks its regions;
  Results stacks report/actions; no centered frame leaves the safe viewport.
- [ ] **Windows are no bigger than they need to be.** Load Game and Campaign Library
  should be modest centered dialogs, NOT near-fullscreen panels — they previously
  rendered at 90% of the viewport on every display. New Game should still be a large
  scrolling frame. This is the change most likely to look wrong, and the automated
  containment checks cannot see it: an over-large window is still inside the viewport.
- [ ] Verify non-zero safe-area padding and HUD panel attachment/clamping.
- [ ] Confirm contextual action, attack-preview, weapon, item, and map menus remain
  anchored to gameplay rather than being forced to screen center.

## Input and stability

- [ ] Repeat keyboard, mouse, and controller navigation across every menu.
- [ ] Exercise FileDialog filename editing and Escape ownership.
- [ ] Repeat controller attacks, level-ups, end-turn confirmation, and menu transitions;
  attach the structured `TRANSITION` log if a lockout recurs. **Use the debug executable
  for this.** Tracing is now debug-only: the release build keeps the records in memory
  and writes nothing until the watchdog fires, at which point it flushes the retained
  history. Both produce usable evidence for a lockout, but only the debug build traces
  the whole session, so reproduce lockouts there if you can.
- [ ] Complete a representative map without a crash or stuck modal.

## Carry-forward items (PP-V060-CHECKLIST-CARRYFORWARD-2026-07-29)

**Items 1, 2, 4 and 5 are CLOSED on v0.6.0 evidence — do not re-run them.** They were
long described as never-collected, but the v0.6.0 return answered four of the five; two
were answered by returned logs nobody had opened. Full analysis:
[`v060_carryforward_log_inspection_2026-08-02.md`](v060_carryforward_log_inspection_2026-08-02.md).

Only these remain:

- [ ] **3. FileDialog cancel/Escape input ownership** — returned `FAILED` in v0.6.0. This
  is the one carry-forward item still genuinely open, and it is what the v0.6.1 explicit
  filename-edit state exists to fix. Record the outcome and the `escape_consumed_by`
  value from the log.
- [ ] **While a real pad is in hand:** does joypad button 1 do anything odd on
  accept/back? `[input]` binds `confirm=joy(1,0)` and `cancel=joy(2,1)`
  (`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND-2026-07-24`). Left unanswered in v0.6.0.
- [ ] **Filesystem check the logs cannot answer:** confirm NO v0.3.0 resize-trace file
  exists in `%APPDATA%\Godot\app_userdata\Fire Emblem RPG\`. The log half of this item
  already passed (no `[V030 TRACE]` lines in any of the seven v0.6.0 logs).

## Campaign and save carry-forward

- [ ] Launch both bundled campaign packages and confirm expected factions spawn.
- [ ] Load existing v0.6.0 saves with their campaign packages installed.
- [ ] Confirm a missing campaign package blocks restore without changing the save.
  Move the pack folder out of
  `%APPDATA%\Godot\app_userdata\Fire Emblem RPG\campaign_packs\installed\`, relaunch,
  load the save, then move it back. This PASSED in v0.6.0; re-run only as a regression
  check. More helpful recovery wording is deliberately deferred to the associated plan.

## Result

- Tester / host:
- Date:
- PASS / FAIL:
- Notes and screenshot references:
- [ ] **The whole Godot log directory is attached.** Returning logs is not enough on its
  own — the v0.6.0 logs came back complete and then sat uninspected for a day while the
  items they answered were still recorded as outstanding. Whoever triages this return
  greps the logs and records the result.
