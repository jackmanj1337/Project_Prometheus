# Code Review Prep — v0.2.1 (2026-06-19)

**Last verified:** 2026-06-19

Handoff so the next session can start a focused code review without re-deriving scope.
Pairs with the full procedure in `AGENT/Review Procedures/00_Master_Review_Procedure.md`.

## Recommended scope

Review the **v0.2.0 return fixes + v0.2.1 features** — the changes since the shipped
v0.2.0 build (commit `9c394b6`), i.e. roughly:

```bash
git diff 9c394b6..HEAD -- 'scripts/**/*.gd' scenes/ data/ ':(exclude)scripts/tests/*'
```

~570 lines of non-test code across 30 files (plus their tests). This is the freshest
unreviewed surface and a sensible single review.

> **Note on branch divergence:** `code-review-followups-2026-06-17` is ~288 commits
> ahead of `main` (the whole v0.1.x→v0.2.x line lives here, unmerged). A full
> `main..HEAD` review is ~15k lines and not a single sitting. Keep the review scoped to
> the v0.2.x slice above unless a full-branch audit is explicitly wanted; merging the
> branch to `main` is a separate decision.

## How to run it

- Quick: `/code-review high` (current diff) — point it at the range above.
- Deep: `/code-review ultra` for the multi-agent cloud review of the branch.
- Or follow `AGENT/Review Procedures/00_Master_Review_Procedure.md` (5 pillars).

Baseline state: full suite green (48 suites) and `check_docs.py` 12/12 at HEAD.

## Changed surfaces and what to look at

**Camera / zoom (V020-01..03)**
- `scripts/core/CameraController.gd` — small-span edge-buffer reduction + `step_zoom`
  no-op on clamped index. Check the buffer math doesn't strand the cursor at tiny views.
- `scripts/ui/AttackPreview.gd` — defender-rect avoidance + above/below fallback. Check
  edge cases at 0.25× and near all four map edges.
- `scripts/core/MapCursor.gd` — live-zoom application path from Settings.

**State / objective / HUD (V020-04..06, 09)**
- `scripts/core/TurnManager.gd` — same-faction phase-refresh guard for F9 reruns. Check
  the guard resets correctly so a *legitimate* next phase still refreshes units.
- `scripts/resources/ObjectiveCondition.gd` — one-based display formatter; confirm
  evaluator/data logic stays zero-based.
- `scripts/ui/HUD.gd` — terrain More Info reflow on reset; `Support: <name>` line.

**Menu scale split (V020-16)**
- `scripts/ui/MenuScale.gd` (new helper) + wiring across ~10 menu/modal screens
  (`MainMenu`, `MapMenu`, `ItemMenu`, `WeaponMenu`, `ActionMenu`, `ModalScreen`,
  `LevelUpScreen`, `GameOverScreen`, `SettingsScreen`, `NewGameScreen`).
- `scripts/autoloads/SettingsManager.gd` — split of the old global UI-scale knob. Check
  migration/back-compat of any persisted `ui_scale` value and that the HUD no longer
  rides menu scale.

**Character sheet / More Info (V020-07/08/10/11/15)**
- `scripts/ui/UnitDetailsScreen.gd` — the biggest change (+202): class summary, CON/LoS
  rows, weapon stat block, `_inventory_description` keying, and the cursor/d-pad selector
  with the `▶` highlight (`_input`, `_move_selection`, `_refresh_highlight`,
  `_base_texts`). Watch: the highlight string-replace on the cached base text (single
  `[url=meta]` match assumption), and that `_base_texts`/`_entries` stay in sync across
  `open()`/`_close()`.
- `scripts/shared/StatBreakdown.gd` — `format_duration` combat-before-negative ordering;
  CON/LoS labels.
- `scripts/shared/MoreInfoContent.gd` — CON/LoS stat descriptions.

**Editor + validation (V020-12/14)**
- `scripts/ui/HudLayoutEditor.gd` — stylebox outlines (new per-refresh alloc), sample
  text font scaling. Low risk.
- `data/items/debuff_tonic.tres` + Map 950 cavalier inventory — validation-only item.
  Confirm it stays out of the default-roster/shop pipeline.

## Suggested focus / risk ranking

1. `UnitDetailsScreen.gd` selector + highlight (most new logic; string-based row match).
2. `TurnManager.gd` F9 phase-refresh guard (state machine; easy to over/under-guard).
3. `SettingsManager.gd` menu/HUD scale split (persistence/back-compat).
4. `AttackPreview.gd` defender avoidance (geometry edge cases).

## Not in scope this review

- The pre-v0.2.0 backlog already covered by prior reviews/session notes.
- The `main` merge decision and any full-branch audit.
