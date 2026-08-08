---
Type: plan
Status: Planned — approved architecture; implementation not started
Last verified: 2026-07-30
Tracker: B3-REFERENCE-MODEL, IMPL-REFERENCE-MODEL-FOUNDATION
---

# Generated Reference Model, More Info, And Pack Guide — Implementation Plan

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
- formula identity/parameters and bounded human-readable rule summaries; and
- relationship facts such as `grants`, `learned_by`, `requires`, `uses`, `targets`,
  `promotes_to`, `effective_against`, and `defined_in`.

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

Independent switches may refine those profiles. Full provenance should carry, when
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
  "body": "Strong near allies; beware of **effective** weapons.",
  "visibility": "player"
}
```

Initial kinds are `flavor`, `lore`, `strategy`, `tutorial`, and `author`. Unknown
kinds remain displayable as notes rather than changing runtime behavior.

Use one deliberately restricted Markdown-like AST or token vocabulary, not raw BBCode
and not arbitrary HTML. Supported formatting should initially be paragraphs,
emphasis, strong emphasis, lists, safe internal reference links, and approved image
asset references. No scripts, raw HTML, filesystem links, remote embeds, style
attributes, or arbitrary Godot BBCode tags. Parse/validate once and render safely to
Godot rich text, GFM, HTML, and PDF. Preserve plain-text and screen-reader output.

## More Info Migration

The live layout becomes two conceptually separate regions:

1. **Rules and active values** — entirely generated from semantic facts and resolved
   context.
2. **Author notes** — optional formatted flavor/lore/strategy/tutorial material.

Either region may be absent. The rules region must not be replaced by author prose.
The notes region must not be interpreted as runtime rules.

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

- search and category filters;
- stable entry navigation with back/forward history;
- related entries and backlinks;
- “Open Reference” from More Info, inventory, class, skill, and terrain surfaces;
- pack/source attribution and optional diagnostic provenance;
- input parity across mouse, keyboard, controller, and touch; and
- optional discovery/visibility policy supplied by campaign rules without deleting
  facts from author/full exports.

The player-facing name should be **Reference** or **Compendium** unless later tone work
selects “Wiki.” The compendium does not block the external guide and does not embed a
browser.

## Validation And Diagnostics

Semantic validation fails activation/export for:

- duplicate entry/fact IDs after namespacing;
- unresolved references or backlinks;
- unsupported required fact kinds;
- handler facts that contradict parsed parameter types or bounds;
- unsafe author-note formatting or assets;
- provenance paths escaping their pack root;
- non-deterministic ordering or unapproved timestamps;
- release exports containing local-path/private-environment fields; and
- unsupported schema versions.

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
- Mark legacy prose as compatibility-authored, not generated truth.
- Add headless JSON export and coverage diagnostics.

Exit: a synthetic pack produces deterministic valid semantic JSON with full safe
provenance and zero unresolved links.

### Slice 2 — More Info two-box migration

- Add shared semantic render helpers and safe note rendering.
- Migrate stats/classes/weapons/items first, then skills/WEXP/combat/terrain.
- Keep layout behavior and input ordering stable unless separately playtested.
- Remove shared factual literals only after parity and coverage gates pass.

Exit: existing More Info surfaces use structured facts, author notes are visibly
separate, and factual coverage has no silent generic fallbacks.

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

- Add native reference browser, search/category indexes, navigation history, and deep
  links from More Info.
- Add campaign discovery policy and author/full diagnostic modes.

Exit: keyboard/mouse/controller/touch tests pass and the compendium shows the same
facts and links as the exported model.

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
