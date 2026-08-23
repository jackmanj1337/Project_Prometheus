---
Role: dated
---

# Pillar 4 — Tests, CI & Build Review (2026-06-14)

> **Pillar:** 4 — Tests, CI & Build
> **Procedure:** `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md`
> **Snapshot:** branch `awakening-compatability-refactor`, commit `e924bb4`
> **Working tree:** dirty — 3 untracked files (2 `.uid` sidecars, 1 `.png.import`)
> **Environment:** Godot 4.6.stable on PATH; **pytest NOT installed**
> **Previous report:** none — *this is the first Tests/CI/Build pillar report.* All
> deltas below are baselines, not comparisons.

**Pillar score: 6 / 10** (notable debt). The GDScript safety net is genuinely
strong — 39 suites, 870 assertions, all green, fast, headless-clean, with blocking
CI on both PR and push. But the score is held down by the *audit's own load-bearing
tooling being broken and ungated*: the `tools/` analyzer test suite is **red (3 of
12 failing)** and nothing in CI runs it; pytest is absent; and two committed scripts
have untracked `.uid` sidecars that break fresh clones.

---

## Baseline results (the rollup header quotes these)

| Gate | Command | Result | Runtime | Exit |
|------|---------|--------|---------|------|
| GDScript suite | `./run_tests.sh` | **PASS** — 39 suites, **870 assertions, 0 failed** | **1m05s** wall (8 workers) | 0 |
| Docs checks | `python3 AGENT/Docs/check_docs.py` | **PASS** — all 8 checks green | <1s | 0 |
| RNG guard | `bash scripts/ci/check_rng_usage.sh` | **PASS** — no unmarked engine-RNG | <1s | 0 |
| Analyzer suite | `python3 tools/godot-analyzer-mcp/tests/test_tools.py` | **FAIL — 3 of 12 failed** | 20.5s | **1** |
| Analyzer suite | `python3 -m pytest tools/godot-analyzer-mcp/tests/` | **could not run — `No module named pytest`** | — | — |

Per-suite assertion totals (all 0-failed): action_menu 22, attack_preview_position 11,
attack_preview_selector 14, boot 1, combat 47, data_layer 116, data_manager 20,
enemy_ai 21, game_map_scene 45, game_state 27, grid_manager 15, hud 21, level_up_screen 7,
map_950_promotion_validation 6, map_cursor 41, map_cursor_input 19, map_cursor_selection 9,
map_grid 35, map_menu 3, more_info_content 7, new_game_screen 7, pair_up_bonus_resolver 11,
pair_up_combat_context 6, pair_up_registry 17, promotion_screen 4, reclass_screen 4,
release_metadata 5, settings_manager 8, settings_screen 5, skill_item_handler 34,
snapshot_coverage 34, stat_breakdown 11, targeting 17, tile_actions 7, turn_manager 59,
unit_details_screen 13, unit_inventory_refs 2, unit_selection 10, unit_stats 57.

The GDScript baseline is **green and stable**; later pillars may cite it as ground
truth. The analyzer baseline is **red** — see High finding H1.

---

## Issues (severity-tagged)

### H1 — `tools/` analyzer test suite is RED (3/12) and gated by nothing — High
`python3 tools/godot-analyzer-mcp/tests/test_tools.py` exits **1** with 3 failures.
All three are **stale-test rot**, not parser bugs — the tool outputs are correct,
the *assertions* are out of date with the codebase:

1. `test_script_attached_to_no_scene` — asserts `SettingsScreen.gd` is attached to
   no scene, but it is now attached to `scenes/ui/SettingsScreen.tscn`
   (`test_tools.py:74`). Data changed under the test. `[CROSS → Pillar 3]`
2. `test_iron_sword_fields` — asserts field `weapon_type`, but
   `data/weapons/iron_sword.tres` now uses `combat_family`/`triangle_family`
   (`test_tools.py:105`). Schema changed under the test. `[CROSS → Pillar 3]`
