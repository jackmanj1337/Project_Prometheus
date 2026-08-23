---
Role: dated
---

# v0.2.8 Playtest Triage - Owner Review Walkthrough - 2026-07-07

Status: DECIDED 2026-07-07 - see Walkthrough Decisions; section 1.6 fix pass scoped
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

Owner walkthrough completed 2026-07-07.

**Q1 -> Option A (one structured display-size status API).** `SettingsManager`
exposes whether the selected value is a preset request or a custom observed
client size; the Settings label renders from that structure. Presets may show
`-> applied` (only when the clamp changes the request); custom OS-resize values
render as the live client size and are NOT re-run through the 16:9 clamp. Update
the settings guide + next handbook to define "preset request", "client size",
"native display size", and "viewport/canvas size". Keep the single saved field
for now (defer the Option B data-model split).

**Q2 -> fix the ROOT CAUSE, not the symptom, PLUS Option A write-back policy.**
Owner asked why the "menu recenters on resize" bug keeps returning. Root-cause
finding (recorded in the triage plan V028-03 and below):

- The recenter is a *one-shot imperative offset-bake*, not a standing layout
  constraint. `MenuScale._recenter()` (`scripts/ui/MenuScale.gd:218-238`) hard-sets
  `target.size` then calls
  `set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_KEEP_SIZE)`, which
  bakes absolute pixel offsets against the panel size *at that instant*. Godot
  computes the panel's real final size in a *later* deferred layout pass, so when
  the final size differs the baked offsets are stale -> off-center until the next
  re-apply ("wiggling").
- This is ONE bug patched per-trigger four times: V025-05a (first show ->
  `apply_to_deferred`), V026-01a (2.0x -> predict size from base+min),
  V027-04a (edge drag -> coalesce `size_changed`), and now V028-03 (maximize,
  whose window-mode change reflows across several frames so the single deferred
  re-apply fires too early again). Each patch chased a trigger; the cause is that
  centering does not track later size changes.

Decision: make centering track the size the engine actually applies.
- **Section 1.6 fix (now):** connect each `menu_scale_targets` panel's own
  `resized` signal to a guarded re-center so centering re-runs at the exact moment
  the engine changes the panel size, for every trigger (first show, scale change,
  edge drag, maximize, content rebuild). Add a re-entrancy guard (skip when size
  is unchanged, same pattern as `SettingsManager.gd:419`) so the `resized` we emit
  does not loop. This lets us retire the frame-timing guesswork
  (`apply_to_deferred` deferral, the coalesced viewport-only hook) once green.
- **Broader UI pass (later, with Q3):** the clean structural form is wrapping
  each centered panel in a `CenterContainer` and deleting imperative `_recenter`
  entirely (engine re-centers to child min every layout pass). Bigger change
  (~11 scenes; scroll-frame panels need `custom_minimum_size`), so it folds into
  `UI-VIEWPORT-ASPECT` rather than the narrow fix.
- **Write-back (orthogonal, Option A):** maximize is a window STATE, not a chosen
  windowed resolution. Stop persisting the maximized client size into `resolution`
  (`SettingsManager.gd:392-396`); preserve the prior windowed request/custom size
  for restore on unmaximize. Edge drags still write back (unchanged from v0.2.7
  Q5). This also removes a feeder of the Q1 readout confusion.

**Q3 -> Option A (route to `UI-VIEWPORT-ASPECT`, do not block section 1.6).**
Keep the 16:9 `stretch/aspect=keep` contract for now. Attach the CenterContainer
centering refactor (Q2 structural form) to this same broader UI pass so the
aspect/layout work and the menu-centering cleanup land together.

### Section 1.6 fix pass scope (next session)

1. `SettingsManager`: structured window-size status (preset-request vs.
   custom-observed) for Q1; stop persisting maximized size + restore-on-unmaximize
   for Q2 write-back.
2. `SettingsScreen`: render the label from the structured status; no re-clamp of
   custom values.
3. `MenuScale`: reactive `resized`-driven re-center with re-entrancy guard; retire
   the deferred/coalesced timing crutches once green.
4. Docs: settings guide + next handbook size-vocabulary definitions.
5. Tests: headless SettingsManager/SettingsScreen label-semantics + write-back
   policy; MenuScale re-center-on-resize. Live Windows maximize check stays in the
   handbook (real OS maximize timing can't be proven headless).
6. Cut a section-1.6-only rerun build; flip `VAL-V023-DISPLAY` only when it passes
   live.
