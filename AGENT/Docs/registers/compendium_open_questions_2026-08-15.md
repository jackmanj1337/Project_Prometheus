---
Type: register
Status: OPEN — CMP-1..21 authored 2026-08-15; three pre-ruled, the walk runs next session
Last verified: 2026-08-15
Register: CMP-1..21
Tracker: COMPENDIUM-2026-08-15
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Reference Compendium — Owner Questions

The `S7`/`S8` packet and the last `UBS` group. Read the precedence diff first:
[`compendium_precedence_diff_2026-08-15.md`](../design/compendium_precedence_diff_2026-08-15.md).
Frames: [`compendium_proof_set.html`](../wireframes/albums/compendium_proof_set.html).

**What this packet does not touch.** The semantic reference model itself — entry identity, facts,
author notes, provenance, relations and backlinks, deep-link sources, validation families, delivery
slices and every external output — is approved architecture in
[`generated_reference_model_implementation_plan_2026-07-30.md`](../plans/generated_reference_model_implementation_plan_2026-07-30.md).
This packet asks only what that plan leaves open, plus the places a later ruling overtook it.

**Substrate review, 2026-08-15 (after `CMP-1..15` were authored).** The plan was checked against
every ruling that post-dates it. Nine rulings across `CSA`, `L10N`, `CRD` and `CMP-S1`/`S2` had
never been folded in — including one the `CSA` walk called a **correctness defect**, where the
player-facing provenance profile strips required licence attribution. Those are now corrected
directly in the plan (see its *Corrections Folded In* table); the walk does not need to re-decide
them. What the corrections **left open** is section **F**, `CMP-16..21`. Two of them amend
questions above: `CMP-10` (art breaks the "identical layout" claim) and `CMP-11` (attribution is
off the provenance axis entirely).

---

## Ruled before the walk (owner, 2026-08-15)

- **`[CMP-S1]` — discovery is the closed candidate list.** No in-game search field, confirming
  `[NMTE-S3]` against the plan's line 466. Categories plus derived facets are the whole mechanism.
  The plan's **static HTML** full-text search is untouched and remains ratified (diff `F1`).
- **`[CMP-S2]` — undiscovered entries are hidden, not disabled-with-a-reason.** A deliberate,
  named exception to the `EPUX-02`/`EPUX-07`/`RPD-15` availability vocabulary, because in this
  surface the reason string *is* the spoiler (diff `F4`). Consequences for related links are
  **not** settled by this and are asked as `CMP-6`.
- **`[CMP-S3]` — shape B: two regions, categories as the facet row.** Chosen against the measured
  alternative: A's category pane is 239 × 986 px for eight rows, and B gives the entry 520 px
  instead of 420 px with no new composition. At Compact both collapse to the same chain, so this
  is an Expanded-only decision.

---

## A. Shape and navigation

### [CMP-1] Which composition? — **PRE-RULED `[CMP-S3]`: B.**
Kept in the register so the rejected option and its measurement are not lost. Revisit only with a
frame, not an argument.

### [CMP-2] What does the back arrow mean?

Following a related link is a **sideways jump**, not a step down the chain, so the compendium needs a
**history stack** — an affordance nothing else in the programme has. `[DSX-S13]`'s step-back and
`[TSV-24]`'s state preservation are different mechanisms and neither is this.

- **A — A true back/forward history stack**, browser-shaped, over both chain steps and link jumps.
- **B — Back is only the chain's step-back**; a related link replaces the entry in place and is not
  separately reversible.
- **C — Back is the chain step; a link jump pushes a "return to X" affordance** in the entry itself.
- **Recommendation: A**, because the plan already promises "stable entry navigation with
  back/forward history" and B makes a two-link excursion unrecoverable. But A owes an answer to
  `CMP-3`.

### [CMP-3] Does **forward** earn its place at Compact?

Back is unambiguous; forward only has meaning after a back, and it costs a target in a 360-px app bar
that also carries a title and a pack identity.

- **Recommendation: back always, forward only where the size class has room** — and never as the
  only path to anything. Drawn with both in the proof set so the cost is visible.

### [CMP-4] How does the facet row behave when categories overflow?

Eight categories is more than `UUI-19` fitted in a 524-px landscape rect.

