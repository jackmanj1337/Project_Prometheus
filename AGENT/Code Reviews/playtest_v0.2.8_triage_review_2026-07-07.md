# v0.2.8 Playtest Triage - Owner Review Walkthrough - 2026-07-07

Status: OPEN - owner walkthrough pending
Companion: `AGENT/Docs/playtests/playtest_v0.2.8_results_triage_plan_2026-07-07.md`

The good news is narrow: v0.2.8 closes section 1.3 and section 1.4 live. The only
display-gate blocker left is section 1.6 windowed resize behavior.

Format per question: context -> options with drawbacks -> recommendation first.
After owner decisions, record them at the bottom and route them to the fix pass.

---

## Q1. Custom size readout semantics (`V028-02`, section 1.6 FAILED)

The UI currently uses one saved `resolution` string for two different concepts:

- preset values are 16:9 **requests** that may be clamped;
- `Custom (WxH)` values are **observed client sizes** written back after an OS
  resize.

The Settings screen still sends both through the same "requested -> applied"
clamp calculation, so the tester can see confusing output like
`Custom (3840x2071) -> applied 3563x2004`.

- **Option A (recommended): one structured display-size status API.** Keep the
  saved field for now, but have `SettingsManager` expose whether the selected
  value is a preset request or a custom observed client size. Render the label
  from that structure: presets can show `-> applied`, custom values should show
  as the live client size without being clamped again. Update the guide and next
  handbook to define "request", "client size", "native display size", and
  "viewport/canvas size."
  - Drawback: still carries one field with dual semantics internally, but the
    UI stops lying and the diff stays small.
- **Option B: split the data model now.** Store `windowed_resolution_request`,
  `last_windowed_client_size`, and optionally `was_maximized` separately.
  - Drawback: cleaner long-term, but this is a larger settings migration for a
    narrow release-line bug.
- **Option C: only rewrite the explainer.**
  - Drawback: insufficient. The screenshot proves the UI itself is confusing,
    not just the prose.

## Q2. Windows maximize button while Settings is open (`V028-03`, section 1.6 FAILED)

The tester used the window's top-right maximize button while the Settings menu was
open. The panel drifted off-center until another size/scale adjustment caused a
later re-center. Source reading also shows maximize is currently written back as a
custom resolution.

- **Option A (recommended): handle maximize as a window state, not a saved
  resolution.** Re-center menus after maximize with a settled-frame pass, but do
  not save the maximized client size into `resolution`. Preserve the previous
  windowed request/custom size for restore after unmaximize.
  - Drawback: this slightly narrows the owner Q5 full-write-back decision from
    v0.2.7: edge drags still write back; maximize does not.
- **Option B: keep maximize write-back, only add another re-center pass.**
  - Drawback: keeps the awkward `Custom (monitor-ish size) -> applied clamp`
    confusion unless Q1 also special-cases it; relaunch behavior may be odd.
- **Option C: document "don't use maximize."**
  - Drawback: not acceptable for a visible OS control on a release-gate item.

## Q3. Aspect ratio / black-bars policy (`V028-04`, routing request)

The tester asked to revisit changing the full viewport ratio for Steam Deck/mobile
instead of living with black bars. GDD_00 currently says Steam Deck starts
letterboxed and should be revisited once UI scale exists. UI scale now exists.

- **Option A (recommended): route to `UI-VIEWPORT-ASPECT`, do not block the
  section 1.6 fix.** Keep the current 16:9 `stretch/aspect=keep` contract until
  a real platform/UI pass decides whether to expand the logical viewport for
  16:10 / mobile shapes. The decision needs a layout matrix, HUD safe-area
  review, screenshots, and controller/touch implications.
  - Drawback: black bars remain for now.
- **Option B: add 16:10 / custom viewport support in the v0.2.9-style fix pass.**
  - Drawback: too broad for a live display-gate bug. It touches camera framing,
    HUD edge clamps, modal centering, and map readability.
- **Option C: permanently keep letterbox.**
  - Drawback: premature. The project already promised a revisit after UI scale.

---

## Walkthrough Decisions

Pending owner review.
