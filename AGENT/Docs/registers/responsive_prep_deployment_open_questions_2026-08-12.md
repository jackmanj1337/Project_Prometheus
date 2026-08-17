---
Type: register
Status: RESOLVED — `RPD-1..18` walked and closed 2026-08-13
Last verified: 2026-08-13
Register: RPD-1..18
Tracker: RESPONSIVE-PREP-DEPLOYMENT-RESEARCH-2026-08-12
---

# Responsive Prep and Deployment — Owner Questions

Research: [Responsive Prep and Map Deployment](../design/responsive_prep_deployment_comparative_research_2026-08-12.md)

> **RESOLVED 2026-08-13.** All eighteen questions are dispositioned in the *"Owner rulings"*
> section at the end of this document, which is the decision source — the recommendations below
> are the **pre-walk** text and several were rejected or reframed. **Read the rulings first**, and
> read [`rpd_precedence_diff_2026-08-13.md`](../design/rpd_precedence_diff_2026-08-13.md) before
> reopening anything: this packet cited **no ratified decision at all**, and three of its questions
> were already answered by `PHB-1..7` (June) and the `EPUX` prep-hub ratification (July).

## Composition and navigation

### [RPD-1] Is the map the persistent primary surface at every size class?

**Recommendation:** yes. Compact changes the adjacent controls into sheets; it does not
replace the map with a menu during routine deployment.

### [RPD-2] Should Compact use three bottom-sheet pages: Units, Unit and Mission?

**Recommendation:** yes. They cover selection, contextual configuration and battle context
without introducing a second navigation hierarchy.

### [RPD-3] Should Medium tablet keep a persistent drawer while Medium landscape overlays a drawer only inside the game-view rectangle?

**Recommendation:** yes. The landscape control columns are reserved and must never be
covered; tablet portrait has enough width for a persistent secondary surface.

### [RPD-4] Should Expanded use roster / map / selected-unit panes simultaneously?

**Recommendation:** yes, with Mission and Readiness folded into header/footer at the
1024×768 boundary and expanded into their own regions at FHD.

### [RPD-5] What maximum workspace width should FHD and 4K use?

**Recommendation:** token-scaled sidebars with a bounded central workspace; allow the map to
grow to a configured ceiling and use remaining width as breathing room, not longer rows.

## Roster and placement

### [RPD-6] Does Manage Roster own who deploys while Map Preview owns where?

**Recommendation:** yes, with both editing one live `DeploymentPlan`.

### [RPD-7] What is the fastest substitution gesture for each input family?

**Recommendation:** select placed unit, choose replacement from roster/bench, confirm once;
touch may drag only as an optional shortcut, never as the sole accessible route.

### [RPD-8] How are two occupied starting tiles swapped?

**Recommendation:** select source then destination, with a visible swap preview and a
controller/touch-neutral `Swap` action.

### [RPD-9] Are empty deployment slots warnings or neutral capacity?

**Recommendation:** neutral unless a campaign rule requires an exact count. Do not imply the
player is wrong for deploying below the cap.

### [RPD-10] How are required, excluded, dead and otherwise unavailable units represented?

**Recommendation:** separate status glyph + text vocabulary, with required preselected,
excluded/dead unavailable but inspectable, and no reliance on color alone.

## Information and configuration

### [RPD-11] Which selected-unit actions belong in the quick card?

**Recommendation:** Loadout, Skills, Details and Swap. Class change, convoy-wide work and
other deep configuration stay behind Manage Roster's open panel registry.

### [RPD-12] Which mission facts remain visible without opening Mission?

**Recommendation:** objective, defeat condition and exceptional deployment constraint;
terrain, threats, rewards and chests live in the Mission surface.

### [RPD-13] How should enemy ranges and terrain inspection behave during prep?

**Recommendation:** reuse map inspection vocabulary, with independent threat overlays and a
clear return to placement mode so inspection never accidentally moves a unit.

### [RPD-14] Should unit configurations or whole deployment plans be reusable presets?