- **Recommendation: horizontal scroll, as facets already do**, with the active category always
  scrolled into view. This is the known behaviour rather than a new one; recorded because
  `[CMP-S3]` makes categories facets and therefore inherits it.

## B. Discovery

### [CMP-5] Does the discovery policy apply to the exported reference? — **partly answered**

The plan already says visibility policy applies *"without deleting facts from author/full exports."*

- **Recommendation: confirm and go further** — exports are complete by definition, and a
  player-facing export profile (if one is ever wanted) is a **filter over a complete document**,
  never a different document. Otherwise discovery state becomes an export input and two authors
  exporting the same pack get different guides.

### [CMP-6] What happens to a related link that points at a hidden entry? **Take this early.**

`[CMP-S2]` settles list membership and not this. Drawn in the proof set.

- **A — Show it struck through, "not yet known."** Honest about the gap. **But it still announces
  that something called Argent Blade exists**, which is most of the spoiler.
- **B — Omit the link entirely.** Leaks nothing. Costs: the same entry renders differently in two
  saves, and a player comparing notes with a friend sees a different page.
- **C — Show it and let it resolve.** Contradicts `[CMP-S2]`.
- **Recommendation: B**, with one binding constraint — **the omission is a presentation filter over
  a complete graph, never a hole in the semantic document.** The plan's validator fails activation
  on unresolved references, so if hiding ever reached the document, discovery state would become an
  export input and the validator would start failing on correct packs.

### [CMP-7] Is "hidden" per-save, per-campaign, or per-profile?

Discovery is progress, so it is save state — but the compendium is reachable from a campaign that
has several saves.

- **Recommendation: per-save**, alongside the rest of campaign progress, and stated as such in
  `S12`'s settings-scope review rather than invented here. Flagged because `[CMP-S2]` is the first
  ruling in the programme that makes a **screen's content** depend on save state.

## C. Deep links

### [CMP-8] Does "Open Reference" navigate away or open in place?

The plan gives five sources: More Info, inventory, class, skill, terrain. Three of those are inside
the distribution shell, and one is mid-battle.

- **A — Always navigate to the compendium**, with the return path in history.
- **B — Open in place as a bounded panel** over the calling surface.
- **C — By caller: in place from a battle surface, navigate from a prep surface.**
- **Recommendation: C, expressed as a rule rather than a list** — a caller that owns the canvas
  region opens in place (`[DSX-S16]`'s on-map rule and `UBS-4`'s conversation precedent); a caller
  that can be left and returned to navigates. Do not enumerate the five callers; the plan's own
  registry will grow them.

### [CMP-9] Where does a deep link return to?

- **Recommendation: the caller, always, as the first entry in the compendium's own history.** A
  deep link that dumps the player at the compendium's root has lost the thing they were reading
  about.

## D. Entry content

### [CMP-10] Does the compendium reuse the More Info layout? — **amended 2026-08-15, see `CMP-16`**

The plan's Slice 2 migrates every More Info surface to **generated facts** plus a **separate
author-notes box**.

- **Recommendation: yes, identically, for the rules and notes regions.** The compendium is the
  same content at a different size, and a second layout for the same two boxes is how the
  programme grows a second vocabulary. Drawn that way in the proof set.
- **Amendment (substrate review, 2026-08-15): "identically" cannot hold for art.** As authored,
  this question assumed a two-region layout. `[CSA-15]` makes it **three** regions, and
  `[CSA-26]` requires the compendium and More Info to render the same asset **differently** on
  purpose. The identity claim survives for regions 1 and 2 and fails for region 3 — asked
  separately as `CMP-16`. The proof set does not draw a visual region.

### [CMP-11] Is provenance player-facing?

The plan carries provenance profiles and "optional diagnostic provenance".

- **A — Always visible** (pack name and version on every entry).
- **B — Pack identity always; full provenance behind dev mode.**
- **C — Never in game.**
- **Recommendation: B.** Pack and version answer "where did this come from", which a player of a
  third-party pack genuinely needs; source paths and rule provenance are diagnostics. `CL-ADV`
  already gates loose-folder packs behind dev mode, so the gate exists.
