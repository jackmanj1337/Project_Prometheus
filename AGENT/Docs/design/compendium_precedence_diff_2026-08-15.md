---
Type: design
Status: Written before the walk (DOC-014); findings F1–F6. The CMP walk is scheduled for the next session
Last verified: 2026-08-15
Tracker: COMPENDIUM-2026-08-15
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Reference Compendium — Precedence Diff

Written before [`compendium_open_questions_2026-08-15.md`](../registers/compendium_open_questions_2026-08-15.md)
is walked. This is `S7`/`S8` of
[`research_and_discussion_sequencing_2026-08-13.md`](../plans/research_and_discussion_sequencing_2026-08-13.md)
and the last `UBS` group. Eighth `DOC-014` check in the series.

## 1. The unusual thing about this one

**The compendium's substrate is already specified — by an approved *plan*, not a register.**
[`generated_reference_model_implementation_plan_2026-07-30.md`](../plans/generated_reference_model_implementation_plan_2026-07-30.md)
(662 lines, `Status: Planned — approved architecture`) already owns stable entry identity,
facts-not-sentences, provenance profiles, related entries and backlinks, the "Open Reference" deep
links from five surfaces, input parity, the diagnostic families and the delivery slices.

That is the same relationship `TSV` had to convoy/shop, with one difference that matters: a plan is
**not** a register, so none of it was walked with the owner. The packet therefore cites it as
ratified architecture and asks only what it does not decide — but where a plan sentence collides
with a later *ruling*, the ruling wins and the plan is corrected (`DOC-014`, standing rule 4).

## 2. Findings

### F1 — The plan's in-game search is superseded; its HTML search is not

Plan line 466 gives the in-game compendium *"search and category filters"*. `[NMTE-S3]` (2026-08-14)
ruled game-UI discovery is a **closed candidate list over pack content**, no free-text search, and
`EPUX-15` had already cut search from v1 for the same controller reason. The plan predates both.

**The precision that matters:** the plan's *Static HTML — later output* section also specifies
full-text search, and that sentence is **untouched**. It describes a browser artifact with a
keyboard, which is exactly the surface `[NMTE-S1]`/`[NMTE-S3]` left alone. A correction that struck
both would remove a ratified capability. **Only line 466 is stale.**

### F2 — The tracker row's text-entry prerequisite is discharged

`IMPL-REFERENCE-COMPENDIUM`'s reference reads: *"This plan specifies 'search and category filters'
… which makes it the trigger for `DESIGN-TEXT-ENTRY-SERVICE`: it needs arbitration … and OS-keyboard
lifecycle."* All three premises are gone — `[NMTE-S1]` made non-modal entry editor-only,
`[NMTE-S2]` removed the on-screen keyboard, and `[NMTE-S3]` removed this consumer. The compendium
has **no text-entry prerequisite**. The row is owed an edit.

### F3 — "Reachable outside a campaign" was a conflation, and it dissolves the theming question

`[UBS-7]`'s must-settle list ends: *"whether the compendium is chrome or pack-themed. `[UUI-16]` does
not name it, and the argument runs both ways — it describes pack content, but it is reachable outside
a campaign."*

**Owner, 2026-08-15: the out-of-campaign reference is the *exported* artifact**, not a game screen —
the GFM folder, the combined Markdown/PDF and the later static HTML, generated headlessly or from the
editor, which the plan already specifies in full. The in-game compendium is **campaign-scoped**.

So the theming question has no fork left: one pack is active (`ICO-1`), the screen exists only inside
a campaign, and `UUI-16` puts it inside the pack theme boundary. The question is **dissolved rather
than arbitrated** — the same shape as the `NMTE` modality collision, where the owner removed a
consumer instead of choosing between two answers.

### F4 — Undiscovered content is a deliberate exception to the availability vocabulary

The plan allows *"optional discovery/visibility policy supplied by campaign rules without deleting
facts from author/full exports."* The shell-wide vocabulary — `EPUX-02`, `EPUX-07`, `RPD-15`,
`[TSV-13]` — says a gated entry is **shown disabled with its reason**, and that vocabulary has been
inherited by every surface in the programme.

