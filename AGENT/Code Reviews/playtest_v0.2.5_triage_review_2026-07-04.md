---
Role: dated
---

# v0.2.5 Playtest Triage — Owner Review Walkthrough - 2026-07-04

Status: RESOLVED — Q1-Q14 walked with the owner 2026-07-04; decisions recorded below
Companion: `AGENT/Docs/playtests/playtest_v0.2.5_results_triage_plan_2026-07-04.md`
(diagnosis + evidence per item; this doc holds only the decisions to debate).

Format per question: context → options with drawbacks → recommendation. Recommendation
first in the option list. Decisions get recorded in a "Walkthrough Decisions" section at
the bottom, then routed into the triage plan / control plane in the same session.

---

## Q1. Menu Scale slider flicker (`V025-01a`): apply-on-release vs frozen track?

The live re-scale changes the slider track's own geometry mid-drag, so the same mouse
pixel maps to a different value and the value oscillates between adjacent steps.

- **Option A (recommended): apply the scale on `drag_ended` only.** During the drag the
  row label previews the target factor ("1.5x") but the re-scale fires once on release.
  - Drawback: loses the live whole-screen preview mid-drag (you see the result a beat
    later). Keyboard/step changes can stay live since no drag geometry is in play.
- **Option B: keep live apply, freeze the slider geometry during a drag.** Capture the
  track rect at `drag_started`, force the control column to keep that rect until
  release.
  - Drawback: this is the third patch on the same live-preview mechanism (x-lock in
    v0.2.4, y-anchor in v0.2.5, now track-freeze); each fix has revealed the next axis.
    More moving parts to keep correct under future Settings layout changes.
- **Option C: replace the slider with discrete +/- stepper buttons for Menu Scale.**
  Buttons don't care about geometry under the cursor.
  - Drawback: UI inconsistency with the other sliders; loses drag-to-scrub.

History says B's class of fix keeps leaking; A is one line of behavior with an obvious
mental model ("release to apply").

## Q2. Settings horizontal overflow (`V025-01b`): wrap policy at high scales

At 1.5-2.0x the label+control+value row minimums exceed the panel and summon a
horizontal scrollbar.

- **Option A (recommended): disable horizontal scroll; let rows adapt.** Value labels
  ellipsize/autowrap; the keybind list becomes two-line (action name above, binding
  below) when the factor is >= a threshold.
  - Drawback: layout code gets a scale-conditional branch; two-line rows make the panel
    taller (it already scrolls vertically, so acceptable).
- **Option B: shrink the Settings panel's content to always fit one line** (tighter
  paddings, shorter labels).
  - Drawback: fights localization and future settings; you re-tune every addition.
- **Option C: cap Menu Scale's effect on the Settings screen itself** (Settings renders
  at min(factor, 1.25x), everything else at full factor).
  - Drawback: the screen where you *set* the scale no longer previews it truthfully —
    directly contradicts the live-preview intent.

## Q3. Character sheet stats More-Info redesign (`V025-02c`): adopt the tester layout?

Tester ask: one More-Info section for stats with the numbers at the top and prose at the
bottom, full page height, so short descriptions don't shrink the box.

- **Option A (recommended): adopt now, as a layout-only change.** Fixed full-height side
  panel: stat table (top, fixed), prose scroll (bottom, fills the rest). No content
  model change.
  - Drawback: touches the sheet layout again before the eventual `UI-INSPECTION` paged
    redesign (`V023-02b`) — some rework is possible later.
- **Option B: defer to `UI-INSPECTION`** with the paged-sheet design.
  - Drawback: the tester hit this twice now; the sheet is the most-used inspection
    surface and the fix is cheap relative to the annoyance.

Wrap + Back-button sizing (`V025-02a/b`) are treated as plain bugs — in the v0.2.6 pass
regardless; only the More-Info layout needs this call.

## Q4. Contextual-menu close-zoom jitter (`V025-03`): how much is enough?

