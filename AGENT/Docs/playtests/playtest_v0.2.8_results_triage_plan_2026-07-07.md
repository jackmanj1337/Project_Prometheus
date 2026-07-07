---
Type: playtest
Status: Returned results - diagnosed 2026-07-07; v0.2.8 closes section 1.3/1.4 but leaves section 1.6 pending
Last verified: 2026-07-07
---

# v0.2.8 Playtest Results Triage And Fix Plan - 2026-07-07

## Scope

Triage for the returned v0.2.8 display-gate rerun. This build only asked the
tester to rerun section 1.3, section 1.4, and section 1.6 after the v0.2.7 fix
pass.

Evidence:

- Returned checklist: `playtest_checklist_v0.2.8_returned_2026-07-07.md`
- Build manifest: `playtest_build_v0.2.8.md` (source commit `ab81a21`, SHA-256
  `850c5f87...`)
- Screenshots and logs in `AGENT/Docs/archive/evidence/`:
  - `settings_windowed_custom_readout_2026-07-07.png`
  - `settings_windowed_custom_4k_clamp_readout_1p75x_2026-07-07.png`
  - `settings_windowed_maximize_recentering_1p75x_2026-07-07.png`
  - `godot_log_v0.2.8_returned_2026-07-07.log`
  - `godot_v0.2.8_session_2026-07-07T02.55.24.log`
  - `godot_v0.2.8_session_2026-07-07T03.10.39.log`
- Tester environment from logs/screenshots: Windows desktop, NVIDIA RTX 5070 Ti,
  OpenGL Compatibility renderer, exe run from `E:/Utilities/ObsidianPortable/`.

## Findings First

1. **The display gate is still pending, but it narrowed to section 1.6 only.**
   Section 1.3 action-menu anchoring and section 1.4 combat forecast placement are
   checked PASS. Section 1.6 remains unchecked with new targeted resize/readout
   reports. `VAL-V023-DISPLAY` stays Pending validation.
2. **The v0.2.7 high-zoom popup fixes held live.** The tester checked the action
   menu and combat forecast items with no added comments, so `V027-02` and
   `V027-03` can be treated as live-validated.
3. **Borderless/fullscreen gray-out held live.** The tester explicitly said
   "borderless and fullscreen work well", so `V027-05c` is validated. The
   remaining issue is Windowed OS-resize behavior.
4. **The custom-size readout mixes two meanings.** Source investigation shows a
   non-preset `Custom (WxH)` value is the actual client size reported by an OS
   resize (`SettingsManager.apply_resize_write_back`, `SettingsManager.gd:403`),
   but the Settings screen still computes the adjacent "applied" label by parsing
   that value as a request and passing it through the 16:9 clamp path
   (`SettingsScreen.gd:407`, `SettingsManager.gd:318`). That is how a screenshot
   can show `Custom (3840x2071) -> applied 3563x2004`: the UI is comparing an
   observed custom size against a clamped request model.
5. **The Windows maximize button is not just an edge drag.** The code currently
   treats both `WINDOW_MODE_WINDOWED` and `WINDOW_MODE_MAXIMIZED` as write-back
   candidates (`SettingsManager.gd:392`). The screenshot shows the Settings panel
   can remain off-center after maximizing until another size/scale adjustment
   triggers a later re-apply. That suggests the one deferred resize re-apply is
   firing before the maximize/layout state has fully settled, and maximizing
   should likely be handled as a distinct window state rather than persisted as a
   custom 16:9 resolution.
6. **The aspect-ratio / black-bars request is real but not a v0.2.8 defect.**
   GDD_00 still says Steam Deck starts letterboxed and should be revisited after
   UI scale exists. Menu Scale now exists, so the revisit should be tracked, but
   it should not block the small section 1.6 fix pass.
7. **Logs are clean for this issue.** The returned logs contain valid v0.2.8 build
   stamps and only the known `SkillHandler` M9 stub warnings for `bastion` /
   `iron_wall`. No crash or DisplayServer warning was captured.

## Workstreams

### V028-01 - Section 1.3 action menu and section 1.4 combat forecast are live-validated

Tester checked both items PASS:

