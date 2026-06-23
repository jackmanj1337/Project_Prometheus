> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Combat Preview Render Fix Plan - 2026-06-10

## Status - Implemented for v0.1.4

The forecast-row and panel-geometry fixes are implemented and covered by
`test_attack_preview_selector.gd`. The v0.1.4 playtest checklist retains the
manual `1280x720` and narrow-viewport checks because automated geometry tests
cannot judge final readability.

## Evidence

Latest screenshot:

- `AGENT/Docs/2026-06-10 broken combat preview.png`
- The game client is approximately `1280x720`.
- The preview panel is compact and positioned on-screen.
- The `More Info` title and hint render normally.
- Both attacker and defender forecast columns are completely blank.

The older `2026-06-09` screenshot showed a different failure: the preview grew
nearly to the full viewport height. Commit `e504784` fixed that outer-panel
growth, but introduced the blank forecast regression.

## Diagnosis

### Primary cause - high confidence

Commit `e504784` changed every attacker and defender `RichTextLabel` in
`scenes/ui/AttackPreview.tscn` from `fit_content = true` to
`fit_content = false`.

Those labels are children of `VBoxContainer` nodes and have:

- no vertical custom minimum size
- no vertical expand flag
- `fit_content = false`

They therefore contribute a zero minimum height and the container allocates
them no visible vertical space. The dynamic BBCode strings are still assigned
by `AttackPreview.show_preview()`, but they are clipped into zero-height rows.

The `More Info` column remains visible because its title and hint have normal
minimum heights, while `InfoDescription` has an explicit `88` pixel minimum.

`AttackPreview._size_panel_to_content()` only sets the outer panel size. It
does not give the forecast rows a height, so its `170` pixel panel height does
not solve the collapsed child controls.

### Test gap

`test_attack_preview_selector.gd` currently passes because it checks:

- the assigned BBCode strings
- the outer panel width and height
- selector behavior

It does not wait for a layout pass and assert that visible forecast rows have a
non-zero rendered height. This allowed a fully blank forecast to pass.

## Fix Plan

### 1. Add a failing geometry regression test

Extend `scripts/tests/test_attack_preview_selector.gd` before changing the
scene:

1. Call `show_preview()` and wait for one process frame.
2. Assert every non-empty attacker and defender row has `size.y > 0`.
3. Assert both forecast columns have non-zero width and fit inside the panel.
4. Assert the attacker, defender, and More Info columns do not overlap.
5. Add a no-counter case and verify `No counter` remains visible while empty
   defender rows collapse without leaving overlapping controls.

The current scene should fail the row-height assertions.

### 2. Restore content height only where needed

In `scenes/ui/AttackPreview.tscn`:

- Restore `fit_content = true` for the 14 attacker and defender forecast
  labels.
- Keep `scroll_active = false` on those forecast labels.
- Keep `InfoDescription.fit_content = false`,
  `InfoDescription.scroll_active = true`, and its bounded height.
- Keep the `150` pixel forecast-column minimum widths added by `e504784`.
- Do not restore the old horizontal expand flags. The fixed column widths are
  what prevent text from wrapping into the extremely tall June 9 layout.
- Do not add fixed heights to every forecast row. Empty triangle,
  effectiveness, hit, and crit rows must still collapse naturally.

### 3. Recheck panel sizing after row heights are restored

Keep `_size_panel_to_content()` based on `get_combined_minimum_size()` so rows
can increase the panel height when necessary. Verify that:

- the normal panel remains close to the intended `170` pixel height
- long names and the `Vantage` suffix do not clip
- triangle and effectiveness rows can increase the height without overlap
- opening a long More Info description scrolls inside its column instead of
  growing the whole panel

Only adjust `PANEL_DEFAULT_HEIGHT` after measuring the restored layout. The
positioning code should not be changed unless the corrected panel dimensions
expose a separate edge-clamping defect.

### 4. Expand automated coverage

Add cases for:

- countering defender
- no-counter defender
- triangle advantage and disadvantage
- effectiveness marker
- `Vantage` suffix
- neutral and non-effective empty rows
- visible row geometry after a completed layout pass

`run_tests.sh` now glob-discovers all test files, so the existing attack
preview suites are included in the full test run.

### 5. Manual validation

Test the real map UI at:

- `1280x720`, matching the screenshot client area
- a narrower viewport such as `960x540`

For each viewport, check a center target and targets near all four screen
edges. Verify:

- both forecast columns are readable
- no rows overlap
- `No counter`, triangle, effectiveness, crit, and `Vantage` render correctly
- More Info does not cover the forecast
- the panel remains fully on-screen
- any camera pan still leaves the defender and preview readable

Capture an after-fix screenshot at `1280x720`.

## Recommended Commit Sequence

1. `Add combat preview rendered-row regression coverage`
2. `Restore combat preview forecast row sizing`
3. `Document combat preview visual verification`

## Expected Files

- `scenes/ui/AttackPreview.tscn`
- `scripts/ui/AttackPreview.gd` only if measured panel sizing needs adjustment
- `scripts/tests/test_attack_preview_selector.gd`
- `scripts/tests/test_attack_preview_position.gd` if viewport geometry coverage
  belongs there
- relevant `AGENT` manual-test and session documentation
