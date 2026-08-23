---
Role: dated
Type: plan
Status: Planned — approved architecture; implementation not started. Corrected 2026-08-15 for later rulings, and carries the CMP-1..22 walk outcome (see Corrections Folded In)
Last verified: 2026-08-16
Tracker: B3-REFERENCE-MODEL, IMPL-REFERENCE-MODEL-FOUNDATION, COMPENDIUM-2026-08-15
---

# Generated Reference Model, More Info, And Pack Guide — Implementation Plan

## Corrections Folded In (2026-08-15)

This plan was written 2026-07-30 and approved as architecture. It is **not frozen**
(`DOC-014`): where a later owner *ruling* collides with a plan sentence, the ruling wins and
the plan is corrected here. Applied during the `S7`/`S8` compendium substrate review:

| Ruling | Date | What changed below |
|---|---|---|
| `[CSA-13]` | 2026-07-31 | Attribution is a **separate, non-suppressible channel**, not a provenance field. The `none` profile no longer strips it. |
| `[CSA-15]` | 2026-07-31 | More Info is **three** regions, not two — art is a fact, but gets its own visual region. |
| `[CSA-14]` | 2026-07-31 | Art facts added to the vocabulary; the in-game compendium **and** the HTML output animate live, GFM/PDF keep still frames. |
| `[CSA-26]` | 2026-07-31 | Reference/compendium art renders in **native, unswapped colours** plus a swap enumeration; More Info renders the context-resolved variant. |
| `[L10N-3]`/`[L10N-9]`/`[L10N-10]` | 2026-08-13 | Packs ship their own locale catalogues; IDs are never translated; **author-note bodies are keyed**, not raw strings. |
| `[L10N-15]` | 2026-08-13 | Localized assets use an explicit locale-to-asset mapping, not filename encoding. |
| `[CRD-6]`/`[CRD-9]` | 2026-08-13 | Required attribution can never be suppressed; a missing required notice **fails** release/public export. |
| `[CMP-S1]` | 2026-08-15 | In-game discovery is the closed candidate list — no in-game search field. **The static HTML full-text search is untouched and remains ratified.** |
| `[CMP-S2]` | 2026-08-15 | Undiscovered entries are **hidden**, a named exception to the `EPUX-02`/`RPD-15` availability vocabulary. |
| `[CMP-S4]`–`[CMP-S20]` | 2026-08-15 | The `S8` owner walk. Discovery mechanism and scope, the entry resolver, the view-time provenance setting, the screen's name, and the `art_asset` slice assignment — all previously unspecified. |

Those gaps were then **walked and closed** on 2026-08-15:
[`compendium_open_questions_2026-08-15.md`](../registers/compendium_open_questions_2026-08-15.md)
is `RESOLVED`, `CMP-1..22`, rulings `[CMP-S1]`–`[CMP-S20]`. Their consequences are written into
the sections below — discovery, run scope and carry-over, the entry resolver, the provenance
setting, and the `art_asset` slice assignment.

## Outcome

Project Prometheus has one structured, provenance-carrying description of pack
content and engine-owned rules. The same semantic reference entries drive:

- live **More Info** factual panels;
- a separate author-authored notes panel for flavor, lore, and tactical advice;
- a cross-linked GitHub-Flavored Markdown reference folder;
- one cross-referenced PDF for readers who prefer a conventional document;
- a later static HTML reference and search index;
- a later in-game Reference/Compendium menu; and
- editor previews, validation, and export actions.

The pack resources, activated registries, and runtime resolvers remain authoritative.
Markdown, HTML, PDF, and displayed prose are renderings, never independent rule
sources. Adding an author-extensible rule or effect is not done until its registered
handler can validate its parameters and emit structured reference facts with safe
provenance.

## Placement And Dependencies

`B3-REFERENCE-MODEL` is a late-Band-3 enabling track. Its first implementation
slice follows the narrow `B3-CAMPAIGN-RULES` profile foundation, so the selected
ruleset and defaults can appear in provenance, and precedes `B4-PXP`, so proficiency
access, trainability, and EXP multipliers implement the reference contract rather
than being retrofitted.

The dependency direction is:

```text
B3-CAMPAIGN-RULES + activated pack/registry identity
                         |
                         v
              B3-REFERENCE-MODEL foundation
                 |            |             |
                 v            v             v
              B4-PXP       B4-IEQ      later registries
                 \            |             /
                  +---- semantic entries ---+
                              |
                 +------------+-------------+
                 v            v             v
             More Info    GFM/PDF       Compendium
```

The external renderer can begin after the foundation and one non-trivial consumer
(`B4-PXP`) prove floors, multipliers, source contributions, and cross-links. The
in-game compendium belongs after PXP and the first skill-effect conversion. Editor
integration remains later; the editor consumes this system and does not own it.

## Architectural Boundaries

### Engine-side authority

Godot and the activated content session own:

- pack discovery, activation order, identity, and source-relative paths;
- entity schemas, defaults, inheritance/composition, and reference validation;
- registry handler selection and parameter interpretation;
- semantic fact extraction from the same definitions runtime uses;
- resolved live values for a subject/context;
- provenance collection and safe redaction; and
- export of a versioned, deterministic semantic document.

