---
Role: dated
Type: design
Status: Active - architecture contract
Last verified: 2026-07-31
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

A campaign is a **self-contained pack** in `user://`. **How a pack gets there
differs by channel, deliberately** (`[CSA-31]`(d), `[CSA-35]`):

- **Desktop — the program ships no campaign pack at all.** Packs are distributed
  *alongside* the executable and arrive by **explicit user-initiated import**,
  never by silent auto-install and never by a seed copy (`[CSA-33]`(b)). "No
  packs installed" is the ordinary first-run state, not an edge case (`[CSA-33]`).
- **Web — exactly one pack is packaged inside the bundle** and seeded
  `res://`→`user://` on first run, because on web there is no "alongside": the
  browser receives one bundle and `user://` is browser storage a cache clear
  wipes (`[CSA-35]`, resolved C). It re-seeds naturally after such a clear.
  **That pack's art must be entirely first-party, generated, or CC0** — a
  *validated* property via `[CSA-6]`'s `rights_status`, not a promise. It cannot
  be a trimmed `Campaign_Pack_0`, which has two formally CC-BY 4.0 sources.

> **The narrow seed path is web-only and licence-constrained.** The clause this
> replaced described a general "defaults seed-copied `res://`→`user://` on first
> run" for a shipped default campaign; **that** mechanism is retired — there is no
> default campaign to seed (`[CSA-2]`, `[CSA-31]`(d)). What survives is a single
> bundled demo pack on the web channel only. Do not generalise it back into a
> desktop default-content path.

Two facts from that model force a format decision the pack builder, the loaders,
and the asset manager all depend on:

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
editor import pipeline (the `[ICO-6]` constraint). The runtime seam is **not yet
built** (the `res://` default tilesets still go through the editor `.import`
pipeline), but the load API for every Tier-1 format is now **proven** — see the
spike result below.

> **SPIKE RETIRED (2026-07-02, Godot 4.6.stable):** the runtime raw-load API for
> **OGG audio**, **TTF/OTF fonts**, and **WAV** from `user://` is confirmed in a
> real **exported Linux template** (`OS.has_feature("editor") == false`, no
> `.import`), not just the editor binary. Proven load calls:
> - PNG: `Image.load_from_file(path)` -> `ImageTexture.create_from_image(img)`.
> - OGG: `AudioStreamOggVorbis.load_from_file(path)` (and `load_from_buffer(bytes)`)
>   — decoded a real 6.1 s stream from `user://`.
> - WAV: `AudioStreamWAV.load_from_file(path)` (round-tripped `save_to_wav` ->
>   load). MP3 (`AudioStreamMP3.load_from_file`) is also present if ever needed.
> - TTF/OTF: `var f := FontFile.new(); f.load_dynamic_font(path)` — err 0, real
>   font name + glyph metrics from a system DejaVu `.ttf` at `user://`.
>
> All are core-module bindings + core codecs (libvorbis/FreeType), so they survive
> templating; the export test confirmed it rather than assuming it. Evidence:
> session note `2026-07-02g`. **The loader seam is now unblocked to build.**

### Tier 1a — Sprite sheets & runtime slicing (owner decisions, 2026-07-02)

A **sprite sheet** is one PNG holding many sub-images addressed by rectangle. We
use them where art is naturally many-frames-drawn-together (batching + animation);
we do **not** force them where art is large and singular. Because everything
resolves through `AssetResolver` (id -> texture), callers never see the
difference, so a class can start as single files and be packed later without
touching call sites.

Per-class stance:

| Class | Sheet? | Rationale |
|---|---|---|
| Unit / map sprites | **Sheet** | Animated (idle/move rows per facing); FE art ships this way; the importer's input |
| Terrain tiles | **Sheet (tileset atlas)** | `TileSetAtlasSource` wants one texture + region size; enables autotiling. Today's per-tile PNGs are the placeholder shortcut, not the target |
| UI chrome (buttons, 9-slice frames) | **Sheet** | State-sets + frames pack and draw together |
| Icons (weapon/item/skill/condition/stat/resource) | **Both** | An author may pack their own icons as one atlas **or** drop in single files (adding one icon must not force an atlas repack). We ship no default icon set — see the note below |
| Portraits / backgrounds | **Single file** | Large, singular, loaded once, never batched |
| Fonts | n/a | Glyph atlas is generated by the rasterizer at runtime |

