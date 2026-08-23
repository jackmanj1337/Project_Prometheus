---
Role: dated
Type: playtest
Status: Pending validation
Last verified: 2026-07-16
---

# v0.5.0 Consolidated Windows Playtest Checklist

## Changelog since the stable v0.4 line

- Added the integrated campaign-package workflow: discovery, validation,
  installation, deterministic export, campaign selection, and Tier-2 runtime
  activation.
- Added unified named save slots, autosaves, suspend/Continue, Retry, Rewind,
  portable save integrity checks, campaign identity, mutable campaign rules,
  and completion-status export/import.
- Added deterministic encounter/deployment data and encounter-model foundations.
- Added victory results with committed reward and total-gold displays, plus
  duplicate-award protection.
- Added explicit gameplay-modal cursor locking so results and defeat overlays
  block keyboard, held-key, controller, and pointer movement behind them.
- Added keyboard/controller More Info prose scrolling and release-availability
  filtering for deferred skills.
- Updated Main Menu, Settings, Item, and Weapon UI theming; kept the Main Menu
  readable independently of tactical menu scale.
- Corrected results layout behavior at 0.5x, 1.0x, and 2.0x menu scales and
  preserved the v0.4 tester-feedback fixes in the consolidated architecture.

This is the authoritative full-feature validation for v0.5.0. Complete every
required field. Use `NOT RUN — <reason>` only where the checklist explicitly
permits it. Return this same file rather than writing a separate summary.

## Build and tester identity

- Executable: `Project_Prometheus_v0.5.0_debug.exe`
- Expected byte size: `102150680`
- Expected SHA-256: `81dabb79b302e27607d54404ad963195c8d314e833bcc08b336f3653d676ca49`
- Expected BUILD STAMP commit: `2e3f55d`
- Expected built-at UTC: `2026-07-16T23:49:38Z`
- Windows version/device: ____________________
- Tester and date: ____________________
- CPU/GPU: ____________________
- Monitor/native resolution: ____________________
- Keyboard/mouse: ____________________
- Controller model, or `NOT RUN — no controller available`: ____________________

In PowerShell, run:

```powershell
Get-FileHash .\Project_Prometheus_v0.5.0_debug.exe -Algorithm SHA256
```

- [ ] Filename, byte size, and SHA-256 exactly match this checklist.
- [ ] Main Menu displays `v0.5.0`.
- [ ] `godot.log` begins with a BUILD STAMP matching the commit and built-at
      values above.

Stop immediately if an identity check fails. Record the mismatch and do not
continue against an unknown build.

## 1. Boot, menus, and input smoke

- [ ] The game reaches Main Menu without a crash or blocking error.
- [ ] New Game, Continue, Settings, and Quit have sensible enabled states.
- [ ] Keyboard and mouse can navigate, confirm, cancel, and return from Settings.
- [ ] A controller can navigate, confirm, and cancel without duplicate input, or
      this item is marked `NOT RUN — no controller available`.
- [ ] Main Menu remains centered and fully readable at tactical Menu Scale 0.5x,
      1.0x, and 2.0x.

Notes: ____________________

## 2. Campaign selection and package boundary

- [ ] New Game lists shipped campaigns and starts the selected campaign/map.
- [ ] Returning from the selector does not accidentally start or change a campaign.
- [ ] If an existing valid test campaign package is available, install/refresh it
      and confirm its title, version, maps, and roster are shown correctly.
- [ ] A malformed or incompatible package is rejected with a useful message and
      does not partially replace active data. If no fixture is available, mark
      `NOT RUN — no package fixture`.
- [ ] Switching back to shipped content restores shipped campaign data.
- [ ] Exporting the same campaign twice produces equivalent content and excludes
      saves, caches, temporary state, and unrelated files.

Notes/package identity: ____________________

## 3. Tactical map and encounter/deployment smoke

- [ ] A selected map loads terrain, deployment, units, HUD, cursor, and objectives.
- [ ] Deployment positions and force membership match the selected encounter.
- [ ] No two units occupy the same tile after spawn/deployment.
- [ ] Keyboard movement, confirm/cancel, mouse selection/right-click, and zoom work.
- [ ] Controller cursor/menu/action operation works, or is marked `NOT RUN` above.
- [ ] Map Menu, Unit Details, Item, Weapon, and Action menus open, remain readable,
      and close without trapping focus.

Notes/map: ____________________

## 4. Combat, projection, and deferred skills

- [ ] Attack Preview shows plausible attacker/defender forecast information.
- [ ] Cancelling preview changes no HP, inventory, party gold, RNG-visible result,
      or map state.
- [ ] Confirming one combat resolves once and leaves the game controllable.
- [ ] HP, durability, experience, death/incapacitation, and displayed outcome agree.
- [ ] Promotion-validation combat with legacy Armsthrift/Dash and enemy
      Bastion/Iron Wall emits no `_apply_unimplemented` warning.
- [ ] Deferred skills are absent from release-facing promotion/reclass choices;
      implemented skills remain available.

Notes: ____________________

## 5. Save slots, autosave, integrity, and load

- [ ] Create a named manual save and confirm slot name/type/campaign identity.
- [ ] Trigger an autosave and confirm manual and autosave slots remain distinct.
- [ ] Load the manual save and verify roster, inventory, resources, campaign rules,
      current map/progression, and settings-relevant state.
