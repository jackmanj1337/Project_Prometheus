---
Type: playtest
Status: Pending validation
Last verified: 2026-07-17
---

# v0.5.1 Windows Playtester Handbook

## What this build changes

v0.5.1 is a focused follow-up to v0.5.0. It adds:

- a rewind-history selector shared by the Map Menu and Defeat screen;
- unit name plus `(start x,y) → (end x,y)` on every rewind choice;
- `per_activation` and one-charge `full_history` rewind pricing;
- a two-map import fixture with two blue and three red units per map;
- Proving Grounds completion-gold capture in new status records;
- source-matched campaign benefits: the fixture carries that gold forward and
  grants Mira a **Proving Grounds Medal**;
- Tier-2 campaign-package item documents.

The original v0.5.0 status records did not store party gold. Create the Proving
Grounds completion record in this v0.5.1 build before testing gold transfer.

## Build identity

- Executable: `Project_Prometheus_v0.5.1_debug.exe`
- Campaign fixture: `two-map-skirmish-1.0.zip`
- Expected executable byte size: `102162400`
- Expected executable SHA-256: `44a11c6a86cae807547a54f72fb16a3bff4610270a3bd3e880c7e2abc778c6fc`
- Expected fixture byte size: `3652`
- Expected fixture SHA-256: `09737619bc15403d923d9b72ca1039cb157325f5cbca57867498b57a39abbfff`
- Expected BUILD STAMP commit: `d96d035`
- Expected built-at UTC: `2026-07-17T04:32:08Z`
- Windows version/device: ____________________
- Tester and date: ____________________
- CPU/GPU: ____________________
- Keyboard/mouse: ____________________
- Controller model, or `NOT RUN — no controller`: ____________________

Run in PowerShell:

```powershell
Get-FileHash .\Project_Prometheus_v0.5.1_debug.exe -Algorithm SHA256
Get-FileHash .\two-map-skirmish-1.0.zip -Algorithm SHA256
```

- [ ] Filenames, sizes, hashes, and BUILD STAMP match this handbook.
- [ ] Main Menu displays `v0.5.1`.

Stop if identity does not match.

## 1. Baseline smoke

- [ ] Game reaches Main Menu without a blocking error.
- [ ] New Game, Continue, Settings, Load, and Quit behave normally.
- [ ] Start Proving Grounds and enter its first tactical map through Prep.
- [ ] Move, combat, menus, Suspend & Quit, Continue, Retry, and results still work.
- [ ] Keyboard/mouse navigation works; controller works or is marked `NOT RUN`.

Notes: ____________________

## 2. Rewind selector and coordinates

Complete several blue actions with deliberately different start/end tiles.

- [ ] Map Menu shows `Rewind (N)` with the correct remaining charges.
- [ ] Selecting Rewind opens a history list rather than rewinding immediately.
- [ ] Each row names the activated unit.
- [ ] Each row shows accurate `(start x,y) → (end x,y)` coordinates.
- [ ] Two same-named units can be distinguished by their coordinates.
- [ ] Cancel returns focus to Rewind without moving the map or spending a charge.
- [ ] Choosing a row restores the boundary before that activation.
- [ ] The chosen cost is deducted exactly once.
- [ ] Inventory, gold, HP, positions, Pair Up, phase, cursor, and threat state match
      the selected boundary.

Record three example rows exactly as displayed:

1. ____________________
2. ____________________
3. ____________________

## 3. Rewinding across the enemy phase

Let all red units act. At the start of the next blue phase, open Rewind.

- [ ] The final red activation appears with its red unit and coordinates.
- [ ] Selecting it restores the boundary before that red activation.
- [ ] The red unit performs no unexplained duplicate action during restoration.
- [ ] Control and phase ownership are correct after replaying or changing the action.
- [ ] Repeating identical decisions reproduces identical deterministic results.
- [ ] Choosing a different committed action can produce a different RNG branch.

Notes: ____________________

## 4. Rewind cost modes

Proving Grounds uses the default `per_activation` behavior. The imported
Two-Map Skirmish fixture uses `full_history`.

- [ ] In Proving Grounds, older rows show increasing costs as more activations
      are crossed.
