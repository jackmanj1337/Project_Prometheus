---
Type: design
Status: Written before the walk (DOC-014); findings F1–F9. F1 corrected and F7–F9 added by the 2026-08-15 substrate review. The CMP walk is scheduled for the next session
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
both would remove a ratified capability.

> **Corrected 2026-08-15 (substrate review).** This finding originally read *"Only line 466 is
> stale."* That was wrong: the plan specifies in-game search in **two** places — line 466 and the
> **Slice 6** bullet (*"Add native reference browser, search/category indexes, navigation history,
> and deep links"*). A correction applied to line 466 alone would have left the delivery slice
> still specifying the cut capability. Both are now corrected in the plan; the HTML search
> sentences are deliberately untouched, as this finding says.

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

### F7 — `CSA` closed one day after the plan and binds it in four places — **the diff's own miss**

Found 2026-08-15 by re-reading the plan against every ruling that post-dates it, which this diff
should have done at authoring time and did not. `campaign_sprite_authoring` closed **2026-07-31**
— the plan is dated **2026-07-30** — and four `CSA` rulings are *about* the reference model. The
`CMP-1..15` packet mentions art, sprites, animation and attribution **zero times**.

| Ruling | Binds | Plan as written |
|---|---|---|
| `[CSA-13]` | Attribution is a **separate, non-suppressible channel**, independent of the provenance profile | `none` = "player-facing content without provenance blocks" — the player-facing path is exactly the one that strips CC-BY attribution |
| `[CSA-15]` | More Info is **three** regions; art is a fact for data, its own region for layout | "two conceptually separate regions" |
| `[CSA-14]` | The **in-game compendium** and the HTML output animate art **live**; GFM/PDF keep still frames | No art output requirement at all |
| `[CSA-26]` | Reference shows **native, unswapped colours** + swap enumeration; More Info shows the context-resolved variant | The `definition`/`resolved`/`example` trichotomy has no axis for this |

**`[CSA-13]` is the sharp one, and `CSA` said so at the time** — it labelled it "a correctness
defect rather than a preference" and "the sharpest finding of the walk". It sat uncorrected for
fifteen days because it was ruled in one document and the defect lived in another.

**And the vocabulary gap is load-bearing:** `CSA` states plainly that there is *"no visual/art/
animation fact anywhere in"* the first fact vocabulary. Unknown fact kinds **fail** strict
exports, so without an `art_asset` kind the compendium cannot legally show a sprite. All four are
now folded into the plan.

### F8 — `L10N` never reached the substrate

`[L10N-3]` (each pack ships its own locale catalogues), `[L10N-9]` (IDs never translated, display
keys separate) and `[L10N-10]` (user names verbatim) were ruled 2026-08-13 and none reached the
plan. The plan's `title` correctly uses `{text_key, fallback}` — but **`author_notes.body` is a
raw string**, which makes author notes structurally untranslatable and contradicts a pack
shipping its own catalogues. `[L10N-15]`'s locale-to-asset mapping lands on the same missing art
facts as `F7`. Corrected in the plan.

### F9 — Five things `CMP-1..15` assumes that nothing specifies

Not collisions — **holes**. Each is asked in the register's new section `F`:

| Gap | Assumed by | Asked as |
|---|---|---|
| **What *discovers* an entry** — no trigger vocabulary, event, or authoring surface exists | `CMP-5`, `CMP-6`, `CMP-7`, `[CMP-S2]` | `CMP-17` |
| Entry IDs become **save-persisted keys**; the ID-stability rule is written only for renderers | `CMP-7` | `CMP-18` |
| **Runtime subject → entry ID** resolution; `[TSV-11]` commits *instance* IDs, entries are *definitions* | `CMP-8`, `CMP-9` | `CMP-19` |
| No **view-time** provenance profile — `none`/`summary`/`full` are export parameters | `CMP-11` | amends `CMP-11` |
| Compendium pack line vs. the always-reachable **credits view** (`[CRD-2]` scopes it identically) | `CMP-12`, `CMP-13` | `CMP-21` |

Plus one the plan has carried unresolved since 2026-07-30 and no register ever asked: the
compendium's **player-facing name** (`CMP-20`).

**`CMP-17` is the one that reorders the walk.** `CMP-5..7` decide discovery *policy*; `CMP-17`
asks what discovery **is**. Ruling scope and export behaviour for a mechanism that does not exist
produces decisions nobody can implement.

## 3. Cited, never restated

| Source | Owns |
|---|---|
| `B3-REFERENCE-MODEL` plan | Entry identity, facts, author notes, provenance, relations/backlinks, deep-link sources, validation families, delivery slices, all external outputs |
| `[NMTE-S3]` | Discovery is the closed candidate list; no in-game text field |
| `ICO-1..6` | One pack active at a time, self-contained |
| `UUI-15/16` | Album hold; the pack theme boundary |
| `[DSX-S10]`/`[DSX-S14]` | The Compact chain and its context line |
| `EPUX-02`/`EPUX-07` | The availability and reason vocabulary this surface is **exempted** from (`F4`) |
| `[CSA-13]`/`[CSA-14]`/`[CSA-15]`/`[CSA-26]` | Attribution channel; live-animated art; the third visual region; native-vs-contextual colour (`F7`) |
| `[L10N-3]`/`[L10N-9]`/`[L10N-10]`/`[L10N-15]` | Pack-owned locale catalogues, untranslated IDs, keyed note bodies, locale-to-asset mapping (`F8`) |
| `[CRD-1]`/`[CRD-2]`/`[CRD-6]`/`[CRD-9]` | Structured notices as source of truth; engine + active pack + active theme; non-suppressible attribution; draft-warns/release-fails |

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

> **Caveat added 2026-08-15 (`F7`).** Every frame in the proof set was drawn with **two** entry
> regions. `[CSA-15]` makes it three, so the 520-px shape-B entry pane was measured against an
> incomplete layout. The ruling itself probably survives — B's gain is horizontal and an art
> region costs vertical space — but `[CMP-S3]` should be re-checked against a three-region entry
> before the album is drawn. Asked as `CMP-16`.

## 5. Walk order

`CMP-17` (what discovery **is**) → `CMP-1..4` (shape and navigation, of which `CMP-1` is
pre-ruled) → `CMP-5..7` (discovery policy, where `CMP-6` is the one with no cheap answer) →
`CMP-8..9` + `CMP-19` (deep links and their resolver) → `CMP-10..12` + `CMP-16` (entry content and
the visual region) → `CMP-13..15` (scope, album, persistence) → `CMP-18`, `CMP-20`, `CMP-21`
(durability, naming, the credits channel).

**Two out-of-position questions to take early.** `CMP-17` now leads the walk: `CMP-5..7` decide
policy for a mechanism it defines, and deciding the policy first is how a register produces
rulings nobody can implement. `CMP-6` keeps its old promotion — it constrains the exporter and
the validator, not just the screen — and is now joined by `CMP-18`, the other question that can
produce a save-visible inconsistency.
