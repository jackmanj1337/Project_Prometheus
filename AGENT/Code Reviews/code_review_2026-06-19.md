# Code Review — v0.2.1 slice (2026-06-19)

**Scope:** the v0.2.0-return fixes + v0.2.1 features, `9c394b6..HEAD` — ~570 lines
of non-test code across 30 files (plus tests). Scoped per
`AGENT/Docs/code_review_prep_v0.2.1_2026-06-19.md`. Read in full: `UnitDetailsScreen`,
`TurnManager` (enemy-phase loop), `SettingsManager` + `SettingsScreen` + `MenuScale`
+ `ModalScreen` + sample wirings, `CameraController`, `AttackPreview`, `HUD`,
`StatBreakdown`, `ObjectiveCondition`, `MapCursor`, `HudLayoutEditor`, and the Map 950
validation data. The `main` merge decision and the deferred `Unit.gd` extraction
(2026-06-17 #5) stay out of scope.

Lens: correctness, clarity, robustness, extensibility, and the design choices behind
the menu/HUD scale split and the More Info selector.

## 1. Executive summary

**Overall: 9 / 10.** No correctness bugs in the high-logic areas. The two state
machines I worried about most — the `TurnManager` F9 phase-refresh guard and the
`StatBreakdown.format_duration` combat-ordering fix — are both correct, and the
menu/HUD scale split is a clean, non-compounding design. Findings are all
low-severity: a cosmetic duplicate-row case, a controller-reachability gap on the new
selector screen, and two nits. Full suite green (48 suites; `test_unit_details_screen`
18, `test_turn_manager` 63, `test_menu_scale` 115-assert) and `check_docs` 12/12.

## 2. Correctness — verified clean

- **`TurnManager` F9 guard (V020-04).** `phase_started` is a per-call local keyed by
  `faction_id`; `_begin_phase` (turn-modifier tick / fort heal / start-of-turn skills)
  runs once per faction per enemy phase, and the F9 `continue` reruns correctly skip it
  while still re-dispatching the swapped controller. A legitimate next round gets a fresh
  dict, so the next phase still refreshes. The `guard += 1` refund on rerun is matched to
  the `continue`s. Correct. Also a nice readability win: capturing `faction_id` once
  removes the repeated `active_faction()` calls the old body interleaved with mutation.
- **`StatBreakdown.format_duration`.** Matching `"combat"` *before* the `remaining < 0`
  fallback is the right fix — Pair Up's combat-scope `-1` now reads "this combat" instead
  of "—". The comment explains the ordering dependency, which is exactly where a future
  edit would reintroduce the bug.
- **`CameraController`.** `_effective_edge_buffer` caps the buffer to `(span-1)/2` and
  returns 0 at span ≤ 1, which removes the high-zoom jitter without stranding the cursor;
  `step_zoom` now no-ops on an unchanged clamped index. Both correct.
- **`AttackPreview._defender_avoid_rect`.** Appends the defender tile to the avoid list;
  geometry reuses the tested `_place_clear_of` pure helper. Correct.
- **`SettingsManager` scale split.** Load migration reads `menu_scale_index` and falls
  back to the old `ui_scale_index`, clamped — back-compat is preserved. `_apply_menu_scale`
  resets `content_scale_factor` to 1.0 so the HUD no longer rides the global scale. Good.
- **`MenuScale.apply_to`** sets `scale` absolutely (`Vector2.ONE * factor`), so repeated
  applications (\_ready + group call + ActionMenu's per-show) don't compound. Correct.
- **`ModalScreen` super-call fix.** `SettingsScreen._ready` now calls `super._ready()`;
  previously it overrode without it, so the base hide()+registration didn't run. This is a
  latent fix folded into the scale work — worth noting it changes SettingsScreen's ready path.

## 3. Findings (all low severity)

### #1 — Duplicate inventory rows highlight/select the first match (cosmetic)
`UnitDetailsScreen._format_inventory` keys each row `inventory:weapon:<id>`. A unit carrying
two of the same weapon produces two `_entries` with identical category+key and two identical
`[url=...]` tags. `_on_entry_clicked` (`break` on first match) and `_refresh_highlight`
(`find` returns first occurrence) both resolve to the *first* row, so clicking/▶-marking the
second duplicate lands the marker on the first. **Impact: cosmetic only** — duplicates share
identical More-Info content, so the side panel is still correct; only the ▶ position is off,
and F-cycling appears to "stick" for one extra press. Not worth a fix unless distinct-stack
metadata (uses/forge) later makes duplicates visually meaningful. If fixed, add a per-row
ordinal to the key (`...:<id>#<n>`).

### #2 — Arrow/d-pad keys can't reach the "View Support/Lead" button (controller gap)
`UnitDetailsScreen._input` consumes all four cursor directions to drive the More Info
highlight and calls `set_input_as_handled()`. Because game cursor keys are mirrored to the
`ui_*` actions, focus navigation never sees them, so a controller/d-pad user can't move focus
off `BtnBack` to the `BtnPair` ("View Support/Lead") button — only a mouse click or `Tab`
(`ui_focus_next`, not consumed) reaches it. On the very screen built to be keyboard/d-pad
friendly, the pair-jump affordance is effectively mouse-only on a gamepad. Suggest binding the
pair jump to a dedicated action (e.g. reuse the pair/confirm key) rather than relying on focus
nav, or letting one cursor axis fall through to focus.

### #3 — Two different green/red hex pairs for the same "boosted/lowered" meaning (clarity)
The inline stat row (`_stat_link`) colours boosted `#61c454` / lowered `#d85b5b`, while the
side-panel "Effective" line (`_format_mods_block`) uses the file constants `_BOOST_COLOR`
`#5fd35f` / `_DEBUFF_COLOR` `#ff6b6b`. Same semantic, two palettes a few lines apart. Fold
`_stat_link` onto the `_BOOST_COLOR`/`_DEBUFF_COLOR` constants for one source of truth.

### #4 — `HudLayoutEditor._refresh_handles` allocates a StyleBoxFlat per panel per refresh (nit)
`_make_frame_style(...)` builds a fresh `StyleBoxFlat` for every editable panel on every
`_refresh_handles`, which runs during drag. Editor-only and low panel count, so impact is
negligible, but two cached styleboxes (selected/unselected) swapped by reference would avoid
the per-frame churn.

## 4. Design choices — questioned, and where I landed

- **Menu scale via `Control.scale` instead of the old global `content_scale_factor`.** This is
  the right call: it cleanly separates "menu chrome size" from "HUD layout", which the global
  knob couldn't do, and the current modal Panels are offset-sized `PanelContainer`s so `size`
  is valid at apply time and the centered pivot lands correctly. **Caveat for the future:** a
  shrink/content-sized modal added later could have `size == 0` at the `_ready` apply and scale
  from a stale pivot, since modals don't re-apply on `open()`. Cheap insurance would be to call
  `_apply_menu_scale_from_settings()` in the modal `open()` path (ActionMenu already re-applies
  in `show_for`). Not needed for today's scenes.
- **One-based tile display (`ObjectiveCondition._format_display_tile`).** Display-only; the
  evaluator stays zero-based. Correct separation — just keep any future "go to objective tile"
  affordance reading the raw coord, not the formatted string.
- **`debuff_tonic.tres` as test content.** Confirmed it's referenced only by the Map 950
  validation roster (`unit_01_cavalier.tres`) and not by any shop/recruit/default-roster path;
  name + description are loudly marked `(TEST)` / `VALIDATION ITEM`. Stays out of the pipeline.

## 5. Verification

- `TEST_JOBS=8 ./run_tests.sh` — all 48 suites green.
- `check_docs.py` — 12/12 green.
- No findings rise to a behavior-doc change (DoD#1 N/A); these are hygiene/UX notes.
