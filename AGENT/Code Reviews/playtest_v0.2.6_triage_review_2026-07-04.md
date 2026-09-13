---
Role: dated
---

# v0.2.6 Playtest Triage — Owner Review Walkthrough - 2026-07-04

Status: RESOLVED — owner walkthrough complete 2026-07-05 (decisions below)
Companion: `AGENT/Docs/playtests/playtest_v0.2.6_results_triage_plan_2026-07-04.md`
(diagnosis + evidence per item; this doc holds only the decisions to debate).

Unlike the v0.2.5 review, the mechanical fixes did NOT wait for this walkthrough —
they landed 2026-07-04 with regression tests (first-apply centering `V026-01a`,
scrollbar margin `V026-01b`, hotseat debug row `V026-01c`, stale-canvas-transform
flush `V026-03/04a`, forecast dash rows `V026-04b`, promotion `follow_focus`
`V026-05c`). The questions below are the items with real design choice in them.

Format per question: context → options with drawbacks → recommendation first.
Decisions get recorded in a "Walkthrough Decisions" section at the bottom, then
routed into the triage plan / control plane in the same session.

---

## Q1. Two open §1.1 loose ends: flicker repro + truncated comment (`V026-01d/e`)

The tester reports the value label "still flickers slightly if you try to hover near
the border" — not reproducible from source reading (drag previews only touch the
label; step changes apply once). Separately, the §1.1 comment ends mid-sentence:
"…moved menu scale from 0.5x to 2x and the same centering issue reoccured and this
time" — the rest never arrived.

- **Option A (recommended): fold both into the v0.2.7 handbook as targeted asks.**
  §1.1's rerun item asks the tester to (a) finish the truncated sentence, (b) try to
  reproduce the flicker and name the exact pointer position + action.
  - Drawback: one more round-trip; but the centering fix likely subsumes the second
    half of the truncated sentence anyway.
- **Option B: chase the flicker now with a synthetic-drag harness.**
  - Drawback: speculative work without a repro; the v0.2.5 history says diagnosis
    from evidence beats diagnosis from guessing.

## Q2. Character-sheet Back button via directional keys (`V026-02e`)

`UnitDetailsScreen._input` consumes all four cursor directions for the More-Info
highlight (deliberately — same pattern as ActionMenu), so GUI focus nav can never
reach `BtnBack`. Back IS reachable via cancel (X/Esc/right-click), but the tester
expects the selector to walk to it. The pair-jump button had the same problem and
got a dedicated key (`next_unit`/`prev_unit`).

- **Option A (recommended): make Back a terminal entry in the selection cycle.**
  Cursor-down past the last stat row (and cycle wrap) lands on Back; confirm
  activates it. One interaction model (the highlight cycle) owns the whole screen.
  - Drawback: touches the `_entries` grid plumbing (Back is not a More-Info entry;
    needs a pseudo-entry or a "focus zone" concept); slightly more code than B.
- **Option B: dedicated key hint** ("Back: X / Esc") rendered next to the button,
  no navigation change.
  - Drawback: doesn't give the tester what they asked for; the button stays a
    mouse-only control with a keyboard *alternative*, not keyboard *access*.
- **Option C: defer to `B6-INPUT` selector extraction / `UI-INSPECTION`.** The shared
  selector-focus model will have to answer exactly this question for every screen.
  - Drawback: the sheet keeps an acknowledged keyboard gap for another build cycle.

If the auto-scroll ask (`V026-02d`, route to UI pass) gets pulled forward, A and it
should land together — both are "the selection cycle drives the viewport" features.

## Q3. Portable log strategy after the `._sc_` failure (`V026-08`)

The v0.2.6 build shipped a `._sc_` marker claiming the log would land next to the
exe. The returned build stamp proves it didn't: Godot's self-contained mode is an
editor/tools feature and exported projects ignore the marker. Meanwhile the actual
outcome succeeded — the stamp's `log=` line pointed the tester at the `%APPDATA%`
path and the log came back for the first time in four builds.

- **Option A (recommended): drop the marker; make `%APPDATA%` the documented
  primary.** Remove the `._sc_` step + claim from `prepare_build.sh` and the build
  manifest template; the handbook §3.2 gives the exact `%APPDATA%` path up front and
  says "the BUILD STAMP's `log=` line is authoritative".
  - Drawback: the log stays two directory levels away from the exe; testers must
    paste a path. Evidence says they can — this is the flow that finally worked.
- **Option B: best-effort log mirror next to the exe.** At quit (and per-launch
  start), Boot copies `user://logs/godot.log` to `OS.get_executable_path()`'s dir
  when writable.
  - Drawback: silently does nothing in unwritable locations (Program Files),
    recreating a "the doc says X but the folder shows nothing" support case; a
    crash skips the at-quit copy exactly when the log matters most.
- **Option C: `application/config/use_custom_user_dir`.**
  - Drawback: renames the `%APPDATA%` subfolder, still not next to the exe;
    breaks continuity with existing tester save/settings state for zero gain.

## Q4. Promotion picker sizing: one whole class per frame (`V026-05a-ask`)

At 2.0x the picker fits and scrolls (v0.2.6 fix held), but roughly one class option
fits the frame and the tester wants to see a full class entry at once — and asked
whether that's deferred to the UI pass.

- **Option A (recommended): cheap bound now, redesign stays with `UI-INSPECTION`.**
  Raise the authored panel width/height caps so at 2.0x the frame shows at least one
  full option (the follow-focus fix already keeps the focused one in view).
  - Drawback: tuning by hand against one screen size; the real fix is the picker
    redesign (class list left / details right) already routed to `UI-INSPECTION`
    from v0.2.5 Q10.
