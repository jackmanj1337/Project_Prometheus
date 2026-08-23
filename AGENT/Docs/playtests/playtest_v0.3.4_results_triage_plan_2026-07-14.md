---
Role: dated
Type: playtest
Status: Repairs implemented - pending v0.3.5 live validation
Last verified: 2026-07-14
---

# v0.3.4 Playtest Results and Root-Cause Triage

## Outcome and evidence

The returned checklist is preserved as
[`playtest_checklist_v0.3.4_returned_2026-07-14.md`](playtest_checklist_v0.3.4_returned_2026-07-14.md).
Four Action Menu screenshots are preserved in `AGENT/Docs/archive/evidence/`.
No `godot.log`, platform/controller metadata, Settings/Unit Details screenshots,
or hash confirmation were returned.

| Finding | Result | Disposition |
|---|---|---|
| LT/RT threshold and cadence | Pass | Do not reopen in v0.3.5 |
| Per-faction threat views | Pass | Do not reopen in v0.3.5 |
| `V034-UI-01` Action Menu stale width | Fail | Repaired; focused live rerun |
| `V034-UI-02` focus-scroll end jumping | Fail | Repaired; focused live rerun |

## `V034-UI-01` - stale rendered Action Menu width

The returned 1x and 2x image pairs show that labels fit, but a short `Equip` /
`Wait` menu retains the panel width of the preceding longer action list.
`ActionMenu._fit_width_to_visible_labels()` reduced `custom_minimum_size.x`, which
is only a lower bound and does not shrink an already-expanded free-standing
Control. MapCursor then measured and placed that stale rendered size.

The repair assigns the computed content width to both the minimum and actual
Control width before placement. Regression coverage now performs a long-label to
short-label transition at 2x and asserts that rendered `size.x` shrinks.

## `V034-UI-02` - competing focus-scroll corrections

The tester reported that continuous movement in one direction immediately threw
the Settings scrollbar between opposite ends. Settings and Unit Details enabled
`ScrollContainer.follow_focus` while `ModalScreen` also applied custom lookahead.
The custom path read global rectangles before the engine's focus scroll settled,
used accumulated relative corrections, and always measured following rows even
when travelling upward. The two owners could therefore counteract each other.

The repair makes custom lookahead the sole scroll owner on those two screens,
waits for layout, computes one absolute content-coordinate target, and measures
context in the direction of travel. Settings coverage traverses the complete 2x
focus list and asserts monotonic downward scrolling.

## v0.3.5 live gate

The rerun is intentionally limited to the two repaired UI paths. It must prove
long-to-short Action Menu resizing at 1x and 2x and bidirectional Settings/Unit
Details traversal at 0.5x, 1x, and 2x. The v0.3.4 trigger and threat-view passes
are accepted and need not be repeated.
