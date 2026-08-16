---
Type: plan
Status: Split — Slice 3 catalogue families Implemented through terrain (class, advancement, weapons, rosters, media, items, maps, terrain); Slices 4–5 Target design
Last verified: 2026-08-01
Decision source: campaign_data_ownership_research_findings_2026-07-23.md
Tracker: IMPL-ZERO-CONTENT-FOUNDATION, IMPL-ZERO-CONTENT-FAMILIES, IMPL-ZERO-CONTENT-BASE-PACK, IMPL-ZERO-CONTENT-EXPORT-GATE
---

# Zero-Content Engine — Implementation Plan

## Outcome and boundary

The engine boots with no active gameplay catalogue. It retains Main Menu,
settings/accessibility/input, package discovery/install/selection, trusted primitive
handlers, validators/adapters, and empty inactive catalogues. New Game and gameplay
stay disabled until one self-contained pack validates and activates. No hidden base
pack, implicit `res://data` fallback, or v1 pack dependency is permitted.

Product slices merge to `agent/integration`. This plan changes no behavior itself.

## Current-state inventory

- `scripts/autoloads/DataManager.gd`: `_ready`, `reload_presets`,
  `activate_campaign_package`, `deactivate_campaign_package`, map/campaign/class/
  roster catalogues; `_ready` loads project `data/`.
- `scripts/autoloads/RegistryManager.gd`: `DEFAULT_CONTENT_SOURCE`,
  `REQUIRED_FAMILIES`, `_ready`, `reload_presets`; five registry families load from
  `res://data/registries`.
- `scripts/resources/Tier2Catalogue.gd`: `parse`, `load_and_validate`,
  `load_campaign_pack`, `validate_campaign_documents`, `get_document`.
- `scripts/resources/CampaignTier2Validators.gd`: `registry`,
  `collect_cross_reference_errors`, validators for campaign, map registry, map,
  roster, and class.
- `scripts/resources/CampaignTier2RuntimeAdapter.gd`: `load`, `_build_classes`,
  `_build_rosters`, `_build_maps`, `_build_map_registry`, `_build_campaigns`.
- `CampaignPackRegistry`, `PackManifest`, archive preflight/installer,
  `CampaignPackExporter.export_zip`, `MainMenu._on_new_game`, and the campaign
  selector are the existing package and player-flow seams.
- `data/` currently contains campaigns; split battle maps/encounters plus legacy
  map resources; rosters; classes; weapons; items; skills; Pair Up; registry
  entries; and map registry JSON. Media lives under `assets/` and must be admitted
  by pack index/resolver rather than copied wholesale.

## Target package contract

`manifest.json` identifies package/version and content-schema version.
`data/catalogue.json` is the sole indexed document list. Each entry has a supported
`kind`, durable package-local `id`, safe relative JSON path, and schema version. Media
is indexed through logical asset ids. Primitive callables remain engine-owned; pack
registry documents only select registered handler ids and validated parameters.

The v1 manifest fields are:

- `package_id`: stable lowercase RFC 4122 UUID generated once by the authoring tool;
  it does not change when the package is renamed, edited, or versioned;
- `package_version`: author-assigned SemVer 2.0 release identifier;
- `content_schema_version`: engine-owned positive integer schema projection;
- `display_name` and author identity/presentation fields;
- `authoring_status: draft | finalized` (author declaration, not validation result);
- `distribution_policy: private_only | authorized_internal | public_candidate`;
- `default_enabled` (selection preference only, never permission or validity);
- `catalogue_path`, fixed to `data/catalogue.json` in v1.

The engine derives, and the manifest cannot self-assert, `structurally_valid`,
`playable`, target-specific distribution eligibility, and effective enablement. An
empty-content package is a real manifest plus an empty authoritative catalogue: it
may be structurally valid and finalized while remaining non-playable. `New Game`
requires a playable campaign graph, not merely a valid or finalized package.

Activation builds a candidate `ContentSession` containing typed catalogues plus the
package identity tuple; only a fully validated candidate is swapped into
`DataManager`/`RegistryManager`. Deactivation returns both to a valid empty state.
Entity ids and references remain package-local in v1. Package ids are unique across
the installed library; saves, diagnostics, caches, and receipts carry package context
rather than requiring authors to write qualified entity ids. Cross-package content
references are rejected.

### Canonical content fingerprint

`content_fingerprint` identifies one exact package snapshot; it is not durable package
identity. The v1 algorithm id is `pp-pack-sha256-v1`:

1. Reject symlinks, duplicate/case-folded paths, unindexed bytes, and any path
   outside the admitted grammar: `/`-joined segments each matching `[a-z0-9_.-]+`,
   with no backslash, no absolute or empty path, no leading/trailing separator,
   and no `.` or `..` segment. The conservative ASCII grammar makes byte-order
   sorting, case-folding, and cross-platform hashing exact by construction.