**For a compendium it is exactly wrong: the reason string is the spoiler.** "Requires defeating the
Black Knight" leaks the thing hiding the entry was protecting. Owner ruled 2026-08-15: undiscovered
entries are **hidden**. Recorded here as a **named exception**, because a later reader who finds a
hidden entry will otherwise correctly report it as a vocabulary violation — this is the fourth
surface to inherit that vocabulary and the first to be exempted from it.

### F5 — Hiding entries does not hide the shape of the graph

Found by drawing, not by reading. `[F4]`'s ruling settles list membership but not **related links
from a visible entry to a hidden one** — and the plan makes those links first-class ("see also",
"used by", "granted by", plus validation that fails on unresolved backlinks).

Three options, none free: a struck-through *"not yet known"* chip still announces that something
called Argent Blade exists; omitting the link leaks nothing but makes the same entry render
differently in two saves; revealing it contradicts `[F4]`. Asked as `CMP-6`, with the drawn frame.

**And it reaches the exporter:** the plan's validator *fails* activation on unresolved references.
If the in-game view can omit a link, the omission must be a presentation filter over a complete
graph, never a hole in the semantic document — otherwise discovery state would have to become an
export input, which the plan explicitly refuses ("without deleting facts from author/full exports").

### F6 — Back/forward history has no precedent in the programme

Also found by drawing. `[DSX-S13]` gives the distribution shell a **step-back that restores focus**;
`[TSV-24]` preserves state across recomposition. Neither is a **history stack**, and the compendium
needs one because following a related link is a *sideways jump*, not a step down a chain. Nothing
else in the programme has this affordance, so the back arrow's meaning is genuinely undecided —
`CMP-2`.

## 3. Cited, never restated

| Source | Owns |
|---|---|
| `B3-REFERENCE-MODEL` plan | Entry identity, facts, author notes, provenance, relations/backlinks, deep-link sources, validation families, delivery slices, all external outputs |
| `[NMTE-S3]` | Discovery is the closed candidate list; no in-game text field |
| `ICO-1..6` | One pack active at a time, self-contained |
| `UUI-15/16` | Album hold; the pack theme boundary |
| `[DSX-S10]`/`[DSX-S14]` | The Compact chain and its context line |
| `EPUX-02`/`EPUX-07` | The availability and reason vocabulary this surface is **exempted** from (`F4`) |

## 4. What the proof set measured

[`compendium_proof_set.html`](../wireframes/albums/compendium_proof_set.html), six frames:

| Frame | Measured |
|---|---|
| **A** — three regions (category │ list │ entry) | category pane **239 × 986 px for 8 rows**; entry 420 px |
| **B** — two regions, categories as facets | entry **520 px**, no new composition |
| Compact, categories step | 5.8 rows |
| Compact, entry list | 4.4 rows, 2.33 screens |
| Compact, entry | 2.3 screens |
| Hidden-link case | drawn; see `F5` |

**Owner chose B (`[CMP-S3]`).** A spends a 986-px-tall pane on a list of eight that changes about
once a session, and gives the narrowest column to the pane carrying facts, an author note, related
links and provenance. B is the ratified record-screen archetype and buys the entry 100 px. **At
Compact both shapes are the identical chain**, so this was an Expanded-only decision and stays cheap
to revisit.

Second sighting of a distribution-album finding: the entry list is **1259 px wide for two-line
rows**. Nothing caps the row measure at Expanded, in a second unrelated screen family — which
strengthens the case for capping it once, globally, rather than per screen.

## 5. Walk order

`CMP-1..4` (shape and navigation, of which `CMP-1` is pre-ruled) → `CMP-5..7` (discovery, where
`CMP-6` is the one with no cheap answer) → `CMP-8..9` (deep links) → `CMP-10..12` (entry content) →
`CMP-13..15` (scope, album, persistence). **Take `CMP-6` early despite its position:** it constrains
both the exporter and the validator, and it is the only question here that can produce a save-visible
inconsistency.
