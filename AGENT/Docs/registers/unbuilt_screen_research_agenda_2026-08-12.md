---
Type: register
Status: ACTIVE — re-issued 2026-08-13; UBS-3 discharged and UBS-8 CLOSED 2026-08-14; UBS-6 (next session, convoy+shop combined) and UBS-7 remain
Last verified: 2026-08-14
Register: UBS-1..9
Tracker: UNIFIED-UI-PROGRAMME-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Unbuilt Screens — Research and Question Agenda

**Why this exists.** `[UUI-15]` holds an unbuilt screen out of the wireframe album only while
its own design questions remain unanswered. Drawing it first would manufacture decisions that
deserve an owner walk, and the album's whole value is that it is drawn to ratified answers.
This document now distinguishes the discharged decisions from the three screen groups still
held, so a completed decision cannot keep an unrelated album sheet blocked.

**Re-issued 2026-08-13 after the S1 disposition sweep.** `[UBS-1]`, `[UBS-2]`, `[UBS-4]` and
`[UBS-5]` are discharged; `[UBS-9]`'s design half is discharged. The remaining held screen
groups are **shop/convoy (`UBS-6`), reference compendium (`UBS-7`), and campaign editor
(`UBS-8`)**. `UBS-3` **was** the live cross-cutting dependency; it was walked 2026-08-14 and
discharged — non-modal text entry is editor-only, so it gates nothing outside `UBS-8` and the
compendium is released. **No cross-cutting gate remains.** Dialogue and credits are released for drawing now.

**What it is not.** It does not re-derive anything already decided. `UI-ARCH-01..06`, the
interaction vocabulary, `[MCH-1..8]`, `[PVP-1..8]`, `[ICO-1..6]` and the prep-hub structure
are all accepted; each session starts from them.

**The pattern every one of these rows already asks for** — a campaign-library-style research
doc plus an owner-questions packet with stable ids, then a branch-by-branch walk recording
decisions — is the format. Nothing here invents a new process.

---

## The finding that should shape the schedule

**Several of these sessions converge on the same vocabulary, and running them independently
would produce competing answers to one question.** `DISCUSS-DIFFICULTY-DEATH-UX`'s own
reference already records this for the combat-feedback trio: three independent research docs
would give three vocabularies for *"when the engine does something to a unit the player did
not command, how does the player learn that it happened, and why."*

The same shape appears twice more:

- **Shop, convoy and forge are one transaction surface.** All three quote a cost, reserve,
  commit or refund through the same live `ResourceLedger`, and all three need an item
  selector. Designing them separately produces three selectors.
- ~~**Compendium search, campaign-editor search and any future filter are one text-entry
  problem.**~~ **Dissolved 2026-08-14, and worth reading as a lesson.** The convergence was
  real, but the walk resolved it by *removing consumers* rather than by unifying them: the
  compendium has no search field (closed candidate list), the game UI has none, and only the
  editor is left — so there is one consumer, not three, and nothing to converge. The original
  reasoning below is kept because it is why the question was asked at all.

  > The compendium's non-modal search field is the **first text field in the program that is
  > not inside a modal FileDialog** — which is what makes it the trigger for
  > `DESIGN-TEXT-ENTRY-SERVICE-2026-07-31`: arbitration (two fields must not both drive one
  > on-screen keyboard) and OS-keyboard lifecycle (show/hide plus height, so a results list
  > resizes). No `virtual_keyboard` handling exists anywhere in `scripts/` today.

  Two of the three premises turned out not to survive contact: there is no OS keyboard to have
  a lifecycle (`html/experimental_virtual_keyboard=false`, test-guarded), and the arbitration
  problem needs two simultaneous fields, which one editor-only consumer does not produce.

So the sessions are grouped below by shared vocabulary, not by screen.

---

## Cross-cutting questions — answer once, before any group

These four are inputs to several sessions. Answering them inside one session and not the
others is how the vocabularies diverge.