2. Resolve the closure consisting of `manifest.json`, `data/catalogue.json`, every
   indexed document, and every indexed media file.
3. Project `manifest.json` with exactly the top-level keys `content_fingerprint`
   and `fingerprint_algorithm` omitted; unknown manifest fields are rejected
   before fingerprinting, so no unrecognized key is ever hashed. Encode the
   projection per RFC 8785 (JSON Canonicalization Scheme): UTF-8, object keys
   sorted by code point, minimal string escapes, integer-only numbers (the
   manifest schema admits no non-integer numbers), no insignificant whitespace,
   and no trailing newline. Other indexed files contribute their exact stored
   bytes.
4. Sort the admitted relative paths by UTF-8 byte order. Feed SHA-256, for every
   entry, with the UTF-8 path length, path bytes, content-byte length, then content
   bytes, using unsigned 64-bit big-endian lengths. Include the algorithm id as the
   first record, encoded as one `(uint64-BE byte length, UTF-8 bytes)` pair.

The fingerprint is defined only for structurally closed packs: a root that fails
step 1 has no `pp-pack-sha256-v1`. Draft backups of unclosed or invalid roots carry
an ordinary archive checksum with no snapshot-identity or conflict-quarantine
claims.

The import/export receipt stores `{package_id, package_version,
fingerprint_algorithm, content_fingerprint}` outside the hashed payload, in the
engine's package-library metadata — never as a file inside the package root. Same id,
version, and fingerprint is an exact duplicate. Same id/version with a different
fingerprint is a quarantined conflict requiring an explicit compare/keep/replace
choice; it is never silently overwritten. Different package ids with identical
fingerprints may be deduplicated physically without merging their declared identity.

## Content-family migration matrix

| Family | Tier-2 work before movement | References / activation exit |
|---|---|---|
| Campaigns | Expand existing validator for profile id, defaults, mandates, nodes and presentation ids. | Campaign/node/map/profile ids resolve; selector can launch. |
| Map registry | Preserve labels, roster policy/source and package-local map ids. | Every entry resolves one map/encounter pair and valid roster policy. |
| Battle maps | JSON grid, terrain cells, start/objective tiles, asset ids. | Bounds/terrain/objective cross-checks pass. |
| Encounters | Factions, turn order, placements, objectives, rewards, overrides. | All faction/unit/class/item/skill/objective ids resolve. |
| Rosters/units | Engine-owned declarative schema over existing `UnitData`: identity, level/EXP, the stat block, growths, WEXP totals, weapon inventory, skills, reclass options, AI profile, and the durable class/edge/weapon variant selections. Stat and track ids validate as map *keys*. No `faction` field — faction lives on a map's enemy placement, not on `UnitData`. | Unknown fields fail with unit-qualified paths; unit ids unique; every class/weapon/edge id and every durable variant selection resolves; mutable runtime copies build without dropping typed arrays. |
| Classes | Engine-owned declarative schema over existing `ClassData`: flat `base_*`, player/enemy growths, caps, WEXP bases/caps, `skill_unlocks`, `tier`, `internal_level_rule`, compatibility `promotes_to`, bounded variants, movement and sprite ids. | Unknown fields fail with exact paths; stat/skill/class/media/provenance ids resolve; selected durable variants are saveable. |
| Weapons | Full combat fields, effects, costs and registered range formula selection. | Item/stat/formula/resource references validate. |
| Items | Uses, effects, costs, class requirements, icons. | Effect/requirement/resource/class ids validate. |
| Skills | Triggers, modifiers and registered engine primitive selections. | Handler/stat/resource ids validate; no pack callable. |
| Terrain | Movement/avoid/defence/healing and media ids. | Movement/stat/media ids validate. |
| Pair Up | Bonus table schema and stat-id validation. | Every table cell and referenced stat is bounded. |
| Registry documents | JSON adapters for resource types, objective conditions, item effects, action primitives, occupancy policies. | Handler ids exist in trusted primitive registries. |
| Rule profiles | Added by the rule-profile plan after save/schema seams. | Profile ids unique and CampaignRules-valid. |
| Media | Logical id, admitted path, decoded type, exact byte size, SHA-256, original filename and optional `author_notes`. | Every referenced id resolves inside pack root and generated integrity data matches. |

Legacy `data/maps/<id>/*_data.tres` is retired only after split battle-map and
encounter JSON provides equivalent coverage. Every current `data/` file must appear
in an extraction inventory with destination, disposition, and provenance; no
unclassified file may be deleted.

### Class entity, provenance, and advancement contract

