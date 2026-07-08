# v0.3.0 Playtest Triage - Owner Review Walkthrough - 2026-07-08

Status: DECIDED 2026-07-08 - see Walkthrough Decisions; fix passes scoped
Companion: `AGENT/Docs/playtests/playtest_v0.3.0_results_triage_plan_2026-07-08.md`

The v0.3.0 return leaves both gates open, but the failures are well-localized:
controller MENU navigation (focus scroll/repeat/cadence/trigger feel) rather
than mapping, and a narrow section 1.6 residue. Suspend/Continue is the one
broad regression. The straightforward defects (`V030-SUS-01`, `V030-GP-01/02/03`,
the first-connected-pad brand bug) need no decision — they are queued in the
triage plan sequencing. These five questions are the ones that change what the
fix passes build.

Format per question: context -> options with drawbacks -> recommendation first.
After owner decisions, record them at the bottom and route them to the fix pass.

---

## Q1. What should an explicit Input Mode actually do? (`V030-INP-01`)

The tester expected **Input Mode: Gamepad** to block keyboard input; today an
explicit mode only drives prompts and menu focus, and every device keeps
working (which is also what let section 5 mixed-input pass cleanly).

- **Option A (recommended): prompts/focus only — fix the handbook wording, not
  the code.** Explicit mode pins the prompt/focus scheme; devices are never
  rejected. This is the friendliest behavior (a pad player can still touch the
  mouse) and matches the shipped resolver design.
  - Drawback: "Input Mode" reads stronger than it is; the Settings row may
    need a caption ("affects prompts & menu focus").
- **Option B: explicit mode filters device events.** Gamepad mode ignores
  keyboard/mouse gameplay input (Settings stays reachable).
  - Drawback: self-inflicted lockouts (choose Gamepad, unplug pad, stuck);
    needs an escape hatch and more test surface for little player value.
- **Option C: keep Auto only; drop explicit modes.**
  - Drawback: throws away shipped, working persistence for no reported harm.

## Q2. PlayStation prompt glyphs: real symbols or words? (`V030-INP-02`)

PS prompts currently print the word "Square". Real ✕○□△ glyphs need font
coverage in the UI font (and a fallback when a pad is GENERIC).

- **Option A (recommended): ship brand-correct WORDS now ("Square"/"Cross"),
  add real glyphs with the `UI-INSPECTION` font/theme pass.** The active bug
  worth fixing now is the first-connected-pad branding, which is independent.
  - Drawback: words read less polished until the theme pass lands.
- **Option B: add a glyph-capable font now.**
  - Drawback: font licensing/pipeline work dragged into a bugfix rerun; the
    draft-UI font kits are already queued for evaluation under `UI-INSPECTION`.
- **Option C: use Unicode approximations (✕○□△) from the existing font.**
  - Drawback: renders inconsistently across fonts/platforms; can look worse
    than words.

## Q3. Threat overlay + watch markers: what may coexist? (`V030-MRD-01`)

Watch "D" markers die with the overlay; selecting any unit or opening the
pause menu clears the overlay; the movement selector and threat overlay are
mutually exclusive (peek is not). The tester wants concurrent layers with
distinct textures or a strong border.

- **Option A (recommended): make watch-set threat a STANDING layer.** Watched
  enemies' ranges + "D" markers persist through selection, menus, and overlay
  cycling; the overlay cycle only governs the all-enemies display; movement
  selection draws OVER standing threat with a distinct border/texture so both
  read. This is what the precedence-ordered overlay registry was built for.
  - Drawback: needs a real visual-distinction asset decision (border vs
    texture) — small `UI-INSPECTION` coupling.
- **Option B: keep modal overlays, just restore state after menus/selection.**
  - Drawback: fixes the annoyance, ignores the actual request (seeing threat
    while plotting a move is the point of a watch list).
- **Option C: full concurrent-overlay compositing for every layer.**
  - Drawback: readability soup and a much bigger visual design problem than
    the watch-set case needs.

## Q4. What should the size readout say while maximized? (`V030-DSP-01`)

Maximize is (correctly) never persisted, but the readout keeps the stale
pre-maximize `client WxH` label while maximized.

