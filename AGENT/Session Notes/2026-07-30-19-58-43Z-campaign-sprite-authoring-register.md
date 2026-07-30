# Session Note - 2026-07-30-19-58-43Z-campaign-sprite-authoring-register

## Branch context

- Branch: `agent/from-integration/campaign-sprite-authoring-register`
- Base branch: `agent/integration`
- Base SHA: `a8a558bc19cb9402804b2b369fa8355b4e3f802f`
- Coordination Work ID: `DECISION-CSA-CAMPAIGN-SPRITE-AUTHORING-2026-07-30`

## What was done

Asked to walk the sprite-importer plans and explain how campaign authors would
turn PNG sheets into animations. The walk found there is no such path, and that
two ratified contracts describe different tools.

- **No importer exists.** `IMP-1..6` is a decided contract with nothing built;
  the guide is a tutorial for a version that was never written and is superseded
  on three points (output shape, folder layout, frame-size/scan behaviour).
- **`[IMP-1..6]` and the campaign asset taxonomy conflict.** `IMP` decided an
  editor-time, `res://`, `.tres`-emitting tool; the taxonomy (`[ICO-5/6]`,
  2026-07-01/02) requires a runtime, `user://`, raw-loaded path emitting PNG +
  JSON sidecar, and says an author with a clean sheet may skip the tool
  entirely. Verified by grep that the `IMP` decision record and register make
  **no reference** to the taxonomy, `AssetResolver`, sidecars, or `user://`.
- **`AssetResolver` is already built** (`scripts/assets/AssetResolver.gd`) and
  loads whole textures only — no slicer, no sidecar reader, no `SpriteFrames`
  anywhere in `scripts/`. The `IMP` decision was taken as though this seam did
  not exist.
- **The load-bearing gap is provenance.** `class_schema_trial_v1` requires every
  art asset to resolve to a file catalogued in-pack, and `[LEG-4]` makes rights
  status mandatory — but `schema_registry.json` has no art-asset kind, so art
  cannot carry `source_refs` and therefore cannot carry provenance at all.
- Opened `[CSA-1..10]` recording all of the above with options and a
  recommendation per question, plus a slice sketch and test notes.

Also corrected, in the container repo (`Project_Prometheus_Container`
`agent/from-staging-area/sprite-importer-authoring`, commit `13cfee8`): the
shared `data-authoring` block told pack authors to mirror the superseded
`assets/raw/` → `assets/generated/<unit>/` layout in the present tense, as
though the importer shipped. That block is propagated into the workspace
`AGENTS.md`, so it was the guidance an author or agent would actually read.

## Commits claimed

- `6774ce1574b34919b5d23058f92d32ea2e6fbb49` — Open CSA register: campaign sprite authoring open questions
- `f6711addb75f8531361cc46a9130749043079cb7` — Record owner direction on CSA and open the reference-model seam
- `b695ce11ff186b68a943a48a0bd0d067744d9d96` — Record pack self-containment in AGENTS.md and correct the CSA-5 collision claim
- `3c61b02c28e6631d2fda1957acd1c98d983735e6` — Record CSA overrides: zero required art, asset-manager scope, palette swaps
- `156de25947bdc52c0bd4665f581dd7b7c1a50a75` — Add CSA-19..27: palette swap design, measured Godot facts
- `ff41abf571a2dad70493c1e252306e233ca12c64` — Expand CSA-16 into where/when/how; add CSA-28..29 shell-skin boundary
- `2dbf5f54b4ee82b050e9f72b32d0f93696af303e` — Correct CSA-10 framing; add CSA-30 fork-first and CSA-31 template art

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated `INDEX.md` + `REGISTERS.md`, committed in the same change.
- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks green.
- `check_gdscript_style` — PASS, 257 tracked files (no GDScript touched).
- Godot suite skipped by the pre-commit hook: docs-only change.
- Container repo fast checks — 71 passed, 1 skipped; receipt
  `audit/check-receipts/Project_Prometheus_Container-fast.json`.

## Owner direction (same session)

Authors need a tool that imports art, defines animation cells, defines licence
and source, and defines when/where/how assets are used in a campaign — using the
standardized documentation conventions, with art and its information reachable
by the semantic reference engine for both the generated Markdown reference docs
and the in-game More Info page (e.g. a class's sprite animations on its More
Info page and character sheet).

That resolved `[CSA-1]`, `[CSA-4]`, `[CSA-5]`, `[CSA-6]` and opened
`[CSA-11..16]` against `B3-REFERENCE-MODEL`
(`AGENT/Docs/plans/generated_reference_model_implementation_plan_2026-07-30.md`,
approved architecture, implementation not started). That plan fixes namespaced
ids, facts-not-sentences, provenance profiles and the two-region More Info — but
its first fact vocabulary contains **no visual or art fact**, so the requested
More Info sprite display has nothing to carry it, and "approved image asset
references" in author notes is permitted without approval being defined.

`[CSA-13]` is the sharpest finding: the model's `none` provenance profile is
"player-facing content without provenance blocks". Carrying licence data as
provenance therefore strips attribution from exactly the player-facing surface
where CC-BY requires it, and two sources already in `Campaign_Pack_0` are
formally CC-BY 4.0. Attribution needs a separate non-suppressing channel,
mirroring the `presentation_name_collision` precedent.

## Correction worth carrying forward

I claimed in a `[CSA-5]` draft that two packs shipping `knight_sprite` would be
an `identity_collision` hard error. **Wrong.** `[ICO-1..6]` settled in June that
one pack is active at a time and a pack is completely self-contained, so two
packs are never loaded together. `CampaignPackInstaller` rejects only a
re-install of the same id *and* version and never cross-checks ids across
installed packs; the runtime carries a single `active_package_identity`.