The concrete pre-freeze serialization and synthetic conformance inputs are defined
by [`class_schema_trial_v1_2026-07-29.md`](../design/class_schema_trial_v1_2026-07-29.md).
Implement that narrowly versioned trial, run its promotion exits, and update its
registry and fixtures together if implementation exposes a defect. Do not treat the
trial label as permission to invent a second schema in implementation.

The engine-owned schema registry is canonical. Generated JSON Schema, references,
and golden fixtures are projections, not competing authorities. Class documents use
one identity-bearing base entity plus optional bounded variants: each variant has a
stable `variant_id`, eligibility predicate, and typed overrides. Class variants may
override only admitted class-owned fields; advancement-edge variants may override
only admitted edge-owned fields. Identity, schema, provenance, and arbitrary
deep-merge overrides are rejected.

Packages own reusable source registries. Every identity-bearing document has nonempty
resolving `source_refs`; direct transcription needs document references, while
transformed, disputed, conflicting, or ambiguous fields also name stable occurrence
audit ids. Missing document coverage, missing occurrence coverage, and dangling
references are distinct structured errors. Dangling references are never waivable.
Editor-only draft launch may temporarily waive missing occurrence coverage with a
persistent warning, prelaunch report, and isolated saves; finalized load/public export
rejects all missing or dangling required provenance. Errors carry package, catalogue
entry, document path, field path, code, source/audit id, actionable message, and a
suggested fix where possible.

Source registries, asset registries, the catalogue, and the manifest are a closed set
of infrastructure documents exempt from document-level `source_refs`; every record
inside them is still validated. Source records carry `locator`, title/author and
attribution data, `rights_status: unchecked | verified | disputed | no_grant`,
`license_id` (SPDX id or `LicenseRef-*`, required when verified),
`distribution_scope: private_only | authorized_internal | public`,
`attribution_required`, `verified_at`, and optional `author_notes`. Occurrence records
may preserve `source_value`, `canonical_value`, transformation state, and optional
`author_notes`. Notes explain decisions but never replace structured evidence or
rights fields.

Eligibility is target-specific, not one author-set boolean. Faithful private backup
never requires playability or finalized status. Author/device transfer preserves a
draft/internal marker. Personal testing requires structural safety and only the
content graph being exercised. Public release requires finalized status, structural
validity, verified distributable rights, satisfied attribution, and an allowed
distribution policy. A public export fails if selected content references anything
ineligible; private backup still preserves malformed or incomplete bytes without
claiming they can execute.

Exact field evidence may optionally use a `transcribed` occurrence record; ordinary
direct transcription does not require one unless an authoring/audit policy opts in.
Required class maps carry completeness states. Draft packs may retain `unverified`
fields, while finalized-package public export/load rejects them; an empty required map must be
explicitly `unverified` or rules-profile-permitted `not_applicable`.

`ClassAdvancement` replaces compatibility-only `promotes_to` semantics. Classes
reference stable edges; edges own source/destination, transition gains, rank grants,
variant selection, and bounded one-time operations. Routes compose registered
trigger, requirement, cost, selection, and transition handlers, all engine-owned;
packs provide data only. Fixed and branching advancement use this same path.
Reclass destinations remain unit-owned. Keep a `promotes_to` import adapter only
while old content exists, and sequence this schema before bulk class transcription.

Trusted handler registrations declare typed required/optional parameters, local
entity-reference targets, consumed advancement-context bindings, and preview versus
mutation behavior. Eligibility facts are typed open-registry entries. Commit records
route, edge, destination, class-variant, and edge-variant ids; restore validates that
record instead of rerunning historical eligibility.

Whole-field variant replacement remains v1 behavior. Authoring preview expands the
effective value and warns when a replacement map removes an inherited key. Optional
localization keys accompany required fallback display names.

## Incremental slices and dependencies

1. **`IMPL-ZERO-CONTENT-FOUNDATION` — inactive boot and atomic session.** Add
   explicit inactive catalogue state; remove unconditional loads from both `_ready`
   methods; keep an opt-in compatibility activation of project data while extraction
   proceeds. Main Menu shows No Packs / invalid-pack diagnostics and disables play.
   Exit: headless engine boots with empty catalogues and can activate/deactivate the
   existing complete Tier-2 fixture atomically.
2. **`IMPL-FORMULA-REGISTRY-V1`** (separate plan) lands the v1-required range, hit,
   cost and requirement registry contracts before weapon/item schemas freeze.