The extractor must use the normal candidate-catalogue and activation path. A second
Python/JavaScript implementation of pack loading, defaults, formulas, or effect
resolution is prohibited because it would become a divergent second engine.

### External presentation tooling

A small sidecar tool consumes the exported semantic document and owns:

- folder and page organization;
- GFM rendering, stable anchors, indexes, and backlinks;
- combined-document rendering;
- HTML templates, CSS, search indexes, and optional diagrams;
- PDF conversion and pagination;
- output link/asset validation; and
- release packaging of generated references.

Start this renderer under `tools/reference_builder/` in the main repository so the
producer schema and consumer are tested together. It may move to a separate project
only after it has an independent audience or release lifecycle. Campaign packs do
not carry their own generator copies.

### In-game rendering

The live game consumes semantic entries directly; it does not parse generated
Markdown or HTML. The future compendium and More Info share render helpers and link
targets, while remaining native Godot UI.

## Semantic Reference Document

The headless exporter produces deterministic UTF-8 JSON. The root contract begins:

```json
{
  "schema": "prometheus-reference-model",
  "schema_version": 1,
  "engine_version": "0.0.0",
  "generator_version": "1",
  "generated_from": {
    "pack_id": "example.pack",
    "pack_version": "1.0.0",
    "content_fingerprint": "sha256:...",
    "rules_profile_id": "developer_default"
  },
  "entries": [],
  "diagnostics": []
}
```

Consumers reject unsupported major schema versions. New optional fields may be
added compatibly within a major version; removing or reinterpreting a field requires
a version change. JSON object keys and arrays use a declared stable order so equal
input produces byte-identical output apart from an explicitly optional timestamp.
The default test/release export omits wall-clock time.

### Stable entry identity

Every entry has a namespaced ID independent of its display name:

```json
{
  "id": "example.pack:skill:vantage",
  "kind": "skill",
  "local_id": "vantage",
  "title": {"text_key": "skill.vantage.name", "fallback": "Vantage"},
  "facts": [],
  "author_notes": [],
  "relations": [],
  "provenance": {}
}
```

IDs, not titles or filenames, own links. Renderers derive collision-safe filenames
and anchors from IDs and retain redirects only when an explicit migration maps an
old ID to a new ID.

### Facts, not sentences

Handlers emit semantic facts rather than finished English:

```json
{
  "fact_id": "weapon_access:sword:ring",
  "kind": "weapon_access",
  "subject": {"ref": "example.pack:item:swordmaster_ring"},
  "values": {
    "track": {"ref": "example.pack:weapon_track:sword"},
    "grants_family_access": true,
    "effective_rank_floor": "C",
    "training": "enabled"
  },
  "provenance": {}
}
```

Renderers select compact, detailed, static-rule, or live-resolved templates. They
must not recover structure by parsing prose. The first vocabulary must cover:

- identity, aliases, categories, tags, and availability state;
- stat definitions, caps, formulas, growths, and active contributions;
- class bases/caps, movement, traits, weapon access, advancement, and skill gains;
- weapon/item stats, requirements, range formulas, uses, effects, and targets;
- skill triggers, conditions, operations, durations, chances, counters, and effects;
- proficiency tracks, stored progress, effective floors, trainability, and gains;
- experience award/multiplier channels;
- terrain costs/bonuses/actions/restrictions;
- requirements with player-facing unmet reasons;
- formula identity/parameters and bounded human-readable rule summaries;
- **art assets** — catalogued sprite/animation/palette-swap references, their native colours,
  their available swaps, and their locale-to-asset mapping (`[CSA-14]`, `[CSA-26]`,
  `[L10N-15]`); and
- relationship facts such as `grants`, `learned_by`, `requires`, `uses`, `targets`,
  `promotes_to`, `effective_against`, `depicted_by`, and `defined_in`.

**Art is a fact, not prose (`[CSA-15]`).** An art asset needs a `kind` to have a stable ID at
all, and unknown fact kinds fail strict exports — so `art_asset` and its `depicted_by` relation
are part of the first vocabulary, not a later addition. Two presentation rules ride on them and
must not be conflated (`[CSA-26]`):

- **More Info** shows the **context-resolved** variant — the sprite as it actually appears now,
  in the current faction's colours. It is a `resolved` fact.
- **The reference/compendium view and every external output** show the asset in its **native,
  unswapped colours**, alongside an enumeration of the swaps that exist for it. Rendering the
  reference in one faction's colours would make an arbitrary context look canonical.

Renderers must not generate one image per variant per asset. The in-game compendium and the
static HTML output animate live; GFM and PDF render a still frame (`[CSA-14]`).

Unknown fact kinds fail in strict author/full exports. Player UI may omit unsupported
optional facts only while surfacing a diagnostic; it may not invent fallback rules.

### Static rule, live value, and example

Facts distinguish three scopes:

