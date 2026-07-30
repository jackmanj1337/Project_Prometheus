---
Type: register
Status: OPEN
Last verified: 2026-07-30
Register: CSA-1..29
---

# Campaign Sprite Authoring — Open Questions

**Started:** 2026-07-30
**Register:** `[CSA-1..29]`
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
> - `[CSA-10]` — **no animation is required at all**, overriding the "idle required"
>   recommendation. Zero required art, everywhere.
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

### [CSA-2] Does `[IMP-3]` (generated `.tres` under `data/`) survive? **[OPEN]**
- **A — Retire it for pack content.** Pack sprite data is PNG + JSON sidecar;
  `SpriteFrames` is built in memory, never serialised.
- **B — Keep `.tres` for the built-in default campaign, JSON for user packs.**
- **C — Keep `.tres` everywhere** (contradicts the taxonomy).
- **Rec: B.** Mirrors the already-ratified Tier-2 rule exactly — defaults MAY be
  authored as `.tres` in-editor then serialised at build; user packs are pure
  JSON. One rule for both tiers is easier to hold than two.

### [CSA-3] What is the sidecar schema? **[OPEN]**
The taxonomy fixes the shape (uniform grid `cell` + `columns`/`rows`, or an
explicit frame table; plus `frames`/`fps`/`loop`) but no field list exists.
- Needs: exact key names, required vs defaulted, `schema_version`, and whether
  the animation-name vocabulary (`idle_down`, `walk_left`, …) is **fixed** or an
  open registry.
- **Rec:** open registry for animation names, keyed by a **state × facing**
  convention, with the engine requiring only `idle_<facing>`. A closed set of
  animation names is precisely the closed-enum smell `AGENTS.md` forbids — and
  a pack with a 6-frame attack animation should not need an engine edit.

### [CSA-4] Does an art asset get a Tier-2 catalogue document? **[OPEN]**
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

### [CSA-5] Identity — is a sprite id a catalogue id? **[OPEN]**
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

### [CSA-6] Rights recording for imported art **[OPEN]**
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

### [CSA-7] Frame size, `SPRITE_SOURCE_SIZE`, and the 32/64 split **[OPEN]**
`TILE_SIZE = 64`; `[LEG-4.4]` scopes release 1 to 32px source art at 2×. So
`frame_size` defaulting to `TILE_SIZE` (per `[IMP-1]`) is **wrong for most real
sheets**, and per-pack art may not match the project tier at all.
- **Rec:** the sidecar's `cell` is authoritative per sheet; `SPRITE_SOURCE_SIZE`
  becomes a real constant for the *default* pack only; the renderer scales
  `cell` → `TILE_SIZE` at integer ratios and warns on a non-integer ratio.