3. **`IMPL-ZERO-CONTENT-FAMILIES` — catalogue expansion.** Add each table row as a
   vertical validator + adapter + cross-reference fixture. Commit families in
   dependency order: registries/media → minimal skill/item identity and local-reference
   schemas → terrain/classes/advancement → full skills/items → weapons → rosters →
   maps/encounters → campaigns. The minimal skill/item stage resolves class unlocks
   and promotion-item parameters without prematurely implementing full behavior.
   Keep compatibility activation green. The class vertical then lands: canonical schema projection,
   source registry and occurrence-audit validation, bounded class/edge variants,
   `ClassAdvancement`, runtime adapter, structured diagnostics, then golden and
   invalid fixtures. Do not begin bulk class transcription before this exit passes.
   Treat exits in two layers: class-contract closure covers provenance, completeness,
   typed descriptors/facts, local skill/item identities, variants, and advancement;
   expanded-pack closure adds maps/campaigns, shared catalogue use, presentation
   warnings, and the separately implemented Awakening pressure profile.
   **Class foundation landed 2026-07-30:** the engine schema DSL now admits the
   required class envelope/mechanics, nested descriptors, source and occurrence
   resolution, bounded class variants, and WEXP invariants. The pure
   `ClassAdvancement` seam proves fixed/branching resolution plus non-mutating
   cancellation/failure and atomic confirmed state application. This is the
   first bounded vertical slice, not class-contract closure; edge/route schemas,
   complete occurrence auditing, runtime adapter adoption, cross-references,
   fixtures, and durable state exits remain.
   **Edge/route schemas landed 2026-07-31:** `advancement_edge` and
   `advancement_route` are registered engine-owned schemas. Fixed and branching
   edges share one schema and one commit path, differing only in destination
   count; edge variants may override destination, gains, and operations but never
   the routes that gate the transition. Every executable descriptor on an edge or
   route resolves against a new **open handler registry**
   (`EntitySchemaRegistry.register_handler`, seeded with `class_advancement_v1`),
   so an unknown handler or an unadmitted handler version fails validation before
   preview rather than at runtime, and adding a handler is a registration rather
   than an engine edit. Still open on the class family: variant *eligibility*
   descriptors are not yet handler-checked (class and edge variants are
   consistent in this, and closing it should close both together), plus complete
   occurrence auditing, runtime adapter adoption, cross-references, fixtures, and
   durable selection round-trips. The synthetic Z0/Z1 fixture corpus was ported
   into `test_fixtures/zero_content/` on 2026-07-31; see its README for the four
   known vocabulary drifts to normalize as Tier-2 adoption proceeds.
   **Class vertical adoption landed 2026-07-31:** class and edge variant
   eligibility descriptors now resolve through the same trusted handler registry;
   the duplicated Z0/Z1 corpus was normalized once at its FE-pack authoring source
   and mirrored into the engine; all eleven roots run through an engine-owned
   expected-diagnostic suite. `Tier2Catalogue` now invokes the registered entity
   schemas after gathering package provenance, checks class/edge/route references,
   and `CampaignTier2RuntimeAdapter` retains validated advancement documents while
   preserving compatibility activation.
   **Class vertical closed 2026-07-31:** occurrence audits now bind
   bidirectionally to their document, resolving source, and real JSON field path.
   Selected class and edge variants live on `UnitData`, are written by the shared
   advancement commit seam, and round-trip through the one `SaveCodec` snapshot
   used by campaign save, suspend, Retry, and Rewind.
   **Weapon family landed 2026-07-31:** `weapon` is a registered engine-owned
   schema projecting the existing `WeaponData` surface, so every admitted field
   name is the runtime property the adapter writes. Registered documents select
   `range_min_formula_id`/`range_max_formula_id` plus parameters and are checked
   against the v1 range registry during validation; the legacy `range_*_formula`
   grammar is deliberately not admitted, keeping it an import concern instead of
   a second range authority. Author-facing vocabularies (combat family, WEXP
   track, weapon rank, effect tag) resolve through a new **open vocabulary
   registry** (`EntitySchemaRegistry.register_vocabulary`) seeded from the
   engine's existing single-source lists, so admitting a new family or tag is one
   edit rather than a new check in the validator. The contract also enforces
   coherent literal ranges, `uses` of -1 or at least 1, natural-weapon cost/use
   rules, family/track coherence, and heal-tag/staff coherence, and bounds weapon
   variants to numbers, effects, icon, and range. `CampaignTier2RuntimeAdapter`
   adapts a validated document into `WeaponData` with the same range/equip/combat
   inputs the JSON authored, converting the `Array[String]` effect tags and
   narrowing JSON's float-decoded formula parameters back to integers.
   **Still open from the Weapons handoff:** `icon` is admitted as a plain string
   and weapons contribute no new package-local cross-references, because the
   campaign Tier-2 validator set has no `media`/`asset_registry` kind yet and
   weapons carry no item or effect *document* references — those land with the
   Media and Items family rows rather than being designed inside the Weapons
   change. Weapon variants are also validated but not yet *selectable*: nothing
   in the runtime records a chosen weapon variant, so there is no durable
   round-trip equivalent to `UnitData.class_variant_id`. That belongs on
   `InventoryEntry` and lands with the roster/inventory family, which is where a
   selection would first be authored. Rosters and encounters are the next
   families.
   **Roster family landed 2026-08-01:** `roster` is a registered engine-owned
   schema projecting the existing `UnitData` surface. One document still holds a
   whole party — `units` is validated as a nested array, so every diagnostic stays
   unit-qualified (`units[i].inventory[j]`) — which matches how the catalogue
   already indexes rosters and cross-references `units[].class_id`. The open
   vocabulary registry gained a **key** form: a map whose vocabulary lives in its
   keys (`growth_rates`, `growth_accumulators`, `weapon_wexp`) now validates those
   keys, seeded from `StatRegistry` and the existing `wexp_track` registry, so an
   authored `strenght: 40` fails instead of being admitted and never rolling;
   `ai_profile` resolves through `AIProfileRegistry` on the same seam. The contract
   enforces positive HP that does not exceed the unit's own maximum, unique unit
   ids, inventory `uses` of -1 or at least 1, and an edge-variant selection that
   names the edge it belongs to.
   **The Weapons deferral on durable variant selection is now closed:**
   `InventoryEntry.weapon_variant_id` records the chosen variant per slot, whole-pack
   validation resolves it — along with `class_variant_id`, `advancement_edge_id`,
   and `advancement_edge_variant_id` — against the document that owns the variant,
   and it round-trips through the one `SaveCodec` snapshot used by campaign save,
   suspend, Retry, and Rewind. Saves written before the field existed load as the
   base weapon.
   Runtime adoption converted the typed `Array[String]` exports and the JSON-float
   stat maps explicitly, and repaired the same silent-empty trap on `ClassData`'s
   four authored string lists (`allowed_weapon_families`, `class_groups`,
   `special_qualities`, `vulnerability_groups`).
   **Still open from the Rosters handoff:** the asset/item cross-reference deferral
   does **not** close here and was not forced to. `UnitData` has no sprite or
   portrait property, so a roster needs no asset reference and inventing the
   smallest `media`/`asset_registry` schema for it would have authored a field
   nothing reads; `WeaponData.icon` and `ClassData.sprite_id` stay plain strings
   until the Media family row. For the same reason no `faction` field is admitted —
   faction lives on a map's enemy placement, not on the unit. Inventory slots admit
   weapons only; item and equip slots wait for the Items family identity schema.
   The class family's growth/cap maps still validate values but not keys — the key
   vocabulary is deliberately not retrofitted onto a closed vertical, and is the
   obvious first follow-up when the class family is next opened. Maps/encounters
   and items are the next families.
   **Media family landed 2026-08-01:** `asset_registry` is a registered
   engine-owned schema and is one of the infrastructure documents exempt from
   document-level `source_refs` (with the catalogue, manifest, and source
   registry), though every record inside it is validated. Logical asset ids are
   author-defined, so `assets` carries no *key* vocabulary — the values are what
   is bounded. Admission is seeded from
   `CampaignArchivePreflight.APPROVED_MEDIA_EXTENSIONS` (`png, ogg, wav, ttf,
   otf`) rather than restated, so the plan's "decoder-verified inert formats
   already on the project allow-list" rule has one authority and SVG stays
   non-admitted by construction; a test asserts the extension→type table covers
   the allow-list exactly, so adding an extension without a type fails a test
   instead of silently admitting an untyped format. **Integrity is verified, not
   trusted:** `byte_size` and `sha256` are compared against the real file and
   magic bytes against the declared type, so a mutated asset fails under a record
   that still looks internally consistent. This required one new seam,
   `Tier2Catalogue.pack_root`, because the filesystem pass needs a root that
   `validate_document` deliberately does not take; the archive path leaves it
   empty and skips integrity, where `CampaignArchivePreflight` already checks the
   archive bytes. **The asset cross-reference deferral carried past class,
   weapons, and rosters is CLOSED:** registered documents resolve
   `sprite_id`/`icon` against the pack's asset registries through
   `MEDIA_REFERENCE_FIELDS` — data, not another match arm — and an empty
   reference stays legal, falling back to the engine placeholder rather than
   refusing the pack.
   **Items family landed 2026-08-01:** `item` is a registered engine-owned schema
   projecting the existing `ItemData` surface, and roster inventory slots now
   admit items — closing the second half of the roster family's deferral.
   `effect_id` resolves through `ItemEffectRegistry` as an open vocabulary, so
   adding an effect entry admits it for authoring without editing the schema; an
   unregistered effect that `ItemHandler` used to discover as a `push_warning` at
   use time now fails the pack. An inventory slot holds exactly one of a weapon or
   an item, enforced in the roster contract rather than by `required` so the
   diagnostic stays slot-qualified (`units[i].inventory[j]`).
   **Still open from the Items handoff:** `item_type` is admitted as a plain
   string on purpose — it is a real `ItemData` property a pack may author, but
   nothing in the engine reads it, so binding a vocabulary now would invent a
   constraint no behaviour justifies; it lands with the first consumer. No
   `variants` array is admitted, for the same reason the roster family refused
   `faction`: nothing selects an item variant. Equip slots still wait on M10
   forging.
   **Maps/encounters family landed 2026-08-01:** `map_data` is a registered
   engine-owned schema, closing the largest unvalidated surface in a pack — the
   legacy check verified four fields, leaving placements, factions, turn order,
   activation mode, objectives, rewards, and camera entirely unchecked. **The
   governing decision is that authority is split, not duplicated.**
   `DataManager.collect_map_data_validation_errors` already validates tile bounds,
   terrain codes, faction/turn-order coherence, duplicate tiles, objective groups
   against alliance groups, and objective conditions; the Tier-2 path simply never
   reached it, and restating those rules in the schema contract would have created
   exactly the competing authority this plan forbids. So the **schema** owns
   document shape (admitted fields, types, vocabularies, JSON paths) and the
   **existing validator** owns semantics, now running at activation in
   `select_tier2_campaign_source` before `_commit_session` so atomicity holds and a
   Tier-2 pack is held to the same rules as project data. A test proves the split:
   an out-of-bounds placement tile is shape-valid JSON the schema admits, and
   activation still refuses the pack. `activation_mode` is CLOSED and
   single-sourced in `GameConstants.VALID_ACTIVATION_MODES` (a new mode is a
   turn-scheduler change) while objective types stay OPEN (a new objective is
   content); `tilemap_scene_path` is not admitted at all, because a pack carries
   indexed JSON plus approved Tier-1 media and can never ship the `PackedScene` it
   names.
   **Still open from the Maps handoff:** the plan's matrix splits Battle maps from
   Encounters, but `MapData` holds both, so v1 registers **one** document. The
   split belongs with the first encounter authored independently of its terrain.
   **Terrain family landed 2026-08-01:** `terrain` is a registered Tier-2 schema,
   but the family is two commits because terrain was the **only** family with no
   `*Data` resource behind it — its numbers were baked into six engine tables that
   each owned part of the same vocabulary and could drift (two separate move-cost
   tables keyed differently, the def/dodge bonus consts, `GameMap`'s char→source
   map, `DataManager`'s inline char set, and `TurnManager`'s `== "fort"` healing
   literal). Registering a schema over that would have authored a document nothing
   reads, so the tables were first consolidated into one `TerrainRegistry`. Costs
   are now keyed by `GameConstants.VALID_MOVEMENT_TYPES` rather than by HUD label,
   which is what removed the duplicate table; impassability is *derived* from the
   cost column rather than stored, so a terrain cannot declare itself passable
   while costing 999; and healing is now data (`heal_fraction`), so any terrain
   given a fraction heals. Whole-registry coherence — two terrains claiming one
   grid char are individually valid but make an authored map row ambiguous — has
   one owner: `CampaignTier2Validators` builds the same candidate registry
   activation builds and asks `TerrainRegistry.collect_coherence_errors()`, the
   maps precedent applied again. Terrain resolves *before* maps at activation,
   since a pack may retune which char means which terrain.
   **The terrain family's real boundary — and the v1 limit to revisit — is that a
   pack RETUNES terrain but cannot INTRODUCE it.** A tile's appearance comes from
   the engine's generated tileset by source id, and a pack carries only indexed
   JSON plus approved Tier-1 media, never the `TileSet` a new terrain would need —
   the same reason `map_data` refuses `tilemap_scene_path`. An unpaintable terrain
   would paint as `wall` with no diagnostic, so `id` resolves against a vocabulary
   seeded from the engine set and `tile_source_id` is not admitted at all. Lifting
   this needs `GameMap` to build tile sources from pack media at runtime — a
   rendering change requiring a Windows visual pass the container cannot provide,
   and the engine's placeholder tileset is what base-pack extraction (Slice 4)
   replaces anyway. Retunes merge field by field, so a partial `move_costs` map
   leaves the rest of the column intact.
   **Still open from the Terrain handoff:** `RULE-011` terrain ID mapping
   (throne-vs-fort) stays an open GDD decision — this change makes it cheaper to
   answer, since a throne is now a terrain with its own `heal_fraction` rather than
   a second literal, but does not answer it. Custom author-designed terrain,
   decorative variants sharing one stat block, and terrain-defined *actions* are
   deliberately not decided here; they are the subject of
   `DESIGN-TERRAIN-AUTHORING-2026-08-01`, to be held **before** further terrain
   implementation because three of those four questions would change the schema
   this family just shipped.
   **Terrain authoring discussion HELD 2026-08-01 — three of those answers change
   this family, so read them before reopening terrain.** Decisions `[TER-1..10]` are
   recorded in `../design/terrain_authoring_decisions_2026-08-01.md`. What changes
   here: **the retune-only boundary above is LIFTED** (`[TER-2]`) — a pack may
   introduce terrain, with `GameMap` building tile sources from pack media at
   activation, which **supersedes** `tile_source_id`'s exclusion as "engine identity".
   The *reason* for that exclusion still stands, so its replacement must fail
   validation when a terrain's media does not resolve rather than silently painting as
   `wall`. A **variant layer** (`[TER-1]`) splits art identity from stat identity, with
   the tileset's `terrain_type` custom data still carrying the **terrain id** so
   `get_terrain_at` and every id-matching consumer are untouched; this is what
   **answers `RULE-011`/`AWR-8`**, closing it when the build lands and not before.
   `heal_fraction` later becomes one entry in a phase-effect list (`[TER-6]`), which is
   deliberately queued behind `ARCH-ONE-PRIMITIVE-LIST-2026-08-01` so terrain effects
   register as primitives instead of forming a sixth dispatch table. What does **not**
   change: terrain gains no player-initiated actions (`[TER-3]`) — those stay
   `map_objects` per `[DCH-2]`/`[SAC-1]` — and the terrain/`map_object` line is
   per-instance save state (`[TER-4]`). `[TER-1]` and `[TER-2]` build **together** as
   the next terrain change (tracker `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01`):
   they need the same runtime tile-source machinery, and `[TER-2]` needs a Windows
   visual pass the container cannot provide.
