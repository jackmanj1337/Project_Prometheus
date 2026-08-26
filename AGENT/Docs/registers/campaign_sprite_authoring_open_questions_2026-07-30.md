---
Role: dated
Type: register
Status: RESOLVED 2026-07-31 - CSA-1..36; CSA-37 spun out to BACKLOG-SETTINGS-EXPORT-SCOPE-2026-07-30
Last verified: 2026-08-26
Register: CSA-1..37
---

# Campaign Sprite Authoring — Open Questions

**Started:** 2026-07-30
**Register:** `[CSA-1..37]`
**Question:** what has to be true for a **campaign author** — not a
`Project_Prometheus` developer — to bring art into their own pack, define how it
is cut up, record its licence and source, say where it is used, and recolour it?

*(Opened as a unit-sprite question; broadened to the full asset-manager scope by
owner direction — see `[CSA-17]`.)*

**Source of the gap:** `[IMP-1..6]`
([`../decisions/decision_record_2026-07-20_sprite_importer.md`](../decisions/decision_record_2026-07-20_sprite_importer.md))
decided an **editor-time, `res://`, `.tres`-emitting** importer. The campaign
asset model
([`../design/campaign_asset_taxonomy_and_format_2026-07-01.md`](../design/campaign_asset_taxonomy_and_format_2026-07-01.md),
`[ICO-5/6]`) requires a **runtime, `user://`, raw-loaded** path. Both are
ratified. They do not describe the same tool. This register resolves the
difference; it does not re-open `[IMP-1..6]`.

Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

## Status at 2026-07-31 session close (second walk)

**The decision register is COMPLETE.** `[CSA-1..36]` are answered, including
every sub-question. `[CSA-29]` was reframed rather than answered — its premise
was wrong and `[CSA-31]` absorbed the real question.

**The one item not decided here:** `[CSA-37]` (settings in exports/imports),
deliberately spun out to `BACKLOG-SETTINGS-EXPORT-SCOPE-2026-07-30`.

**Closed in the second walk (2026-07-31):**

| Item | Decision |
|---|---|
| `[CSA-7]` pivot | Optional per frame, default **bottom-centre**; lives in the sidecar frame table |
| `[CSA-14]` live view | **Both** — in-game compendium animates as well as exported HTML |
| `[CSA-22]` done swap | **Keyed** lookup, one swap per (faction, state); editor derives state variants |
| `[CSA-27]` theme removed | Fall back to pack default, **say so once** per (pack, theme-id) |
| `[CSA-28]`(c) | Absence falls back to **engine primitives**, never a shipped art set — stated explicitly |
| `[CSA-28]`(d) | Taxonomy row **superseded outright** (not narrowed to shell) |
| `[CSA-28]`(f) | Skin follows `active_package_identity`; quit-to-shell deactivates |
| `[CSA-28]`(g) | Skin resolution rides the **atomic content-session activation** already built |
| `[CSA-28]`(h) | Unregistered slot → **warn and ignore**; never fails the pack |
| `[CSA-31]`(a) | Generate **on creation, silently** |
| `[CSA-31]`(a2) | Extractor **reports frequency** per colour (derived, recomputed on scan) |
| `[CSA-31]`(b) | **Explicit `generated` flag** on `art_asset@1`, not inferred from a missing source |
| `[CSA-31]`(c) | Fill + **optional** baked label; **generate plain, bake later**; generated art only |
| `[CSA-31]`(e) | **Closed by (a1)** — the extractor is the palette step; imports do not degrade to tint |
| `[CSA-31]`(f) | **No hints.** Schemas are blank; first-time authors **fork a public pack** |
| `[CSA-33]`(a) | Empty library offers **import only**; the editor is reached separately |
| `[CSA-33]`(b) | **Files beside the binary**, offered for import; never silent auto-install |
| `[CSA-33]`(c) | Seed-copy clause **superseded** |

**Two answers overrode the recommendation, and they cohere** — `[CSA-33]`(a)
(import only) and `[CSA-31]`(f) (no hints, fork instead). Together they say the
onboarding answer to an empty install is **someone else's pack**, not a blank
template. `[CSA-30]`'s "nobody starts from scratch" is now the shipped
experience, not just an expectation. **Constraint that falls out:** "public
packs" means `Campaign_Pack_0` — `Campaign_Pack_FE` is internal-only under
`[LEG-4]` and must never be offered in-product as a fork target.

**One inference to confirm rather than a direct answer:** `[CSA-31]`(e) is
closed by (a1)'s extractor. If imported art was meant to degrade to tint-only
despite the extractor, that line is the one to correct.

**✅ THE THREE OWED TAXONOMY EDITS ARE APPLIED (2026-07-31,
`FIX-CSA-TAXONOMY-EDITS-2026-07-31`).** In
`campaign_asset_taxonomy_and_format_2026-07-01.md`: the default icon atlas clause
(`[CSA-28]`(d)), the `res://`→`user://` seed-copy clause (`[CSA-33]`(c)), and the
subject-less "`.tres` is an authoring convenience" clause (`[CSA-2]`). The same
pass also applied `[CSA-7]` (arbitrary two-point rects + optional bottom-centre
pivot supersede the uniform-grid preference) and repointed the stale
`B6-SPRITE-IMPORTER`/`[IMP-1..6]` references at this register.

**The defect had a second home.** `ui_theme_and_asset_resolution_2026-07-03.md`
carried the same shipped-default assumption in four places, one of them inside a
chain it declares *locked*: its resolution order had **"shipped default theme,
copied into `user://` on first run"** as step 4. That step is deleted and the
`[CSA-27]` per-pack player override added above the pack default; its
`icon_atlas_default` token, its `.tres`-shipped-default clause, and its open
questions 1 and 2 are all resolved to match. **Lesson: a superseded clause
propagates — grep the whole `design/` tree for a ratified phrase before
declaring a taxonomy edit done.**

**Process gate:** `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31` blocks the UI-facing
work. The engine-side slices are **not** gated and can start: sidecar schema +
validator, runtime slicer, `AssetResolver` semantic groups + fallbacks,
`art_asset@1` with source/licence, `Unit`→`AnimatedSprite2D`.

**`[CSA-22]` needs its own slice** — it made the tint work non-additive
(`_base_modulate` and `set_done_appearance()` become fallback paths behind a swap
lookup). Do not slip it into another slice.

## 2026-08-26 addendum — authored sprite composition

**Status: RESOLVED by owner direction.** `TEAM-HALO-OPTION-2026-08-25`
generalises the team-halo question into one authored composition contract. The
engine must not grow separate shadow, badge, halo, or reclass-part renderers.

- A composition is an **ordered array of authored layers**. Array order is draw
  order. Every layer authors its own anchor, offset, transform, visibility
  predicates, asset/frame binding, and optional palette binding. The engine
  does not reserve positions such as `shadow`, `body`, `head`, `badge`, or
  `halo`, and does not reorder layers by type. Those words may be editor labels
  and preset names only.
- Anchors are author-defined points in the composed sprite's coordinate space.
  A layer may anchor to the composition origin or to another authored anchor;
  validation rejects missing anchors and cycles. There is no fixed
  bottom-centre requirement beyond the existing default offered for ordinary
  frames by `[CSA-7]`.
- A faction visual is a **complete palette-swap asset**, not one faction colour.
  It may provide every exact source-RGBA to target-RGBA entry the art needs.
  Layers opt into a palette (and may select an authored entry/role for a halo or
  other single-colour treatment); layers that do not opt in retain source
  colours. The existing bounded-entry, exact-mapping, tint-fallback, and
  non-colour-channel rules from `[CSA-18..21]` still apply.
- Composition inheritance is author convenience, not engine policy: a class or
  art asset may reference a base composition and replace, insert, remove, or
  reorder layers by stable layer id. The fully resolved ordered array is the
  runtime input. Per-class overrides therefore stay easy without creating a
  second renderer.
- Author and player visibility controls remain separate. Halo use is an author
  choice. A tier badge may be hidden by either author or player; collision
  warnings are advisory. FE-style faction-erasing done palettes remain valid
  only for phase-scoped refresh that restores faction presentation at phase
  end. Movement arrows and range squares stay in the overlay/theme system.
- The engine ships **no composition presets**. Recommended presets — for
  example shadow/body/external-badge/halo arrangements and palette examples —
  are ordinary authored data in the sample campaign packs. Authors can inspect,
  fork, and alter them, and the public and internal sample packs can demonstrate
  different valid orders without either becoming an implicit default.

**Implementation slices:** (1) versioned composition + faction-palette schema,
resolution, cycle validation, and pure tests; (2) runtime resolver/render stack
over `AnimatedSprite2D`, with exact author order and anchors; (3) campaign-editor
layer/palette authoring and advisory diagnostics; (4) sample-pack presets and
playtest adoption. The schema foundation cannot close as `completed` until a
tracked sample-pack successor authors and plays a preset.

---

> ## Owner direction — 2026-07-30
>
> Authors need **a tool or tools** that let them:
> 1. import art,
> 2. **define where the animation cells are**,
> 3. **define licence and source**, and
> 4. define **when, where, and how** those assets are used in a campaign.
>
> Use the **standardized documentation** conventions, and plan for art and its
> information to be **content the semantic reference engine can reach** — both the
> generated Markdown reference docs and the in-game More Info page (e.g. show a
> class's sprite animations on its More Info page when changing classes, and on
> the character sheet).
>
> **This settles `[CSA-1]`, `[CSA-4]`, and `[CSA-6]`** (below) and adds
> `[CSA-11..16]`, which are about the authoring surface and the reference-model
> seam rather than the loader.
>
> **Follow-up overrides (same session, more expected):**
> - `[CSA-11]` — the tool lives in **our campaign editor**, not the general Godot
>   editor. `IMP-EDITOR-PLUGIN-2026-07-20` is superseded, not gated.
> - `[CSA-5]` — **corrected**: two packs sharing a content id is fine. One pack is
>   active at a time and packs are self-contained (`[ICO-1..6]`). No cross-pack id
>   checks.
> - `[CSA-10]` — **no animation is required**, overriding the "idle required"
>   recommendation — but **static art IS expected to exist**, because packs are
>   forked and templates generate art (`[CSA-30]`, `[CSA-31]`). An earlier draft
>   overstated this as "zero required art, everywhere"; that was wrong.
> - `[CSA-17]` — scope is an **asset manager**, not a sprite importer: portraits,
>   UI, map tiles, backgrounds, dialogue art, future combat-scene animation.
> - `[CSA-18]` — pixel-art **palette swaps**, not generic `modulate` tint. A swap
>   is a **property**; swaps are a **from→to list**; a sprite lists which swaps it
>   supports; **each swap carries a tinting fallback**.
> - `[CSA-28]` — **no default art goes through the asset manager.** Main menu,
>   campaign library and editor have built-in graphics; everything else is
>   author-provided, ideally including a per-campaign settings screen.
>
> **The register is expected to keep growing; do not treat it as closed.**
>
> **It also raises the ceiling on the work.** Points 3 and 4 mean art is not a
> file the loader happens to find — it is *catalogued, provenanced, and
> referenced* content, i.e. a first-class entity in both the pack schema and the
> reference model. Neither system has an art kind today.

---

> **⚠️ ASSET-LICENSING GATE — unchanged and still in force.** `[LEG-4]`
> governs what art may be committed (CC0 / OGA-BY only; paid "no-redistribute"
> packs are build-only placeholder; FE-derivative art is internal-only). Nothing
> in this register lifts it, and **an importer is never a licence-laundering
> step.** `[CSA-6]` is about *recording* rights, not granting them.

---

## 1. State today — code-grounded

Verified against the working tree on 2026-07-30, not from documents:

| Claim | Evidence |
|---|---|
| **No importer exists.** No `addons/`, no importer script. | `IMP-IMPORTER-CORE-2026-07-20` is still `planned`; nothing in the tree. |
| **`AssetResolver` IS built** — pack-scoped, id→`Resource`, registerable loaders + fallback chains, path-escape guard, structured repair report. | `scripts/assets/AssetResolver.gd` (167 lines), `scripts/tests/test_asset_resolver.gd` |
| **It loads whole textures only.** `_load_texture` → one `ImageTexture` per file. | `AssetResolver.gd:139-146` |
| **No slicer, no sidecar reader, no `SpriteFrames` anywhere.** Tier-1a is unbuilt. | No `AtlasTexture` / `SpriteFrames` / sidecar reference in `scripts/` |
| **Pack install/export are built.** | `CampaignPackInstaller.gd` (243), `CampaignPackExporter.gd` (173), `CampaignPackRegistry.gd` |
| **The installer registers groups by file *extension*, and scans `assets/`.** | `CampaignPackInstaller.gd:133-149` — `{"png","ttf","otf","ogg","wav"}`; the taxonomy specifies semantic groups under `art/`. |
| **No group registers a fallback chain.** The taxonomy's "missing asset never crashes a pack" chain is specified, not implemented. | `_validate_optional_media` passes `register_group(ext, loader)` with no fallbacks |
| **`ClassData.sprite_id` exists, is authored `""` everywhere, and is read by nothing.** | `scripts/resources/ClassData.gd:65`; 14 `data/classes/*.tres`; only other hit is the schema registry |
| **`sprite_id` is an admitted class-schema field.** | `../design/class_schema_trial_v1_2026-07-29.md:132` |
| **There is no art-asset schema kind.** | `test_fixtures/schema_trial/trial_v1/schema_registry.json` → `schemas` = source_registry, occurrence_audit, class, advancement_edge, advancement_route, skill, map, campaign, item, progression_pressure_profile |
| **`SPRITE_SOURCE_SIZE` is a documented seam that does not exist in code.** | Named in `[LEG-4.4]` and `ui_ux_asset_inventory_and_reuse_2026-07-02.md`; zero hits in `scripts/` |
| **`GameConstants.TILE_SIZE = 64`**, while `[LEG-4.4]` scopes the first release to 32px source art. | `scripts/shared/GameConstants.gd:10` |

**Two ratified contracts disagree.** `[IMP-1..6]` and its register make **no
reference** to the taxonomy, `AssetResolver`, sidecars, or `user://` — verified
by grep, not inferred. The decision was taken as though the game repo were the
only consumer.

| | `[IMP-1..6]` (2026-07-20) | Taxonomy `[ICO-5/6]` (2026-07-01/02) |
|---|---|---|
| Runs | Editor button, authoring time | Runtime, on pack load |
| Reads | `res://assets/` | `user://campaigns/<pack>/art/` |
| Emits | `SpriteFrames.tres` under `data/` | PNG + JSON sidecar; `SpriteFrames` built in memory |
| Canonical format | `.tres` | JSON (`.tres` is authoring convenience only) |
| Author can skip the tool? | No — it *is* the pipeline | **Yes** — "an author with a clean sheet + sidecar can skip it" |

**This blocks more than sprites.** The `UiThemeDef` / `AssetResolver` visual half
of the UI/UX pass is explicitly gated on `B6-SPRITE-IMPORTER` / `[IMP]`
(`campaign_library_ux_decisions_2026-07-24.md:557`).

