---
Role: topic
---

# Pillar 3 — Scenes, Data & Assets Review

> **Status:** Active — new pillar (no predecessor)
> **Last verified:** 2026-06-14
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`

Judges everything that is **content rather than logic**: scene graphs and their
node wiring, resource/data integrity (`.tres`, `data/`), the asset import
pipeline, and autoload *registration*. This is where Godot projects rot silently —
a renamed node, a stale `.import`, a `.tres` field pointing at a deleted resource —
none of which the GDScript compiler or a unit test necessarily catches.

## 1. Mandate & non-goals

**In scope:** `scenes/**.tscn`, **all `*.tres` resources wherever they live** —
`data/**`, `assets/**` (e.g. tilesets), and repo-root resources like
`default_bus_layout.tres` — `assets/**`, all `*.import` files, the `*.uid`
sidecar files, stray/empty top-level directories, and autoload registration in
`project.godot`.

**Out of scope:** the *logic* inside scripts (Pillar 1); whether tests pass
(Pillar 4); whether the GDD *describes* the data correctly (Pillar 2 — but a
data↔code structural mismatch is yours).

## 2. Tools

Lean on the godot-analyzer MCP — it reads scenes/resources structurally:
- `mcp__godot-analyzer__get_autoloads` — registered singletons.
- `mcp__godot-analyzer__find_scenes_with_script` — script↔scene mapping.
- `mcp__godot-analyzer__get_scene_nodes` — node tree of a scene.
- `mcp__godot-analyzer__validate_onready_paths` — `@onready`/`$path` resolution.
- `mcp__godot-analyzer__get_resource_fields` — fields of a `.tres`/resource class.

## 3. Procedure (exhaustive)

**A. Scene wiring**
- Run `validate_onready_paths` across scenes — every `@onready`/`get_node` path
  resolves to an existing node.
- Every `.tscn` references an existing script; every exported node ref is satisfied.
- No broken `ext_resource` / `PackedScene` references (deleted sub-scenes).

**B. Orphans & dangling references**
- Scripts with `class_name`/scene intent but attached to no scene (intentional
  helper vs. dead code — cross-check Pillar 1).
- Scenes attached to a missing/renamed script.
- `data/` resources referenced by nothing, and references to missing resources.

**C. Resource / data integrity**
- For each resource family (units, classes, weapons/items, skills, maps): IDs are
  unique; required fields populated; enum/typed fields in range; file paths inside
  resources exist.
- Data↔code structural drift: `.tres` fields match the current resource class
  definition (use `get_resource_fields`); no leftover fields from removed scripts.
- Cross-references resolve (a unit's class id exists; a skill's owner class exists;
  a map's spawn/objective references exist).

**D. Asset & import pipeline**
- Every imported asset (`.png`, audio, etc.) has its `.import`; no orphan `.import`
  whose source asset was deleted.
- No source asset committed without an import (will fail a clean reimport).
- Sprite/map-import conventions per `AGENT/Docs/fe_map_sprite_importer_guide.md`
  and `AGENT/Docs/map_authoring_guide.md` are followed.

**E. Autoload registration**
- `get_autoloads` vs. `project.godot`: every registered autoload's script exists
  and loads; ordering dependencies are sane (consumers after providers).

**F. `.uid` consistency (Godot 4)**
- Note the two UID mechanisms so this check isn't misapplied: a `.gd` script
  carries a **sidecar** `<name>.gd.uid` file, whereas a `.tres`/`.tscn` embeds its
  `uid="uid://…"` **inline** (no sidecar). So this check targets `.gd` sidecars;
  zero `.uid` files next to `.tres` is correct, not a gap.
- Every `.gd` that should carry a sidecar has one, and it is **tracked in git** —
  `git ls-files | grep '\.uid$'` vs. untracked `.uid` from `git status --porcelain`.
  Missing/untracked UIDs break references on a fresh clone or CI. Flag any `.gd`
  whose `.uid` is untracked (High — it bites a new machine), and any orphan `.uid`
  whose owner was deleted. (`check_docs.py` check 9 now gates untracked `.uid`.)
- Confirm the `.gitignore` policy for `.uid` is intentional and consistent (all in
  or all out), not accidental drift.

**G. Stray / empty directories & misplaced resources**
- Empty or vestigial top-level dirs — recommend deletion or document why they
  exist; flag any live doc still referencing them. Note git **cannot track empty
  dirs**, so an untracked-empty dir (e.g. the former `code/`) is a *local* cleanup
  (`rmdir`) plus a doc-reference check, not a committable change. (`check_docs.py`
  check 11 gates *named* top-level dirs against the master coverage map.)
- `.tres` resources sitting outside their expected home (root, `assets/`) — confirm
  they are referenced and intentional, not strays.

## 4. Spot-check requirements

State your sample (e.g. "validated onready paths on all 18 scenes; checked field
integrity on every `data/units/*.tres`, spot-checked 5 maps"). Cite the scene/
resource path and the offending field/node for every finding.

## 5. Output report

**Path:** `AGENT/Code Reviews/data_assets_review_YYYY-MM-DD.md`. Sections:
Executive summary + 1–10 score; Issues (severity-tagged, Location = scene/resource
path + node/field, Problem, Evidence, Recommended fix); ≥3 Positive observations;
Prioritized action plan; **Delta vs previous review**. Tag cross-pillar items
`[CROSS]` (e.g. an orphan script is also a Pillar 1 dead-code concern).

## 6. Sub-agent dispatch brief

> You are the **Scenes, Data & Assets** pillar of the full project audit. Follow
> `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md` exactly, at commit
> `<SHA>`. Use the godot-analyzer MCP tools for scene/resource structure. Document
> only. Compute deltas against `<prev data_assets_review path>`. Produce the report
> at `AGENT/Code Reviews/data_assets_review_<DATE>.md` and return its path, your
> 1–10 score, and your top 3 findings.
