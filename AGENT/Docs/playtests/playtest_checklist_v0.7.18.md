---
Role: dated
Type: playtest
Status: Ready - native return round
Last verified: 2026-09-06
---

# v0.7.18 Windows Tester Checklist

The container tests and browser gates are supplemental evidence. This pass is
for native Windows display, GPU, window-manager, input, visual, and playability
evidence. Return this checklist, the diagnostics ZIP, and screenshots for defects.

## Section 0 — Start in this order

1. Verify `BUILD_INFO.json` and `SHA256SUMS.txt`, launch the supplied release
   executable once, and keep the supplied Godot user-data location unchanged.
2. Before importing any pack, use a clean profile with no saves: open **Load Game**
   and verify the empty state is clear; then resize below 600 px wide and run the
   compact Settings checks.
3. Only after pack-free checks, import the supplied `free-roam.zip`, migration v1,
   and migration v2 archives through Campaign Library. Do not edit them in place.
4. Copy `tester-fixtures-v0.7.18.zip` outside the game's user-data directory.

## Section 1 — Native diagnostics and window evidence

- [ ] The session header identifies v0.7.18, the actual executable, Windows
  platform, GPU, displays, DPI/refresh, live window mode/size, and content scale.
- [ ] The returned diagnostics ZIP opens cleanly and contains logs, settings,
  pack manifests, save-slot documents, and the contents manifest.
- [ ] Compare returned diagnostics records with this checklist and record any
  disagreement; do not transcribe normal log lines or count error lines.

## Section 2 — Compact settings and responsive layout

- [ ] Below 600 px wide, Settings labels stack above controls without clipping;
  slider trough, fill, and endcaps remain visible at 0%, 50%, and 100%.
- [ ] A popup/confirmation dialog is fully visible and usable with keyboard or
  controller input; normal-size/fullscreen recovery leaves no stale clipping,
  overflow, or lost focus.

## Section 3 — Phase banner and resumed-load visual pass

- [ ] Enter the first Proving Grounds battle; the phase banner spans and centres
  in the safe viewport, including after fullscreen/windowed changes and resize.
- [ ] Suspend & Quit, reload the battle, and verify the banner settles and hides;
  two close phase changes do not leave a superseded banner visible.

## Section 3a — Renewal transaction and suspend/Continue blocker

This is the native evidence still needed to clear the shared-effect architecture
blocker. Do not mark it passed from automated tests, a log count, or a different
skill. Use the supplied `free-roam.zip` to import **The Proving Grounds**, then
open a playable map without editing or re-zipping the pack.

1. Inspect the roster/unit details and find the authored Renewal unit:
   `Unit_05` / `unit_05_cleric`. Confirm that its skill list says **Renewal**.
   If the imported pack or candidate does not contain that unit, record the pack
   filename, manifest identity, and the missing unit as **blocked**; do not add a
   skill or alter the pack to make the test work.
2. In a safe battle, record the unit's map/node, faction, max HP, turn number,
   and current HP. Damage it without killing it, without using a healing item or
   staff, and without applying another healing effect. Leave enough missing HP
   that a heal is visible. The expected increase is:
   `min(max(1, floor(max_hp * 0.10)), max_hp - hp_before)`.
3. Advance to that unit's next eligible faction phase. Record HP immediately
   before and after phase start, and capture the unit HP and phase banner if the
   UI makes them visible. The result must be exactly one Renewal increase, with
   no second increase during the same phase. For `Unit_05` at max HP 16, the
   expected uncapped increase is 1 HP; if possible, repeat while one HP below
   full to show the cap at max HP.
4. Advance one more complete round and record the same values. There must be
   exactly one new Renewal increase on the next eligible phase and none during
   intervening/ineligible phases. If the candidate supplies an authored enemy
   unit with Renewal, repeat steps 2–4 for that enemy faction. If it does not,
   record that the supplied pack has no enemy Renewal fixture; do not substitute
   an enemy with another skill. The faction limitation must be visible in the
   returned evidence because the blocker cannot be fully cleared without the
   required faction coverage.
5. With Renewal already triggered for the current phase, use **Suspend & Quit**
   before that phase ends. Continue the same battle and record the unit HP on
   return. HP must be unchanged from the post-Renewal value: Continue must not
   replay the phase-start heal. Advance to the next eligible phase and confirm
   exactly one new increase there. Record any load/phase-start error shown in
   the UI or Godot log.

Return this filled table with the diagnostics ZIP and screenshots; it is the
minimum information needed to decide the blocker:

| run | faction | unit/id | max HP | HP before | expected delta | HP after phase start | turn/phase | HP before Suspend | HP after Continue | HP next eligible phase |
|---|---|---|---:|---:|---:|---:|---|---:|---:|---:|
| 1 — first eligible phase |  |  |  |  |  |  |  | n/a | n/a |  |
| 1b — next full round |  |  |  |  |  |  |  | n/a | n/a |  |
| 2 — enemy, if authored |  |  |  |  |  |  |  | n/a | n/a |  |
| 3 — suspend/Continue |  |  |  |  |  |  |  |  |  |  |

Attach screenshots that make the before/after HP and faction/phase readable.
Retain the Godot log inside the diagnostics export, and include the Windows
version, GPU, build stamp, candidate executable, imported pack manifest, and
whether any enemy Renewal fixture was available.

## Section 4 — Stateful dialogs, saves, and migration

- [ ] Empty-profile Load Game is clear; nested changed-save confirmation restores
  focus correctly after closing, and canceling replacement preserves the original
  row and bytes.
- [ ] Restore the supplied corrected campaign backup. Its two slots revalidate,
  share the expected pack identity, and return to the correct campaign/Prep node.
- [ ] Import migration v1/v2 and exercise supplied saves. Refusals name missing or
  mismatched content in player-facing language, with no raw internal id alone.
- [ ] Import free-roam, Suspend & Quit, reload, and export a non-empty save owned
  by the expected campaign.

## Section 5 — Proving Grounds campaign playability

- [ ] Input feels responsive and camera behavior is correct in battle/navigation.
- [ ] Play for roughly 45 minutes or until an honest stopping point; reachable
  objectives, rewards, progression, saves, and campaign/node resume remain valid.
- [ ] Record crashes, impassable walls, dead ends, or visual/input defects with
  screenshots and the diagnostics ZIP. Balance, difficulty, damage curves, and
  pacing are out of scope.

## Section 6 — Return package and closeout

- [ ] Use Settings **Export Diagnostics** or `Ctrl+Shift+F12` and return the
  resulting `Prometheus_diagnostics_<version>_<timestamp>.zip`.
- [ ] Return this completed checklist, screenshots for defects, and any save or
  fixture result needed to explain a failure. For Section 3a, include the
  completed HP/phase table, before/after screenshots, Godot log, and any missing
  faction fixture or phase-start error. State Windows version, GPU/display,
  sections run, stopping point, and items not reproducible.