**Recommendation:** research before committing. Player feedback supports reducing repeated
configuration, but presets introduce invalidation rules when roster, class, items or map
start tiles change.

## Readiness, exceptional state and persistence

### [RPD-15] Is Begin Battle always visible, even when invalid?

**Recommendation:** yes. Keep it focusable and expose a player-facing unmet reason rather
than hiding it or presenting an inert disabled control.

### [RPD-16] What happens when a required unit is permanently dead or otherwise unavailable?

**Recommendation:** content validation should prevent impossible authored states where it
can; runtime must show the specific contradiction and use an author-selected fallback or
block, never silently drop the requirement.

### [RPD-17] How do Retry and suspend-resume enter prep?

**Recommendation:** campaign Retry restores map-start state and previous plan before prep;
bare-map Retry remains direct. A suspend payload must be cleared through an explicit safe
transition or prep must be skipped—never allow a plan that spawn ignores.

### [RPD-18] What deployment state survives leaving prep, saving, resizing or changing input mode?

**Recommendation:** resize/input/theme changes preserve the live plan, selection, focused
unit and open information surface. A between-map campaign save does not persist the plan;
returning later authors it again from the current campaign state.

---

## Owner rulings, 2026-08-13

Walked in one sitting after the standing `DOC-014` precedence check
([`rpd_precedence_diff_2026-08-13.md`](../design/rpd_precedence_diff_2026-08-13.md)), which is the
fourth in the 2026-08-13 series and the first to find a packet citing **no ratified decision at
all**. Three questions closed by precedence, two were derived rather than asked, thirteen were
ruled. One ruling reaches well beyond prep — see `[RPD-15]`.

### Composition — one ruling covering `[RPD-1]` through `[RPD-5]`

- **`[RPD-1]`/`[RPD-2]`/`[RPD-3]`/`[RPD-4]` — RESOLVED. Map Preview is a canvas, governed by
  `UBS-4`'s rule.** Surfaces inside Map Preview occupy the **canvas region only and never the
  control band**, at every size class — the same rule ruled for dialogue on 2026-08-13, so one
  presenter rule now covers both. The packet's framing that the map is "the persistent primary
  surface" was already answered at the hub level in July: `[EPUX-01]` makes the node interior a
  **flat activity list** and Map Preview **one of six top-level entries**, and `[EPUX-03]` lists it
  among the **full-width escape-hatch** panels the shell presents *alone*. This ruling strengthens
  that without amending it: Map Preview is not merely full-width, it is a **canvas, so the pane
  model does not apply inside it**.
  - `[RPD-2]`'s three Compact pages (Units, Unit, Mission) stand, but as **canvas-region** sheets.
    A screen-bottom sheet would cover the control band — the defect `[UUI-2]` and `UBS-4` both
    exist to prevent, and the republish-during-gesture class the existing suites structurally
    cannot catch.
  - `[RPD-3]`'s landscape half was **already correct** ("overlay a drawer only inside the game-view
    rectangle" *is* the canvas rule). Its Medium-tablet **persistent drawer becomes a canvas-region
    band**, so portrait and landscape stop being two rules.
  - `[RPD-4]` is **REJECTED as written.** Three simultaneous panes contradict `[EPUX-03]`'s *"never
    three panes — a third collapses at 200% Menu Scale and steals width from the terminal panel"*,
    a reason `[UUI-8]` has since made more load-bearing, not less. `UBS-4` rejected the same
    extension one day earlier with *"the tactical map is a canvas, not a list+detail screen"*.
    Expanded takes the canvas rule with a **proportional band**, exactly as `UBS-4` was extended to
    Medium and Expanded.
