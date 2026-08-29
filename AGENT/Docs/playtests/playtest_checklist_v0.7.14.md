---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-08-29
---

# v0.7.14 Windows Tester Checklist

This replacement retains the unfinished v0.7.13 campaign/save scope. It restores the
bundled free-roam archive's schema admission and makes Load Game/import reachable on an
empty profile. Return this checklist, requested screenshots, and the complete Godot log
directory. Record observed text and behaviour, not only ticks.

## Build identity

- [ ] Log begins with BUILD STAMP version `0.7.14` and the commit in `BUILD_INFO.json`.
- [ ] Executable matches `SHA256SUMS.txt`.
- [ ] Windows version, GPU, display resolution, and controller: ______________________

## 1. Main Menu and Settings

- [ ] At approximately 360x640, **Project Prometheus** and the complete pre-install
  `New Game (No Data Packs Installed)` label are visible.
- [ ] Settings stays inside the viewport with side margins. Slider values, labels,
  keybinding names/descriptions, and Apply/Revert/Reset Controls are fully readable.
- [ ] Scroll top-to-bottom with mouse wheel, keyboard, and controller; move focus through
  every row; close Settings and confirm focus returns to Main Menu Settings.
- [ ] At desktop size, Settings returns to normal width and keybinding text remains whole.
- [ ] Menu Density offers Full/Standard/Minimal and persists after close/reopen.
- [ ] Screenshot narrow Main Menu, narrow Settings top/keybindings/bottom, and desktop Settings.

## 2. Slider native rendering and input

- [ ] Trough, fill, both endcaps, thumb, and value remain visible at min/mid/max.
- [ ] Mouse hover, keyboard focus, and controller focus are legible.
- [ ] Home/End or controller equivalents reach endpoints; directional input changes value
  predictably without losing focus.
- [ ] Screenshot the whole Settings screen and focused min/mid/max states.

## 3. Campaign-map return, save, and Settings

Import `free-roam-proving-grounds.zip` and start clean.

- [ ] Import succeeds; New Game launches Chapter 1 Prep; completing it reaches the map.
- [ ] Revisiting cleared Chapter 1 leaves battle disabled and Return to Campaign Map works
  with keyboard/controller, including Cancel.
- [ ] Chapter 2 is reachable and a later gated node states its prerequisite in a sentence.
- [ ] Save from the campaign map; record success text: _______________________________
- [ ] Quit fully, relaunch, Continue, and confirm the same map state.
- [ ] Open Settings from the map, change a harmless setting, close it, and confirm focus
  returns to the map Settings button.

## 4. Package-scoped saves and missing-pack recovery

Keep exported files outside Godot's user-data directory and do not overwrite fixtures.

- [ ] Import `migration-v1.0.0.zip`, start Two-Map Skirmish, save, then Export that slot.
- [ ] Quit, rename the Godot user-data directory as a temporary backup, relaunch clean,
  and import the portable JSON through Load Game.
- [ ] On that empty profile, Load Game is enabled, its empty state offers Import Save,
  and keyboard/controller focus starts on Import Save without a throwaway slot.
- [ ] The absent-pack save stays disabled, names `v076_migration_fixture` 1.0.0, offers a
  useful recovery action, and does not become Continue or change active content.
- [ ] Import `migration-v2.0.0.zip`, Retry/Load the save, and accept the migration preview.
- [ ] The save becomes runnable through migration and is grouped under its package/campaign.
- [ ] Screenshot grouped Load Game, missing-pack diagnostic, and recovered save.

## 5. Full campaign backup and transactional restore

- [ ] From Manage Campaigns, create a full backup for the active campaign.
- [ ] Backup includes clean pack plus user saves/status without changing play state.
- [ ] Change/remove installed campaign state, restore backup, accept confirmation, and
  confirm pack, saves, and status return and launch.
- [ ] Select `migration-v2.0.0.zip` in Restore; it is rejected as the wrong artifact type
  before commit and leaves installed pack, saves, status, and active campaign intact.
- [ ] From Load Game open Manage Campaigns and return; focus and selection return to Load Game.
- [ ] Screenshot backup confirmation, successful restore, rejected restore, and return focus.

## 6. Regression smoke and return contents

- [ ] Launch a reached battle; terrain renders and keyboard/controller remain responsive.
- [ ] Returned logs contain no duplicate-signal, stuck-modal, focus-loss, activation,
  migration, save, backup, or restore error.
- [ ] Include checklist, screenshots, tester-created exported files, and complete logs.

Restore the renamed pre-test user-data directory afterward if desired; do not merge the
two directories.