### [UBS-1] The engine-action feedback vocabulary

**DISCHARGED 2026-08-13.** `CFB-1..18` established the shared vocabulary, `SKF-1..12`
applied it to skill/status feedback, and `CAU-1..10` applied it to combat actions. Difficulty/
death and support may consume that vocabulary, but neither may create a competing one.

When the engine does something to a unit the player did not command — a skill procs, a
status ticks, a support bonus applies, a death triggers — how does the player learn *that it
happened*, *why*, and *to whom*? Feeds `DISCUSS-DIFFICULTY-DEATH-UX`,
`DISCUSS-SKILL-STATUS-FEEDBACK`, `DISCUSS-SUPPORT-UX` and `DISCUSS-COMBAT-ACTIONS-UX`.
Handoff already written:
[`combat_feedback_research_session_handoff_2026-08-07.md`](../plans/combat_feedback_research_session_handoff_2026-08-07.md).

### [UBS-2] The transaction surface

**DISCHARGED 2026-08-13.** `TSV-1..24`, with `SHC-1..8` and `CUR-1..7`, owns the shared
quote/stage/commit/refund, selector, capacity, cancellation, receipt and failure vocabulary.
`UBS-6` still needs its dependent screen packet and walk, but must cite rather than restate TSV.

One quote → reserve → commit → refund presentation shared by shop, convoy and forge, over
the live `ResourceLedger` / `CostSpec` / `ResourceTransaction` spine and the single
`party_gold` wallet. Includes the shared item selector — the convoy plan's Slice 4 already
specifies "a pure `PanelSelector` paired with the shop plan's selector UX", so the pairing
is intended and just needs designing once.

### [UBS-3] Non-modal text entry

**DISCHARGED AS A CROSS-CUTTING GATE, 2026-08-14.** It was the last live one; there are now
none. Walked as `S4`, where the owner ruled non-modal text entry **editor-only**
(`[NMTE-S1]`), game-UI discovery a **closed candidate list over pack content** (`[NMTE-S3]`),
and the surviving questions part of the editor walk (`[NMTE-S4]`).

It is no longer cross-cutting because it now has exactly one consumer. It **does not block the
compendium** — see `[UBS-7]` — and it is not a separate prerequisite for the editor; it is
*inside* `[UBS-8]`. There is no OS-keyboard lifecycle to settle: the editor assumes a physical
keyboard and the project ships no native keyboard.

`DESIGN-TEXT-ENTRY-SERVICE-2026-07-31`'s seam is unchanged for modal game text entry and needs
no further decision before any screen is drawn.

### [UBS-4] Where dialogue sits relative to the control region

**DISCHARGED 2026-08-13.** The `DRC` owner walks ruled placement for Compact, Medium and
Expanded: dialogue is a stage inside the activity snapshot, uses the game-view/dialogue region,
and does not become a control-band modal or count as another `EPUX-06` gated activity.

`[UUI-16]` puts dialogue in pack-themed territory and `[UUI-5]` bounds modals to the game
view — but dialogue is not a modal and not a HUD panel, and nothing has said which it is. In
Compact the answer decides whether a dialogue box eats the map, the control band, or
neither. This is the one cross-cutting question with **no existing row that owns it**.

---

## The sessions

### [UBS-5] Dialogue presentation — `DISCUSS-DIALOGUE-UX-2026-07-23` *(in_review)*

**DISCHARGED 2026-08-13.** `DLUX-1..16` and `DRC-1..18`, including `[UBS-4]`, resolved the
presentation, history, input, choice, save-boundary and size-class questions below. Dialogue is
released into the album; recruitment/capture implementation remains a separate build line.

The furthest along; a research doc and questions packet are the stated first deliverable.

**Must settle before a wireframe:** box placement and height at each size class; speaker
name and portrait treatment given that images are *always present, never informative*;
choice list presentation and how it inherits the ~4-row Compact budget; the backlog
surface; skip and auto controls in touch mode where there is no key to hold; input
arbitration against the control region; and the save-boundary spec — what a save taken
mid-conversation restores to. Plus `[UBS-4]`.

