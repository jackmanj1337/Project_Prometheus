---
Role: dated
Type: playtest
Status: Candidate preparation
Last verified: 2026-09-24
---

# v0.8.3 Tester Candidate

v0.8.3 replaces the rejected v0.8.2 candidate, which itself replaced the rejected
v0.8.1. It carries the same authored interaction content and fixtures, v0.8.2's
two forecast fixes, and one more correction:

- below about 1000 px of usable width the attack forecast reflows its columns —
  attacker | defender with More Info below, then all three stacked — instead of
  running off the right edge of the screen. Columns keep their width, so the
  relationship rows stay on one line.

- Source branch: `agent/from-integration/v083-tester-bundle`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.

The replacement remains a native-test candidate, not an accepted release.
Windows display, GPU, DPI, controller, window-manager and diagnostics evidence
remain mandatory.
