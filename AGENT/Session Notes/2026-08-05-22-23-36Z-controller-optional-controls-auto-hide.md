# Session Note - 2026-08-05-22-23-36Z

## Branch context

- Branch: `agent/from-integration/mobile-controller-web-wiring`
- Base branch: `agent/integration`
- Base SHA: `d61de613`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`

## What was done

**Slice 4 step 4 — optional-control toggles and auto-hide**, the next bounded
action named by the previous session and by
`AGENT/Docs/plans/mobile_web_controller_remaining_slices_handoff_2026-08-05.md`.
Steps 1–3 (persistence, the Control Style / Arrangement rows, and the drag /
scale / opacity editor) were already built; this finishes the submenu's
element-level work.

Both halves of this step exist to give a small screen back to the game, and both
carry the same failure if trusted blindly: **a control the player cannot see is a
control they cannot use to undo whatever hid it.** Every design decision below
follows from that.

### Optional controls

- A saved element carries `enabled`, defaulting to true — which is what every
  layout written before the field existed says, so a returning player does not
  lose controls on upgrade.
- A descriptor may declare itself `required`. That set is exactly the directional
  cross, Confirm and Back, on both profiles: they are what reaches and works the
  Settings screen the toggle lives on.
- The rule is enforced **twice on purpose**. `set_element_enabled()` refuses, which
  stops the player; `build_payload_for()` draws a required control even when the
  saved layout says otherwise, which stops a hand-edited or corrupt cfg, where
  there is no UI to refuse. Reverting the second one fails exactly one assertion,
  and it is the one that matters.
- Toggling inherits the step-3 materialization rule: the first edit freezes the
  whole placement, or hiding Zoom would take every other control with it.

### The control picker

A hidden control cannot be tapped, so the tap-to-select path that arms every other
editor row cannot reach it. The Settings screen therefore lists **every** control
the profile can draw, hidden ones marked, and selecting from that list is what
arms the size, opacity and visibility rows. Without it, turning a control off
would be irreversible short of resetting the whole arrangement. A required
control's visibility row is shown inert rather than hidden — the question "why can
I not turn this one off?" is answered instead of avoided.

The picker is repopulated only when its contents would read differently, compared
by signature. Rebuilding it on every published layout (which includes every slider
tick) would close the dropdown under the player's finger — the same trap the
arrangement list is already split out to avoid.

### Auto-hide

The delay is a setting; the countdown is in the shell, because only the browser
sees the touches that keep the controls awake — a tap that lands on a control never
reaches Godot as an input event at all.

- `controller_auto_hide_seconds` is a `SettingsManager` key, deliberately OUTSIDE
  the saved layout: position, size and visibility describe one arrangement, while
  this describes how long any arrangement lingers, and per-slot it would have to be
  set six times to mean anything. Vocabulary `0|3|5|10|30`, default `0` (never), so
  the feature is inert for anyone who does not go looking for it. A stored value
  the menu cannot offer snaps to one it can, rather than clamping.
- A faded control goes fully transparent **and inert together**, so the tap that
  brings it back reaches the game instead of firing whichever control it landed on.
  Fading while leaving them live would be the invisible dead zone the opacity floor
  already exists to prevent, only worse — the player cannot see what they are hitting.
- **Nothing fades while a control is held.** The vanishing control would take its
  pointer-up with it and strand the action down, which is the stuck input this whole
  service exists to prevent. `hideNow()` reschedules instead.
- The editor is exempt: a control that has faded away cannot be dragged.
- Retiming travels on its own signal (`auto_hide_changed` → `PrometheusController
  .autoHide()`), the third split from `layout_changed` and for the third time for
  the same reason — a republished layout rebuilds every control and drops what is held.

### One thing deliberately NOT done

`press()` is not gated on `enabled`. Hiding a control is a presentation choice, and
every hideable control fires an action its profile already exposes, so refusing the
press buys no authorisation the registry allow-list does not already give — while
adding a second rule that could drift from the payload filter's, and a rule that
disagreed would turn a visible control into a dead one.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

One substantive commit (`93a0462a`) carrying the model, service, shell, bridge,
Settings rows, tests, GDD_07 and two doc guards.

## Gates

- `bash run_tests.sh` — all suites green. `test_controller_service` 126 → 145,
  `test_controller_layout` 13 → 15, `test_settings_manager` 40 → 41,
  `test_settings_screen` 35 → 36.
- `NODE_PATH=/opt/prometheus-web-harness/node_modules node
  tools/web/controller_shell.test.mjs` — 45 → 57 assertions, 0 fail.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 301 files.
- `python3 AGENT/Docs/check_docs.py` — PASS, 49 checks. Guard `[49]` fixes the
  auto-hide vocabulary; guard `[45]` (navigability) now also requires every
  descriptor carrying `cursor_*`, `confirm` or `cancel` to be `required`, because
  a profile that keeps its d-pad and loses Confirm reaches the same dead end by a
  longer road. **Both verified from both sides** — dropping `required` from
  `act_confirm` and changing one delay each fail their own guard and nothing else.
- Two implementation guards were also verified by reversion: removing the
  `pointerBusy()` check fails only "the delay does not expire under a held
  control", and removing the `required` exemption from the payload filter fails
  only "a saved layout that hides a required control is overruled, not obeyed".

### Browser evidence

Against a **real v0.7.0 web export**, served locally and driven on an emulated
Pixel 7 in landscape (`?test_bridge=1`), entirely through the on-screen controls —
no keyboard, no direct DOM calls except to read state:

- 11 assertions on the optional-control half. Stepping reaches the new Control
  row; the picker chooses Zoom In through a real Godot **popup** (which is a
  separate window, so this is also proof the injected events reach one); the Show
  Control row becomes focusable only once something is selected, exactly as
  intended, and is absent from the focus walk before that; turning it off removes
  that control and only that control, leaving every control that reaches this
  screen. **Then the page is RELOADED and Zoom In is still gone, with every other
  control back** — shell → bridge → service → `SettingsManager` → `user://` →
  restore, the one assertion nothing headless can make.