---

## 2. Open questions

### [CSA-1] Which tool is the campaign author's? **[RESOLVED 2026-07-30]**
**Resolution — owner direction: authors get a real authoring tool, and the
runtime slicer is its foundation, not its replacement.** Option A stands as the
*engine* answer (the runtime slicer is what makes art work in an exported
build, and a hand-authored sheet + sidecar must keep working), but A alone was
too narrow: an author also needs to *define* cells, licence, and usage, which is
a UI problem, not a loader problem. The tool is specified in `[CSA-11]`; the
slicer remains slice 1 because the tool's output has to be loadable before the
tool is worth building.

Options as originally posed:
- **A — The runtime slicer is the product; the importer is optional convenience.**
  Ship the sidecar reader + `SpriteFrames` builder first; a hand-authored
  `knight.png` + `knight.json` works with no tool at all.
- **B — The editor importer is the product**, extended to write into `user://` packs.
- **C — Both, slicer first.**
- **Rec: A.** It is what the taxonomy already promises, it is the only half that
  works in an exported build, and it is headless-testable. An editor button
  cannot help an author who does not have the Godot editor — which is every
  campaign author.

### [CSA-2] Does `[IMP-3]` (generated `.tres` under `data/`) survive? **[RESOLVED 2026-07-31 — A]**
**Owner: no. All campaign packs are basic file types with JSON sidecars — never
Godot `.tres`.** Stronger than the recommendation below, which would have kept
`.tres` for a built-in default campaign; `[CSA-33]`(d) removed that campaign
anyway, so one rule now covers everything.
- **Consequence:** `[IMP-3]` is fully retired. `SpriteFrames` is built in memory
  and never serialised, and a pack is readable and diffable without Godot — which
  is what the taxonomy wanted JSON-canonical for in the first place.
- **Consequence:** the taxonomy's "`.tres` is an authoring-time convenience for
  the default palette" clause now has no subject. Fold it into the same edit as
  `[CSA-28]`(d) and `[CSA-33]`(c) when the taxonomy is revised.

Options as originally posed:
- **A — Retire it for pack content.** Pack sprite data is PNG + JSON sidecar;
  `SpriteFrames` is built in memory, never serialised.
- **B — Keep `.tres` for the built-in default campaign, JSON for user packs.**
- **C — Keep `.tres` everywhere** (contradicts the taxonomy).
- **Rec: B.** Mirrors the already-ratified Tier-2 rule exactly — defaults MAY be
  authored as `.tres` in-editor then serialised at build; user packs are pure
  JSON. One rule for both tiers is easier to hold than two.

### [CSA-3] What is the sidecar schema? **[RESOLVED 2026-07-31]**
The taxonomy fixes the shape (uniform grid `cell` + `columns`/`rows`, or an
explicit frame table; plus `frames`/`fps`/`loop`) but no field list exists.
- Needs: exact key names, required vs defaulted, `schema_version`, and whether
  the animation-name vocabulary (`idle_down`, `walk_left`, …) is **fixed** or an
  open registry.
- **Rec:** open registry for animation names, keyed by a **state × facing**
  convention, with the engine requiring only `idle_<facing>`. A closed set of
  animation names is precisely the closed-enum smell `AGENTS.md` forbids — and
  a pack with a 6-frame attack animation should not need an engine edit.
- **RESOLVED 2026-07-31 — open registry, minimum cut to a single `idle`**
  (owner). The engine requires **one** animation named `idle` — not one per
  facing. **State × facing is a recommended convention for authors**, documented
  and encouraged, never enforced.
  - *Why the cut matters:* requiring `idle_<facing>` would have forced four
    entries on a pack that only wants one square. A single `idle` means the
    cheapest valid sprite is one still image, which is what `[CSA-10]` and
    `[CSA-31]` already imply everywhere else.
  - **Editor must offer generic manipulation: rotate and mirror** (owner). This
    is a bigger lever than it sounds — **mirror halves the authoring work for
    left/right facings**, and rotate covers tile and directional-marker cases,
    so a one-facing sheet can populate a four-facing convention without new art.
  - **Open:** are rotate/mirror **destructive** (write new pixels into the asset)
    or **declarative** (a flag on the frame/binding, applied at draw)? *Rec:
    declarative*, because it keeps one source image, survives a palette swap
    unchanged, and costs nothing at rest — with a destructive "bake" available
    via `[CSA-25]` for authors who want the pixels.
  - **RESOLVED 2026-07-31 — declarative until baked** (owner). Rotate and mirror
    are flags applied at draw; baking (`[CSA-25]`) is what makes them pixels.
    *Consequence:* a mirrored frame and its source share one image, so a palette
    swap, a re-import, or a source-art fix applies to both automatically — which
    is the whole reason mirror is cheap enough to lean on for facings.

### [CSA-4] Does an art asset get a Tier-2 catalogue document? **[RESOLVED 2026-07-30 — A]**
This is the load-bearing one. `class_schema_trial_v1` says every "class, skill,
item, **art asset**, route, edge" must resolve to a file **catalogued inside that
same pack** — but there is no art kind in the schema registry, so an art asset
**cannot currently be catalogued, cannot carry `source_refs`, and therefore
cannot carry provenance at all.**
- **A — Add an `art_asset@1` kind** carrying the common envelope (`id`,
  `display_name`, `source_refs`, …) plus `path`, `group`, and the sidecar ref.
- **B — Leave art Tier-1-only**, path-resolved, no provenance.
- **C — Provenance on the sidecar** rather than a catalogue document.
- **Rec: A.** B silently exempts the *only* asset class with a real third-party
  licensing problem from the provenance system built for text content. C splits
  the provenance model in two.
- **Resolution: [RESOLVED 2026-07-30 — A].** Owner direction: authors define
  licence and source, using the standardized documentation conventions, and the
  result must be reachable by the semantic reference engine. All three of those
  require art to be a catalogued document with the common envelope; a
  path-resolved Tier-1 file can carry none of them. Add `art_asset@1`.
  **Consequence:** art joins the globally unique catalogue id space, which
  auto-resolves `[CSA-5]` — see there.

### [CSA-5] Identity — is a sprite id a catalogue id? **[RESOLVED 2026-07-30 — see the correction]**
If `[CSA-4]`=A, art ids join the **globally unique** id space and inherit
`identity_collision` as a hard error. Confirm that is intended, and confirm
`ClassData.sprite_id` resolves against that id space rather than a bare filename.
- **Rec:** yes to both. `sprite_id` becomes a catalogue reference like any other,
  which also makes it validatable — today it is an unvalidated free string.
- **Resolution: [RESOLVED 2026-07-30 — yes, follows from `[CSA-4]`=A].** A
  catalogued art asset has a catalogue id by construction.
- **Correction (owner, 2026-07-30).** An earlier draft of this entry claimed two
  packs both shipping `knight_sprite` would be an `identity_collision` hard
  error. **That was wrong.** `[ICO-1..6]` settled that one pack is active at a
  time and a pack is completely self-contained, so two packs are never loaded
  together and cannot collide. Verified in code: `CampaignPackInstaller` rejects
  only a re-install of the same id *and* version and never cross-checks ids
  against other installed packs; the runtime carries a single
  `active_package_identity`. Id uniqueness is a rule **within** one pack's
  export set. **Do not design cross-pack id checks or precedence rules for art.**
- **Doc defect to fix on the owning track:** `class_schema_trial_v1`'s "globally
  unique … across all packs considered together during installation or load"
  reads as though the installed library is checked as a set. It means the one
  loaded set. This sentence is what misled the draft above; worth a clarifying
  edit by whoever owns `CLASS-SCHEMA-TRIAL-V1-2026-07-29`.

### [CSA-6] Rights recording for imported art **[RESOLVED 2026-07-30 — required]**
`source_registry` already requires `locator`, `title`, `attribution`,
`rights_status`, `verified_at`. Does importing art **require** a source record?
- **Rec: yes, required for `complete` packs, warned for `draft`.** It reuses the
  existing `field_completeness` `unverified` mechanism rather than inventing a
  second one, and it makes CC-BY attribution (mandatory for Puny Dungeon and
  octoshrimpy's MiniWorld+, per `Campaign_Pack_0/CREDITS.md`) a validation
  result instead of a promise.
- **Resolution: [RESOLVED 2026-07-30 — yes, required].** Owner direction names
  "define licence and source" as a first-class thing the tool does. Required for
  `complete` packs, `unverified`-warned for `draft`. **See `[CSA-13]` — recording
  the licence is not the same as honouring it, and the reference model's
  provenance profiles can currently strip attribution from the exact surface
  where CC-BY requires it.**

### [CSA-7] Frame size, `SPRITE_SOURCE_SIZE`, and the 32/64 split **[RESOLVED 2026-07-31 — fully, incl. frame pivot]**
`TILE_SIZE = 64`; `[LEG-4.4]` scopes release 1 to 32px source art at 2×. So
`frame_size` defaulting to `TILE_SIZE` (per `[IMP-1]`) is **wrong for most real
sheets**, and per-pack art may not match the project tier at all.
- **Rec:** the sidecar's `cell` is authoritative per sheet; `SPRITE_SOURCE_SIZE`
  becomes a real constant for the *default* pack only; the renderer scales
  `cell` → `TILE_SIZE` at integer ratios and warns on a non-integer ratio.
- **RESOLVED 2026-07-31 — the sheet's sidecar is authoritative, and slicing is
  arbitrary** (owner). Any arbitrary section of the image may be used, defined as
  **two-point rectangles on the picture's pixel grid**. Warnings on odd ratios
  are wise and **disableable**.
  - **This supersedes the taxonomy's uniform-grid preference for authored
    sheets** (it reserved the explicit frame-table form for the shipped default
    set). With no shipped default set (`[CSA-33]`(d)), the frame table is simply
    *the* form, and a uniform grid becomes a convenience the editor can generate
    rather than a constraint the format imposes.
  - *Why arbitrary rects are the right call:* real third-party sheets are not
    uniform — they pack characters at varying sizes with irregular padding.
    Requiring a uniform grid would have forced authors to re-cut source art
    before importing it, which is exactly the friction the manager exists to
    remove. Two-point rects also make the colour sampler and the frame editor the
    same kind of pixel-grid interaction.
  - **Frame pivot — RESOLVED 2026-07-31: yes, optional per frame, defaulting to
    bottom-centre** (owner). Irregular rects make this necessary sooner than a
    uniform grid would — a 24×32 frame and a 32×32 frame in one animation need a
    shared anchor or the sprite jitters between frames.
    - Bottom-centre is the conventional anchor for a unit standing on a tile, so
      the default is correct for the common case and the uniform-grid path never
      has to state it.
    - *Optional, not required:* the author touches a pivot only when a frame
      actually misaligns. Requiring one per frame would make the uniform-grid
      case tediously explicit for no gain.
    - *Implementation note:* the pivot is part of the **sidecar frame table**
      (`[CSA-3]`), alongside the two-point rect — same record, so a frame is
      always fully described in one place.

### [CSA-8] Does `Unit` still switch to `AnimatedSprite2D`? **[RESOLVED 2026-07-31 — as recommended]**
Owner accepted the recommendation. Note the *rationale* below is stale where it
says most packs ship no unit art — under `[CSA-31]` templates generate art, so
art normally exists. The placeholder path stays first-class for a different
reason: **resolution can still fail** on a corrupted or hand-edited pack, and
that path must never crash.

`[IMP-2]` says yes. Still the right call under a runtime slicer, but the
`SpriteFrames` now arrives from `AssetResolver` rather than a preloaded `.tres`.
- Unresolved: what a unit shows **before/while** art resolves, and what happens
  when a pack ships no sprite at all (the taxonomy's answer is "generated
  placeholder tile + validation warning" — confirm that applies to units).
- **Rec:** keep the switch; make the placeholder path the *normal* path, since
  most packs will ship no unit art.

### [CSA-9] Pack layout — `art/` vs the implemented `assets/` **[RESOLVED 2026-07-31 — as recommended]**
Owner accepted: move the installer to the taxonomy's semantic groups and register
the fallback chains in the same change.

The taxonomy specifies `art/{icons,portraits,sprites,tilesets,ui}`;
`CampaignPackInstaller` validates whatever is under `assets/`, grouped by file
extension.
- **Rec:** move the installer to the taxonomy's semantic groups, and register the
  fallback chains at the same time — extension-keyed groups cannot express a
  fallback ("missing portrait → silhouette") because the extension does not say
  what the asset *is*. Low cost now, and it is a format break later.

### [CSA-10] Animation scope — what set does v1 require? **[RESOLVED 2026-07-30/31]**
`ui_ux_asset_inventory_and_reuse_2026-07-02.md` flags "are unit map sprites
static or idle/move-animated?" as **owned by the importer register** — and
`[IMP-1..6]` resolved the plumbing without ever answering it.
- **Rec:** v1 requires **idle only**; walk is optional and falls back to idle.
  It is the difference between a pack author needing 4 frames and 20, and the
  fallback is free once `[CSA-3]`'s registry exists.
- **Resolution: [RESOLVED 2026-07-30 — no ANIMATION required; static art IS
  expected]** (owner override, then clarified). Precise statement:
  **the engine may expect static art to exist; animation frames are optional.**
  Static art is expected not because authors must source it, but because packs
  are **forked from an existing pack** and templates **generate** flat-colour art
  (`[CSA-30]`, `[CSA-31]`) — so a pack that lacks art is the abnormal case, not
  the normal one.
- **An earlier draft of this register overstated this** as "zero required art,
  everywhere", and built `[CSA-29]` on that reading. Corrected below.

- **Missing animation cells — the question largely dissolves.** Owner framing:
  either synthesise frames from the static image, or skip the animation and wait
  the time it would have taken; **both must read as a boardgame piece sliding
  across the board**, not a unit walking and not a teleport. Measured: that is
  **already how movement works**. `Unit.gd:556-580` tweens `position` with one
  chained segment per tile at `seconds_per_tile` (plus an "instant" speed that
  snaps), while the sprite is a static `Sprite2D` that never changes frame.
  - So the two mechanisms are **independent**: the tween owns *duration and
    motion*; `SpriteFrames` owns *whether pixels change*. Neither of the owner's
    two options needs a special case — a single-frame animation slides for
    exactly as long as a twenty-frame one.
  - The only real sub-question is the internal API: when art has no `walk_*`,
    does the engine **synthesise a one-frame `walk_*`** so consumers can always
    ask for it, or do consumers **fall back** to `idle_*`/the static frame?
    *Rec: synthesise one frame* — consumers stay uniform, and "copy the static
    image over and over" needs exactly one copy, not N, because the tween already
    supplies the time.
- **Consequence — this is stronger than it sounds.** "Required art" drops to
  zero across the board, so the **placeholder + validation-warning path is the
  primary path, not the error path**, and every consumer must be written that
  way from the start rather than retrofitted. It also settles the open
  "which surfaces are required art vs placeholder-OK?" question in
  `ui_ux_asset_inventory_and_reuse_2026-07-02.md` in favour of "almost none" —
  which is what that note itself recommended.
- It also removes the last reason to block on art sourcing: the loader, the
  `Unit` switch, and the catalogue can all ship and be tested with no art.

---

## 3. The authoring tool and the reference-model seam (`[CSA-11..16]`)

### State today — the reference model, code-grounded

`B3-REFERENCE-MODEL` is **approved architecture, implementation not started**
([`../plans/generated_reference_model_implementation_plan_2026-07-30.md`](../plans/generated_reference_model_implementation_plan_2026-07-30.md),
on `agent/integration` as of `4c3d7abd`). What it already fixes, and what it
leaves open for art:

| Already decided | Consequence for art |
|---|---|
| Entries have namespaced ids `pack:kind:local_id`; **ids own links**, not titles or filenames | An art asset needs a `kind` to have an id at all |
| Handlers emit **facts, not sentences**; unknown fact kinds **fail** in strict exports | "Show the class's sprite animation" needs a *registered fact kind*; there is none |
| The first fact vocabulary covers identity, stats, class data, weapons, skills, proficiency, terrain, requirements, formulas, relations | **No visual/art/animation fact anywhere in it** |
| Provenance is first-class at document/entry/fact/relation/note level, with export profiles `none` / `summary` / `full` | Licence data has an obvious home — and a sharp edge, see `[CSA-13]` |
| Author notes use one restricted Markdown vocabulary allowing "**approved image asset references**" | What makes a reference *approved* is undefined — that is `[CSA-14]` |
| More Info becomes two regions: generated rules/values, and author notes | A sprite animation is neither a rule nor prose — see `[CSA-15]` |
| A second implementation of pack loading/defaults/resolution outside the engine is **prohibited** | The renderer cannot slice sheets itself; the engine must export what it needs |
| Migration step 2 is **classes** — movement, traits, bases/caps, weapon access, advancement | This is exactly the surface the owner wants sprites on |

### [CSA-11] What is the authoring tool, and where does it live? **[RESOLVED 2026-07-30 — A]**
**Resolution — owner: the tool lives inside our campaign editor, not the general
Godot editor.** The pure `RefCounted` core underneath stays headless-testable
(`[IMP-4]`), which yields option C's CLI path as a by-product. `[IMP-EDITOR-PLUGIN-2026-07-20]`
— a Godot `EditorPlugin` toolbar button — is therefore **superseded and should be
retired**, not merely gated.

Options as originally posed:
The owner's four capabilities (import, define cells, define licence/source,
define usage) are one workflow but not necessarily one tool.
- **A — One in-campaign-editor "art" workflow**: import → visual cell definition
  → licence/source form → usage binding, all inside the campaign editor that
  `campaign_library_ux_decisions_2026-07-24.md` already scopes as full editor
  integration.
- **B — A Godot `EditorPlugin`** (the `[IMP]` assumption).
- **C — Split**: a headless/CLI importer for bulk work plus an editor UI for
  cell definition and binding.
- **Rec: A, with the pure module underneath usable headlessly (C as a
  by-product).** B is disqualified by the audience — campaign authors do not
  have the Godot editor, and `[ICO-5/6]` means their packs live in `user://`
  where the editor pipeline does not run. Building A on a pure `RefCounted` core
  (`[IMP-4]`, still the right call) gives C for free and keeps CI coverage.
- **Note:** the reference plan says "editor integration remains later; the editor
  consumes this system and does not own it." Sequencing this tool *after* the
  foundation is consistent with that; building it as a parallel art-only editor
  is not.

### [CSA-12] Does an art asset get a reference-model entry, or only a pack-catalogue document? **[RESOLVED 2026-07-31 — A]**
Owner accepted: a full entry with facts and `used_by` relations.

`[CSA-4]` gives art a *pack schema* document. Separately, does the semantic
exporter emit an **entry** (`pack:art_asset:knight_sprite`) with facts?
- **A — Yes, a full entry** with facts (dimensions, animation list, frame counts,
  source, licence) and relations (`used_by` → class/unit/tile).
- **B — No entry; art is only ever a *field* of other entries** (a class entry
  gains a `sprite` fact).
- **Rec: A.** The owner asked for "when, where, and how those assets are used in
  a campaign" to be authored data. That is a *relation*, and relations in this
  model hang off entries. A also gives the reference docs a place to list an
  asset's licence once, rather than repeating it on every class that uses it. B
  cannot express "which classes use this sheet" without inverting the whole
  relation model.

### [CSA-13] Attribution must not ride on a suppressible provenance profile **[RESOLVED 2026-07-31 — A]**
Owner accepted: **a separate, non-suppressible attribution channel**, independent
of the provenance profile. This closes the one item in this register that was a
correctness defect rather than a preference.

The reference model's `none` profile is "player-facing content **without
provenance blocks**". If licence/attribution is carried as provenance, then the
player-facing rendering path is precisely the one that strips it — and for the
CC-BY sources already in `Campaign_Pack_0` (Puny Dungeon, octoshrimpy's
miniworld +), attribution is a **licence condition**, not a nicety.
- **A — Attribution is a separate, non-suppressible channel**, independent of the
  provenance profile, surfaced in an always-reachable credits view.
- **B — `none` is redefined** to still carry required attribution.
- **C — Accept it**: attribution lives only in `CREDITS.md`.
- **Rec: A.** It mirrors the precedent already in `class_schema_trial_v1`, where
  `presentation_name_collision` is "severe, non-suppressing" and "never changes
  resolution". C is how a public release ships a licence violation.
- **This is the sharpest finding of the walk** — it is a defect in the seam
  between two systems that are each individually correct.

### [CSA-14] What is an "approved image asset reference" in restricted Markdown? **[RESOLVED 2026-07-31 — fully; live view in-game too]**
The reference plan permits "approved image asset references" in author notes but
does not define approval, and lists "asset-boundary tests" as a required test.
- Needs: may a note reference **only** catalogued in-pack art ids (never a path,
  never a remote URL)? Does an animated asset in a note render as a still frame?
- **Rec:** catalogued in-pack ids only, resolved through `AssetResolver`, with a
  still frame in static renderings. It makes the asset boundary a *resolution*
  property rather than a string-validation problem, and `[CSA-4]`'s catalogue is
  what makes "is this id in this pack" answerable at all.
- **RESOLVED 2026-07-31 — as recommended, plus one live-rendering requirement**
  (owner). Ids only, still frames in static renderings — **but at least one
  reference/compendium export option must show the animations live.**
  - *Consequence:* the sidecar renderer needs one output format that can animate.
    The reference plan already anticipates "a later static HTML reference and
    search index"; **HTML is the natural home** (CSS sprite animation over the
    original sheet, or a generated APNG), while GFM and PDF keep still frames.
  - *Consequence:* that HTML output must stay self-contained and offline-safe —
    animating from the pack's own sheet, never a remote embed, which is the same
    boundary `[CSA-14]` draws for author notes.
  - **RESOLVED 2026-07-31 — both** (owner). The live view animates in the
    **in-game compendium** as well as the exported HTML.
    - In-game already holds the real `SpriteFrames`, so animating there is
      strictly cheaper than in a renderer — the export is the hard case, and it
      is already required.
    - *Why it matters beyond cost:* it keeps More Info and the exported reference
      showing **the same thing**. An offline document richer than the running
      game is a gap authors would have to explain to players.

