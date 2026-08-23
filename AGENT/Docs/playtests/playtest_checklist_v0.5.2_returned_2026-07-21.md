---
Role: dated
Type: playtest
Status: Pending validation
Last verified: 2026-07-19
---

# v0.5.2 Windows Verification Checklist

## Purpose

This build verifies the v0.5.1 playtest blockers and retains a short regression
sweep. Use a fresh folder containing only the supplied executable and fixture.
Mark an unavailable check `NOT RUN — <reason>`; do not silently leave it blank.

## Build identity

- Executable: `Project_Prometheus_v0.5.2_debug.exe`
- Campaign fixture: `two-map-skirmish-1.0.zip`
- Expected executable size: `102168544` bytes
- Expected executable SHA-256: `76527c91872d666dde2cc73aedf6a96e4d438c696574067840f3571ae6e5d1d4`
- Expected fixture size: `4271` bytes
- Expected fixture SHA-256: `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`
- Expected BUILD STAMP: version `0.5.2`, commit `06e0386`, built
  `2026-07-19T02:08:57Z`
- Windows version/device/GPU: ____________________
- Tester and date: ____________________
- Controller, or `NOT RUN — no controller`: ____________________

PowerShell:

```powershell
Get-FileHash .\Project_Prometheus_v0.5.2_debug.exe -Algorithm SHA256
Get-FileHash .\two-map-skirmish-1.0.zip -Algorithm SHA256
```

- [ ] Filenames, sizes, hashes, Main Menu `v0.5.2`, and BUILD STAMP match.
- [ ] The log begins with the same BUILD STAMP. Stop if identity differs.

## 1. Main Menu and baseline smoke

- [x] Main Menu reaches a stable idle state without blocking errors.
- [x] The wider panel contains all controls without clipping or title/version overlap.
- [x] New Game, Continue, Load Game, Settings, and Quit remain usable.
- [x] WASD, Z/X, mouse, and controller navigation work as applicable.

Screenshot at 1280x720 and notes: 

## Proving grounds notes
During the escape mission, the cavalier was paired up with the mercenary and when they escaped together we got the same `next battle is unavailable` and `Campaign data error` but when the map was replayed and the units escaped separately the error did not occur. Also realized that the defend map had never been tested and could not make it past that map and victory was not granted even when all units survive past turn 8.
## 2. FileDialog printable bindings

Open **New Game > Manage Campaigns > Import** and focus the filename field.

- [ ] The first press of X types `x`; it does not close or validate the dialog.
- [x] Z types `z`; repeated X/Z and ordinary letters remain editable.
- [x] Backspace, selection replacement, Cancel, and file selection still work.
- [x] Import `two-map-skirmish-1.0.zip` successfully.

Exact filename text tested: 
`z` works but `x` backs out of the selection and enables `wasd` as navigation. pasting a `x` through the clip board worked.

## 3. Campaign selector source ownership

- [x] Before import, shipped Proving Grounds and shipped single-map choices appear once.
- [x] After import, **Two-Map Skirmish** appears once without hiding shipped choices.
- [x] Start Two-Map Skirmish, Suspend & Quit, then reopen New Game.
- [x] Shipped choices still appear once and Two-Map Skirmish still appears once.
- [x] Selecting a shipped campaign after the package switches back to shipped content.

Screenshot after suspend/reopen and notes: ____________________

## 4. Two-Map Skirmish combat and Chapter 1 progression

Start **Two-Map Skirmish > The Crossroads** through Prep.

- [x] Alden and Mira spawn with usable Training Swords.
- [x] Exactly three red raiders spawn with usable Training Swords.
- [x] Blue and red units can attack and deal damage normally.
- [x] Defeating all red units resolves the authored Rout objective.
- [x] Results offers `Continue: River Pass`, not `Finish Campaign`.
- [x] Clicking Continue autosaves and reaches River Pass Prep/map successfully.
- [x] River Pass has two blue units, three armed red raiders, and a Rout objective.

Notes and screenshots: ____________________

## 5. Full-history Rewind and charges

