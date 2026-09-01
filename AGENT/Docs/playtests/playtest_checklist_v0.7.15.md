---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-09-01
---

# v0.7.15 Windows Tester Checklist

This is the **Revision B** checklist form, carried forward. v0.7.14's checklist was
rebuilt from the older compressed draft and silently dropped Section 0; without it two
sections below cannot be performed at all. Read Section 0 first.

This round finally reaches the campaign/save scope that v0.7.13 and v0.7.14 were both cut
for. Return this completed checklist, every requested screenshot, the tester-created
export files from Sections 5-6, and the complete Godot log directory. **Record observed
text and behaviour, not only ticks** — the wording of a dialog is often the thing under
test.

## What changed since the build you last played (v0.7.13)

- The bundled **free-roam Proving Grounds pack now imports.** v0.7.13 rejected it with
  `unknown_field ... traversal_mode` and lost you four sections. Every campaign in every
  bundled pack was driven to a live map in a browser before this bundle was assembled.
- The **migration v1/v2 fixtures were rebuilt from tracked sources.** The v2 archive you
  were handed last round shipped an incomplete identity declaration; that is why the
  migration section could not run.
- **Dropdowns can now be operated by keyboard and controller.** Previously the New Game
  campaign dropdown opened but arrow keys moved nothing. Section 4 tests this.
- Compact Settings containment and the slider trough/fill/endcap rendering you approved
  last round are still in — re-confirm briefly, do not re-test in depth.

**Already known, please do not spend time on it:** the slider border art stretches rather
than tiling at large scales, and Menu Density has no visible effect on the Settings screen
itself. Both of your v0.7.13 notes are logged and owned.

---

## Section 0 — Setup you need before starting

Read this section first. Two steps below are easy to get wrong in a way that silently
invalidates a whole later section.

### 0.1 Where your files live

Godot user-data directory (saves, settings, and logs):

```
%APPDATA%\Godot\app_userdata\Project Prometheus
```

Paste that into the Explorer address bar. The log directory is the `logs` subfolder
inside it. Section 6 asks you to rename this whole directory; the logs move with it, so
return **both** log folders — the pre-rename one and the one the clean relaunch creates.

### 0.2 How to reach the narrow window size

Sections 2 and 3 ask for approximately **360 x 640**. You cannot get there from in-game
Settings: the Resolution dropdown's smallest preset is 1280 x 720. Instead:

1. Set Window Mode to **Windowed** in Settings (not Borderless or Fullscreen).
2. Drag the window's left or right border inward until the window is roughly 360 px
   wide, then drag the bottom border to roughly 640 px tall.
3. Windows shows the pixel size in a tooltip while dragging on most systems. Exact
   numbers are not required — anything near 360 wide puts the game in its Compact size
   class, which is what these sections test. Under 600 px wide is the threshold that
   matters.

Record the size you actually reached: ______________ x ______________

### 0.3 Keep test files out of the game's folder

Every JSON or ZIP you export in Sections 5-6 must be written **outside** the Godot
user-data directory — put them beside this checklist. Do not overwrite the supplied
fixture ZIPs in `campaign-packs/`.

### 0.4 Order matters

Sections 2 and 3 must be done **before you install any campaign pack**. Installing a pack
un-gates New Game, and the pre-install button label is one of the things under test. Once
a pack is installed that evidence cannot be recovered without wiping the profile.

---

## Section 1 — Build identity

- [ ] The log begins with a BUILD STAMP reading version `0.7.15` and the commit recorded
  in `BUILD_INFO.json`. Record what you see: ______________________________________
- [ ] The executable matches `SHA256SUMS.txt` (`sha256sum -c SHA256SUMS.txt`, or
  `certutil -hashfile Project_Prometheus_v0.7.15.exe SHA256`).
- [ ] Windows version, GPU, display resolution, and controller model:

  ______________________________________________________________________

---

## Section 2 — Main Menu and Settings at Compact width

Do this **before installing any campaign pack**, at the ~360 x 640 window from step 0.2.

- [ ] The title **Project Prometheus** and the complete pre-install button label
  `New Game (No Data Packs Installed)` are both fully visible — no ellipsis, no clipping
  at either end. Record the label exactly as shown: ____________________________________
- [ ] Open Settings. The panel stays inside the viewport with visible side margins.
- [ ] **Every one of these is fully readable, not cut off:** slider values, row labels,
  keybinding names, keybinding descriptions, and the Apply / Revert / Reset Controls
  buttons along the bottom. Note anything still clipped: ______________________________