3. `test_all_hud_paths_validate_ok` — asserts `"11 OK"`, but `HUD.gd` now has **21**
   `@onready` vars (all OK) (`test_tools.py:49`). Script grew under the test.

**Why it matters:** the master procedure says this tooling is *load-bearing* —
Pillar 3 uses the godot-analyzer MCP to judge scenes/data, so a real parser
regression here would silently corrupt that pillar's results. The suite *did* catch
real drift (its purpose), but because no gate runs it, the suite was allowed to go
red unnoticed. The parsers themselves verified fine in spot-checks (autoloads,
onready validation, resource fields, scene nodes all produce correct output).
Fix: refresh the 3 assertions to match current data, or make them
data-independent.

### H2 — pytest absent → analyzer is untested by any gate — High (PL#9)
The pillar doc §E states this absence is itself a finding. Neither pre-commit nor
either CI workflow installs pytest or runs the analyzer suite. The analyzer can
regress freely between audits. This is already listed as a PL#9 enforcement
candidate in the master doc §10. Fix: add `pytest` to the Docker image + CI, and a
CI step `python3 -m pytest tools/godot-analyzer-mcp/tests/` (after H1 is green).
The suite uses `unittest` so it also runs under stock `python3` — a zero-dependency
CI step (`python3 tools/.../test_tools.py`) is the cheapest immediate gate.

### H3 — Untracked `.uid` sidecars on committed scripts break fresh clones — High
Two tracked `.gd` files have **untracked** `.uid` sidecars:
- `scripts/resources/CampaignRules.gd.uid`
- `scripts/tests/test_unit_inventory_refs.gd.uid`

95 `.uid` files are tracked; these two are not. A fresh clone is missing them, so
Godot regenerates UIDs and any `uid://` reference to these scripts can break. This
is the exact PL#9 "`.uid` tracking" enforcement candidate (master §10) — currently
honor-system and already violated. `check_docs.py` does not check it.
`[CROSS → Pillar 5 / process]`

### M1 — pre-commit hook diverges from CI on the test entrypoint — Medium
CI runs `scripts/ci/run_headless_tests.sh` (which first does `godot --import` and
**asserts `.godot/global_script_class_cache.cfg` exists** before running tests). The
pre-commit hook calls `run_tests.sh` directly (`scripts/hooks/pre-commit:52`).
`run_tests.sh` warms the cache with `godot --headless --path . --quit` but does not
assert it. Result: a class-cache-resolution failure (a known headless footgun, see
MEMORY) would be caught by CI but *not* by the local hook — local and remote can
disagree. Low blast radius, but it is real hook↔CI drift. Fix: have the hook also
call `run_headless_tests.sh`, or fold the cache assertion into `run_tests.sh`.

### M2 — `tools/convert_inventory_tres.py` is a stale one-off migration script — Medium
This is a completed migration tool: it skips any `.tres` already containing
`SubResource` (line 25), and all unit `.tres` are already migrated, so it is now a
no-op on the repo. It has no tests, hardcodes `/workspace/data` (line 95) and the
ext_resource id `"2"` (line 10), and silently `SKIP`s on any unexpected shape with
no error exit. It is dead weight that a future reader could mistake for live
tooling. Fix: move to an `archive/`-style location or delete; if kept, add a header
noting the migration is complete.

### L1 — `config/name` vs export product name mismatch — Low
`project.godot` `config/name="Fire Emblem RPG"` but `export_presets.cfg` ships
`application/product_name="Project Prometheus"` and preset name
`"Project Prometheus v0.1.5.0"`. The shipped Windows binary and the in-editor
project name disagree. Cosmetic, but a playtester sees "Project Prometheus" while
the project file says "Fire Emblem RPG". `[CROSS → Pillar 2 naming]`