### [UBS-6] The transaction group — `B4-SHOP-ECONOMY` + `B4-CONVOY`

**LIVE; packet authoring is unblocked, and this is the NEXT SESSION** — owner decision
2026-08-14. `[UBS-2]`/`TSV` is resolved. Author the dependent convoy/shop packet over that
contract, without reopening transaction semantics.

**Convoy and shop are ONE session covering both surfaces** (`S5`+`S6` combined): author, precedence-
check, and walk in the same sitting, as the editor arc did. Convoy first is the **packet's internal
section order** — items need a home before they can be bought — **not** a session boundary, so the
shared decisions (selector shape, capacity presentation, transaction display) are taken once with
both consumers in the room rather than settled for convoy and re-litigated for shop.

**Must settle:** the shared selector's shape at Compact, where a list *is* the screen;
convoy capacity presentation and the key-items exemption (`CNV-2`, `CEX-16`); the `SHP-6`
sell-price model, resolved in session notes but never built or drawn; refresh cadence; and
how a reserved-but-uncommitted transaction is shown if the player backs out. Code foothold:
`SaveData.gd:271-279` already persists `party.convoy.entries` with a malformed→legacy-items
fallback, but no `ConvoyService` and no UI exist. `TileActions.gd` declares `shop` as a
reserved placeholder action.

### [UBS-7] Reference compendium — `IMPL-REFERENCE-COMPENDIUM`

**UNBLOCKED 2026-08-14** (was: blocked on `[UBS-3]`). Native discovery, category, history and
deep-link UI — no Markdown parsing, no embedded browser. Discovery is the **closed candidate
list over pack content** ruled in `[NMTE-S3]`, not a text search field: one pack is active at a
time, so its units, classes and items are an enumerable vocabulary. The packet may be authored
now and inherits no input contract.

**Must settle:** candidate-list navigation and category navigation at Compact; history and
deep-link affordances; and
whether the compendium is chrome or pack-themed. `[UUI-16]` does not name it, and the
argument runs both ways — it describes pack content, but it is reachable outside a campaign.

### [UBS-8] Campaign editor UI — `DISCUSS-CAMPAIGN-EDITOR-UI` + `DESIGN-CAMPAIGN-EDITOR-UX`

> **CLOSED 2026-08-14.** `S9` (precedence diff), `S10` and `S11` all ran that day:
> `CEUI-1..40` are resolved, the twelve `NMTE` residues are closed, and the nine `EW`
> wireframe findings are ruled — fifty rulings, `[CEUI-S1]`–`[CEUI-S50]`, in
> [`campaign_editor_ui_open_questions_2026-08-12.md`](campaign_editor_ui_open_questions_2026-08-12.md).
> **`UBS-8` no longer holds anything.** The `UUI-15` album hold now waits only on `UBS-6` and
> `UBS-7`. The "must settle" list below was the agenda for that walk and is kept as a record of
> what it was asked to cover; every item in it is answered.
>
> The **inversion note** at the end of this section survived the walk unchanged and is now a live
> build check: `[CEUI-S7]`'s generated panels make the editor the first consumer of `[UUI-13]`'s
> role vocabulary.

**LIVE as `CEUI-1..40` + the `NMTE` residue.** The two tracker rows are one session, not two.
**Updated 2026-08-14:** search-specific decisions no longer inherit `[UBS-3]` and are no longer
held — twelve `NMTE` questions are *part of this session*, re-scoped as editor questions
(`[NMTE-S4]`). The editor's floor is `1920×880` (`[CEUI-5]`), Expanded-only, with mouse,
physical keyboard and a large screen strongly recommended (`[NMTE-S2]`).

Owner-gated: *"talk UI before it gets built, and that applies to the whole campaign editor,
not just the asset manager."*

