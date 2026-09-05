---
Role: dated
Type: register
Status: RESOLVED — CMP-1..22 ruled at the owner walk 2026-08-15; cross-system follow-up ruled 2026-08-31 in [CMP-S21]-[CMP-S31]. ALBUM APPROVED 2026-08-16, so UBS-7 has lifted
Last verified: 2026-08-31
Register: CMP-1..22
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
them. What the corrections **left open** became section **A**, `CMP-16..22`, placed at the top
because those were the questions with no answer anywhere.

**The walk ran 2026-08-15 and closed the register.** All twenty-two are ruled — see *Rulings*
below. The questions are kept in full, with their options and measurements, because a ruling that
records only its answer loses the reason it was not one of the others.

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
  - **Re-measured 2026-08-15 and CONFIRMED.** The original frames were drawn with a two-region
    entry, so the substrate review re-measured shape B with `[CSA-15]`'s visual region present
    (proof set §4, on a class — the surface `CSA` names). **Expanded absorbs it entirely:** the
    entry pane's extent goes 402 → **509 px in a 986 px pane**, still fitting with 477 px to
    spare. The cost is *vertical* and shape B's gain was *horizontal*, so the region cannot
    reopen the A-versus-B choice. **`[CMP-S3]` stands as ruled; no re-decision is owed.** What the
    re-measure did surface is a **Compact** number — 2.3 → **2.83 screens** — which is `CMP-16`.

---

## Rulings — owner walk, 2026-08-15 (`S8`)

`CMP-1..22` are all resolved. Seventeen rulings, `[CMP-S4]`–`[CMP-S20]`. Three owner answers
**reversed or reframed the recommendation** and are marked; two of those changed a ratified
premise rather than picking an option.

### Discovery

- **`[CMP-S4]` — `CMP-17` → C. Discovery is encounter-by-default with an authored override.**
  Seeing a unit/item/terrain in play discovers its entry; campaign rules may also name an explicit
  condition per entry, on the existing requirement-predicate substrate. **Build the authored half
  first** — it is the cheap half, and encounter then lands as a default predicate on top rather
  than as a second mechanism. This is the question `CMP-5..7` were resting on and it did not
  exist anywhere before this walk.
- **`[CMP-S6]` — `CMP-18`+`CMP-7` → discovery is scoped to the RUN, not the save. REFRAMED BY THE
  OWNER; the register's own recommendation was wrong.** `[CL-SAVE-01]` already defines the tiers:
  *"Campaign → Run → Save. A run is one playthrough bound to a chosen rule profile and **its
  cumulative progress**; a save is a recovery point inside a run."* Discovery **is** cumulative
  progress. Per-save would have meant **loading an earlier recovery point un-discovers entries** —
  rewinding deleting knowledge the player actually has.
  - **Carry-over rides the existing status record.** `CampaignStatusRecord`/`CampaignStatusStore`
    are already implemented and are explicitly *"a cross-campaign continuity artifact … not a
    resumable save"* — the exact role. **The player ticks a box at import**; discovery then
    carries for any entry ID that **matches, or has a mapped destination**.
  - **"Mapped destination" is the plan's existing migration mechanism**, generalized from
    within-pack renames to cross-pack succession — *not* a second mapping system. A sequel author
    maps `oldpack:item:iron_sword → newpack:item:iron_sword` and inherited discovery lands.
  - **Unmatched, unmapped IDs are dropped silently and that is not an error.** `[ICO-1..6]` makes
    packs self-contained, so a record from campaign A necessarily carries IDs campaign B never
    defines. Failing on them would make the validator reject correct packs.
  - **Discovery is one engine-known key whose contents are content IDs** — the same shape as
    `counters`, so it stays inside *"no story fact becomes an engine field"*. A per-entry engine
    field would not.
  - **It stays player-editable.** The record's checksum *"detects corruption, **not** tampering →
    fun continuity, not competitive integrity."* Unlocking your own encyclopedia early is
    self-inflicted; do not harden this later.
  - **The ID-migration obligation survives**, binding run state instead of save state.