### L2 — root `tools/` Python not excluded from export — Low
`export_presets.cfg` `exclude_filter` lists `AGENT/**, scripts/tests/**,
scripts/tools/**` but not the repo-root `tools/` (the analyzer + convert script).
`export_filter="all_resources"` means non-resource `.py` files almost certainly are
not packed, so impact is likely nil — but the dev-only `tools/` tree is logically in
the same class as the excluded `scripts/tools/`. Add `tools/**` for parity/clarity.

### L3 — release-metadata test couples version parsing to a magic prefix — Low
`test_release_metadata.gd:19` derives the version via
`preset_name.trim_prefix("Project Prometheus v")`. If the product is ever renamed
(see L1), this silently parses the whole string as the version and the downstream
asserts fail with a confusing message. Minor brittleness; the test is otherwise an
excellent consistency guard.

---

## Coverage gap table (system → has meaningful test? → criticality)

| Subsystem / script | Test? | Criticality | Note |
|---|---|---|---|
| `core/TurnManager` (turn flow) | Yes (59) | Critical | Strong |
| `core/CombatResolver` (combat) | Yes (47) | Critical | Strong |
| save/load (GameState/DataManager/snapshot) | Yes (data_layer 116, snapshot 34, game_state 27) | Critical | Strong |
| promotion / reclass | Yes (promotion 4, reclass 4, map_950 6, +data) | Critical | Covered |
| pair-up (registry/resolver/context) | Yes (17/11/6) | Critical | Strong |
| `core/EnemyAI` | Yes (21) | High | Covered |
| `units/Unit`, unit stats | Yes (unit_stats 57) | High | Strong |
| `skills/SkillHandler`, `items/ItemHandler` | Yes (skill_item_handler 34) | High | Covered |
| `core/MapCursor*` (cursor/input/select/target) | Yes (41/19/9 + targeting 17) | High | Strong |
| `ui/HUD`, ActionMenu, AttackPreview | Yes | Medium | Covered |
| **`ui/WeaponMenu`** | **No** | Medium | Inventory-action flow; no direct test |
| **`ui/ItemMenu`** | **No** | Medium | Inventory-action flow; no direct test |
| **`ui/GameOverScreen`** | **No** | Medium | End-of-match path; untested |
| **`ui/ModalScreen`** (base) | **No** | Low | Base class; exercised indirectly via subclasses |
| **`shared/InputDisplay`** | **No** | Low | Input-glyph mapping; untested |
| **`resources/CampaignRules`** | **No** | Low | **Orphan: referenced by NO non-test script** — likely dead code `[CROSS → Pillar 1/3]` |
| `core/CameraController`, `HotseatController`, `ui/PhaseBanner` | Indirect | Low | Referenced by suites but not directly asserted |
| `scripts/ai/` directory | n/a | — | **Empty** — AI lives in `core/EnemyAI.gd` (tested) |

The critical-path coverage is good — no Critical path is uncovered. The gaps are
mid/low UI flow (WeaponMenu, ItemMenu, GameOverScreen) and one apparently-dead
resource class (CampaignRules).

**Headless-safety:** the suite passed cleanly headless (the real test), so no
in-editor-only assumptions surfaced. `run_tests.sh` isolates `HOME`/`XDG_DATA_HOME`
per worker, eliminating `user://` cross-suite races — a good defense against order
dependence. RNG determinism is guarded by `check_rng_usage.sh`.

---

## CI / hook findings

- **CI workflows** (`tests-pr.yml`, `tests-push.yml`): both run, in order,
  `check_docs.py` → `check_rng_usage.sh` → `run_headless_tests.sh`. **No
  `continue-on-error`** anywhere — gates are genuinely blocking. Godot pinned to
  4.6, matching the local environment and the Dockerfile. Good.
- **PR and push are near-duplicates** — the only difference is the `on:` trigger and
  the job name. Acceptable (a shared reusable workflow would de-dupe, but the
  duplication is small and low-risk). Low priority.
