---
Type: playtest
Status: Repairs implemented - pending v0.3.6 live validation
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

## v0.3.6 live gate

Repeat Action Menu long-to-short transitions at 1.0x and 2.0x, then traverse
Settings and Unit Details bidirectionally at 0.5x, 1.0x, and 2.0x. Close the UI
findings only after the complete checklist and requested screenshots return.
