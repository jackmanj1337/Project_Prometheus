---
Role: dated
---

# v0.3.0 Full-Scan — Scope Lock

## Why this scan exists

The `2026-07-07p` release-delta review
(`AGENT/Code Reviews/code_review_v0.3.0_release_delta_2026-07-07.md`, score 6/10)
was a *composed* pass: it leaned on the July 5 and July 7 reviews for prior
coverage and only spot-rechecked the prompt-selector changes. It did not freshly
read every changed line. This scan gives the full `ab81a21..b7bcfd2` production
delta a genuine line-by-line read, in small resumable passes, before the v0.3.0
build is cut.

## Boundary

- Base: `ab81a21` — v0.2.8 executable source.
- Head: `b7bcfd2` — pre-build v0.3.0 snapshot (matches the existing delta review
  so findings compose).
- Current HEAD `cef8e83` adds only the prior review + its session note — no
  production code lands after `b7bcfd2`, so the head is stable to review against.
- Delta size: ~8,326 insertions / ~575 deletions across 38 production `.gd`
  files (per `git diff --stat ab81a21 b7bcfd2 -- scripts/**/*.gd`, excluding
  `scripts/tests/`).

## How each focused pass works

For its file set:
1. `git diff ab81a21 b7bcfd2 -- <files>` for what changed, **and** read the
   file at `b7bcfd2` for full current context.
2. Review against `AGENT/Review Procedures/01_Code_Pillar.md`.
3. Cross-reference the matching `scripts/tests/` suite(s) to separate real gaps
   from coverage-shape gaps.
4. Write findings to the pass's file with severity, location (`file:line`),
   problem, why-it-matters, root cause, recommended fix — record which files were
   read at what commit.
5. Flip the `_TRACKER.md` row to DONE with the findings count + commit hash.
6. Commit the pass on its own.

## File → pass map (all 38, no overlaps)

**Pass 1 — Save/persistence codec (3)**
- `scripts/save/SaveData.gd`
- `scripts/save/SaveCodec.gd`
- `scripts/autoloads/SaveManager.gd`

**Pass 2 — Determinism: state capture + RNG + combat (7)**
- `scripts/autoloads/GameState.gd`
- `scripts/autoloads/RngService.gd`
- `scripts/core/CombatResolver.gd`
- `scripts/skills/SkillHandler.gd`
- `scripts/core/EnemyAI.gd`
- `scripts/resources/CampaignRules.gd`
- `scripts/resources/UnitData.gd`

**Pass 3 — Input model & settings persistence (3)**
- `scripts/autoloads/InputModeManager.gd`
- `scripts/autoloads/SettingsManager.gd`
- `scripts/core/MapCursorInput.gd`

**Pass 4 — Input display & rebind UI (2)**
- `scripts/ui/SettingsScreen.gd`
- `scripts/shared/InputDisplay.gd`

**Pass 5 — Map/turn core (5)**
- `scripts/core/MapCursor.gd`
- `scripts/core/MapCursorTargeting.gd`
- `scripts/core/GridManager.gd`
- `scripts/core/GameMap.gd`
- `scripts/core/TurnManager.gd`

**Pass 6 — UI screens, selection & misc data (18)**
- `scripts/ui/SelectionCursor.gd`
- `scripts/ui/ModalScreen.gd`
- `scripts/ui/UnitDetailsScreen.gd`
- `scripts/ui/AttackPreview.gd`
- `scripts/ui/HUD.gd`
- `scripts/ui/LevelUpScreen.gd`
- `scripts/ui/MenuScale.gd`
- `scripts/ui/MainMenu.gd`
- `scripts/ui/MapMenu.gd`
- `scripts/ui/NewGameScreen.gd`
- `scripts/ui/GameOverScreen.gd`
- `scripts/ui/ActionMenu.gd`
- `scripts/autoloads/DataManager.gd`
- `scripts/autoloads/PairUpRegistry.gd`
- `scripts/resources/MapData.gd`
- `scripts/units/Unit.gd`
- `scripts/tools/generate_placeholder_assets.gd`
- `scripts/tools/generate_tilesets.gd`

**Pass 7 — General/integration & rollup**: reads across passes 1–6, hunts
cross-cutting/seam issues, and writes the consolidated
`code_review_v0.3.0_full_scan_2026-07-XX.md` with an updated score and a 38/38
coverage assertion.

## Carried findings to re-confirm in-context (from the 6/10 delta review)

- **High** — fresh maps never call `RngService.start_map()` → Pass 2 (+ Pass 5 startup order).
- **Medium** — Settings Input Mode changes don't refresh prompts immediately → Pass 3.
- **Medium** — rebind UI omits `more_info`, `peek_range`, `zoom_in/out/reset` → Pass 4.
- **Medium** — author-facing closed dispatch lists (registry debt) → Pass 6 (`DataManager`) + Pass 2/5 seams.
