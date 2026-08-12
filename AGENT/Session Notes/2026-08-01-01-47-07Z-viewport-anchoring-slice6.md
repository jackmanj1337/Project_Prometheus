# Session Note - 2026-08-01 — Viewport anchoring Slice 6 (docs closeout)

## Branch context

- Branch: `agent/from-integration/viewport-anchoring`
- Base branch: `agent/from-integration/viewport-aspect-decisions` (sibling off `agent/integration`)
- Base SHA: `d1302b729519e074756968ea3af7ba72bdfa3e22`
- Coordination Work ID: `IMPL-VIEWPORT-ANCHORING-2026-07-31`

## What was done

Completed **Slice 6**, the docs + closeout slice of `IMPL-VIEWPORT-ANCHORING` (no engine
behaviour change). Slices 1–5 (code) were already done, committed, and pushed (tip `95758a91`);
this session closes the code side. Full closure still gated on the owner visual pass.

- **Design floor RATIFIED: 1280×720** (desktop/web) minimum reference viewport — the number the
  Slice-3 scroll-frame panels were already sized to. Written into the scoping doc §0.1 and
  `GDD_07_UI_UX.md` as a hard constraint; worst-case mobile-portrait floor stays deferred with
  §0.3 until mobile is live.
- **Scoping doc** (`viewport_expand_more_tiles_scoping_2026-07-11.md`): header → Implemented
  (Slices 1–5) / Pending validation; new §0.1 with per-slice status, the design floor, the
  pixel-ratio-is-a-product note, and the owner visual matrix. §D design-floor note + task rows
  1–4 marked Implemented.
- **DoD#1**: `GDD_07_UI_UX.md` migration clause flipped from "until the `UI-VIEWPORT-ASPECT`
  migration" to Implemented / Pending-validation, added the 1280×720 display/scaling obligation,
  refreshed Status + Last verified — AND flipped the matching `GDD_10_Roadmap.md`
  validation-queue status row in the same commit.
- **Control plane**: `UI-VIEWPORT-ASPECT` row implementation cell updated (BUILT, Slices 1–5).
- Regenerated `AGENT/Docs/INDEX.md` for the scoping-doc header change.
- **Tracker** (container `coordination/tasks.json`, staging-area docs line): added
  `playtest_ref` (the owner visual matrix) to `IMPL-VIEWPORT-ANCHORING-2026-07-31`; kept it
  `in_progress` — NOT closed until the visual pass lands. Committed + pushed on
  `agent/staging-area` (`846341c`); also fixed a pre-existing missing `AI-Run-ID` trailer on the
  prior row-registration commit so the provenance check would pass.

## Commits claimed

- `a26f9cdd1e87411306871130cd259b2f00957406` — Slice 6: viewport-anchoring docs closeout (DoD#1) + design floor

## Gates

- `bash run_tests.sh` — PASS, all suites green (also re-run in the push check worktree).
- `python3 AGENT/Docs/check_docs.py` — PASS (all 43 checks; E5 already guards `expand`).
- `python3 AGENT/Docs/gen_docs_index.py` — INDEX/REGISTERS regenerated (INDEX header line only).
- Container `coordination/check_tasks.py` — OK, 300 tasks valid, no conflicts.
- Pre-commit ran docs-only path (Godot suite correctly skipped for the docs commit).

## Next

Slice 6 done; the branch is code- and docs-complete. **Resume point = the owner visual
validation pass** (cannot run headless): 16:9 desktop, 16:10 Steam-Deck, ultrawide, web;
HUD/menu/camera screenshots at 100% and 200% `content_scale_factor`. Confirm no black bars;
menus centred + correctly sized at every menu scale AND global factor; no blur regression;
`snap_2d_transforms_to_pixel` motion looks right; scroll panels fit + scroll down to the
1280×720 floor. Only after that does `IMPL-VIEWPORT-ANCHORING-2026-07-31` close and the branch
merge back to `agent/integration` to open the rest of the UI/UX pass.

Gotcha carried over: `agent-push.sh` blocks on the untracked
`test_fixtures/zero_content/.../fixture_marker.svg.import` (a generated import sidecar, not
ours) — relocate it before push and restore after (it regenerates on `--import`).