**Already settled, do not re-open:** distribution (full integration in all builds,
runtime-gated, OR-warning), the author/player boundary, and — new on 2026-08-12 — that the
editor is **chrome-themed and shares its theme with the Main Menu, pack management and
Campaign Library** (`[UUI-14]`).

**Must settle:** panel layout for a desktop-first mouse+keyboard tool; authoring workflows;
the encounter/balance test environment and its own fixtures, which are explicitly *not* the
player save model; fixture generation; developer-mode surfaces (`CL-ADV-01` unpacked packs,
`CL-ADV-02` deep author validator); the non-blocking author version-bump note
(`CL-ADV-03`); and the asset-manager surfaces against `CSA-11`, `CSA-17`, `CSA-18`. It
should adopt the `UUI-4` list/detail/action components rather than growing its own.

**Note the inversion:** the 2026-08-10 palette decision makes the editor the *first*
consumer of the `[UUI-13]` role vocabulary, because it generates one flat RGBA panel per
role for a new pack. If the editor cannot enumerate the roles well enough to generate a
panel for each, the role list is underspecified — which is a free consistency check on
`[UUI-13]`.

### [UBS-9] In-game credits — `LEG-INGAME-ATTRIBUTION-2026-07-20`

**DESIGN DISCHARGED 2026-08-13.** `CRD-1..10` resolved presentation, engine/pack composition,
license grouping and navigation. Credits are released into the album. The implementation and
asset audit remain a hard first-public-RC blocker; design completion does not discharge that build.

Smallest of the set and the only one with a hard deadline: `LEG-3` chose repo-file-only
(`ATTRIBUTION.md`) for now, but Godot ships under MIT and most asset licences require
attribution be **shown to users**, not merely recorded in a repo file. It becomes a
**release blocker at the first public RC**.

**Must settle:** scrolling versus paged presentation; how pack-supplied attribution composes
with engine attribution given one pack is active at a time; and whether the shipped theme
assets published through Pack 0 (`[UUI-14]`) need their own attribution entry — they will,
if authors are copying them into packs.

---

## Deliberately deferred, not scheduled

These need the same treatment eventually but nothing downstream waits on them, and
scheduling them now would crowd out the five above.

| Row | Why it waits |
|---|---|
| `DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23` | Design is resolved by `DRC-1..33`; the re-derived `DRC-V1` plan owns implementation |
| `DISCUSS-SUPPORT-UX-2026-07-23` | Still live, but consumes resolved `CFB`; it no longer blocks this album queue |
| `DISCUSS-PVP-MODE-UX-2026-07-24` | Closed by precedence (`PVP-1..8`); build-dep is training-hall + hotseat, later in v1 |
| `DISCUSS-AVATAR-MYUNIT-UX-2026-07-24` | An in/out feasibility call, not a layout question |
| `DISCUSS-MINIGAMES-SEAM-UX-2026-07-24` | Very likely post-v1; near-term ask is only "don't architecturally block it" |

---

## Recommended order

**Re-ordered 2026-08-14 after the `[UBS-3]` walk.** Step 1 is done and steps 3–4 lost their
dependency, so the three remaining groups have **no ordering between them** and may run in any
order or in parallel.

1. ~~**Precedence-check and walk `[UBS-3]` / `NMTE-1..20`.**~~ **DONE 2026-08-14.** It did not
   resolve twenty questions; it re-scoped them to the editor and discharged the gate.
2. **Author and walk `[UBS-6]`, convoy before shop.** TSV is resolved, so authoring may begin
   immediately; the walk follows the authored packet. Unchanged.
3. **Author and walk `[UBS-7]`.** No longer waits on anything — discovery is the ratified closed
   candidate list, so there is no text-entry contract to inherit.
4. **Precedence-check and walk `[UBS-8]` / `CEUI-1..40` + the twelve surviving `NMTE` questions.**
   One combined editor session; the search half is no longer deferred to a later supplement.
   Budget for it — it is now the largest walk in the programme by a wide margin.