- **`[CMP-S12]` — `CMP-6` → B. A related link to a hidden entry is OMITTED entirely.** Binding
  constraint: the omission is a **presentation filter over a complete graph, never a hole in the
  semantic document**. The validator fails activation on unresolved references, so if hiding
  reached the document, discovery state would become an export input and the validator would begin
  failing on correct packs. Accepted cost: the same entry renders differently in two runs.
  - *Narrowed by `[CMP-S4]`:* with encounter-default discovery, a player who has **seen** the
    thing already has it. The dangling case is genuinely-unseen, story-gated content — which is
    where the spoiler risk was highest anyway.
- **`[CMP-S13]` — `CMP-5` → exports are complete by definition.** Confirms the plan's *"without
  deleting facts from author/full exports"* and goes further: a player-facing export profile, if
  ever wanted, is a **filter over a complete document, never a different document**. Otherwise
  discovery becomes an export input and two authors exporting the same pack get different guides.

### Shape, navigation and content

- **`[CMP-S5]` — `CMP-16` → C for presence, B for placement, and the Compact cost is accepted.**
  Art sits under the title above facts; the region is **absent entirely** on entries with no art
  (stats, formulas, rules — the majority). Compact pays **2.3 → 2.83 screens**. An entry is a
  reading surface, it was already a scroll, and a collapsed-by-default sprite on the one screen an
  author uses to check their sheet is the wrong default.
- **`[CMP-S9]` — `CMP-2` → A. A true back/forward history stack**, over both chain steps and link
  jumps. The affordance nothing else in the programme has; `[DSX-S13]`'s step-back and
  `[TSV-24]`'s preservation are different mechanisms and neither is this.
- **`[CMP-S10]` — `CMP-3` → back always, forward only where the size class has room**, and never
  as the only path to anything.
- **`[CMP-S11]` — `CMP-4` → horizontal scroll, active category always scrolled into view.**
  Inherited from facets rather than invented, since `[CMP-S3]` made categories facets.
- **`[CMP-S14]` — `CMP-8`+`CMP-9` → ALWAYS NAVIGATE, and the return must be ACCURATE. OWNER
  REVERSED the recommendation** (a caller-dependent rule) after review. One behaviour everywhere;
  the entry always gets full room.
  - **The return restores the caller's state, not merely the caller's screen** — selection, cursor,
    open panel and scroll. This is the owner's binding qualifier and it is stronger than `CMP-9` as
    written; it is `[TSV-24]`/`[DSX-S13]`'s restore-focus obligation applied to an excursion.
  - **Consequence: navigating mid-battle must preserve battle state exactly.** The compendium is
    not a save point. A terrain or skill deep link is a full context exit and back.
  - Does **not** collide with `[DSX-S16]`, which governs the on-map *distribution* surface.
  - Measured context for the rejected options: the Compact entry needs **604 px of extent** with
    the visual region against a **352 px** on-map band, so an in-place panel scrolls ~2 screens
    anyway. In-place is cheap at Expanded and cramped at Compact — the opposite of the intuition.
- **`[CMP-S15]` — `CMP-10` → identical for rules and notes; art deliberately differs.** A second
  layout for the same two boxes is how the programme grows a second vocabulary. Region 3 cannot
  match: `[CSA-26]` requires native unswapped colours plus a swap enumeration here, where More
  Info shows the context-resolved variant. **The difference is ruled, not accidental.**
- **`[CMP-S17]` — `CMP-15` → state survives, history does not.** Category, facets, focused entry
  and scroll survive recomposition and input change (`[TSV-24]`/`[DSX-S13]`); the history stack is
  **session-scoped**, matching `[CEUI-S6]`'s editor history rather than inventing a third
  retention policy.