### [CSA-15] How does More Info render an animation? **[RESOLVED 2026-07-31]**
More Info is being migrated into a facts region and a notes region. A playing
sprite animation is neither.
- **A — A third presentation region** ("visual"), fed by art facts.
- **B — Part of the facts region**, as a fact whose renderer happens to be a
  texture.
- **Rec: B for the data, A for the layout** — the animation *is* a fact
  (`art_asset` + `used_by` relation) and must not be author prose, but it needs
  its own region so the rules region stays text and stays screen-readable. The
  plan's "preserve plain-text and screen-reader output" requirement means the
  visual region needs a text equivalent, which the `art_asset` entry's title and
  animation list can supply.
- Also unresolved: static renderings (GFM/PDF/HTML) cannot animate. Sprite sheet
  + frame table, first frame, or an animated GIF/APNG produced by the sidecar
  renderer?
- **RESOLVED 2026-07-31 — as recommended; defined in data is right** (owner),
  with one addition: **art display of this kind should only be available at
  certain resolution/scale combinations, or as a UI format setting.**
  - *Why this matters:* the visual region competes for space with the rules
    region, and at small window sizes or high menu scale it would push the facts
    off-screen — which inverts the priority, since the rules are the thing More
    Info exists for.
  - *Rec:* treat it as a **layout capability the surface declares**, evaluated
    against the current resolution × `menu_scale_index`, with an explicit user
    override in settings (show always / auto / never). Auto is the default.
  - *Rec:* the text equivalent (`art_asset` title + animation list) is what shows
    when the visual region is suppressed — so suppression degrades rather than
    hides, and screen-reader output is unchanged either way.

### [CSA-16] What does "when, where, and how used" mean as data? **[RESOLVED 2026-07-31 — as recommended]**
Owner accepted all three: entity-names-asset where a content entity owns the art
plus a **named-slot registry** for surfaces (never the inverted form); scope lands
whole-campaign and per-node, deferring per-runtime-state; presentation parameters
live on the **binding**, with per-kind schemas supplied by the registering surface.


The fourth owner capability is the least specified, and the no-default-art
direction (`[CSA-28]`) makes it the **central** question rather than a
nice-to-have: if every surface outside the shell is author-skinned, then "where
is this asset used" is the mechanism the whole skin runs on.

It is really three questions wearing one name.

#### 16a — WHERE: what does the binding hang off?

- **A — The consuming entity names the asset.** `ClassData.sprite_id = "knight"`.
  This is the only mechanism that exists today.
  *For:* already present, trivially validatable, obvious to an author editing a
  class. *Against:* **only works where a content entity exists.** There is no
  "settings screen" entity, no "prep hub background" entity, no "dialogue box
  frame" entity in the content schema — so it cannot express most of what
  `[CSA-28]` now requires.
- **B — The asset declares where it is used** (`used_by: [class:knight]`).
  *For:* one place to see an asset's whole footprint. *Against:* inverts the
  dependency — a general-purpose asset would have to know about every consumer,
  which is the inverted-dependency anti-pattern already found six times in this
  codebase.
- **C — A named-slot registry.** The engine registers skinnable **surface ids**
  (`ui.settings.background`, `ui.dialogue.frame`, `map.cursor`), and a pack ships
  a binding table from slot id → asset id.
  *For:* it is the only option that can skin a screen that has no content
  entity; it is an open registry, so a new skinnable surface is a registration
  rather than a schema change; and the set of slots becomes self-documenting for
  authors ("here is everything you can skin").
  *Against:* a second addressing scheme alongside `sprite_id`; risk of the slot
  list becoming a de-facto closed enum if it is hardcoded rather than registered.
- **Rec: A for content entities, C for surfaces, never B.** Keep `sprite_id`
  where a content entity owns the art — that is the natural place an author
  looks — and add the slot registry for everything else. Resist a big-bang
  migration of `sprite_id` into the slot table; they answer different questions.
  **The slot registry is now on the critical path**, because `[CSA-28]` says
  almost every surface is author-skinned.

#### 16b — WHEN: what is a binding's scope and condition?

Scope, roughly in order of cost:

1. **Whole campaign** — one binding set for the pack. Certainly needed.
2. **Per campaign node / chapter / map** — swap the prep background between
   chapters, or re-skin for an act break. Strongly implied by "how those assets
   are used *in a campaign*".
3. **Per runtime state** — faction, promoted class, day/night, weather, damaged
   variant.
- **Rec: land 1 and 2; defer 3.** 1 and 2 are static author data resolvable at
  load with no predicate engine. 3 needs conditions evaluated against live state,
  which is a requirement-predicate problem (`[REQ]`) and an open-registry problem
  at once — it will re-open `[EXT]`-shaped questions and should not block a
  campaign having a themed settings screen.
- **Note:** the `[CSA-18]` palette swap is a *cheap* form of 3 for the specific
  case of faction colour, which is the one everyone actually asks for. That is a
  reason to defer general conditional binding, not a reason to rush it.

#### 16c — HOW: what presentation parameters ride along?

A binding is rarely just "use this file". The taxonomy's Tier-1a table already
implies the parameter set differs per asset kind:

| Kind | "How" parameters |
|---|---|
| Unit sprite | which animation plays by default; which palette swap applies (`[CSA-18]`) |
| UI panel | **9-slice margins**; stretch vs tile |
| Background | anchoring, aspect handling, parallax or not |
| Tileset | cell size, autotile terrain bits |
| Icon | none — it is a single image at a fixed size |

- **Rec:** presentation parameters live on the **binding**, not on the asset. The
  same background reused in two slots may anchor differently; the same sheet used
  by two classes may default to different animations. Putting them on the asset
  forces a copy of the asset to vary them.
- **Open:** whether the parameter schema is per-kind (validatable, but a closed
  per-kind list) or a free dictionary the consuming surface interprets
  (extensible, but unvalidatable). *Lean:* per-kind schemas supplied **by the
  registering surface**, so it stays open-registry while remaining checkable.

#### What lands first

Slot registry (16a-C) with whole-campaign scope (16b-1) and per-kind presentation
params (16c). That is enough to skin a campaign end to end, and it is all static
data — no predicates, no live evaluation.

### [CSA-17] Scope — the tool is an asset manager, not a sprite importer **[RESOLVED 2026-07-30 — scope set; sub-questions OPEN]**
**Owner direction:** expose options for **portraits, UI elements, map tiles,
backgrounds, dialogue-system art, and future combat-scene animation art** —
not just unit map sprites.

This is a rename as much as a scope change: `B6-SPRITE-IMPORTER` is really
`ASSET-MANAGER`. The taxonomy already anticipates it — its Tier-1a table gives a
per-group sheet/single-file stance for exactly these groups:

| Group | Taxonomy stance | Extra shape the manager must handle |
|---|---|---|
| Unit / map sprites | Sheet | Animation rows per facing (`[CSA-3]`) |
| Terrain tiles | Sheet (tileset atlas) | `TileSetAtlasSource` built at runtime; autotile is a separate open question |
| UI chrome | Sheet | **9-slice margins** — a different sidecar shape from animation frames |
| Icons | **Both** | Author single-file drop-ins must not force an atlas repack |
| Portraits / backgrounds | Single file | No slicing at all; largest files in a pack |
| Fonts | n/a | Rasterizer-generated; already loadable (`HANDLER_FONT`) |
| Audio | n/a | Already loadable (`HANDLER_OGG`/`HANDLER_WAV`); in scope for a *manager*, out of scope for a *slicer* |

**Open sub-questions:**
- **(a)** One asset-kind vocabulary shared by the catalogue (`[CSA-4]`), the
  resolver groups (`[CSA-9]`), and the manager UI — or three lists that drift?
  **Rec: one registry**, since these are the same vocabulary viewed three ways,
  and a closed per-surface list is the enum smell again.