- **`[RPD-5]` — RESOLVED. Bounded workspace now; no internal breakpoint; revisit only on playtest
  evidence.** Token-scaled surfaces with a bounded central workspace, the map growing to a
  configured ceiling and the remainder as breathing room rather than longer rows.
  `ResponsiveLayout` derives **three** classes from logical width alone and `[UUI]`'s album calls
  1280×720 *"Expanded — now the largest class"*; `[RPD-4]`/`[RPD-5]`'s "at FHD" wording invented a
  second breakpoint *inside* Expanded that no component has a notion of. Marked provisional in the
  posture `EPUX` used for subject memory: reopen if an FHD/4K return shows the workspace reads as
  empty. **The comparative research was already correct here** — it labels 1920×1080 *"Expanded
  FHD"* and 3840×2160 *"Expanded 4K"*. Only this register's question text drifted; preserve the
  eight-viewport proof set.

### Roster and placement

- **`[RPD-6]` — CLOSED BY PRECEDENCE, not asked.** `EPUX`'s ratified prep-hub section already says
  it in these words: Manage Roster "holds **deployment selection** (which units deploy)"; Map
  Preview is "the *where* half of deployment; Manage Roster is the *who*." The seam is also built —
  `scripts/shared/DeploymentPlan.gd`, exercised by `test_deployment_plan.gd`.
- **`[RPD-7]`/`[RPD-8]` — RESOLVED. Select-then-select, committing on the second selection, with no
  confirm step.** `EPUX` had already ruled the model — the author numbers start positions, the
  engine **auto-fills from the deployment roster in order**, the player may **swap**, and placement
  is never a mandatory chore — so the board starts full and only ergonomics were open. One gesture
  serves touch, mouse and gamepad, satisfying `[UUI-2]`'s control columns and `UBS-4`'s gamepad path
  with a single implementation. Touch **drag remains an optional shortcut, never the sole route**.
  `[RPD-8]`'s **visible swap preview is retained** — it is feedback, not a gate.
  - **Consistent with `CAU-4` by construction.** A swap is reversible before Begin Battle, so it
    emits **no confirmation tag**; `CAU-4`'s presets govern only the engine-derived tag set, and an
    author's predicate on a specific action remains a floor.
  - **What no-confirm owes is undo, and that is structural** — the plan is a staged transaction
    (`[RPD-17]`), so nothing before Begin Battle is irreversible.
- **`[RPD-9]` — DERIVED, not asked.** It follows from `[RPD-10]`: an exact-count campaign rule is a
  `REQ` predicate like any other, so an under-filled roster shows Begin Battle **disabled with the
  authored reason**. Empty slots are otherwise **neutral capacity** — under auto-fill-in-order they
  occur only when the roster is shorter than the authored slot list, which is not something the
  player did wrong.

### Information and configuration

- **`[RPD-10]` — RESOLVED. A `REQ` predicate returning an `[EPUX-02]` unmet reason. No sixth
  vocabulary.** `[EPUX-02]` ruled **one** two-state rule (absent → hidden, gated → shown disabled
  with a reason) uniform across four surfaces — one of them the Manage Roster panel registry where
  deployment selection lives — and `[EPUX-04]` put evaluation, the hidden-vs-disabled decision, the
  disabled treatment and the reason placement **in the shell**, so adapters cannot drift. `DRC-11`
  added the tactical map as a **fifth** surface and rejected a richer three-value vocabulary to do
  it. `TSV-8` lost this same argument earlier the same day. *Dead* and *excluded* are **unit state**
  from `DRC-19..24`'s five dimensions, not a display vocabulary. **Depends on `REQ`'s display path**
  for the reason string — the reason `[RCR-4]`'s missing `REQ` banner is load-bearing.
- **`[RPD-11]` — RESOLVED. The quick card is a projection of the Manage Roster registry, filtered by
  a `quick` flag.** `EPUX` ratified Manage Roster as an **open registry** of roster-config panels
  and `AGENTS.md` forbids the closed-enum shape, so a hardcoded four-entry card was never available.
  Loadout, Skills, Details and Swap become **shipped defaults**, not the set: a campaign that never
  uses skills gets no Skills entry for free, and a pack that adds a panel can surface it with no
  engine edit.
