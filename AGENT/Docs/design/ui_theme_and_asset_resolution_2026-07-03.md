---
Role: dated
Type: design
Status: Target design (author-facing contract)
Last verified: 2026-07-31
---

# UiThemeDef & Asset Resolution — Presentation Contract

**Started:** 2026-07-03. A **thin, author-facing contract** for how UI presentation
(skins, colors, fonts, icons, backgrounds, audio slots) and user-supplied art
resolve — so Band 4-6 panel plans reference *shared tokens + one resolver* instead
of each inventing local labels, colors, and asset lookups. This note **locks the
token schema shape, the id/path convention, and the fallback chain**; it does not
enumerate every future token (the schema is an open registry — see below) and it is
not an implementation plan.

It is the deliverable the band-UI review asked for: *"Add a thin `UiThemeDef` /
asset-resolution design note before more PHB panels are planned"*
([`band_ui_initial_designs_review_2026-06-30.md`](../../Code%20Reviews/band_ui_initial_designs_review_2026-06-30.md)).
It consumes the asset taxonomy
([`campaign_asset_taxonomy_and_format_2026-07-01.md`](campaign_asset_taxonomy_and_format_2026-07-01.md))
and the asset inventory / reuse map
([`ui_ux_asset_inventory_and_reuse_2026-07-02.md`](ui_ux_asset_inventory_and_reuse_2026-07-02.md)).

## Grounding & what is already true

- The Tier-1 **raw-load API is proven** (the OGG/TTF spike is **retired** — taxonomy
  doc "SPIKE RETIRED" block, session note `2026-07-02g`). So font and audio tokens
  below name **real load calls** (`FontFile.load_dynamic_font`,
  `AudioStreamOggVorbis.load_from_file`), not a deferred unknown. PNG is
  `Image.load_from_file` -> `ImageTexture`.
- `FactionData.color: Color` (exists, `FactionData.gd:23`) and `ClassData.sprite_id:
  String` (exists, `ClassData.gd:63`) are the two live art seams; the resolver reuses
  them rather than adding parallel fields.
- `MenuScale._scaled_theme(factor)` already builds a runtime Godot `Theme` from engine
  defaults and assigns it to `Control.theme` (`scripts/ui/MenuScale.gd:94`). **This is
  the display-scale layer and it stays.** `UiThemeDef` is the *authored* layer that
  feeds into the same built `Theme` (see "Relation to menu-scale" below) — the two
  compose; neither replaces the other.
- All campaign art is copied to `user://` and raw-loaded by id/path (`[ICO-5/6]`).
  Missing art is a validation **warning + fallback**, almost never a hard error.

## Two seams (both open registries, per the `[EXT]` principle)

1. **`UiThemeDef`** — a data resource (**JSON in a pack; there is no `.tres` shipped
   default** — revised 2026-07-31, `[CSA-2]`/`[CSA-31]`(d))
   holding **presentational tokens only** (`PHB-6`: no discounts / stock / objectives /
   rules ever live in a theme). A theme is a flat bag of named tokens; unknown token
   names are ignored, missing ones fall back. **Theme ids are authored data**, resolved
   through the registry/validation path — never a closed GDScript `enum` + `match`.
2. **`AssetResolver`** — one function `resolve(kind, id_or_path) -> Resource` that maps a
   string to a loaded Tier-1 asset (texture / font / stream), applying the fallback chain
   and emitting a validation warning on miss. Every panel, the board, dialogue, and the
   importer call *this*; no call site does `Image.load_from_file` itself.

Callers ask the theme for a **token**, or the resolver for an **asset id** — never a raw
file path baked into a scene.

## Token schema (thin v1 — grouped, extensible)

Start with these groups; add tokens as panels need them (open registry — adding a token
is authoring data, not an engine edit). Every token is **optional**; an unset token uses
the next fallback level.

