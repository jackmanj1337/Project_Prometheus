---
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
- Expected executable size: pending export
- Expected executable SHA-256: pending export
- Expected fixture size: pending export
- Expected fixture SHA-256: pending export
- Expected BUILD STAMP commit/time: pending export
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

- [ ] Main Menu reaches a stable idle state without blocking errors.
- [ ] The wider panel contains all controls without clipping or title/version overlap.
- [ ] New Game, Continue, Load Game, Settings, and Quit remain usable.
- [ ] WASD, Z/X, mouse, and controller navigation work as applicable.

Screenshot at 1280x720 and notes: ____________________

## 2. FileDialog printable bindings

Open **New Game > Manage Campaigns > Import** and focus the filename field.

- [ ] The first press of X types `x`; it does not close or validate the dialog.
- [ ] Z types `z`; repeated X/Z and ordinary letters remain editable.
- [ ] Backspace, selection replacement, Cancel, and file selection still work.
- [ ] Import `two-map-skirmish-1.0.zip` successfully.

Exact filename text tested: ____________________

## 3. Campaign selector source ownership

- [ ] Before import, shipped Proving Grounds and shipped single-map choices appear once.
- [ ] After import, **Two-Map Skirmish** appears once without hiding shipped choices.
- [ ] Start Two-Map Skirmish, Suspend & Quit, then reopen New Game.
- [ ] Shipped choices still appear once and Two-Map Skirmish still appears once.
- [ ] Selecting a shipped campaign after the package switches back to shipped content.

Screenshot after suspend/reopen and notes: ____________________

## 4. Two-Map Skirmish combat and Chapter 1 progression

Start **Two-Map Skirmish > The Crossroads** through Prep.

- [ ] Alden and Mira spawn with usable Training Swords.
- [ ] Exactly three red raiders spawn with usable Training Swords.
- [ ] Blue and red units can attack and deal damage normally.
- [ ] Defeating all red units resolves the authored Rout objective.
- [ ] Results offers `Continue: River Pass`, not `Finish Campaign`.
- [ ] Clicking Continue autosaves and reaches River Pass Prep/map successfully.
- [ ] River Pass has two blue units, three armed red raiders, and a Rout objective.

Notes and screenshots: ____________________

## 5. Full-history Rewind and charges

On either skirmish map, perform several blue and red activations before rewinding.

- [ ] Rewind begins with 4 charges and is enabled.
- [ ] Every retained activation from the full map history remains selectable.
- [ ] Every selectable row costs exactly one charge, including the oldest row.
- [ ] Choosing a row restores HP, inventory, units, phase, cursor, RNG, and economy.
- [ ] Remaining charges show 3 after the first successful rewind and persist after
      Suspend & Quit / Continue.
- [ ] A boundary before a red activation resumes red AI; the game does not freeze
      waiting for player input or duplicate an already-completed activation.
- [ ] Four successful rewinds exhaust the pool; Rewind then disables.

Record oldest/newest rows and observed charge sequence: ____________________

## 6. Results and casualty labels

- [ ] With Permadeath On, a defeated blue unit appears as `Name — Fallen`.
- [ ] With Permadeath Off, a defeated blue unit appears as `Name — Retreated`.
- [ ] An escaped unit is not listed as a casualty.
- [ ] A true terminal campaign result alone reads `Finish Campaign`.
- [ ] Completing Promotion Validation or another generated one-map campaign returns
      to Main Menu without a failed advance.

Notes/screenshots: ____________________

## 7. Save, Retry, and modal regression

- [ ] Mid-map Suspend & Quit / Continue restores the correct turn and spent units.
- [ ] Retry restores the initial board and campaign position without skipping a map.
- [ ] Victory removes the stale mid-map resume slot only after resolution.
- [ ] Results waits for level-up/promotion presentation and blocks map input behind it.
- [ ] Autosave/Load Game preserves campaign package identity, roster, gold, inventory,
      rewind history, and remaining charges.

Notes/save names: ____________________

## 8. Display and settings regression

- [ ] Menu Scale options keep Main Menu, Prep, Results, and dialogs on-screen.
- [ ] Windowed resize/maximize/restore remains usable and controls do not drift off-screen.
- [ ] Settings save and reopen correctly; Reset restores expected defaults.
- [ ] No new clipping is visible at 1280x720 and one larger resolution.

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
