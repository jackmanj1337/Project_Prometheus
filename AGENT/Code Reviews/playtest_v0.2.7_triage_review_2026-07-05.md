# v0.2.7 Playtest Triage — Owner Review Walkthrough - 2026-07-05

Status: OPEN — awaiting owner walkthrough
Companion: `AGENT/Docs/playtests/playtest_v0.2.7_results_triage_plan_2026-07-05.md`
(diagnosis + evidence per item; this doc holds the problems and the choices).

Unlike the v0.2.6 cycle, **nothing has been built yet** — this return was
diagnosis-only, so even the mechanical items appear here (marked as such) before
any code lands. Q1/Q2/Q4 are mechanical with a clear recommended repair; Q3 needs
a repro decision; Q5–Q7 have real design choice in them.

Format per question: context → options with drawbacks → recommendation first.
Decisions get recorded in a "Walkthrough Decisions" section at the bottom, then
routed into the triage plan / control plane in the same session.

---

## Q1. Action menu drifts over the unit at high zoom (`V027-02`, §1.3 FAILED) — mechanical

`MapCursor._place_menu_near()` offsets the menu from the tile's top-LEFT screen
corner by a gap capped at one UNZOOMED tile (`minf(tile_px, TILE_SIZE) + 4`,
the V025-03 cap). At zoom > 1 the on-screen tile (96–256px) is wider than the
capped 68px offset, so the menu sits progressively deeper inside the unit's tile —
at 4× it covers most of the unit (tester screenshot). The cap fixed the old
"launches a full magnified tile away" bug by breaking the geometry the other way.

- **Option A (recommended): anchor to the tile's far edge + constant gap.**
  `right_x = tile_left + tile_px + 4` / `left_x = tile_left - menu_size.x - 4` —
  the exact model `AttackPreview._reposition_for()` already uses, so both
  per-unit popups share one geometry. V025-03's real intent (the gap BEYOND the
  tile must not scale) is preserved; the tile-width term must scale. Regression
  case in `test_map_cursor.gd` at zoom 4 (menu rect fully clear of the tile rect,
  within gap+ε of its edge).
  - Drawback: at max zoom the menu sits one 256px tile off the anchor corner —
    further right in absolute pixels than today. That is the correct "hugs the
    unit without covering it" placement, but it IS a visible change at every
    zoom > 1, so §1.3 needs the v0.2.8 re-walk either way.
- **Option B: keep the offset from the tile corner but subtract the menu overlap
  dynamically.** Equivalent output to A with more math and no shared model.
  - Drawback: strictly worse than A — rejected unless A shows a problem live.
- **Option C: defer to the UI pass.**
  - Drawback: §1.3 is one of the three items holding `VAL-V023-DISPLAY` open;
    deferring blocks the release-line gate on a diagnosed one-line geometry fix.

## Q2. Combat forecast first-open dead space (`V027-03a`, §1.4 FAILED) — mechanical

On the FIRST `show_preview()` after boot the panel draws with empty tinted space
below the rows; the second open is tight. `_size_panel_to_content()` seeds
`PANEL_DEFAULT_HEIGHT` and lets `PanelContainer` enforce its content minimum —
but RichTextLabel minimums read INFLATED until one layout frame passes (the same
first-show trap the codebase already handles in `MenuScale.apply_to_deferred`,
V025-05a), so the first open freezes an over-tall frame.

- **Option A (recommended): one-frame deferred second pass.** After `show()`,
  `await process_frame`, then re-run `_size_panel_to_content()` +
  `_reposition_for()` (guarded on continued visibility/validity). Established
  in-repo pattern; fixes every future content change too.
  - Drawback: the panel can visibly snap smaller one frame after appearing
    (mitigable with the same hold-transparent-for-a-frame trick apply_to_deferred
    uses); adds an async path to a currently synchronous show.