- [ ] Unaffordable rows are not offered.
- [ ] In Two-Map Skirmish, every retained row costs exactly one charge.
- [ ] A one-charge selection can reach the oldest retained activation.
- [ ] History depth remains bounded by retained data; no nonexistent history appears.
- [ ] With zero charges, Rewind is disabled.

Notes and observed costs: ____________________

## 5. Defeat-screen Rewind

- [ ] Trigger a defeat after several retained activations.
- [ ] Defeat screen Rewind opens the same labelled history selector.
- [ ] Coordinates and costs match the Map Menu presentation.
- [ ] Selecting a pre-defeat boundary dismisses Defeat and reloads a playable map.
- [ ] Cancel returns to the Defeat actions without spending a charge.

Notes: ____________________

## 6. Import the test campaign

Place `two-map-skirmish-1.0.zip` somewhere accessible to the Windows file picker.
From **New Game > Manage Campaigns > Import**, select it.

- [ ] Import reports package `two_map_skirmish` version `1.0` successfully.
- [ ] New Game lists **Two-Map Skirmish** without automatically starting it.
- [ ] It lists **The Crossroads** and **River Pass** as linked chapters.
- [ ] The first map loads Alden and Mira as blue units.
- [ ] Exactly three red raiders load on the first map.
- [ ] Terrain and starting positions match the package data.
- [ ] Re-importing the installed version is rejected without partial replacement.

Known v0.5.1 fixture limitation: imported Tier-2 objective conditions are not yet
deserialized. Defeating all red units may not resolve Chapter 1 or naturally
advance to Chapter 2. Record this as the known limitation, not a new regression.

Notes: ____________________

## 7. Create a fresh Proving Grounds status record

Use this v0.5.1 executable. Complete the five-map Proving Grounds campaign.

- [ ] Record party gold immediately before completing the final map: __________
- [ ] Completion returns to Main Menu without an error.
- [ ] Starting New Game and selecting Two-Map Skirmish finds the compatible
      Proving Grounds 1.0.0 record under Carry Forward.
- [ ] **None — start clean** remains available and selected by default.

If completing all five maps is impractical, mark the remaining status-transfer
checks `NOT RUN — no fresh v0.5.1 Proving Grounds completion record`.

Notes/status timestamp: ____________________

## 8. Carry-over gold and special item

Start Two-Map Skirmish once with **None**, then start it again with the fresh
Proving Grounds record.

- [ ] Clean start does not grant the Proving Grounds Medal.
- [ ] Clean start does not inherit the completed Proving Grounds gold.
- [ ] Record-backed start has exactly the final Proving Grounds party gold.
- [ ] Mira has one **Proving Grounds Medal** with infinite uses.
- [ ] Alden does not receive a duplicate medal.
- [ ] The benefit applies once; Retry, map reload, and Continue do not duplicate
      gold or the medal.
- [ ] Starting with an unrelated/manual record does not silently receive this
      source-specific benefit.

Clean gold: ______  Proving Grounds final gold: ______  Imported gold: ______

Notes: ____________________

## 9. Saves and compatibility

- [ ] A v0.5.0 save loads with `rewind_cost_mode` defaulted safely.
- [ ] A suspend made after several activations preserves the labelled rewind list.
- [ ] Older ledger entries without metadata remain loadable and show unknown
      coordinates rather than crashing.
- [ ] Saving/loading Two-Map Skirmish preserves carried gold, Mira's medal, package
      identity, and remaining rewind charges.

Notes/save names: ____________________

## 10. Regression carry-over from v0.5.0

v0.5.1 changed rewind pricing, the save/ledger, status records, and the
results/gold path, so re-confirm the v0.5.0 behaviors nearest that code — plus the
regression areas the full v0.5.0 suite covered that this focused handbook skips.
Where §§1–9 already cover a behavior it is **cross-referenced, not restated**.
`NOT RUN — <reason>` is allowed **only on the items below that explicitly carry a
`NOT RUN` option** (as in the v0.5.0 checklist); every other item is required.

### 10.1 Save integrity, autosave, and full load (v0.5.0 §5)

- [ ] A named manual save stores the correct slot name, type, and campaign identity.
- [ ] An autosave fires and stays a slot distinct from manual saves.
- [ ] Loading that manual save restores roster, inventory, resources, campaign rules,
      current map/progression, and settings-relevant state. (§9 covers the
      Two-Map-Skirmish gold/medal/charges specifics; this is the general load-verify.)