- `definition`: context-free rule, such as “maximum range is MAG/2”;
- `resolved`: value under an actual unit/action/context, such as range 1–6; and
- `example`: clearly labelled illustrative inputs and outputs.

Static guides normally show definitions and optional examples. Live More Info shows
definitions plus resolved values and their contribution chain. Examples must never
be presented as authoritative live values.

## Provenance

Provenance is first-class at document, entry, fact, relation, author-note, diagnostic,
and resolved-contribution levels. Supported export profiles are:

- `none`: player-facing content without provenance blocks;
- `summary`: pack/version, resource ID, and important sources; and
- `full`: every safe available content/build/rule/contribution source.

Independent switches may refine those profiles.

### Attribution is not a provenance field (`[CSA-13]`, `[CRD-6]`)

**Required licence attribution travels on a separate, non-suppressible channel**, independent of
the provenance profile above. This corrects a real defect in the 2026-07-30 text: if attribution
rode on provenance, then `none` — the *player-facing* profile — would be exactly the rendering
path that strips it, and for the CC-BY sources already in `Campaign_Pack_0` attribution is a
**licence condition, not a nicety**.

The rules that follow from that:

- No profile, switch, or author setting may suppress a **required** notice. Authors may suppress
  only *optional* provenance narrative (`[CRD-6]`).
- Attribution is surfaced in an always-reachable credits view composed of engine/application
  notices plus the **active** pack and **active** theme (`[CRD-2]`) — never every installed pack,
  which would assert a composition model `[ICO-1..6]` forbids.
- Structured validated notices are the single source of truth and generate both the in-game
  screen and the repo file (`[CRD-1]`). A hand-maintained legal artifact is the `DoD#2`
  anti-pattern.
- Links in notices display the URI with a copy action and open externally only where supported
  and confirmed (`[CRD-7]`).

Whether the compendium's own pack/version line is this same channel or a second one is **open** —
see `CMP-21`. Full provenance should carry, when
available:

- pack ID, version, content fingerprint, and activation priority;
- stable entity ID, kind, schema version, and pack-relative source path;
- source commit/build stamp when supplied by the build environment;
- authored field/component path and component/effect index;
- applied schema defaults and compatibility adapters;
- registry family, handler ID/version, rule/formula/profile ID, and parameters;
- dependency and cross-reference IDs;
- contribution ordering, winning floor/cap/setter, shadowed definitions, and conflict
  resolution;
- active campaign/rules profile and context identity;
- generator/semantic-schema versions; and
- warnings, unsupported facts, and validation diagnostics.

Full resolved provenance should explain results, for example:

```text
Effective Sword rank C
  stored: 0 WEXP / no stored rank
  family access: Mercenary class
  rank floor C: Swordmaster Ring
  training enabled: Swordmaster Ring
  WEXP multiplier x1.5: Discipline
```

Absolute machine paths, usernames, credentials, tokens, private remote URLs, and
environment dumps are never included by ordinary `full` mode. Source paths are
pack-relative. If a local diagnostic export is ever added, it must be explicitly
named, excluded from release artifacts, and scrubbed by tests.

## Author Notes And Safe Formatting

Factual rules and author writing are separate fields. Replace ambiguous future uses
of `description` with structured `author_notes`; retain compatibility adapters for
existing class/item/skill descriptions until packs migrate.

An entry may contain ordered note blocks:

```json
{
  "kind": "strategy",
  "format": "restricted_markdown",
  "body": {"text_key": "skill.vantage.note.strategy", "fallback": "Strong near allies; beware of **effective** weapons."},
  "visibility": "player"
}
```

Initial kinds are `flavor`, `lore`, `strategy`, `tutorial`, and `author`. Unknown
kinds remain displayable as notes rather than changing runtime behavior.

**Note bodies are keyed, not raw strings (`[L10N-3]`, `[L10N-9]`).** This corrects the
2026-07-30 shape, which made author notes structurally untranslatable. A `text_key` plus an
English `fallback` matches the `title` field and follows the ratified model: each pack ships its
own locale catalogues, the engine translates chrome only, and registry IDs are **never**
translated — display keys are always separate fields, because saves and cross-references depend
on ID stability. A pack declares a completeness level per locale and missing keys are reported
rather than silently falling back (`[L10N-14]`). User-authored names are the exception: they
render verbatim with optional authored localized variants, never as lookup keys (`[L10N-10]`).

Use one deliberately restricted Markdown-like AST or token vocabulary, not raw BBCode
and not arbitrary HTML. Supported formatting should initially be paragraphs,
emphasis, strong emphasis, lists, safe internal reference links, and approved image
asset references. No scripts, raw HTML, filesystem links, remote embeds, style
attributes, or arbitrary Godot BBCode tags. Parse/validate once and render safely to
Godot rich text, GFM, HTML, and PDF. Preserve plain-text and screen-reader output.

