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
  fixture result needed to explain a failure. State Windows version, GPU/display,
  sections run, stopping point, and items not reproducible.