- **(b)** Does the manager own **audio** too, given the owner's list is art-only
  but `AssetResolver` already loads OGG/WAV? **Rec: yes** — "asset manager" that
  cannot see half the pack's assets will be worked around immediately.
- **(c)** Dialogue art and combat-scene art have **no consuming system yet**
  (combat is still frame-atomic; the dialogue register is open). **Rec:** admit
  their *asset kinds* now so packs can carry and licence the art, but do not
  design their sidecar shapes until the consuming systems exist — that is the
  same trap `[IMP-6]` was narrowed to avoid.

### [CSA-18] Palette swaps, not generic tint **[PARTIALLY RESOLVED 2026-07-31 — UI gated on DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31]**
**Owner direction:** pixel art needs real **palette swaps**, not a generic tint.

**Why this is load-bearing, code-grounded:**
- The project contains **zero shaders** — no `.gdshader`, no `ShaderMaterial`
  anywhere in `scripts/` or `scenes/`. A palette swap introduces the first one.
- `modulate` **multiplies** the whole texture. It can darken or wash a sprite; it
  cannot map "red armour → blue armour" while leaving skin and steel alone. That
  is precisely the FE-style faction recolour the owner is asking for.
- **Faction identity currently *is* the modulate colour.** `Unit._apply_faction_visual()`
  sets `_sprite.modulate` and stores it as `_base_modulate` (`Unit.gd:78-93`), and
  `set_done_appearance()` renders "done" as `_base_modulate.darkened(...)`
  (`Unit.gd:605-608`). If palette swap takes over faction identity, `_base_modulate`
  stops meaning "faction" and **done-appearance needs a new mechanism** — it
  cannot darken a colour that is no longer carrying the faction.
- `ui_ux_asset_inventory_and_reuse_2026-07-02.md` uses **"tintable"** as a reuse
  lever on **9 rows**, defined as "author white/greyscale source, recolor at
  runtime via `modulate` (one asset → many colors)". Palette swap changes that
  reuse math; those rows should be re-read, not assumed still valid.

**Options:**
- **A — Indexed palette + LUT shader.** Art authored against a known palette; a
  small palette texture per variant; the shader maps index → colour.
  *For:* one sheet serves unlimited variants; exact pixel-art control; tiny
  variant assets. *Against:* constrains authors to indexed art, which most
  third-party CC0 sheets are **not**; needs a palette-extraction step in the
  manager for arbitrary art.
- **B — Colour-remap shader** with a small explicit from→to table per variant.
  *For:* works on arbitrary art with no re-authoring; the manager can offer an
  eyedropper over the sheet. *Against:* per-pixel match is brittle against
  anti-aliased or dithered art; table size grows with palette size.
- **C — Pre-baked variant sheets**, one per faction/recolour, no shader.
  *For:* zero runtime tech, works everywhere including web, trivially
  previewable, no first-shader risk. *Against:* asset count multiplies; an
  author adding a faction must re-export every sheet.
- **D — Keep `modulate`** for faction and accept it is not a real recolour.
  *For:* already built. *Against:* explicitly rejected by the owner.

**RESOLVED 2026-07-31 (partial, owner):** the **palette extractor is required**
and is what makes the approach work on real art. Matching is **exact** with
transparent special-cased and partial swaps allowed (`[CSA-19]`), which is
effectively option **A's data model reached through B's tooling** — extraction
produces the palette, and the swap is an explicit from→to list against it.

> **PROCESS GATE (owner, 2026-07-31): talk UI before building.** The asset
> manager's interface should be designed before it is implemented — **and that
> applies to the whole campaign editor**, not just this tool. Nothing in
> `[CSA-11]`/`[CSA-17]`/`[CSA-18]` should be built ahead of that discussion.
> Tracked as `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`. The engine-side slices
> (sidecar, slicer, resolver groups, `art_asset@1`, `Unit` switch) are **not**
> gated by it — they have no UI surface.

**Rec: B for the runtime, with C available as an author-side "bake" action** in
the manager. B is the only option that works on the third-party CC0 art the
project actually has, and it degrades gracefully — a pack with no palette data
renders unmodified. C as a bake gives an escape hatch for web/perf and for art
where remapping is unreliable. A stays open as a later optimisation once the
manager can extract a palette.

**Must verify, not assume:** a custom `canvas_item` shader must keep honouring
`modulate`/`COLOR` explicitly, or faction tint *and* done-darkening silently
stop applying. This is the same class of risk `[IMP-2]` flagged for the
`Sprite2D` → `AnimatedSprite2D` switch, and it should be proven with a test, not
reasoned about.

**Sub-question RESOLVED 2026-07-30 — a property**, per owner. The licence and
source belong to the sheet; a recolour of it is not independently licensable.

### Owner design — 2026-07-30 (`[CSA-18]` shape)

1. A palette swap is a **property**, not a separate asset.
2. Swaps are defined as a **from→to list**, held in the assets somewhere
   (location open — `[CSA-19]`).
3. **A sprite lists which palette swaps it supports.**
4. **Each palette swap also carries a tinting fallback**, used when the swap is
   not defined or not allowed for the sprite in question.

This is a good shape and worth naming why: point 4 means **palette swap can
never harden into a requirement**. A swap always has a degraded-but-valid
rendering, which is the same "zero required art" stance as `[CSA-10]` applied to
recolouring — and it keeps the existing `modulate` path alive as the fallback
rather than replacing it. `[CSA-19..26]` below are the parts still unspecified.

### Palette swaps — measured facts (Godot 4.6.3, not read from docs)

Probed headlessly on 2026-07-30 in this project; probe scripts were temporary and
are not committed. Re-measure rather than trusting this block after an engine bump.

| Fact | Measured | Why it matters |
|---|---|---|
| Project renders with **`gl_compatibility`** on desktop *and* mobile | `project.godot:195-196` | The palette shader must live inside the Compatibility feature set, which is also what a web export uses. Do not design against Forward+ only. |
| Canvas texture filter default is **0 (Nearest)** | `project.godot:197` | Already correct for exact colour matching. Linear filtering would blend neighbouring palette colours and break per-pixel remapping — this project has dodged that by default, but a per-node `texture_filter` override would reintroduce it. |
| PNG round-trip via `Image.save_png` → `Image.load` is **byte-exact** in `FORMAT_RGBA8` | Probed: 4/4 pixels identical, including a fully transparent pixel and a ±1 near-miss neighbour | Exact from→to matching is viable; a raw-loaded `user://` PNG does not silently drift. This is what makes the whole approach workable with `AssetResolver`'s raw loader. |
| A remap `canvas_item` shader with `uniform vec4 from_colors[16]`, a `swap_count` loop and `COLOR = src * COLOR` **parses cleanly** | Probed: 4 uniforms reflected | The intended shader shape is at least syntactically valid in 4.6.3. |
| The shader parser **does validate identifiers** — a bogus built-in fails with "Unknown identifier" | Probed | So the clean parse above is real validation, not a no-op. |
| **`MODULATE` is a distinct built-in** in `canvas_item` fragment | Probed: parses with no error | **The composition trap.** Because `MODULATE` exists separately from `COLOR`, a fragment shader that writes `COLOR = src` can drop the CanvasItem's modulate — i.e. faction tint *and* done-darkening stop applying, silently. |

**Not proven, and do not assume it is:** headless uses the dummy rasterizer, so
this shows *parsing*, not GPU compilation or visual output on the Compatibility
backend. Whether `COLOR` alone carries the CanvasItem modulate under 2D batching
is exactly the kind of thing the dummy renderer cannot answer. It needs a real
visual pass on the Windows host — the same gate `[IMP-2]` set for the
`Sprite2D` → `AnimatedSprite2D` switch.

### [CSA-19] Where do palette-swap definitions live? **[RESOLVED 2026-07-31 — A, pack-level]**
Point 3 of the owner design ("a sprite lists which swaps it supports") means
definitions must be **shared and addressable by id** — a swap cannot be private
to one sheet if several sheets declare the same one.
- **A — Their own catalogue kind** (`palette_swap@1`), like any other content.
- **B — One pack-level palettes document** listing all swaps.
- **C — Inline in each asset's sidecar** (duplicated per sheet).
- **Rec: A.** It is the standardized-documentation answer, it gives a swap an id
  for sprites to reference, and it gets validation and reference-model entry for
  free. C makes "recolour every sheet consistently" an edit of every sheet, which
  is the failure mode the shared-definition design is avoiding. B is A without
  the benefits.
- **RESOLVED 2026-07-31 — A, with pack-level definitions** (owner). Own catalogue
  kind, defined at pack level so several sheets share one swap.
- **Two matching rules fixed at the same time (owner):**
  1. **Exact colour matches only** — no fuzzy matching at runtime — **except for
     transparent**, which is handled specially (`[CSA-20]`, `[CSA-31]`(a2)).
  2. **A swap is partial, not all-or-nothing.** Colours present in a sprite but
     absent from the swap's `in` list **do not disqualify the sprite**; they are
     simply left unchanged.
  - *Why rule 2 is the important one:* it means one faction swap can be applied
    across a whole roster of sheets that share an armour palette but differ in
    skin, hair and weapons — nothing needs to be exhaustive, and adding a new
    sheet cannot "break" an existing swap. It also makes the near-miss problem in
    `[CSA-21]` cosmetic rather than fatal: unmatched anti-aliasing pixels just
    stay their original colour.

### [CSA-20] What exactly is a from→to entry? **[RESOLVED 2026-07-31 — full RGBA]**
- Needs: exact 8-bit RGBA or RGB-with-alpha-preserved; whether **alpha** may be
  remapped; first-match-wins vs last; whether a `to` may be fully transparent
  (an erase); and whether entries are ordered or a map.
- **Rec:** RGB match with alpha preserved, first-match-wins, ordered list,
  transparent `to` **disallowed** (an erase is a different feature and a likely
  authoring mistake). Exact 8-bit equality by default — see `[CSA-21]` for
  tolerance.
- **RESOLVED 2026-07-31 — full RGBA, first-occurrence wins, duplicate-input
  warning** (owner). Overrides the "RGB match with alpha preserved" half of the
  recommendation: matching is on **all four channels**.
  - **The editor warns when the same exact colour appears more than once in the
    input list**, and **the first occurrence takes effect**. Deterministic, and
    the warning catches the real authoring mistake (two rules fighting over one
    colour) without making it an error.
  - *Consequence of full RGBA:* semi-transparent pixels are matchable, which
    matters for soft shadows authored at a fixed alpha. It also means a `from`
    entry must state its alpha — another reason the labelled-channel storage from
    `[CSA-31]`(a2) is the right shape.
  - *Still standing:* transparent is special-cased per `[CSA-19]`, and a fully
    transparent `to` remains disallowed.

### [CSA-21] Tolerance, anti-aliasing and dithering **[RESOLVED 2026-07-31 — exact match; tunable detector]**
Exact matching is measured to be reliable (above) — but only for pixels the
author actually listed. Anti-aliased edges and dithered shading produce
near-miss colours that will **not** be remapped, leaving halos of the original
colour around a swapped region.
- **A — Exact match only.** Simple, fast, predictable; pushes the problem onto
  art selection.
- **B — A tolerance radius** (the probe shader already carries one).
- **C — Exact match plus a validation pass** that reports near-miss colours the
  author probably meant to include.
- **Rec: A + C.** Tolerance sounds helpful but silently captures neighbouring
  palette entries and is very hard to debug; a validator that says "17 pixels are
  within 2/255 of a listed colour — did you mean these?" gives the same help
  visibly. Keep the tolerance uniform in the shader but default it to zero.
- **RESOLVED 2026-07-31 — as recommended, with user-tunable sensitivity**
  (owner). Runtime matching stays **exact** (`[CSA-19]`); the **near-miss
  detector's sensitivity is tunable by the author**, not fixed.
  - *Read carefully — two different thresholds:* the shader's match is exact and
    is not the thing being tuned. What tunes is the **authoring-time detector**
    that says "these 17 colours are close to one you listed." Sensitivity turns
    that from a fixed guess into a dial the author sets per sheet, which is what
    heavily-dithered art needs and clean pixel art does not.
  - *Pairs with `[CSA-31]`(a2)'s frequency count:* sensitivity plus per-colour
    pixel counts is what separates "6 colours that matter" from "200
    anti-aliasing colours" without guessing on the author's behalf.

### [CSA-22] Composition with faction tint and done-appearance **[RESOLVED 2026-07-31 — fully; keyed lookup]**
The measured `MODULATE` finding makes this concrete rather than theoretical.
- Needs: does the palette shader multiply `MODULATE` back in (preserving today's
  faction tint and `set_done_appearance()` darkening), or does palette swap
  **replace** faction tinting, leaving done-appearance to find another mechanism?
- **Rec:** shader multiplies `MODULATE`, and **faction tinting stays exactly as
  it is** for v1. Palette swap becomes an *additional* per-sprite property, not a
  replacement for the faction system. That keeps `[CSA-18]` additive and avoids
  rewriting `_base_modulate`/`set_done_appearance()` in the same change — which
  is the one non-additive area `[IMP-2]` already warned about.
- Later, a faction *may* be expressed as a palette swap with the faction colour
  as its tint fallback — which is exactly what the owner's point 4 enables.
- **RESOLVED 2026-07-31 — palette swap REPLACES faction tint when available**
  (owner), overriding the "keep faction tinting exactly as it is for v1"
  recommendation. Same pattern for the **expended/done** state: check for a valid
  palette swap first, fall back to tint. **HP bars stay faction-coloured.**
  - **This makes the work non-additive, as `[IMP-2]` warned.** `_base_modulate`
    currently *is* faction identity (`Unit.gd:78-93`) and `set_done_appearance()`
    darkens it (`Unit.gd:605-608`). Under this decision both become
    *fallback* paths behind a swap lookup, so the tint stack needs restructuring
    rather than extending. Budget for it; do not slip it into another slice.
  - **The HP-bar rule is what makes this safe**, and is worth stating as the
    reason rather than a detail: once a sprite can be recoloured to anything an
    author likes, colour alone no longer reliably signals faction. Keeping the HP
    bar faction-coloured preserves a **non-authorable** faction cue that no pack
    can accidentally destroy. Any later "author can skin the HP bar" request
    should be weighed against that.
  - *Consequence:* `set_done_appearance()`'s darkening constant stops being the
    definition of "done" and becomes the fallback definition. A pack supplying a
    `done` swap owns that look entirely — including the ability to make it
    illegible, which is an argument for a validation warning rather than a block.
  - **RESOLVED 2026-07-31 — keyed lookup** (owner): **one swap per (faction,
    state) pair**, not two layered lookups.
    - Layering two exact-match swaps means the second operates on colours the
      **first just produced** — order-dependent, and very hard for an author to
      reason about when debugging a wrong colour. Keyed keeps **every swap
      defined against the original art**, which is the only version of the
      pipeline an author can hold in their head.
    - *Cost, accepted:* the author writes N×M swaps rather than N+M. The editor
      should mitigate this by **generating the state variants** from a faction
      swap (e.g. derive `done` by applying the darkening constant to each `to`
      colour), leaving the author to override only where the derived result is
      wrong. That keeps authoring cheap without making *resolution* compositional.
    - *This also keeps `[CSA-24]`'s ceiling meaningful*: one lookup per sprite per
      draw, so the 32-entry cap is measured against a single swap, not a chain.

