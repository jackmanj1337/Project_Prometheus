---
Role: dated
Type: playtest
Status: Pending validation
Last verified: 2026-07-19
---

# v0.5.2 Windows Verification Checklist

## Purpose

This build verifies the v0.5.1 playtest blockers and retains the entire v0.5.0
regression sweep. Use a fresh folder containing only the supplied executable and fixture.
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

## 9. Full v0.5.0 regression sweep

v0.5.2 changed campaign selection/import, combat-source resolution, objective
progression, full-history rewind, results/casualty labels, and display layout. Re-run
every v0.5.0 regression area below in addition to the focused checks in §§1–8.
Where those sections already cover a behavior it is **cross-referenced, not
restated**. `NOT RUN — <reason>` is allowed **only** where an item explicitly offers
that option; every other item is required.

### 9.1 Save integrity, autosave, and full load (v0.5.0 §5)

- [ ] A named manual save stores the correct slot name, type, and campaign identity.
- [ ] An autosave fires and stays a slot distinct from manual saves.
- [ ] Loading that manual save restores roster, inventory, resources, campaign rules,
      current map/progression, and settings-relevant state. (§7 covers the
      Two-Map-Skirmish package/gold/rewind specifics; this is the general load-verify.)
- [ ] A deliberately corrupted or version-mismatched save copy is rejected with a
      clear integrity/version warning and does not damage valid slots.
      `NOT RUN — no corrupted-save fixture` if none is prepared.
- [ ] Export then import of a valid portable save preserves identity and loads.

### 9.2 Suspend and Retry hygiene (v0.5.0 §6)

- [ ] After a full quit and relaunch, Continue restores the exact recorded map,
      phase/turn, unit positions, HP, inventory, Pair Up, gold, and threat state.
      (§7 covers the focused mid-map restore; this is the full board-state comparison.)
- [ ] Completing a suspended-then-Continued map clears the suspend entry.
- [ ] Retry restores the original board, RNG timeline, inventory, economy, and campaign
      position without duplicating rewards or skipping a map.

### 9.3 Victory, rewards, and modal input-locking (v0.5.0 §7)

- [ ] A rewarded map's Victory/Results resolves exactly once.
- [ ] Results show `Gold earned` and `Total gold`, and before + earned = total
      (exact arithmetic; reopening or waiting never duplicates the award).
- [ ] While Results is visible, taps, held keys, d-pad/stick, wheel, clicks, and
      pointer motion do NOT move or activate the tactical map behind it.
- [ ] The Defeat overlay likewise blocks map input behind it.

Before gold: ______  Earned: ______  Total: ______

### 9.4 Menu Scale and results layout (v0.5.0 §1, §8)

- [ ] Main Menu stays centered and fully readable at tactical Menu Scale 0.5x,
      1.0x, and 2.0x.
- [ ] A rewarded result is fully visible (title, standings, reward rows, Retry,
      Quit; nothing clipped) at 0.5x, 1.0x, and 2.0x. Attach one original-resolution
      screenshot per scale.

### 9.5 UI regression, scaling, and theming (v0.5.0 §3, §9, §10)

- [ ] Unit Details, Item, Weapon, and Action menus open, stay readable, and close
      without trapping focus.
- [ ] Settings, Unit Details, Attack Preview, and the Action Menu stay usable at
      0.5x, 1.0x, and 2.0x menu scales.
- [ ] Overflowing More Info prose scrolls with Page Up/Down and mouse wheel (without
      moving the selected entry), and with right-stick (`NOT RUN — no controller`
      if unavailable).
- [ ] Changing the selected entry resets or clamps the old More Info scroll offset,
      and the scroll hint appears only on overflow.
- [ ] Main, Settings, Item, and Weapon screens use the intended consistent theme,
      and menus stay inside the viewport at 0.5x/1.0x/2.0x.

### 9.6 Combat and deferred skills (v0.5.0 §4)

- [ ] Confirming one combat resolves exactly once and leaves the game controllable,
      with HP, durability, experience, and death/incapacitation matching the
      displayed outcome.
- [ ] Attack Preview shows a plausible forecast; cancelling it changes no HP,
      inventory, gold, RNG-visible result, or map state.
- [ ] A promotion-validation combat with legacy Armsthrift/Dash and enemy
      Bastion/Iron Wall emits no `_apply_unimplemented` warning, and deferred skills
      stay absent from release-facing promotion/reclass choices.

### 9.7 Campaign package boundary (v0.5.0 §2)

Extends §§2–4 (valid import, source ownership, and chapter progression) with the
remaining package-boundary checks:

- [ ] A malformed or incompatible package is rejected with a useful message and does
      not partially replace active data. `NOT RUN — no malformed-package fixture`
      if none is prepared.
- [ ] Switching back to shipped content restores shipped campaign data.
- [ ] Exporting the same campaign twice produces equivalent content and excludes
      saves, caches, temporary state, and unrelated files.

### 9.8 Display and settings regression (v0.5.0 §10)

- [ ] Windowed, borderless, and fullscreen apply without crash or inaccessible UI;
      a supported windowed resolution applies; resizing via Windows controls
      recenters menus; audio and input continue after returning to the map.

Notes: ____________________

## 10. Logs and return package

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
