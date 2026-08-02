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

## Campaign and save carry-forward

- [ ] Launch both bundled campaign packages and confirm expected factions spawn.
- [ ] Load existing v0.6.0 saves with their campaign packages installed.
- [ ] Confirm a missing campaign package blocks restore without changing the save.
  More helpful recovery wording is deliberately deferred to the associated plan.

## Result

- Tester / host:
- Date:
- PASS / FAIL:
- Notes and screenshot references:
