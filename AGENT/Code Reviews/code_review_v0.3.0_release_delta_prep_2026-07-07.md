---
Role: dated
---

# v0.3.0 Release-Delta Code Review Prep - 2026-07-07

Purpose: prepare the next-session review of the full delta from the shipped
v0.2.8 build source to the planned v0.3.0 build snapshot.

This is prep only. The actual review artifact should be written next session as:

`AGENT/Code Reviews/code_review_v0.3.0_release_delta_2026-07-XX.md`

## Read First

- `AGENT/Session Notes/2026-07-07n.md`
- `AGENT/Code Reviews/code_review_2026-07-05.md`
- `AGENT/Code Reviews/code_review_2026-07-07.md`
- `AGENT/Review Procedures/00_Master_Review_Procedure.md`
- `AGENT/Review Procedures/01_Code_Pillar.md`

## Boundary

- Base: `ab81a21` - v0.2.8 executable source commit.
- Head: the actual planned v0.3.0 build commit.
- If no build commit exists yet, use current `HEAD` and label the result
  "pre-build snapshot review".

Always start by recording:

```bash
git status --short
git rev-parse HEAD
git log --oneline -5
```

Known dirty file at prep time:

- `AGENT/Docs/playtests/playtest_checklist_v0.3.0.md` - now explicitly marked as
  a draft; do not treat it as final playtest material until the review and fixes
  are done.

## Coverage Map to Build

Use this command set to generate the review matrix:

```bash
BASE=ab81a21
HEAD_COMMIT=$(git rev-parse HEAD)

git diff --name-status "$BASE..$HEAD_COMMIT"
git diff --stat "$BASE..$HEAD_COMMIT"

git diff --name-only "$BASE..$HEAD_COMMIT" -- 'scripts/**/*.gd' ':!scripts/tests/**' | sort
git diff --name-only "$BASE..$HEAD_COMMIT" -- 'scripts/tests/**' | sort
git diff --name-only "$BASE..$HEAD_COMMIT" -- '*.tscn' '*.tres' '*.res' 'project.godot' | sort
git diff --name-only "$BASE..$HEAD_COMMIT" -- 'export_presets.cfg' 'tools/**' 'builds/**' | sort
git diff --name-only "$BASE..$HEAD_COMMIT" -- 'AGENT/**' | sort
```

Then classify each bucket as:

- Covered by July 5 review.
- Covered by July 7 review.
- Not yet reviewed.
- Changed after both reviews.

## Prior Review Coverage

July 5 review snapshot: `914dd025`

- Covered earlier v0.3.0 feature work before the save/input wave.
- Explicitly reviewed MRD/threat-overlay architecture.
- Known July 5 findings were spawn-seam issues and closed registry debt.
- July 7 review confirmed the spawn-seam issues are fixed.

July 7 review snapshot: `7c6378e`

- Covered unreviewed non-test `scripts/**/*.gd` since `914dd025`.
- Focused on save/suspend, RNG determinism, B6 input, `CampaignRules`, and the
  previous spawn-seam findings.
- Found one High and three Medium items.

## Known Gaps to Re-Check

These production GDScript files changed across `ab81a21..HEAD` but were outside
the July 7 review delta because they predated the July 5 review snapshot:

- `scripts/core/GridManager.gd`
- `scripts/tools/generate_placeholder_assets.gd`
- `scripts/tools/generate_tilesets.gd`

Re-check them only enough to confirm July 5 coverage still applies and no later
release-delta interaction changes the risk.

## Must-Recheck Findings

Unless already fixed before the next review starts, carry these forward:

1. **High:** production fresh-map startup does not call `RngService.start_map()`.
2. **Medium:** Settings -> Input Mode does not refresh `InputModeManager`
   immediately after the explicit setting change.
3. **Medium:** rebind UI omits shipped player-facing actions:
   `more_info`, `peek_range`, `zoom_reset`, `zoom_in`, `zoom_out`.
4. **Medium:** author-facing vocabularies still use closed dispatch lists in
   several areas.

## Release-Risk Checklist

Review these as a release delta, not as isolated commits:

- Save/suspend/continue lifecycle and cleanup.
- RNG determinism, Retry/suspend RNG capture, and raw RNG guard.
- Input mode, gamepad controls, rebind capture/conflicts, and prompt swapping.
- MRD/threat overlays, watch set, range peek, path arrows, and terrain dim.
- Display/window changes since v0.2.8 and v0.2.9 section 1.6 behavior.
- Release metadata, export version, build stamp, and checklist/build-manifest
  alignment.
- Docs/playtest material: the v0.3.0 checklist is draft until final build hash
  and known fixes are reflected.

## Verification Commands

Run at minimum:

```bash
python3 AGENT/Docs/check_docs.py
scripts/tools/check_rng_usage.sh
```

Run the full Godot suite if time allows. If time is tight, run focused suites for
the areas that changed or are flagged by the review, and state what was skipped
in the review artifact.

## Output Shape

The review artifact should include:

- Exact base/head commits.
- Dirty-tree note.
- Coverage matrix.
- Findings first, ordered by severity.
- Prior-review coverage notes.
- Remaining build blockers.
- Prioritized action plan.

Keep this review document-only. Fixes should land afterward in focused commits.