### [CSA-8] Does `Unit` still switch to `AnimatedSprite2D`? **[OPEN]**
`[IMP-2]` says yes. Still the right call under a runtime slicer, but the
`SpriteFrames` now arrives from `AssetResolver` rather than a preloaded `.tres`.
- Unresolved: what a unit shows **before/while** art resolves, and what happens
  when a pack ships no sprite at all (the taxonomy's answer is "generated
  placeholder tile + validation warning" — confirm that applies to units).
- **Rec:** keep the switch; make the placeholder path the *normal* path, since
  most packs will ship no unit art.

### [CSA-9] Pack layout — `art/` vs the implemented `assets/` **[OPEN]**
The taxonomy specifies `art/{icons,portraits,sprites,tilesets,ui}`;
`CampaignPackInstaller` validates whatever is under `assets/`, grouped by file
extension.
- **Rec:** move the installer to the taxonomy's semantic groups, and register the
  fallback chains at the same time — extension-keyed groups cannot express a
  fallback ("missing portrait → silhouette") because the extension does not say
  what the asset *is*. Low cost now, and it is a format break later.

### [CSA-10] Animation scope — what set does v1 require? **[OPEN]**
`ui_ux_asset_inventory_and_reuse_2026-07-02.md` flags "are unit map sprites
static or idle/move-animated?" as **owned by the importer register** — and
`[IMP-1..6]` resolved the plumbing without ever answering it.
- **Rec:** v1 requires **idle only**; walk is optional and falls back to idle.
  It is the difference between a pack author needing 4 frames and 20, and the
  fallback is free once `[CSA-3]`'s registry exists.
- **Resolution: [RESOLVED 2026-07-30 — NONE required]** (owner override of the
  recommendation). **No animation is required at all.** A pack may ship a single
  still frame, or no unit art whatsoever, and must load and play.
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

### [CSA-12] Does an art asset get a reference-model entry, or only a pack-catalogue document? **[OPEN]**
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

### [CSA-13] Attribution must not ride on a suppressible provenance profile **[OPEN]**
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

### [CSA-14] What is an "approved image asset reference" in restricted Markdown? **[OPEN]**
The reference plan permits "approved image asset references" in author notes but
does not define approval, and lists "asset-boundary tests" as a required test.
- Needs: may a note reference **only** catalogued in-pack art ids (never a path,
  never a remote URL)? Does an animated asset in a note render as a still frame?
- **Rec:** catalogued in-pack ids only, resolved through `AssetResolver`, with a
  still frame in static renderings. It makes the asset boundary a *resolution*
  property rather than a string-validation problem, and `[CSA-4]`'s catalogue is
  what makes "is this id in this pack" answerable at all.

### [CSA-15] How does More Info render an animation? **[OPEN]**
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

### [CSA-16] What does "when, where, and how used" mean as data? **[OPEN — expanded 2026-07-30]**

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

### [CSA-18] Palette swaps, not generic tint **[OPEN]**
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

### [CSA-19] Where do palette-swap definitions live? **[OPEN]**
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

### [CSA-20] What exactly is a from→to entry? **[OPEN]**
- Needs: exact 8-bit RGBA or RGB-with-alpha-preserved; whether **alpha** may be
  remapped; first-match-wins vs last; whether a `to` may be fully transparent
  (an erase); and whether entries are ordered or a map.
- **Rec:** RGB match with alpha preserved, first-match-wins, ordered list,
  transparent `to` **disallowed** (an erase is a different feature and a likely
  authoring mistake). Exact 8-bit equality by default — see `[CSA-21]` for
  tolerance.

### [CSA-21] Tolerance, anti-aliasing and dithering **[OPEN]**
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

### [CSA-22] Composition with faction tint and done-appearance **[OPEN]**
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

### [CSA-23] When does the tint fallback fire? **[OPEN]**
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

### [CSA-24] Platform ceiling — how many swaps, how big? **[OPEN]**
- Needs: maximum entries per swap (the probe used 16, arbitrarily), uniform array
  limits under `gl_compatibility`, and cost of a per-fragment loop on low-end and
  web targets.
- **Rec:** fix a documented cap (16 or 32), validate against it at author time
  with a clear message, and measure on the web export before raising it. An
  unbounded from→to list is a per-pixel loop of unbounded length.

### [CSA-25] Does the manager bake variants? **[OPEN]**
The measured byte-exact round-trip means a CPU bake is trivially correct: apply
the remap to an `Image` and save a new PNG.
- **Rec: yes, as an author-side action, not a runtime path.** It is the escape
  hatch for web/perf (`[CSA-24]`), for art where remapping is unreliable
  (`[CSA-21]`), and for authors who would rather ship pixels than trust a shader.
  A baked variant is then just another sheet — but note it inherits the source's
  licence, so `[CSA-6]` provenance must carry across the bake.

### [CSA-26] What do swaps mean to the reference model and More Info? **[OPEN]**
Ties `[CSA-18]` back to `[CSA-12]`/`[CSA-15]`.
- Needs: does a `palette_swap` get a reference entry and facts; does More Info
  show the class's sprite in the **player's faction colours** or a neutral
  default; do generated Markdown/PDF renderings show variants at all?
- **Rec:** the swap gets an entry (it is catalogued content under `[CSA-19]`=A),
  More Info shows the **contextually correct** variant since it is a resolved
  live value, and static renderings show the unswapped sheet plus a list of
  available swaps. Do not generate one image per variant per asset in the docs.

### [CSA-27] Accessibility — is palette swap the colourblind seam? **[OPEN]**
Faction identification by colour is the classic colourblind failure in tactics
games, and this feature is the natural place to address it.
- **Rec:** confirm palette swaps may be **user-selected**, not only
  author-assigned, so a colourblind palette is a first-class use rather than a
  retrofit. It costs nothing now (it is the same lookup) and is expensive later.
  This also gives `[CSA-23]`'s "user setting forces fallback" trigger a purpose.

### [CSA-28] The shell / skin boundary — no default art through the manager **[OPEN]**
**Owner direction 2026-07-30:** *no* default art goes through the asset manager.
The **main menu, campaign library, and editor** have built-in graphics.
**Everything else is author-provided.** Ideally even the **settings screen**
re-skins per active campaign.

This draws a boundary the codebase does not currently have. Roughly, against the
existing `scripts/ui/` surfaces:

| Band | Surfaces (existing scripts) | Art source |
|---|---|---|
| **Shell** — exists before/without a campaign | `MainMenu`, `CampaignLibraryScreen`, `LoadGameScreen`, `NewGameScreen`, the editor | **Built-in only.** Never touched by the manager. |
| **Dual-context** | `SettingsScreen`, `DisplayConfirmDialog`, `ModalScreen`, `MenuScale` | Built-in when no campaign is active; **campaign-skinned when one is** |
| **In-campaign** | `HUD`, `CombatHUD`, `PrepScreen`, `MapMenu`, `ActionMenu`, `ItemMenu`, `WeaponMenu`, `UnitDetailsScreen`, `LevelUpScreen`, `PromotionScreen`, `ReclassScreen`, `MapResultsScreen`, `GameOverScreen`, `PhaseBanner`, `SelectionCursor`, `AttackPreview`, dialogue, map, units | **Author-provided**, with engine fallback |

**Open questions:**
- **(a) Is that banding right, and who owns the list?** It should be the same
  slot registry as `[CSA-16]`-16a-C, with each registered slot declaring its band
  — otherwise "which screens can a pack skin" becomes tribal knowledge.
- **(b) The settings screen is the hard case**, and the owner named it
  deliberately. It is reachable from the main menu (shell, no campaign) *and*
  mid-campaign. So a skinnable slot must resolve differently by context, and
  something must define the transition: does the skin apply the moment a campaign
  is selected, or only once a run is loaded? **Rec:** bind to *active pack
  identity*, which already exists at runtime (`active_package_identity`), and
  fall back to built-in whenever it is empty. That makes "no campaign active" an
  ordinary fallback rather than a special case.
- **(c) `[CSA-10]` interaction — this is not a contradiction, but it reads like
  one.** "Everything else is author-provided" and "no art is required" coexist
  only if *absence* falls back to **engine primitives** — generated placeholder
  tiles, the default `UiThemeDef`, plain text rows — **not** to a shipped default
  art set. State that explicitly, because the natural reading of "author-provided"
  is "the author must provide it", and that is exactly what `[CSA-10]` forbids.
- **(d) Direct conflict with the ratified taxonomy.** Its Tier-1a table says of
  icons: *"Ship the **default** set as one packed atlas; allow author single-file
  drop-ins"*, and §Tier-1a reserves the packed frame-table form for *"the shipped
  default set, where we own the build tool"*. Under this direction there is **no
  shipped default icon atlas** outside the shell. Either the taxonomy row is
  superseded, or "default set" means shell-only chrome. **This must be settled in
  the taxonomy document, not just here** — it is a ratified contract and leaving
  both statements standing guarantees someone builds the atlas.
- **(e) Does the built-in shell art live in the same catalogue at all?** *Rec:*
  no — shell art stays ordinary `res://` project assets with no manifest, no
  `art_asset@1` entry, no `AssetResolver` lookup. Keeping it out of the pack
  system is what makes "no default art through the manager" enforceable rather
  than aspirational.

### [CSA-29] What does an unskinned campaign look like? **[OPEN]**
Follows directly from `[CSA-28]`(c) plus `[CSA-10]`: the *expected* state for a
new or minimal pack is a campaign with almost no art.
- Needs: is the engine-primitive look a deliberate, presentable "wireframe"
  style, or an obviously-broken placeholder that pressures authors to supply art?
- **Rec: deliberate and presentable.** Zero-required-art is only credible if the
  zero-art result is shippable. It also makes the engine fallback the thing every
  test exercises by default, which is what `[CSA-10]`'s slice note already
  demands.

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
