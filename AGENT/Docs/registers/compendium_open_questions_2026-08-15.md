---
Type: register
Status: OPEN — CMP-1..15 authored 2026-08-15; three pre-ruled, the walk runs next session
Last verified: 2026-08-15
Register: CMP-1..15
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
This packet asks only what that plan leaves open, plus the two places a later ruling overtook it.

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

### [CMP-10] Does the compendium reuse the More Info two-box layout?

The plan's Slice 2 migrates every More Info surface to **generated facts** plus a **separate
author-notes box**.

- **Recommendation: yes, identically.** The compendium is the same content at a different size, and
  a second layout for the same two boxes is how the programme grows a second vocabulary. Drawn that
  way in the proof set.

### [CMP-11] Is provenance player-facing?

The plan carries provenance profiles and "optional diagnostic provenance".

- **A — Always visible** (pack name and version on every entry).
- **B — Pack identity always; full provenance behind dev mode.**
- **C — Never in game.**
- **Recommendation: B.** Pack and version answer "where did this come from", which a player of a
  third-party pack genuinely needs; source paths and rule provenance are diagnostics. `CL-ADV`
  already gates loose-folder packs behind dev mode, so the gate exists.

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

---

## What the walk should expect

1. **Most of this packet is confirmation.** The plan did the architecture; three questions have real
   forks — `CMP-2` (history), `CMP-6` (dangling links) and `CMP-8` (deep-link behaviour).
2. **`CMP-6` is the only question here that can produce a save-visible inconsistency**, and it
   constrains the exporter and validator, not just the screen.
3. **Two documents are owed edits regardless of how the walk goes:** the plan's line 466, and
   `IMPL-REFERENCE-COMPENDIUM`'s text-entry prerequisite (diff `F1`, `F2`).