### [CSA-23] When does the tint fallback fire? **[RESOLVED 2026-07-31 — as recommended]**
Owner accepted: one unconditional-by-construction fallback path with a structured
repair-report entry when it degrades. A missing swap is never an error.

Owner design point 4 gives every swap a tint fallback. The trigger list needs to
be closed, and it is longer than "not defined":
- the sprite does not list this swap; the swap id does not resolve; the art has
  none of the `from` colours present; **the platform cannot run the shader**
  (web / Compatibility limits); or a user accessibility setting forces it.
- **Rec:** treat all of these as the same path and make the fallback
  unconditional-by-construction — the renderer asks for a swap and always gets
  *something*, with a structured repair-report entry when it degraded (the
  `AssetResolver` report already has this shape). Never let a missing swap be an
  error.

### [CSA-24] Platform ceiling — how many swaps, how big? **[RESOLVED 2026-07-31 — max 32, rec 16]**
- Needs: maximum entries per swap (the probe used 16, arbitrarily), uniform array
  limits under `gl_compatibility`, and cost of a per-fragment loop on low-end and
  web targets.
- **Rec:** fix a documented cap (16 or 32), validate against it at author time
  with a clear message, and measure on the web export before raising it. An
  unbounded from→to list is a per-pixel loop of unbounded length.
- **RESOLVED 2026-07-31 — max 32, recommend 16, keep the number easy to change**
  (owner), possibly author-adjustable later once testing shows the real cost.
  - *Rec for implementation:* make the cap a single named constant consumed by
    the shader's array size, the validator's message, and the editor's warning —
    so "raise it to 48 after measuring" is one edit, not three. Uniform array
    size is compile-time in GLSL, so treat the shader's array length as generated
    from that constant rather than hand-written.
  - *Rec:* the **recommended** 16 should be a soft warning in the editor, not a
    second hard limit — an author at 20 colours is fine, just warned they are
    past the tested-comfortable range.

### [CSA-25] Does the manager bake variants? **[RESOLVED 2026-07-31 — at export; provenance unchanged]**
The measured byte-exact round-trip means a CPU bake is trivially correct: apply
the remap to an `Image` and save a new PNG.
- **Rec: yes, as an author-side action, not a runtime path.** It is the escape
  hatch for web/perf (`[CSA-24]`), for art where remapping is unreliable
  (`[CSA-21]`), and for authors who would rather ship pixels than trust a shader.
  A baked variant is then just another sheet — but note it inherits the source's
  licence, so `[CSA-6]` provenance must carry across the bake.
- **RESOLVED 2026-07-31 — an author-side option at EXPORT time** (owner).
  Baking is offered when exporting a pack, not as a runtime path.
  - *Why export is the right moment:* it keeps the authoring copy editable and
    swap-driven while letting the distributed copy be pixels — so an author can
    keep iterating on palettes without re-baking, and the exported pack is the
    only place the flattened result exists.
  - **Later, same seam:** trimming and stitching **custom sprite sheets** for
    authors who upload a large sheet and use only two or three sprites from it.
    That is the same machinery — read arbitrary rects (`[CSA-7]`), write a new
    PNG (`[CSA-31]`(a0)) — pointed at a different goal, and it directly reduces
    the size and licence exposure of a shipped pack by not carrying art the pack
    never uses.
  - **Open:** does export-time baking rewrite `source_refs`/`derived` markers
    (`[CSA-32]`) on the baked output? *Rec: yes* — a baked sheet is a derivative
    of the original plus a named swap, and that is exactly what the `derived`
    marker is for.
  - **RESOLVED 2026-07-31 — provenance stamps stay UNCHANGED** (owner),
    overriding the recommendation above. **Our baking must not combine sources**,
    so a bake is only *deleting* and *precalculating* information that was
    already there — no new authorship, no new source, nothing to re-attribute.
    - *Why this is the better reading:* a `derived` marker exists to stop a record
      claiming an asset **is** the original after a human changed it. A bake
      changes no artistic content; it materialises a transformation the pack
      already described. Stamping it would dilute `derived` into "something
      happened to this file", which is exactly the signal `[CSA-32]` needs to
      stay sharp.
    - **Forward constraint this places on trimming/stitching:** the same rule
      means a *stitched* sheet may only combine sprites **from the same source**.
      The moment stitching merges art from two differently-sourced sheets, the
      output has two `source_refs` and the "unchanged provenance" shortcut stops
      being true. *Rec:* build trimming/stitching same-source-only, and treat
      cross-source stitching as a separate feature that must carry multi-source
      provenance — not as a natural extension.

### [CSA-26] What do swaps mean to the reference model and More Info? **[RESOLVED 2026-07-31]**
Ties `[CSA-18]` back to `[CSA-12]`/`[CSA-15]`.
- Needs: does a `palette_swap` get a reference entry and facts; does More Info
  show the class's sprite in the **player's faction colours** or a neutral
  default; do generated Markdown/PDF renderings show variants at all?
- **Rec:** the swap gets an entry (it is catalogued content under `[CSA-19]`=A),
  More Info shows the **contextually correct** variant since it is a resolved
  live value, and static renderings show the unswapped sheet plus a list of
  available swaps. Do not generate one image per variant per asset in the docs.
- **RESOLVED 2026-07-31 — More Info is context-based; the reference model lists
  every available swap and displays native colours** (owner).
  - So More Info shows the sprite as it actually appears in the current context
    (a resolved live value), while the reference/compendium view shows the art in
    its **native, unswapped colours** alongside an enumeration of the swaps that
    exist for it.
  - *Why that split is right:* More Info answers "what am I looking at right
    now"; the reference answers "what is this asset". Showing the reference in one
    faction's colours would make an arbitrary context look canonical.
  - *Pairs with `[CSA-14]`'s live-animation requirement:* the compendium view is
    where an author checks their sheet, so native colours + live animation + the
    swap list is the complete "inspect this asset" surface.

### [CSA-27] Accessibility — is palette swap the colourblind seam? **[RESOLVED 2026-07-31 — fully; author-owned + faction glyph]**
Faction identification by colour is the classic colourblind failure in tactics
games, and this feature is the natural place to address it.
- **Rec:** confirm palette swaps may be **user-selected**, not only
  author-assigned, so a colourblind palette is a first-class use rather than a
  retrofit. It costs nothing now (it is the same lookup) and is expensive later.
  This also gives `[CSA-23]`'s "user setting forces fallback" trigger a purpose.
- **RESOLVED 2026-07-31 — as recommended, plus a non-colour faction indicator**
  (owner). User-selected swaps are first-class. **Additionally: consider
  shortening the HP bar and adding a faction glyph — or a faction-shaped frame
  around a different glyph — to that row**, as a faction indicator that does not
  depend on colour at all.
  - **This closes a real hole rather than polishing one.** `[CSA-22]` made the
    faction-coloured HP bar the non-authorable faction cue — but a *colour* cue
    is exactly what fails for a colourblind player, so faction identity was still
    reachable only through hue. A glyph in the same row makes the indicator
    **redundantly encoded** (colour *and* shape), which is the standard fix and
    is far cheaper designed in than retrofitted.
  - **The "frame around a different glyph" form is the stronger one.** It turns
    one scarce row into a composable slot: the frame carries faction, the glyph
    inside carries whatever else that unit most needs to advertise (status
    condition, unit class, leader/boss marker). One lane, two channels.
  - **Cost to weigh:** shortening the HP bar reduces its readable resolution at
    `TILE_SIZE = 64`, where the bar is already small. Worth prototyping both — a
    shortened bar plus glyph, and a full bar with the glyph above/below — before
    committing, and worth checking at the smallest supported
    `menu_scale_index`, since a glyph illegible at minimum scale is not an
    accessibility feature.
  - **Open:** is the glyph **engine-owned or author-supplied**? *Rec:
    engine-owned and non-skinnable*, per `[CSA-28]`(i) — its entire value is that
    no pack can weaken it. Authors get faction *colour*; the shape stays ours.
  - **REVISED 2026-07-31 by owner — the burden sits with authors.** Most of the
    colourblind-accessibility responsibility belongs to **authors**, and our job
    is to **give them tools** — perhaps a per-campaign **"UI theme"** setting.
    This overrides the "engine-owned, non-skinnable" recommendation above and
    `[CSA-28]`(i).
    - *It maps onto an existing seam:* `UiThemeDef` is already the proposed token
      registry resolving through `AssetResolver`
      (`ui_ux_asset_inventory_and_reuse_2026-07-02.md`). A per-campaign UI theme
      is that registry, scoped to the active pack — not a new concept.
    - **The risk, stated once and then accepted:** if authors own accessibility,
      a pack can ship an inaccessible campaign and the player has no recourse
      inside it. The mitigation is entirely in the tooling — so the tools need to
      make the accessible choice the *easy* one, not merely the possible one.
      Concretely: ship legible default themes worth starting from, warn in the
      editor on low contrast rather than only documenting it, and keep the
      redundant-encoding affordance (the faction glyph) present in the default
      theme so an author has to actively remove it rather than forget to add it.
    - **Open — one word settles it:** is the per-campaign "UI theme" an **author**
      setting (the pack ships one or more themes) or a **player** setting (the
      player picks a theme, remembered per campaign)? *Rec: both, layered* —
      the pack supplies themes, the player may override per campaign, and the
      override wins. That is the cheapest version of "burden on authors" that
      still leaves a player who cannot read a theme somewhere to go.
    - **RESOLVED 2026-07-31 — the pack supplies; the player's preference is
      remembered per PACK, across campaigns and runs within it** (owner).
      - *Note the scope carefully: the key is **pack identity**, not campaign and
        not run.* A player who picks a readable theme once keeps it for every
        campaign and every run in that pack — they are never asked twice for the
        same body of content. A different pack starts from that pack's own
        default, since its themes are its own.
      - *Consequence for storage:* this is a small per-pack preference map, and
        it belongs with the **portable** half of the settings split in
        `[CSA-37]` — it is a comfort/accessibility choice, machine-independent,
        and exactly the kind of thing a player would be annoyed to re-pick after
        moving machines. It also survives a pack version bump, since the key is
        pack identity rather than version.
      - **RESOLVED 2026-07-31 — fall back to the pack's default and say so
        once** (owner), when a pack **removes** the theme a player had selected.
        - A vanished theme is exactly the case where a colourblind player needs
          to know **why the screen changed**. A silent fallback reads as a
          rendering bug; a one-time notice is honest without nagging.
        - *Not a blocking prompt:* load is never held on a theme dialog, since
          the trigger may be nothing more than a theme rename in a pack update.
        - *Implementation note:* "once" is per (pack, removed-theme-id), so a
          player is not re-notified on every launch. The stored preference is
          then rewritten to the default — the dangling id is not kept hoping the
          theme returns.

### [CSA-28] The shell / skin boundary — no default art through the manager **[RESOLVED 2026-07-31 — rule + all sub-questions]**
**Owner direction 2026-07-30:** *no* default art goes through the asset manager.
The **main menu, campaign library, and editor** have built-in graphics.
**Everything else is author-provided.** Ideally even the **settings screen**
re-skins per active campaign.

#### What the boundary actually is

Not "which screens look nice" — **two different ownership and licence regimes in
one program**:

| | Shell | Skinned |
|---|---|---|
| Art lives in | `res://`, inside the executable | the active pack, in `user://` |
| Licence attaches to | **the program** | the pack |
| Exists when no pack is active | yes | no |
| Reachable by `AssetResolver` | **never** | always |
| Can a pack change it | **no** | that is the point |

The reason the line is drawn where it is: **the shell must be able to run with no
pack at all.** `[CSA-33]` makes "no packs installed" the ordinary first-run state,
so every surface a user can reach before activating a pack must have art that
ships with the program — and every surface that ships art with the program adds
to the executable's licence surface, which `[CSA-31]`(d) worked to keep empty.
Shell art is therefore *deliberately minimal and first-party*, and everything
else is pushed into packs where its obligations travel with it.

#### The distinction that resolves most confusion

**A shell surface may still *display* pack art as content.** The campaign library
shows pack cover art and banners; the editor previews the very sheets an author is
importing; a load-game row may show a campaign's icon. None of that makes those
screens skinned.

- **Chrome** — the panel frames, buttons, fonts, backgrounds *of the screen
  itself* — is what banding governs.
- **Content** — art the screen is displaying *about* a pack — is pack data,
  resolved through `AssetResolver` like anything else, and may appear in any band.

Without this split, "the campaign library has built-in graphics" reads as
"campaign covers can't be shown", which is wrong and would gut the library.

#### The rule — RESOLVED 2026-07-31, and it replaces the banding table

**Owner:** *"The panel is the thing that asks for a skin, and if you can access
it while a pack is loaded, the pack should be able to skin it."*

Two clauses, and both do work:

1. **The panel opts in.** Skinnability is declared *by the surface*, not granted
   by a central list. This is the `[CSA-16]`-16a slot registry seen from the
   other side, and it answers `[CSA-28]`(a): **the panels own the list**, so it
   cannot drift from the code the way a curated document would.
2. **Reachability decides eligibility.** If a panel is reachable while a pack is
   loaded, that pack may skin it.

**This dissolves the dual-context problem rather than solving it.** The settings
screen is skinnable *because* it is reachable during play, and falls back to
built-in when no pack is loaded — no special case, no band membership, no
per-screen argument. The banding table below is retained only as a **worked
example** of what the rule produces; it is no longer the mechanism.

**One sharp edge that needs confirming.** The original direction said the **main
menu, campaign library, and editor** have built-in graphics — but you *do* access
the editor while a pack is loaded, since editing a pack is loading it. Taken
literally, clause 2 would make the editor skinnable by the pack being edited,
which is both contradictory and unpleasant (a half-finished theme rendering the
tool used to fix it).

- *Rec:* read "loaded" as **activated for play** — `active_package_identity` set
  by a play session, not by an editing session. Editing a pack does not activate
  it, so the editor stays shell chrome while still *displaying* pack art as
  content (`chrome vs content`, above). The campaign library resolves the same
  way: it lists packs, it does not play them.
- That keeps **one** rule with a stated meaning for "loaded", rather than one
  rule plus a three-screen exception list.
- **RESOLVED 2026-07-31 — "active for play, including any in-editor or
  from-editor launch"** (owner). That is the wording; use it verbatim.
  - *The editor-launch clause is the part that matters.* A playtest launched from
    the editor **is** active for play, so the game surfaces skin exactly as a
    player would see them — which is the only way an author can check their own
    theme. The **editor's own chrome** stays built-in throughout, because editing
    is not playing. One pack, two simultaneous relationships, cleanly separated.
  - *Implementation note:* this makes the predicate "is a play session active",
    not "is a pack open". Whatever sets `active_package_identity` for a test
    launch must set it the same way a real launch does, or the author's preview
    silently differs from the player's view — which would defeat the purpose.