- **Amendment (substrate review, 2026-08-15) — two corrections to the premise.** First,
  `none`/`summary`/`full` are **export** parameters; nothing in the plan defines a *view-time*
  profile, so B needs one invented rather than selected. Second, `[CSA-13]`/`[CRD-6]` removed
  **required attribution** from the provenance axis entirely — it is non-suppressible and cannot
  be gated behind dev mode by any answer here. Whichever option is chosen governs *diagnostic*
  provenance only. The channel question is `CMP-21`.

### [CMP-12] Does the compendium state which pack and version it describes?

- **Recommendation: yes, in the app bar**, as drawn. It is the one line that makes every other line
  interpretable, and `ICO-1`'s one-active-pack model means it is never ambiguous.

## E. Scope, album, persistence

### [CMP-13] Campaign-scoped and pack-themed — confirm the consequences

Owner 2026-08-15: the out-of-campaign reference is the **exported** artifact, so the screen exists
only inside a campaign and `UUI-16` puts it inside the pack theme boundary (diff `F3`).

- **Recommendation: confirm, and record the two consequences** — there is no no-pack empty state to
  design, and the main menu gains no compendium entry. The `[UBS-7]` must-settle line that asked
  chrome-versus-pack-themed is **dissolved**, not answered.

### [CMP-14] What does the compendium contribute to the wireframe album?

- **Recommendation: the six proof-set frames plus a Medium landscape frame**, drawn to the rulings
  after the walk. `UBS-7` then lifts on **album approval**, per `[DSX-S29]` — the same standard as
  `UBS-6` and `UBS-8`.

### [CMP-15] What survives leaving the compendium?

- **Recommendation: extend `[TSV-24]`/`[DSX-S13]`** — category, facets, focused entry and scroll
  survive recomposition and input change. **History does not survive exit**: a session-scoped stack,
  matching `[CEUI-S6]`'s session-scoped editor history rather than inventing a third retention
  policy.

## F. Substrate gaps — added 2026-08-15 after the semantic-system review

`CMP-1..15` were authored against the plan as written. Reviewing the plan against every ruling
that post-dates it surfaced one ratified register that binds it (`CSA`, closed **2026-07-31 —
one day after the plan**) and five things the questions above assume but nothing specifies. The
already-ruled half is corrected directly in the plan; what is left needs the owner.

### [CMP-16] Does the compendium have a visual region, and where?

`[CSA-15]` makes More Info **three** regions — rules, notes, and a **visual** region fed by
`art_asset` facts. `[CSA-14]` requires the in-game compendium to **animate art live**.
`[CSA-26]` requires the compendium to show the asset in **native, unswapped colours plus a swap
enumeration**, where More Info shows the context-resolved variant. None of that reached
`CMP-1..15`, and **the proof set draws no visual region** — so the `[CMP-S3]` measurement of a
520-px entry pane was taken against a layout with one region missing.

- **A — A third region in the entry pane**, below facts, above or below notes.
- **B — Art is the entry's header**, with facts and notes beneath — the archetype a wiki uses.
- **C — Art only where the entry kind has it**, with the region absent otherwise.
- **Recommendation: C for presence, B for placement.** Most entries (a stat, a formula, a
  requirement) have no art at all, so a permanently reserved region is dead space on the
  majority of entries; but where art exists it is the fastest identifier on the page and belongs
  at the top. **This owes `[CMP-S3]` a re-measure**, not just an answer — 520 px was measured
  without it.

### [CMP-17] What *discovers* an entry? **No mechanism exists anywhere.**

`CMP-5`, `CMP-6` and `CMP-7` all presuppose discovery, and `[CMP-S2]` rules what an undiscovered
entry looks like. But the plan's only sentence on the subject is *"discovery/visibility policy
supplied by campaign rules"* — **no trigger vocabulary, no event, no authoring surface.** Nothing
in the programme says what marks an entry discovered.

- **A — Authored explicitly**: campaign rules name the condition per entry, on the existing
  requirement-predicate substrate.
- **B — Derived from encounter**: seeing a unit/item/terrain in play discovers its entry
  automatically, engine-side.
- **C — Both** — B as the default, A as the author override.
- **Recommendation: C, built as A first.** B alone cannot express "discovered by finishing
  chapter 3", and it silently makes every entry's visibility a consequence of engine internals
  nobody authored. A alone makes an author hand-write a condition for every item in the pack.
  The predicate substrate already exists, so A is the cheap half and B is a default predicate on
  top of it. **This is the question `CMP-5..7` were resting on**, and it should be taken before
  them.