`[UBS-1]`, `[UBS-2]`, `[UBS-4]`, `[UBS-5]` and `[UBS-9]` are not schedule entries anymore.
Dialogue and credits may be drawn now. Shop/convoy, compendium and campaign editor are released
individually when their named walk resolves; the unbuilt-screen album hold is fully lifted when
all three groups have resolved.

Each session's wireframes are drawn to the conventions the proof set establishes, and land
in the album as a new sheet rather than a new document.

## Packet-authoring disposition — 2026-08-12

The projected research pass is now authored at the base layer:

| Packet | Register | Questions | Disposition |
|---|---:|---:|---|
| Responsive prep/deployment | `RPD-1..18` | 18 | Ready for owner walk |
| Transaction vocabulary | `TSV-1..24` | 24 | **First dependency packet**; convoy/shop held |
| Non-modal text entry | `NMTE-1..20` | 20 | **First dependency packet**; compendium and editor search held |
| Campaign editor UI | `CEUI-1..40` | 40 | Ready except search-specific decisions |
| Localization scope | `L10N-1..18` | 18 | Independent; ready for owner walk |
| Credits/attribution | `CRD-1..10` | 10 | Independent; ready for owner walk |

That is **130 newly explicit questions**, each with options, arguments for and against, and a
recommendation. This replaces the earlier estimate of roughly 110–115 questions. The
downstream convoy/shop and compendium packets are deliberately **not** counted or authored:
their composition depends on `TSV` and `NMTE` respectively, and writing them now would hide
base decisions inside a dependent packet.

Previously written packets remain separate: `SKF-1..12` and `DRC-1..33` are now resolved,
along with `CFB-1..18`, `CAU-1..10`, `DLUX-1..16` and `UUI-1..19`; none may be reopened from
this agenda.

## Next-session owner walk queue — saved 2026-08-12

This is the comprehensive queue agreed with the owner. Preserve the order because the first
two packets establish vocabulary consumed by later packets.

> **Progress as of 2026-08-13, and what the owner scheduled next.**
>
> | Queue item | State |
> |---|---|
> | 1. `TSV-1..24` | **DONE** 2026-08-13 |
> | 4. `L10N-1..18` | **DONE** 2026-08-13 |
> | 8. `CRD-1..10` | **DONE** 2026-08-13 |
> | 5. `SKF-1..12` | **DONE** 2026-08-13 — register closed |
> | 6. `DRC-1..18` + `UBS-4` | **DONE** 2026-08-13 — `UBS-4` ruled for Compact, Medium and Expanded |
> | 12. `DRC-19..33` | **DONE** 2026-08-13 — pulled forward; the whole `DRC` register is now RESOLVED |
> | 3. `RPD-1..18` | **DONE** 2026-08-13 — register RESOLVED |
> | 2. `NMTE-1..20` | written, unwalked — still gates `CEUI` search; **the last unwalked packet of the written set** |
>
> **All scheduled `SKF`/`DRC` work is complete.** `SKF-1..12` closed, `DRC-1..33` closed across
> four sittings on 2026-08-13. Queue item 12 was pulled forward rather than waiting for
> recruitment/capture to enter release scope, because Group A's `custody_status` dimension was
> blocking groups C and D and the implementation-plan re-derivation was blocking thirteen build
> rows behind that.
>
> **What comes next is not on this queue.** `DRC-PLAN-REDERIVATION-2026-08-13` is unblocked and
> scheduled for the next session; it is a plan re-derivation, not a research walk. The remaining
> queue items (`NMTE-1..20`, `RPD-1..18`) resume after it.
>
> **`RPD-1..18` walked 2026-08-13**, out of the recorded order and ahead of the plan
> re-derivation, at the owner's instruction. Thirteen ruled, three closed by precedence, two
> derived without being asked. Its check is
> [`rpd_precedence_diff_2026-08-13.md`](../design/rpd_precedence_diff_2026-08-13.md) and it found
> the worst case yet: **a packet citing no ratified decision at all**, against a corpus that had
> already answered three of its questions (`PHB-5`, `PHB-7`, the `EPUX` prep-hub ratification) and
> constrained eight more. One ruling reached beyond its own packet — `[RPD-15]` closed the
> disabled-entry **focusability** question that `EPUX-02` and `EPUX-04` both deferred to
> `EPUX-06/07`, which never ruled it; both are now amended.
>
> **Four precedence checks were run for these packets, and all four changed the questions
> before the owner saw them** — one of them by finding the *previous* check partly wrong. They
> are recorded in
> [`skf_drc_precedence_diff_2026-08-13.md`](../design/skf_drc_precedence_diff_2026-08-13.md),
> [`drc_group_a_precedence_diff_2026-08-13.md`](../design/drc_group_a_precedence_diff_2026-08-13.md)
> and
> [`drc_groups_bcde_precedence_diff_2026-08-13.md`](../design/drc_groups_bcde_precedence_diff_2026-08-13.md).
> Read them before reopening anything in either packet — eleven questions were disposed of
> without ever being asked and must not be re-asked.
>
> Two rows spun out of the same session and sequence **after** this queue completes:
> `SETTINGS-PERSISTENCE-SCOPE-REVIEW-2026-08-13` and
> `OPTIMIZATION-PASS-RATIFIED-DECISIONS-2026-08-13` (the `DOC-014` corollary).