- **Pre-commit** (`scripts/hooks/pre-commit`): runs docs + RNG always, and the test
  suite only when non-doc files are staged (conservative safelist; unknown paths run
  tests). Matches CI's *checks* — but uses `run_tests.sh` instead of CI's
  `run_headless_tests.sh` (M1 drift).
- **Neither CI nor the hook runs the analyzer test suite** (H1/H2).

---

## PL#9 enforcement-gap list (rules stated but unchecked)

From AGENTS.md / master §10, cross-referenced against `check_docs.py` (which today
checks: banned paths, repo-relative paths, required headers, feature-index targets,
duplicate roadmap headings, stale Last-verified, prohibited status words, approved
status labels — 8 checks, all doc-prose-focused):

1. **`.uid` tracking** — every committed `.gd`/`.tres` with a `.uid` sidecar must
   have it tracked. **Currently violated (H3).** Scriptable in `check_docs.py` (or a
   git-aware pre-commit step). **Recommend landing this check** — it is both a
   ratified candidate and an active violation.
2. **`tools/` Python tested in CI** — add pytest (or a stock-`unittest` step) + CI
   job (H2).
3. **GDScript lint/format gate** — no `gdlint`/`gdformat` in hooks or CI; style is
   human-only. Candidate.
4. **Scene/resource integrity gate** — the analyzer already has
   `validate_onready_paths` + orphan detection; not wired into CI (Pillar 3's
   structural checks only run at audit time).
5. **Procedure-folder scan** — `AGENT/Review Procedures/**` is not in
   `check_docs.py`'s scan set, so its backtick paths are unvalidated.
6. **Version-consistency check** — `test_release_metadata.gd` covers
   preset↔label↔checklist↔setup-guide, but `config/name`↔product-name (L1) is
   unchecked.

`check_docs.py` is healthy for *doc prose* but does **zero** code/asset structural
enforcement — every PL#9 candidate above is honor-system.

---

## Build / export findings

- **`export_presets.cfg`**: valid, loads cleanly (the release-metadata test loads it
  every run). Single Windows Desktop preset, x86_64, embedded PCK, dev-only paths
  excluded. Matches the platform actually shipped (Windows `.exe` to playtesters).
- **Version consistency**: **good** — `0.1.5.0` agrees across preset name,
  `export_path`, `application/product_version`, the Main-Menu `VersionLabel`, the
  `playtest_checklist_v0.1.5.0.md`, and `environment_setup.md`, all *enforced* by
  `test_release_metadata.gd`. This is a model of how to keep version strings honest.
  Note: `project.godot` has **no `config/version` key** at all — version lives only
  in the export preset + code + docs (acceptable, but worth knowing).
- **`Dockerfile`**: pins Godot 4.6, installs the same headless runtime deps as CI,
  bakes export templates, disables the Claude auto-updater. Consistent with CI; no
  issues found. (Full image build not run — ~1.1 GB template download — verified by
  inspection + CI parity.)
- **`docker-compose.yml` + `Docker Instructions.md`**: the documented commands
  (`docker compose build` / `run --rm` / `down`) are standard and match the compose
  file. No stale commands spotted. `[CROSS → Pillar 2 for prose]`
- **`__pycache__`/`*.pyc` under `tools/`**: present on disk but **correctly
  gitignored and NOT tracked** (`tools/godot-analyzer-mcp/.gitignore` covers
  `__pycache__/`, `*.pyc`, `*.pyo`; `git check-ignore` confirms). Clean.

---

## Positive observations (≥3)

1. **Excellent GDScript safety net** — 870 assertions across 39 suites, all green,
   with every Critical path (turn flow, combat, save/load, promotion/reclass,
   pair-up) regression-tested. Glob-based discovery means new `test_*.gd` files are
   picked up automatically (no registry to forget).
2. **Fast, hermetic, parallel runner** — `run_tests.sh` cuts a ~4.5-min sequential
   run to ~65s via per-worker `HOME`/`XDG_DATA_HOME` isolation and a pre-warmed
   class cache, removing `user://` order-dependence. Output is re-sorted so logs
   read deterministically. Thoughtful engineering.