### Identity, provenance and scope

- **`[CMP-S8]` — `CMP-20` → the screen is the COMPENDIUM**, and authors may rename the label
  through translation data — scoped to **a declared, narrow list of overridable engine chrome
  keys**. The narrow list is what keeps `[L10N-3]`'s *"the engine translates chrome only"* true by
  construction: the engine still owns the key and its fallback, the pack supplies one value. **A
  general chrome-override capability is NOT granted** — a pack may not rename Save, Quit, or an
  error message.
- **`[CMP-S16]` — `CMP-11`+`CMP-12`+`CMP-21` → a provenance-display setting governs the ENTIRE
  in-game compendium, with a per-campaign author default. OWNER REFRAMED the question.** The
  register offered a dev-mode gate; the answer is a real setting, which is also the **view-time
  profile the substrate review found missing** — the plan's `none`/`summary`/`full` are export
  parameters only.
  - **The export always has everything** (`[CMP-S13]`).
  - **No pack/version line in the app bar** (`CMP-12` → "not shown"). Pack identity, when shown at
    all, appears in the entry under the setting.
  - **The setting may go to zero without a `[CSA-13]` regression, because the compendium is not
    the attribution channel.** `[CRD-3]` already ruled Credits reachable from the Main Menu **and
    in-campaign Settings**, rendering the same screen from engine + active-pack + active-theme
    notices (`[CRD-2]`). That always-reachable screen is where required attribution lives — which
    is exactly the separate, non-suppressible channel `[CSA-13]` was ruled to get.
  - **So `CMP-21` resolves to "not a second channel at all."** One attribution channel (Credits);
    the compendium carries optional provenance under the setting. Both read the same structured
    notices (`[CRD-1]`) so they cannot drift.
- **`[CMP-S18]` — `CMP-13` → confirmed, with both consequences recorded.** The screen exists only
  inside a campaign and `[UUI-16]` puts it inside the pack theme boundary. **There is no no-pack
  empty state to design, and the main menu gains no compendium entry.** `[UBS-7]`'s
  chrome-versus-pack-themed line is **dissolved, not answered**.

### Delivery

- **`[CMP-S7]` — `CMP-19` → one shared resolver; callers pass a definition-level entry ID.** Never
  construct the ID at the call site. `[TSV-11]` commits *instance* IDs while entries describe
  *definitions*, so a forged, half-broken Iron Sword resolves to `pack:item:iron_sword` through one
  place. The plan's registry will grow the caller list, so the **resolver** is what must be single,
  not the enumeration.
- **`[CMP-S20]` — `CMP-22` → the `art_asset` fact kind lands in Slice 1; the visual region lands in
  Slice 2.** The kind ships with every other kind in the semantic foundation, so the vocabulary is
  never incomplete and no consumer works around a hole; the region ships with the More Info surface
  that first draws one. Splits along the existing producer/consumer line. **The plan's Slice 2 note
  is owed this edit.**
- **`[CMP-S19]` — `CMP-14` → a FULL album pass, every state — not just the proof frames. OWNER
  EXPANDED the recommendation.** Empty states, deep-link arrival, the setting levels, the visual
  region present and absent, facet overflow. `[UBS-7]` lifts on **album approval** per `[DSX-S29]`,
  the same standard as `UBS-6` and `UBS-8` — not on this walk closing.

---

## Cross-system follow-up — owner walk, 2026-08-31

This walk closes `COMPENDIUM-COMPLETION-DENOMINATOR-2026-08-30`. It jointly reviewed the
Compendium, Campaign Journal and the implemented `CampaignStatusRecord`, then replaced the
terminal-single-record assumption with a collection-of-run-records contract. These rulings amend
`[CMP-S6]`, `[CMP-S13]`, `[CJ-S8]` and `[CJ-S26]` where named; the older text remains above so the
change in reasoning is visible.