This draws a boundary the codebase does not currently have. The table below is
now **illustrative** — what the rule yields against existing `scripts/ui/`
surfaces, not an independent source of truth:

| Band | Surfaces (existing scripts) | Art source |
|---|---|---|
| **Shell** — exists before/without a campaign | `MainMenu`, `CampaignLibraryScreen`, `LoadGameScreen`, `NewGameScreen`, the editor | **Built-in only.** Never touched by the manager. |
| **Dual-context** | `SettingsScreen`, `DisplayConfirmDialog`, `ModalScreen`, `MenuScale` | Built-in when no campaign is active; **campaign-skinned when one is** |
| **In-campaign** | `HUD`, `CombatHUD`, `PrepScreen`, `MapMenu`, `ActionMenu`, `ItemMenu`, `WeaponMenu`, `UnitDetailsScreen`, `LevelUpScreen`, `PromotionScreen`, `ReclassScreen`, `MapResultsScreen`, `GameOverScreen`, `PhaseBanner`, `SelectionCursor`, `AttackPreview`, dialogue, map, units | **Author-provided**, with engine fallback |

**Open questions:**
- **(a) Is that banding right, and who owns the list?**
  **[RESOLVED 2026-07-31]** — the **panels own it**, by declaring their own
  skinnable slots. No curated band list to maintain or drift.
- **(b) The settings screen** — **[RESOLVED 2026-07-31 by the rule above]**: it
  is reachable during play, therefore skinnable, therefore not a special case.
  Original framing retained for the transition detail it raises: It is reachable from the main menu (shell, no campaign) *and*
  mid-campaign. So a skinnable slot must resolve differently by context, and
  something must define the transition: does the skin apply the moment a campaign
  is selected, or only once a run is loaded? **Rec:** bind to *active pack
  identity*, which already exists at runtime (`active_package_identity`), and
  fall back to built-in whenever it is empty. That makes "no campaign active" an
  ordinary fallback rather than a special case.
- **(c) `[CSA-10]` interaction — this is not a contradiction, but it reads like
  one. [RESOLVED 2026-07-31 — state the fallback clause explicitly]** (owner).
  "Everything else is author-provided" and "no art is required" coexist only if
  *absence* falls back to **engine primitives** — generated placeholder tiles,
  the default `UiThemeDef`, plain text rows — **not** to a shipped default art
  set.
  - **The clause is stated, not inferred, and the phrase "author-provided"
    stays.** The natural reading of "author-provided" is "the author must provide
    it", which is exactly what `[CSA-10]` forbids — so the fallback has to be
    written down. Rewording the phrase alone would fix the reading while leaving
    the actual fallback behaviour unspecified.
  - **The "never to a shipped default art set" half is the load-bearing one.** It
    is what keeps `[CSA-31]`(d)'s empty licence surface from being re-opened by a
    fallback path quietly acquiring art.
- **(d) Direct conflict with the ratified taxonomy. [RESOLVED 2026-07-31 —
  supersede the row outright]** (owner). Its Tier-1a table says of icons: *"Ship
  the **default** set as one packed atlas; allow author single-file drop-ins"*,
  and §Tier-1a reserves the packed frame-table form for *"the shipped default
  set, where we own the build tool"*. Under this direction there is **no shipped
  default icon atlas** outside the shell.
  - **Both statements are deleted, not narrowed.** The taxonomy describes *pack*
    assets, and `[CSA-28]`(e) keeps shell art out of the pack system entirely —
    no manifest, no `art_asset@1` entry, no `AssetResolver` lookup. So the row has
    **no subject left to describe**: there is no shipped default set in a pack,
    and shell chrome is not the taxonomy's business.
  - *Why not "default set means shell-only chrome":* that would put the taxonomy
    in the business of specifying art outside the pack system, and would leave the
    packed frame-table form specified — implying a build tool we would still owe.
  - This is the **same shape as `[CSA-2]`'s** now-subject-less "`.tres` is an
    authoring convenience" clause. Both are subject-less, both go, and they are
    two of the **three edits owed to the taxonomy document** (the third is
    `[CSA-33]`(c)). Do them in one pass — leaving either standing guarantees
    someone builds the atlas.
- **(e) Does the built-in shell art live in the same catalogue at all?** *Rec:*
  no — shell art stays ordinary `res://` project assets with no manifest, no
  `art_asset@1` entry, no `AssetResolver` lookup. Keeping it out of the pack
  system is what makes "no default art through the manager" enforceable rather
  than aspirational.
- **(f) When does the skin apply and unapply? [RESOLVED 2026-07-31 — as
  recommended]** (owner). The banding says *what* skins; this is *when*.
  Candidate moments were: pack selected in the library; run loaded; first map
  entered; and the reverse on quit-to-menu. A campaign-skinned settings screen
  opened from a paused map must stay skinned; the same screen opened from the
  main menu after quitting must not.
  - **The rule: the skin follows `active_package_identity`, and quitting to the
    shell deactivates the pack.** One observable answers it everywhere. Anything
    else invites a screen that is skinned in one entry path and not another.
  - Note this is the *same* observable the `[CSA-28]` rule already turns on
    ("active for play, including any in/from editor launch"), so (f) adds no new
    state — it only pins the deactivation edge.
- **(g) What happens on a pack swap mid-session? [RESOLVED 2026-07-31 — as
  recommended]** (owner). Deactivating one pack and activating another must not
  leave half-resolved textures on a shared surface.
  - **Skin resolution is part of the atomic content-session activation that
    `IMPL-ZERO-CONTENT-FOUNDATION` already built**, not a separate lazy-loaded
    path. The machinery exists and already has the right all-or-nothing
    semantics; a second path would have to re-derive them and would drift.
- **(h) Can a pack skin a surface it should not? [RESOLVED 2026-07-31 — warn and
  ignore]** (owner). The registry is the control: a slot that is not registered
  as skinnable simply has no binding key, so a pack naming it is an
  **unknown-slot validation warning**, not a silent override.
  - **Never fail the pack** — an author who over-reaches should not have their
    campaign refuse to load. Warning, ignore the binding, load the campaign.
- **(i) Accessibility interaction** — **[SUPERSEDED 2026-07-31]** by the owner's
  `[CSA-27]` revision: the burden sits with authors and our job is tooling, so
  the "declare accessibility affordances non-skinnable" recommendation below does
  **not** stand. What survives is the mitigation list recorded in `[CSA-27]` —
  legible default themes, editor contrast warnings, and the faction glyph present
  by default so it must be actively removed rather than forgotten. Original text:
- **(i-original) Accessibility interaction, and it is not small.** `[CSA-27]` makes some
  visual language user-controlled, while this row makes much of it
  author-controlled. Where they meet — a pack that skins a panel to low contrast,
  or replaces an icon a player relies on — **the user setting must win**. *Rec:*
  the shell's accessibility-relevant affordances (contrast floor, text
  legibility, the faction indicators from `[CSA-22]`/`[CSA-27]`) are declared
  **non-skinnable** in the registry from the start. It is far easier to open a
  slot later than to take one back once packs bind to it.