The rule is now in this repo's `AGENTS.md` architecture section (and the shared
`data-authoring` block) because it keeps being forgotten. The likely cause is
`class_schema_trial_v1`'s "globally unique … across all packs considered
together during installation or load", which reads as though the installed
library is checked as a set — worth a clarifying edit by whoever owns
`CLASS-SCHEMA-TRIAL-V1-2026-07-29`.

`[CSA-11]` also resolved: the art authoring tool lives in **our campaign
editor**, not the general Godot editor. That supersedes
`IMP-EDITOR-PLUGIN-2026-07-20` rather than gating it.

## Owner overrides (same session; more expected)

- `[CSA-10]` — **no required animations at all**, overriding "idle required".
  Required art drops to zero everywhere, so the placeholder + validation-warning
  path is the *primary* path and slices 1-5 must be built and tested with no art
  present. Also settles the "which surfaces are required art?" question in
  `ui_ux_asset_inventory_and_reuse_2026-07-02.md`.
- `[CSA-17]` — the tool is an **asset manager**: portraits, UI elements, map
  tiles, backgrounds, dialogue art, future combat-scene animation. UI chrome
  needs 9-slice margins, not animation frames, so the sidecar is not one shape.
  Dialogue and combat-scene art have no consuming system yet — admit the kinds,
  defer the shapes.
- `[CSA-18]` — **palette swaps**, not generic tint. The project has **zero
  shaders** today, so this introduces the first. Faction identity currently *is*
  the modulate colour (`Unit.gd:78-93`) and `set_done_appearance()` darkens it
  (`Unit.gd:605-608`), so a palette swap taking over faction identity leaves
  done-appearance with nothing to darken. "Tintable" is a reuse lever on 9 rows
  of the asset inventory, defined as greyscale + `modulate`; that math changes.

## Palette swaps — measured, not read (Godot 4.6.3)

Owner design: a swap is a **property**; swaps are a **from→to list** held in the
assets; **a sprite lists which swaps it supports**; **each swap carries a tinting
fallback**. The fallback is the load-bearing part — it means palette swap can
never harden into a requirement, matching the `[CSA-10]` zero-required-art stance.

Probed headlessly (temporary scripts, not committed — re-measure after an engine
bump):

- The project renders **`gl_compatibility`** on desktop *and* mobile
  (`project.godot:195-196`), so the shader must fit the Compatibility feature
  set, which is also what a web export uses.
- Canvas texture filter already defaults to **0 / Nearest**
  (`project.godot:197`) — exact colour matching is not undermined by filtering.
- **PNG round-trip via `save_png`/`load` is byte-exact** in `FORMAT_RGBA8`,
  including a fully transparent pixel and a ±1 near-miss. Exact from→to matching
  is viable on raw-loaded `user://` art, and a CPU bake is trivially correct.
- A remap `canvas_item` shader with `uniform vec4 from_colors[16]` and a
  `swap_count` loop **parses**, and the parser genuinely validates — a bogus
  built-in fails with "Unknown identifier".
- **`MODULATE` is a distinct built-in.** This is the composition trap: a fragment
  shader that writes `COLOR = src` can silently drop faction tint *and*
  done-darkening.

**Not proven:** headless uses the dummy rasterizer, so this is parsing, not GPU
compilation or visual output. Needs the Windows-host visual pass — the same gate
`[IMP-2]` set for the `Sprite2D` → `AnimatedSprite2D` switch.

## Shell / skin boundary (`[CSA-28..29]`, and why `[CSA-16]` grew)

Owner: **no default art goes through the asset manager.** Main menu, campaign
library and editor keep built-in graphics; everything else is author-provided,
ideally including a settings screen that re-skins per active campaign.

That promotes `[CSA-16]` from a nice-to-have to the mechanism the entire skin
runs on, so it was expanded into **where / when / how**:

- **Where** is the important one. The only binding mechanism that exists today is
  a content entity naming an asset (`ClassData.sprite_id`) — and there is no
  settings-screen entity, no prep-background entity, no dialogue-frame entity to
  name one. UI skinning therefore needs a **named-slot registry**, with
  `sprite_id` kept where a content entity genuinely owns the art.
- **When** is binding scope: whole-campaign and per-node are static author data;
  per-runtime-state needs predicates and should be deferred.
- **How** is presentation parameters, which belong on the **binding**, not the
  asset — the same background may anchor differently in two slots.

Two flags from `[CSA-28]`:

- The **settings screen** is the hard case the owner named: reachable both with
  and without an active campaign. Recommend binding to the existing
  `active_package_identity` so "no campaign active" is an ordinary fallback.
- **Direct conflict with the ratified taxonomy**, whose Tier-1a table says to
  *"ship the default set as one packed atlas"* for icons. Under this direction
  there is no shipped default icon atlas outside the shell. That row must be
  settled in `campaign_asset_taxonomy_and_format_2026-07-01.md` itself, or
  someone will build the atlas.

`[CSA-29]` asks what an unskinned campaign should look like, since under
`[CSA-10]` that is the *expected* state for a new pack rather than an error.

## Next

Owner answers on `[CSA-2/3/7/8/9/12/13/14/15]`, the `[CSA-16]` sub-questions,
the `[CSA-17]` sub-questions, and `[CSA-19..29]`. More overrides expected — the
register is open and growing, not closed. `[CSA-13]` should be settled first — it is a
licence-correctness defect, not a preference. Slices 1-5 of the revised sketch
(sidecar, slicer, resolver groups, `art_asset@1`, `Unit` switch) do **not**
depend on `B3-REFERENCE-MODEL` and should not wait for it; slices 6-7 do. The
three planned `IMP-*` rows remain gated in `coordination/tasks.json`, and
`IMP-IMPORTER-CORE` is explicitly no longer "start here".