| Group | v1 tokens (ids/paths unless noted) | Notes |
|---|---|---|
| **Colors** | `accent`, `text_primary`, `text_muted`, `warning`, `error`; overlay tokens `range`, `threat`, `valid_target`, `aoe`, `heal`, `danger` | `Color` values. Overlay tokens drive the **one white tile + `modulate`** lever — colors, not 6 PNGs |
| **Panel chrome** (9-slice) | `panel_frame`, `button` (state-set), `tooltip`, `list_row`, `slider`, `scrollbar`, `divider`, `modal_scrim` | Resolve to StyleBox/`NinePatchRect` textures + margins (sidecar JSON per Tier 1a) |
| **Fonts** | `font_body` (SDF), `font_numeric` (tabular figures), `font_title` | TTF/OTF ids -> `FontFile.load_dynamic_font` |
| **Icons** | `icon_atlas_default` (the active pack's fallback icon atlas) | Per-entry icons come from **registry `icon` metadata**, not the theme; the theme only supplies this atlas + a generic fallback token. **Pack-supplied, not shipped** — see the note below |
| **Cursor / selection** | `cursor`, `selection_ring`, `highlight` | Shared board + menu primitive |
| **Backgrounds** | `bg_main_menu`, `bg_prep_hub`, `bg_stage_default`, `bg_gameover`, `bg_victory`, `bg_defeat` | Large single files; fall back to live map / neutral plate |
| **Stage** | `stage_speaker_frame`, `stage_nameplate` | Shared by dialogue **and** activity intros (`StagePresentation`) |
| **Audio slots** | `sfx_cursor`, `sfx_select`, `sfx_cancel`, `sfx_error`, `stinger_reward`, `music_map`, `music_hub` | OGG ids -> `AudioStreamOggVorbis.load_from_file`; silent fallback |

Rationale for thin: every panel plan will reference token *names*, so renaming later
touches every consumer. Ship few, well-named tokens; grow the registry, don't reshape it.

> **⚠️ "default" in a token name means *fallback within the active pack*, not art
> we ship** (`[CSA-28]`, `[CSA-31]`(d), 2026-07-31). `icon_atlas_default` named a
> "default packed atlas" before this revision, which read as a shipped asset set;
> the program ships **no default art** outside its own shell chrome, and shell
> chrome is not reachable through `AssetResolver` at all (`[CSA-28]`(e)). An
> **unset** token therefore falls back to **engine primitives** — a generic token,
> a text-only row, the default `UiThemeDef` — never to a shipped art set
> (`[CSA-28]`(c)). Applies to every `*_default` token in this table.
>
> Related: the per-campaign UI theme is **pack-supplied**, and a player's theme
> preference is remembered **per pack** — across campaigns and runs within it. If
> a pack removes the theme a player selected, fall back to that pack's default and
> **say so once** (`[CSA-27]`).

## Reference model — id vs path

- **Authors reference by asset id** wherever reuse matters (icons, fonts, portraits,
  sprites); ids resolve to raw paths inside the pack's `art/` tree via `AssetResolver`
  (matches band-UI review Q2 recommendation).
- A **raw relative path** is allowed as an escape hatch for one-off art.
- Ids are stable content keys; paths are an implementation detail of one pack. Prefer ids
  in shared/registry contexts so a pack can relocate a file without editing content.

## Resolution & fallback chain (per token / per asset)

Resolve in this fixed order; first hit wins (from the band-UI review):

1. Panel / activity **explicit override** (a token set on the specific surface).
2. Progression-node `theme` (per-map / per-node override — the 3-layer resolver from
   the 2026-07-01 walkthrough).
3. **Player-selected theme for the active pack**, if the pack offers a choice and the
   player has made one — remembered **per pack**, across campaigns and runs
   (`[CSA-27]`).
4. **Campaign default theme** (the pack's `UiThemeDef`).
5. **Engine fallback**: default Godot `Theme` + generated placeholder asset, with a
   validation warning.

> **⚠️ REVISED 2026-07-31 — one step removed, one added.** The old step 4,
> *"**Shipped default theme**, copied into `user://` on first run"*, is **deleted**:
> the program ships no pack and no seed copy runs on first run (`[CSA-31]`(d),
> `[CSA-33]`(c)), so that step had nothing to resolve to and a chain declared
> "locked" would have kept a dead rung in it. A pack with no theme now falls
> straight from its own default to the engine fallback, which is `[CSA-28]`(c)'s
> "absence falls back to engine primitives, never a shipped art set".
>
> The new step 3 is the `[CSA-27]` player override. It sits **above** the pack
> default deliberately: authors own accessibility, but a player who cannot read a
> theme must still have somewhere to go, and the override is worthless below the
> value it is meant to override.

Per-asset fallbacks (from the inventory / band-UI review): missing icon -> text-only row
(+ generic token); missing portrait -> class/faction silhouette; missing background ->
live map / neutral plate; missing panel skin -> default `UiThemeDef`; missing sound ->
silent (unless the content explicitly marks it required).

**Order is itself a contract:** once panels assume this precedence, changing it silently
re-skins existing packs. Treat the order as locked.

## Relation to menu-scale (integration, not replacement)

`MenuScale` owns **display scaling** (font size + container spacing × the user's scale
factor, cached per factor). `UiThemeDef` owns **authored appearance** (which font face,
which stylebox, which colors). The build path composes: resolve the authored `UiThemeDef`
-> produce a Godot `Theme` (fonts/styleboxes/colors from tokens) -> hand that themed base
to the menu-scale step, which multiplies sizes/spacing by the factor. Neither hardcodes
the other; a campaign changing its font must not break menu-scale, and vice-versa.

## What this locks (weigh before ratifying)

- **Token names** — every panel plan references them; renaming is a cross-consumer edit.
  Mitigation: thin + well-named from the start.
- **Fallback order** — changing precedence re-skins existing campaigns silently.
- **id-preferred convention** — shapes how every content ref is authored; hard to reverse
  once packs exist on disk.
- **"Presentational only" (`PHB-6`)** — deliberately permanent; keeps mechanics out of skins.

## Required vs optional assets

Almost nothing is a hard error. Missing assets emit a validation **warning** and take a
fallback, **except** an asset a specific authored activity/content marks `required: true`
(band-UI review Q3). Build the missing-asset fallback tests early (review rec #5) so a
user pack never crashes on an absent portrait / icon / background.

## Definition of done (when implemented)

- **DoD#1:** this is a behavior-shaping contract — when `UiThemeDef` / `AssetResolver` are
  built, update the affected GDD section(s) and flip the `GDD_10` status in the same commit.
- **DoD#2:** land `check_docs.py` guards for the ratified rules — token names are
  registry-driven (no closed enum), theme carries no mechanical fields (`PHB-6`), and the
  fallback order is the five levels above.
- **Tests first-class:** missing-asset fallback + resolution-order tests ship with the
  resolver (there is no seam to test yet, so no test is committed now — DoD, not debt).

## Open questions (resolve at implementation)

1. ~~**Default theme authoring**~~ — **CLOSED 2026-07-31, NO** (`[CSA-2]`,
   `[CSA-31]`(d)). It asked whether to ship the default `UiThemeDef` as `.tres`
   serialized to JSON at build, "matching the Tier-2 default-content path", and
   recommended yes. **The default-content path it mirrored no longer exists** —
   there is no default pack, so there is nothing to ship and no `.tres` route.
   Every pack's theme is pure JSON. The engine's own `UiThemeDef` fallback
   (chain level 5) is engine primitives, not a shipped authored theme.
2. ~~**Icon atlas source**~~ — **CLOSED 2026-07-31, text-only** (`[CSA-28]`(c),
   `[CSA-31]`(d)). It asked whether to ship a CC0/OGA-BY starter atlas for "the
   default campaign". **The program ships no campaign and no art**; a starter
   atlas inside the executable is exactly the licence surface `[CSA-31]`(d)
   emptied. A missing icon falls back to a **text-only row + generic token**
   until an author supplies icons, and authors get icons by **forking a public
   pack** (`[CSA-31]`(f)) rather than from us.
3. **Per-node theme granularity** — is progression-node `theme` a whole-`UiThemeDef`
   swap or a sparse token overlay on the campaign default? (Recommend: sparse overlay, so a
   node re-tints without redefining every token.)
4. **Which panel first consumes icons** — convoy/shop rows (review Q5 recommendation), since
   they benefit most while still allowing text-only fallback.
