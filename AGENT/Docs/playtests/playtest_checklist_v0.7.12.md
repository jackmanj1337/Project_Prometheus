---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-08-28
---

# v0.7.12 Consolidated Windows Tester Checklist

This round combines the remaining v0.7.11 native checks with Compact Settings and
the pack-associated save, migration, recovery, backup, and restore work integrated
on 2026-08-27. Return this completed checklist, every requested screenshot, and the
complete Godot log directory. Record observed text and behaviour, not only ticks.

## Build identity

- [ ] The log begins with BUILD STAMP version `0.7.12` and the commit in `BUILD_INFO.json`.
- [ ] The executable matches `SHA256SUMS.txt`.
- [ ] Windows version, GPU, display resolution, and controller: ______________________

## 1. Main Menu, Compact Settings, and Menu Density

Before installing a pack, use the narrowest supported window size.

- [ ] **Project Prometheus** and `New Game (No Data Packs Installed)` are fully visible.
- [ ] Open Settings at approximately 360×640. The panel stays inside the viewport with
  side margins; labels, values, keybindings, and controls do not overlap or clip.
- [ ] Scroll from top to bottom with mouse wheel, keyboard, and controller.
- [ ] Move focus through every visible row and close Settings; focus returns to the
  Main Menu Settings button.
- [ ] At desktop size, Settings returns to its normal width without stretched rows.
- [ ] **Menu Density** offers Full / Standard / Minimal and persists after close/reopen.
- [ ] Screenshot narrow Main Menu, narrow Settings top and bottom, and desktop Settings.

## 2. Slider native rendering and input

At native resolution, exercise a Settings slider with mouse, keyboard, and controller.

- [ ] Trough, fill, both endcaps, and thumb remain visible at minimum, midpoint, and maximum.
- [ ] Mouse hover, keyboard focus, and controller focus are legible.
- [ ] Home/End or equivalent controller actions reach the endpoints; directional input
  changes the value predictably without losing focus.
- [ ] Screenshot the whole Settings screen and focused minimum/midpoint/maximum states.

## 3. Campaign-map return, save, and Settings

Import the supplied free-roam Proving Grounds pack and start clean.

- [ ] Import succeeds; New Game launches Chapter 1 Prep and completing it reaches the map.
- [ ] Revisit cleared Chapter 1. Its non-repeatable battle remains disabled and **Return
  to Campaign Map** works with keyboard and controller, including Cancel.
- [ ] Chapter 2 is reachable and a later gated node states its prerequisite in a sentence.
- [ ] On the campaign map choose **Save**; record the success text: __________________
- [ ] Quit the process fully, relaunch, choose Continue, and confirm the same map state.
- [ ] Open Settings from the campaign map, change one harmless setting, close it, and
  confirm focus returns to the map's Settings button.

## 4. Package-scoped saves and missing-pack recovery

Use the supplied versioned/migration fixtures. Do not overwrite the ZIP fixtures.

- [ ] Saves are grouped by package and campaign; two packages reusing a campaign id stay
  visibly distinct and the selected save launches the selected package.
- [ ] Import a portable save whose pack is absent. It is retained as disabled, explains
  which pack/version is missing, and does not alter the active campaign.
- [ ] Install the compatible destination pack and retry. The save becomes runnable and
  loads through the declared migration chain.
- [ ] Confirm the loaded campaign visibly identifies the expected fixture version/state.
- [ ] A fingerprint mismatch or unsupported migration remains disabled with a useful
  diagnostic; no partial pack, slot, catalogue, or active-campaign change remains.
- [ ] Screenshot the grouped Load Game view, missing-pack diagnostic, and recovered save.

## 5. Full campaign backup and transactional restore

- [ ] From **Manage Campaigns**, create a full backup for the active campaign.
- [ ] Confirm the backup includes the clean pack plus user saves/status without modifying
  the installed pack or current play state.
- [ ] Change or remove the installed campaign state, then restore the backup.
- [ ] Review the confirmation wording and complete restore. The pack, saves, and campaign
  status return and can be launched.
- [ ] Attempt a deliberately invalid or mismatched restore fixture. It is rejected before
  commit and the previously installed pack, saves, status, and active campaign remain intact.
- [ ] From Load Game open Manage Campaigns, then return; focus and selection return to the
  Load Game picker rather than unexpectedly jumping to the Main Menu.
- [ ] Screenshot backup confirmation, successful restore, rejected restore, and return focus.

## 6. Regression smoke and return contents

- [ ] Launch a reached battle; terrain renders and keyboard/controller input remain responsive.
- [ ] No duplicate-signal, stuck-modal, focus-loss, activation, migration, save, backup, or
  restore error appears in the returned logs.
- [ ] Completed checklist, screenshots, exported tester-created files used in Sections 4–5,
  and the complete Godot log directory are included.
