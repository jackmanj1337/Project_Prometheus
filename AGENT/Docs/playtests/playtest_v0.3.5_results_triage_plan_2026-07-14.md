---
Type: playtest
Status: v0.3.6 live pass accepted - visual polish deferred
Last verified: 2026-07-14
---

# v0.3.5 Playtest Results and Root-Cause Triage

## Outcome

The stamped build and log are valid and contain no related runtime error. The
Action Menu and Settings sections both failed live validation. The returned
checklist is [`playtest_checklist_v0.3.5_returned_2026-07-14.md`](playtest_checklist_v0.3.5_returned_2026-07-14.md).

## Root causes and repairs

### Action Menu shrink-wrap and ornament clearance

`ActionMenu._fit_width_to_visible_labels()` forced only the rendered width.
Because a free-standing `PanelContainer` does not shrink merely when its minimum
falls, the previous rendered height survived a shorter visible action list. The
generic StyleBox minimum also describes the control rectangle, not the narrower
safe region between the button texture's inward-pointing ornaments.

The repair resets both rendered dimensions from the current visible content and
reserves a font-scale-aware safe margin on both sides of every label. Coverage
now asserts rendered height shrinkage and ornament-safe text width at every
supported Menu Scale.

### Settings endpoint jumps

`ModalScreen._visual_scroll_row()` climbed through Settings' MarginContainer and
returned the entire VBox document instead of the focused row. Lookahead therefore
measured the full document height and clamped each correction to an endpoint.
Held navigation could also leave multiple deferred corrections alive.

The repair stops at the focused control's visual VBox row, coalesces deferred
requests, ignores stale focus owners, and changes lookahead from unconditional
recentering to a bounded reveal only when requested context lies outside the
viewport. Coverage traverses Settings in both directions and requires monotonic,
viewport-bounded corrections.

## v0.3.6 live gate - accepted

The returned v0.3.6 checklist passed every behavior box for Action Menu
long/short transitions and bidirectional Settings/Unit Details traversal. The
owner accepted both surfaces for now and explicitly requested a recheck during
the broader UI pass. The return omitted its requested metadata, log, and eight
screenshots, so it closes this focused behavior gate without claiming a complete
evidence package. See
[`playtest_checklist_v0.3.6_returned_2026-07-14.md`](playtest_checklist_v0.3.6_returned_2026-07-14.md).

Action Menu ornament spacing/shrink-wrap and Settings focus-scroll context now
remain as visual-quality review items under `UI-INSPECTION`; they are not open
v0.3.6 correctness defects.
