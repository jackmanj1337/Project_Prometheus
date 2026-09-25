---
Role: dated
Type: playtest
Status: Candidate preparation
Last verified: 2026-09-25
---

# v0.8.6 Tester Candidate

v0.8.6 replaces v0.8.5, which was withdrawn before native testing. The agent
browser walk of v0.8.5 (`evidence/v0.8.5/agent-walk/agent-walk-report.md`, corrected
2026-09-25) failed three live-map cases at 2×: 1280×720, 900×760 and 560×900.
v0.8.6 carries everything in v0.8.5, plus:

- **Viewport Scale is limited by the window.** The factor applied to the window is
  capped so the logical canvas stays at or above 640×360, snapped down to the
  slider's 0.5 step. The player's choice is kept, and Settings shows `2x (1x)`
  while the window is deciding. At 900×760 and 560×900, 2× had produced 450×380
  and 280×450 canvases, and on the Main Menu the Settings button went off-screen,
  so the player could not undo the change.
- **Live-map panels resolve overlaps.** On a short canvas (640×360) the Objectives
  box collapses to its title while it would cover the unit or terrain panel. On a
  narrow canvas (560×900) the unit panel stacks above the terrain panel. The HUD
  readability suite now fails on any panel-to-panel overlap.
- **Checklist corrections from the walk.** 1B turns Auto-End Turn off, because
  Hallowed Bearer is BLUE's only unit and the attack otherwise ends BLUE's phase
  before `(2 phases)` can be seen. It also warns that the pixel font's `1` looks
  like `I`. Section 3 sets 1.0× explicitly for 900×760, and Section 2 names
  **Edit a Copy…** as the way to get a working copy.

- Source branch: `agent/from-integration/v086-candidate-cut`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Tracker rows: `V086-SCALE-FLOOR-HUD-2026-09-25`, `V086-CANDIDATE-CUT-2026-09-25`.

This is a native-test candidate, not an accepted release. Windows display, GPU,
DPI, controller, window-manager, campaign-editor and human playability evidence
remain mandatory. The Playwright gates cover web-visible surfaces only.