**An "approved image asset reference" is a catalogued in-pack art ID (`[CSA-14]`)** — never a
path, never a remote URL — resolved through `AssetResolver`. That makes the asset boundary a
*resolution* property rather than a string-validation problem. An animated asset referenced from
a note renders as a still frame in static renderings; live animation is the compendium's and the
HTML output's job, not the note vocabulary's. Localized art uses the explicit locale-to-asset
mapping in the pack catalogue, not locale encoded in filenames (`[L10N-15]`).

## More Info Migration

The live layout becomes **three** conceptually separate regions (corrected from two by
`[CSA-15]`):

1. **Rules and active values** — entirely generated from semantic facts and resolved
   context.
2. **Author notes** — optional formatted flavor/lore/strategy/tutorial material.
3. **Visual** — the art asset, fed by `art_asset` facts.

Any region may be absent. The rules region must not be replaced by author prose.
The notes region must not be interpreted as runtime rules.

**Why art gets its own region rather than living in the other two.** A playing sprite animation
is neither a rule nor prose. Its *data* is a fact — it must not become author-authored content
that a pack could use to smuggle presentation past the fact vocabulary — but its *layout* has to
be separate so the rules region stays text and stays screen-readable. `[CSA-15]` is deliberately
"B for the data, A for the layout"; implementing only one half loses either the validation or the
accessibility.

### Existing surfaces

Migrate in this order:

1. Stats: replace factual literals with stat-registry/formula facts; preserve the
   existing live base/cap/growth/modifier breakdown as resolved facts.
2. Classes: render movement, traits, bases/caps, weapon access, advancement, and
   level-based skill gains from active class data; move prose to author notes.
3. Weapons/items: render stats, dynamic range definition/current result, requirements,
   uses, effects, and restrictions; move item prose to notes.
4. Skills: replace the generic sentence with trigger/condition/effect facts from the
   skill-effect registry and render the existing `SkillData.description` through the
   compatibility author-note adapter.
5. Weapon/proficiency tracks: show stored WEXP, effective rank, floors, trainability,
   multiplier contributions, next threshold, and source provenance.
6. Combat forecast: retain live projected values, but derive field explanations and
   formula/profile attribution from registered rule descriptors.
7. Terrain/tile actions: generate costs, bonuses, requirements, consequences, and
   selected-unit availability from the same terrain/action registries.

Delete `MoreInfoContent.gd` literals only after parity fixtures prove every supported
entry has structured facts or intentional author notes. During migration, tag legacy
literals as compatibility facts with explicit provenance; do not silently claim they
were derived from runtime rules.

## Proficiency And Experience Integration (`B4-PXP`)

PXP must keep these concepts independent:

- stored proficiency XP/rank;
- family/equipment access;
- effective rank used by requirements and penalties;
- trainability (permission to gain stored PXP); and
- proficiency-gain multipliers.

The shared registered effect is structurally equivalent to:

```yaml
effect: weapon_access
track: sword
grants_family_access: true
effective_rank_floor: C
training: enabled | not_granted
```

Both modes are floors and never reduce stored or effective rank. `enabled` makes the
track trainable even when stored WEXP is zero. `not_granted` supplies borrowed mastery
but does not permit gain unless another source independently grants trainability.
Removing the effect removes its access/floor/training contribution but never erases
WEXP earned while it was active. Personal locks and unrelated restrictions remain
separate checks; this is not a universal “ignore restrictions” flag.

Resolution is contribution-based:

```text
effective rank = max(stored rank, active rank floors)
trainable      = natural permission OR any enabling contribution
final PXP gain = 0 when not trainable,
                 otherwise round_once(base gain * combined multiplier)
```

The PXP plan must settle multiplier stacking, rounding, minimum gain, caps, duplicate
source behavior, and zero-base behavior before implementation. Recommended default:
non-negative multiplicative stacking, floor once at the end, and zero remains zero;
an explicit registered guarantee is required to force a minimum gain.

EXP multipliers use separate channels:

```yaml
effect: experience_multiplier
channel: proficiency | unit | class
multiplier: 1.5
track_filter: sword        # optional for proficiency
```

Use `unit` for ordinary level EXP. Reserve `class` only if a distinct class-progression
currency is actually introduced; do not use it as an ambiguous synonym. Class EXP and
PXP storage remain separate as decided in the existing boundary plan.

Every access and multiplier handler emits definition facts. Live contexts additionally
emit base gain, each multiplier/source, trainability decision, rounding, and final gain.

## Registry Contract

Every public registry handler that affects player-visible rules implements or supplies:

- `validate_definition(definition, catalogue) -> diagnostics`;
- `describe_definition(definition, context?) -> semantic facts`;
- `related_references(definition) -> relations`;
- stable handler ID and semantic version;
- supported fact kinds and parameter schema; and
- provenance mapping from emitted facts back to definition fields/defaults.

Runtime execution and fact extraction must share parsed/validated parameters. They may
not each reinterpret raw dictionaries. Tests assert that changing a parameter changes
both behavior and its semantic fact, and that preview/execution/reference outputs name
the same handler/version.

This obligation applies incrementally to PXP, item components, skills, conditions,
formulas, predicates, combat operations, sources/styles, map objects, shops, AI
profiles, and later author-extensible systems. Existing registries receive adapters
during their owning implementation slices rather than through one giant retrofit.