- [ ] Scroll from top to bottom three ways — mouse wheel, keyboard, and controller.
- [ ] Move focus through every visible row; nothing is skipped and nothing traps focus.
- [ ] Close Settings. Focus returns to the Main Menu **Settings** button.
- [ ] Resize back to desktop size. Settings returns to its normal width without stretched
  rows, and keybinding text remains whole.
- [ ] **Menu Density** offers exactly Full / Standard / Minimal, and the choice persists
  after closing and reopening Settings.
- [ ] Screenshots: narrow Main Menu; narrow Settings top; narrow Settings keybindings;
  narrow Settings bottom; desktop Settings.

---

## Section 3 — Slider native rendering and input

**At native desktop resolution**, pick one Settings slider and exercise it with mouse,
keyboard, and controller. This is a rendering check on real Windows GPU output — the
browser harness already approved the same states, so what matters here is whether native
rendering agrees. You approved this last round; a quick confirmation is enough.

- [ ] Trough, fill, **both** endcaps, thumb, and the numeric value all remain visible at
  minimum, midpoint, and maximum.
- [ ] Home / End (or the controller equivalents) reach the endpoints; directional input
  changes the value predictably without losing focus.
- [ ] Screenshots: the whole Settings screen, plus focused minimum, midpoint, and maximum.

---

## Section 4 — Keyboard and controller dropdown operation (NEW)

This is new in v0.7.15 and has never been confirmed on native Windows or on a physical
controller. Do it before installing a pack if you can reach a dropdown in Settings;
otherwise repeat it on the New Game campaign selector in Section 5.

- [ ] Focus a dropdown (Settings has several; New Game's campaign selector is the one
  that matters most) using **only** the keyboard. It opens with Enter or Space.
- [ ] With the popup open, **arrow keys move the highlight between rows** and wrap at the
  ends. Disabled rows and separators are skipped rather than trapping focus.
- [ ] Enter selects the highlighted row and the closed dropdown shows that new choice.
  Escape closes without changing the selection.
- [ ] Repeat all three with the **physical controller**. Record the controller model and
  anything that behaves differently from the keyboard:

  ______________________________________________________________________
- [ ] Focus returns somewhere sensible after the popup closes — not to the top of the
  screen, not nowhere.
- [ ] Screenshot the open popup with a row highlighted by keyboard.

---

## Section 5 — Campaign-map return, save, and Settings

Import `campaign-packs/free-roam-proving-grounds.zip` through Campaign Library and start
clean. Do not unzip it. This pack was driven to a live map in a browser against this exact
build before the bundle was assembled, so an import failure here is a **native-only**
defect and worth reporting in detail.

- [ ] Import succeeds with no error dialog. Record any diagnostic text that appears even
  on success: ______________________________________________________________
- [ ] New Game offers **The Proving Grounds** plus the individual map entries. Use the
  campaign dropdown with keyboard or controller (Section 4) to pick The Proving Grounds.
- [ ] New Game launches Chapter 1 Prep; completing it reaches the campaign map.
- [ ] Revisit cleared Chapter 1. Its non-repeatable battle stays disabled, and **Return to
  Campaign Map** works with keyboard and controller, including Cancel. It must not
  dead-end: you must always have a route back out. (This dead end is what rejected
  v0.7.10; the fix has never been confirmed natively.)
- [ ] Chapter 2 is reachable, and a later gated node states its prerequisite in a
  sentence. Record that sentence: ______________________________________________
- [ ] On the campaign map choose **Save**. Record the success text exactly:

  ______________________________________________________________________
- [ ] Quit the process fully, relaunch, choose Continue, and confirm the same map state.
- [ ] Open Settings from the campaign map, change one harmless setting, close it, and
  confirm focus returns to the **map's** Settings button.
- [ ] Screenshots: New Game campaign selector with the pack installed; the campaign map;
  the cleared-node revisit; the save confirmation.

---

## Section 6 — Package-scoped saves and missing-pack recovery

**Why the profile rename below matters:** this section needs the source pack to be
*genuinely absent*, not merely inactive. Renaming the user-data directory is what makes it
absent. If you skip that step the whole section passes for the wrong reason and the
evidence is void.

- [ ] Import `campaign-packs/migration-v1.0.0.zip`, start its **Two-Map Skirmish**
  campaign, and create a save.
- [ ] In Load Game, press **Export** on that save's row and write the portable JSON
  **beside this checklist** (see step 0.3).
