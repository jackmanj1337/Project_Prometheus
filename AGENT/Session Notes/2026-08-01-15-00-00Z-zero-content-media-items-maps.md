# Session Note - 2026-08-01-15-00-00Z-zero-content-media-items-maps

## Branch context

- Branch: `agent/from-integration/zero-content-families-maps`
- Base branch: `agent/integration`
- Base SHA: `30f277fa` (merge that landed class/weapons/rosters onto integration)
- Coordination Work ID: `IMPL-ZERO-CONTENT-FAMILIES`

## Scope this session

Owner asked for three families in one session: **media, items, maps**. This is the
plan's dependency order (`registries/media → minimal skill/item identity → …
maps/encounters`), and it deliberately front-loads media so the asset/item
cross-reference deferral carried past class, weapons, and rosters closes *before*
maps needs it rather than being shaped by maps alone.

## State entering the session

Registered engine-owned schemas: `class`, `advancement_edge`, `advancement_route`,
`weapon`, `roster`. Legacy shape checks only: `campaign`, `map_registry`,
`map_data`, `item`. No kind at all: media/`asset_registry`, skills, terrain,
pair-up. Full suite green at baseline (all suites pass, corpus 11/11).

## Decisions taken (and why)

1. **`decoded_type` is an allow-list, not a decode.** The implementation plan
   (§ Import and media authoring flow) states v1 admits "decoder-verified inert
   raster/audio/font formats already on the project allow-list" and that **SVG is
   not production-admitted**. That allow-list already exists as
   `CampaignArchivePreflight.APPROVED_MEDIA_EXTENSIONS` (`png, ogg, wav, ttf, otf`),
   so the media vocabulary is seeded FROM it rather than restated — same
   single-source rule the weapon family used for combat families.
2. **Integrity is verified, not trusted.** `byte_size` and `sha256` are checked
   against the real file, and magic bytes are checked against the declared type.
   Full decode belongs to the authoring/import tool; magic-byte verification is the
   validation-time weight and is strictly stronger than trusting the field.
3. **The Z0/Z1 corpus is a different path and is not touched.** It is validated by
   `ZeroContentFixtureValidator` (package shell), uses kind `fixture_identity`, and
   its media record is explicitly a "logical-media fixture" that "does not admit SVG
   for production packages". The Tier-2 `asset_registry` kind is separate; the SVG
   fixture stays valid at the shell level.

## What was done

### 1. Media (`asset_registry`) — LANDED

`asset_registry` is a registered engine-owned schema. It is one of the
infrastructure documents exempt from document-level `source_refs` (with the
catalogue, manifest, and source registry), but every record inside it is
validated. Logical ids are author-defined, so `assets` carries **no** key
vocabulary — the values are what is bounded.

- **Admission** reuses `CampaignArchivePreflight.APPROVED_MEDIA_EXTENSIONS`
  (`png, ogg, wav, ttf, otf`). `MEDIA_TYPES_BY_EXTENSION` adds only the canonical
  type per admitted extension, and a test asserts the table covers the allow-list
  exactly — adding an extension without a type fails a test instead of silently
  admitting an untyped format. SVG fails on the extension, by design.
- **Integrity is verified, not trusted.** `byte_size` and `sha256` are compared
  against the real file, and magic bytes against the declared type. A mutated
  asset now fails under a record that still looks internally consistent.
- **New seam:** `Tier2Catalogue.pack_root`, because the filesystem pass needs a
  root that `validate_document` deliberately does not take. The archive path
  leaves it empty and skips integrity — `CampaignArchivePreflight` already checks
  archive bytes there.
- **The carried deferral is CLOSED.** Registered class/weapon/item documents
  resolve `sprite_id`/`icon` against the pack's asset registries via
  `MEDIA_REFERENCE_FIELDS` (data, not another match arm). An empty reference stays
  legal — the engine falls back to its placeholder rather than refusing the pack.
- **Runtime adoption:** `Result.assets` maps each logical id to a loadable path.

### 2. Items — LANDED

`item` is a registered engine-owned schema projecting the existing `ItemData`
surface, and roster inventory slots now admit items. That closes the second half
of the roster family's deferral ("inventory slots admit weapons only").

- **`effect_id` resolves through `ItemEffectRegistry`**, seeded as an open
  vocabulary so adding an effect entry admits it for authoring without editing the
  schema file. `ItemHandler` previously discovered an unregistered effect as a
  `push_warning` at use time; it now fails the pack.
- **`item_type` is admitted as a plain string on purpose.** It is a real
  `ItemData` property, so a pack may author it, but nothing in the engine reads it
  — binding a vocabulary now would invent a constraint no behaviour justifies.
  The vocabulary lands with the first consumer.
- **No `variants` array**, for the same reason the roster family refused
  `faction`: nothing selects an item variant, so the surface would be unread.
- **An inventory slot holds exactly one of a weapon or an item**, enforced in the
  roster contract rather than by `required` so the diagnostic is slot-qualified
  (`units[i].inventory[j]`). Equip slots still wait on M10 forging.
- The adapter narrows JSON-float `effect_params` back to integers — the same trap
  proven twice on weapons and rosters.

### 3. Maps/encounters — LANDED

`map_data` is a registered engine-owned schema. This closed the largest
unvalidated surface in a pack — the legacy check verified four fields, leaving
placements, factions, turn order, activation mode, objectives, rewards, and camera
entirely unchecked.

**The key design decision: do not duplicate what already exists.**
`DataManager.collect_map_data_validation_errors` is ~380 lines that already
validate tile bounds, terrain codes, faction/turn-order coherence, duplicate tiles,
objective groups against alliance groups, and objective conditions (through
`ObjectiveConditionRegistry`). The Tier-2 path simply never reached it. Writing
those rules into the schema contract would have created exactly the competing
authority the implementation plan forbids, so instead:

- the **schema** owns document shape (admitted fields, types, vocabularies, JSON
  paths);
- the **existing validator** owns semantics and now runs at activation in
  `select_tier2_campaign_source`, before `_commit_session`, so atomicity holds and
  a Tier-2 pack is held to the same rules as project data.

A test proves the split: an out-of-bounds placement tile is shape-valid JSON that
the schema admits, and activation still refuses the pack.

Other decisions:
- **One document, not two.** The plan's matrix splits Battle maps from Encounters,
  but `MapData` holds both, so v1 registers one document and records why. The split
  belongs with the first encounter authored independently of its terrain.
- **Inline placements reuse the roster `unit` object** rather than a second copy
  that would drift.
- **`activation_mode` is CLOSED, objective types are OPEN.** A new activation mode
  is a turn-scheduler change; a new objective is content. The closed one is now
  single-sourced in `GameConstants.VALID_ACTIVATION_MODES` so the schema and
  `DataManager` cannot drift.
- **`tilemap_scene_path` is not admitted at all** — a pack carries indexed JSON
  plus approved Tier-1 media, so it can never ship the `PackedScene` it names.
- **Condition group keys carry no key vocabulary** (author-defined names), unlike
  the roster's stat/track maps.

**A latent bug found and fixed:** `MapData.factions` is an `Array[FactionData]`
export that `_apply_properties` silently left EMPTY — the fifth instance of that
Godot trap in this work. An authored faction list became the blue+red default with
no diagnostic at all. The adapter now builds factions explicitly (including the
JSON-array→`Color` conversion).

**DSL additions:** array `max_items` (a tile is exactly `[x, y]`; a third
coordinate was accepted and then silently discarded by the `Vector2i` conversion)
and a `number` type for colour channels.

## Commits claimed

- `b51f2659c519189a39f0108bb834a6bd97169246` — Add the Tier-2 media identity family (asset_registry)
- `202aeef1e2a79db393db549c2082fe3913872d68` — Add the Tier-2 items family and item inventory slots
- `c4e4b4ccb4842248884f40c3afa12e52bd8ab67c` — Add the Tier-2 maps/encounters family
- `2d01509f7269e9c699858c774c7e3f40638e443d` — Claim the maps commit and refresh GDD verification dates

## Gates

- Baseline before any change: `bash run_tests.sh` → **PASS: all suites green**
  (includes `test_zero_content_fixture_corpus: 11 passed, 0 failed`).
- After media: `test_entity_schema_registry` **49 passed** (was 44),
  `test_campaign_tier2_runtime_adapter` **11 passed** (was 8), full suite green,
  `check_gdscript_style` PASS (260 files), `check_docs.py` PASS.
- After items: `test_entity_schema_registry` **52 passed**,
  `test_campaign_tier2_runtime_adapter` **12 passed**, full suite green,
  `check_gdscript_style` PASS.

- After maps: `test_entity_schema_registry` **56 passed**,
  `test_campaign_tier2_runtime_adapter` **15 passed**, full suite green (115
  suites), `check_gdscript_style` PASS (260 files), `check_docs.py` PASS.

## Still open (deliberately, not forgotten)

- **Equip inventory slots.** `InventoryEntry`'s equip fields are M10 forging
  surface nothing authors or reads; admitting them now would repeat the `faction`
  mistake.
- **`item_type` vocabulary.** Lands with the first engine consumer.
- **The class family's growth/cap key vocabulary.** Still values-only. One line
  each, and still the cheapest follow-up — take it the next time the class family
  is opened for another reason, not as an unprompted reopen.
- **Battle-map / encounter document split.** v1 is one document; the split belongs
  with the first encounter authored independently of its terrain.
- **The plan doc was NOT amended this session.** `AGENT/Docs/plans/` is fenced off
  feature branches by the pre-commit docs-guard. Following last session's
  precedent, the plan amendment should land by merging this branch **forward** into
  `agent/integration` (the docs line) rather than by overriding the guard with
  `DOCS_GUARD_OVERRIDE=1`.

## Next

Remaining Slice 2 families, in the plan's dependency order: **terrain** (small, and
maps has just established what a terrain asset id means), then **skills**,
**pair-up**, and the remaining **registry documents**, then **campaigns** +
**map_registry** last, once every id they reference resolves.

Then Slice 3 (`IMPL-ZERO-CONTENT-BASE-PACK`), whose one live external blocker is
`LEG-ENGINE-ASSET-PROVENANCE-2026-07-26` — 51 engine art assets needing individual
provenance review. That can proceed in parallel at any time.