- section 1.3: `playtest_checklist_v0.2.8_returned_2026-07-07.md:138`
- section 1.4: `playtest_checklist_v0.2.8_returned_2026-07-07.md:169`

**Routing:** close the v0.2.7 action-menu anchor and forecast wall-placement
defects as live-validated. No follow-up work.

### V028-02 - Section 1.6 custom-size readout is confusing / not always live

Tester: "the custom WxH readout doesn't seem to be updating live all the time.
Please investigate and include a more detailed explanation about what exactly is
being measured."

**Diagnosis:** There are two size concepts:

- A preset resolution is a **request**. It can be clamped by
  `windowed_client_size_for_screen()` before being applied.
- A `Custom (WxH)` value produced by OS resize write-back is already an
  **observed client size**.

The UI does not distinguish those concepts. `_refresh_applied_size()` parses the
saved `resolution` string into `requested` and calls `applied_windowed_size()`
unconditionally (`SettingsScreen.gd:407-410`). `applied_windowed_size()` always
passes the parsed value through the clamp helper when display config is supported
(`SettingsManager.gd:318-326`). For non-preset values this can invent a second
"applied" size for a value that was already the applied size.

**Fix recommendation:** render a structured window-size status instead of
deriving every label from the saved string. At minimum:

- preset selection: show `preset request -> applied clamp` only when the clamp
  changes the requested size;
- custom OS resize: show the custom value as the live client size and do not run
  it through the 16:9 request clamp;
- settings guide / next handbook: define "preset request", "client size",
  "native display size", and "viewport/canvas size" explicitly.

### V028-03 - Section 1.6 Windows maximize button can leave Settings off-center

Tester: "if you are in a windowed mode and have the settings menu open then use
the windows fullscreen button in the top right corner the menu does the old thing
where the menu does not stay centered but recenters on adjusting the size."

**Diagnosis (source + screenshot inference):** The resize hook queues one deferred
menu-scale reapply on every viewport resize (`SettingsManager.gd:365-377`), and
MenuScale recenters scroll-frame panels during that reapply (`MenuScale.gd:218-238`).
The screenshot still shows the Settings panel off-center after maximize, but a later
manual adjustment recovers it. That points to a timing gap specific to maximize:
the reapply likely runs before the final viewport/window mode layout settles.

The second design problem is that maximize is accepted as a resolution write-back
source (`SettingsManager.gd:392-396`). A maximize button is a window state, not a
chosen windowed client resolution; saving it as `Custom (3840x2071)` creates the
readout confusion in V028-02 and may produce odd relaunch behavior.

**Fix recommendation:** treat maximize separately from edge-drag resize:

- re-center menu-scale targets after maximize with a second settled-frame pass;
- do not persist maximized client size as the saved `resolution`, unless the owner
  explicitly wants "maximized" to become a saved window state;
- cover with a headless-safe unit test around the state decision and a live
  Windows check in the next handbook, because the real OS maximize timing cannot
  be fully proven headless.

### V028-04 - Aspect-ratio / black-bars policy revisit

Tester: "Lets also revisit the idea of being able to change the full viewport
window ratio so that when we ship a steam deck or mobile version we don't have to
deal with black bars."

**Diagnosis:** This is not a regression in v0.2.8. The project intentionally uses
`stretch/aspect=keep` with a 16:9 logical viewport, and GDD_00 says Steam Deck
starts letterboxed with a revisit after UI-scale support exists. That revisit is
now timely, but it is a platform/UI policy decision with broad layout impact.

**Routing:** add `UI-VIEWPORT-ASPECT` as the owner for an aspect expansion /
black-bars decision. Keep the immediate v0.2.9-style fix focused on section 1.6
windowed readout/maximize behavior.

## Sequencing

1. Owner walkthrough of the companion review questions:
   `AGENT/Code Reviews/playtest_v0.2.8_triage_review_2026-07-07.md`.
2. Land the decided section 1.6 fixes on the release line:
   - custom/readout semantics (`V028-02`);
   - maximize recenter/write-back policy (`V028-03`);
   - guide/handbook wording for the measured sizes.
3. Cut a focused rerun build for section 1.6 only.
4. When section 1.6 passes live, flip `VAL-V023-DISPLAY` and proceed to
   `REL-V023-MERGE` / `B6-WEB-DEBUG`.