- [ ] A deliberately corrupted or version-mismatched save copy is rejected with a
      clear integrity/version warning and does not damage valid slots.
      `NOT RUN — no corrupted-save fixture` if none is prepared.
- [ ] Export then import of a valid portable save preserves identity and loads.

### 10.2 Suspend and Retry hygiene (v0.5.0 §6)

- [ ] After a full quit and relaunch, Continue restores the exact recorded map,
      phase/turn, unit positions, HP, inventory, Pair Up, gold, and threat state.
      (§9 covers that the labelled rewind list survives; this is board-state restore.)
- [ ] Completing a suspended-then-Continued map clears the suspend entry.
- Retry recovery and reward non-duplication are covered in §1 (smoke) and §8
  (benefit non-duplication) — not restated here.

### 10.3 Victory, rewards, and modal input-locking (v0.5.0 §7)

- [ ] A rewarded map's Victory/Results resolves exactly once.
- [ ] Results show `Gold earned` and `Total gold`, and before + earned = total
      (exact arithmetic; reopening or waiting never duplicates the award).
- [ ] While Results is visible, taps, held keys, d-pad/stick, wheel, clicks, and
      pointer motion do NOT move or activate the tactical map behind it.
- [ ] The Defeat overlay likewise blocks map input behind it. (Its Rewind recovery
      selector is exercised in §5.)

Before gold: ______  Earned: ______  Total: ______

### 10.4 Menu Scale and results layout (v0.5.0 §1, §8)

- [ ] Main Menu stays centered and fully readable at tactical Menu Scale 0.5x,
      1.0x, and 2.0x.
- [ ] The rewarded result is fully visible (title, standings, reward rows, Retry,
      Quit; nothing clipped) at 0.5x, 1.0x, and 2.0x. Attach one original-resolution
      screenshot per scale.

### 10.5 UI regression, scaling, and theming (v0.5.0 §3, §9, §10)

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

### 10.6 Combat and deferred skills (v0.5.0 §4)

- [ ] Confirming one combat resolves exactly once and leaves the game controllable,
      with HP, durability, experience, and death/incapacitation matching the
      displayed outcome.
- [ ] Attack Preview shows a plausible forecast; cancelling it changes no HP,
      inventory, gold, RNG-visible result, or map state.
- [ ] A promotion-validation combat with legacy Armsthrift/Dash and enemy
      Bastion/Iron Wall emits no `_apply_unimplemented` warning, and deferred skills
      stay absent from release-facing promotion/reclass choices.

### 10.7 Campaign package boundary (v0.5.0 §2)

Extends §6 (valid import / re-import rejection) with the boundary checks §6 omits:

- [ ] A malformed or incompatible package is rejected with a useful message and does
      not partially replace active data. `NOT RUN — no malformed-package fixture`
      if none is prepared.
- [ ] Switching back to shipped content restores shipped campaign data.
- [ ] Exporting the same campaign twice produces equivalent content and excludes
      saves, caches, temporary state, and unrelated files.

### 10.8 Display and settings regression (v0.5.0 §10)

- [ ] Windowed, borderless, and fullscreen apply without crash or inaccessible UI;
      a supported windowed resolution applies; resizing via Windows controls
      recenters menus; audio and input continue after returning to the map.

Notes: ____________________

## 11. Logs and return package

- [ ] Log belongs to this exact BUILD STAMP and contains the tested session.
- [ ] No crash, assertion, missing-resource, parser, package-validation, restore,
      or transaction failure appears in `godot.log`.
- [ ] Every failure includes exact steps, expected/actual behavior, repeatability,
      and an original-resolution screenshot.

Final result: [ ] PASS  [ ] FAIL

Release-blocking failures: ____________________

Return the completed package to:

`/workspace/godot-prometheus-env/repo/Project_Prometheus/AGENT/Incoming/v0.5.1/`

Include:

- completed `playtest_checklist_v0.5.1.md`;
- original `godot.log` containing the BUILD STAMP;
- screenshots for selector ambiguity, cross-enemy-phase restore, imported gold,
  and Mira's medal;
- any modified or rejected test artifacts used.

Tell the maintainer:

```text
v0.5.1 return is ready in AGENT/Incoming/v0.5.1/.
```
