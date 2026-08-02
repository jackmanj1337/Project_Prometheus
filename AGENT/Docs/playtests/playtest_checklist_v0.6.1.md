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

Owner instruction on accepting v0.5.8. Items 1–2 can ONLY be satisfied by returning the
log bundle — a verbal return can never satisfy them, which is why they have slipped
across v0.5.6, v0.5.7 and v0.5.8. Items 3–5 are observable on screen.

- [ ] **1. Controller hot-plug telemetry.** With a real pad: connect, disconnect and
  reconnect it during play. The log must contain a `PLAYTEST CONTROLLER
  device_id=… connected=…` line for every transition. Never collected in any return
  so far. **Return the log.**
- [ ] **2. Log inspection.** In the returned log confirm PRESENT: `=== BUILD STAMP ===`,
  `=== RUNTIME ENVIRONMENT ===`, `PLAYTEST CONTEXT`, and the controller telemetry above.
  Confirm ABSENT: any `[V030 TRACE]` line, and any resize trace file. **Return the log.**
- [ ] **3. FileDialog cancel/Escape input ownership** — failed again in v0.5.8. Covered
  in Input and stability above; record the outcome explicitly here.
- [ ] **4. Package save validation, missing-package half.** This has NEVER been run: the
  v0.5.6 tester wrote "don't know how to test this" because no instruction gave the
  path. Concretely: installed packs live under
  `%APPDATA%\Godot\app_userdata\Fire Emblem RPG\campaign_packs\installed\`
  (`user://campaign_packs/installed`, per `CampaignPackRegistry.gd`). Save a run, quit,
  move that pack's folder out of `installed\`, relaunch, and attempt to load the save.
  - [ ] Restore is blocked with a clear message.
  - [ ] The save file is NOT modified. Restore the folder afterwards and confirm the
    same save then loads normally.
- [ ] **5. Retry-after-Save and one-item-per-press controller movement.** Re-confirmation,
  not first verification — this PASSED 5/5 in the v0.5.6 return, but `19e2c0e4`
  restructured MapResultsScreen afterwards, so a failure REOPENS B4-RESULT-ACTIONS.
  - [ ] Retry Battle after using Save on the Results screen.
  - [ ] Controller movement advances exactly one item per press (no double-step).
  - [ ] Successor-dropdown navigation works — it failed in the v0.5.6 return.
- [ ] **While a real pad is in hand:** check whether joypad button 1 is bound to BOTH
  confirm and cancel at first launch
  (`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND-2026-07-24`).

## Campaign and save carry-forward

- [ ] Launch both bundled campaign packages and confirm expected factions spawn.
- [ ] Load existing v0.6.0 saves with their campaign packages installed.
- [ ] Confirm a missing campaign package blocks restore without changing the save
  (the concrete procedure is item 4 above). More helpful recovery wording is
  deliberately deferred to the associated plan.

## Result

- Tester / host:
- Date:
- PASS / FAIL:
- Notes and screenshot references:
- [ ] **The whole Godot log directory is attached.** Carry-forward items 1 and 2 cannot
  be closed without it, and they have now slipped four releases for exactly this reason.