4. **`IMPL-ZERO-CONTENT-BASE-PACK` — extract playable content once.** Build the
   base game as an ordinary self-contained pack, using the same importer/installer/
   selector path as third-party packs. Coordinate with `LEG-AUDIT-FE-NUMBERS-2026-07-20`:
   audited values and provenance move or are retuned once, never copied into two
   authorities. Owner decision 2026-07-30: independent of the audit's remedy, the
   current live balance is preserved as a self-contained internal-only
   Campaign_Pack_FE pack (workspace row `PACK-FE-CURRENT-BALANCE-2026-07-30`).
   FE-derived values and their provenance land in that pack, never in the public
   base pack, which retunes any entry the audit marks as transcribed — the audit
   scopes the public retune; it no longer decides whether the FE pack exists. The
   extraction inventory's destination column therefore admits both targets, and
   each FE-derived value still has exactly one authority.
   Exit: first end-to-end playable slice selects the base pack, starts
   a campaign, loads a map/roster and finishes one encounter.
   **Status 2026-08-05 — extraction now emits an encounter per map, so the exit is
   reachable but is NOT met yet.** `extract_proving_grounds_pack.gd` joins each
   `BattleMapDef` to its `BattleEncounterDef` (placements with inline units,
   factions, turn order, activation mode, objectives, rewards) and carries the full
   unit surface including inventories, so both packs activate with 8 playable maps
   and no unarmed unit — `validate_pack.gd --require-playable` is the machine check,
   and it now validates by ACTIVATING rather than by adapting. What is still
   unproven is the last clause: nobody has *finished* an encounter from the pack.
   That is a human-with-a-display step and is what the v0.7.0 bundle buys
   (`V070-BUNDLE-EXECUTION-2026-08-04`); the row closes on that evidence, not on
   this change.
   Two families are still absent from the pack and are reported as gaps by the tool
   rather than assumed: **skills** (units carry skill ids that nothing in the pack
   resolves, so they answer against the engine's own set) and **fog** — an encounter
   that authors `fog_enabled` extracts as a clear map, because the registered
   `map_data` schema admits no such field. Fog is out of v0.7.0 scope; adding the
   field belongs with `IMPL-FOG-RENDER-2026-08-02`.
5. **`IMPL-ZERO-CONTENT-EXPORT-GATE` — Implemented 2026-08-09.** The
   project-data bridge is editor-gated and the package-less New Game activation path is gone.
   Every export preset excludes `data/**`, retaining that tree only as the
   extractor/test input in an editor checkout.
   Add export audit proving the engine PCK has no catalogue/playable definitions,
   and pack closure proving all referenced families are contained. Missing/invalid/
   mutated packs remain non-activatable with human-readable errors.

Every commit leaves `agent/integration` bootable. The extraction commit cannot
precede a passing replacement-pack fixture and rollback path.

## Player flows and failure/security cases

- No packs: Main Menu remains usable; New/Load explains how to install/select.
- Invalid pack: package remains listed as disabled with path-safe validator errors.
- Missing family/reference: activation fails before global state changes.
- Multiple packs: explicit selection; current active identity is visible. Package ids
  are library-unique; catalogue ids are case-fold unique across kinds within their own
  package. Raw entity-id lookup across installed packages is prohibited.
- Same display name/author/version is legal when package ids differ. Same package
  id/version with a different fingerprint is quarantined as a conflicting build.
- Removed pack with saves: save remains indexed but disabled; persistence plan owns
  compatible-pack resolution/import behavior.
- Reject traversal, symlinks, duplicate/case-colliding ids/paths, unknown kinds,
  unknown primitive/formula ids, unindexed bytes, and partial activation.
- Equal/case-folded display names or localization keys remain legal, but exporter and
  loader emit severe non-suppressing diagnostics naming every package/entity/path.

### Import and media authoring flow

File and recursive-folder import are atomic authoring-tool operations. The tool
normalizes safe relative paths, decodes the real media type, generates a stable local
logical id, byte size and SHA-256, updates the asset registry/catalogue, and rolls back
the whole batch on an unaccepted error. Hash matches offer reuse; id/path collisions
show both candidates and require rename, reuse, or replacement. Reimport never silently
changes a finalized version: it produces a dirty draft snapshot and a new fingerprint,
and same-version replacement requires explicit confirmation.

Authors normally choose files/folders and answer only exceptional prompts: identity
collision, unknown rights, required attribution, or unsupported media. Generated
integrity fields are read-only in the normal editor. Optional `author_notes` remain
editable. v1 admits only decoder-verified inert raster/audio/font formats already on
the project allow-list. SVG is not production-admitted until a separate contract
defines active-feature sanitization, external-reference rejection, and canonical
decode behavior; a private logical-media fixture does not grant that admission.

### Validation phases and diagnostics

Validation aggregates all safely discoverable errors in phases: manifest, catalogue
structure, document structure, provenance/cross-references, then package closure. A
blocking failure suppresses only dependent later phases. Stable output order is
document path, JSON/field path, then diagnostic code. Deliberately invalid fixture
expectations live outside realistic package roots at
`tests/expected_errors/<fixture-id>.json`; production closure has no test-metadata
exception. The Godot validator/schema registry is canonical, and it owns the closed
diagnostic-code registry: the code strings pinned by the current private fixture
corpus are provisional inputs to be ratified or remapped in the Z0 parity slice.
Python/CLI tooling must
invoke it or consume its generated projection and may not define competing rules.

## Verification and documentation

- Focused validators/adapters per family; hostile archive and cross-family fixtures;
  atomic activation/deactivation; no-pack boot; invalid/missing-family UI tests.
- Class fixtures prove existing fields pass, unknown fields report exact paths,
  missing/dangling provenance differs from missing occurrence coverage, cross-owner
  and identity variant overrides fail, selected variants round-trip/migrate, and
  cancelled or failed advancement routes mutate nothing.
- Fixture exits also prove draft/finalized authoring gates, typed handler/fact
  failures, pack-local skill/item references, variant map-removal warnings, package-id
  and fingerprint conflict handling, presentation-name warnings, and recorded-selection
  restore.
- Z0/Z1 parity consumes the private fixture suite's external expected-error corpus and
  proves phased multi-error ordering, empty finalized/non-playable semantics, rights
  records with author notes, media integrity generation, and same-id/version conflict
  quarantine against the canonical Godot validator.
- Export audit compares admitted engine paths against a forbidden playable-family
  list; base-pack closure walks every reference. Full `run_tests.sh` per slice.
- Windows: install/select pack, no-pack/invalid-pack dialogs, New Game and one full
  encounter; check focus, readable diagnostics, and pack identity labels.
- DoD#1: update GDD 01/03/04/05/06/07/08 as affected and GDD 10 plus Feature Index
  in each behavioral slice. Control Plane owns status/sequencing.
- DoD#2: extend `AGENT/Docs/check_docs.py` in the same slice that ratifies the
  engine-export no-content and self-contained-pack rules.

## Exclusions and supersession

No pack scripts, general expressions, dependencies, hidden inheritance, editor
redesign, DLC/store service, or save migration implementation here. Supersede the
“engine owns saves” wording in `campaign_pack_engine_boundary_plan_2026-07-15.md`
with “engine writes user state; package identity owns namespace/interpretation”;
retain its executable-authority and archive-security decisions. This plan refines,
not replaces, the Project Control Plane.