- **`[CMP-S21]` — every authored quest/journal entry has a Compendium section or subsection.**
  The systems share stable definition ids and deep-link to one another, but remain distinct
  records with distinct lifecycles. The Journal records what happened in the current timeline
  (offered, activated, updated, completed, failed, expired or withdrawn). The Compendium owns the
  durable reference page saying the quest exists and progressively reveals or updates authored
  sections as the quest line proceeds. A completed Journal record does **not** graduate out of
  history and the Compendium is not another Journal view. One event may commit a Journal
  transition and reveal a Compendium section through the shared id binding.
- **`[CMP-S22]` — Compendium discovery is run-owned and cumulative; Journal history remains
  save-timeline-owned.** Each run tracks its own discovered entry and subsection ids, including the
  active run. Loading an earlier save may rewind Journal lifecycle/history under `[CJ-S18]`, but
  does not unlearn Compendium knowledge accumulated by the run. A run record carries both its
  effective discoveries (everything this run can show, including inherited knowledge) and the
  subset discovered through this run's play, so exporting that record alone preserves the
  beginning/partial Compendium without falsely attributing inherited knowledge to this run.
- **`[CMP-S23]` — player exports gain discovered and spoiler-aware profiles. AMENDS
  `[CMP-S13]`, not its complete-document invariant.** A discovered export filters presentation to
  discovered material and reports coverage. A spoiler-aware export contains the complete semantic
  document, visibly distinguishes discovered from undiscovered entries/sections and permits an
  intentional reveal. Interactive HTML uses click-to-reveal; PDF/GFM use an explicit spoiler or
  redacted presentation because they cannot reproduce that interaction reliably. Author/full
  export remains complete without player-state filtering. The denominator belongs to this
  deliberately spoiler-aware export, not the ordinary Journal or in-game discovered-only view;
  coverage may be reported for the exported category and quest-line sections.
- **`[CMP-S24]` — cross-run continuity is a collection of immutable exported run records. AMENDS
  `[CMP-S6]` and supersedes `[CJ-S26]`'s terminal-only restriction.** The engine-level status store
  holds many run records and derives a materialized union of the records relevant to a campaign.
  A run may export at a safe boundary before completion, including an abandoned or partial run;
  such a record may contribute knowledge and explicitly portable facts but cannot claim terminal
  campaign/route completion. Completed and abandoned records coexist. The Journal itself is never
  copied into a status record.
- **`[CMP-S25]` — every fresh export of the active run is a separate record with a fresh
  `export_id`; there is no revision lineage.** Separate exports of the same `run_id` remain
  separate inputs and resolve through the standard union rules. Import deduplication uses only
  `export_id`: an already-present id is an idempotent no-op, while the same id with different bytes
  is corruption/collision and is refused. Re-exporting a previously imported record preserves its
  original id and provenance. A bulk-transfer container may have its own bundle id, but never
  rewrites ids of contained records.
- **`[CMP-S26]` — union is materialized when inputs change, never re-derived during ordinary
  Compendium navigation.** The compact index contains discovered entry/subsection ids, completed
  quest/route ids, contributing export ids, schema version and a source-set fingerprint. Import,
  migration or removal atomically rebuilds/updates it; entry rendering performs direct membership
  reads. Individual run records remain the provenance authority and can recreate a missing or
  corrupt cache. A backup/export may carry the cache as acceleration only; import verifies or
  discards it rather than trusting it as authority.
- **`[CMP-S27]` — New Game imports status records from the engine collection into the run,
  defaulting to every compatible record.** Setup scans sources the campaign declares compatible,
  selects all by default and permits player deselection. Selected records plus their resolved union
  become part of the campaign save envelope. The run thereafter has no live dependency on the
  engine-level originals: deleting or changing those affects later New Game scans, not this run.
  External records are validated at import; after incorporation the save is authoritative. The
  engine owes no recovery semantics for a player who manually corrupts or inconsistently edits
  that save: validation may fail hard and abort load.