- **Option B: pull the picker redesign forward now.**
  - Drawback: real design+build work on a surface the UI pass will restyle anyway;
    v0.2.5 Q10 already decided against this once.

## Q5. Recoverable auto-promotion: a non-turn-ending "Promote" action (`V026-05b-ask`)

With auto-promote on, dismissing the picker means waiting for the NEXT level-up (more
EXP) to see it again. The tester asks for a free action on max-level units that
re-opens the picker.

- **Option A (recommended): design it as an action-menu entry gated by
  `promotion_available`-style state, but LAND it with the action/menu registry work**
  (`B2-ACTION-EFFECT` / `[SAC]` family) rather than hardcoding a new ActionMenu row
  now. Record the requirement where the action vocabulary is being designed.
  - Drawback: the tester waits; but a hardcoded row is exactly the closed-switch
    smell the architecture principle bans, and Equip already shows what a free
    (non-turn-ending) action looks like when the registry can express it.
- **Option B: hardcode a "Promote" row in ActionMenu now** (visible when unit is
  max-level + auto-promote on + promotion targets exist).
  - Drawback: engine edit per content addition; third bespoke row special-case in
    ActionMenu; will be re-done under the registry anyway.
- **Option C: don't add an action; make dismissal harder** (confirm prompt on
  cancel).
  - Drawback: friction for the common case to protect the rare one; testers grind
    EXP anyway on Map 950.

## Q6. Victory screen must stack under pending level-ups/promotions (`V026-05d-ask`)

The tester notes victory screens should always sit at the bottom of the notification
stack so queued level-ups and promotions resolve before the battle ends. Today the
end-of-battle flow can present over (or instead of) pending progression modals —
progression earned on the killing blow can be swallowed by the victory transition.

- **Option A (recommended): sequence, don't restack — victory presentation waits for
  the progression queue to drain.** The level-up/promotion queue already has
  started/finished signals (`level_up_started`/`finished`,
  `promotion_started`/`finished`); the victory/GameOver presenter subscribes and
  defers until the queue is empty, same pattern PromotionScreen already uses to wait
  out LevelUpScreen.
  - Drawback: needs a careful look at TurnManager's map-over path so input stays
    locked during the deferral; a test must cover "kill boss → level up → promote →
    THEN victory".
- **Option B: literal z-order restack** (victory screen below modal layers).
  - Drawback: two interactive modals alive at once — input routing ambiguity, and
    the victory screen peeking from underneath is exactly the confusion the
    ordering is meant to remove.

Route: this is real sequencing work — file it as its own small slice on the
control plane (it is not a display-gate item; it should NOT block `VAL-V023-DISPLAY`).

## Q7. Handbook explainer: resolutions, window modes, OS resizing (`V026-06-ask`)

§1.6 passed; the tester wants the next checklist to explain what the resolution
options actually do and how OS window resizing interacts.

- **Option A (recommended): lift a half-page digest from
  `display_and_settings_guide.md` into the v0.2.7 handbook's §1.6 preamble** (request
  → clamp → applied readout; windowed vs borderless vs fullscreen; OS drag-resize
  writes back the applied size).
  - Drawback: none meaningful — the guide exists (v0.2.5 Workstream F); this is a
    copy-edit at build-cut time.
- **Option B: link the guide from the handbook.**
  - Drawback: violates the handbook's "everything needed is in this one file" rule.

---

## Walkthrough Decisions

Owner walkthrough 2026-07-05. Six of seven took the recommended option; Q2 chose
Option C (defer, not the recommended A).

| Q | Decision | Routed to |
|---|---|---|
| Q1 | **A** — fold both loose ends into the v0.2.7 handbook: §1.1 rerun asks the tester to (a) finish the truncated sentence and (b) reproduce the flicker with exact pointer position + action. No speculative harness. | v0.2.7 playtest checklist §1.1 rerun items |
| Q2 | **C** — defer Back-button keyboard access to the shared `B6-INPUT` selector-focus extraction / `UI-INSPECTION`; do NOT special-case the sheet now. Sheet keeps an acknowledged keyboard gap (Back still reachable via X/Esc/right-click) for one build cycle. | `B6-INPUT` / `UI-INSPECTION` control-plane row (record the requirement) |
| Q3 | **A** — drop the `._sc_` marker + its claim from `prepare_build.sh` and the build manifest template; handbook §3.2 documents the exact `%APPDATA%` path as primary and names the BUILD STAMP `log=` line authoritative. | `prepare_build.sh`, build manifest template, handbook §3.2 |
| Q4 | **A** — raise authored promotion-picker width/height caps so at 2.0x the frame shows ≥1 full class option; the picker redesign stays routed to `UI-INSPECTION` (from v0.2.5 Q10). | v0.2.7 fix pass (cheap cap) + `UI-INSPECTION` for redesign |
| Q5 | **A** — spec the recoverable-promotion re-open as an action-menu entry gated by `promotion_available`-style state, but LAND it with the action/effect registry work (`B2-ACTION-EFFECT` / `[SAC]`), not a hardcoded ActionMenu row. | `B2-ACTION-EFFECT` / `[SAC]` requirement note |
| Q6 | **A** — victory/GameOver presentation waits for the level-up/promotion queue to drain (subscribe to `level_up_started/finished` + `promotion_started/finished`), not a z-order restack. Its own small control-plane slice; does NOT block `VAL-V023-DISPLAY`. | New control-plane slice (victory-waits-for-progression); test covers kill boss → level up → promote → THEN victory |
| Q7 | **A** — lift a half-page digest from `display_and_settings_guide.md` into the v0.2.7 handbook §1.6 preamble (request→clamp→applied readout; windowed/borderless/fullscreen; OS drag-resize writes back). | v0.2.7 handbook §1.6 |