1. **`TSV-1..24` — transaction vocabulary.** Resolve quote/stage/commit/refund, atomicity,
   selector, destination, capacity, cancellation, receipt and failure semantics.
2. **`NMTE-1..20` — non-modal text entry.** Resolve focus/edit ownership, keyboard and IME
   lifecycle, resize behavior, cancellation, input handoff, privacy and persistence.
3. **`RPD-1..18` — responsive prep/deployment.** Resolve the final map-first deployment
   experience across Compact, Medium, Expanded, FHD and 4K.
4. **`L10N-1..18` — localization scope.** Decide the v1 seam before responsive components
   bake in English-only assumptions.
5. **`SKF-1..12` — skill/status feedback.** Apply the already-resolved `CFB` vocabulary to
   activation, attribution, passive/failure and status-lifecycle presentation.
6. **Dialogue presentation from `DRC-1..18`, including `UBS-4`.** Settle presentation,
   choices, history, skip/auto, save boundary and dialogue placement relative to the control
   region. Do not pull recruitment/capture mechanics into this walk merely because they share
   the older register.
7. **`CEUI-1..40` — campaign editor UI, excluding held search behavior.** Search inherits
   `NMTE`; all other editor decisions may proceed.
8. **`CRD-1..10` — credits and attribution.** Must close before the first public RC.
9. **Author and discuss the convoy/shop packet after `TSV`.** Use the resolved shared
   transaction contract; convoy precedes shop.
10. **Author and discuss the compendium packet after `NMTE`.** Use the resolved shared
    search/text-entry contract.
11. **Complete campaign-editor search decisions after `NMTE`.** Do not create a second
    keyboard or focus authority.
12. ~~**Return to `DRC-19..33` only when recruitment/capture enters release scope.**~~
    **Superseded 2026-08-13 — walked early and DONE.** The condition was overtaken: Group A's
    `custody_status` dimension blocked groups C and D, and the gated implementation-plan
    re-derivation blocked thirteen build rows behind that, so waiting for release scope would
    have held up work that was not itself waiting on release scope.

Already resolved inputs are not discussion items: `UUI-1..19`, `CFB-1..18`, `CAU-1..10`,
`DLUX-1..16`, `DRC-1..33`, `SKF-1..12`, `UI-ARCH-01..06`, `PHB-1..7` and `EPUX-1..28`. Support UX, PvP UX,
Avatar/My Unit feasibility and the minigame seam remain deliberately deferred.
