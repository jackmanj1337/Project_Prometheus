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

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated `INDEX.md` + `REGISTERS.md`, committed in the same change.
- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks green.
- `check_gdscript_style` — PASS, 257 tracked files (no GDScript touched).
- Godot suite skipped by the pre-commit hook: docs-only change.
- Container repo fast checks — 71 passed, 1 skipped; receipt
  `audit/check-receipts/Project_Prometheus_Container-fast.json`.

## Next

Owner walk of `[CSA-1..10]`. `[CSA-1]` (which tool is the author's) and
`[CSA-4]` (does art get a Tier-2 catalogue document) are the two that unblock
the rest — the other eight mostly follow from those answers. The three planned
`IMP-*` rows are gated on that walk in `coordination/tasks.json`;
`IMP-IMPORTER-CORE` is explicitly no longer "start here".
