---
Role: dated
Type: playtest
Status: Returned - UI regressions reproduced
Last verified: 2026-07-14
---

# Playtester Handbook and Checklist - v0.3.5 Returned

The focused Windows return used the stamped `v0.3.5` build at commit `47e29e4`.
Four Action Menu screenshots and `godot.log` are preserved under
`AGENT/Docs/archive/evidence/`. Platform/controller metadata, scrolling
screenshots, hash confirmation, and an overall result were not returned.

## Action Menu result

- Labels still enter the ornate decorations at 2.0x.
- The rendered panel retains excessive height after its visible rows shrink.
- Tester note: "The menu now seems to be clamped at its max height, and at 2x
  size some of the larger items still overlap the decorations."

## Focus scrolling result

- [x] Continuous travel no longer oscillates between opposite ends.
- Settings still jumps directly toward the bottom or top; Unit Details is fine.
- The remaining context, clamp, overflow, and reachability boxes were not passed.
- Tester note: "The menu jumps to the bottom when scrolling down and jumps to
  the top when scrolling up, but it doesn't swap back and forth. Unit details
  are fine."

## Disposition

FAIL. Both UI validation findings remain open for a v0.3.6 focused rerun.