- **Option A (recommended): side stickiness + offset cap** (keep the chosen side across
  re-placements; hug the unit at high zoom instead of a full magnified tile away).
  - Drawback: still heuristic; extreme zoom + map edge can still nudge it.
- **Option B: fixed screen-corner placement at high zoom** (menu docks to a corner once
  zoom exceeds a threshold).
  - Drawback: breaks the "menu at the unit" spatial link the tester asked for in
    v0.2.3; two placement modes to maintain.

## Q5. Author-extensible combat forecast (`V025-04a`): where does the seam live?

Tester: an author may not want the weapon triangle at all — e.g. advantage from class
tags (air/water/land). This is the open-registry principle applied to AttackPreview; the
Band 5 source/style plan already rebuilds the forecast generically.

- **Option A (recommended): fold into Band 5's generalized-forecast slice; no engine
  edit now.** Record the requirement there: forecast rows = data-driven registry
  (row id, label, value resolver, marker style), triangle/effectiveness become two
  authored entries an author can replace.
  - Drawback: the ask waits for Band 5; the current preview stays triangle-hardcoded
    until then.
- **Option B: add a thin row-registry seam in AttackPreview now** and migrate it into
  Band 5 later.
  - Drawback: builds a registry against the *old* forecast internals that Band 5
    replaces — near-certain rework; violates the "no builds before the schema lock"
    working rule.

## Q6. Effectiveness presentation (`V025-04b`): green damage vs Neutral row

Tester: drop the second `■ Neutral` row; color the per-hit damage green when
effectiveness applies; full breakdown in More Info.

- **Option A (recommended): adopt, with a legibility safeguard.** Green damage value +
  a small `!`/`Eff` glyph next to it (color alone is invisible to ~5% of players and
  the v0.2.3 owner decision favored text markers for exactly this reason); triangle row
  keeps its `■ Neutral` marker; More Info gets the full effectiveness breakdown.
  - Drawback: two conventions in one panel (triangle = row, effectiveness = value
    styling) — needs one More-Info line explaining the color.
- **Option B: keep both Neutral rows** (v0.2.4 behavior, tester dislikes the second).
  - Drawback: overrules fresh tester feedback on a pure-presentation point.
- **Option C: move BOTH triangle and effectiveness to value styling** (no marker rows).
  - Drawback: loses the explicit triangle row the v0.2.3 walkthrough just ratified;
    bigger churn for no reported problem with the triangle row.

Note: whatever is chosen becomes a *default row style* in the Q5 registry, so this
decision is about v1 presentation, not the long-term model.

## Q7. AttackPreview re-anchor on zoom (`V025-04c`) — proposed as no-debate

Register the visible preview with the existing context-menu zoom-reposition hook.
Small, matches the tester ask ("same reposition the wait menu has"). Only veto if the
preview's screen-edge-relative placement should stay fixed for readability reasons.

## Q8. Level-up first-show narrow panel (`V025-05a`): deferred sizing vs no autowrap

Leading cause: first-show `size = get_combined_minimum_size()` against an un-laid-out
autowrap label (see triage E1).

- **Option A (recommended): both.** Drop `autowrap_mode` on `LabelStats` (stat lines
  are short, fixed-format; wrap adds nothing) AND defer the recenter/size one layout
  frame after `show()` for all MenuScale grow-to-content panels — the deferral protects
  every other dynamic modal from the same class of bug.
  - Drawback: a one-frame flash of pre-layout size is possible on very slow frames
    (mitigate: show the panel transparent for that frame).
- **Option B: only drop autowrap** (minimal, targeted).
  - Drawback: leaves the first-show sizing race latent for every other dynamic panel
    (PromotionScreen just demonstrated the same family of bug).
- **Option C: only defer sizing** (keep autowrap).
  - Drawback: keeps a wrap mode that serves no purpose and can still interact with
    width-dependent min-size in surprising ways.

## Q9. Level-up click dismissal (`V025-05b`): `_gui_input` handling + right-click?

