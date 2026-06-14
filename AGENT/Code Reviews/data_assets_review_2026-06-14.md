# Pillar 3 — Scenes, Data & Assets Review — 2026-06-14

> **Pillar:** Scenes, Data & Assets (Pillar 3 of the full project audit)
> **Procedure:** `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md`
> **Snapshot:** branch `awakening-compatability-refactor`, commit `e924bb4`
> **Working tree:** dirty — 3 untracked files (see §F)
> **Baseline (from orchestrator §3):** `check_docs.py` = PASS, `run_tests.sh` = PASS
> **Previous review:** none — **this is the first Pillar 3 (data/assets) run.** No
> `data_assets_review_*.md` exists in `AGENT/Code Reviews/`, so all "Delta vs
> previous" entries below read "n/a (first run)".

**Pillar score: 8 / 10**

---

## 1. Executive summary

The content layer of this project is in **solid, well-disciplined shape**. Every
scene's `@onready`/`$path` reference resolves (validated across all 18 `.tscn`
scenes via `validate_onready_paths`), every scene's attached-script and sub-scene
`ext_resource` exists, all 12 registered autoloads point at real scripts, and the
entire `.tres` data set is internally consistent: IDs are unique per family,
cross-references (unit→class, unit→skill, unit→weapon/item, class→promotion,
class→skill_unlock, map→unit, registry→map/roster) all resolve, and every
`.tres`/tileset/`.import` `res://` path on disk is live. The import pipeline is
clean (no orphan `.import`, no source PNG missing an `.import`). `.tres` fields
match their current resource-class definitions with no leftover/removed fields.

The **single real defect** is `.uid` sidecar tracking drift: two `.gd` scripts are
committed but their `.gd.uid` sidecars are **untracked**, which breaks `uid://`
resolution on a fresh clone or CI checkout. The remaining items are housekeeping:
an empty top-level `code/` directory, an untracked `.import` for a tracked doc
screenshot, and a stub script (`CampaignRules.gd`) wired to nothing yet.

---

## 2. Spot-check / sample statement

- **Scene wiring (§A):** `validate_onready_paths` run on **all 18 scene-attached
  scripts** (every `.tscn` under `scenes/**`). Script + sub-scene `ext_resource`
  refs verified for all 18 `.tscn`. **Result: 0 broken paths.**
- **Autoloads (§E):** all **12** registered autoloads cross-checked
  (`get_autoloads` vs `project.godot`) — every script exists on disk.
- **Resource integrity (§C):** ID uniqueness checked across **all** of
  `data/classes` (24), `data/items` (7), `data/weapons` (11), `data/skills` (54).
  Cross-references validated exhaustively across **every** unit `.tres` in
  `data/roster/**` and `data/maps/**` (class_id, skills, earned_skills,
  reclass_options, inventory weapon_id/item_id), **every** class `.tres`
  (promotes_to/from, skill_unlocks), the map registry, and all tileset sources.
  Field-drift spot-checked via `get_resource_fields` on `mercenary.tres`,
  `iron_sword.tres`, `sol.tres`, `master_seal.tres`, `map_001_data.tres`,
  `map_001_c3_factions_data.tres`.
- **Import pipeline (§D):** all 18 `.import` (assets) + 4 doc `.png.import` and all
  source PNGs scanned for orphans / missing imports (null-delimited to handle
  spaced filenames).
- **`.uid` (§F):** full disk-vs-git scan — 97 `.gd` / 97 `.gd.uid` on disk, 95
  tracked; `.tres` carry inline UIDs, not sidecars.
- **Stray dirs (§G):** every top-level dir inspected; `code/` confirmed empty.

---

## 3. Issues

### High

**H1 — Two `.gd.uid` sidecars are untracked; `uid://` refs break on a fresh clone**
- **Location:** `scripts/resources/CampaignRules.gd.uid` (`uid://bpwgwcbue0kyu`),
  `scripts/tests/test_unit_inventory_refs.gd.uid` (`uid://cn1ng2cbilnvm`).
- **Problem:** Both owner `.gd` files **are** tracked in git, and both have a valid
  `uid://` sidecar on disk, but the sidecars are untracked (`git status`: `??`).
  The project's de-facto policy is "track every `.gd.uid`" — `.gitignore` has **no**
  `*.uid` rule and 95 of 97 sidecars are already committed. These two are
  accidental drift, not an intentional ignore. On a fresh clone / CI checkout the
  sidecars are absent, so any `uid://`-style reference to these scripts cannot
  resolve and Godot regenerates new UIDs, which can desync references.