## External Reference Outputs

### GFM folder — first supported output

Generate portable GitHub-Flavored Markdown using ordinary relative links rather than
Obsidian-only wikilinks:

```text
reference/
  index.md
  provenance.md
  classes/index.md
  classes/<stable-slug>.md
  skills/index.md
  weapons/index.md
  items/index.md
  terrain/index.md
  effects/index.md
  relationships/class-skill-progression.md
  relationships/weapon-access.md
```

Pages contain generated factual sections, optional author notes, related-entry links,
source/provenance blocks according to profile, and diagnostics when requested. Relative
links must work in GitHub, VS Code, Obsidian, and ordinary Markdown viewers.

### Combined Markdown and PDF

Generate a combined Markdown document directly from semantic entries; do not concatenate
the folder and rewrite links with text substitutions. Folder mode renders links to
files; combined mode renders stable internal anchors. The combined document contains:

- cover metadata and content fingerprint;
- clickable hierarchical table of contents;
- category sections in deterministic order;
- stable namespaced anchors;
- “see also,” “used by,” and “granted by” cross-links;
- an alphabetical index; and
- optional summary/full provenance appendices.

The first PDF backend should be Pandoc plus an HTML/CSS print path or another small,
pinned external converter. PDF generation is optional: missing converter dependencies
produce a clear tooling diagnostic without invalidating semantic/GFM generation.
The resulting PDF must preserve internal links/bookmarks, external links, page numbers,
headers/footers, grayscale readability, and pack/version/build identity. Treat PDFs as
release artifacts, not authored or reviewed source.

### Static HTML — later output

HTML adds sidebar navigation, breadcrumbs, full-text search, filters, sortable tables,
backlinks, and optional relationship diagrams. It consumes the semantic document (or a
generated JSON search index), not scraped Markdown. Avoid mandatory network assets so a
downloaded guide remains usable offline. Do not make HTML block the GFM/PDF milestone.

**HTML's full-text search survives `[CMP-S1]` and is ratified.** The in-game search was cut
because of the controller; a browser has a keyboard. This is the one search capability in the
system.

**HTML is the animating output (`[CSA-14]`).** At least one exported format must show art
animations live, and HTML is its natural home — CSS sprite animation over the pack's original
sheet, or a generated APNG. It must animate **from the pack's own sheet, never a remote embed**,
which is the same asset boundary the note vocabulary draws. GFM and PDF keep still frames. This
keeps the offline document from being either richer or poorer than the running game.

## Headless And Editor Entry Points

Provide one headless engine export command conceptually equivalent to:

```bash
godot --headless --path Project_Prometheus \
  --script res://tools/reference/export_reference.gd \
  --pack /path/to/pack \
  --output build/reference-model.json \
  --provenance full
```

The exact CLI parsing should follow existing project tool conventions. The exporter:

1. activates the pack through the normal candidate-content transaction;
2. validates all entities and references;
3. takes an immutable activated-catalogue snapshot;
4. collects entries/facts/relations/provenance;
5. validates semantic IDs, links, facts, and redaction;
6. writes atomically; and
7. exits nonzero on errors with stable diagnostic codes.

The later editor UI is a thin wrapper over the same callable module. It may select a
pack, provenance profile, and output formats; preview entries/notes/diagnostics; and
open generated artifacts. No extraction or rendering rules live only in the button.

## In-Game Reference / Compendium

After PXP and the first skill registry conversion, add a native Godot shell that reads
the same semantic entries and supports:

- **a closed candidate list over pack content — categories plus derived facets, and no in-game
  search field** (`[CMP-S1]`, confirming `[NMTE-S3]`; corrected from "search and category
  filters");
- stable entry navigation with back/forward history;
- related entries and backlinks;
- “Open Reference” from More Info, inventory, class, skill, and terrain surfaces;
- pack/source attribution and optional diagnostic provenance, subject to the non-suppressible
  attribution channel above;
- **live-animated art in native, unswapped colours plus a swap enumeration** (`[CSA-14]`,
  `[CSA-26]`) — in-game already holds the real `SpriteFrames`, so this is strictly cheaper here
  than in the renderer;
- input parity across mouse, keyboard, controller, and touch; and
- a discovery/visibility policy supplied by campaign rules without deleting
  facts from author/full exports.

**Undiscovered entries are hidden, not shown-disabled-with-a-reason (`[CMP-S2]`).** This is a
deliberate, *named* exception to the `EPUX-02`/`EPUX-07`/`RPD-15` availability vocabulary that
every other surface inherits — the compendium is the fourth surface to inherit it and the first
to be exempted. The reason is specific to this surface: **the reason string is the spoiler.**
"Requires defeating the Black Knight" leaks exactly what hiding the entry was protecting. A later
reader who finds a hidden entry here and reports it as a vocabulary violation is reading
correctly and reaching the wrong conclusion.

**The hiding is a presentation filter over a complete graph, never a hole in the semantic
document.** Validation fails activation on unresolved references, so if discovery ever reached
the document, discovery state would become an export input and the validator would begin failing
on correct packs. Two authors exporting the same pack must get the same guide.

**The static HTML output's full-text search is untouched by `[CMP-S1]` and remains ratified.** It
describes a browser artifact with a keyboard, which is the surface `[NMTE-S1]`/`[NMTE-S3]`
deliberately left alone. Do not strike both when correcting the in-game search — that would drop
a capability.

### The screen is the **Compendium** (`[CMP-S8]`)

Ruled 2026-08-15. Authors may rename the label through translation data, but **only via a
declared, narrow list of overridable engine chrome keys** — which is what keeps `[L10N-3]`'s
*"the engine translates chrome only"* true by construction: the engine owns the key and its
fallback, the pack supplies one value. **A general chrome-override capability is not granted.**
That list is new engine surface and belongs to `L10N`, not here.

The compendium does not block the external guide and does not embed a browser.

### Discovery: the mechanism, its scope, and carry-over

**What discovers an entry (`[CMP-S4]`).** Encounter by default — seeing a unit, item or terrain in
play discovers its entry — **plus an authored override**, where campaign rules name an explicit
condition per entry on the existing requirement-predicate substrate. **Build the authored half
first**; encounter then lands as a default predicate on top of it rather than as a second
mechanism. Before this ruling the plan had one sentence and no mechanism at all.

**Discovery is scoped to the RUN, not the save (`[CMP-S6]`).** `[CL-SAVE-01]` defines the tiers as
*"Campaign → Run → Save"*, where a run is one playthrough *"and its cumulative progress"* and a
save is *"a recovery point inside a run"*. Discovery is cumulative progress. **Per-save would mean
loading an earlier recovery point un-discovers entries** — rewinding deleting knowledge the player
has.

**Carry-over rides the existing status record.** `CampaignStatusRecord`/`CampaignStatusStore` are
already implemented and are explicitly *"a cross-campaign continuity artifact … not a resumable
save"*. The player **ticks a box at import**; discovery then carries for any entry ID that
**matches, or has a mapped destination**. Four constraints bind it:

- **"Mapped destination" is this plan's existing ID-migration mechanism**, generalized from
  within-pack renames to cross-pack succession — not a second mapping system.
- **Unmatched, unmapped IDs are dropped silently, and that is not an error.** `[ICO-1..6]` makes
  packs self-contained, so a record from campaign A necessarily carries IDs campaign B never
  defines. Failing on them would make the validator reject correct packs.
- **Discovery is one engine-known key whose contents are content IDs**, the same shape as
  `counters` — so it stays inside the record's *"no story fact becomes an engine field"* rule.
- **It stays player-editable.** The record's checksum detects corruption, not tampering; this is
  *"fun continuity, not competitive integrity"*. Do not harden it later.

The ID-stability guarantee therefore binds **run state**, not only renderers: an author renaming a
local ID without a migration silently un-discovers content in every existing run.

### Deep links: one resolver, always navigate, restore the caller exactly

**Callers pass a definition-level entry ID through one shared resolver (`[CMP-S7]`).** Never
construct the ID at the call site. `[TSV-11]` commits *instance* IDs while entries describe
*definitions*, so a forged, half-broken Iron Sword must resolve to `pack:item:iron_sword` in one
place. The caller list will grow, so the **resolver** is what must be single — not the enumeration.

**"Open Reference" always navigates (`[CMP-S14]`).** One behaviour from every caller; the entry
always gets full room. **The return must restore the caller's *state*, not merely its screen** —
selection, cursor, open panel and scroll. Two consequences:

- **Navigating mid-battle must preserve battle state exactly.** The compendium is not a save point,
  and a terrain or skill deep link is a full context exit and back.
- The measured alternative was rejected on geometry, not taste: the Compact entry needs **604 px of
  extent** against a **352 px** on-map band, so an in-place panel scrolls roughly two screens
  anyway. In-place is cheap at Expanded and cramped at Compact.

### Provenance display is a setting, not a profile (`[CMP-S16]`)

The `none`/`summary`/`full` profiles above are **export** parameters. The in-game compendium has a
**player setting, with a per-campaign author default**, governing how much provenance, source and
diagnostic detail it shows. It governs the **entire in-game compendium** and **may go to zero**.

- **The export always has everything.**
- **There is no pack/version line in the app bar.** Pack identity, when shown at all, appears in
  the entry under the setting.
- **Zeroing the setting is not a `[CSA-13]` regression, because the compendium is not the
  attribution channel.** `[CRD-3]` already makes Credits reachable from the Main Menu **and**
  in-campaign Settings, rendering one screen from engine + active-pack + active-theme notices
  (`[CRD-2]`). That always-reachable screen is where required attribution lives — exactly the
  separate, non-suppressible channel `[CSA-13]` was ruled to get.
- Both surfaces read the same structured notices (`[CRD-1]`), so they cannot drift.

### Scope and the rest of the ruled behaviour

**Campaign-scoped and inside the pack theme boundary (`[CMP-S18]`)** — so there is **no no-pack
empty state** and **the main menu gains no compendium entry**. Also ruled: a true back/forward
**history stack** (`[CMP-S9]`, session-scoped per `[CMP-S17]`), back always with forward only
where the size class has room (`[CMP-S10]`), horizontally scrolling categories with the active one
always in view (`[CMP-S11]`), a related link to a hidden entry **omitted entirely** as a
presentation filter over a complete graph (`[CMP-S12]`), and an entry layout **identical to More
Info for rules and notes but deliberately different for art** (`[CMP-S15]`, per `[CSA-26]`).
Category, facets, focused entry and scroll survive leaving; history does not (`[CMP-S17]`).

## Validation And Diagnostics

Semantic validation fails activation/export for:

- duplicate entry/fact IDs after namespacing;
- unresolved references or backlinks;
- unsupported required fact kinds;
- handler facts that contradict parsed parameter types or bounds;
- unsafe author-note formatting or assets;
- provenance paths escaping their pack root;
- non-deterministic ordering or unapproved timestamps;
- release exports containing local-path/private-environment fields;
- **a recorded licence obligation whose required notice is missing**, on release-complete or
  public export — draft packs warn instead (`[CRD-9]`, mirrored by `[L10N-14]`'s
  draft-warns/release-fails severity for locale completeness); and
- unsupported schema versions.

`[CRD-9]` has a known upstream gap that is **not** the validator's: it can only fail on
obligations someone has already recorded, so a *missing* record still passes until `LEG-4`'s
asset audit lands. Do not mistake the check for coverage.

Advisories report missing optional author notes, entries with no player-facing facts,
or facts only available through a legacy compatibility adapter. A coverage report
lists every activated registry handler and whether definition, live-resolution, and
provenance emitters exist.

Suggested stable diagnostic families:

```text
REF_SCHEMA_*     semantic document/entry shape
REF_ID_*         identity and collisions
REF_LINK_*       missing/ambiguous relations
REF_FACT_*       unsupported/invalid facts
REF_NOTE_*       author-note parsing/safety
REF_PROV_*       provenance/redaction
REF_RENDER_*     renderer/output failures
```

## Test Strategy

### Engine tests

- Golden semantic export for a minimal synthetic pack.
- Deterministic byte-identical export from identical activated content.
- Namespace collision and same-display-name fixtures across two packs.
- Pack-relative full provenance and release-redaction negative fixtures.
- Default/inheritance/compatibility provenance tests.
- Fact/runtime parity for at least one handler per registry family.
- Live/static/example scope separation.
- Restricted-note parser injection, malformed link, and asset-boundary tests.
- **Attribution survives every provenance profile**, including `none` — the negative fixture is a
  CC-BY asset exported player-facing (`[CSA-13]`, `[CRD-6]`).
- **Art facts**: native-colour reference rendering versus context-resolved More Info rendering for
  the same asset, and a swap enumeration that lists variants without generating one image each
  (`[CSA-26]`).
- **Keyed note bodies resolve through the pack's own locale catalogue**, fall back to English,
  and report — never silently swallow — a missing key (`[L10N-3]`, `[L10N-14]`).
- **Discovery is a presentation filter only**: exporting the same pack against two saves with
  different discovery state produces **byte-identical** documents (`[CMP-S2]`).
- More Info parity during each migrated surface.
- PXP access floor, trainability overlap/removal, stored-WEXP preservation, multiplier,
  rounding, and contribution-chain tests.
- Skill facts using real `SkillData` and handler parameters rather than the generic text.

### Renderer tests

- Golden GFM pages and deterministic filename/anchor generation.
- Every generated relative/internal link resolves.
- Backlinks are symmetric where required.
- Combined-document links target internal anchors, never `.md` paths.
- Markdown escaping and safe formatting parity.
- PDF smoke test checks a non-empty artifact, bookmarks/TOC, selected internal links,
  metadata, and absence of machine-local paths.
- HTML output works without a network and its search index resolves stable IDs.

Golden fixtures should be small and synthetic. Do not use private campaign content as
the public suite's expected output.

## Incremental Delivery Slices

### Slice 0 — contract fixtures and inventory

- Inventory every existing More Info producer, literal, data description, and dynamic
  block.
- Inventory activated registries and identify their parsed definition authorities.
- Freeze semantic JSON v1, provenance profiles, stable IDs, note AST, diagnostic codes,
  and renderer escaping rules with synthetic examples.
- Extend the PXP and skill plans with the mandatory emitter contract.

Exit: schema fixtures and validation tests are approved before runtime integration.

### Slice 1 — engine semantic foundation

- Add typed/reference-model value objects or validated dictionaries.
- Add entry/fact/relation/provenance builders and deterministic collector.
- Export identity, pack metadata, classes, items, weapons, existing skills, stats, and
  terrain from an immutable activated catalogue.
- Include the **`art_asset` fact kind and its `depicted_by` relation** (`[CMP-S20]`), so the
  vocabulary ships complete even though nothing renders it until Slice 2.
- Mark legacy prose as compatibility-authored, not generated truth.
- Add headless JSON export and coverage diagnostics.

Exit: a synthetic pack produces deterministic valid semantic JSON with full safe
provenance and zero unresolved links.

### Slice 2 — More Info region migration

- Add shared semantic render helpers and safe note rendering.
- Migrate stats/classes/weapons/items first, then skills/WEXP/combat/terrain.
- Keep layout behavior and input ordering stable unless separately playtested.
- Remove shared factual literals only after parity and coverage gates pass.

Exit: existing More Info surfaces use structured facts, author notes are visibly
separate, and factual coverage has no silent generic fallbacks.

**Slice 2 delivers the rules and notes regions; the `art_asset` fact kind lands in Slice 1**
(`[CMP-S20]`). The kind ships with every other kind in the semantic foundation, so the vocabulary
is never incomplete and no consumer works around a hole; the **visual** region required by
`[CSA-15]` ships here in Slice 2, with the first surface that draws one. The fact kind depends on
the `[CSA-4]` art catalogue; the compendium (Slice 6) and the HTML output (Slice 7) both consume
it.

### Slice 3 — PXP and EXP emitters

- Implement weapon-access floors, independent trainability, stored PXP, and
  multipliers in `B4-PXP`.
- Emit static and live contribution facts with provenance.
- Add class weapon-access and class-skill-gain relationships.

Exit: the ring/borrowed-mastery overlap cases are executable, inspectable, and present
identically in semantic JSON and More Info.

### Slice 4 — GFM and PDF sidecar

- Implement semantic-document reader and version gate.
- Generate folder GFM, indexes, backlinks, and combined Markdown.
- Add optional pinned PDF conversion and link validation.
- Document the author/release command and artifact locations.

Exit: the synthetic pack and one complete development pack produce a valid GFM folder
and single cross-referenced PDF in `none`, `summary`, and `full` provenance modes.

### Slice 5 — skill/effect adoption

- Make the `B5-SKILLS-EFFECTS` registry conversion emit trigger/condition/operation
  facts and relationships.
- Adapt conditions, durations, grants/revokes, counters, and level-up triggers.
- Treat unavailable/unimplemented effects as structured availability, never roadmap
  prose embedded in player descriptions.

Exit: no skill More Info entry relies on the generic skill sentence.

### Slice 6 — in-game compendium

- Add native reference browser, **category and derived-facet indexes — no in-game search field**
  (`[CMP-S1]`; corrected from "search/category indexes"), navigation history, and deep
  links from More Info.
- Add campaign discovery policy and author/full diagnostic modes.
- Add the live-animated visual region in native colours with its swap enumeration
  (`[CSA-14]`, `[CSA-26]`).

Exit: keyboard/mouse/controller/touch tests pass, the compendium shows the same
facts and links as the exported model, and a hidden entry changes **nothing** in the exported
document.

### Slice 7 — HTML and editor integration

- Add optional static HTML/search presentation.
- Add the thin campaign-editor preview/export surface.
- Evaluate splitting the sidecar into its own project based on actual reuse and release
  needs.

Exit: no semantic logic exists exclusively in HTML templates or editor UI.

## Documentation And Definition Of Done

When behavior lands, update the affected GDD owners in the same commit:

- `GDD_01`: content session, schema, provenance, and tool boundary;
- `GDD_02`: progression, resolved values, and contribution explanations;
- `GDD_03`: classes, proficiency access, and class-skill relationships;
- `GDD_04`: weapons/items/effects and reference facts;
- `GDD_05`: skill/condition handler description contract;
- `GDD_06`: terrain/action facts;
- `GDD_07`: More Info, external reference, compendium, and editor surfaces; and
- `GDD_10`: track status and delivery ordering.

Each implementation slice must also update this plan, the control-plane row, and the
canonical coordination task. Mechanical requirements—stable IDs, safe provenance,
handler coverage, and link resolution—must land with automated enforcement rather
than prose alone.

The full feature is implemented only when:

- activated rules and semantic facts share parsed handler parameters;
- all supported More Info facts come from the semantic model;
- author notes are separately stored and safely rendered;
- summary/full provenance is available without leaking local/private data;
- required attribution is present under **every** profile, including `none`;
- art assets carry facts, render natively in the reference and contextually in More Info, and
  animate in-game and in HTML;
- author-note bodies are keyed and resolve through the active pack's locale catalogue;
- GFM and the combined PDF have validated cross-links;
- new public registry handlers cannot omit reference coverage silently;
- PXP and skills demonstrate live contribution provenance; and
- the in-game compendium consumes the same model rather than copied descriptions.

## Explicit Non-Goals

- No arbitrary pack scripts, HTML, BBCode, filesystem access, or expression VM.
- No parsing generated prose back into rules or relationships.
- No PDF or Markdown as runtime authority.
- No duplicated external implementation of Godot resource/registry resolution.
- No requirement that every author write flavor or tactical notes.
- No universal weapon-restriction bypass hidden inside proficiency access.
- No public campaign-builder implementation in the foundation slices.
- No publication-quality PDF typography gate before semantic correctness and links.