- **`[CMP-S28]` — mid-game imports append to the run but cannot rewrite its past.** At the next
  named safe campaign boundary, compatible imported records and the updated union are committed
  atomically into the save. They do not add retroactive Journal events, change prior outcomes or
  replay one-time New Game gold/items/units/other start benefits. They may reveal Compendium
  knowledge and satisfy requirements that open activities or actions. Those openings enter the
  Journal only through their ordinary new committed transitions at import time. Imported knowledge
  and openings are monotonic for that run; later removal from the engine collection cannot revoke
  them.
- **`[CMP-S29]` — authors have full structured read access to explicitly accepted sources.** A
  campaign declares accepted stable pack/campaign ids, optionally with versions. Its queries may
  read the complete validated public run-record shape from those sources: completion/abandonment,
  discoveries, routes, facts, counters, source/run/export ids, timestamps and future
  schema-declared portable fields. This does not grant filesystem, save, Journal-history or
  undeclared-campaign access. An undeclared selector is an authoring error; a declared source with
  no records yields an empty result.
- **`[CMP-S30]` — the bounded query vocabulary is `present`, `min`, `max`, `sum`, `count`,
  `count_distinct`, `contains`, `any`, `all`, `latest` and `earliest`.** Queries may address raw
  accepted records or their resolved union and explicitly select `exports`, `runs` or `union`
  scope: separate exports, distinct playthroughs or distinct resolved values are different
  questions. Grouping several exports by run requires an explicit inner reducer such as `max`;
  export frequency must not silently multiply gameplay benefits. Numeric fields declare their
  union policy because set union is correct for discovery/completion ids but not for counters.
  Missing numeric values do not participate; empty queries produce `present=false`, zero counts
  and no min/max/latest/earliest value. Wrong types and overflow fail rather than coerce.
- **`[CMP-S31]` — run-start and live legacy projections are separate.** `run_start_legacy` freezes
  the New Game selection and alone owns initialization benefits. `current_legacy` includes later
  imports and owns Compendium knowledge and live availability. This is the structural reason a
  mid-game import can open an activity without retroactively granting a start bonus. Both
  projections are saved; neither is reconstructed by scanning the external collection on load.

---

## A. Substrate decisions — TAKE THESE FIRST

`CMP-1..15` (sections `B`–`F` below) were authored against the plan as written. Reviewing the plan
against every ruling that post-dates it surfaced one ratified register that binds it (`CSA`,
closed **2026-07-31 — one day after the plan**) and six things those questions assume but nothing
specifies. The already-ruled half is corrected directly in the plan; what is left is here.

**These lead the register because they have no answer anywhere** — not in the plan, not in a
ruling, not in a frame. Several of them constrain questions further down, so taking those first
risks deciding policy for mechanisms that do not exist. `CMP-17` is the clearest case and should
be the first question of the walk.

### [CMP-16] Does the compendium have a visual region, and where?  
**RESOLVED — `[CMP-S5]`.**

`[CSA-15]` makes More Info **three** regions — rules, notes, and a **visual** region fed by
`art_asset` facts. `[CSA-14]` requires the in-game compendium to **animate art live**.
`[CSA-26]` requires the compendium to show the asset in **native, unswapped colours plus a swap
enumeration**, where More Info shows the context-resolved variant. None of that reached
`CMP-1..15`. The proof set now draws it (§4, added by the substrate review) and **the re-measure
is done** — it clears `[CMP-S3]` and leaves one live question, at Compact.

**Measured 2026-08-15**, shape B, class entry, visual region present:

| Viewport | Entry pane | Two regions | Three regions |
|---|---|---|---|
| Expanded 1920 | 520 × 986 | ext 402 px, fits | ext **509 px, fits** (477 px spare) |
| Compact 360 | 360 × 213 | ext 489 px, 2.3 screens | ext **604 px, 2.83 screens** |