### [CMP-18] Do entry IDs become durable save state?

If discovery is per-save (`CMP-7`'s recommendation), the save must persist *which entries* are
discovered — and it can only key that on the entry ID. The plan's ID-stability rule is written
for **renderers**: *"retain redirects only when an explicit migration maps an old ID to a new
ID."* Saves need the same guarantee, and nothing says so.

- **Recommendation: yes — state it, and inherit the renderer's migration rule.** This is exactly
  `[L10N-9]`'s reasoning ("registry IDs are never translated… forced by save durability and
  cross-reference stability") applied to a case nobody has applied it to. Without it, an author
  renaming a local ID silently un-discovers content in every existing save.

### [CMP-19] How does a deep link resolve a runtime object to an entry?

`CMP-8`/`CMP-9` decide what "Open Reference" *does*; nothing decides what it is *given*. The plan
lists five deep-link **sources** but never the mapping, and the ambiguity is real: `[TSV-11]`
commits exact **instance** IDs, while an entry describes the **definition**. An inventory slot
holding a forged, half-broken Iron Sword must resolve to `pack:item:iron_sword`.

- **Recommendation: callers pass a definition-level entry ID, resolved through one shared
  helper** — never construct the ID at the call site. The plan's own registry will grow the
  caller list (`CMP-8`), so the resolver is the thing that must be single, not the enumeration.

### [CMP-20] What is the compendium actually called?

The plan says the name *"should be **Reference** or **Compendium** unless later tone work selects
'Wiki'"* — and no ruling has ever picked one. Every document since has used all three informally.
`[L10N-2]` now makes it a chrome message ID, so it is one key with one English value.

- **Recommendation: pick one now, at the walk.** It is a one-line decision that is embarrassing
  to still be carrying at implementation, and the register, the plan, the tracker row and the
  album all currently disagree.

### [CMP-21] Is the compendium's pack line the credits channel, or a second one?

`CMP-12` puts pack and version in the compendium app bar. `[CSA-13]` puts required attribution in
"an always-reachable credits view"; `[CRD-2]` composes that view from engine notices plus the
**active** pack and **active** theme — which is exactly the scope `CMP-13` gives the compendium.
Two surfaces now display overlapping pack identity, and no ruling says whether they are one
mechanism.

- **A — One channel**: the compendium's pack line links to the credits view, which owns all
  attribution.
- **B — Two**: the app-bar line is identification, credits is compliance, and they share nothing
  but a data source.
- **Recommendation: B for presentation, A for data.** They answer different questions and belong
  in different places, but both must read the same structured notices (`[CRD-1]`) or they will
  drift — which is the exact failure `[CRD-1]` exists to prevent.

---

## What the walk should expect

1. **`CMP-1..15` is mostly confirmation; section `F` is not.** The plan did the architecture, and
   three of the original questions have real forks — `CMP-2` (history), `CMP-6` (dangling links)
   and `CMP-8` (deep-link behaviour). `CMP-16..21` are different in kind: they are things the
   substrate does not specify at all.
2. **Take `CMP-17` before `CMP-5..7`.** Those three decide the *policy* for discovery; `CMP-17`
   asks what discovery **is**. Answering scope and export behaviour for a mechanism that does not
   exist yet is how a register produces rulings that cannot be implemented.
3. **`CMP-6` and `CMP-18` are the two that can produce a save-visible inconsistency**, and both
   constrain the exporter and validator, not just the screen.
4. **`CMP-16` owes `[CMP-S3]` a re-measure.** The 520-px entry pane was measured on a layout with
   no visual region. The shape-B ruling probably survives — it gains 100 px, and a header-placed
   art region costs height, not width — but it was measured against an incomplete layout and
   should be re-checked before the album is drawn, not after.
5. **Documents owed edits regardless of how the walk goes:** the plan's line 466 **and its Slice 6
   bullet** (diff `F1` said only line 466; there are two), and `IMPL-REFERENCE-COMPENDIUM`'s
   text-entry prerequisite (diff `F2`). The plan's stale sentences are **already corrected**; the
   tracker row is not.