- [ ] A deliberately invalid or unsupported save copy is rejected with a clear
      integrity/version warning and does not damage valid slots. If no safe copy
      is prepared, mark `NOT RUN — no corrupted-save fixture`.
- [ ] Export/import of a valid portable save preserves identity and loads normally.

Notes/save names: ____________________

## 6. Suspend, Continue, Retry, and Rewind

On a map, move units and complete combat. Record turn/phase, positions, HP,
inventory, gold, Pair Up state, and threat-watch state.

- [ ] Suspend & Quit safely returns to Main Menu.
- [ ] After fully closing and relaunching, Continue restores the exact recorded
      map, phase/turn, positions, HP, inventory, Pair Up, gold, and threat state.
- [ ] Play continues normally after restoration.
- [ ] Rewind restores the prior deterministic ledger state and consumes/records
      its cost correctly; replaying from it does not corrupt RNG or resources.
- [ ] Retry follows the intended recovery path without duplicating rewards or
      carrying invalid transient state.
- [ ] Completing the restored map clears the suspend entry.

Recorded pre-suspend state and notes: ____________________

## 7. Victory, defeat, rewards, and modal ownership

- [ ] Complete a rewarded Rout map. Victory resolves once.
- [ ] Results show `Gold earned` and `Total gold`; Map Menu previously showed the
      matching starting total.
- [ ] Before + earned = displayed total, and reopening/waiting never duplicates it.
- [ ] While Results is visible, taps, held keys, d-pad/stick, wheel, clicks, and
      pointer attempts do not move or activate the tactical map behind it.
- [ ] Retry and Quit to Menu are visible, focused, and usable.
- [ ] Trigger a defeat where practical; its overlay also blocks map input and its
      recovery choices work. If no practical fixture exists, mark `NOT RUN` with map.

Before gold: ______  Earned: ______  Total: ______

Notes: ____________________

## 8. Results layout at every menu scale

Complete or reopen the rewarded Rout result at each scale.

- [ ] At 0.5x, title, standings, reward rows, Retry, and Quit are fully visible.
- [ ] At 1.0x, title, standings, reward rows, Retry, and Quit are fully visible.
- [ ] At 2.0x, title, standings, reward rows, Retry, and Quit are fully visible.
- [ ] Attach one original-resolution screenshot for each scale.
- [ ] No panel is clipped at the top/left or pushed outside the usable viewport.

Notes/resolution per scale: ____________________

## 9. Unit Details and UI regression

- [ ] Overflowing More Info prose scrolls with Page Up/Page Down.
- [ ] It scrolls with right-stick vertical input, or controller is `NOT RUN`.
- [ ] It scrolls with mouse wheel without moving the selected entry.
- [ ] The scroll hint appears only for overflow; changing entries resets or clamps
      the old offset.
- [ ] Main, Settings, Item, and Weapon screens use the intended consistent theme.
- [ ] Menus remain inside the viewport at 0.5x, 1.0x, and 2.0x.

Notes: ____________________

## 10. Display and settings regression

- [ ] Windowed, borderless, and fullscreen apply without crash or inaccessible UI.
- [ ] A supported windowed resolution applies and the displayed mode is sensible.
- [ ] Resizing via Windows controls recenters menus without stretching or clipping.
- [ ] Settings, Unit Details, Attack Preview, and Action Menu remain usable at all
      three menu scales.
- [ ] Audio and input continue after display changes and returning to the map.

Notes: ____________________

## 11. Campaign completion and status transfer

- [ ] Complete a campaign/map outcome and confirm progression/successor selection
      follows authored data.
- [ ] Completion status export includes the expected campaign identity and result.
- [ ] Importing a compatible completion record seeds the expected New Game state.
- [ ] An incompatible record is rejected without partial mutation.

Notes/status artifact: ____________________

## 12. Log review and final result

Exit normally and copy the original log from the BUILD STAMP's `log=` path,
normally `%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs\godot.log`.

- [ ] Log belongs to this exact BUILD STAMP and contains the tested session.
- [ ] No crash, assertion, registry failure, missing resource, save transaction
      failure, repeated reward, or release-blocking error appears.
- [ ] Every failed box includes map/screen, exact steps, actual result, expected
      result, repeatability after relaunch, and an original-resolution screenshot.

Final result: [ ] PASS  [ ] FAIL

Release-blocking failures: ____________________

Tester comments and requested changes: ____________________

## Return instructions

Return the completed package inside this environment at:

`/workspace/godot-prometheus-env/repo/Project_Prometheus/AGENT/Incoming/v0.5.0/`

Create the directory if necessary. Put these files directly inside it:

- Completed `playtest_checklist_v0.5.0.md`
- Original matching `godot.log`
- Any exported save/campaign/status fixture requested by a failed test
- A short `README.txt` only if extra context does not fit in the checklist

Put every photo or screenshot in:

`/workspace/godot-prometheus-env/repo/Project_Prometheus/AGENT/Incoming/v0.5.0/screenshots/`

Use descriptive names such as `results_0.5x_1920x1080.png` or
`save_integrity_failure.png`. Do not edit, resize, crop, or recompress evidence.
Keep the original resolution. When all files are copied, tell the agent that the
v0.5.0 return is ready in `AGENT/Incoming/v0.5.0/`.