- **Option B: deterministic measured height.** Sum the per-row measured heights
  (`_measure_forecast_row_height` already exists) + paddings and set the frame
  height exactly; never trust the container minimum on first show.
  - Drawback: hand-maintained layout math — every future row/column addition must
    update the measurement or the bug returns in a new shape; the InfoBox column
    (autowrap description) is awkward to measure by hand.

## Q3. Combat forecast misplaced at the LEFT wall + max zoom (`V027-03b`, §1.4 FAILED) — needs repro

The v0.2.6 right-wall fix (stale-transform flush) held; the tester reports the
same misplacement on the LEFT wall. Source reading does NOT find a left-side
mirror of the old bug — placement prefers the defender's right side, which is
where the room is at the left wall. Real candidates (triage plan has detail):
the pan-camera branch fires across most of the map at max zoom (panel + tile >
half the 1280×720 canvas) and is untested against the left clamp; the avoid-rect
slide is single-pass and can land back on the defender; or a residual one-frame
timing hole (the tester's "zoom past max" heal is a no-op re-place).

- **Option A (recommended): repro-first, plus the cheap self-heal regardless.**
  (1) Extend the durable headless scene suite (test_mrd_scene pattern) with a
  left-wall + max-zoom forecast placement check (panel rect vs defender rect,
  pan-branch coverage both walls); fix what it shows. (2) Independently, add a
  deferred one-frame re-anchor after zoom-driven repositions — the automated
  version of the manual heal, closing any timing residue on BOTH walls.
  - Drawback: (2) can mask a real geometric bug if (1) is skipped or fails to
    reproduce — which is why the order is repro first, self-heal second.
- **Option B: self-heal only.** Smallest diff, ships today.
  - Drawback: if the cause is geometric (candidates 1–2), the panel still lands
    wrong for one frame and "settles" — tester will report jitter, and we'll be
    back here with less trust.
- **Option C: ask the tester for a screenshot/repro before touching code.**
  - Drawback: another round-trip on a gate item; the headless suite can likely
    answer the same question tonight.

## Q4. Settings menu stretches off-screen on windowed 1440p→4K at 2.0× (`V027-04a`, §1.6 FAILED) — mechanical

Once per boot, switching windowed resolution at high Menu Scale left the settings
panel grown off the right edge until a slider wiggle re-applied the scale. NOTHING
re-applies Menu Scale on a window-size change (`size_changed` is connected
nowhere in the codebase), so any post-resize content-minimum change grows the
ScrollContainer frame rightward/downward from its anchored top-left with no
recenter — the V026-01a failure shape, re-triggered by resize instead of slider.

- **Option A (recommended): connect the resize hook.** In SettingsManager, on
  `get_viewport().size_changed` → deferred `_apply_menu_scale()` (idempotent —
  overrides scale off captured bases). One connection self-heals this case and
  every future "layout changed under a live menu" variant; it is also the natural
  home for Q5's readout refresh.
  - Drawback: re-applies scale on EVERY resize event (OS drags fire many) —
    needs the deferred/coalesced call so it's once per settled frame, not per
    event; a tiny cost on desktop, none headless.
- **Option B: re-apply only from the display-apply path** (after
  `_apply_display()` resizes the window).
  - Drawback: covers the dropdown switch but not OS drag-resizes or future
    resize sources; Q5 then needs its own hook anyway — two mechanisms where one
    suffices.
- **Option C: document the wiggle workaround.**
  - Drawback: not serious for a gate item — it fails §1.6 again in v0.2.8.

## Q5. Applied-size readout ignores OS drag-resize (`V027-04b`, §1.6 FAILED) — design choice

The §1.6 handbook explainer promised: drag the window edge → the applied W×H
readout updates and the window re-centres. Neither exists in code:
`applied_windowed_size()` derives from the SAVED request (never reads the actual
window), and there is no `size_changed` handler. The explainer overpromised —
the dropdown-apply recentre got generalised into a drag behaviour that was never
built. Whatever is decided, the handbook §1.6 text must be corrected in the same
change (DoD#1).

- **Option A (recommended): readout tracks reality; the saved request stays a
  request.** `_refresh_applied_size()` reads the live window size in windowed
  mode (`DisplayServer.window_get_size()`), refreshed via the Q4 hook while the
  settings screen is open. No write-back to the `resolution` setting, no
  drag-triggered recentre (re-centring a window the user just placed is hostile).
  Handbook: "the readout shows the window's real current size; the dropdown keeps
  your last request."
  - Drawback: readout and dropdown can disagree after a drag (readout 1800×1013,
    dropdown "2560×1440") — that is honest but needs the one-line explainer.
- **Option B: full write-back (what the handbook promised).** A drag-resize
  updates the saved resolution to the applied size; dropdown gains a
  "Custom W×H" display state.
  - Drawback: mutates the user's chosen setting from a window drag (surprising;
    a maximize-drag would silently overwrite a deliberate 1440p choice);
    dropdown needs custom-entry plumbing; more state to persist and test.
- **Option C: drop the claim, change nothing.** Correct the handbook to "the
  readout shows the clamped result of your last request".
  - Drawback: the tester's expectation was set and is reasonable; a readout that
    ignores the real window stays a recurring confusion generator.

## Q6. Resolution row in Borderless/Fullscreen (`V027-05c`, §1.6 ask) — design choice

Tester: pin the displayed resolution to the display size and gray out or remove
the option outside Windowed mode, to prevent confusion. Today the dropdown stays
enabled and shows the stale windowed request; only the §1.6 explainer says it is
ignored.

- **Option A (recommended): disable + repurpose the readout.** Outside Windowed:
  gray out `OptResolution` (keep it visible, keep the saved request intact
  underneath) and set the applied readout to "native W×H". Re-enable on switching
  back to Windowed with the request preserved.
  - Drawback: a disabled row still occupies space and invites "why can't I click
    this" — mitigated by the native-size readout sitting right next to it.
- **Option B: hide the row entirely outside Windowed.**
  - Drawback: layout shift when toggling window mode; discoverability suffers
    (players hunting "resolution" won't find the row to learn WHY it's absent).
- **Option C: leave as-is (explainer text only).**
  - Drawback: the explainer demonstrably did not prevent the confusion it was
    written to prevent — the ask came WITH the explainer in hand.

## Q7. Routing the §1.1 notes (`V027-01`, `V027-05a`, §1.1 PASSED) — routing choice

§1.1 passed; two notes ride along: (a) the settings frame lands on different
total sizes at 1.75× vs 2.0× — by-design under the V026-01a model (frame =
clamp(max(authored base, scaled content min), viewport)); a constant frame is a
different design, not a bug fix. (b) The tester wants the main menu ("home
screen") exempt from Menu Scale and simply left large — `MainMenu.gd` is an
ordinary `menu_scale_targets` member today. Also: both v0.2.6 §1.1 loose ends
(`V026-01d` truncated sentence, `V026-01e` border flicker) close on this return —
"everything seems fine" and no flicker reported.

- **Option A (recommended): log both to `UI-INSPECTION`, build nothing now.**
  The tester checked the item and said "later" in the same breath; frame-size
  policy and per-menu scale exemptions are exactly what that pass exists to
  decide holistically (it already holds the promotion-picker redesign and the
  paged character sheet).
  - Drawback: the 1.75×↔2.0× size jump stays visible in v0.2.8 — acceptable, the
    item passes with it.
- **Option B: pin the scroll-frame size across factors now** (width fixed to the
  authored base; content scales inside and scrolls).
  - Drawback: at 2.0× rows wider than the fixed frame either re-grow a horizontal
    scrollbar (V026-01b just removed one) or force ellipsis policy decisions —
    that's the UI pass's call, made piecemeal here.
- **Option C: exempt MainMenu from scaling now** (one-line group removal).
  - Drawback: trivially easy but preempts the UI pass's screen-by-screen scale
    policy with an ad-hoc exception; nothing is broken today.

---

## Walkthrough Decisions

_To be recorded during the owner walkthrough._
