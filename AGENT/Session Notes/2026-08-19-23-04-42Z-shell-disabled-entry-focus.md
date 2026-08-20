# Session Notes — 2026-08-19-23-04-42Z-shell-disabled-entry-focus (Shell Disabled-Entry Focus)

## Branch context

- Branch: `agent/from-integration/shell-focusable-disabled-entries`
- Base branch: `agent/integration`
- Base SHA: `7dac8abcfb5fe714905179195b8b39ce51b60c1c`
- Coordination Work ID: `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`

## What was done

`[EPUX-07]` (owner ruling 2026-07-26, restated as `[RPD-15]` on 2026-08-13 and promoted
to all five availability surfaces) ruled that a gated entry stays **focusable but not
activatable**, so its unmet reason is reachable by keyboard, controller and screen reader
rather than by pointer hover only. The shell shipped it **inverted**, and the fix removes
the inversion in both places the shell implements focus traversal.

- **`ModalScreen._collect_focusable_controls`** no longer filters disabled buttons out of
  the traversal order.
- **`FocusNavigator._collect`** carried the same filter, inlined rather than shared. This
  is the half the row did not name and the half that matters most: **`PrepScreen` — the
  `[EPUX]` availability surface the ruling was written for — navigates through
  `FocusNavigator`, not `ModalScreen`.** Fixing only `ModalScreen` would have left the
  ruling defeated on its own surface. `MapResultsScreen`, `GameOverScreen` and
  `RewindSelector` inherit the fix too.
- **Entry focus is kept as a separate rule** in both (`_first_focusable`,
  `grab_default`): prefer an available entry, fall back to a gated one only when every
  entry is gated.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`. `71d5f59c` is the whole change: both
traversals, the new suite, and the DoD#1 documentation pair.

## Gates

- `bash run_tests.sh`: required non-Godot checks green + **all Godot suites green**, run
  twice — once before the commit and once by `agent-commit.sh` against the exact staged
  tree.
- New suite `scripts/tests/test_shell_disabled_focus.gd`: **10 passed, 0 failed**.
- Unchanged and green, and they are the evidence for the entry/traversal split:
  `test_main_menu_zero_content` (3), `test_map_menu` (13), `test_main_menu` (20),
  `test_settings_screen` (33), `test_prep_screen` (12).
- `python3 AGENT/Docs/check_docs.py`: **46/46**.
- `bash scripts/ci/check_gdscript_style.sh`: **PASS, 334 files**.
- DoD#1: `GDD_07_Screens_Panels.md` §Focus-grab subscribers and a new
  `GDD_10_Roadmap.md` Next Work Queue entry, both in the same commit.

## Decisions and context

**The row's stated premise was wrong, and it made the fix smaller.** The tracker row
says *"a disabled `BaseButton` does not take focus natively, so this needs an explicit
focusable-but-inert treatment (keep `focus_mode`, block activation) rather than just
deleting the helper"*, and warns that deleting the filter *"would let focus land on a
control that then swallows input with no feedback"*. Measured on Godot 4.6.3 rather than
read:

- `grab_focus()` on a disabled `BaseButton` **succeeds** — `has_focus()` is true.
- Setting `disabled = true` on a **focused** button does **not** release its focus.
- A focused disabled button emits **no** `pressed` for `ui_accept`.
- `find_next_valid_focus()` / `find_prev_valid_focus()` step **through** disabled buttons.

So the engine already implements focusable-but-not-activatable exactly as ruled, and only
this project's own traversal disagreed with it. No inert control type, no activation
guard, no `focus_mode` bookkeeping. Deleting the filter *is* the fix. The last check in
the new suite pins those engine facts deliberately, so a future Godot that changes them
fails here rather than silently reintroducing the defect.

**Entry focus is not traversal, and conflating them is what made the original filter look
reasonable.** The ruling governs the focus *order*; it says nothing about where a surface
should *open*. Landing the player's first focus on an inert control is a bad entry point,
and the corpus already agreed without saying so — `test_main_menu_zero_content` asserts
that with New Game disabled the Main Menu opens focused on Campaign Library, and
`test_map_menu` asserts that with End Turn and Rewind disabled the AI-phase menu opens
focused on Suspend. Both pass unchanged, which is the evidence the split is right: had I
made entry focus follow traversal, both would have broken. The fallback matters as much
as the preference — a **fully** gated surface still takes focus, or its reasons become
unreachable again, which is the failure the ruling exists to prevent.

## Next

**The ruling names three channels; this delivers two.** Keyboard and controller now
reach a gated entry's reason. **Screen reader does not, and cannot: the engine has no
accessibility or announcement seam at all** — `grep` for `accessibility_*` / announce
across `scripts/` returns nothing outside unrelated prose. Today a disabled entry's
reason lives in `tooltip_text` (as `MainMenu`'s no-pack state does), which is
pointer-only — the exact failure `[EPUX-07]` rejects option A for. Closing that is a new
row, not this one: it needs a decision about where announcements come from before any
code. Recorded here and in the roadmap entry rather than quietly scoped out.

Otherwise this row is ready to close. Its two consumers — `PREP-V1-S01` and
`B4-PREP-MAP-DEPLOYMENT` slice 2d — inherit the primitive and should not reimplement it.