### [CSA-29] What does an unskinned campaign look like? **[REFRAMED 2026-07-30]**
**The premise was wrong.** This was written assuming a new pack normally has
almost no art. Under `[CSA-30]`/`[CSA-31]` a pack is **forked**, and templates
**generate** flat-colour art, so an artless pack is not the normal state — it is
close to unreachable. The engine-primitive fallback is a safety net for a
corrupted or hand-edited pack, not the everyday look.
- What survives: the fallback still must exist and still must not crash
  (`AssetResolver`'s chain), and the *generated* look — flat colour blocks — is
  what a drafting author actually sees. So the real question is **what the
  generator emits**, which is `[CSA-31]`, not what a fallback looks like.

### [CSA-30] Fork-first authoring, and licence propagation **[RESOLVED 2026-07-30 — complete copy + per-hop history]**
**Owner direction:** nobody generates a pack from scratch. The expected path is
**fork an existing pack**; inside a pack, the expected path is **copy a template
and edit it**.

Partly built already: `PackManifest.forked_from` exists, is validated as a pack
id, and is surfaced by `CampaignPackRegistry`
(`PackManifest.gd:9,24,49-50`; `CampaignPackRegistry.gd:142`). The
copy/fork/resync provenance contract is designed in
`content_pack_compatibility_resync_contract_2026-06-28.md`.

**The unaddressed consequence: a fork inherits the source pack's art *and* its
licence obligations.** This is where `[CSA-6]`'s source records stop being
bookkeeping and start being load-bearing:
- Forking a pack containing CC-BY art means the fork **must** carry attribution —
  two sources in `Campaign_Pack_0` are formally CC-BY 4.0.
- Forking a pack whose own content is "all rights reserved" (which is
  `Campaign_Pack_0`'s stated position until v1) means the fork **may not be
  redistributed at all**.
- So "fork this pack" is the exact moment a licence obligation transfers to a new
  author who may not read `CREDITS.md`.
**Resolution — owner, 2026-07-30.** Packs are **entirely DRM-free data** and can
be forked externally with no difficulty. An in-editor fork is therefore **the
same complete copy**, plus **a note tracing the upstream history**, and **each
individual asset retains its own source records**.

**What that settles.** Because a fork is a complete copy, per-asset `source_refs`
survive by construction — no transfer mechanism is needed, and the earlier
recommendation that the tool "must not be able to silently drop a source record"
is the wrong frame. Dropping is not the failure mode. Equally, because external
forking is trivial, **in-editor validation is an author aid, not a control**: it
should warn and explain, never block. That matches the campaign library's
data-only stance — there is nothing to enforce and pretending otherwise is
theatre.

**Two provenance axes, do not conflate them:**
1. **Pack lineage** — which pack this was forked from (`forked_from`).
2. **Asset source records** — where each individual asset came from
   (`source_refs` → `source_registry`), carried verbatim through the copy.

**Open — `forked_from` cannot express a history.** `PackManifest.forked_from` is
a **single `String`**, validated as one pack id (`PackManifest.gd:9,24,49-50`). A
"note tracing the upstream history" of a fork of a fork of a fork is a **chain**,
which that field cannot hold.
- **A — Keep the single immediate parent** and reconstruct lineage by following
  it. *Against:* only works if every ancestor is still installed, which for a
  downloaded fork it will not be. In practice the chain is unrecoverable.
- **B — An ordered ancestry list** in the manifest, appended to on each fork.
- **C — A structured fork-history document** (parent id, version, timestamp,
  optional author) per hop.
- **RESOLVED 2026-07-30 — C** (owner). Per-hop history is the structure, with
  each hop carrying an **origin note** (`[CSA-34]`).
- **Rec: C, with `forked_from` retained as the immediate parent** for
  compatibility and cheap display. The history is exactly the "note" the owner
  described, it survives redistribution because it travels inside the pack, and
  per-hop version/time is what makes an upstream diff or resync possible later
  (`content_pack_compatibility_resync_contract_2026-06-28.md` already wants fork
  timestamp and migration history).
- **Note:** the history is a *claim*, not a proof — DRM-free means it can be
  edited or removed. Present it as provenance, never as authenticity. This is the
  same distinction `campaign_library_ux_decisions_2026-07-24.md` already draws
  (integrity ≠ authenticity; signatures deferred).

### [CSA-32] What happens to a source record when the asset is edited? **[RESOLVED 2026-07-30/31 — B; bakes do NOT stamp]**
Falls directly out of `[CSA-30]`: a fork copies an asset *and* its source record,
and then the author repaints it. The record still says "Kenney, CC0" — but the
pixels are now partly the author's.

This matters legally and practically: a derivative of CC-BY art still carries the
attribution duty, so the record must not simply be deleted when the art changes;
but leaving it stating the asset *is* the original is also wrong.

- **A — Record stays as-is.** Simple; overstates the source's contribution.
- **B — Mark the asset `derived`**, retaining the source ref plus a note of what
  changed.
- **C — Drop the record once edited past a threshold.** No workable threshold
  exists, and it is the option most likely to lose an attribution duty.
- **RESOLVED 2026-07-30 — B, using the `[CSA-34]` origin structure** (owner:
  "use the same structure for derived-from assets"). A derived asset keeps its
  source record and gains a derived-from block of the same shape.
- **Rec: B.** There is already a precedent to copy rather than invent:
  `class_schema_trial_v1`'s `occurrence_audit` records a `decision_state` of
  `transformed` / `disputed` / `conflicting` / `ambiguous` for exactly this
  "we changed what the source said" case on text content. Reusing that vocabulary
  for art keeps one provenance model instead of two.
- **Open:** is `derived` set **manually** by the author, or **inferred** by the
  editor when it detects the pixels no longer match the imported original (a
  content hash on the asset would make that automatic — `source_registry` already
  has an optional `content_hash`)? *Lean: inferred, author-editable* — the honest
  default costs the author nothing.

### [CSA-31] Template art generation — the editor makes art, it does not ship it **[RESOLVED 2026-07-31 — one open: (b) generated marker]**
**Owner direction:** the base template should carry art — at minimum **flat
colour rectangles, possibly with a hex colour picker** for drafting. The editor
should carry **just enough schema information to generate those templates on
command**, and **no art needing a redistribution licence except its own GUI**.

This resolves the apparent tension in `[CSA-28]` cleanly: the pack contains all
art, but the author need not source it, because the editor **generates** it.
Generated flat-colour art has no third-party source, so it creates no
redistribution obligation — the licence problem is designed out rather than
managed.

**Prior art exists.** `scripts/tools/generate_placeholder_assets.gd` already does
this: a headless `SceneTree` script emitting solid-colour PNGs at
`GameConstants.TILE_SIZE` for terrain, overlays, unit sprites and the cursor,
with a named colour palette per terrain type. It is a developer tool run by hand
today; `[CSA-31]` is essentially *productionising it into the editor and pointing
its output at a pack*.

**Open questions:**
- **(a0) Generated art is REAL art. [RESOLVED 2026-07-30]** (owner). The
  generator emits **full raw PNGs**, exported and stored in the pack exactly like
  imported art — not a runtime-synthesised texture, not a special-cased
  placeholder type. One asset pipeline, one storage format, one export path.
  *Why this is right:* a generated block and a commissioned sprite differ in
  origin, not in kind, so anything that treats them differently (preview, export,
  palette swap, More Info) would need two code paths forever. It also means the
  measured byte-exact PNG round-trip covers generated art too.
  **Still true:** it should carry the `generated` marker from (b) — that is
  metadata about *origin*, not a different asset type.

- **(a1) Palette extractor + colour sampler. [RESOLVED 2026-07-30 — build both]**
  (owner). Two tools the manager needs:
  - **Palette extractor** — pull *every* colour present in an image. This is what
    unblocks `[CSA-18]` option A for imported art, and it is what makes the
    `[CSA-31]`(e) "seam supporting both" real: extraction turns arbitrary
    direct-colour art into a palette we can swap against.
  - **Colour sampler** — click a pixel, get its code back. This is the eyedropper
    that makes authoring a `from→to` entry practical instead of clerical.
  - **Transparency is tracked**, per owner. This is not a detail — see (a2).

- **(a2) Two sharp consequences of tracking alpha. [OPEN]**
  - **[RESOLVED 2026-07-30]** Owner: store each channel **labelled**; the *order*
    is free so long as it is **consistent and clearly communicated**. So: named
    fields in stored data (order becomes irrelevant there by construction), and
    **one** documented order for any hex string the UI accepts or displays,
    stated at the point of entry. Pick it once, write it in the sidecar schema
    (`[CSA-3]`), and never accept a bare hex string whose order is ambiguous.
  - Original reasoning, retained because it is why labelling matters:
  - **Channel order must be pinned, once, in writing.** The owner said "ARGB";
    Godot's `Color8()` and the common `#RRGGBBAA` hex form are **RGBA**. Same four
    bytes, different order. A `from→to` table written in one order and compared in
    the other fails *silently* — colours simply never match, and the art looks
    unswapped rather than broken. *Rec:* store channels as **named fields**
    (`{"r":200,"g":40,"b":40,"a":255}`) in the sidecar/palette data and treat any
    hex string as a display/entry convenience with its order stated at the point
    of entry. Named fields cannot be misread.
  - **Fully transparent pixels have arbitrary RGB, and the extractor will see
    them.** A transparent pixel may be `00000000` or `FF00FF00` — visually
    identical, byte-different, and the measurement above confirms PNG preserves
    that difference exactly. So a naive "every colour in the image" extraction
    yields phantom palette entries that no one can see. *Rec:* the extractor
    **groups all `a == 0` pixels as one "transparent" entry** and never offers
    them as a `from` target, while the sampler still reports the true bytes when
    asked. Matching stays on RGB with alpha preserved (`[CSA-20]`).
  - **RESOLVED 2026-07-31 — yes, report frequency per colour** (owner). Pixel
    count per extracted colour.
    - Nearly free during the scan, and it is what lets the UI sort **"the 6
      colours that matter" above "the 200 anti-aliasing colours"** — the
      `[CSA-21]` near-miss problem surfacing as a **UI affordance rather than a
      validation message**, which is the cheaper place to solve it.
    - *Consequence:* frequency is **derived, not authored** — it describes a
      specific image at a specific moment. Keep it out of the stored palette data
      and recompute on scan, or it goes stale the first time art is edited.
    - *It also gives the `a == 0` grouping above something to report:* "transparent
      (1,204 px)" as one entry, rather than silently collapsing a count the author
      might want to sanity-check.

- **(a) Generate on entity creation, or on request? [RESOLVED 2026-07-31 — on
  creation, silently]** (owner). Creating a class always yields a working
  coloured block, so art never blocks authoring, and the "expect static art to
  exist" rule in `[CSA-10]` holds **by construction rather than by hope**.
  - *Silently* is the load-bearing word: no prompt, no confirmation step. The
    author notices generated art because it is marked as generated ((b)), not
    because the editor interrupted them at creation time.
- **(b) Is generated art marked as generated? [RESOLVED 2026-07-31 — yes, a flag
  on the `art_asset@1` document]** (owner). An explicit field, **not** inferred
  from an absent source record.
  - It lets the editor show "14 assets are still placeholders", lets `[CSA-6]`
    skip a source record **without it counting as missing provenance**, and stops
    the reference docs presenting a coloured rectangle as authored art.
  - It is also the **capability check** the (c) bake-scope decision depends on:
    "bake a label" is offered on generated art and simply absent on imported art.
  - *Why not infer it from "no source record":* that conflates **"we made this"**
    with **"the author has not recorded provenance yet"** — precisely the
    distinction `[CSA-6]` exists to keep, and the one `[LEG-4]` compliance turns
    on. An explicit flag keeps "unprovenanced import" a reportable state.
  - *Per `[CSA-31]`(a0), the flag is metadata about **origin**, not a different
    asset type* — generated art stays a full raw PNG on the one pipeline.
- **(c) What does the generator emit beyond flat colour? [RESOLVED 2026-07-31 —
  fill + *optional* baked label]** (owner). Flat colour fill, with a short text
  label **baked into the pixels as an option**, not unconditionally.
  - *Why the label exists at all:* a board of identical coloured squares is
    unreadable once there are eight classes, which is exactly the drafting case
    this is for.
  - *Why optional matters:* the label is baked into the PNG (`[CSA-31]`(a0) —
    generated art is real art, one pipeline, no runtime-synthesised overlay), so
    it is **destructive to the fill**. An author who wants a clean colour block
    to recolour via `[CSA-31]`(e) must be able to get one. Optional keeps both
    cases reachable without a second asset kind.
  - **Consequence — regenerating is the only way to change the label**, because
    it is pixels, not metadata. The editor should therefore treat "generate
    template art" as a repeatable command over an existing asset, not a
    once-at-creation event. That does not conflict with (a): (a) fixes when the
    *first* generation happens, not that it can only happen once.
  - **Default — RESOLVED 2026-07-31: "generate plain, bake label in later"**
    (owner). Creation-time generation emits a **plain fill, no label**. Baking a
    label is a **separate, later, author-invoked command** over art that already
    exists.
  - *This settles the (a)/(c) interaction:* silent creation never produces
    lettered art, so the common case stays a clean block that `[CSA-31]`(e)
    recolouring works on directly. The label is opt-in at the moment the author
    actually has the readability problem — a board with eight classes on it —
    rather than pre-emptively.
  - **It also confirms the generator is a repeatable command, not a
    creation-time event.** "Bake in later" only means anything if generation can
    be re-run over an existing asset. Fold that into the tool's shape from the
    start.
  - **Scope — RESOLVED 2026-07-31: generated art only** (owner). "Bake a label"
    is **not** offered on imported art, not even behind a warning.
    - Baking text into a third-party-licensed image modifies a work whose licence
      may forbid derivatives, and `[CSA-32]` establishes that bakes do **not**
      re-stamp source records — so a labelled import would silently carry a
      source record describing pixels that no longer exist.
    - *Why not "allow it with a warning":* that puts a licence decision behind a
      dismissable dialog. The `generated` marker from (b) already tells the
      editor which assets are eligible, so this is a **capability check, not a
      prompt** — the command is simply absent on imported art.
- **(d) Does the shipped game include a forkable starter pack?**
  **[RESOLVED 2026-07-30 — NO]** (owner, overriding the recommendation to ship
  one). The program ships **no campaign pack at all**. Authors either **generate
  templates in the editor**, or obtain the `Campaign_Pack_0` packs, which are
  **distributed alongside the program, not inside it**.
  - **Why this is the stronger answer:** it makes the *program's* licence surface
    empty rather than merely small. A pack distributed alongside carries its own
    `CREDITS.md` and its own obligations (`Campaign_Pack_0` has two formally
    CC-BY 4.0 sources), and those obligations never attach to the executable.
    Shipping even generated art inside would have re-opened the question every
    time the starter pack grew.
  - **It also closes the loop with `[CSA-30]`:** "nobody starts from scratch"
    stays true without a bundled pack, because the editor's template generator
    *is* the from-scratch path, and it produces a real pack immediately.
- **(e) Does the hex colour picker write to the asset or to a palette?**
  **[RESOLVED 2026-07-30 — a seam supporting both]** (owner). The picker edits a
  *colour slot*; whether that slot is baked into pixels or held as a palette
  entry is the seam's business, not the author's.
  - *Why this is the right call:* generated art starts with a tiny known palette
    (one fill colour per asset), so "recolour this draft" and "define a palette
    swap" are the same operation on the same data at that moment. Forcing a
    choice up front would either burden drafting with palette metadata or strand
    drafts outside the `[CSA-18]` machinery.
  - **CLOSED 2026-07-31 by `[CSA-31]`(a1), not separately decided.** The open
    question was what happens when *imported* art (arbitrary, no known palette)
    meets the same picker: either the seam gains a palette-extraction step
    (`[CSA-18]` option A's blocker) or it degrades to "you can tint, not
    recolour".
    - **(a1) resolved to build the palette extractor**, which *is* that step. So
      imported art does **not** degrade to tint-only — extraction gives it a
      known palette and it enters the same colour-slot seam as generated art.
    - *Flagged as an inference rather than a direct answer:* if the intent was
      that imported art degrades to tinting despite the extractor existing, this
      is the line to correct.

- **(f) Does the editor know the entity schema?**
  **[RESOLVED 2026-07-30 — yes]** (owner). The editor knows the schema well
  enough to generate whatever art an entity requires, rather than keeping a
  separate art list.
  - *Consequence:* template generation **follows the schema automatically as it
    grows** — adding a field that references art means new entities get generated
    art for it without a second edit. The alternative would have drifted the
    moment a schema gained a field.
  - *Consequence for `[CSA-33]`:* this is also what makes a **content-free
    engine** workable. With `res://data` gone there is no example content to copy
    a template from, so templates must be derived from the schema itself. Those
    two decisions depend on each other.
  - **RESOLVED 2026-07-31 — no hints. "In engine, schemas are blank. First-time
    authors are encouraged to fork one of the public packs."** (owner,
    overriding the lean toward validation-time hints).
    - Schema-derived templates produce *structurally* valid entities with
      **default values** — a class with zeroed stats — and that is the whole of
      what the engine offers. The editor carries **no game-design opinions**, not
      as baked values and not as guidance.
    - **The blank-page problem is answered by forking, not by hints.** This is
      the same move as `[CSA-33]`(a): the answer to "I don't know what a good
      class looks like" is *a real pack full of real classes*, which is
      strictly better than a hint string and costs the engine nothing.
    - **It also keeps the engine content-free in a second sense.** "Movement is
      usually 4-6" is a balance opinion about *our* game; shipping it would make
      the engine quietly normative for every pack built on it, which is the
      opposite of `[EXT]`'s data-driven direction.
    - **⚠️ Constraint on "public packs":** this means `Campaign_Pack_0`.
      `Campaign_Pack_FE` is **internal-only** under `[LEG-4]` (FE-derivative art)
      and must **never** be presented in-product as a fork target. Whatever
      surface encourages forking needs that list to be explicit, not "whatever is
      installed".

### Colour, briefly — enough to decide `[CSA-18]`/`[CSA-19]`/`[CSA-31]`(e)

Recorded because these questions keep turning on the same handful of facts.

- **A pixel is four 8-bit channels** — red, green, blue, alpha — each 0-255.
  Hex `#RRGGBB` is just those bytes written in base 16; `#FF8000` is
  (255, 128, 0). Alpha is the fourth, often written `#RRGGBBAA`. That is why
  `Color8(200, 40, 40, 255)` and `#C82828` are the same colour.
- **Two ways to store an image.** *Direct colour* stores the actual bytes per
  pixel — what a PNG normally is, and what the measured byte-exact round-trip
  above confirms. *Indexed colour* stores a small **palette** (say 16 colours)
  plus, per pixel, an *index into it*. Classic pixel art was indexed, which is
  why palette swapping was historically free: change the palette, every pixel
  using index 3 changes at once, and nothing touches the image.
- **We are working with direct-colour art.** Third-party CC0 sheets are ordinary
  PNGs, and Godot's `Image` is direct-colour. So we do not get free palette
  swapping; we have to *emulate* it by matching colours — which is why
  `[CSA-18]` is a from→to list rather than a palette pointer, and why exactness
  (`[CSA-21]`) matters at all.
- **Generated art is the exception, and that is the opportunity.** Art the editor
  generates has a palette *by construction* — we chose its colours. So generated
  art can behave like indexed art (swap the palette entry, done) while imported
  art needs colour matching. That asymmetry is exactly why `[CSA-31]`(e)'s "seam
  supporting both" is the right shape.
- **Anti-aliasing and dithering are what break matching.** A hand-drawn sprite
  blends edge pixels toward the background, producing dozens of near-miss colours
  that are *not* in any palette. Match them and you catch colours you did not
  mean; ignore them and swapped regions keep a halo of the original hue. Pixel
  art drawn without anti-aliasing has this problem far less, which is a real
  argument for the art style rather than only for the tech.
- **Tint is not recolour.** `modulate` **multiplies** every channel by one
  colour, so it can darken, wash out, or push everything toward a hue — but it
  cannot map red armour to blue while leaving skin alone, because it has no way
  to treat two pixels differently. This is the whole reason `[CSA-18]` exists,
  and also why a tint is a *legitimate degraded fallback* (it always produces
  something recognisable) rather than a wrong answer.
- **Colour space is the lurking gotcha.** The same bytes can be interpreted as
  sRGB (perceptual, what image files normally hold) or linear (physical, what
  shaders often compute in). If a shader compares a texture sample against a
  colour constant in the wrong space, "equal" colours will not compare equal.
  This is measurable rather than arguable — and the measurement has **not** been
  done here, because the headless dummy rasterizer cannot answer it. It belongs
  in the same visual pass as the `MODULATE` composition check.

### [CSA-34] The origin note — one structure, five places **[RESOLVED 2026-07-30 — structure set; details OPEN]**
**Owner direction:** a pack's data carries **a note from the author on where to
obtain the pack again** — a download link, a personal website, contact info, or
**left blank**. It is added to the fork history and to exported runs. **The same
structure is used for "derived from" assets** (`[CSA-32]`).

**This is one small block reused in five places**, which is why it is worth
naming rather than inlining:

| Where | What it means |
|---|---|
| Pack manifest | "here is where to get *this* pack" |
| Each fork-history hop (`[CSA-30]`) | "here is where to get *that ancestor*" |
| Exported runs | a run can be traced back to the pack that produced it |
| Asset source records (`[CSA-6]`) | where a third-party asset came from |
| Derived-from assets (`[CSA-32]`) | what this art was derived *from* |

**There is already a field of exactly this shape.** `source_registry` records
require a **`locator`** alongside `title`, `attribution`, `rights_status` and
`verified_at` (`class_schema_trial_v1`). Reusing that shape — rather than adding
a parallel "where to get it" concept — is what makes the owner's "same structure"
instruction cheap: art provenance and pack provenance become one vocabulary.

Exported runs already carry provenance too: `campaign_library_ux_decisions_2026-07-24.md`
puts record/author/campaign id + version and `created_at_utc` into the run/save
header at `FORMAT_VERSION = 1`. So this extends an existing header rather than
inventing one — **but confirm against the save schema lock before adding a field.**

**Three things this must not become:**
- **Not a dependency.** A "where to obtain" URL looks exactly like a dependency
  reference, and packs are self-contained (`[ICO-1..6]`). It is a human-readable
  breadcrumb; nothing resolves it, nothing fetches it, and a missing or dead
  locator is never a load error.
- **Never auto-fetched.** Display as text; no network request, no embedded
  preview, no click-through without an explicit confirmation. This matches the
  reference model's restricted-markdown stance (no remote embeds, no filesystem
  links).
- **Not a claim of authenticity.** Like the fork history, it is DRM-free text an
  author or a re-distributor can edit. Present it as provenance only.

**Open details:**
- **(a) Free text, or lightly structured?** *Rec:* a small structured block —
  optional `label`, `locator`, `contact` — rather than one free string, so the UI
  can render "Obtained from: <label>" without parsing, and so a blank field is
  distinguishable from an absent one. Keep every part optional.
- **(b) Contact info is personal data.** An email address in pack data travels to
  everyone who ever receives the pack or a fork of it. *Rec:* the editor states
  that plainly at the point of entry — "this will be shipped with your pack and
  every fork of it" — and it stays blank by default. This is the one field in the
  system where the harm of a thoughtless default lands on the author personally.
- **(c) Does a fork rewrite the note?** When A forks B, the new pack's own note
  should describe *A*, while B's note moves into the history hop. *Rec:* yes —
  and the editor should not silently inherit B's contact details as A's, which is
  the obvious implementation shortcut and also the one that leaks B's identity.

### [CSA-33] First run with no packs installed **[RESOLVED 2026-07-31 — all sub-questions]**
Falls straight out of `[CSA-31]`(d). If the program ships no campaign pack, then
**"no packs installed" is the first thing every new player and author sees** — it
is the default state, not an edge case, and the campaign library's empty/"not
installed" state becomes the front door.

- **(a) What can you actually do from a cold install? [RESOLVED 2026-07-31 —
  import only from the library; the editor is reached separately]** (owner,
  overriding the recommendation to offer both routes in the empty state).
  - The empty campaign library offers **import**, which under `[CSA-33]`(b)
    points at the pack files sitting beside the binary. Template generation is
    **not** advertised there; the editor has its own entry point.
  - **Why this is coherent rather than a narrowing:** it pairs with the
    `[CSA-31]`(f) answer that first-time authors are **encouraged to fork a
    public pack**. The empty library's job is to get the user to *content*, and
    the honest shortest path to content is importing a pack — not authoring one.
    Offering "generate a blank template pack" to someone who just launched the
    game for the first time proposes a project, not a way out.
  - **Consequence for `[CSA-31]`(d):** its line that the template generator "*is*
    the from-scratch path" remains true as a **capability**, but it is no longer
    the **promoted onboarding route**. `[CSA-30]`'s "nobody starts from scratch"
    is now literally the shipped experience rather than an expectation.
  - **Note the boot state is already built** — `MainMenu.gd:74` renders "New Game
    (No Packs)" (`IMPL-ZERO-CONTENT-FOUNDATION`). This decision is about the
    library's empty state, not about reaching it.
- **(b) How do the alongside-distributed `Campaign_Pack_0` packs arrive?
  [RESOLVED 2026-07-31 — files beside the binary, offered for import]** (owner).
  **Never a silent auto-install.**
  - The packs ship in the download **beside** the executable; the campaign
    library **offers to import** them, and the user accepts.
  - *Why:* it keeps the program/pack separation the owner drew in `[CSA-31]`(d)
    **visible to the user** rather than a technicality, and it reuses the
    existing `CampaignPackInstaller` path instead of adding a privileged one that
    would have to re-implement preflight, validation and version checks.
  - *Consequence:* the empty-library state in (a) is the front door **even when
    packs are present on disk** — until the user accepts the import. That is the
    intended reading, not an oversight.
- **(c) Conflict to settle with the taxonomy. [RESOLVED 2026-07-31 — supersede
  the clause]** (owner). `campaign_asset_taxonomy_and_format_2026-07-01.md`
  describes campaigns as living in `user://` **"(defaults seed-copied
  `res://`→`user://` on first run)"** — a mechanism that presumes shipped default
  content to seed *from*. Under `[CSA-31]`(d) there is no shipped campaign pack
  to seed.
  - **The clause goes.** It is not narrowed to the Tier-2 content palette,
    because a seed-copy mechanism with nothing to copy is a **trapdoor**:
    someone eventually fills it with "just a small default pack", and the
    licence surface `[CSA-31]`(d) emptied comes back.
  - `[CSA-33]`(b) already makes pack arrival an explicit user-initiated import,
    so nothing depends on the seed-copy path.
  - **This is the third of the three edits owed to the taxonomy document** —
    with `[CSA-28]`(d) and `[CSA-2]`. One pass, all three.
