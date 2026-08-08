# Session Note - 2026-08-06-17-35-18Z

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `a0826599aced8a9a285c2bbd049ed19b13d09a62`
- Coordination Work ID: `IMPL-VIEWPORT-ANCHORING-2026-07-31`

## What was done

Executed the owner fold-in decision from 2026-08-06: closed
`IMPL-VIEWPORT-ANCHORING-2026-07-31` as **superseded** rather than closing it on the
v0.7.0 visual bundle.

The decision itself was already recorded on the row. This session did the three things it
called for, and corrected one factual claim inside it.

**1. Verified what actually survives, instead of trusting the prose.** The row said its
branch `agent/from-integration/viewport-anchoring` @ `f4a7f8f6` was **unmerged** and had
to be "picked over, not merged wholesale". That is wrong. `f4a7f8f6` is an **ancestor** of
`origin/agent/integration` (`a0826599`):

    git merge-base --is-ancestor f4a7f8f6 origin/agent/integration   # true
    git log origin/agent/integration..origin/agent/from-integration/viewport-anchoring
    # (empty)

It landed via merge `eb5dac14` (viewport-anchoring into the v0.6.0-visual-pass build
source) — the same ancestry `V070-BUNDLE-EXECUTION-2026-08-04` recorded on 2026-08-04.
There is **no cherry-pick step** in the handover, and the next session should not spend
time salvaging a branch.

Confirmed present on `a0826599`, symbol by symbol:

- `project.godot` — `window/stretch/aspect="expand"`, `2d/snap/snap_2d_transforms_to_pixel=true`
- `scripts/autoloads/SettingsManager.gd` — `content_scale_factor` persisted under
  `[display]`, `_derived_content_scale_factor()` (identity-diagonal first-launch default),
  `normalize_content_scale_factor()`, `set_content_scale_factor()`, `_apply_content_scale()`,
  plus the review-driven guards: `maxf(content_scale_factor, CONTENT_SCALE_FACTOR_MIN)`
  against divide-by-zero, the `content_scale <= 0.0` early-out in the safe-area inset
  maths, and the derived-default fallback on a corrupt cfg
- `scripts/ui/MenuScale.gd` — the reconciliation
  `get_effective_menu_scale() = get_menu_scale() / content_scale_factor`, with the
  rationale in its header; `_recenter()` / `_on_centered_target_resized` retired

That is the entire foundation the size-class model rests on, and it is already in the
v0.7.0 candidate.

**2. Removed the row from the display-gated list** (`f9a7f482`, this branch). Its visual
pass is **cancelled, not deferred**: it would have validated the 1280×720 design floor,
which `SMALL-SCREEN-UI-REDESIGN-2026-08-05` retires in favour of a size-class model
(Compact <600 / Medium 600–1023 / Expanded ≥1024 logical px, floor 360×640).
`IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01` was sharing that same pass and still
needs one, so it keeps its own table entry — the bundle is now the only thing gating it.

**3. Moved the unfinished part rather than dropping it.** The ~11-scene anchor conversion
is folded into each screen's per-screen conversion under the redesign row, so it is paid
once instead of landing against a retired floor and being redone.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

`f9a7f482` edits `AGENT/Docs/plans/v0.7.0_playtest_visual_bundle_handoff_2026-08-05.md`:
§2 drops the viewport-anchoring captures; §3 drops the table row and records why plus what
the closed row shipped that still holds up; §4 drops "viewport anchoring" from the v0.7.0
checklist additions while **keeping** the Viewport Scale setting (it shipped, testers
should exercise it) and flags that the checklist's "1280×720 is the design floor" wording
describes what v0.7.0 *is* and must not be returned as a ratification of the floor; §5
re-points the "Viewport Scale default and range" decision at the redesign row, because the
size class is derived from `window_size / content_scale_factor` and that default decides
which class a device lands in.

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks
- `pre-commit` full chain on `f9a7f482` — PASS (docs checks, RNG guard, analyzer tests
  12/12, scene integrity 23 scripts, session claims 500 commits, evidence matrices,
  gdformat/gdlint 301 files). Godot suite skipped: docs-only change.
- Branch-content claims above verified with `git merge-base --is-ancestor`,
  `git log <range>` and `git show <ref>:<path>` against `origin/agent/integration`, not
  from the working tree.

## Next

Tracker: `IMPL-VIEWPORT-ANCHORING-2026-07-31` → `completed`;
`V070-BUNDLE-EXECUTION-2026-08-04` and `SMALL-SCREEN-UI-REDESIGN-2026-08-05` annotated.

Then the redesign's sequencing step (2), unchanged and now unblocked: land the size-class
seam — one autoload, three classes, `size_class_changed`, both density token sets, the
density token, headless tests for boundary / hysteresis / state-preservation — replacing
the hard-coded `900.0` in `UnitDetailsScreen._update_responsive_layout()`.