On either skirmish map, perform several blue and red activations before rewinding.

- [x] Rewind begins with 4 charges and is enabled.
- [x] Every retained activation from the full map history remains selectable.
- [x] Every selectable row costs exactly one charge, including the oldest row.
- [x] Choosing a row restores HP, inventory, units, phase, cursor, RNG, and economy.
- [x] Remaining charges show 3 after the first successful rewind and persist after
      Suspend & Quit / Continue.
- [x] A boundary before a red activation resumes red AI; the game does not freeze
      waiting for player input or duplicate an already-completed activation.
- [x] Four successful rewinds exhaust the pool; Rewind then disables.

Record oldest/newest rows and observed charge sequence: Noticed that the cursor on the rewind selector during first level of the proving grounds seemed to skip certain rows and would take disapear and start to move the cursor on the map menu every now and then and confirming while the cursor was on settings oppened up the settings menu. After closing the settings menu, all menus closed, but when the map menu opened again the rewind menu was already open. Check that both menus are seperated and input is consumed properly. Also do a complete investigation of why this happened as this is not the first time we have a problem that looked like this and try to make a note about preventing this kind of error in the future.

It seems like two map skirmish history is not being stored the way I expected (full complete history) it seems that only 5 actions are recorded, it also seems that history is not being removed during a rewind. Also note that a manual turn end should expend each remaining unactivated unit and lodge a point in the history.

Also note that the gold display does not change per active faction
## 6. Results and casualty labels

- [x] With Permadeath On, a defeated blue unit appears as `Name — Fallen`.
- [x] With Permadeath Off, a defeated blue unit appears as `Name — Retreated`.
- [x] An escaped unit is not listed as a casualty.
- [x] A true terminal campaign result alone reads `Finish Campaign`.
- [x] Completing Promotion Validation or another generated one-map campaign returns
      to Main Menu without a failed advance.

Notes/screenshots: ____________________

## 7. Save, Retry, and modal regression

- [x] Mid-map Suspend & Quit / Continue restores the correct turn and spent units.
- [x] Retry restores the initial board and campaign position without skipping a map.
- [x] Victory removes the stale mid-map resume slot only after resolution.
- [x] Results waits for level-up/promotion presentation and blocks map input behind it.
- [x] Autosave/Load Game preserves campaign package identity, roster, gold, inventory,
      rewind history, and remaining charges.

Notes/save names: ____________________

## 8. Display and settings regression

- [x] Menu Scale options keep Main Menu, Prep, Results, and dialogs on-screen.
- [x] Windowed resize/maximize/restore remains usable and controls do not drift off-screen.
- [x] Settings save and reopen correctly; Reset restores expected defaults.
- [x] No new clipping is visible at 1280x720 and one larger resolution.

Notes/screenshots: ____________________

## 9. Logs and return package

- [ ] No crash, assertion, parser, missing-resource, restore, package-validation,
      transaction, or repeated error appears after the BUILD STAMP.
- [ ] Each failure records exact steps, expected/actual behavior, repeatability,
      relevant save name, and an original-resolution screenshot.

Final result: [ ] PASS  [ ] FAIL

Release-blocking failures: ____________________

Return to:

`/workspace/godot-prometheus-env/repo/Project_Prometheus/AGENT/Incoming/v0.5.2/`

Include the completed checklist, original `godot.log`, and screenshots for the Main
Menu, post-suspend selector, Chapter 1 results, River Pass, casualty labels, and
full-history Rewind. Tell the maintainer:

```text
v0.5.2 return is ready in AGENT/Incoming/v0.5.2/.
```

We need to make a todo list item to remove all data from the engine and make everything fully reliant on the campaign packs. The main menu should replace the `new game` and `load game` with a campaign selector, and after a campaign has been selected then the player can choose to load a save from that campaign, or start a new file for that campaign. We should also look at how the campaign packs and the save data are serialized and look for any ways to deduplicate within the self contained campaign packs. As part of that we should add more human readable labels to the save data and packs so they are easier to debug. But we should talk about all of this and flesh out the plan and all the effects before doing anything.