- **(d) `res://data` — ALREADY DECIDED, and partly built. This register asked a
  settled question.** The **zero-content engine** track answered it on
  2026-07-23 and owner-approved it. `zero_content_engine_implementation_plan_2026-07-23.md`
  states the boundary outright: *"No hidden base pack, implicit `res://data`
  fallback, or v1 pack dependency is permitted."*
  - `RESEARCH-ENGINE-ZERO-CONTENT-2026-07-23` — **completed**, owner-approved.
  - `IMPL-ZERO-CONTENT-FOUNDATION` — **completed**: valid inactive boot, atomic
    content session, no-pack player flow. `MainMenu.gd:74` already renders
    **"New Game (No Packs)"**, so `[CSA-33]`(a)'s cold-start state is **built**,
    not hypothetical.
  - `IMPL-ZERO-CONTENT-BASE-PACK` (Slice 3, planned) — extract the base game into
    **one self-contained normal pack**.
  - `IMPL-ZERO-CONTENT-EXPORT-GATE` (Slice 4, planned) — remove the compatibility
    data source and **enforce a content-free engine export**.
  - So: `res://data` goes, gameplay stays disabled until a pack validates and
    activates, and the engine ships rules-and-registries but no content.
  - **Lesson recorded deliberately:** this question was re-derived from first
    principles when the tracker already held the answer. Check
    `coordination/tasks.json` before opening a question about engine/pack
    boundaries — it is the only cross-repo view, and this register nearly
    duplicated a completed decision.

- **(e) The one genuinely open coupling: where does Slice 3's base pack go?**
  Slice 3 extracts the base game into "one self-contained normal pack", and the
  zero-content plan forbids a *hidden* base pack — but it does not say whether
  that extracted pack is **bundled with the program** or **distributed
  alongside** it. `[CSA-31]`(d) now answers that from the other direction: the
  program ships no pack, so the base pack must be an alongside artefact
  (`Campaign_Pack_0` repo), not a bundled one.
  - **This needs to reach whoever implements Slice 3.** "Extract the base game
    into a pack" reads naturally as "…and ship it", which is exactly the outcome
    `[CSA-31]`(d) rules out. Flag it on `IMPL-ZERO-CONTENT-BASE-PACK`.

### [CSA-35] Web build with no packs — bootstrap demo content? **[RESOLVED 2026-07-31 — C]**
`[CSA-31]`(d) works on desktop because "alongside the program" is a real place.
**On web there is no alongside** — the browser receives one bundle, and `user://`
lives in browser storage that a cache clear wipes. So a first-time or
cache-cleared web visitor lands on `[CSA-33]`'s empty library with no way to
reach a pack, which is a much worse first impression than on desktop.

Relevant existing state: `scripts/export-web.sh` and `serve-web-local.sh` exist;
`IMPL-ASYNC-PROGRESS-CANCEL-2026-07-24` already scopes **web-safe cooperative
chunking** for scan/import; `CampaignArchivePreflight` + `CampaignPackInstaller`
already install a zip and are tested.

- **A — Prompt on boot, then download.** `HTTPRequest` the pack zips, write to
  `user://`, hand to the existing installer.
  *For:* keeps the licence separation `[CSA-31]`(d) bought — the *program* still
  ships no art, and the demo packs remain separately-licensed artefacts fetched
  from elsewhere. Keeps initial page load small. The user chooses.
  *Against:* needs a CORS-permitted host and a live network; adds failure modes
  (offline, blocked, partial) on the very first screen; needs the async/chunked
  import that is planned but not built.
- **B — Pre-installed in the web build**, deletable and exportable.
  *For:* simplest possible first run — no network, no CORS, no progress UI. Reuses
  the seed-copy `res://`→`user://` mechanism the taxonomy already describes, and
  re-seeds naturally after a cache clear.
  *Against:* **it puts art back inside the program.** The demo packs' licence
  obligations re-attach to the web build — which is exactly what shipping
  "alongside" was designed to avoid, and `Campaign_Pack_0` has two formally
  CC-BY 4.0 sources. It also grows the initial download for every visitor,
  including returning ones.
- **C — B, but only demo packs whose art is entirely generated or first-party.**
  *For:* keeps first run trivial *and* the licence surface clean, because
  generated art (`[CSA-31]`) has no third-party source at all.
  *Against:* the demo is then visibly placeholder-grade unless first-party art
  exists by then.
- **RESOLVED 2026-07-30 — C** (owner). **At least one entirely
  first-party / generated / CC0 pack is packaged with the web version**, so a
  user who clicks a link can play a round or two with no download.
  - **Note the constraint is stricter than the law requires, deliberately.**
    CC-BY art *may* legally be redistributed inside the build — it would just
    attach an attribution obligation to the build. First-party / generated / CC0
    attaches **nothing**. So the rule keeps the web build's licence surface
    *empty* rather than merely *satisfiable*, which is the same standard
    `[CSA-31]`(d) set for desktop, reached by a different route.
  - **This is a real constraint on whichever pack gets built.** It cannot simply
    be a trimmed `Campaign_Pack_0` — that pack's verified sources include two
    formally CC-BY 4.0 entries (Puny Dungeon, octoshrimpy's miniworld +). The web
    demo pack needs its art to be generated (`[CSA-31]`), commissioned/owned, or
    CC0-only, and that should be a **validated property of the pack**, not a
    promise — it is exactly what `[CSA-6]`'s `rights_status` is for.
  - Desktop is unchanged: no pack ships. The two channels deliberately differ.

### [CSA-36] Web durability warnings **[RESOLVED 2026-07-30 — build them; details OPEN]**
**Owner:** the web version carries **extra warnings, disableable in settings**,
that you should export saves to ensure durability.

Grounded: `user://` on web is browser storage, which a cache clear, private
session, or storage-pressure eviction can wipe without warning. The persistence
design assumed a filesystem. `SettingsManager` already persists to
`user://settings.cfg` — **which is itself in the volatile store**, so a cache
clear takes the "don't warn me again" preference with it. That is arguably the
right failure direction (a cleared browser gets the warnings back), but it should
be a deliberate choice rather than an accident.

- **Open (a) — when do they fire?** First save; first *campaign completion*; on
  a schedule; before closing the tab (unreliable in browsers). *Rec:* on first
  save and then at meaningful milestones only. A warning shown every session
  trains people to dismiss it, which is worse than showing it twice well.
- **Open (b) — the warning must be actionable in one step.** Telling a player to
  export without a one-click export *at that moment* is worse than silence.
  *Rec:* the warning **is** the export affordance, not a pointer to a menu.
- **Open (c) — scope of "disableable".** One switch for all durability warnings,
  or per-warning? *Rec:* one, clearly labelled, and web-only so it does not
  clutter desktop settings.

### [CSA-37] Settings in exports and imports **[OPEN]**
**Owner note:** possibly include a settings file in mass exports/imports, or as
an individual export/import option.

Grounded: settings live in `user://settings.cfg` via `ConfigFile`
(`SettingsManager.gd:2,5`). Reading the actual keys, they **do not form one
portable set** — they split cleanly in two:

| Portable — means the same anywhere | Machine-specific — meaningless or harmful elsewhere |
|---|---|
| `master_volume`, `music_volume`, `sfx_volume` | `window_mode`, `resolution` |
| `combat_animations`, `movement_speed` | `input_mode` (`auto`/`gamepad`/`touch`/`mouse_keyboard`) |
| `phase_banner`, `level_up_screen`, `auto_end_turn` | `touch_controls` |
| `camera_edge_buffer`, `map_zoom_index`, `grid_dim` | *(borderline)* `menu_scale_index`, `hud_layout` — display-dependent |

- **The sharp risk:** importing a settings file wholesale from another machine can
  set a `resolution` the display cannot show, or an `input_mode` for hardware
  that is not present — turning a convenience feature into a soft-lock. On web,
  `window_mode`/`resolution` are largely meaningless anyway, since the browser
  owns the window.
- **The real value is on the other side:** accessibility and comfort settings are
  exactly what a player most wants to carry between machines — and `[CSA-27]`'s
  colourblind palette selection would live here too.
- **Rec: partition the file, do not choose between all-or-nothing.** Export both
  halves, import the portable half by default, and offer the machine-specific
  half explicitly (off by default, per-key visible). `hud_layout` deserves its
  own treatment — it is real user work worth preserving, but it is laid out
  against a specific screen.
- **Open:** does this belong to this register at all, or to the backup/export
  design (`campaign_backup_content_addressed_format_2026-07-25.md`, the manual
  export/import v1 primary)? *Rec:* **there** — it is a backup-scope question,
  not an art question. Recorded here only because it arose here; it should be
  handed over with a tracker row rather than solved in an art register.

---

## 4. Slice sketch (revised for the owner direction)

1. Sidecar schema + validator (`[CSA-3]`), headless-tested against fixtures.
2. Runtime slicer: sheet texture + sidecar → `SpriteFrames`, via `AtlasTexture`
   regions over one `ImageTexture` (no pixel copies).
3. `AssetResolver` semantic groups + fallback chains (`[CSA-9]`).
4. `art_asset@1` catalogue kind + source/licence wiring (`[CSA-4]`, `[CSA-6]`),
   including the non-suppressible attribution channel (`[CSA-13]`).
5. `Unit` → `AnimatedSprite2D`, resolving by `sprite_id` (`[CSA-8]`, `[IMP-2]`);
   verify faction tint and done-appearance survive.
6. Art facts + `used_by` relations in the semantic exporter (`[CSA-12]`,
   `[CSA-16]`) — **requires the `B3-REFERENCE-MODEL` foundation first.**
7. More Info visual region (`[CSA-15]`), landing with class migration step 2.
8. The authoring tool (`[CSA-11]`) on top of the pure core, covering every
   Tier-1 asset group (`[CSA-17]`), not unit sprites alone.
9. Palette-swap runtime + the manager's palette editing (`[CSA-18]`) — the
   project's first shader; prove `modulate` still composes before adopting it.
10. Static-rendering treatment of animated art in `tools/reference_builder/`.

**Zero-required-art consequence (`[CSA-10]`):** slices 1-5 must be built and
tested with **no art present**. The placeholder + repair-report path is the
primary path, so it is what the first tests exercise.

**Sequencing warning:** steps 6-7 are downstream of a track that has not started.
Steps 1-5 do not depend on it and should not wait for it.

## 5. Test notes

- Slicer: fixture sheet + sidecar yields expected animation names, frame counts,
  and regions; a bad `cell` fails loud.
- Fallbacks: a pack with a missing sheet loads, renders the placeholder, and
  reports one structured repair entry — it does not crash.
- Provenance: a `complete` pack whose art has no `source_ref` fails validation.
- **Attribution:** a player-facing export at profile `none` still surfaces
  required CC-BY attribution (`[CSA-13]`) — the regression test for a licence
  violation.
- **Asset boundary:** an author note referencing an out-of-pack or remote image
  fails validation (`[CSA-14]`).