Fix shape (see triage E2): clicks handled in `_gui_input` on the STOP root; keyboard
stays in `_unhandled_input`; needs one live confirmation since headless picking differs.

- **Decision (a):** confirm the `_gui_input` approach (alternative — set the root to
  IGNORE and rely on suppression flags — un-blocks the map beneath and regresses #12).
- **Decision (b):** should right-click also advance? v0.2.4 allowed left+right; keep
  that, or left-only? Recommendation: keep left+right (cancel-as-continue is a common
  SRPG idiom and it's already ratified behavior).

## Q10. Promotion picker (`V025-05c/d`): minimal fix now, redesign when?

- **Option A (recommended): v0.2.6 = re-apply scale after rebuild + Options
  ScrollContainer + padding trim** (triage E3); the list-left/details-right redesign
  (tester's sketch, incl. eventual class animations) goes to `UI-INSPECTION` next to
  the character-sheet page design — they should share the master/detail pattern.
  - Drawback: testers see the cramped-but-functional picker for another cycle.
- **Option B: do the redesign now.** The tester's sketch is genuinely better UX and
  promotion is a showcase moment.
  - Drawback: a new master/detail UI mid-bugfix-pass, before `UiThemeDef` tokens and
    the UI-inspection pass exist — high odds of double rework; delays the display gate.

## Q11. Windowed clamp (`V025-06`): explainer only, or Settings feedback too?

The clamp works as designed (title bar reachable; desktop visible around the window is
the expected outcome of "largest 16:9 inside the usable rect"). The tester's 1080p
desktop on a 4K panel adds OS-scaling confusion.

- **Decision (a):** the display/settings explainer guide (also answers V025-09's
  settings.cfg ask) — assumed yes, it's just writing.
- **Decision (b) options:**
  - **B1 (recommended): also show the applied size** next to the Resolution row (e.g.
    "3840x2160 → applied 1904x1071") so the clamp is self-explaining in-game.
    Drawback: one more live-updating Settings label.
  - **B2: nothing in-game**, docs only. Drawback: the confusion recurs with every new
    tester; docs don't ship in the window.
  - **B3: add a "Fit screen" resolution entry** that names the clamped size.
    Drawback: list entry varies per machine; persistence/migration wrinkles.

## Q12. Terrain More Info (`V025-08b`): adopt the single-page redesign?

The click bug itself is settled (mouse_filter on the RichTextLabels — triage G). The
tester re-suggests collapsing the paged panel: tile type + coordinate as a fixed label,
one page cycling all info options, tactics info as another option.

- **Option A (recommended): fix the click bug now; take the single-page redesign as the
  *shape* of the `V023-09b` descriptor surface** (deferred to `B4-MAP-OBJECTS`/`[SAC]`,
  where tile actions become data-driven descriptors) — design it once, with the real
  action vocabulary.
  - Drawback: tester sees the same 3-page cycle another build.
- **Option B: restructure the panel now** (single page + label header), redesign again
  when `[SAC]` lands.
  - Drawback: two redesigns of the same panel; the second one invalidates the first.

## Q13. Test-fidelity rule for input routing (process)

Two v0.2.4 repairs passed headless tests and failed on desktop because the tests call
`_unhandled_input()` / `_try_cycle_terrain_panel_at()` directly, bypassing GUI-phase
mouse consumption (and a headless probe shows headless picking differs from desktop
anyway).

- **Proposed rule:** any fix whose bug involves *event routing* (who receives/consumes
  an input) must ship a `push_input`-injection test AND a line in the next build's
  checklist for live confirmation; direct handler calls remain fine for *logic* tests.
  Land the rule in `AGENT/Docs/guides/testing_guide.md` with the v0.2.6 fixes (DoD#2:
  if we can make check_docs/CI enforce any part of it mechanically, do it in the same
  change; realistically this one is a guide rule + review-checklist item).
- **Debate point:** is there a cheap way to make headless picking match desktop (e.g.
  running the suite in a real display server on CI)? Likely not worth it now — but
  worth 5 minutes next session.

## Q14. v0.2.6 scope confirmation

Proposed build content (triage "Recommended Order" step 2): E1-E3 level-up/promotion
fixes, G terrain mouse_filter, A slider flicker + h-scroll, B1-B2 sheet wrap + Back
button, D3 preview re-anchor, C anchor stickiness, E5 content (5th skill for
`M950_Hero_SkillCap`, extra weapons on Map 950), + explainer guide + handbook digest
with a prominent `godot.log` request. Anything the Q1-Q12 decisions move in or out
adjusts this list; the intent is a focused display-gate closer, not a feature build.

---

## Walkthrough Decisions (recorded 2026-07-04)

All 14 walked with the owner; every one took the recommended option except two owner
additions (Q2 panel-widen, Q14 grind units), noted below.

- **Q1 — Slider flicker:** Option A. Apply Menu Scale on `drag_ended` only; row label
  previews the target factor during the drag; keyboard/step stays live.
- **Q2 — Settings h-overflow:** Option A (disable horizontal scroll, rows adapt /
  keybind list two-line above a threshold) **AND** widen the Settings panel itself
  (owner add) so the adapt branch has more room before it triggers.
- **Q3 — Sheet stats More-Info:** Option A. Adopt the tester's full-height layout now
  (stat table fixed top, prose scroll bottom) as a layout-only change.
- **Q4 — Contextual-menu jitter:** Option A. Side stickiness + offset cap (keep chosen
  side, hug the unit at high zoom).
- **Q5 — Author-extensible forecast:** Option A. Fold into Band 5's generalized-forecast
  slice (rows = data-driven registry; triangle/effectiveness = replaceable authored
  entries). No engine edit now.
- **Q6 — Effectiveness presentation:** Option A. Green per-hit damage + small `!`/`Eff`
  glyph; triangle keeps its `■ Neutral` marker; full breakdown in More Info. Becomes the
  default row style in the Q5 registry later.
- **Q7 — AttackPreview re-anchor:** Confirmed. Register the visible preview with the
  existing context-menu zoom-reposition hook.
- **Q8 — Level-up narrow panel:** Option A (both). Drop `autowrap_mode` on `LabelStats`
  AND defer recenter/size one layout frame for all MenuScale grow-to-content panels;
  mitigate the one-frame flash by showing transparent for that frame.
- **Q9a — Level-up dismiss routing:** Confirmed `_gui_input` on the STOP root (keyboard
  stays in `_unhandled_input`); needs one live desktop confirmation.
- **Q9b — Right-click advance:** Keep left+right (cancel-as-continue idiom, already
  ratified).
- **Q10 — Promotion picker:** Option A. v0.2.6 = re-apply scale after rebuild + Options
  ScrollContainer + padding trim; the list-left/details-right redesign goes to
  `UI-INSPECTION` alongside the character-sheet page design (shared master/detail).
- **Q11 — Windowed clamp:** explainer guide **yes**; Decision (b) = B1, show the applied
  size next to the Resolution row (e.g. "3840x2160 → applied 1904x1071").
- **Q12 — Terrain More Info:** Option A. Fix the click bug now (mouse_filter on the
  RichTextLabels); take the single-page redesign as the *shape* of the `V023-09b`
  descriptor surface, deferred to `B4-MAP-OBJECTS`/`[SAC]`.
- **Q13 — Test-fidelity rule:** Adopt. Any event-routing fix ships a `push_input`
  -injection test + a live-confirmation checklist line; direct handler calls stay fine
  for logic tests. Land the rule in `AGENT/Docs/guides/testing_guide.md` with the
  v0.2.6 fixes.
- **Q14 — v0.2.6 scope:** Confirmed the focused display-gate-closer list (E1-E3, G, A,
  B1-B2, D3, C, E5 content, explainer guide + handbook digest) **PLUS** (owner add)
  **10 extra red units on the promotion validation map** usable for EXP grinding, to
  test repeated level-ups and enforce stat caps.
