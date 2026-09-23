---
Role: dated
Type: playtest
Status: Candidate preparation
Last verified: 2026-09-23
---

# v0.8.2 Tester Candidate

v0.8.2 replaces the rejected v0.8.1 candidate. It carries the same authored
interaction content and fixtures, plus two focused corrections:

- the attack forecast gives authored relationship columns enough room for the
  Chapter 3 two-row case and paints transient interaction UI above the persistent
  terrain HUD;
- More Info explains an intentional suppression using the suppressed
  relationship's player-facing label, without exposing authoring ids.

- Source branch: `agent/from-integration/v082-tester-bundle`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.

The replacement remains a native-test candidate, not an accepted release.
Windows display, GPU, DPI, controller, window-manager and diagnostics evidence
remain mandatory.
