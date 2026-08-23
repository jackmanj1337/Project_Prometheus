---
Role: dated
Type: playtest
Status: Historical - returned smoke incomplete
Last verified: 2026-07-16
---

# v0.4.0 Windows Playtest and Smoke Checklist

> Returned tester copy. The byte-for-byte original is archived as
> `AGENT/Docs/archive/evidence/playtest_checklist_v0.4.0_d12eb33_returned_raw_2026-07-15.txt`.
> Intake findings are in
> `playtest_v0.4.0_results_triage_plan_2026-07-16.md`.

Return this completed file and the original `godot.log`. This playtest is the
v0.4.0 release checklist's smoke gate.

## Before testing

- Executable: `Project_Prometheus_v0.4.0_debug.exe`
- Expected byte size: `101840832`
- Expected SHA-256:
  `651bc28deca99724bef1a7a438350defc47fb6cdebd479050d4ad8140cc326a2`
- Windows version/device: 11
- Tester/date: ____________________
- Keyboard/mouse used: yes
- Controller model, or `NOT RUN`: Xbox
- Monitor and desktop resolution: ____________________

Verify the artifact in PowerShell:

```powershell
Get-FileHash .\Project_Prometheus_v0.4.0_debug.exe -Algorithm SHA256
```

- [ ] Filename, byte size, and SHA-256 match the build manifest.
- [x] Main Menu shows `v0.4.0`.
- [ ] The log's BUILD STAMP shows version `0.4.0`, the manifest commit, and a
      plausible build/start timestamp.

If any identity check fails, stop: the wrong or damaged build is under test.

## 1. Boot and main menu

Launch the executable normally on Windows.

- [x] The game reaches the Main Menu without a crash or blocking error dialog.
- [x] Menu text, focus, and buttons are visible and usable.
- [x] New Game, Continue state, Settings, and Quit have sensible enabled states.
- [ ] No release-blocking error appears at the start of `godot.log` after the
      BUILD STAMP.

Notes: ____________________

## 2. Start and operate a tactical map

Choose New Game and reach a playable map.

- [x] The map loads with terrain, units, HUD, cursor, and menus present.
- [x] Keyboard movement and confirm/cancel work.
- [x] Mouse hover, selection/click, right-click cancel, and wheel zoom work.
- [x] Map Menu and Unit Details open and close without trapping focus.
- [x] Action menus are readable, remain inside the viewport, and allow an
      ordinary move/action to complete.
- [x] If a controller is available, it can navigate menus, move the map cursor,
      confirm/cancel, and complete an action without duplicate input.
- [x] If controller hardware is unavailable, the controller item is marked
      `NOT RUN`; it does not invalidate the keyboard/mouse smoke result.

Notes: ____________________

## 3. Attack Preview and combat projection

Move a unit into attack range and select a valid target.

- [x] Attack Preview opens and displays attacker/defender forecast information.
- [x] Cancel the first preview: HP, inventory, party gold, and map state do not
      change merely from previewing.
- [x] Reopen the preview and confirm the attack.
- [x] One combat completes without a crash, stuck animation, or stuck phase.
- [x] Resulting HP and any death/incapacitation outcome are plausible for the
      displayed combat result.
- [x] The game remains controllable after combat.

Notes: ____________________

## 4. Victory gold through the resource ledger

Complete the map's victory condition and record party gold immediately before
and after the award when the UI permits.

- [ ] Victory resolves normally.
- [ ] Victory gold is awarded once through the normal results flow.
- [ ] The displayed total changes by the expected amount.
- [ ] Reopening menus, changing screens, or waiting does not duplicate the award.

Before: __________  Award: __________  After: __________

Notes: I cannot locate the party gold through the ui at all. extra note, the victory screen does not block the cursor from moving either through the keyboard or the gamepad.
## 5. Suspend, relaunch, and Continue

If victory ended the first map, start another map. Move units and complete at
least one combat so the state is unmistakably changed. Record unit positions,
HP, phase/turn, Pair Up state if used, and any watched threat marker. Use
Suspend & Quit, close the executable completely, relaunch it, and choose
Continue.

- [x] Suspend & Quit returns safely to the Main Menu.
- [x] Continue is enabled after relaunch.
- [x] Continue restores the same map and controlling phase/turn.
- [x] Unit positions and HP match the recorded suspended state.
- [x] Relevant inventory and Pair Up state are preserved.
- [x] Threat-watch state is preserved when one was set.
- [x] Play can continue normally after restoration.
- [x] Completing the restored map clears the suspend so Continue does not resume
      an already-finished battle.

Notes: At some point we need to make suspend save allowed during non blue turns

## 6. Settings and Windows display regression

Open Settings and exercise the available desktop display and menu controls.

- [x] Settings opens, focus remains visible, and every required row is reachable.
- [x] Windowed, borderless, and fullscreen changes apply without a crash or
      inaccessible UI.
- [x] A representative supported windowed resolution applies sensibly.
- [x] Menu Scale at `0.5x`, `1.0x`, and `2.0x` leaves Settings, Unit Details,
      Attack Preview, and Action Menu usable.
- [x] No unexpected horizontal scrollbar, clipped required control, opposite
      focus-scroll jump, or persistent stale Action Menu space is observed.
- [x] Audio and input continue after changing display mode and returning to the
      map.

Notes: At some point we need to check on the character sheet more info page and its scrolling behavior.

## 7. Log and regression result

After all checks, exit normally and preserve the original log reported by the
BUILD STAMP (normally under
`%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs`).

- [x] `godot.log` belongs to this BUILD STAMP and includes the tested session.
- [ ] No crash, assertion, registry-load failure, missing-resource error, or
      repeated release-blocking error appears in the log.
- [ ] Any failed box has exact reproduction steps: map, unit/UI, action, actual
      result, expected result, and whether it reproduces after relaunch.
- [x] Original-resolution screenshots accompany visual failures.

Final result: [ ] PASS  [ ] FAIL

Final notes: ____________________

## Return package

- [x] Completed `playtest_checklist_v0.4.0.md`.
- [x] Original `godot.log` containing the BUILD STAMP.
- [ ] Screenshots for every visual failure.
- [ ] Exact reproduction steps for every failed item.
- [ ] Windows, input-device, display, filename, size, and hash metadata above.
