---
Role: dated
Type: playtest
Status: Ready - diagnostics-first native round
Last verified: 2026-09-06
---

# v0.7.17 Windows Tester Checklist

This round asks the build to measure what it can and asks you to judge what only a
real Windows display, GPU, window manager and human can judge. Please return this
checklist, the diagnostics bundle, and screenshots for anything that looks wrong.

## Section 0 — Start in the right order

1. Launch the supplied release executable once and leave the user-data/log location
   unchanged. The executable writes a diagnostics log beside Godot's normal log.
2. Before importing any campaign pack, use a profile with no saves and open **Load
   Game**. Confirm that the empty profile is handled cleanly and that the screen does
   not present a misleading selectable save.
3. Only after that pass, import `campaign-packs/free-roam-proving-grounds.zip` through
   Campaign Library. Installing a pack unlocks New Game, so importing first destroys
   the pack-free evidence.

The diagnostics session header carries the build stamp, executable identity, platform,
GPU, displays, window/content-scale configuration, settings, installed packs, user-data
migration state and RNG seed. Do not copy those values into this checklist.

## Section 1 — Native diagnostics header

After the run, open the diagnostics log in the returned bundle.

- [ ] The session header contains real Windows display records: resolution, DPI,
  refresh rate and scale.
- [ ] The window record contains the live window mode, size and content-scale
  configuration.
- [ ] The header identifies the actual build and the installed pack(s).
- [ ] No diagnostic category is producing an unbounded error storm.

This is a bundle cross-check, not a transcription exercise. If a record is missing or
clearly wrong, note the category and attach a screenshot if the display shows the issue.

## Section 2 — Compact Settings and responsive layout

Switch to Windowed mode and resize to approximately 360 x 640 (anything under 600 px
wide is sufficient), then open Settings.

- [ ] Compact rows stack each label above its control.
- [ ] No label is clipped and no control leaves the right edge or safe viewport.
- [ ] Sliders show a visible trough, filled portion and endcaps.
- [ ] Open a popup/dialog and confirm it is correctly sized and positioned.
- [ ] Resize back to a normal window. Rows, controls and dialogs recover cleanly.

Attach screenshots for any visual defect. The diagnostics log records clipping,
overflow, dialog geometry and focus-loss findings automatically; do not count lines.

## Section 3 — Nested dialogs and focus

- [ ] From the Main Menu open **Load Game**, then open an inner confirmation dialog.
- [ ] The inner dialog is on top and receives keyboard/controller input.
- [ ] Closing it returns to Load Game with usable focus.
- [ ] Nothing flickers, closes unexpectedly or reopens underneath.

## Section 4 — Save, migration and Prep return smoke

- [ ] Manually save into an occupied slot. The replacement picker is understandable,
  and cancelling leaves the existing save untouched.
- [ ] Enter Prep from the campaign map and back out to the same campaign map.
- [ ] Revisit a free-roam node, enter Prep and back out to the node you came from.
- [ ] Import the supplied migration v1 and v2 fixtures and exercise their saves.
- [ ] The free-roam Proving Grounds pack imports and reaches a live map.

The returned diagnostics records are the authority for save/pack identity, refusal
reasons and expected states. Report any player-facing message that does not explain a
failure, but do not transcribe normal log output.

## Section 5 — Proving Grounds campaign playability

Play the campaign on the real Windows build for as much of the campaign as you can,
ideally through completion. Stopping honestly mid-chapter is a valid return; do not
rush to meet a chapter count.

Judge the real-machine experience:

- [ ] Input feels responsive and the camera behaves correctly.
- [ ] The display remains usable during battle and campaign navigation.
- [ ] No crash, impassable wall or progression dead end prevents continuing.
- [ ] Objectives, rewards, campaign advancement and save/resume behave as expected.

This is a playability and correctness pass, not a balance test. Do not report difficulty,
damage curves or pacing judgments as checklist requirements. The diagnostics bundle
records chapters, turns, combat, AI, objectives, rewards, deaths and completion state.

## Section 6 — Return package

- [ ] From Settings, use **Export Diagnostics**, or press **Ctrl+Shift+F12**, to create
  the one-action `Prometheus_diagnostics_<version>_<timestamp>.zip` bundle.
- [ ] Confirm the path shown by the game and return that ZIP.
- [ ] Include screenshots only for visual/input issues or anything the log cannot see.
- [ ] Complete this checklist and identify the sections actually run.

The diagnostics bundle contains the diagnostics and Godot logs, BUILD_INFO, settings,
installed pack manifests (not pack payloads), save-slot documents and its own contents
manifest. The bundle is also written automatically on exit after an error.

## Closeout

An honest partial run is useful. Please say where you stopped and return the bundle even
if one section failed or the game stopped before campaign completion.
