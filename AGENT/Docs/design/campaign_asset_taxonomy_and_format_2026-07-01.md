---
Type: design
Status: Active - architecture contract
Last verified: 2026-07-01
---

# Campaign Asset Taxonomy & On-Disk Format

**Started:** 2026-07-01, from the Band 5-8 review walkthrough
([`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
"Walkthrough Decisions (2026-07-01)", the campaign-asset-taxonomy entry).

**Builds on (do not re-open):** the self-contained per-campaign pack model
`[ICO-1..6]` (RESOLVED 2026-06-23) in
[`campaign_save_expectations_and_foundations_2026-06-23.md`](campaign_save_expectations_and_foundations_2026-06-23.md)
and the pack-provenance rules in
[`content_pack_compatibility_resync_contract_2026-06-28.md`](content_pack_compatibility_resync_contract_2026-06-28.md).
Asset licensing is governed separately by `[LEG-4]`
(`legal_licensing_open_questions_2026-06-21.md`): committed art must be CC0/OGA-BY.

## Why this exists

A campaign is a **self-contained pack** in `user://` (defaults seed-copied
`res://`->`user://` on first run). Two facts from that model force a format
decision the pack builder, the loaders, and the sprite importer all depend on:

1. **Art lives in the package, never in the save, and is raw-loaded — no
   `.import`.** User-pack media cannot go through Godot's editor import pipeline
   (it does not exist for `user://` files in an exported build), so media must be
   loaded from raw files at runtime.
2. Packs are meant to be **shared/exported** and the save is already
   **human-readable JSON + integrity hash**.

These split campaign assets into two format tiers.

## Tier 1 — Media / art (raw-loaded)

Referenced by `String` path/id, resolved through the shared `AssetResolver`
(below), never via `preload`/`.tres` resource references.

| Asset group | Contents | Format |
|---|---|---|
| Unit / map sprites | map-sprite sheets -> `SpriteFrames` (the sprite importer's job) | **PNG** sheets |
| Tilesets | terrain tiles | **PNG** |
| Icons | item / weapon / resource / effect / condition / skill icons | **PNG** (alpha) |
| Portraits | character portraits / speaker plates | **PNG** |
| Backgrounds | dialogue / cutscene, prep / hub, campaign banner / cover | **PNG**; JPG allowed for opaque art |
| UI skin | panel frames / styleboxes, button atlas | **PNG** |
| Fonts | UI + dialogue typefaces | **TTF / OTF** |
| Audio | music (BGM), SFX | **OGG Vorbis**; WAV allowed for short SFX |

**Format rationale:** each is chosen for runtime raw-loadability without the
editor import pipeline (the `[ICO-6]` constraint). PNG is confirmed in use today
via `Image.load_from_file` -> `ImageTexture` (`resolve_icon()` seam).

> **OPEN SPIKE (blocks locking the loader seam):** verify the Godot 4 runtime
> raw-load API for **OGG audio** and **TTF/OTF fonts** from `user://` in an
> **exported** build. PNG is confirmed; the audio/font loaders are NOT. The
> formats above are the target; the exact load call must be proven before the
> asset loader is built. Do not assert an API here until the spike lands.

## Tier 2 — Structured data (schema-validated)

Loaded and validated through `DataManager` (which already has a validator
culture). **Format = JSON, canonical** (owner decision, 2026-07-01).

| Asset group | Contents |
|---|---|
| Content resources | weapons / items / classes / skills / conditions / effects / styles |
| Campaign graph | nodes, `map_id` refs, `next`, per-node required / excluded / cap |
| Rules | mandate (locked) / default (editable), `protected_fields`, story-flip points |
| Maps | `MapData` geometry |
| Labels / localization | display strings by `label_key` |
| Registry display metadata | `label_key` / `icon` / `help_key` per registered id |
| Pack manifest | pack id / version, `forked_from`, `builder_content_version`, `format_version` |

**Why JSON canonical (not `.tres`):**
- Same family as the save format (human-readable JSON + integrity hash), so packs
  are diffable and tool-neutral.
- Decoupled from Godot `Resource` script-schema versioning — a pack does not break
  when a `Resource` subclass changes shape.
- External / future authoring tools can read and write packs without Godot.

**Authoring path:** the built-in **default** content palette MAY be authored as
`.tres` in-editor for inspector convenience, then **serialized to JSON at build**
into the default pack. User packs are **pure JSON**. `.tres` is an
authoring-time convenience only — JSON on disk is the single source of truth.

**Cost accepted:** a JSON <-> `Resource` load/validate path per content type. This
extends `DataManager`'s existing validator loud-fail culture (missing fields,
bad refs, wrong types fail with actionable messages).

## Pack layout

```
user://campaigns/<pack_id>/
  manifest.json                 # Tier 2: id/version/provenance/format_version
  data/                         # Tier 2: content, graph, rules, maps, labels, registry metadata
  art/
    icons/ portraits/ backgrounds/ sprites/ tilesets/ ui/   # Tier 1: PNG (JPG opaque bg)
  fonts/                        # Tier 1: TTF/OTF
  audio/
    music/ sfx/                 # Tier 1: OGG (WAV short SFX)
```

## Asset resolution (open registry)

All assets are referenced by `String` path/id and resolved through a shared
**`AssetResolver`** (per the UI-designs review,
[`band_ui_initial_designs_review_2026-06-30.md`](../../Code%20Reviews/band_ui_initial_designs_review_2026-06-30.md)).
Asset **groups are registry entries**, each supplying a loader + a fallback chain,
so a new group (e.g. cutscene video later) registers a resolver rather than
requiring an engine edit. Fallback chain (missing asset never crashes a pack):

- missing item/weapon icon -> text-only row (+ generic item icon if the layout
  needs one);
- missing portrait -> class/faction silhouette or neutral speaker plate;
- missing dialogue/background art -> live map background or neutral prep
  background;
- missing panel skin -> default engine `UiThemeDef`;
- missing resource/effect icon -> text label + generic token;
- missing sprite/tileset -> generated placeholder tile, with a validation warning.

## Definition of done (when implemented)

- **DoD#1:** this is a behavior-shaping contract; when the loader/format is built,
  update the affected GDD section(s) and flip the matching `GDD_10` status in the
  same commit.
- **DoD#2:** if a checkable rule is ratified here (e.g. "Tier 1 media must be
  PNG/OGG/TTF", "Tier 2 pack data must be JSON"), land its `check_docs.py` guard
  in the same change.
- **Sequencing:** the OGG/TTF raw-load spike must retire before the media loader
  seam is locked; the sprite importer (`B6-SPRITE-IMPORTER`, `IMP-1..6`) stays
  HELD until asset sourcing is decided, but consumes this taxonomy when it builds.

## Open questions (resolve at implementation)

1. **OGG/TTF raw-load API** (the spike above) — the one hard technical unknown.
2. **Integrity hashing scope** — does the pack carry a manifest-level integrity
   hash over Tier 2 (like the save), and does it cover Tier 1 media too?
3. **JSON schema versioning** — per-file `format_version` vs one pack-level
   version; ties to `builder_content_version` provenance (no cross-version
   migration pre-1.0).
