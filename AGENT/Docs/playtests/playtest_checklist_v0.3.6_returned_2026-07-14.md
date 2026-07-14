---
Type: playtest
Status: Returned - owner-accepted pass with UI polish deferred
Last verified: 2026-07-14
---

# Playtester Handbook and Checklist - v0.3.6 Returned

The focused Windows return marked every Action Menu and focus-scrolling
behavior check as passed and selected an overall PASS. The tester accepted both
surfaces for now and asked that they be reviewed again during the broader UI
redesign pass.

## Action Menu result

- [x] Labels clear both ornate arrows.
- [x] Long and short menus shrink-wrap in both dimensions and resize correctly
  when reopened in either order.
- [x] Edge flipping and clamping hold for the tested variants.
- Tester disposition: good enough for now; revisit during the UI redesign pass.

## Focus-scrolling result

- [x] Focus no longer jumps to an unrelated endpoint or scrolls opposite to
  focus travel.
- [x] Mixed-height rows retain bounded lookahead where space permits.
- [x] Endpoint clamps, reachability, horizontal overflow, and Unit Details
  traversal passed.
- Tester disposition: good enough for now; revisit during the UI redesign pass.

## Evidence qualification

The returned checklist did not include input/Windows/monitor metadata, build
hash or BUILD STAMP confirmation, `godot.log`, or the requested screenshots.
This is therefore an owner-accepted live pass, not a complete evidence package.
No failed behavior box or reproduction was returned.

## Disposition

PASS for the v0.3.6 focused gate. Carry a visual-quality recheck of Action Menu
ornament spacing/shrink-wrap and Settings focus-scroll context in the existing
`UI-INSPECTION` redesign pass.