- **Option A (recommended): show the live truth with a state tag.** While
  maximized show `Maximized (WxH)` from the actual client size, dropdown
  selection unchanged; on un-maximize return to the saved windowed readout.
  Mirrors how Borderless/Fullscreen show `native WxH`.
  - Drawback: one more readout state to test.
- **Option B: freeze the readout at the saved windowed size (status quo),
  document it in the handbook.**
  - Drawback: the label says `client` but is not the client size — the same
    class of lie V028-02 removed.
- **Option C: gray the Resolution row out entirely while maximized.**
  - Drawback: hides useful information and adds a fourth row-state.

## Q5. Cursor-traced manual pathing: v1 scope or backlog? (`V030-FRQ-01`)

Request: unit movement should prefer the path the player traced with the
cursor (up to movement limits) instead of always auto-shortest — so a player
can route around a suspected fog ambush or a known trap.

- **Option A (recommended): backlog it with the perception/fog work.** The
  stated motivations are fog and traps — neither system exists yet. Design it
  as part of `[PER]` (perception/masking), where "path around what you
  believe" has meaning. Record it in the map-readability/movement register now
  so it is not lost.
  - Drawback: a tester-visible request sits unaddressed for a while.
- **Option B: implement waypoint pathing now.** Path arrows already trace the
  cursor route; movement resolution snaps to shortest. Persist the traced
  route when legal.
  - Drawback: real path-planner + input work in the middle of a
    blocker-fix/rerun cycle, with no fog/trap payoff yet.
- **Option C: middle ground — honor the traced path only when its cost equals
  the shortest path.**
  - Drawback: subtle, hard to explain, and still planner surgery.

---

## Walkthrough Decisions

Owner decisions 2026-07-08:

- **Q1 — Relabel, keep behavior (owner variant of A).** The Settings row is
  renamed from **Input Mode** to **Input Prompts** so the label matches what it
  does (prompts + menu focus scheme); devices are never blocked. No behavioral
  change; update the row label, any caption, the display guide/GDD_07 wording,
  and the next handbook's terms section. Internal setting keys (`input_mode`
  et al.) stay as-is so saves/tests/check_docs vocabularies are untouched.
- **Q2 — A. Words now, glyphs later.** Ship brand-correct words ("Square",
  "Cross") and brand the rebind rows through the same
  `InputDisplay.joypad_button_label` helper; real button glyphs ride the
  `UI-INSPECTION` font/theme pass. The first-connected-pad branding bug
  (V030-INP-02) is fixed regardless via last-used-pad device tracking.
- **Q3 — Prototype BOTH shared-cell treatments and compare.** The registry
  compose plumbing is unconditional: route selection/targeting/menu paths
  through the same `repaint_overlays` compose that peek uses, and render "D"
  markers whenever the watch set is non-empty. For SHARED cells, build both
  candidates — (i) border-through: watch threat paints an edge/border variant
  on covered cells; (ii) second-layer true stacking: a second `TileMapLayer`
  renders threat as a translucent tint over/under movement — behind a debug
  toggle, generate headless screenshot comparisons first (the `UI-INSPECTION`
  mockup pipeline), and let the rerun build carry the toggle so the live pass
  picks the winner.
- **Q4 — A. Live truth + state tag.** While maximized the readout shows
  `Maximized (WxH)` from the actual client size (mirroring `native WxH` for
  Borderless/Fullscreen); on un-maximize it returns to the saved windowed
  readout. Persistence policy unchanged (maximize is never written back).
- **Q5 — A, plus a handbook note.** Cursor-traced manual pathing is backlogged
  with the perception/fog work ([PER]) and recorded as [MRD-8] in the
  map-readability register. Every future handbook carries a short "recorded
  requests" note listing it, so the tester can see it is tracked rather than
  dropped.

Routing: Q1/Q2 → the `B6-INPUT` fix pass (V030-GP-01..03 + V030-INP-02); Q3 →
`B6-MRD` V030-MRD-01 slice; Q4 → the V030-DSP-01 fix; Q5 → [MRD-8] + handbook
template.