- **A — A third region in the entry pane**, below facts, above or below notes.
- **B — Art is the entry's header**, with facts and notes beneath — the archetype a wiki uses.
- **C — Art only where the entry kind has it**, with the region absent otherwise.
- **Recommendation: C for presence, B for placement.** Most entries — a stat, a formula, a
  requirement, a rule — have no art at all, so a permanently reserved region is dead space on the
  majority of them; but where art exists it is the fastest identifier on the page and belongs at
  the top. Expanded settles nothing here because it absorbs the region without noticing it.
- **The real question is Compact**, where the region costs **+115 px on a 213 px window** and
  pushes the entry from 2.3 to 2.83 screens. Three ways to spend that: accept it (art is worth a
  scroll), collapse it to a thumbnail that expands on demand, or drop the visual region at Compact
  and let `[CSA-14]`'s live animation be an Expanded-and-HTML capability. **Recommendation:
  accept it** — 2.3 screens was already a scroll, an entry is a reading surface rather than an
  action surface, and a collapsed-by-default sprite on the one screen an author uses to check
  their sheet is the wrong default. But this is a genuine spend and is drawn so the cost is
  visible.

### [CMP-17] What *discovers* an entry? **No mechanism exists anywhere.**  
**RESOLVED — `[CMP-S4]`.**

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
**RESOLVED — `[CMP-S6]`.**