3. **Blocking CI on both PR and push**, with no `continue-on-error`, Godot pinned to
   4.6, and a fresh-clone bootstrap (`run_headless_tests.sh`) that asserts the class
   cache before running — directly defending against the known headless cache
   footgun.
4. **Version drift is machine-enforced** — `test_release_metadata.gd` ties the
   export preset, in-game label, playtest checklist, and setup guide together so a
   stale build number fails the suite. Exactly the PL#9 spirit.
5. **The analyzer test suite did its job** — all 3 failures are it *correctly*
   detecting that scene/data drifted; the rot is the missing gate, not the test.

---

## Prioritized action plan

| # | Action | Severity | Effort | Owner |
|---|--------|----------|--------|-------|
| 1 | Track the 2 untracked `.uid` sidecars; add a `.uid`-tracking check to `check_docs.py` (PL#9) | High | Low | P4/P5 |
| 2 | Refresh the 3 stale assertions in `test_tools.py` so the analyzer suite is green | High | Low | P4 |
| 3 | Add a CI step running the analyzer suite (`python3 .../test_tools.py`, no pytest needed) once green | High | Low | P4 |
| 4 | Align pre-commit with CI: call `run_headless_tests.sh` (or fold cache assertion into `run_tests.sh`) | Medium | Low | P4 |
| 5 | Add direct tests for WeaponMenu / ItemMenu / GameOverScreen flows | Medium | Med | P1/P4 |
| 6 | Resolve `CampaignRules.gd` (dead resource class) — wire up or delete | Medium | Low | P1/P3 |
| 7 | Archive/delete the completed `convert_inventory_tres.py` migration script | Medium | Low | P4 |
| 8 | Reconcile `config/name` vs export product name; consider a version/name check | Low | Low | P2/P4 |
| 9 | Add `tools/**` to export `exclude_filter` for parity | Low | Low | P4 |

---

## Delta vs previous review

**None — this is the first Tests, CI & Build pillar report.** No
`tests_ci_build_review_*.md` exists in `AGENT/Code Reviews/`. All findings above are
baselines; future runs compute deltas against this report. (Prior generic
`code_review_*.md` reports exist but are Pillar-1-scoped and not directly
comparable.)

---

## Procedure friction

- **§E pytest expectation vs reality** — the pillar doc treats "pytest absent" as
  *the* finding, but the analyzer suite is plain `unittest` and runs fine under stock
  `python3`. The bigger finding is that the suite is *red and ungated*; the missing
  pytest is secondary. The doc could note the `unittest` fallback gives a
  zero-dependency CI option, so "no pytest" need not block the gate.
- **Exit-code masking when piping** — running the analyzer suite through
  `| tail`/`| head` returns exit 0 (the pipe's last stage), hiding the real failure;
  I had to re-run capturing the unpiped exit code to confirm `FAILED (failures=3)`
  is exit 1. Worth a procedure note: capture exit codes *before* piping output.
- **No prior-report path supplied** — the dispatch brief has a `<prev ... path>`
  slot, but none exists for this pillar; I confirmed absence and proceeded. Fine,
  just flagging that the "compute deltas" step is a no-op on first run.
- **Severity rubric is shared, scoring rubric is per-pillar but undefined here** —
  master §6 says each pillar scores "using its own rubric (defined in its doc)," but
  the Pillar 4 doc gives no explicit 1–10 rubric beyond the master's generic
  9–10/7–8/5–6/3–4/1–2 bands. I scored against those generic bands.
- **Worktree guidance** — the doc says run in a worktree so tests can't disturb the
  main tree. I ran in the main tree (read-only intent, no edits to code/docs); the
  test runner uses isolated temp `HOME`s and a temp work dir, so it does not mutate
  tracked files. Noting the deviation for transparency.
