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

Keep every exported JSON/ZIP outside Godot's user-data directory. Do not overwrite
the supplied fixtures. This section deliberately uses a fresh profile so the source
pack is genuinely absent rather than merely inactive.

- [ ] Import `migration-v1.0.0.zip`, start its Two-Map Skirmish campaign, create a save,
  then use Load Game **Export** to write that slot as a portable JSON beside this checklist.
- [ ] Quit fully. Rename the Project Prometheus Godot user-data directory as a temporary
  backup, relaunch to a clean profile, and import the portable JSON through Load Game.
- [ ] The absent-pack save is retained as disabled, names `v076_migration_fixture` 1.0.0,
  offers a useful recovery action, and does not become Continue or alter active content.
- [ ] Import `migration-v2.0.0.zip`, return to the disabled save, and choose Retry/Load.
  Review and accept the 1.0.0 → 2.0.0 migration preview.
- [ ] The same save becomes runnable, loads the Two-Map Skirmish state through the declared
  migration, and is grouped under its package/campaign rather than mixed with Proving Grounds.
- [ ] Screenshot the grouped Load Game view, missing-pack diagnostic, and recovered save.

## 5. Full campaign backup and transactional restore

- [ ] From **Manage Campaigns**, create a full backup for the active campaign.
- [ ] Confirm the backup includes the clean pack plus user saves/status without modifying
  the installed pack or current play state.
- [ ] Change or remove the installed campaign state, then restore the backup.
- [ ] Review the confirmation wording and complete restore. The pack, saves, and campaign
  status return and can be launched.
- [ ] In **Restore...**, deliberately select the supplied `migration-v2.0.0.zip` campaign
  package instead of a backup. It is rejected as the wrong artifact type before commit;
  the installed pack, saves, status, and active campaign remain intact.
- [ ] From Load Game open Manage Campaigns, then return; focus and selection return to the
  Load Game picker rather than unexpectedly jumping to the Main Menu.
- [ ] Screenshot backup confirmation, successful restore, rejected restore, and return focus.

## 6. Regression smoke and return contents

- [ ] Launch a reached battle; terrain renders and keyboard/controller input remain responsive.
- [ ] No duplicate-signal, stuck-modal, focus-loss, activation, migration, save, backup, or
  restore error appears in the returned logs.
- [ ] Completed checklist, screenshots, exported tester-created files used in Sections 4–5,
  and the complete Godot log directory are included.

After collecting evidence, restore the renamed pre-test user-data directory if you want
to keep the profile that existed before this round. Do not merge the two directories.