If discovery is per-save (`CMP-7`'s recommendation), the save must persist *which entries* are
discovered — and it can only key that on the entry ID. The plan's ID-stability rule is written
for **renderers**: *"retain redirects only when an explicit migration maps an old ID to a new
ID."* Saves need the same guarantee, and nothing says so.

- **Recommendation: yes — state it, and inherit the renderer's migration rule.** This is exactly
  `[L10N-9]`'s reasoning ("registry IDs are never translated… forced by save durability and
  cross-reference stability") applied to a case nobody has applied it to. Without it, an author
  renaming a local ID silently un-discovers content in every existing save.

### [CMP-19] How does a deep link resolve a runtime object to an entry?  
**RESOLVED — `[CMP-S7]`.**

`CMP-8`/`CMP-9` decide what "Open Reference" *does*; nothing decides what it is *given*. The plan
lists five deep-link **sources** but never the mapping, and the ambiguity is real: `[TSV-11]`
commits exact **instance** IDs, while an entry describes the **definition**. An inventory slot
holding a forged, half-broken Iron Sword must resolve to `pack:item:iron_sword`.

- **Recommendation: callers pass a definition-level entry ID, resolved through one shared
  helper** — never construct the ID at the call site. The plan's own registry will grow the
  caller list (`CMP-8`), so the resolver is the thing that must be single, not the enumeration.

### [CMP-20] What is the compendium actually called?  
**RESOLVED — `[CMP-S8]`.**

The plan says the name *"should be **Reference** or **Compendium** unless later tone work selects
'Wiki'"* — and no ruling has ever picked one. Every document since has used all three informally.
`[L10N-2]` now makes it a chrome message ID, so it is one key with one English value.

- **Recommendation: pick one now, at the walk.** It is a one-line decision that is embarrassing
  to still be carrying at implementation, and the register, the plan, the tracker row and the
  album all currently disagree.

### [CMP-21] Is the compendium's pack line the credits channel, or a second one?  
**RESOLVED — `[CMP-S16]`.**

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

### [CMP-22] Which slice builds the art facts? **Sequencing, and it gates this screen.**  
**RESOLVED — `[CMP-S20]`.**

`[CSA-15]`/`[CSA-14]`/`[CSA-26]` all depend on an `art_asset` fact kind that **post-dates the
plan's delivery breakdown**, so no slice owns it. It is not optional detail: unknown fact kinds
**fail** strict exports, so until it exists the compendium cannot legally render a sprite, and
`CMP-16` has nothing to place. Slice 2 (More Info) wants it for the visual region, Slice 6 (the
compendium) and Slice 7 (HTML) both consume it, and it depends on the `[CSA-4]` art catalogue.

- **A — Fold into Slice 1** (the semantic foundation), as one more exported kind.
- **B — Fold into Slice 2**, with the More Info region that first displays it.
- **C — Its own slice between 1 and 2**, gated on the `[CSA-4]` catalogue.
- **Recommendation: A for the fact kind, B for the rendering.** The *kind* belongs with every
  other kind in the foundation, or the vocabulary ships incomplete and every consumer works around
  the hole; the *region* belongs with the surface that first draws one. C invents a slice for what
  is really two lines in two existing ones. **Whichever is chosen, the plan owes an edit** — it
  currently flags this as unassigned rather than answering it.

## B. Shape and navigation

### [CMP-1] Which composition? — **PRE-RULED `[CMP-S3]`: B.**  
**RESOLVED — `[CMP-S3]`.**
Kept in the register so the rejected option and its measurement are not lost. Revisit only with a
frame, not an argument.

### [CMP-2] What does the back arrow mean?  
**RESOLVED — `[CMP-S9]`.**

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
**RESOLVED — `[CMP-S10]`.**

Back is unambiguous; forward only has meaning after a back, and it costs a target in a 360-px app bar
that also carries a title and a pack identity.

- **Recommendation: back always, forward only where the size class has room** — and never as the
  only path to anything. Drawn with both in the proof set so the cost is visible.

### [CMP-4] How does the facet row behave when categories overflow?  
**RESOLVED — `[CMP-S11]`.**

Eight categories is more than `UUI-19` fitted in a 524-px landscape rect.

- **Recommendation: horizontal scroll, as facets already do**, with the active category always
  scrolled into view. This is the known behaviour rather than a new one; recorded because
  `[CMP-S3]` makes categories facets and therefore inherits it.

## C. Discovery

### [CMP-5] Does the discovery policy apply to the exported reference? — **partly answered**  
**RESOLVED — `[CMP-S13]`.**

The plan already says visibility policy applies *"without deleting facts from author/full exports."*

- **Recommendation: confirm and go further** — exports are complete by definition, and a
  player-facing export profile (if one is ever wanted) is a **filter over a complete document**,
  never a different document. Otherwise discovery state becomes an export input and two authors
  exporting the same pack get different guides.

### [CMP-6] What happens to a related link that points at a hidden entry? **Take this early.**  
**RESOLVED — `[CMP-S12]`.**

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
**RESOLVED — `[CMP-S6]`.**

Discovery is progress, so it is save state — but the compendium is reachable from a campaign that
has several saves.

- **Recommendation: per-save**, alongside the rest of campaign progress, and stated as such in
  `S12`'s settings-scope review rather than invented here. Flagged because `[CMP-S2]` is the first
  ruling in the programme that makes a **screen's content** depend on save state.

## D. Deep links

### [CMP-8] Does "Open Reference" navigate away or open in place?  
**RESOLVED — `[CMP-S14]`.**

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
**RESOLVED — `[CMP-S14]`.**

- **Recommendation: the caller, always, as the first entry in the compendium's own history.** A
  deep link that dumps the player at the compendium's root has lost the thing they were reading
  about.

## E. Entry content

### [CMP-10] Does the compendium reuse the More Info layout? — **amended 2026-08-15, see `CMP-16`**  
**RESOLVED — `[CMP-S15]`.**

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
**RESOLVED — `[CMP-S16]`.**

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
**RESOLVED — `[CMP-S16]`.**

- **Recommendation: yes, in the app bar**, as drawn. It is the one line that makes every other line
  interpretable, and `ICO-1`'s one-active-pack model means it is never ambiguous.

## F. Scope, album, persistence

### [CMP-13] Campaign-scoped and pack-themed — confirm the consequences  
**RESOLVED — `[CMP-S18]`.**

Owner 2026-08-15: the out-of-campaign reference is the **exported** artifact, so the screen exists
only inside a campaign and `UUI-16` puts it inside the pack theme boundary (diff `F3`).

- **Recommendation: confirm, and record the two consequences** — there is no no-pack empty state to
  design, and the main menu gains no compendium entry. The `[UBS-7]` must-settle line that asked
  chrome-versus-pack-themed is **dissolved**, not answered.

### [CMP-14] What does the compendium contribute to the wireframe album?  
**RESOLVED — `[CMP-S19]`.**

- **Recommendation: the six proof-set frames plus a Medium landscape frame**, drawn to the rulings
  after the walk. `UBS-7` then lifts on **album approval**, per `[DSX-S29]` — the same standard as
  `UBS-6` and `UBS-8`.

### [CMP-15] What survives leaving the compendium?  
**RESOLVED — `[CMP-S17]`.**

- **Recommendation: extend `[TSV-24]`/`[DSX-S13]`** — category, facets, focused entry and scroll
  survive recomposition and input change. **History does not survive exit**: a session-scoped stack,
  matching `[CEUI-S6]`'s session-scoped editor history rather than inventing a third retention
  policy.

---

## What the walk produced

1. **Section `A` justified the reorder.** The six substrate questions produced the walk's three
   most consequential rulings — `[CMP-S4]` (a discovery mechanism that existed nowhere),
   `[CMP-S6]` (run scope, which corrected a ratified-adjacent assumption) and `[CMP-S16]` (a
   view-time provenance profile the plan never had). Taking `CMP-5..7` first would have decided
   policy for a mechanism that did not exist.
2. **Two owner answers overturned the register's own reasoning, not just its recommendation.**
   `[CMP-S6]` replaced per-save with run scope by citing `[CL-SAVE-01]`'s existing definition —
   the register had conflated a run with a save. `[CMP-S16]` replaced a dev-mode gate with a real
   setting and, by moving attribution onto `[CRD-3]`'s always-reachable Credits screen, made
   `CMP-21` dissolve rather than resolve.
3. **`[CMP-S14]` reversed the recommendation after review** and added a qualifier stronger than
   the question asked: the return must restore the caller's **state**, not its screen.
4. **Three rulings constrain code outside this screen** and must not be treated as presentation:
   `[CMP-S4]` (predicate substrate), `[CMP-S6]` (run state, status-record carry-over, ID
   migration) and `[CMP-S20]` (delivery slices).
5. **`[CMP-S3]` held** under re-measure. The visual region costs 107 px in a 986 px pane at
   Expanded; the number that survived is Compact's 2.83 screens, ruled acceptable by `[CMP-S5]`.

## What is owed next

- **The plan** takes the consequences of `[CMP-S4]`, `[CMP-S6]`, `[CMP-S7]`, `[CMP-S8]`,
  `[CMP-S14]`, `[CMP-S16]` and `[CMP-S20]` — the last of which finally assigns the `art_asset`
  slice the substrate review flagged as unassigned.
- ~~**The album** is a full pass, every state (`[CMP-S19]`).~~ **DONE — drawn 2026-08-16 and
  APPROVED by the owner the same day, so `UBS-7` has LIFTED** (`[DSX-S29]`'s standard).
  [`compendium_album.html`](../wireframes/albums/compendium_album.html), nine sections over the six
  ratified viewports. Two frames draw an *absence* on purpose: the no-pack state that `[CMP-S18]`
  makes impossible, and the rejected in-place deep-link panel with the geometry that killed it.
- **`IMPL-REFERENCE-COMPENDIUM`** gains the ruled scope; its text-entry prerequisite was already
  discharged by the substrate review.
- **A declared list of overridable engine chrome keys** (`[CMP-S8]`) is new engine surface and
  needs an owner: it is `L10N` work, not compendium work.