- [ ] Quit fully. Rename `%APPDATA%\Godot\app_userdata\Project Prometheus` to something
  like `Project Prometheus_pretest` — this is your temporary backup, keep it.
- [ ] Relaunch to a clean profile. On this empty profile **Load Game is enabled**, its
  empty state offers **Import Save**, and keyboard/controller focus starts on Import Save
  without a throwaway slot being created.
- [ ] Import the portable JSON through Load Game → **Import Save...**.
- [ ] The absent-pack save is retained but **disabled**. It names
  `v076_migration_fixture` 1.0.0, and its row offers **Manage Campaigns** and **Retry**.
  It does **not** become Continue and does **not** change active content. Record the
  disabled row's tooltip / diagnostic text: ____________________________________________
- [ ] **(Do this now, while the disabled row still exists.)** From Load Game press
  **Manage Campaigns**, then come back. Focus and selection return to the Load Game
  picker rather than jumping to the Main Menu.
- [ ] Press **Retry** with the pack still missing. Record the message shown:

  ______________________________________________________________________
- [ ] Now import `campaign-packs/migration-v2.0.0.zip` and return to the disabled row.

**Read this before the next step.** Installing 2.0.0 does *not* make the 1.0.0 save load
directly. The row gains a button reading **`Import into 2.0.0`**. Pressing it opens a
preview dialog headed *"Create a migrated copy for version 2.0.0?"* listing a new slot
name and counts of references renamed vs. kept unchanged. Confirming with **Create
Migrated Copy** produces a **new** save; the original 1.0.0 save is preserved and stays
disabled. That is correct behaviour, not a bug.

- [ ] The **`Import into 2.0.0`** button appears on the row.
- [ ] The preview dialog lists a new slot name and the renamed / unchanged reference
  counts. Record the counts: renamed ________ , unchanged ________
- [ ] Confirm with **Create Migrated Copy**. The result message names the new slot and
  says the original was preserved. Record it: __________________________________________
- [ ] The **new** save is runnable and loads the Two-Map Skirmish state. The **original**
  1.0.0 save is still present and still disabled.
- [ ] Saves are grouped under their package/campaign — the fixture saves are **not** mixed
  in with the Proving Grounds saves.
- [ ] Screenshots: empty-profile Load Game; grouped Load Game view; missing-pack
  diagnostic; migration preview dialog; recovered/migrated save.

---

## Section 7 — Full campaign backup and transactional restore

Reached from Campaign Library (**Manage Campaigns**).

- [ ] With a campaign active, press **`Back Up...`** and create a full backup.
- [ ] The backup includes the clean pack plus user saves and status, and creating it does
  **not** modify the installed pack or your current play state.
- [ ] Change or remove some installed campaign state, then press **`Restore...`** and
  select your backup.
- [ ] **Read the confirmation wording before accepting** and record it here:

  ______________________________________________________________________
- [ ] Complete the restore. Pack, saves, and campaign status all return, and the campaign
  launches.
- [ ] Press **`Restore...`** again and deliberately select `campaign-packs/migration-v2.0.0.zip`
  — a campaign package, not a backup. It is rejected as the wrong artifact type **before
  anything is committed**, and the installed pack, saves, status, and active campaign are
  all left intact. Record the rejection text: __________________________________________
- [ ] From Load Game open Manage Campaigns and return; focus and selection return to Load
  Game rather than the Main Menu.
- [ ] Screenshots: backup confirmation; successful restore; rejected restore.

---

## Section 8 — Regression smoke and what to return

- [ ] Launch a reached battle. Terrain renders, and keyboard and controller input remain
  responsive.
- [ ] The returned logs contain no duplicate-signal, stuck-modal, focus-loss, activation,
  migration, save, backup, or restore error.
- [ ] Anything odd that no checklist line covers:

  ______________________________________________________________________

**Return all of:** this completed checklist; every screenshot listed above; the export
files you created in Sections 5-6; and the complete Godot log directory from step 0.1
(both the pre-rename copy and the post-rename one).

For reference, `screenshot-album-reference/` in the bundle holds browser-harness Settings
captures (360x640 and 1280x720) — useful if you want to compare what native Windows
renders against what the harness saw. `bundle-pack-gate-receipt.json` records the browser
run that proved every bundled campaign reaches a live map on this exact build.

---

## Afterwards

Delete the profile the test created and rename `Project Prometheus_pretest` back to
`Project Prometheus` if you want your pre-test profile returned. **Do not merge the two
directories** — take one or the other.