- 14 assertions on auto-hide. A delay is chosen through the same popup path and
  the shell is retimed over the bridge without a rebuild; Back still closes
  Settings with the delay armed; the controls fade after the delay; a faded
  control is `opacity: 0`, hit-tests to the **canvas** rather than to itself, and
  is still in the DOM (faded, not rebuilt away); one tap anywhere brings them back
  and they take touches again; and **nothing fades while a control is held** —
  held past the delay it stays up, and fades once the finger lifts.

The first probe run died mid-way with Playwright reporting "canvas intercepts
pointer events" on a control tap. That was **the feature working**: the probe had
just armed a 3-second delay and then paused longer than that before tapping, so
the control was correctly inert. A player wakes the controls with one tap first,
and so does the probe now. Worth knowing before writing the next one: with
auto-hide on, any automated walk has to wake before every tap or it will look like
a broken control.

No page errors in either run.

## Next

**Slice 3's viewport drag editor**, which the plan sequences after the control
editor so it inherits its guides and snapping. Also still open from the plan's §6
list: global opacity and scale (the model carries `global_opacity` and nothing
edits it), theme selection and haptics (Slice 5), and combination
save/rename/delete.

The probe described above is still NOT checked in — it needs an export plus a
served build, and folding it into `scripts/playwright-drive.sh` belongs with Slice
6's matrix work. Note for whoever does: the container's
`tools/playwright/lib/` now carries `controller.mjs` with `readController()` and
`tapControl()`, so a probe no longer has to hand-roll DOM access, and the test
bridge needs `?test_bridge=1` on the URL or it publishes nothing.

Portrait is still not laid out for portrait (`SMALL-SCREEN-UI-REDESIGN-2026-08-05`),
which is why the browser pass runs in landscape. Branch is unmerged; no PR opened.