> **No shipped default art set** (`[CSA-28]`, `[CSA-31]`(d), 2026-07-31). This
> table describes what a **pack author** may do; it does not describe art we
> ship. The program's built-in shell chrome (main menu, campaign library, editor)
> is ordinary `res://` project art with **no manifest, no `art_asset@1` entry and
> no `AssetResolver` lookup** (`[CSA-28]`(e)) — it is outside this taxonomy
> entirely. Everything else is author-provided, and **absence falls back to
> engine primitives** — generated placeholder tiles, the default `UiThemeDef`,
> plain text rows — **never to a shipped default art set** (`[CSA-28]`(c)). That
> is what keeps the executable's licence surface empty rather than merely small.

**Why no `.import` help:** Godot's editor pipeline (which normally emits
`AtlasTexture` / `SpriteFrames` / `TileSet` from a sheet) does not run on `user://`
media in an exported build. So slicing happens **in code**:

1. Load once: `Image.load_from_file` -> `ImageTexture` = one GPU texture for the sheet.
2. Slice without copying pixels: per-frame `AtlasTexture` (`atlas` = sheet texture,
   `region` = frame rect). Regions share the one texture, so batching is preserved.
3. Consume: assign to `Sprite2D.texture`, add frames to a `SpriteFrames` for
   `AnimatedSprite2D`, build a `TileSet` + `TileSetAtlasSource` at runtime for
   terrain, or set `NinePatchRect.texture` + `patch_margin_*` for UI frames.

**Frame metadata = a JSON sidecar** (a bare PNG carries none — this replaces the
`.import`-generated atlas metadata):

