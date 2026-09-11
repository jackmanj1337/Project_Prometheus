---
Role: dated
Type: playtest
Status: Ready - native return round
Last verified: 2026-09-11
---

# v0.7.19 Windows Tester Checklist

Container tests and browser gates are supplemental evidence. This pass is for
native Windows display, GPU, window-manager, input, visual, accessibility, and
playability evidence. Return this checklist, the diagnostics ZIP, and defect
screenshots.

## Section 0 — Start in this order

1. Verify `BUILD_INFO.json` and `SHA256SUMS.txt`; launch the supplied release
   executable once and keep the supplied Godot user-data location unchanged.
2. With a clean profile and no saves, use **Main Menu -> Manage Library ->
   New Game** to confirm the empty state; also open **Load Game** and verify its
   empty state is clear. Resize below 600 px and run the compact Settings checks.
3. From **Main Menu -> Manage Library**, import `free-roam.zip`, migration v1,
   and migration v2. Do not edit or re-zip the supplied archives.
4. Copy `tester-fixtures-v0.7.19.zip` outside the game's user-data directory.

## Section 1 — Native diagnostics and window evidence

- [ ] The session header identifies v0.7.19, the executable, Windows platform,
  GPU, displays, DPI/refresh, live window mode/size, and content scale.
- [ ] **Export Diagnostics** or `Ctrl+Shift+F12` produces a readable diagnostics
  ZIP containing logs, settings, pack manifests, save-slot documents, and its
  contents manifest. Return it with this checklist.
- [ ] Compare diagnostics records with this checklist; do not transcribe normal
  log lines or infer native results from container/browser evidence.

## Section 2 — Campaign Library route and compact layout

- [ ] Main Menu -> Manage Library -> New Game opens the playable campaign list;
  Back returns to the library hub with focus restored, and Back again returns to
  Main Menu. Load Game follows the same hub route and restores focus.
- [ ] Below 600 px wide, Settings labels stack above controls without clipping;
  slider trough, fill, endcaps, and thumb remain visible at 0%, 50%, and 100%.
- [ ] A popup/confirmation dialog is fully visible and usable with keyboard or
  controller input; normal-size/fullscreen recovery leaves no stale clipping,
  overflow, or lost focus.

## Section 3 — Phase banner and resumed-load visual pass

- [ ] Enter the first Proving Grounds battle; the phase banner spans and centres
  in the safe viewport after fullscreen/windowed changes and resize.
- [ ] Suspend & Quit, reload the battle, and verify the banner settles and hides;
  two close phase changes do not leave a superseded banner visible.

## Section 3a — Renewal transaction and suspend/Continue

Use the supplied `free-roam.zip` to import **The Proving Grounds**, then open a
playable map without editing or re-zipping the pack.

1. Find `Unit_05` / `unit_05_cleric` and confirm its skill list says **Renewal**.
   If absent, record the pack filename, manifest identity, and missing unit as
   blocked; do not alter the pack.
2. In a safe battle, record node, faction, max HP, turn, and current HP. Damage
   the unit without killing it or using another heal. Expected increase:
   `min(max(1, floor(max_hp * 0.10)), max_hp - hp_before)`.
3. Advance to the next eligible faction phase. Record HP immediately before and
   after phase start; it must increase exactly once, with no second increase in
   that phase. For max HP 16, the uncapped increase is 1 HP.
4. Advance one full round and repeat. If an authored enemy Renewal unit exists,
   repeat for that faction; otherwise record that no enemy fixture was supplied.
5. After Renewal triggers, Suspend & Quit before the phase ends. Continue must
   preserve post-Renewal HP (no replay), then the next eligible phase gets one
   new increase.

| run | faction | unit/id | max HP | HP before | expected delta | HP after phase start | turn/phase | HP before Suspend | HP after Continue | HP next eligible phase |
|---|---|---|---:|---:|---:|---:|---|---:|---:|---:|
| 1 — first eligible phase |  |  |  |  |  |  |  | n/a | n/a |  |
| 1b — next full round |  |  |  |  |  |  |  | n/a | n/a |  |
| 2 — enemy, if authored |  |  |  |  |  |  | n/a | n/a | n/a |  |
| 3 — suspend/Continue |  |  |  |  |  |  |  |  |  |  |

Attach screenshots making HP, faction, and phase readable, plus the Godot log
inside the diagnostics export. State Windows version, GPU/display, build stamp,
imported pack manifest, and whether enemy Renewal was available.

## Section 4 — Stateful dialogs, saves, and migration

- [ ] Empty-profile Load Game is clear; changed-save confirmation restores focus,
  cancel preserves the original row and bytes, and import remains reachable.
- [ ] Restore `campaign_backup_v2.zip`. Its slots revalidate, share the expected
  pack identity, and return to the correct campaign/Prep node.
- [ ] Import migration v1/v2 and exercise supplied saves. Refusals name missing
  or mismatched content in player-facing language, not only an internal id.
- [ ] Import free-roam, Suspend & Quit, reload, and export a non-empty save owned
  by the expected campaign.

## Section 5 — Proving Grounds playability

- [ ] Input feels responsive and camera behavior is correct in battle/navigation.
- [ ] Play for roughly 45 minutes or until an honest stopping point; reachable
  objectives, rewards, progression, saves, and campaign/node resume remain valid.
- [ ] Record crashes, impassable walls, dead ends, visual/input/accessibility
  defects with screenshots and the diagnostics ZIP. Balance, difficulty, damage
  curves, and pacing are out of scope.

## Section 6 — Return package and closeout

- [ ] Return the completed checklist, diagnostics ZIP, screenshots for defects,
  and any save or fixture needed to explain a failure.
- [ ] State Windows version, GPU/display, build stamp, sections run, stopping
  point, and items not reproducible. Native acceptance is pending until this
  evidence is reviewed; do not mark it passed from automated gates.
