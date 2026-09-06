---
Role: dated
Type: playtest
Status: Ready - native return round
Last verified: 2026-09-06
---

# v0.7.17 Windows Tester Checklist

This is the next real-machine pass. The in-container browser gates and stateful
journeys are supplemental evidence already shipped in this bundle; they do not
replace Windows display, GPU, input, window-manager or human-playability evidence.
Please return this checklist, the diagnostics ZIP, and screenshots for anything
that looks wrong.

The build records measurements in its diagnostics. Do not spend time transcribing
normal log lines or counting errors. Judge what only a real Windows machine can
judge, and say exactly where you stopped.

## Section 0 — Start in this order

1. Verify the bundle identity from `BUILD_INFO.json` and `SHA256SUMS.txt`, then launch
   the supplied release executable once. Do not alter the Godot user-data location.
2. Before importing any pack, use a clean profile with no saves and open **Load Game**.
   Confirm that the empty profile is clear and has no misleading selectable save.
3. Still before importing a pack, set Windowed mode and resize below 600 px wide. Open
   Settings and run the compact-layout checks in Section 2.
4. Only after the pack-free checks, import these files through Campaign Library:
   `campaign-packs/free-roam.zip`, `campaign-packs/migration-v1.zip`, and
   `campaign-packs/migration-v2.zip`. Do not unzip or overwrite them.
5. The bundle also contains `tester-fixtures-v0.7.17.zip`. Copy its contents to a
   separate working folder outside the game's user-data directory; never edit the
   supplied fixture files in place.

The diagnostics session header records the build stamp, executable identity, Windows
platform, GPU, displays, window/content-scale configuration, settings, installed
packs, user-data migration state and RNG seed. Do not copy those values into this
checklist.

## Section 1 — Native diagnostics and window evidence

After the run, open the diagnostics ZIP exported in Section 6.

- [ ] The session header opens and contains real screen resolution, DPI, refresh rate
  and scale records.
- [ ] The window record contains the live mode, size, position and content-scale
  configuration.
- [ ] The header identifies the actual v0.7.17 build and installed pack identities.
- [ ] The diagnostics ZIP opens cleanly and contains the logs, settings, pack
  manifests, save-slot documents and contents manifest.
- [ ] Compare the returned diagnostics records with the answers in this checklist;
  note any disagreement rather than copying one over the other.

## Section 2 — Compact Settings and responsive layout

Use the pack-free profile from Section 0 at a window below 600 px wide, then repeat
the important visual checks at a normal window and fullscreen/content scale.

- [ ] Compact Settings rows stack each label above its control; no label is clipped and
  no control leaves the safe viewport.
- [ ] At slider values 0%, 50% and 100%, the trough, fill and both endcaps are visible.
- [ ] Open a popup or confirmation dialog. It is fully visible, positioned correctly
  and remains usable with keyboard/controller input.
- [ ] Resize back to a normal window. Rows, controls and dialogs recover without
  stale clipping, overflow or lost focus.
- [ ] Attach screenshots for any visual defect, especially a clipped label, missing
  slider track/endcap, misplaced dialog or focus loss.

## Section 3 — Phase banner and resumed-load visual pass

This is the native follow-up to the earlier phase-banner finding. The old
`PROMETHEUS_BANNER_TRACE` launcher is not in this build; do not set that variable.
Use the visible behaviour and the diagnostics record instead.

- [ ] Launch `proving_grounds`, enter the first battle, and confirm the phase banner
  spans and centres in the safe viewport rather than only part of the window.
- [ ] Use the in-game Map Menu's **Suspend & Quit**, return to Main Menu, and load the
  saved battle. The banner appears only for its transition, then hides on its own.
- [ ] Switch between Windowed and fullscreen, trigger a phase change, and confirm the
  banner remains correctly sized and centred.
- [ ] Resize during a banner animation. It settles in the correct place.
- [ ] Trigger two phase changes close together. No superseded banner remains visible.
- [ ] Attach screenshots for any banner that persists, clips, shifts off-centre or
  renders at the wrong width. Include the diagnostics ZIP so the resize records can
  be correlated with the screenshot.

## Section 4 — Stateful dialogs, saves and migration

The supplied fixture archive contains `legacy_minimal.json`, migration saves, a
between-map Prep save, a complete v2 campaign backup, and the browser-created
Proving Grounds suspend save.

- [ ] In Load Game, import `legacy_minimal.json` and close the nested changed-save
  confirmation. The dialog is on top, receives input, and closing it restores usable
  focus to Load Game without closing the screen underneath.
- [ ] On an occupied save slot, open the replacement picker, cancel, and verify that
  the original save's visible row and exported bytes remain unchanged.
- [ ] Restore the supplied campaign backup, load its between-map save, enter Prep and
  return to the same campaign map/node. Repeat from a revisited free-roam node if the
  campaign exposes that route.
- [ ] Import the migration v1 and v2 fixtures and exercise their supplied saves. Any
  refusal names the missing content and gives a useful player-facing explanation; no
  raw `migration_*` code is shown by itself.
- [ ] Import `free-roam.zip`, launch `proving_grounds`, use **Suspend & Quit**, reload
  the save, and export it through Load Game. Confirm the exported save is non-empty
  and belongs to `proving_grounds`.
- [ ] Report any crash, save loss, changed save row, wrong campaign/node, unusable
  dialog, or return to the wrong screen with a screenshot and the diagnostics ZIP.

## Section 5 — Proving Grounds campaign playability

Play the supplied Proving Grounds campaign on the native Windows build. A full
playthrough may be attempted. Stopping honestly mid-chapter is a valid return and is
more useful than rushing to a milestone.

- [ ] Input feels responsive and the camera behaves correctly during battle and
  campaign navigation.
- [ ] The drill, rout, seize, defeat-boss, escape and defend nodes are reachable as
  the campaign advances, as far as the run proceeds.
- [ ] Objectives resolve, rewards and progression commit, saves resume at the correct
  campaign/node position, and no crash, impassable wall or progression dead end blocks
  continuation.
- [ ] Report playability and correctness only. Do not report difficulty, damage
  curves, balance or pacing as checklist requirements; balance testing is out of
  scope for this project.

## Section 6 — Return package and closeout

- [ ] From Settings, use **Export Diagnostics**, or press `Ctrl+Shift+F12`, to create
  `Prometheus_diagnostics_<version>_<timestamp>.zip`.
- [ ] Confirm the path shown by the game and return that ZIP, the completed checklist,
  and screenshots for visual/input issues.
- [ ] Include any exported save or migration fixture result that was needed to explain
  a failure. Do not return the whole user-data directory unless the diagnostics export
  fails; the diagnostics ZIP is the intended handoff artifact.
- [ ] State the Windows version, GPU/display setup, sections run, where the session
  stopped, and whether any item was not reproducible.

An honest partial run is useful. The native return is the remaining evidence needed to
move the open visual rows and the v0.7.17 round forward; the bundled Playwright report
cannot close those rows by itself.