- **Format:** `<name>.png` + a sibling **`<name>.json`** in the same `art/`
  subfolder (owner decision: per-file sidecar, not a global manifest section — an
  author edits one sprite without touching a shared file, and it mirrors the
  importer's emitted output).
- **Contents:** an explicit **named-frame table** — each frame a **two-point
  rectangle on the image's pixel grid**, with an **optional per-frame
  origin/pivot** defaulting to **bottom-centre** — plus animation defs (`frames`,
  `fps`, `loop`) and, for UI, 9-slice `margins`.
  - **REVISED 2026-07-31 (`[CSA-7]`).** The frame table is now *the* form, and
    the earlier rule — authored sheets standardize on a uniform grid, with the
    frame-table form reserved for a shipped default set — is **superseded on both
    halves**. There is no shipped default set (`[CSA-31]`(d)), so the reservation
    had no subject; and real third-party sheets are not uniform — they pack
    characters at varying sizes with irregular padding, so requiring a grid forced
    authors to re-cut source art before importing it.
  - A **uniform grid stays available as a convenience the editor can generate**
    (`cell` size + `columns`/`rows` expanded into the table), rather than a
    constraint the format imposes.
  - **Why the pivot is not optional-in-practice for irregular sheets:** a 24×32
    and a 32×32 frame in one animation need a shared anchor or the sprite jitters
    between frames. Bottom-centre is the conventional anchor for a unit standing
    on a tile, so the default is right for the common case and the grid path never
    has to state it.
  - The sheet's sidecar is **authoritative** for cell size — `TILE_SIZE` is not.
    The renderer scales to `TILE_SIZE` and **warns on a non-integer ratio**; that
    warning is **disableable**.
- **Fallbacks:** missing sidecar -> treat as single-frame (or a project-default
  grid); missing file -> placeholder + validation warning (per the fallback chain
  below).

**Author workflow:** drop `knight.png` (+ optional `knight.json`) into
`art/sprites/`, reference it by id in Tier-2 content (`ClassData.sprite_id ->
"knight"`); on load `AssetResolver` finds the file and a runtime slicer reads the
sidecar. The **campaign asset manager** is the tool that *produces* the PNG +
sidecar — an author with a clean sheet + sidecar can skip it.

> **⚠️ The tool changed identity, 2026-07-31.** This previously named the
> **sprite importer** (`B6-SPRITE-IMPORTER`, `[IMP-1..6]`) and pointed at
> [`map_sprite_importer_open_questions_2026-06-21.md`](../registers/map_sprite_importer_open_questions_2026-06-21.md).
> Both are superseded as a description of the authoring surface:
> - The scope is an **asset manager**, not a sprite importer — portraits, UI, map
>   tiles, backgrounds and dialogue art, not just unit sheets (`[CSA-17]`).
> - It lives in **our campaign editor**, never a Godot `EditorPlugin`
>   (`[CSA-11]`); `IMP-EDITOR-PLUGIN-2026-07-20` is **retired, not deferred**.
> - `[IMP-3]`'s output shape (editor-time `res://` `.tres`) is **superseded** by
>   the runtime `user://` PNG + JSON sidecar contract above (`[CSA-2]`).
>
> Current contract: [`../registers/campaign_sprite_authoring_open_questions_2026-07-30.md`](../registers/campaign_sprite_authoring_open_questions_2026-07-30.md)
> (`[CSA-1..37]`). Asset classes + reuse levers:
> [`ui_ux_asset_inventory_and_reuse_2026-07-02.md`](ui_ux_asset_inventory_and_reuse_2026-07-02.md).

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

**Authoring path: every pack is pure JSON. There is no `.tres` path.**
- **REVISED 2026-07-31 (`[CSA-2]`).** This paragraph previously carved out the
  built-in **default content palette**, which MAY have been authored as `.tres`
  in-editor and serialized to JSON at build "into the default pack". **There is
  no default pack and no built-in content palette** (`[CSA-31]`(d),
  `IMPL-ZERO-CONTENT-*`), so the carve-out had no subject and is deleted rather
  than narrowed.
- JSON on disk is the single source of truth for **all** packs, with no
  privileged authoring route for any of them. Content is authored in **our
  campaign editor** (`[CSA-11]`), which reads and writes JSON directly — authors
  do not have the Godot editor, so an inspector-convenience path was never
  reachable by the people who need it.

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
    # sheet folders (sprites/ tilesets/ ui/) may carry a sibling <name>.json
    # frame/animation/9-slice sidecar per sheet (Tier 1a)
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
- **Sequencing:** the OGG/TTF raw-load spike is **retired** (see the spike-result
  block above) — the media loader seam is unblocked to build. When it is built,
  DoD#2 fires: add the `check_docs.py` guards for "Tier 1 media = PNG/OGG/TTF(/WAV)"
  and "sheet sidecars = per-file JSON".
- **The importer is no longer HELD (2026-07-31).** It previously stayed held
  "until asset sourcing is decided"; asset sourcing **is** decided (`[CSA-1..36]`,
  and `[LEG-4]` governs what may be committed). `IMP-IMPORTER-CORE-2026-07-20`
  and `IMP-UNIT-ANIMATED-SPRITE-2026-07-20` are **ungated and ready**, and must be
  built to the contract in this document rather than `[IMP-3]`'s superseded
  output shape. Only the **UI-facing** work is gated, by
  `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`.

## Open questions (resolve at implementation)

1. ~~**OGG/TTF raw-load API**~~ — **RESOLVED 2026-07-02** (spike retired above; all
   Tier-1 loaders proven in an exported build).
2. **Integrity hashing scope** — does the pack carry a manifest-level integrity
   hash over Tier 2 (like the save), and does it cover Tier 1 media too?
3. **JSON schema versioning** — per-file `format_version` vs one pack-level
   version; ties to `builder_content_version` provenance (no cross-version
   migration pre-1.0).
