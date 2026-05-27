# Project Prometheus

Grid-based tactical RPG prototype in Godot 4 / GDScript.

The project is data-driven: classes, weapons, items, skills, rosters, and maps are
authored as resources under `data/`, while the runtime systems live under `scripts/`.

## First Read

For onboarding, start here:

1. `AGENT/GDD/GDD_00_Overview.md`
2. `AGENT/GDD/GDD_01_Architecture.md`
3. `AGENT/GDD/GDD_02_Core_Mechanics.md`
4. `AGENT/GDD/GDD_03_Units_Classes.md`
5. `AGENT/GDD/GDD_06_Maps_Objectives.md`
6. `AGENT/GDD/GDD_07_UI_UX.md`

Use `AGENT/GDD/GDD_10_Roadmap.md` and `AGENT/GDD/GDD_10a_Overview.md` for planned /
deferred work, not for the current runtime contract.

For centralized practical workflows, use:

- `AGENT/Docs/map_authoring_guide.md`
- `AGENT/Docs/testing_guide.md`
- `AGENT/Docs/campaign_rules.md`

## Current Runtime Highlights

- Faction-driven phase system with authored `turn_order`, alliance groups, and hotseat-capable controllers
- Objective-condition system supporting Rout, Seize, Defeat Boss, Escape, and Survive / Defend flows
- Promotion and Second Seal reclassing
- Pair Up pass 1 (`Pair Up`, `Swap`, `Separate`)
- More Info / character-sheet UI surfaces
- Map registry-backed New Game selector

## Running Tests

`bash run_tests.sh`

Runs the headless GDScript suite in the current checkout.

`bash scripts/ci/run_headless_tests.sh`

Use this in a fresh clone or CI-style environment. It bootstraps Godot's
import/class cache first, then runs the same suite.

For validation-map roles, manual regression flow, and when to add automated
coverage, start with `AGENT/Docs/testing_guide.md`.

## Project Structure

- `scripts/autoloads/` — global state and registries (`GameState`, `DataManager`, `SettingsManager`, etc.)
- `scripts/core/` — battle-map runtime systems (`GameMap`, `TurnManager`, `MapCursor`, `EnemyAI`)
- `scripts/ui/` — in-map and front-end UI scripts
- `scripts/units/` — `Unit.gd`
- `scripts/skills/` and `scripts/items/` — dispatchers for skill and item effects
- `scripts/tests/` — headless test suites
- `data/` — authored gameplay resources
- `scenes/` — Godot scenes
- `AGENT/GDD/` — current design / implementation reference
- `AGENT/Session Notes/` — per-session record of what changed

## Important Data Conventions

- Content directories that must work in exported builds use `resource_manifest.json`.
- Maps exposed in the New Game selector are registered in `data/maps/map_registry.json`.
- The default player roster loads from `data/roster/default/`.
- Validation maps may use fixed test rosters from `data/roster/test/`.

If you are adding content instead of changing engine logic, use
`AGENT/Docs/map_authoring_guide.md` before touching `map_registry.json` or new
runtime-scanned folders.

## GitHub Actions

This repo includes:

- `.github/workflows/tests-pr.yml`
- `.github/workflows/tests-push.yml`

They install Godot `4.6` and run `bash scripts/ci/run_headless_tests.sh`.

For branch protection, require the `godot-tests-pr` check on `main`.