- **Evidence:** `git ls-files | grep '\.gd\.uid$'` → 95; `find scripts -name
  '*.gd.uid'` → 97; the two-file delta is exactly these. Owners tracked:
  `git ls-files | grep -E 'CampaignRules.gd$|test_unit_inventory_refs.gd$'` → both.
  `.gitignore` / `.gitattributes` contain no `uid` rule.
- **Recommended fix:** `git add scripts/resources/CampaignRules.gd.uid
  scripts/tests/test_unit_inventory_refs.gd.uid` and commit alongside their owners.
  Then (PL#9) wire the `.uid`-tracking check from Master §10 into
  `AGENT/Docs/check_docs.py` so this can't recur. `[CROSS]` Pillar 4 — the test
  sidecar belongs to `scripts/tests/`; coordinate with the tests pillar that the
  fix lands in one commit. `[CROSS]` Pillar 2/process — the missing automated
  check is a Master §10 enforcement candidate.
- **Delta vs previous:** n/a (first run).

### Medium

**M1 — Empty top-level `code/` directory (stray/vestigial)**
- **Location:** `/workspace/code/` (empty; not tracked — git does not track empty
  dirs, so it exists only on this working tree).
- **Problem:** Vestigial directory with no files. The Master Procedure §2 already
  flags it ("`code/` [stray — Pillar 3]"). It serves no purpose and invites
  confusion about where code lives (everything is under `scripts/`).
- **Evidence:** `find code -type f` → empty; `ls -la code/` → only `.`/`..`.
- **Recommended fix:** Delete the directory. No live doc references it (grep clean).
  Because git doesn't track empty dirs there is nothing to commit — just remove it
  locally; optionally add a note so a future checkout doesn't recreate it.
- **Delta vs previous:** n/a (first run).

**M2 — `CampaignRules.gd` is a wired-to-nothing stub `[CROSS]`**
- **Location:** `scripts/resources/CampaignRules.gd` (a `class_name`/Resource
  script added by `7bceda4` "Stage 4.3 … CampaignRules stub").
- **Problem:** No `.tres` instantiates it, no script other than itself references
  it (`grep -rln CampaignRules scripts data project.godot` → only the file). It is
  an intentional forward-looking stub, but as content it is currently dead — and
  it is the owner of one of the untracked UIDs in H1.
- **Evidence:** grep above; it is correctly listed in
  `.godot/global_script_class_cache.cfg`.
- **Recommended fix:** Keep if Stage 4.x will consume it soon; otherwise track its
  status in the roadmap so it doesn't rot. `[CROSS]` Pillar 1 — dead-code /
  unused-`class_name` concern lives there; this entry is only the data-instantiation
  half (no `.tres` uses it).
- **Delta vs previous:** n/a (first run).

### Low

**L1 — `950MERC Promotion.png.import` untracked while the source PNG is tracked**
- **Location:** `AGENT/Docs/950MERC Promotion.png.import` (untracked) vs
  `AGENT/Docs/950MERC Promotion.png` (tracked).
- **Problem:** Inconsistent with its three sibling doc screenshots
  (`2026-06-09/10/10a broken combat preview.png.import`), whose `.import` files
  **are** tracked. A committed source asset without its `.import` will fail a clean
  reimport for anyone who opens the project in the Godot editor.
- **Evidence:** `git ls-files | grep -i 950MERC` → only the `.png`;
  `git ls-files | grep 'broken combat preview.png.import'` → all three tracked.
- **Recommended fix:** Either `git add "AGENT/Docs/950MERC Promotion.png.import"`
  for consistency, or (preferred for doc screenshots that don't need editor import)
  decide these `AGENT/Docs/*.png` are pure documentation and add a `.gitignore`
  rule for their `.import` — but then untrack the three siblings too, so the policy
  is consistent rather than drifting per-file.
- **Delta vs previous:** n/a (first run).

**L2 — Map registry description says "10 units" for a 12-unit test roster**
- **Location:** `data/maps/map_registry.json` line 38 (map_950 description: "10
  units") vs `data/roster/test/map_950_promotion_validation/` which holds **12**
  `unit_*.tres` files.
- **Problem:** Minor stale prose inside the data file; harmless (description is
  display text, not a count the engine uses) but inaccurate.
- **Evidence:** `ls data/roster/test/map_950_promotion_validation/*.tres | wc -l`
  → 12; registry text → "10 units".
- **Recommended fix:** Update the description to "12 units" (or make it generic).
- **Delta vs previous:** n/a (first run).

---

## 4. Positive observations

1. **Scene wiring is flawless.** All 18 scenes pass `validate_onready_paths` with
   zero broken `$`-paths, and every `ext_resource` script and nested `PackedScene`
   resolves. `GameMap.tscn` (the most complex, with 14 sub-scene instances and 10
   `@onready` node refs) is fully wired.
2. **Resource data integrity is excellent.** IDs are unique and match filenames
   across all four catalog families; every cross-reference resolves
   (unit→class/skill/weapon/item, class→promotion/skill_unlock, map→unit,
   registry→map_data/roster). Not one dangling `res://` path exists anywhere in
   `data/**` or `assets/**`.
3. **Import pipeline is clean and conventional.** Every source asset has its
   `.import`; no orphan `.import`; tilesets reference only existing sprite sources;
   `.gitattributes` correctly marks `*.png`/`*.import` binary and normalizes text
   to LF for cross-machine hook safety.
4. **No data↔code structural drift.** `.tres` fields match the current resource
   class definitions exactly (verified via `get_resource_fields`); fields left at
   their class default are correctly omitted from the `.tres` (idiomatic Godot),
   not stale leftovers.
5. **UID policy is coherent for the format era.** Scripts use `.gd.uid` sidecars
   (95/97 tracked) and Godot-4.4 `.tres` embed `uid="…"` inline (0 sidecars,
   correctly). The global class cache is tracked and lists the resource classes
   incl. the new `CampaignRules` — matching the project's documented headless-CI
   convention.

---

## 5. Prioritized action plan

| # | Action | Severity | Effort | Owner pillar |
|---|--------|----------|--------|--------------|
| 1 | Track the two untracked `.gd.uid` sidecars (H1) and commit with their owners | High | trivial | 3 (+4 coord) |
| 2 | Land the `.uid`-tracking check in `check_docs.py` (Master §10) so H1 can't recur | High | small | 4 / process |
| 3 | Delete the empty `code/` directory (M1) | Medium | trivial | 3 |
| 4 | Decide `CampaignRules.gd` fate — wire it or roadmap it (M2) | Medium | small | 1 / 3 |
| 5 | Make the `AGENT/Docs/*.png.import` tracking policy consistent (L1) | Low | trivial | 3 |
| 6 | Fix map_950 "10 units" → "12 units" in `map_registry.json` (L2) | Low | trivial | 3 |

---

## 6. Delta vs previous review

**None — this is the first Scenes/Data/Assets pillar review.** There is no prior
`AGENT/Code Reviews/data_assets_review_*.md` to diff against. Future runs should
compute new / fixed / regressed / still-open against this report.

---

## 7. Procedure friction

- **`get_resource_fields` truncates `Array`-valued fields.** For
  `map_001_data.tres` the tool returned `enemy_placements = [` (open bracket only),
  hiding the array contents — so I could not validate `unit_data_path` entries via
  the MCP alone and fell back to `grep` over the raw `.tres`. The tool is reliable
  for scalar/dict fields but not for inspecting arrays of dicts/sub-resources.
- **No MCP tool for orphan/cross-reference scanning.** §B (orphans, dangling refs)
  and §C (ID uniqueness, cross-reference resolution) have no analyzer primitive;
  all of it was hand-rolled with `find`/`grep`. A `find_orphan_resources` or
  `validate_resource_refs` MCP tool would make this pillar far faster and less
  error-prone. (Listed as a Master §10 enforcement candidate already.)
- **Spaced filenames break naive shell scans.** The `AGENT/Docs/*.png` screenshots
  have spaces; a first-pass `for f in $(find …)` produced false-positive "orphan
  import" noise. Had to re-run null-delimited (`find -print0 | while read -d ''`).
  Worth noting for anyone scripting future runs.
- **Scope ambiguity — `code/` is on disk but not in git.** §G says flag empty
  top-level dirs, but git does not track empty directories, so there is nothing to
  "commit a deletion" of — the fix is purely local. The procedure could clarify
  whether such untracked-empty dirs are in scope (I treated it as Medium per the
  Master §2 explicit call-out).
- **§F wording assumes sidecar UIDs for `.tres`.** In Godot 4.4 `.tres` embed UIDs
  inline rather than via `.tres.uid` sidecars, so "every resource that should carry
  a `.uid`" needs interpreting as "inline `uid=` header" for resources vs sidecar
  for scripts. The check still holds; the doc could note the two mechanisms.
