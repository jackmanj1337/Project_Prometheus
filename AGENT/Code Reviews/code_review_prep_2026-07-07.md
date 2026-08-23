---
Role: dated
---

# Code Review Prep — v0.3.0 pre-build-cut (2026-07-07)

> **Purpose:** scope + focus for the next-session **Pillar 1 (Code)** review of
> `v0.3.0-features` *before the v0.3.0 build is cut*. This is a handoff, not the
> review itself — run the review from here using the procedure below.

## Snapshot / baseline

- **Procedure:** `AGENT/Review Procedures/01_Code_Pillar.md` (+ `00_Master_Review_Procedure.md`)
- **Previous code review:** `AGENT/Code Reviews/code_review_2026-07-05.md` — score **7/10**,
  snapshot `914dd025`.
- **Review baseline → HEAD:** `914dd025..HEAD` (HEAD `c4ac979` at prep time; re-snapshot at review time).
- **Delta since baseline:** **79 commits, 75 code files, +7,717 / −528**. This is the whole
  v0.3.0 code surface that has NOT been reviewed yet — Band 1 save/RNG/suspend plus the
  full B6-INPUT input layer.

Quick regen at review time:
```
git log --oneline 914dd025..HEAD | wc -l
git diff --stat 914dd025..HEAD -- 'scripts/**'
```

## Focus areas (new since baseline — highest risk first)

1. **Save / persistence — save-format critical, new.** `scripts/save/SaveCodec.gd`,
   `scripts/save/SaveData.gd`, `scripts/autoloads/SaveManager.gd`, plus `GameState`
   snapshot/restore. Look at: JSON round-trip fidelity (Vector2i, InventoryEntry, RNG
   ints-as-strings), old-save defaults/migration paths, structured reference validation,
   and the **suspend lifecycle** (write `user://saves/suspend.json` → Main Menu Continue →
   resume from `map_runtime` → delete on map result). A silent codec bug corrupts saves.
2. **Determinism — `scripts/autoloads/RngService.gd` + the CRR-2 resolver seam in
   `scripts/core/CombatResolver.gd`.** Look at: seed/mixer handling, event records,
   Retry snapshot `{map_seed, history_hash}`, and that no non-test GDScript uses unmarked
   engine RNG (the `check_rng_usage.sh` guard already runs, but confirm the seams).
3. **B6-INPUT input layer — the largest UI surface, and it carries a known soft spot.**
   `InputModeManager`, `MapCursorInput` (d-pad/stick/trigger decode), `SettingsManager`
   keybind profiles (`kbd`/`pad` slots + migration), `SelectionCursor` + its adoption in
   `AttackPreview` / `HUD` / `UnitDetailsScreen`, `InputDisplay` prompt swapping,
   `ModalScreen` focus/prompt subscribers. **Specifically scrutinize input exclusivity:**
   it still rests on `MapCursor._input_suppressed` + per-surface `set_input_as_handled()`
   + `HUD._higher_priority_more_info_visible()`, NOT a first-class input-context owner
   (the deferred "Rebuild C" — see
   `AGENT/Docs/design/shared_selector_extraction_design_2026-06-20.md` Component 2). Now
   that the d-pad binds BOTH `cursor_*` and `ui_*`, hunt for any double-input / leak path.
   Also sanity-check the brand-detection heuristic (`InputDisplay.detect_brand`) — it is
   cosmetic-only (SDL normalizes button position), so a wrong guess must never change
   behaviour.
4. **`CampaignRules` consolidation (B1-CST).** Live rules under `GameState.campaign_rules`;
   confirm no loose per-save rule fields remain and migration defaults are sound.
5. **Already partly reviewed (lighter pass):** MRD / threat overlay + `[MRD-1]` overlay
   precedence registry, the inline spawn seam, `GameOverScreen` victory sequencing.

## Previous-review open issues — confirm status

From `code_review_2026-07-05.md`:
- **High — inline placements lose authored `ai_profile`** (`GameMap.gd:206/209`) and
  **Medium — runtime placement resolver accepts a shape validation rejects**
  (`GameMap.gd:224`, `DataManager.gd:416`): both were addressed by the spawn-seam
  alignment in `34384ae` (session `2026-07-05e`, stronger `test_spawn_seam`). **Reviewer:
  confirm the fix holds against current HEAD.**
- **Medium — author-facing vocabularies still use closed code dispatch**
  (`DataManager.gd:13/15`): open-registry conversion is ongoing (`[EXT]` / open_registry
  checklist); likely still open — confirm whether it's in scope to fix pre-cut or defer.

## Not in scope for this review (tracked elsewhere, non-blocking for the cut)

- Live controller feel / display §1.6 — external validation, not code review
  (`VAL-V030-GAMEPAD`, `VAL-V023-DISPLAY`).
- "Rebuild C" input-context-owner refactor, touch-modal Map Menu semantics, character-sheet
  page-control review — deferred B6-INPUT items, flagged non-blocking.

## Output

Write findings to `AGENT/Code Reviews/code_review_2026-07-07.md` (or the review date),
following the pillar procedure's format (Score / Executive Summary / Issues with
Location / Positive Observations / Delta Vs Previous Review / Prioritized Action Plan).
Land any agreed fixes before cutting the v0.3.0 build.
