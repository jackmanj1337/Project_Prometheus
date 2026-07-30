---
Type: register
Status: OPEN
Last verified: 2026-07-30
Register: CSA-1..16
---

# Campaign Sprite Authoring — Open Questions

**Started:** 2026-07-30
**Register:** `[CSA-1..10]`
**Question:** what has to be true for a **campaign author** — not a
`Project_Prometheus` developer — to turn a PNG sheet into working unit
animations inside their own pack?

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

### [CSA-16] What does "when, where, and how used" mean as data? **[OPEN]**
The fourth owner capability is the least specified. Candidate meanings, probably
several at once: which class/unit/tile an asset is bound to; which campaign
nodes or maps it appears in; which animation plays in which state; and
conditional swaps (promoted class, weather, faction).
- **Rec:** land the first two only (`used_by` relations, `[CSA-12]`=A) and treat
  state-driven and conditional selection as a later slice, gated behind the
  animation-name registry from `[CSA-3]`. Conditional visual swaps are an open
  registry problem and will re-open `[EXT]`-shaped questions; do not let them
  block idle sprites on a character sheet.

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
8. The authoring tool (`[CSA-11]`) on top of the pure core.
9. Static-rendering treatment of animated art in `tools/reference_builder/`.

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
