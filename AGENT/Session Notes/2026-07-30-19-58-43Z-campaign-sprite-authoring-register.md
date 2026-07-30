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

## Next

Owner answers on `[CSA-11..16]`. `[CSA-13]` should be settled first — it is a
licence-correctness defect, not a preference. Slices 1-5 of the revised sketch
(sidecar, slicer, resolver groups, `art_asset@1`, `Unit` switch) do **not**
depend on `B3-REFERENCE-MODEL` and should not wait for it; slices 6-7 do. The
three planned `IMP-*` rows remain gated in `coordination/tasks.json`, and
`IMP-IMPORTER-CORE` is explicitly no longer "start here".