- **`[RPD-12]` — RESOLVED. Objective always; defeat condition and deployment constraints on demand
  in Compact.** All three at Medium and Expanded; in Compact only the objective is unconditional,
  with an exceptional deployment constraint surfacing in the canvas only when authored as
  exceptional. `[L10N-7]` binds every responsive component to **1.4× text extent**, and `[UUI]`'s
  own findings recorded the published **Compact row budget is optimistic by half a row** *before*
  1.4×. Three text rows in the class with least room would eat the canvas band the map needs —
  which is `UBS-4`'s proportional-band reasoning applied to a second surface.
- **`[RPD-13]` — presentation half CLOSED BY PRECEDENCE; the mode boundary RESOLVED with an explicit
  mode and a visible indicator.** `EPUX` already ruled pre-battle scouting ("**Preview** (viewed
  from Map Preview pre-battle) → the same view, framed as scouting") and `DRC-11` made the map a
  fifth availability surface, so "reuse map inspection vocabulary" was the ratified answer, not a
  recommendation. What survived was the packet's own best sentence — inspection must never
  accidentally move a unit. **Placement and inspection are named modes with a visible current-mode
  indicator and an explicit toggle**, which is what makes the same tap target safe in both and gives
  gamepad one button to switch.
- **`[RPD-14]` — RESOLVED. Generalize `EPUX`'s subject-memory tiering; no new preset concept.** The
  plan is remembered **firmly within a prep visit** and **best-effort across visits**, falling back
  **per slot** when a unit died, left, changed class, or the map's start tiles changed. `EPUX` had
  already solved this exact invalidation problem once with tiered confidence, which the packet never
  cited. **Provisional and flagged for playtest refinement**, in `EPUX`'s own posture for the same
  mechanism. Named player-authored presets are **not** in v1 and would need their own register.

### Readiness, exceptional state and persistence

- **`[RPD-15]` — RESOLVED, and PROMOTED: disabled entries are FOCUSABLE BUT NOT ACTIVATABLE, at the
  shell, across all five availability surfaces.** "Is Begin Battle always visible when invalid" was
  already `[EPUX-02]`'s per-entry default (`visible-disabled-with-reason`) with `[EPUX-04]` placing
  the reason in the shell. The **new** clause was "keep it focusable", and that question had been
  written down as unruled **twice**: `[EPUX-02]` — *"Derived, not ruled … Recommend
  focusable-but-not-activatable; not settled here"* — and `[EPUX-04]`, which called it "a
  **shell-level** decision too" and deferred it to `EPUX-06/07`. **Neither `EPUX-06` nor `EPUX-07`
  ever ruled it.** A disabled entry takes focus so the unmet reason is reachable by keyboard,
  controller and screen reader rather than hover-only; activating it does nothing. This is not a
  prep decision — **it must be written back into `EPUX-02` and `EPUX-04`**, both of which currently
  point at a deferral target that never resolved.
- **`[RPD-16]` — DERIVED, not asked. Required-ness is a `REQ` predicate over the roster, not a badge
  on the unit.** `DRC-25` ruled this exact shape on 2026-08-13 — the recruitment transition attaches
  to the **opportunity**, with no `recruitable` truth flag on the unit — and `DRC-19..24` retired
  `[RCR-2]`'s auto-set `recruited:<id>` flag for the same duplicate-state reason, a shape that
  appeared **three times in one day**. A required unit is a property of *the mission*. `[RPD-16]`'s
  substance survives intact: author-time validation where possible, a **specific** runtime
  contradiction, an author-selected fallback or block, never a silent drop — and its author-time
  half rides `[DLUX-10]`'s existing structured author-time warning contract rather than a new one.
- **`[RPD-17]` — RESOLVED. The deployment plan IS a staged transaction whose commit point is Begin
  Battle.** Which is `[PHB-5]` (*free navigation; Begin Battle is the sole commit; everything before
  it is revisable*) restated in the two-primitive vocabulary ruled on 2026-08-13. **Suspend discards
  the stage**, per `[PHB-7]` (*no bespoke hub-suspend snapshot; re-entering prep re-derives*).
  **Campaign Retry is a snapshot restore through `MapLedger`**, which `MapLedger` was already ruled
  to consume; bare-map Retry stays direct. The "explicit safe transition" the packet proposed is
  **not built** — it would be a third primitive beside two that already cover the case, the
  inverted/duplicate-mechanism shape caught in `DRC-33` and three more times that day. `[RPD-17]`'s
  own goal — *never allow a plan that spawn ignores* — becomes **structural** rather than a rule to
  enforce: there is no committed plan to ignore until Begin Battle commits one.
