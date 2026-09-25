---
Role: dated
Type: playtest
Status: Candidate preparation
Last verified: 2026-09-25
---

# v0.8.5 Tester Candidate

v0.8.5 replaces the rejected v0.8.4 candidate. Its web pre-pass found overlapping
Objectives and unit-panel text on a live map with `free-roam.zip` active. v0.8.5
carries everything in v0.8.4, plus:

- **Live-map HUD with a campaign font.** HUD rows are spaced for the active face's
  ink height, so a pack font with a tall overhang no longer overlaps itself.
  A headless live GameMap regression covers eight size and scale cases, plus the
  no-pack HUD.
- **Isolated Chapter 6 duration fixture.** `interaction-duration-backup.zip`
  restores a Chapter 6 battle with only Hallowed Bearer and one Revenant, and the
  Revenant waits on its turn. The release build can then show Hallowed Sear
  counting down under the normal AI, which v0.8.3 only showed with the debug
  hotseat override.
- **Populated Load Game coverage.** A headless layout check covers grouped saves,
  multi-line labels and the recovery controls. The checklist adds a native
  screenshot of a Load Game list with saves in it.

- Source branch: `agent/from-integration/v085-candidate-cut`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.

This is a native-test candidate, not an accepted release. Windows display, GPU,
DPI, controller, window-manager, campaign-editor and human playability evidence
remain mandatory. The Playwright gates cover web-visible surfaces only.