- **`[RPD-18]` — CLOSED BY PRECEDENCE, not asked.** Two questions, both already ruled. **Save/leave**
  is `[PHB-7]` (**RESOLVED → A**, 2026-06-23): immediate commit to party state, no hub-suspend
  snapshot, re-derive on re-entry — which is exactly what `[RPD-18]` recommends, re-derived
  correctly without knowing `PHB-7` exists. **Resize/input/theme** is `[EPUX-03]` (**RULED**
  2026-07-26): one presentation controller, composition chosen by measured content width, with
  **selected record and focused region preserved across the transition**, explicitly including the
  200% Menu Scale case that `[UUI-8]` has since made live.

### Debts this walk records

1. ~~**`[EPUX-02]` and `[EPUX-04]` need the `[RPD-15]` write-back.** Both currently defer focusability
   to `EPUX-06/07`, which never ruled it.~~ **WITHDRAWN 2026-08-17 by `R1` — the premise was wrong.**
   `[EPUX-07]` *did* rule it, on **2026-07-26**: *"disabled entries are focusable, not activatable …
   Settles the question deferred from `EPUX-02` and `EPUX-04`."* That is eighteen days before this
   register was authored, and it is the same rule `[RPD-15]` then ruled independently. The corpus has
   since adopted the later one as the source (`campaign_editor_ui_open_questions_2026-08-12.md:1093`
   cites `[RPD-15]` for it). `[RPD-15]` stands and is cited downstream; `[EPUX-07]` has precedence in
   time. The cause was mechanical — `EPUX` was absent from `REGISTERS.md`, so its rulings section was
   unreachable from the catalog and its *question* text, which still reads "deferred", was taken as
   its state. Filed as a register 2026-08-17. Carried into `R3` as a duplicate-mechanism candidate
   with its duplicate already identified. See
   [`r1_plan_corpus_precedence_diff_2026-08-17.md`](../design/r1_plan_corpus_precedence_diff_2026-08-17.md) §5.1.
2. ~~**`PHB` and the `EPUX` prep-hub section owe banners pointing here.**~~ **PAID — verified
   2026-08-17 by `R1`.** Both landed in commit `6068e18b` the same day this debt was recorded:
   `prep_hub_open_questions_2026-06-23.md:16-25` and the `EPUX` prep-hub section's *"Amended
   2026-08-13 by the `RPD-1..18` walk"* banner. Only this ledger line was stale. **The third
   consumer the debt was worried about was `B4-PREP-MAP-DEPLOYMENT`'s plan, which is a *plan*, not
   a packet — and it had no banner, because banners propagate between registers.** `R1` re-derived
   it on 2026-08-17; see
   [`b4_prep_deployment_handoff_2026-07-14.md`](../plans/b4_prep_deployment_handoff_2026-07-14.md).
3. ~~**`[RCR-4]` still owes `[REQ]` a banner** — carried from the `DRC` Group A walk, and `[RPD-10]`
   now depends on `REQ`'s display path for the same reason string.~~ **PAID — verified 2026-08-17 by
   `R1`.** `REQ`'s register cites `[RCR-4]` in five places including the foundation-`F16` consumer
   list; the debt was discharged 2026-08-13 and only this line was stale.
4. **The comparative research is sound; this register is what drifted.** Preserve the eight-viewport
   proof set when amending — only the FHD/4K question wording changes.

### Process note

Fourth precedence check in two days, and the fourth to change the questions before the owner saw
them. This one found a packet with **zero citations** to a corpus that had already answered three of
its eighteen questions and constrained eight more. The `DRC` lesson generalizes: **assume every
2026-07/08 packet owes this check until it has had one.**
